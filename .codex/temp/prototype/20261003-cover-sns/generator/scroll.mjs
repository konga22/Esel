// Scroll-linked masthead: the cover's big "Esel" travels with the cover, a small glass logo
// appears when scrolling back up, and that logo grows back into the masthead near the top.
// With `loginAt`, a glass login bar rises from the bottom once the reader passes that offset.
import { SERIF, INK } from './lib.mjs';

export const mastLayer = `<button type="button" aria-label="맨 위 표지로 돌아가기" ref="{{setPill}}" onClick="{{toTop}}" style="position: absolute; left: 50%; top: 50px; width: 108px; height: 46px; margin-left: -54px; border-radius: 23px; background: rgba(249, 249, 251, 0.86); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.7), 0 4px 16px rgba(41, 42, 39, 0.1); opacity: 0; pointer-events: none"></button>
<div aria-hidden="true" ref="{{setMast}}" style="position: absolute; left: 0; top: 80px; width: 393px; height: 180px; box-sizing: border-box; padding-right: 10px; text-align: center; font-family: ${SERIF}; font-size: 200px; line-height: 0.9; letter-spacing: -10px; color: ${INK}; pointer-events: none; transform-origin: 50% 50%; will-change: transform, opacity"><span style="position: relative; display: inline-block">Esel<span ref="{{setDot}}" style="position: absolute; left: 100%; top: 0; color: #AE8775; opacity: 0">.</span></span></div>`;

export function scrollLogic({ loginAt = 0 } = {}) {
  const logic = `if (!this._esel) {
const refs = {};
const keep = (k) => (el) => { if (el) { refs[k] = el; if (k === 'pill') el.tabIndex = -1; } };
this._esel = { refs: refs, mode: 'cover', y: 0, dir: 0, acc: 0, animUntil: 0, login: false, set: { scroller: keep('scroller'), mast: keep('mast'), pill: keep('pill'), dot: keep('dot'), login: keep('login') } };
}
const es = this._esel;
vals.setScroller = es.set.scroller;
vals.setMast = es.set.mast;
vals.setPill = es.set.pill;
vals.setDot = es.set.dot;
vals.setLogin = es.set.login;
vals.toTop = () => {
if (!es.refs.scroller) return;
es.refs.scroller.scrollTo({ top: 0, behavior: this.eselCalm() ? 'auto' : 'smooth' });
};
vals.onScroll = (e) => this.eselScroll(e.currentTarget.scrollTop);`;
  const methods = `eselCalm() {
return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
}
eselScroll(raw) {
const es = this._esel;
const MELT = 360;
const y = Math.max(0, raw);
const d = y - es.y;
es.y = y;
if (d !== 0) {
const dir = d > 0 ? 1 : -1;
if (dir !== es.dir) { es.dir = dir; es.acc = 0; }
es.acc += Math.abs(d);
}
let mode = es.mode;
if (y <= 1) mode = 'cover';
else if (mode === 'cover' && y >= MELT && es.dir < 0 && es.acc >= 48) mode = 'float';
else if (mode === 'float' && y >= MELT && es.dir > 0 && es.acc >= 18) mode = 'cover';
if (mode !== es.mode) {
es.mode = mode;
if (y > 1) {
if (mode === 'float') {
es.animUntil = 0;
this.eselWrite(-109, 0.14, 0, 1, 0, -12);
if (es.refs.mast) void es.refs.mast.offsetWidth;
}
es.animUntil = Date.now() + 220;
}
}
this.eselPaint(y);
${loginAt ? `const showLogin = y >= ${loginAt};
if (showLogin !== es.login && es.refs.login) {
es.login = showLogin;
const el = es.refs.login;
el.style.transition = this.eselCalm() ? 'opacity 200ms ease-out' : 'transform 360ms cubic-bezier(0.32, 0.72, 0, 1), opacity 200ms ease-out';
el.style.transform = showLogin || this.eselCalm() ? 'translateY(0)' : 'translateY(140%)';
el.style.opacity = showLogin ? 1 : 0;
el.style.pointerEvents = showLogin ? 'auto' : 'none';
}` : ''}
}
eselPaint(y) {
const es = this._esel;
const MELT = 360;
const S0 = 0.14;
const PILL = -97;
if (es.mode === 'cover') {
if (y < 300) this.eselWrite(-y, 1, 1, 0, 0, 0);
else this.eselWrite(PILL - 12, S0, 0, 0, 0, -12);
return;
}
if (this.eselCalm() || y >= MELT) {
this.eselWrite(PILL, S0, 1, 1, 1, 0);
return;
}
const clamp = (v) => Math.max(0, Math.min(1, v));
const p = 1 - y / MELT;
const e = p * p * (3 - 2 * p);
this.eselWrite(Math.max(PILL, -y), S0 + (1 - S0) * e, 1, 1 - clamp(p / 0.25), 1 - clamp(p / 0.18), 0);
}
eselWrite(ty, scale, opacity, dot, pill, pillShift) {
const r = this._esel.refs;
if (!r.mast) return;
const moving = Date.now() < this._esel.animUntil;
const t = moving ? 'transform 200ms cubic-bezier(0.23, 1, 0.32, 1), opacity 200ms ease-out' : 'none';
r.mast.style.transition = t;
r.mast.style.transform = 'translateY(' + ty + 'px) scale(' + scale + ')';
r.mast.style.opacity = opacity;
if (r.dot) {
r.dot.style.transition = moving ? 'opacity 200ms ease-out' : 'none';
r.dot.style.opacity = dot;
}
if (r.pill) {
r.pill.style.transition = t;
r.pill.style.transform = 'translateY(' + pillShift + 'px)';
r.pill.style.opacity = pill;
const on = pill > 0.5;
r.pill.style.pointerEvents = on ? 'auto' : 'none';
r.pill.tabIndex = on ? 0 : -1;
}
}`;
  return { logic, methods };
}
