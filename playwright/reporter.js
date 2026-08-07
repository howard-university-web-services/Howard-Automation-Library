// playwright/reporter.js
// HAL custom side-by-side regression reporter.
//
// Generates a self-contained HTML file (all images are base64-embedded) so the
// report opens instantly with `open playwright-report/index.html` — no server
// or port is required.
//
// Layout per site:
//   | Baseline (prod)  |  Actual (dev/test)  |  Pixel diff (failures only) |
//
// The report header shows which HAL app was tested and which environments were
// compared, so you can identify results when running across multiple apps.

'use strict';

const fs   = require('fs');
const path = require('path');

class SideBySideReporter {
  constructor() {
    this._results   = [];
    this._startMs   = Date.now();
    this._appName   = process.env.HAL_APP_NAME    || 'unknown';
    this._testEnv   = process.env.HAL_TARGET_ENV  || 'prod';
    this._baseEnv   = process.env.HAL_BASELINE_ENV || 'prod';
    this._rootDir   = '';
    this._outputDir = '';
  }

  onBegin(config) {
    this._rootDir   = config.rootDir;
    this._outputDir = path.join(this._rootDir, 'playwright-report');
    fs.mkdirSync(this._outputDir, { recursive: true });
  }

  onTestEnd(test, result) {
    // Collect every PNG attachment keyed by name.
    const atts = {};
    for (const a of result.attachments) {
      if (a.contentType !== 'image/png') continue;
      let b64 = null;
      if (a.body) {
        b64 = a.body.toString('base64');
      } else if (a.path && fs.existsSync(a.path)) {
        b64 = fs.readFileSync(a.path).toString('base64');
      }
      if (b64) atts[a.name] = b64;
    }

    // Read the baseline (prod snapshot) directly from disk — more reliable than
    // piping it through testInfo.attach() which Playwright may save/cleanup
    // before onTestEnd has a chance to read it.
    // Playwright sanitizes snapshot names: dots → hyphens (magazine.howard.edu → magazine-howard-edu).
    if (!atts['baseline']) {
      const sanitized = test.title.replace(/[^a-zA-Z0-9-]/g, '-');
      const baselinePath = path.join(
        this._rootDir, 'snapshots', this._appName,
        'regression.spec.js-snapshots',
        `${sanitized}-chromium-${process.platform}.png`
      );
      if (fs.existsSync(baselinePath)) {
        atts['baseline'] = fs.readFileSync(baselinePath).toString('base64');
      }
    }

    this._results.push({
      domain:   test.title,
      status:   result.status,   // 'passed' | 'failed' | 'timedOut' | 'skipped'
      duration: result.duration,
      atts,
      // First 5 lines of each error message — enough to identify the problem.
      errors: result.errors.map(e =>
        (e.message || '').split('\n').slice(0, 5).join('\n')
      ),
    });
  }

  onEnd() {
    fs.writeFileSync(
      path.join(this._outputDir, 'index.html'),
      this._buildHTML(),
      'utf8'
    );
  }

  // ---------------------------------------------------------------------------
  // HTML generation
  // ---------------------------------------------------------------------------

  _buildHTML() {
    const passed   = this._results.filter(r => r.status === 'passed').length;
    const total    = this._results.length;
    const elapsedS = ((Date.now() - this._startMs) / 1000).toFixed(1);
    const ts       = new Date().toLocaleString();
    const allPass  = passed === total;

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HAL Regression — @${this._esc(this._appName)}</title>
<style>${this._css()}</style>
</head>
<body>
<header>
  <div class="hl">
    <h1>HAL Regression Tests</h1>
    <span class="chip chip-app">@${this._esc(this._appName)}</span>
    <span class="chip chip-env">${this._esc(this._baseEnv)} <span class="arrow">→</span> ${this._esc(this._testEnv)}</span>
  </div>
  <div class="hr">
    <span class="chip ${allPass ? 'chip-pass' : 'chip-fail'}">${passed}/${total} passed</span>
    <span class="ts">${this._esc(ts)} · ${elapsedS}s</span>
  </div>
</header>
<main>
${this._results.map(r => this._card(r)).join('\n')}
</main>
</body>
</html>`;
  }

  _card(r) {
    const isPass   = r.status === 'passed';
    // Playwright attaches the diff as 'screenshot-diff' on toHaveScreenshot failure.
    const hasDiff  = !!r.atts['screenshot-diff'];
    const durStr   = r.duration ? `${(r.duration / 1000).toFixed(1)}s` : '';
    const cols     = hasDiff ? 3 : 2;

    const errHtml = r.errors.length
      ? `<div class="card-errors"><pre>${this._esc(r.errors.join('\n\n'))}</pre></div>`
      : '';

    return `<div class="card ${isPass ? 'card-pass' : 'card-fail'}">
  <div class="card-head">
    <span class="card-domain">${this._esc(r.domain)}</span>
    <span class="pill pill-${isPass ? 'pass' : 'fail'}">${this._esc(r.status)}</span>
    <span class="dur">${durStr}</span>
  </div>
  <div class="compare cols${cols}">
    ${this._pane('baseline', `Baseline (${this._baseEnv})`, r.atts['baseline'])}
    ${this._pane('actual',   `Actual (${this._testEnv})`,   r.atts['actual'])}
    ${hasDiff ? this._pane('diff', 'Pixel diff', r.atts['screenshot-diff']) : ''}
  </div>
  ${errHtml}
</div>`;
  }

  _pane(role, label, b64) {
    const content = b64
      ? `<img src="data:image/png;base64,${b64}" alt="${this._esc(label)}" loading="lazy">`
      : `<div class="no-img">no screenshot</div>`;
    return `<div class="pane pane-${this._esc(role)}">
      <div class="pane-label">${this._esc(label)}</div>
      ${content}
    </div>`;
  }

  // ---------------------------------------------------------------------------
  // CSS
  // ---------------------------------------------------------------------------

  _css() {
    return `
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f1f5f9;color:#0f172a}
header{background:#0f172a;color:#fff;padding:16px 28px;display:flex;justify-content:space-between;align-items:center;
  flex-wrap:wrap;gap:12px;position:sticky;top:0;z-index:10;box-shadow:0 2px 8px rgba(0,0,0,.5)}
.hl,.hr{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
h1{font-size:17px;font-weight:700;letter-spacing:.3px}
.chip{display:inline-flex;align-items:center;padding:3px 12px;border-radius:20px;font-size:12px;font-weight:600}
.chip-app{background:rgba(255,255,255,.12);color:#e2e8f0}
.chip-env{background:rgba(255,255,255,.07);color:#94a3b8}
.chip-pass{background:#16a34a;color:#fff}
.chip-fail{background:#dc2626;color:#fff}
.arrow{color:#475569}
.ts{font-size:12px;color:#64748b}
main{padding:28px;max-width:1800px;margin:0 auto}
.card{background:#fff;border-radius:10px;margin-bottom:24px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.card-pass{border-top:3px solid #16a34a}
.card-fail{border-top:3px solid #dc2626}
.card-head{padding:12px 18px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f1f5f9}
.card-domain{font-size:14px;font-weight:600;flex:1;font-family:'SF Mono',SFMono-Regular,Consolas,monospace}
.pill{padding:2px 9px;border-radius:10px;font-size:11px;font-weight:700;text-transform:uppercase}
.pill-pass{background:#dcfce7;color:#15803d}
.pill-fail{background:#fee2e2;color:#b91c1c}
.dur{font-size:12px;color:#94a3b8}
.compare{display:grid}
.cols2{grid-template-columns:1fr 1fr}
.cols3{grid-template-columns:1fr 1fr 1fr}
.pane{padding:16px 18px}
.pane+.pane{border-left:1px solid #f1f5f9}
.pane-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px}
.pane-baseline .pane-label{color:#2563eb}
.pane-actual   .pane-label{color:#7c3aed}
.pane-diff     .pane-label{color:#dc2626}
.pane img{width:100%;border:1px solid #e2e8f0;border-radius:5px;display:block}
.no-img{display:flex;align-items:center;justify-content:center;height:100px;
  background:#f8fafc;border:1px dashed #cbd5e1;border-radius:5px;color:#94a3b8;font-size:12px}
.card-errors{padding:12px 18px;background:#fef2f2;border-top:1px solid #fecaca}
.card-errors pre{font-size:11px;color:#b91c1c;white-space:pre-wrap;word-break:break-all;font-family:monospace}
`;
  }

  _esc(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

module.exports = SideBySideReporter;
