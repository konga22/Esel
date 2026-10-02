const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../../../..');
const OUTDIR = path.resolve(__dirname, '../paint');
const { PNG } = require(path.join(ROOT, 'node_modules/pngjs'));
const SRC = path.join(ROOT, '.codex/temp/prototype/20260906-minimal-gallery/src/assets/');
const files = { sage: 'paint-sage.png', butter: 'paint-butter.png', powder: 'paint-powder-blue.png' };
const variants = { e: { wf: 0.82, af: 1.225 } };
const OW = 1200, OH = 600;

function cutout(png) {
  const { width: W, height: H, data } = png;
  const N = W * H;
  const d = new Float32Array(N);
  for (let i = 0; i < N; i++) d[i] = 255 - Math.min(data[i * 4], data[i * 4 + 1], data[i * 4 + 2]);
  const T = 16; // background when whiteness distance is below this and connected to the border
  const bg = new Uint8Array(N);
  const stack = [];
  const push = (x, y) => { const i = y * W + x; if (!bg[i] && d[i] < T) { bg[i] = 1; stack.push(i); } };
  for (let x = 0; x < W; x++) { push(x, 0); push(x, H - 1); }
  for (let y = 0; y < H; y++) { push(0, y); push(W - 1, y); }
  while (stack.length) {
    const i = stack.pop(); const x = i % W, y = (i / W) | 0;
    if (x > 0) push(x - 1, y); if (x < W - 1) push(x + 1, y); if (y > 0) push(x, y - 1); if (y < H - 1) push(x, y + 1);
  }
  // reference paint distance
  const sample = []; for (let i = 0; i < N; i += 97) if (!bg[i] && d[i] > 50) sample.push(d[i]);
  sample.sort((a, b) => a - b); const dRef = sample[sample.length >> 1];
  // band = non-bg pixels within R px of bg
  const R = 4; let cur = bg; 
  for (let r = 0; r < R; r++) {
    const nxt = new Uint8Array(cur);
    for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++) { const i = y * W + x; if (!cur[i] && (cur[i - 1] || cur[i + 1] || cur[i - W] || cur[i + W])) nxt[i] = 1; }
    cur = nxt;
  }
  const rgba = new Float32Array(N * 4);
  let x0 = W, x1 = 0, y0 = H, y1 = 0;
  for (let i = 0; i < N; i++) {
    let a = 1;
    if (bg[i]) a = 0;
    else if (cur[i]) a = Math.max(0, Math.min(1, (d[i] - T * 0.5) / (dRef * 0.7 - T * 0.5)));
    let r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
    if (a > 0 && a < 1) { r = Math.max(0, Math.min(255, (r - (1 - a) * 255) / a)); g = Math.max(0, Math.min(255, (g - (1 - a) * 255) / a)); b = Math.max(0, Math.min(255, (b - (1 - a) * 255) / a)); }
    rgba[i * 4] = r * a; rgba[i * 4 + 1] = g * a; rgba[i * 4 + 2] = b * a; rgba[i * 4 + 3] = a; // premultiplied
    if (a > 0.5) { const x = i % W, y = (i / W) | 0; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  }
  return { W, H, rgba, bbox: { x0, x1, y0, y1 }, dRef };
}
function sample(c, x, y, out) {
  const { W, H, rgba } = c;
  if (x < 0 || y < 0 || x > W - 1 || y > H - 1) return;
  const xi = Math.floor(x), yi = Math.floor(y), fx = x - xi, fy = y - yi;
  const xj = Math.min(W - 1, xi + 1), yj = Math.min(H - 1, yi + 1);
  for (let k = 0; k < 4; k++) {
    const a = rgba[(yi * W + xi) * 4 + k], b = rgba[(yi * W + xj) * 4 + k], cc = rgba[(yj * W + xi) * 4 + k], dd = rgba[(yj * W + xj) * 4 + k];
    out[k] += (a * (1 - fx) + b * fx) * (1 - fy) + (cc * (1 - fx) + dd * fx) * fy;
  }
}
function render(c, sx, sy) {
  const out = new PNG({ width: OW, height: OH });
  const base = c.W / OW; // source px per dest px at scale 1
  const cx = (c.bbox.x0 + c.bbox.x1) / 2, cy = (c.bbox.y0 + c.bbox.y1) / 2;
  const SS = 4, acc = [0, 0, 0, 0];
  for (let Y = 0; Y < OH; Y++) for (let X = 0; X < OW; X++) {
    acc[0] = acc[1] = acc[2] = acc[3] = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const u = X + (i + 0.5) / SS - OW / 2, v = Y + (j + 0.5) / SS - OH / 2;
      sample(c, cx + (u * base) / sx, cy + (v * base) / sy, acc);
    }
    const n = SS * SS, a = acc[3] / n, o = (Y * OW + X) * 4;
    out.data[o] = a > 0 ? Math.round(acc[0] / n / a) : 0; out.data[o + 1] = a > 0 ? Math.round(acc[1] / n / a) : 0; out.data[o + 2] = a > 0 ? Math.round(acc[2] / n / a) : 0; out.data[o + 3] = Math.round(a * 255);
  }
  return out;
}
for (const [k, f] of Object.entries(files)) {
  const c = cutout(PNG.sync.read(fs.readFileSync(SRC + f)));
  const bw = c.bbox.x1 - c.bbox.x0, bh = c.bbox.y1 - c.bbox.y0;
  console.log(k, 'bbox', JSON.stringify(c.bbox), 'aspect', (bw / bh).toFixed(2), 'dRef', c.dRef);

  for (const [v, s] of Object.entries(variants)) {
    const sx = (s.wf * c.W) / bw, sy = sx / s.af; s.sx = sx; s.sy = sy; fs.writeFileSync(path.join(OUTDIR, `esel-paint-${k}.png`), PNG.sync.write(render(c, sx, sy)));
    console.log('  ', v, 'aspect', ((bw * s.sx) / (bh * s.sy)).toFixed(2), 'width%', ((bw * s.sx) / c.W * 100).toFixed(0));
  }
}
