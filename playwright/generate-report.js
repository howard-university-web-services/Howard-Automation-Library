#!/usr/bin/env node
// generate-report.js
// Standalone post-processing script called by regression_test.sh after
// each comparison run. Reads screenshots directly from disk and generates
// playwright-report/comparison.html — a self-contained side-by-side visual
// diff report. No custom Playwright reporter machinery needed.
//
// Inputs (written during the test run):
//   playwright-report/screenshots/<domain>-actual.png  (actual, captured in test)
//   snapshots/<app>/regression.spec.js-snapshots/<sanitized>-chromium-<platform>.png (baseline)
//   playwright-report/results.json  (Playwright JSON reporter output — pass/fail status)
//
// Output:
//   playwright-report/comparison.html  (self-contained, base64 images, opens directly)

'use strict';

const fs   = require('fs');
const path = require('path');

const appName = process.env.HAL_APP_NAME    || 'unknown';
const testEnv = process.env.HAL_TARGET_ENV  || 'prod';
const baseEnv = process.env.HAL_BASELINE_ENV || 'prod';
const rootDir = __dirname;
const outDir  = path.join(rootDir, 'playwright-report');

// ---------------------------------------------------------------------------
// Load sites list
// ---------------------------------------------------------------------------
const sitesPath = path.join(rootDir, 'sites.json');
if (!fs.existsSync(sitesPath)) {
  console.error('[generate-report] sites.json not found — skipping report');
  process.exit(0);
}
const sites = JSON.parse(fs.readFileSync(sitesPath, 'utf8'));

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Parse test results from Playwright JSON reporter output
// ---------------------------------------------------------------------------
const testResults = {}; // domain → { status, duration, errors[] }
const resultsPath = path.join(outDir, 'results.json');
if (fs.existsSync(resultsPath)) {
  try {
    const data = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
    (function walk(suites) {
      for (const suite of suites || []) {
        for (const spec of suite.specs || []) {
          const result = spec.tests?.[0]?.results?.[0] || {};
          const errors = (result.errors || [])
            .map(e => (e.message || '').split('\n')
              // Keep lines that contain useful info: pixel counts, ratios, snapshot names.
              .filter(l => l.trim() && !l.startsWith('    at ') && !l.includes('Call log:'))
              .slice(0, 8)
              .join('\n')
            )
            .filter(Boolean);
          testResults[spec.title] = {
            status:   spec.ok ? 'passed' : 'failed',
            duration: result.duration || 0,
            errors,
          };
        }
        walk(suite.suites);
      }
    })(data.suites);
  } catch (e) { /* results.json missing or malformed */ }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Build per-site result objects
// ---------------------------------------------------------------------------
const timestamp  = new Date().toLocaleString();
const passed     = Object.values(testResults).filter(r => r.status === 'passed').length;
const total      = sites.length;
const allPass    = passed === total && total > 0;

const cards = sites.map(site => {
  const sanitized = site.domain.replace(/[^a-zA-Z0-9-]/g, '-');

  // Actual screenshot written by the test into a stable location outside playwright-report/
  const actualFile = path.join(rootDir, 'screenshots', appName, `${site.domain}-actual.png`);
  const actual = fs.existsSync(actualFile)
    ? fs.readFileSync(actualFile).toString('base64')
    : null;

  // Baseline snapshot written by the last `--update-snapshots` run
  const baselineFile = path.join(
    rootDir, 'snapshots', appName,
    'regression.spec.js-snapshots',
    `${sanitized}-chromium-${process.platform}.png`
  );
  const baseline = fs.existsSync(baselineFile)
    ? fs.readFileSync(baselineFile).toString('base64')
    : null;

  // Diff image: Playwright saves this to test-results on failure
  const diffDir  = path.join(rootDir, 'test-results', `regression-${sanitized}-chromium`);
  const diffFile = path.join(diffDir, `${sanitized}-diff.png`);
  const diff     = fs.existsSync(diffFile)
    ? fs.readFileSync(diffFile).toString('base64')
    : null;

  const r = testResults[site.domain] || { status: 'unknown', duration: 0, errors: [] };
  return { domain: site.domain, status: r.status, duration: r.duration, errors: r.errors, actual, baseline, diff };
});

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Generate HTML
// ---------------------------------------------------------------------------

function esc(s) {
  return String(s || '')
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function pane(role, label, b64) {
  const img = b64
    ? `<img src="data:image/png;base64,${b64}" alt="${esc(label)}">` 
    : `<div class="no-img">no screenshot</div>`;
  return `<div class="pane pane-${esc(role)}">
        <div class="pane-label">${esc(label)}</div>
        ${img}
      </div>`;
}

function card(r) {
  const isPass    = r.status === 'passed';
  const isUnknown = r.status === 'unknown';
  const hasDiff   = !!r.diff;
  const cols      = hasDiff ? 3 : 2;
  const durStr    = r.duration ? ` · ${(r.duration / 1000).toFixed(1)}s` : '';
  const openAttr  = '';  // all cards start collapsed

  // Error panel (failures only)
  const errorHtml = (!isPass && r.errors.length)
    ? `<div class="card-error">
        <span class="error-icon">✕</span>
        <pre>${esc(r.errors.join('\n\n'))}</pre>
      </div>`
    : '';

  return `<div class="card card-${isPass ? 'pass' : isUnknown ? 'unknown' : 'fail'}">
  <details${openAttr}>
    <summary class="card-head">
      <span class="card-domain">${esc(r.domain)}</span>
      <span class="pill pill-${isPass ? 'pass' : isUnknown ? 'unknown' : 'fail'}">${esc(r.status)}</span>
      <span class="dur">${esc(durStr)}</span>
      <span class="chevron"></span>
    </summary>
    ${errorHtml}
    <div class="compare cols${cols}">
      ${pane('baseline', `Baseline (${baseEnv})`, r.baseline)}
      ${pane('actual',   `Actual (${testEnv})`,   r.actual)}
      ${hasDiff ? pane('diff', 'Pixel diff', r.diff) : ''}
    </div>
  </details>
</div>`;
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HAL Regression — @${esc(appName)}</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f1f5f9;color:#0f172a}
header{background:#0f172a;color:#fff;padding:16px 28px;display:flex;justify-content:space-between;
  align-items:center;flex-wrap:wrap;gap:12px;position:sticky;top:0;z-index:10;box-shadow:0 2px 8px rgba(0,0,0,.5)}
.hl,.hr{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
h1{font-size:17px;font-weight:700;letter-spacing:.3px}
.chip{display:inline-flex;align-items:center;padding:3px 12px;border-radius:20px;font-size:12px;font-weight:600}
.chip-app{background:rgba(255,255,255,.12);color:#e2e8f0}
.chip-env{background:rgba(255,255,255,.07);color:#94a3b8}
.chip-pass{background:#16a34a;color:#fff}
.chip-fail{background:#dc2626;color:#fff}
.ts{font-size:12px;color:#64748b}
main{padding:28px;max-width:1800px;margin:0 auto}
.card{background:#fff;border-radius:10px;margin-bottom:16px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.card-pass{border-left:4px solid #16a34a}
.card-fail{border-left:4px solid #dc2626}
.card-unknown{border-left:4px solid #94a3b8}
details{width:100%}
summary{list-style:none;cursor:pointer;user-select:none}
summary::-webkit-details-marker{display:none}
.card-head{padding:13px 18px;display:flex;align-items:center;gap:10px;transition:background .15s}
.card-head:hover{background:#f8fafc}
details[open] .card-head{border-bottom:1px solid #f1f5f9}
.card-domain{font-size:14px;font-weight:600;flex:1;font-family:'SF Mono',SFMono-Regular,Consolas,monospace}
.pill{padding:2px 9px;border-radius:10px;font-size:11px;font-weight:700;text-transform:uppercase}
.pill-pass{background:#dcfce7;color:#15803d}
.pill-fail{background:#fee2e2;color:#b91c1c}
.pill-unknown{background:#f1f5f9;color:#64748b}
.dur{font-size:12px;color:#94a3b8}
.chevron{width:18px;height:18px;flex-shrink:0;background:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20' fill='%2394a3b8'%3E%3Cpath fill-rule='evenodd' d='M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06z'/%3E%3C/svg%3E") center/contain no-repeat;transition:transform .2s}
details[open] .chevron{transform:rotate(180deg)}
.card-error{display:flex;align-items:flex-start;gap:10px;padding:12px 18px;
  background:#fef2f2;border-bottom:1px solid #fecaca}
.error-icon{color:#dc2626;font-size:14px;font-weight:700;flex-shrink:0;margin-top:1px}
.card-error pre{font-size:12px;color:#7f1d1d;white-space:pre-wrap;word-break:break-word;font-family:'SF Mono',SFMono-Regular,Consolas,monospace;line-height:1.5}
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
.no-img{display:flex;align-items:center;justify-content:center;height:80px;
  background:#f8fafc;border:1px dashed #cbd5e1;border-radius:5px;color:#94a3b8;font-size:12px}
</style>
</head>
<body>
<header>
  <div class="hl">
    <h1>HAL Regression Tests</h1>
    <span class="chip chip-app">@${esc(appName)}</span>
    <span class="chip chip-env">${esc(baseEnv)} &rarr; ${esc(testEnv)}</span>
  </div>
  <div class="hr">
    <span class="chip chip-${allPass ? 'pass' : 'fail'}">${passed}/${total} passed</span>
    <span class="ts">${esc(timestamp)}</span>
  </div>
</header>
<main>
${cards.map(card).join('\n')}
</main>
</body>
</html>`;

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'comparison.html'), html, 'utf8');
console.log(`[generate-report] comparison.html written (${cards.length} sites, ${passed}/${total} passed)`);
