// Helpers for check-server.mjs: read TypeScript and SQL well enough for the harness checks, with plain Node (no install).
// These are heuristics, not a TypeScript parser. scripts/check-server.test.mjs pins down what they must accept and reject.
import { createHash } from 'node:crypto';

// ---------------------------------------------------------------------------------------------------------------
// Source scanning

/**
 * Returns two strings with the same length as `src`:
 * - `code`: comments replaced by spaces (strings kept), so commented-out code never counts.
 * - `mask`: like `code`, but string, template and regex contents are blanked too, so brackets and keywords
 *   inside text (e.g. a todo title that says "it(") never confuse the structure search.
 */
export function scan(src) {
  const code = src.split('');
  const mask = src.split('');
  const blank = (arr, from, to) => {
    for (let k = from; k < to; k++) if (arr[k] !== '\n') arr[k] = ' ';
  };
  let i = 0;
  let prev = '';

  function codeMode(untilBrace) {
    let depth = 0;
    while (i < src.length) {
      const ch = src[i];
      const next = src[i + 1];
      if (ch === '/' && next === '/') {
        const end = src.indexOf('\n', i);
        const stop = end < 0 ? src.length : end;
        blank(code, i, stop);
        blank(mask, i, stop);
        i = stop;
        continue;
      }
      if (ch === '/' && next === '*') {
        const end = src.indexOf('*/', i + 2);
        const stop = end < 0 ? src.length : end + 2;
        blank(code, i, stop);
        blank(mask, i, stop);
        i = stop;
        continue;
      }
      if (ch === "'" || ch === '"') {
        stringMode(ch);
        prev = 'a';
        continue;
      }
      if (ch === '`') {
        templateMode();
        prev = 'a';
        continue;
      }
      if (ch === '/' && (prev === '' || '(,=:[!&|?{};+-*%<>~^'.includes(prev))) {
        regexMode();
        prev = 'a';
        continue;
      }
      if (ch === '{') depth++;
      if (ch === '}') {
        if (untilBrace && depth === 0) return;
        depth--;
      }
      if (!/\s/.test(ch)) prev = ch;
      i++;
    }
  }

  function stringMode(quote) {
    i++;
    const start = i;
    while (i < src.length && src[i] !== quote && src[i] !== '\n') i += src[i] === '\\' ? 2 : 1;
    blank(mask, start, Math.min(i, src.length));
    i++;
  }

  function templateMode() {
    i++;
    let start = i;
    while (i < src.length && src[i] !== '`') {
      if (src[i] === '\\') {
        i += 2;
        continue;
      }
      if (src[i] === '$' && src[i + 1] === '{') {
        blank(mask, start, i);
        i += 2;
        codeMode(true);
        i++; // the closing } of ${ }
        start = i;
        continue;
      }
      i++;
    }
    blank(mask, start, Math.min(i, src.length));
    i++;
  }

  function regexMode() {
    const start = ++i;
    let inClass = false;
    while (i < src.length && src[i] !== '\n') {
      if (src[i] === '\\') {
        i += 2;
        continue;
      }
      if (src[i] === '[') inClass = true;
      else if (src[i] === ']') inClass = false;
      else if (src[i] === '/' && !inClass) break;
      i++;
    }
    blank(mask, start, i);
    i++;
    while (/[a-z]/.test(src[i] ?? '')) i++;
  }

  codeMode(false);
  return { code: code.join(''), mask: mask.join('') };
}

/** Matching bracket positions in a mask: open → close and close → open, for (), [] and {}. */
export function brackets(mask) {
  const close = new Map();
  const open = new Map();
  const stack = [];
  for (let k = 0; k < mask.length; k++) {
    const c = mask[k];
    if (c === '(' || c === '[' || c === '{') stack.push(k);
    else if (c === ')' || c === ']' || c === '}') {
      const o = stack.pop();
      if (o === undefined) continue;
      close.set(o, k);
      open.set(k, o);
    }
  }
  return { close, open };
}

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const QUOTED = /^(['"`])([^'"`$]*)\1$/;

// ---------------------------------------------------------------------------------------------------------------
// Tests: real test blocks, endpoint calls and 'METHOD /api/path: … → status' titles

/** Bodies of real tests: it(...) / test(...) calls. it.todo, it.skip and commented-out tests are not included. */
export function testBlocks(src) {
  const { code, mask } = scan(src);
  const { close } = brackets(mask);
  const blocks = [];
  for (const m of mask.matchAll(/(?<![\w$.])(?:it|test)\s*\(/g)) {
    const o = m.index + m[0].length - 1;
    if (close.has(o)) blocks.push(code.slice(o + 1, close.get(o)));
  }
  return blocks;
}

/** Regex source for a contract path: ':id' segments match any value, including `${issue.id}` in template literals. */
export function pathPattern(contractPath) {
  return contractPath
    .split('/')
    .map((seg) => (seg.startsWith(':') ? "[^/'\"`?\\s]+" : escapeRe(seg)))
    .join('/');
}

/** True when a test body sends the request itself: request(...) and .method('/api/path') in the same it/test block. */
export function callsEndpoint(block, method, contractPath, base = '/api') {
  if (!/\brequest\s*\(/.test(block)) return false;
  const call = new RegExp(`\\.${method.toLowerCase()}\\(\\s*['"\`]${escapeRe(base)}${pathPattern(contractPath)}['"\`?]`);
  return call.test(block);
}

/** Titles of todos and tests that name an endpoint: 'POST /api/issues/:id/like: … → 404 NOT_FOUND'. */
export function endpointTitles(src, base = '/api') {
  const { code } = scan(src);
  const titles = [];
  const re = new RegExp(`(['"\`])(GET|POST|PUT|PATCH|DELETE) (${escapeRe(base)}(?:/:?[A-Za-z0-9-]+)*)(?=[:'"\`\\s])(.*?)\\1`, 'g');
  for (const m of code.matchAll(re)) {
    const status = m[4].match(/→\s*(\d{3})(?:\s+([A-Z_]+))?\s*$/);
    titles.push({
      method: m[2],
      path: m[3].slice(base.length) || '/',
      status: status ? Number(status[1]) : null,
      code: status?.[2] ?? null,
      text: `${m[2]} ${m[3]}${m[4]}`,
    });
  }
  return titles;
}

/** Number of it.todo(...) calls (comments and strings excluded). */
export function countTodos(src) {
  return [...scan(src).mask.matchAll(/(?<![\w$.])(?:it|test)\.todo\s*\(/g)].length;
}

// ---------------------------------------------------------------------------------------------------------------
// Controllers

const VERBS = { Get: 'GET', Post: 'POST', Put: 'PUT', Patch: 'PATCH', Delete: 'DELETE', All: 'ALL', Options: 'OPTIONS', Head: 'HEAD' };
const joinPath = (...parts) => `/${parts.map((p) => p.replace(/^\/|\/$/g, '')).filter(Boolean).join('/')}`;

function readPaths(arg, allowObject) {
  const text = arg.trim();
  if (!text) return [''];
  const quoted = text.match(QUOTED);
  if (quoted) return [quoted[2]];
  if (text.startsWith('[') && text.endsWith(']')) {
    const items = text.slice(1, -1).split(',').map((s) => s.trim()).filter(Boolean);
    const values = items.map((s) => s.match(QUOTED)?.[2]);
    return values.every((v) => v !== undefined) ? values : null;
  }
  if (allowObject && text.startsWith('{') && text.endsWith('}')) {
    const at = text.search(/\bpath\s*:/);
    if (at < 0) return [''];
    const rest = text.slice(at).replace(/^path\s*:\s*/, '');
    if (rest.startsWith('[')) return readPaths(rest.slice(0, rest.indexOf(']') + 1), false);
    const value = rest.match(/^(['"`])([^'"`$]*)\1/);
    return value ? [value[2]] : null;
  }
  return null;
}

/** Routes a controller file exposes, as 'METHOD /path'. Decorator arguments the check cannot read come back in `unreadable`. */
export function controllerRoutes(src) {
  const { code, mask } = scan(src);
  const { close } = brackets(mask);
  const routes = [];
  const unreadable = [];
  const controllers = [...mask.matchAll(/@Controller\s*\(/g)].map((m) => m.index + m[0].length - 1);
  controllers.forEach((o, n) => {
    const c = close.get(o);
    const arg = code.slice(o + 1, c);
    let prefixes = readPaths(arg, true);
    if (!prefixes) {
      unreadable.push(`@Controller(${arg.trim()})`);
      prefixes = [''];
    }
    const end = n + 1 < controllers.length ? controllers[n + 1] : mask.length;
    const re = /@(Get|Post|Put|Patch|Delete|All|Options|Head)\s*\(/g;
    re.lastIndex = c;
    for (let m = re.exec(mask); m && m.index < end; m = re.exec(mask)) {
      const mo = m.index + m[0].length - 1;
      const a = code.slice(mo + 1, close.get(mo));
      const paths = readPaths(a, false);
      if (!paths) {
        unreadable.push(`@${m[1]}(${a.trim()})`);
        continue;
      }
      for (const p of prefixes) for (const q of paths) routes.push(`${VERBS[m[1]]} ${joinPath(p, q)}`);
    }
  });
  return { routes, unreadable };
}

/** True when a file reaches the database itself (PrismaService/PrismaClient import, injection or `new`). */
export function usesPrismaDirectly(src) {
  return /\bPrisma(?:Service|Client)\b|generated\/prisma|@prisma\/client|prisma\.service/.test(scan(src).code);
}

// ---------------------------------------------------------------------------------------------------------------
// Response DTOs and owner-only numbers (P18)

/** DTO classes in a file: name → { fields: [{ name, type }], heritage } (heritage = text after the class name). */
export function dtoClasses(src) {
  const { code, mask } = scan(src);
  const { close } = brackets(mask);
  const classes = new Map();
  for (const m of mask.matchAll(/\bclass\s+(\w+Dto)\b([^{]*)\{/g)) {
    const o = m.index + m[0].length - 1;
    const c = close.get(o) ?? mask.length;
    classes.set(m[1], {
      fields: dtoFields(code.slice(o + 1, c), mask.slice(o + 1, c)),
      heritage: code.slice(m.index, o).replace(/^class\s+\w+/, ''),
    });
  }
  return classes;
}

function dtoFields(code, mask) {
  // Keep only the top level of the class body so decorator arguments and method bodies are skipped.
  let depth = 0;
  let flat = '';
  for (const c of mask) {
    if ('([{'.includes(c)) {
      flat += depth === 0 ? c : ' ';
      depth++;
    } else if (')]}'.includes(c)) {
      depth--;
      flat += depth === 0 ? c : ' ';
    } else flat += depth === 0 || c === '\n' ? c : ' ';
  }
  const fields = [];
  const member = /(?:^|[;\n{}])\s*(?:@[\w.]+\s*(?:\(\s*\))?\s*)*(?:(?:public|private|protected|readonly|declare|static|override)\s+)*(?:get\s+)?([A-Za-z_$][\w$]*)\s*[?!]?\s*(?:\(\s*\)\s*)?:/g;
  for (const m of flat.matchAll(member)) {
    const start = m.index + m[0].length;
    let end = start;
    let d = 0;
    for (; end < mask.length; end++) {
      const c = mask[end];
      if (d === 0 && c === '{' && code.slice(start, end).trim()) break; // a getter or method body starts
      if ('([{<'.includes(c)) d++;
      else if (')]}>'.includes(c)) d--;
      else if (d === 0 && (c === ';' || c === '\n' || c === '=')) break;
    }
    const type = code.slice(start, end).trim();
    fields.push({ name: m[1], type });
    // Inline object types: { stats: { likeCount: number } }
    for (const n of type.matchAll(/([A-Za-z_$][\w$]*)\s*\??\s*:/g)) fields.push({ name: n[1], type: '' });
  }
  return fields;
}

const normName = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, '');

/**
 * Which forbidden field a property name is a variant of, or null.
 * likeCount also catches likesCount, like_count, totalLikes, numLikes and `likes: number`; liked and lines (reader-line text) stay allowed.
 */
export function forbiddenFieldMatch(name, type, forbidden) {
  const n = normName(name);
  for (const f of forbidden) {
    const counted = f.match(/^(.+?)Count$/);
    if (counted) {
      const stem = normName(counted[1]);
      if (new RegExp(`^(?:total|num|numberof|count)?${stem}s?(?:count|counts|total|num|number)$`).test(n)) return f;
      if (new RegExp(`^(?:total|num|numberof|count)${stem}s?$`).test(n)) return f;
      if (n === `${stem}s` && /^number\b/.test(type)) return f;
    } else if (new RegExp(`^${normName(f)}(?:s|ing|score|value)?$`).test(n)) return f;
  }
  return null;
}

/** DTO names mentioned in a type or response string: 'Page<ReaderLinePublicDto>' → ['ReaderLinePublicDto']. */
export const dtoNames = (text) => [...String(text ?? '').matchAll(/\b(\w+Dto)\b/g)].map((m) => m[1]);

function inheritedFields(name, classes, seen) {
  if (seen.has(name)) return [];
  seen.add(name);
  const cls = classes.get(name);
  if (!cls) return [];
  const fields = cls.fields.map((f) => ({ ...f, from: name }));
  const keys = (s) => [...s.matchAll(/['"`](\w+)['"`]/g)].map((m) => m[1]);
  const pick = cls.heritage.match(/PickType\s*\(\s*\w+\s*,\s*\[([^\]]*)\]/);
  const omit = cls.heritage.match(/OmitType\s*\(\s*\w+\s*,\s*\[([^\]]*)\]/);
  for (const parent of dtoNames(cls.heritage)) {
    let pf = inheritedFields(parent, classes, seen);
    if (pick) pf = pf.filter((f) => keys(pick[1]).includes(f.name));
    if (omit) pf = pf.filter((f) => !keys(omit[1]).includes(f.name));
    fields.push(...pf);
  }
  return fields;
}

/**
 * Problems in response DTOs anyone can receive: the given roots (responses of public/user endpoints) plus every …PublicDto,
 * and every DTO they contain (field types) or inherit from (extends, PickType, OmitType…).
 */
export function publicDtoProblems(classes, roots, forbidden) {
  const problems = [];
  const queue = [...new Set([...roots.filter((r) => !r.endsWith('OwnerDto')), ...[...classes.keys()].filter((k) => k.endsWith('PublicDto'))])];
  const seen = new Set();
  while (queue.length) {
    const name = queue.shift();
    if (seen.has(name) || !classes.has(name)) continue;
    seen.add(name);
    for (const field of inheritedFields(name, classes, new Set())) {
      const hit = forbiddenFieldMatch(field.name, field.type, forbidden);
      if (hit) problems.push({ dto: name, field: field.name, forbidden: hit, from: field.from });
      for (const ref of dtoNames(field.type)) {
        if (ref.endsWith('OwnerDto')) problems.push({ dto: name, field: field.name, owner: ref, from: field.from });
        else queue.push(ref);
      }
    }
  }
  const unique = new Map(problems.map((p) => [`${p.dto}.${p.field}.${p.forbidden ?? p.owner}`, p]));
  return [...unique.values()];
}

// ---------------------------------------------------------------------------------------------------------------
// Swagger must be off when NODE_ENV=production

const AND = (a, b) => (a === 'F' || b === 'F' ? 'F' : a === 'T' && b === 'T' ? 'T' : 'U');
const OR = (a, b) => (a === 'T' || b === 'T' ? 'T' : a === 'F' && b === 'F' ? 'F' : 'U');
const NOT = (a) => (a === 'T' ? 'F' : a === 'F' ? 'T' : 'U');

function definitions(files) {
  const consts = new Map();
  const functions = new Map();
  for (const src of files.values()) {
    const { code } = scan(src);
    for (const m of code.matchAll(/\b(?:const|let|var)\s+(\w+)\s*(?::[^=;]+)?=(?!>)\s*([^;]+);/g)) consts.set(m[1], m[2].trim());
    for (const m of code.matchAll(/\b(?:function\s+)?(\w+)\s*\([^()]*\)\s*(?::[^{;=]+)?\{\s*return\s+([^;]+);\s*\}/g)) {
      if (!['if', 'for', 'while', 'switch', 'catch'].includes(m[1])) functions.set(m[1], m[2].trim());
    }
    for (const m of code.matchAll(/\b(?:const|let)\s+(\w+)\s*(?::[^=;]+)?=\s*(?:async\s*)?\([^()]*\)\s*(?::[^=;]+)?=>\s*([^;{][^;]*);/g)) functions.set(m[1], m[2].trim());
  }
  return { consts, functions };
}

const ENV_LITERAL = /^(?:production|prod|development|dev|test|local)$/;

/** Value of a condition when NODE_ENV=production: 'T' (true), 'F' (false) or 'U' (depends on something else, e.g. a flag). */
export function evalUnderProduction(cond, defs) {
  let text = ` ${cond} `;
  // 1. Inline small helpers and named values so their NODE_ENV comparisons become visible.
  for (let round = 0; round < 8; round++) {
    const mask = scan(text).mask;
    const call = [...mask.matchAll(/(?<![\w$.])(\w+)\s*\(/g)].find((m) => defs.functions.has(m[1]));
    const end = call && brackets(mask).close.get(call.index + call[0].length - 1);
    const value = [...mask.matchAll(/(?<![\w$.])([A-Za-z_$][\w$]*)(?![\w$(.])/g)].find((m) => defs.consts.has(m[1]));
    if (call && end !== undefined) text = `${text.slice(0, call.index)} (${defs.functions.get(call[1])}) ${text.slice(end + 1)}`;
    else if (value) text = `${text.slice(0, value.index)} (${defs.consts.get(value[1])}) ${text.slice(value.index + value[0].length)}`;
    else break;
  }
  // 2. NODE_ENV comparisons: x === 'production' → T, x !== 'production' → F, x === 'development' → F, other literals → U.
  const cmp = /(===|!==|==|!=)\s*(['"`])(\w+)\2|(['"`])(\w+)\4\s*(===|!==|==|!=)/;
  for (let round = 0; round < 20; round++) {
    const m = text.match(cmp);
    if (!m) break;
    const literal = m[3] ?? m[5];
    const equal = (m[1] ?? m[6]).length >= 2 && !(m[1] ?? m[6]).startsWith('!');
    const isProd = literal === 'production' || literal === 'prod';
    const value = !ENV_LITERAL.test(literal) ? '__U__' : equal === isProd ? '__T__' : '__F__';
    const { open, close } = brackets(scan(text).mask);
    let from = m.index;
    let to = m.index + m[0].length;
    if (m[1]) {
      // the operand on the left: walk back over identifiers, member access, generics and balanced brackets
      let k = m.index - 1;
      while (k >= 0 && text[k] === ' ') k--;
      while (k >= 0) {
        if (text[k] === ')' || text[k] === ']') k = (open.get(k) ?? k) - 1;
        else if (/[\w$.<>]/.test(text[k])) k--;
        else break;
      }
      from = k + 1;
    } else {
      let k = to;
      while (k < text.length && text[k] === ' ') k++;
      while (k < text.length) {
        if (text[k] === '(' || text[k] === '[') k = (close.get(k) ?? k) + 1;
        else if (/[\w$.<>]/.test(text[k])) k++;
        else break;
      }
      to = k;
    }
    text = `${text.slice(0, from)} ${value} ${text.slice(to)}`;
  }
  // 3. Anything else is unknown. Evaluate !, &&, || and parentheses with three values.
  for (let round = 0; round < 50; round++) {
    const next = text.replace(/[\w$.]+\s*(?:<[^<>()]*>)?\s*\([^()]*\)/g, ' __U__ ');
    if (next === text) break;
    text = next;
  }
  if (/[?:]/.test(text.replace(/\?\./g, ''))) return 'U';
  const atoms = (text.match(/&&|\|\||!(?!=)|\(|\)|[^&|!()]+/g) ?? []).map((t) => t.trim()).filter(Boolean);
  let i = 0;
  const atom = (t) => {
    if (t === '__T__' || t === 'true' || /^isProd(?:uction)?$/.test(t)) return 'T';
    if (t === '__F__' || t === 'false' || /^is(?:Dev(?:elopment)?|Test|Local)$/.test(t)) return 'F';
    return 'U';
  };
  const or = () => {
    let v = and();
    while (atoms[i] === '||') {
      i++;
      v = OR(v, and());
    }
    return v;
  };
  const and = () => {
    let v = unary();
    while (atoms[i] === '&&') {
      i++;
      v = AND(v, unary());
    }
    return v;
  };
  const unary = () => {
    const t = atoms[i++];
    if (t === '!') return NOT(unary());
    if (t === '(') {
      const v = or();
      if (atoms[i] === ')') i++;
      return v;
    }
    return t === undefined ? 'U' : atom(t);
  };
  return atoms.length ? or() : 'U';
}

const CONTROL = ['if', 'for', 'while', 'switch', 'catch'];

function enclosingOpen(close, k) {
  let best = -1;
  for (const [o, c] of close) if (o < k && c > k && o > best) best = o;
  return best;
}

/** Conditions that must hold for the code at `pos` to run, and the innermost named function around it. */
function guardsAt(code, mask, pos) {
  const { close, open } = brackets(mask);
  const guards = [];
  let fn = null;
  // `{` preceded by `if (cond)`: returns the condition
  const ifBefore = (blockOpen) => {
    const pre = mask.slice(0, blockOpen).trimEnd();
    if (!pre.endsWith(')')) return null;
    const po = open.get(pre.length - 1);
    if (po === undefined || !/\bif\s*$/.test(mask.slice(0, po))) return null;
    return code.slice(po + 1, pre.length - 1);
  };
  const enclosing = [...close.entries()].filter(([o, c]) => mask[o] === '{' && o < pos && c > pos).sort((a, b) => b[0] - a[0]);
  for (const [o, c] of enclosing) {
    const pre = mask.slice(0, o).trimEnd();
    const cond = ifBefore(o);
    if (cond !== null) {
      guards.push({ cond, negate: false });
      continue;
    }
    if (/\belse$/.test(pre)) {
      const prevClose = pre.slice(0, -4).trimEnd().length - 1;
      const prevCond = mask[prevClose] === '}' ? ifBefore(open.get(prevClose)) : null;
      if (prevCond !== null) guards.push({ cond: prevCond, negate: true });
      continue;
    }
    if (/\b(?:try|finally|do)$/.test(pre)) continue;
    // `(…) {`, `(…): Type {` or `=> {`: a function, method or control block
    let paren = pre.endsWith(')') ? pre.length - 1 : -1;
    const typed = pre.match(/\)\s*:\s*[\w$<>[\]|.,\s]+$/);
    if (typed) paren = pre.length - typed[0].length;
    const arrow = pre.endsWith('=>');
    if (paren < 0 && !arrow) {
      if (/\bclass\s+\w+[^{]*$/.test(pre)) break;
      continue; // object literal and the like
    }
    if (paren >= 0) {
      const po = open.get(paren);
      const word = po === undefined ? null : mask.slice(0, po).match(/(\w+)\s*$/)?.[1];
      if (CONTROL.includes(word)) continue;
      fn = { open: o, close: c, name: word && word !== 'function' ? word : null };
    } else {
      const name = code.slice(Math.max(0, o - 300), o).match(/\b(?:const|let|var)\s+(\w+)\s*(?::[^=]+)?=\s*(?:async\s*)?\([^()]*\)\s*(?::[^=]+)?=>\s*$/)?.[1];
      fn = { open: o, close: c, name: name ?? null };
    }
    break; // guards outside a function do not decide when the function runs
  }
  // `if (cond) SwaggerModule.setup(…)` without braces
  const bodyStart = fn ? fn.open + 1 : 0;
  let stmt = pos - 1;
  for (; stmt >= bodyStart; stmt--) {
    const ch = mask[stmt];
    if (ch === ')' || ch === ']') stmt = open.get(stmt) ?? stmt;
    else if (ch === ';' || ch === '{' || ch === '}') break;
  }
  const braceless = mask.slice(stmt + 1, pos).match(/^\s*if\s*\(/);
  if (braceless) {
    const po = stmt + 1 + braceless[0].length - 1;
    const pc = close.get(po);
    if (pc !== undefined && pc < pos && !mask.slice(pc + 1, pos).trim()) guards.push({ cond: code.slice(po + 1, pc), negate: false });
  }
  // earlier `if (cond) return;` / `if (cond) { return; }` / `throw` at the top level of the same function
  for (const m of mask.slice(bodyStart, pos).matchAll(/\bif\s*\(/g)) {
    const po = bodyStart + m.index + m[0].length - 1;
    const pc = close.get(po);
    if (pc === undefined || pc > pos || enclosingOpen(close, po) !== (fn ? fn.open : -1)) continue;
    if (/^\s*(?:\{\s*)?(?:return|throw)\b/.test(mask.slice(pc + 1))) guards.push({ cond: code.slice(po + 1, pc), negate: true });
  }
  return { guards, fn };
}

/**
 * For every SwaggerModule.setup call: would it run when NODE_ENV=production?
 * 'off' = blocked in production, 'on' = runs in production, 'unknown' = depends on something the check cannot read (e.g. a flag).
 * `files` is a Map of path → source for all server source files.
 */
export function swaggerInProduction(files) {
  const defs = definitions(files);
  const decide = (guards) => guards.reduce((acc, g) => AND(acc, g.negate ? NOT(evalUnderProduction(g.cond, defs)) : evalUnderProduction(g.cond, defs)), 'T');
  const worst = (a, b) => (a === 'T' || b === 'T' ? 'T' : a === 'U' || b === 'U' ? 'U' : 'F');
  const label = { T: 'on', F: 'off', U: 'unknown' };
  const results = [];
  for (const [file, src] of files) {
    const { code, mask } = scan(src);
    for (const m of mask.matchAll(/\bSwaggerModule\s*\.\s*setup\s*\(/g)) {
      const { guards, fn } = guardsAt(code, mask, m.index);
      let value = decide(guards);
      if (value !== 'F' && fn?.name) {
        // The setup lives in a helper: every call of the helper must be guarded.
        const sites = [];
        for (const callerSrc of files.values()) {
          const c = scan(callerSrc);
          const cb = brackets(c.mask);
          for (const call of c.mask.matchAll(new RegExp(`(?<![\\w$])(?:this\\.)?${escapeRe(fn.name)}\\s*\\(`, 'g'))) {
            const po = call.index + call[0].length - 1;
            const after = c.mask.slice((cb.close.get(po) ?? po) + 1);
            if (/^\s*(?::[^{;=]+)?\{/.test(after) || /\bfunction\s*$/.test(c.mask.slice(0, call.index))) continue; // a definition, not a call
            sites.push(AND(value, decide(guardsAt(c.code, c.mask, call.index).guards)));
          }
        }
        value = sites.length ? sites.reduce(worst) : 'U';
      }
      results.push({ file, line: src.slice(0, m.index).split('\n').length, result: label[value] });
    }
  }
  return results;
}

// ---------------------------------------------------------------------------------------------------------------
// Migrations

/** Line endings do not change a migration: Windows checkouts (CRLF) must hash the same as macOS/Linux (LF). */
export const normalizeNewlines = (text) => text.replace(/\r\n?/g, '\n');
export const migrationHash = (text) => createHash('sha256').update(normalizeNewlines(text)).digest('hex');

/** Add-only lock: new migrations are appended; a changed or deleted locked migration is reported, never re-approved. */
export function mergeMigrationLock(lock, current) {
  const changed = Object.keys(lock).filter((f) => f in current && current[f] !== lock[f]);
  const missing = Object.keys(lock).filter((f) => !(f in current));
  const added = Object.keys(current).filter((f) => !(f in lock)).sort();
  const merged = { ...lock };
  for (const f of added) merged[f] = current[f];
  return { lock: merged, added, changed, missing };
}

/** Colors inserted by migrations, applied in order: [{ id, hex, order }] sorted by sort_order. */
export function seededColors(sqlTexts) {
  const colors = new Map();
  for (const sql of sqlTexts) {
    for (const m of sql.matchAll(/INSERT\s+INTO\s+"?colors"?\s*\(([^)]*)\)\s*VALUES\s*([\s\S]*?)(?:\bON\s+CONFLICT\b|;)/gi)) {
      const columns = m[1].split(',').map((s) => s.trim().replace(/"/g, ''));
      for (const t of m[2].matchAll(/\(([^()]*)\)/g)) {
        const values = [...t[1].matchAll(/'((?:[^']|'')*)'|(-?\d+)/g)].map((v) => (v[1] !== undefined ? v[1].replace(/''/g, "'") : Number(v[2])));
        const row = Object.fromEntries(columns.map((c, k) => [c, values[k]]));
        if (row.id) colors.set(row.id, { id: row.id, hex: row.hex, order: row.sort_order });
      }
    }
  }
  return [...colors.values()].sort((a, b) => a.order - b.order);
}
