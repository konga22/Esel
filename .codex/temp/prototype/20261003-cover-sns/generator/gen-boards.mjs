// Design boards: 00 mood, 01 tokens, 02 components, 04 motion — the reference every screen is checked against.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { B, SANS, SERIF, MONO, INK, PAPER, MUTED, HAIR, PAINT, PEOPLE, COLOR_ORDER, ME, cover, faceStroke, neckDown, crop, avatar, paint, icon, mastSize, page } from './lib.mjs';
import { miniCover } from './gen-cover2.mjs';

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'project');
const files = {};
const sizes = {};
const W = 1440;
const CARD = 'background: #FFFFFF; border-radius: 20px; box-shadow: inset 0 0 0 1px #ECECE8';
const eyebrow = (t) => `<p style="margin: 0; font-family: ${MONO}; font-size: 12px; letter-spacing: 0.08em; color: ${MUTED}">${t}</p>`;
const h2 = (t) => `<h2 style="margin: 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1.2">${t}</h2>`;
const note = (t) => `<p style="margin: 0; font-size: 14px; line-height: 1.6; color: #55574F">${t}</p>`;
const tag = (t, on = false) => `<span style="height: 24px; padding: 0 10px; border-radius: 12px; display: inline-flex; align-items: center; font-size: 12px; font-weight: 600; ${on ? `background: ${INK}; color: ${PAPER}` : `box-shadow: inset 0 0 0 1px ${INK}`}">${t}</span>`;
function board(name, title, no, h, body, opts = {}) {
  sizes[name] = h;
  files[name] = page(title, `<div style="width: ${W}px; height: ${h}px; box-sizing: border-box; padding: 56px 64px; background: ${PAPER}; color: ${INK}; font-family: ${SANS}; display: flex; flex-direction: column; gap: 36px">
<header style="display: flex; align-items: flex-end; justify-content: space-between; padding-bottom: 20px; border-bottom: 2px solid ${INK}">
<div style="display: flex; align-items: baseline; gap: 24px"><span style="font-family: ${SERIF}; font-size: 64px; line-height: 0.9; letter-spacing: -0.05em">Esel</span><span style="font-family: ${SERIF}; font-size: 30px">${title}</span></div>
<span style="font-family: ${MONO}; font-size: 13px; letter-spacing: 0.08em">${no} · 2026. 10.</span>
</header>
${body}
</div>`, { w: W, h, ...opts });
}

// ───────── 00 무드보드
const keyword = (ko, en, d) => `<div style="display: flex; flex-direction: column; gap: 6px; padding: 16px 0; border-bottom: 1px solid ${HAIR}"><div style="display: flex; align-items: baseline; gap: 10px"><span style="font-size: 20px; font-weight: 600">${ko}</span><span style="font-family: ${SERIF}; font-style: italic; font-size: 20px; color: ${MUTED}">${en}</span></div>${note(d)}</div>`;
const principle = (n, t, d) => `<div style="display: flex; gap: 14px; padding: 12px 0; border-bottom: 1px solid ${HAIR}"><span style="font-family: ${SERIF}; font-style: italic; font-size: 22px; line-height: 1.1; width: 24px">${n}</span><div style="display: flex; flex-direction: column; gap: 4px"><span style="font-size: 16px; font-weight: 600">${t}</span>${note(d)}</div></div>`;
board('BoardMood', '무드보드', '00 · MOOD BOARD', 1260, `<div style="display: flex; align-items: flex-end; justify-content: space-between; gap: 40px">
<div><p style="margin: 0; font-family: ${SERIF}; font-style: italic; font-size: 44px; line-height: 1.1">Your everyday, published.</p>
<p style="margin: 10px 0 0; font-size: 17px; line-height: 1.6; color: #44463E">평범한 하루의 착장이 한 권의 잡지가 되는 곳. 사진은 크게, 색은 물감으로, 조작은 조용하게.</p></div>
</div>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 28px; flex: 1 1 0; min-height: 0">
<section style="${CARD}; padding: 28px; display: flex; flex-direction: column; gap: 4px">
${eyebrow('01 / 키워드와 말투')}
${keyword('잡지처럼', 'Editorial', '표지·호수·펼침면·구독. 앱의 말을 잡지의 말로 바꾼다.')}
${keyword('색으로', 'Chromatic', '오늘의 색 하나가 하루의 주제. 색은 아크릴 물감으로 말한다.')}
${keyword('가볍게', 'Effortless', '사진 한 장과 한 줄이면 한 호가 된다. 잡지를 만드는 일이 숙제가 되지 않게.')}
${keyword('누구나 표지', 'Inclusive', '얼굴은 선택. 물감이나 제호로 가린 표지도 똑같이 멋지다.')}
<div style="margin-top: 14px; display: flex; flex-direction: column; gap: 8px">
${eyebrow('VOICE')}
<p style="margin: 0; font-family: ${SERIF}; font-size: 21px; line-height: 1.5">“오늘 호는 아직 열두 쪽이 더 남았어요.”<br>“창간을 축하해요.”<br>“카멜이 보이게 찍어요.”</p>
${note('하지 않는 말: 점수·순위·평가, 과한 감탄사, 제호 밖의 영어.')}
</div>
</section>
<section style="${CARD}; padding: 28px; display: flex; flex-direction: column; gap: 18px">
${eyebrow('02 / 색 — 열두 가지 오늘의 색')}
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px">
${['ama', 'lise', 'kofi', 'riva'].map((k) => cover(k, 88, 132, 0.5, 0.25, '; width: 100%; border-radius: 10px')).join('\n')}
</div>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px 8px">
${COLOR_ORDER.map((c) => `<div style="display: flex; flex-direction: column; align-items: center; gap: 2px">${paint(c, 96, '', '')}<span style="font-size: 13px; font-weight: 600">${PAINT[c].name}</span><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${PAINT[c].hex}</span></div>`).join('\n')}
</div>
${note('하루에 세 가지가 후보로 온다. 값은 방향이며 사진을 정밀 측정한 수치가 아니다.')}
</section>
<section style="${CARD}; padding: 28px; display: flex; flex-direction: column; gap: 4px">
${eyebrow('03 / Esel 문법')}
<div style="display: flex; gap: 16px; margin: 10px 0 6px">
${miniCover({ key: 'dana', w: 150, h: 220, mastColor: INK, px: 0.58, py: 0.5, href: 'CoverFeed.dc.html' })}
${miniCover({ key: ME, w: 150, h: 220, mast: ME, mastColor: '#FFFFFF', style: 'paint', fs: mastSize(ME, 150, 66), href: 'JoinDone.dc.html', label: '내 잡지 표지 보기' })}
</div>
${principle('1', '표지는 첫 장만', '내리면 제호가 작은 로고가 되고, 올라오면 다시 제호로 녹아든다.')}
${principle('2', '제호는 이름이 된다', '내 잡지의 제호는 영문 닉네임. 앱의 첫 표지만 Esel.')}
${principle('3', '얼굴은 선택', '그대로 · 물감 한 획 · 제호 뒤로 · 목 아래. 호마다 바꾼다.')}
${principle('4', '글라스는 사진 위에서만', '메뉴 캡슐과 로그인 바. 흰 화면과 투명도 줄이기에서는 단색.')}
${principle('5', '색 이름은 물감 옆에', '시각은 쪽 번호 맞은편, 색 이름은 물감 바로 옆.')}
${principle('6', '숫자는 본인에게만', '좋아요·구독자·독자 한 줄·스크랩 수는 발행한 사람만 본다. 같은 색 인원과 호수는 모두에게.')}
${principle('7', '같은 색은 발행하면 펼쳐진다', '발행 전에는 같은 색 표지 세 장만. 자정이 지나면 모두 열린다.')}
</section>
</div>`);

// ───────── 01 디자인 토큰
const swatch = (name, hex, use, extra = '') => `<div style="display: flex; flex-direction: column; gap: 8px"><span style="height: 72px; border-radius: 14px; background: ${hex}; box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.08)${extra}"></span><span style="font-size: 14px; font-weight: 600">${name}</span><span style="font-family: ${MONO}; font-size: 12px; color: ${MUTED}">${hex.startsWith('#') ? hex : ''}</span>${note(use)}</div>`;
const typeRow = (role, sample, spec) => `<div style="display: grid; grid-template-columns: 150px minmax(0, 1fr) 360px; align-items: center; gap: 24px; padding: 14px 0; border-bottom: 1px solid ${HAIR}"><span style="font-size: 14px; font-weight: 600">${role}</span>${sample}<span style="font-family: ${MONO}; font-size: 12px; line-height: 1.6; color: #55574F">${spec}</span></div>`;
const curve = (name, x1, y1, x2, y2, use) => `<div style="display: flex; flex-direction: column; gap: 8px"><svg width="120" height="120" viewBox="-6 -6 132 132" fill="none" aria-hidden="true"><rect x="0" y="0" width="120" height="120" stroke="${HAIR}"></rect><path d="M0 120 C ${x1 * 120} ${(1 - y1) * 120} ${x2 * 120} ${(1 - y2) * 120} 120 0" stroke="${INK}" stroke-width="2"></path></svg><span style="font-size: 14px; font-weight: 600">${name}</span><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">cubic-bezier(${x1}, ${y1}, ${x2}, ${y2})</span>${note(use)}</div>`;
board('BoardTokens', '디자인 토큰', '01 · DESIGN TOKENS', 1910, `<section style="display: flex; flex-direction: column; gap: 18px">
${h2('색 · 바탕')}
<div style="display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 20px">
${swatch('Paper', PAPER, '모든 흰 화면의 바탕.')}
${swatch('Ink', INK, '글자·주요 버튼·제호(먹).')}
${swatch('Muted', MUTED, '보조 글자. 더 흐리게 하지 않는다.')}
${swatch('Hairline', HAIR, '목록 구분선, 칩 테두리.')}
${swatch('Glass', 'rgba(249, 249, 251, 0.58)', '흐림 22 · 채도 1.6 · 안쪽 흰 선 1px. 사진 위 메뉴·로그인 바.', '; background: linear-gradient(rgba(249, 249, 251, 0.58), rgba(249, 249, 251, 0.58)), linear-gradient(135deg, #A9BDDC, #C2643F)')}
${swatch('Photo shade', '#000000', '사진 아래 0 → 72%, 위 40 → 0%. 흰 글자와 흰 제호를 받친다.', '; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.72))')}
</div>
</section>
<section style="display: flex; flex-direction: column; gap: 18px">
${h2('색 · 오늘의 색 열두 가지')}
<div style="display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 18px 20px">
${COLOR_ORDER.map((c) => `<div style="display: flex; align-items: center; gap: 10px">${paint(c, 92, '', '')}<div style="display: flex; flex-direction: column"><span style="font-size: 15px; font-weight: 600">${PAINT[c].name}</span><span style="font-family: ${SERIF}; font-style: italic; font-size: 15px; color: ${MUTED}">${PAINT[c].en}</span><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${PAINT[c].hex}</span></div></div>`).join('\n')}
</div>
${note('색은 물감·스와치·띠·같은 색 칩에만 쓴다. 버튼이나 화면 바탕을 색으로 칠하지 않는다. 물감은 같은 입체 모양에 색만 바꾼 이미지다.')}
</section>
<section style="display: flex; flex-direction: column">
${h2('글꼴')}
<div style="margin-top: 8px">
${typeRow('제호', `<span style="font-family: ${SERIF}; font-size: 120px; line-height: 0.9; letter-spacing: -0.05em">Esel</span>`, 'Cormorant Garamond 400 · 200px · 행간 0.9 · 자간 -0.05em<br>글자 수에 맞춰 줄임: min(200, 0.9 × 폭 ÷ (0.47 × 글자 수))')}
${typeRow('이름', `<span style="font-family: ${SERIF}; font-style: italic; font-size: 76px; line-height: 0.9">dana</span>`, 'Cormorant Garamond Italic · 76px · 자간 -0.03em · 표지와 서가')}
${typeRow('지면 제목', `<span style="font-family: ${SERIF}; font-size: 34px; line-height: 1.22">난간에 기대서, 셔츠 하나로.</span>`, 'Cormorant + Nanum Myeongjo · 30–36px · 행간 1.2')}
${typeRow('본문', `<span style="font-size: 15px; line-height: 1.45">오늘 버터는 니트로 풀었다. 스커트 패턴이 다 했다.</span>`, 'Instrument Sans + Pretendard · 15px · 행간 1.45')}
${typeRow('라벨', `<span style="font-size: 14px; font-weight: 600">파우더 블루 · 같은 색 187명</span>`, 'Instrument Sans + Pretendard 600 · 13–16px')}
${typeRow('쪽·시각', `<span style="font-family: ${SERIF}; font-style: italic; font-size: 16px">02 &nbsp;·&nbsp; 오전 8:40</span>`, 'Cormorant Italic · 16px · 쪽 번호와 시각은 양 끝')}
${typeRow('메타', `<span style="font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">ESEL · Nº 249 · 2026. 9. 6.</span>`, 'DM Mono · 11–13px · 자간 0.06em · 호수·날짜·단계')}
</div>
</section>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 28px">
<section style="${CARD}; padding: 24px; display: flex; flex-direction: column; gap: 14px">
${eyebrow('간격 · 크기')}
${[4, 8, 12, 16, 20, 24, 32].map((s) => `<div style="display: flex; align-items: center; gap: 12px"><span style="width: ${s * 4}px; height: 12px; background: ${INK}"></span><span style="font-family: ${MONO}; font-size: 12px">${s}</span></div>`).join('\n')}
${note('누를 수 있는 곳은 최소 48×48. 화면 좌우 여백 20, 안쪽 지면 글 18.')}
</section>
<section style="${CARD}; padding: 24px; display: flex; flex-direction: column; gap: 14px">
${eyebrow('모서리')}
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px">
${[[0, '표지·지면 사진'], [4, '펼침면 사진'], [16, '세그먼트·카드'], [22, '색 고르기'], [28, '시트 위쪽'], [999, '버튼·캡슐']].map(([r, u]) => `<div style="display: flex; flex-direction: column; gap: 6px"><span style="height: 64px; border-radius: ${Math.min(r, 32)}px; box-shadow: inset 0 0 0 1.5px ${INK}"></span><span style="font-family: ${MONO}; font-size: 12px">${r === 999 ? 'pill' : r}</span><span style="font-size: 12px; color: ${MUTED}">${u}</span></div>`).join('\n')}
</div>
</section>
<section style="${CARD}; padding: 24px; display: flex; flex-direction: column; gap: 14px">
${eyebrow('깊이')}
${[['캡슐 · 시트', '0 10px 28px rgba(0,0,0,.14)'], ['작은 표지', '0 4px 12px rgba(41,42,39,.16)'], ['표지 미리보기', '0 14px 36px rgba(41,42,39,.2)']].map(([n, s]) => `<div style="display: flex; align-items: center; gap: 14px"><span style="width: 64px; height: 44px; border-radius: 10px; background: #FFFFFF; box-shadow: ${s.replace(/,\./g, ', 0.').replace(/rgba\(0,0,0,/g, 'rgba(0, 0, 0, ').replace(/rgba\(41,42,39,/g, 'rgba(41, 42, 39, ')}"></span><div style="display: flex; flex-direction: column"><span style="font-size: 14px; font-weight: 600">${n}</span><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${s}</span></div></div>`).join('\n')}
${note('그림자는 떠 있는 것에만. 사진·지면에는 쓰지 않는다.')}
</section>
</div>
<section style="display: flex; flex-direction: column; gap: 18px">
${h2('움직임 곡선과 시간')}
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)) 1.4fr; gap: 28px; align-items: start">
${curve('ease-out', 0.23, 1, 0.32, 1, '들어오는 것, 누름 반응.')}
${curve('drawer', 0.32, 0.72, 0, 1, '시트·로그인 바·화면 연결.')}
${curve('in-out', 0.77, 0, 0.175, 1, '제자리에서 바뀌는 것(엽서 뒤집기).')}
<div style="display: flex; flex-direction: column; gap: 10px">
${[['160ms', '누름'], ['200ms', '작은 로고 나타남·숨김'], ['240ms', '호수 숫자 넘김'], ['360ms', '로그인 바, 표지 → 펼침면'], ['520ms', '하루 한 번: 오늘의 색 짜내기']].map(([t, u]) => `<div style="display: flex; align-items: center; gap: 12px"><span style="width: ${parseInt(t, 10) / 2.2}px; height: 10px; border-radius: 5px; background: ${INK}"></span><span style="font-family: ${MONO}; font-size: 12px; width: 56px">${t}</span><span style="font-size: 13px">${u}</span></div>`).join('\n')}
${note('자주 쓰는 동작일수록 짧게. 하루 한 번인 순간에만 길게.')}
</div>
</div>
</section>`);

// ───────── 02 컴포넌트
const spec = (label, el, w = 'auto') => `<div style="display: flex; flex-direction: column; gap: 10px; width: ${w}"><div style="min-height: 64px; display: flex; align-items: center">${el}</div><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${label}</span></div>`;
const btn = (t, kind, state = 'default', w = 200) => {
  const base = `width: ${w}px; height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 600`;
  const s = state === 'pressed' ? '; transform: scale(0.97)' : state === 'disabled' ? '; opacity: 0.38' : '';
  if (kind === 'primary') return `<span style="${base}; background: ${INK}; color: ${PAPER}${s}">${t}</span>`;
  if (kind === 'secondary') return `<span style="${base}; box-shadow: inset 0 0 0 1.5px ${INK}${s}">${t}</span>`;
  return `<span style="${base}; text-decoration: underline; text-underline-offset: 5px${s}">${t}</span>`;
};
const segSpec = (labels, on) => `<div style="display: flex; gap: 6px; width: 340px">${labels.map((l, i) => `<span style="flex: 1 1 0; height: 36px; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; box-shadow: inset 0 0 0 1.5px ${INK}; ${i === on ? `background: ${INK}; color: ${PAPER}` : ''}">${l}</span>`).join('')}</div>`;
const chipSpec = (label, c, on) => `<span style="height: 38px; padding: 0 ${c ? '14px 0 8px' : '16px'}; border-radius: 19px; display: inline-flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 500; ${on ? `background: ${INK}; color: ${PAPER}` : 'background: #FFFFFF; box-shadow: inset 0 0 0 1px #E0E1DC'}">${c ? paint(c, 40, '', '') : ''}${label}</span>`;
const heartSvg = (fill) => `<svg width="23" height="23" viewBox="0 0 24 24" fill="${fill}" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true"><path d="M12 20.3l-1.2-1.1C6.2 15 3.5 12.5 3.5 9.4 3.5 7 5.4 5 7.8 5c1.6 0 3.2.9 4.2 2.2C13 5.9 14.6 5 16.2 5c2.4 0 4.3 2 4.3 4.4 0 3.1-2.7 5.6-7.3 9.8L12 20.3z"></path></svg>`;
// Reactions carry no numbers on other people's covers; the publisher alone sees counts on their own issue.
const statsSpec = (liked, own = false) => `<span style="display: flex; align-items: center; gap: 18px; color: ${INK}; font-size: 13px; font-weight: 600"><span style="display: flex; align-items: center; gap: 6px">${heartSvg(liked ? 'currentColor' : 'none')}${own ? '128' : ''}</span><span style="display: flex; align-items: center; gap: 6px">${icon('comment', 23)}${own ? '12' : ''}</span><span style="display: flex; align-items: center; gap: 6px">${icon('bookmark', 23)}${own ? '9' : ''}</span></span>`;
const lockedChipSpec = (c) => `<span style="height: 38px; padding: 0 12px 0 8px; border-radius: 19px; display: inline-flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 500; background: #FFFFFF; box-shadow: inset 0 0 0 1.5px ${INK}">${paint(c, 40, '', '')}${PAINT[c].name}${icon('lock', 15, 1.8)}</span>`;
const inputSpec = (label, value, state) => `<div style="display: flex; flex-direction: column; width: 300px"><span style="font-size: 12px; color: ${state === 'error' ? '#B3261E' : MUTED}">${label}</span><span style="height: 44px; display: flex; align-items: center; border-bottom: ${state === 'focus' ? 2 : 1.5}px solid ${state === 'error' ? '#B3261E' : INK}; font-family: ${SERIF}; font-size: 24px; color: ${value ? INK : '#9A9C94'}">${value || 'selin'}</span>${state === 'error' ? '<span style="margin-top: 6px; font-size: 12px; color: #B3261E">이미 있는 이름이에요.</span>' : ''}</div>`;
board('BoardComponents', '컴포넌트', '02 · COMPONENTS', 1770, `<section style="display: flex; flex-direction: column; gap: 18px">
${h2('메뉴 캡슐 · 로그인 바 · 작은 로고')}
<div style="display: flex; gap: 36px; align-items: flex-start; flex-wrap: wrap">
<div style="display: flex; flex-direction: column; gap: 10px"><div style="position: relative; width: 260px; height: 110px; border-radius: 18px; overflow: hidden">${cover('ama', 260, 110, 0.5, 0.55, '; position: absolute; left: 0; top: 0', '')}<span class="esel-glass" style="position: absolute; left: 32px; top: 25px; width: 196px; height: 60px; box-sizing: border-box; padding: 0 6px; border-radius: 30px; display: flex; align-items: center; justify-content: space-between"><span style="width: 60px; display: flex; justify-content: center">${paint(PEOPLE[ME].color, 52, '', '')}</span><span style="width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('plus', 22, 2)}</span><span style="width: 60px; display: flex; justify-content: center">${avatar(ME, 34)}</span></span></div><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">캡슐 · 글라스 · 사진 위</span></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="position: relative; width: 260px; height: 110px; border-radius: 18px; background: #ECECEF"><span style="position: absolute; left: 32px; top: 25px; width: 196px; height: 60px; box-sizing: border-box; padding: 0 6px; border-radius: 30px; display: flex; align-items: center; justify-content: space-between; background: ${PAPER}; box-shadow: 0 10px 28px rgba(0, 0, 0, 0.14)"><span style="width: 60px; display: flex; justify-content: center">${paint(PEOPLE[ME].color, 52, '', '')}</span><span style="width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('plus', 22, 2)}</span><span style="width: 60px; display: flex; justify-content: center">${avatar(ME, 34)}</span></span></div><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">캡슐 · 투명도 줄이기 / 고대비</span></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="position: relative; width: 420px; height: 110px; border-radius: 18px; overflow: hidden">${cover('lise', 420, 110, 0.5, 0.6, '; position: absolute; left: 0; top: 0', '')}<span class="esel-glass" style="position: absolute; left: 20px; right: 20px; top: 22px; height: 66px; box-sizing: border-box; padding: 8px; border-radius: 33px; display: flex; gap: 8px"><span style="flex: 1 1 0; border-radius: 25px; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 1.5px ${INK}; font-size: 15px; font-weight: 600">로그인</span><span style="flex: 1.35 1 0; border-radius: 25px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">내 잡지 만들기</span></span></div><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">로그인 바 · 비로그인 스크롤에서 캡슐 자리</span></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="position: relative; width: 200px; height: 110px; border-radius: 18px; overflow: hidden">${cover('kofi', 200, 110, 0.7, 0.4, '; position: absolute; left: 0; top: 0', '')}<span style="position: absolute; left: 46px; top: 32px; width: 108px; height: 46px; border-radius: 23px; display: flex; align-items: center; justify-content: center; background: rgba(249, 249, 251, 0.86); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.7), 0 4px 16px rgba(41, 42, 39, 0.1); font-family: ${SERIF}; font-size: 28px; letter-spacing: -1.4px">Esel<span style="color: #AE8775">.</span></span></div><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">작은 로고 · 위로 스크롤</span></div>
</div>
</section>
<section style="display: flex; flex-direction: column; gap: 18px">
${h2('버튼')}
<div style="display: grid; grid-template-columns: 120px repeat(3, 220px); gap: 16px 24px; align-items: center">
<span></span>${['기본', '누름 0.97', '비활성 38%'].map((t) => `<span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${t}</span>`).join('')}
<span style="font-size: 14px; font-weight: 600">주요</span>${['default', 'pressed', 'disabled'].map((s) => btn('발행', 'primary', s)).join('')}
<span style="font-size: 14px; font-weight: 600">보조</span>${['default', 'pressed', 'disabled'].map((s) => btn('로그인', 'secondary', s)).join('')}
<span style="font-size: 14px; font-weight: 600">글자</span>${['default', 'pressed', 'disabled'].map((s) => btn('내 잡지 보기', 'text', s)).join('')}
</div>
<div style="display: flex; gap: 24px; align-items: center">
${spec('사진 위 구독', `<span style="padding: 16px; border-radius: 14px; background: #3C3D38; color: #FFFFFF; display: flex; gap: 10px"><span style="height: 32px; padding: 0 14px; border-radius: 16px; display: flex; align-items: center; box-shadow: inset 0 0 0 1.5px #FFFFFF; font-size: 13px; font-weight: 600">구독</span><span style="height: 32px; padding: 0 14px; border-radius: 16px; display: flex; align-items: center; background: #FFFFFF; color: ${INK}; font-size: 13px; font-weight: 600">구독 중</span></span>`)}
${spec('흰 화면 구독', `<span style="display: flex; gap: 10px"><span style="height: 44px; padding: 0 24px; border-radius: 22px; display: flex; align-items: center; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">구독</span><span style="height: 44px; padding: 0 20px; border-radius: 22px; display: flex; align-items: center; box-shadow: inset 0 0 0 1.5px ${INK}; font-size: 15px; font-weight: 600">구독 중</span></span>`)}
${spec('소셜 로그인', `<span style="display: flex; gap: 10px"><span style="width: 220px; height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; gap: 10px; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">${icon('apple', 20, 1.6)}Apple로 계속하기</span><span style="width: 220px; height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; background: #FFFFFF; box-shadow: inset 0 0 0 1px #D8D9D3; font-size: 15px; font-weight: 600">Google로 계속하기</span></span>`)}
</div>
</section>
<section style="display: flex; flex-direction: column; gap: 18px">
${h2('선택')}
<div style="display: flex; gap: 32px; flex-wrap: wrap; align-items: flex-start">
${spec('같은 색 칩 · 선택 / 오늘 후보 색 발행 전 / 기본', `<span style="display: flex; gap: 8px">${chipSpec('전체', null, true)}${lockedChipSpec('camel')}${chipSpec('코발트', 'cobalt', false)}</span>`)}
${spec('세그먼트 · 얼굴', segSpec(['그대로', '물감', '제호 뒤', '목 아래'], 1))}
${spec('색 고르기 · 선택', `<span style="width: 340px; height: 92px; display: flex; align-items: center; gap: 16px; padding: 0 18px; box-sizing: border-box; border-radius: 22px; background: #FFFFFF; box-shadow: inset 0 0 0 1.5px ${INK}, 0 6px 18px rgba(41, 42, 39, 0.08)">${paint('camel', 110, '', '')}<span style="display: flex; flex-direction: column"><span style="font-size: 18px; font-weight: 600">카멜</span><span style="font-family: ${SERIF}; font-style: italic; font-size: 16px; color: ${MUTED}">Camel</span></span><span style="margin-left: auto; width: 26px; height: 26px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('check', 16, 2.2)}</span></span>`)}
${spec('반응 · 남의 표지 · 숫자 없음 / 좋아요', `<span style="display: flex; gap: 28px">${statsSpec(false)}${statsSpec(true)}</span>`)}
${spec('반응 · 내 표지 · 나만 보는 숫자', `<span style="display: flex; flex-direction: column; gap: 6px">${statsSpec(false, true)}<span style="font-size: 13px; color: ${MUTED}">오늘 12명이 읽었어요 · 나에게만 보여요</span></span>`)}
${spec('입력 · 기본 / 입력 중 / 오류', `<span style="display: flex; gap: 28px">${inputSpec('영문 닉네임', '', 'default')}${inputSpec('영문 닉네임', 'selin', 'focus')}${inputSpec('영문 닉네임', 'dana', 'error')}</span>`)}
</div>
</section>
<section style="display: flex; flex-direction: column; gap: 18px">
${h2('표지 · 지면 · 정보 줄')}
<div style="display: flex; gap: 28px; align-items: flex-start">
${spec('작은 표지 · 그대로', miniCover({ key: 'riva', w: 150, h: 220, py: 0.3 }))}
${spec('물감 한 획', miniCover({ key: 'lise', w: 150, h: 220, style: 'paint', py: 0.3 }))}
${spec('제호 뒤로', miniCover({ key: 'kofi', w: 150, h: 220, style: 'zoom' }))}
${spec('목 아래', miniCover({ key: 'omar', w: 150, h: 220, style: 'neck' }))}
${spec('제호 · 글자 수에 맞춰 줄임', `<span style="display: flex; flex-direction: column; gap: 4px; width: 380px">${['Esel', 'selin', 'magdalena'].map((t) => `<span style="height: 64px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid ${HAIR}"><span style="font-family: ${SERIF}; font-size: ${Math.round(mastSize(t, 393, 200) * 0.3)}px; letter-spacing: -0.05em; line-height: 1">${t}</span><span style="font-family: ${MONO}; font-size: 11px; color: ${MUTED}">${mastSize(t, 393, 200)}px @ 393</span></span>`).join('')}</span>`)}
</div>
<div style="display: flex; gap: 28px; align-items: center">
${spec('안쪽 지면 머리 · 쪽 번호 / 시각', `<span style="width: 393px; display: flex; justify-content: space-between; padding: 0 18px; box-sizing: border-box; font-family: ${SERIF}; font-style: italic; font-size: 16px; border-top: 1px solid ${HAIR}; border-bottom: 1px solid ${HAIR}; height: 40px; align-items: center"><span>02</span><span>오전 8:40</span></span>`)}
${spec('이름 줄 · 이름 · 물감 · 색 이름 · 반응', `<span style="width: 393px; display: flex; align-items: center; gap: 8px; padding: 0 6px 0 18px; box-sizing: border-box; height: 52px"><span style="font-size: 18px; font-weight: 600">ama</span>${paint('butter', 54, '', '')}<span style="font-size: 13px; color: ${MUTED}">버터</span><span style="margin-left: auto; display: flex; align-items: center; gap: 22px">${heartSvg('none')}${icon('bookmark', 23)}</span></span>`)}
</div>
</section>`);

// ───────── 04 모션
const motionCss = `@keyframes melt{0%,18%{transform:translateY(-58px) scale(0.2)}62%,100%{transform:translateY(0) scale(1)}}
@keyframes meltPill{0%,18%{opacity:1}32%,100%{opacity:0}}
@keyframes showHide{0%,10%{opacity:0;transform:translateY(-12px)}22%,62%{opacity:1;transform:translateY(0)}74%,100%{opacity:0;transform:translateY(-12px)}}
@keyframes press{0%,30%{transform:scale(1)}36%,48%{transform:scale(0.97)}56%,100%{transform:scale(1)}}
@keyframes loginUp{0%,15%{transform:translateY(140%);opacity:0}38%,80%{transform:translateY(0);opacity:1}92%,100%{transform:translateY(140%);opacity:0}}
@keyframes spread{0%,20%{transform:translate(0,0) scale(1)}55%,100%{transform:translate(-62px,40px) scale(0.42)}}
@keyframes spreadText{0%,45%{opacity:0;transform:translateY(8px)}62%,100%{opacity:1;transform:translateY(0)}}
@keyframes squeeze{0%,12%{clip-path:inset(0 100% 0 0)}48%,100%{clip-path:inset(0 0 0 0)}}
@keyframes stamp{0%,20%{transform:scale(1)}26%{transform:scale(0.96)}32%{transform:scale(1)}38%{transform:scale(0.96)}44%,100%{transform:scale(1)}}
@keyframes roll{0%,46%{transform:translateY(0)}58%,100%{transform:translateY(-100%)}}
@keyframes zoomTile{0%,20%{transform:scale(0.44)}55%,100%{transform:scale(1)}}
@keyframes chipFill{0%,15%{clip-path:inset(0 100% 0 0)}40%,100%{clip-path:inset(0 0 0 0)}}
@keyframes tileIn{0%,40%{opacity:0;transform:translateY(12px)}60%,100%{opacity:1;transform:translateY(0)}}
@keyframes pull{0%,15%{transform:translateY(0)}40%{transform:translateY(34px)}52%{transform:translateY(-4px)}60%,100%{transform:translateY(0)}}
@keyframes heart{0%,30%{transform:scale(0.85);fill-opacity:0}42%,100%{transform:scale(1);fill-opacity:1}}
.m-melt{animation:melt 4s cubic-bezier(0.23,1,0.32,1) infinite alternate}
.m-meltpill{animation:meltPill 4s ease-out infinite alternate}
.m-show{animation:showHide 3.6s cubic-bezier(0.23,1,0.32,1) infinite}
.m-press{animation:press 2s cubic-bezier(0.23,1,0.32,1) infinite}
.m-login{animation:loginUp 4s cubic-bezier(0.32,0.72,0,1) infinite}
.m-spread{animation:spread 3.6s cubic-bezier(0.32,0.72,0,1) infinite alternate;transform-origin:0 0}
.m-spreadtext{animation:spreadText 3.6s ease-out infinite alternate}
.m-squeeze{animation:squeeze 3.2s cubic-bezier(0.23,1,0.32,1) infinite}
.m-stamp{animation:stamp 3.2s cubic-bezier(0.23,1,0.32,1) infinite}
.m-roll{animation:roll 3.2s cubic-bezier(0.23,1,0.32,1) infinite}
.m-zoom{animation:zoomTile 3.6s cubic-bezier(0.32,0.72,0,1) infinite alternate;transform-origin:30% 40%}
.m-chip{animation:chipFill 3.6s ease-out infinite}
.m-tile{animation:tileIn 3.6s ease-out infinite}
.m-pull{animation:pull 3.2s cubic-bezier(0.23,1,0.32,1) infinite}
.m-heart{animation:heart 2.4s cubic-bezier(0.23,1,0.32,1) infinite;transform-origin:50% 50%}
@media (prefers-reduced-motion: reduce){[class^="m-"],[class*=" m-"]{animation:none !important}}`;
const stage = (inner, bg = '#ECECEF') => `<div style="position: relative; height: 210px; border-radius: 16px; overflow: hidden; background: ${bg}">${inner}</div>`;
const mcard = (no, title, status, demo, rows) => `<section style="${CARD}; padding: 22px; display: flex; flex-direction: column; gap: 14px">
<div style="display: flex; align-items: center; justify-content: space-between"><span style="display: flex; align-items: baseline; gap: 10px"><span style="font-family: ${SERIF}; font-style: italic; font-size: 22px">${no}</span><span style="font-size: 17px; font-weight: 600">${title}</span></span>${tag(status, status === '적용됨')}</div>
${demo}
<dl style="margin: 0; display: grid; grid-template-columns: 64px minmax(0, 1fr); gap: 6px 10px; font-size: 13px; line-height: 1.5">${rows.map(([k, v]) => `<dt style="color: ${MUTED}">${k}</dt><dd style="margin: 0; ${/^[0-9a-z(]/i.test(v) ? `font-family: ${MONO}; font-size: 12px` : ''}">${v}</dd>`).join('')}</dl>
</section>`;
const tile = (key, x, y, w, h, extra = '', cls = '') => `<span class="${cls}" style="position: absolute; left: ${x}px; top: ${y}px; width: ${w}px; height: ${h}px; overflow: hidden; border-radius: 6px${extra}">${cover(key, w, h, 0.5, 0.3, '', '')}</span>`;
board('BoardMotion', '모션', '04 · MOTION', 1640, `<p style="margin: -12px 0 0; font-size: 15px; line-height: 1.6; color: #44463E">자주 쓰는 동작일수록 짧고 조용하게, 하루 한 번인 순간에만 힘을 준다. 모든 견본은 반복 재생이고, 움직임 줄이기 설정에서는 멈춘다. 같은 값은 01 디자인 토큰의 곡선·시간을 쓴다.</p>
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 24px">
${mcard('01', '제호 녹아들기', '적용됨', stage(`${cover('dana', 300, 210, 0.58, 0.3, '; position: absolute; left: 0; top: 0', '')}<span class="m-meltpill" style="position: absolute; left: 50%; top: 20px; width: 74px; height: 30px; margin-left: -37px; border-radius: 15px; background: rgba(249, 249, 251, 0.86)"></span><span class="m-melt" style="position: absolute; left: 0; right: 0; top: 60px; text-align: center; font-family: ${SERIF}; font-size: 92px; line-height: 0.9; letter-spacing: -0.05em; color: ${INK}">Esel</span>`), [['계기', '위로 스크롤, 맨 위 360px 안'], ['값', '크기 0.14 → 1, smoothstep'], ['알약', 'p/0.18 안에 사라짐'], ['줄이면', '맨 위 도착 때 한 번에 바뀜']])}
${mcard('02', '작은 로고 나타남·숨김', '적용됨', stage(`${cover('kofi', 300, 210, 0.7, 0.3, '; position: absolute; left: 0; top: 0', '')}<span class="m-show" style="position: absolute; left: 50%; top: 24px; width: 108px; height: 46px; margin-left: -54px; border-radius: 23px; display: flex; align-items: center; justify-content: center; background: rgba(249, 249, 251, 0.86); font-family: ${SERIF}; font-size: 28px; letter-spacing: -1.4px; color: ${INK}">Esel<span style="color: #AE8775">.</span></span>`), [['계기', '위로 48px → 나타남, 아래로 18px → 숨김'], ['시간', '200ms ease-out'], ['속성', 'opacity, translateY(-12px)'], ['줄이면', '페이드만']])}
${mcard('03', '누름', '적용됨', stage(`<span class="m-press" style="position: absolute; left: 50%; top: 78px; width: 200px; height: 54px; margin-left: -100px; border-radius: 27px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 16px; font-weight: 600">발행</span>`), [['계기', '누르는 동안'], ['값', 'scale 0.97'], ['시간', '160ms ease-out'], ['범위', '모든 버튼과 링크']])}
${mcard('04', '로그인 바 올라옴', '적용됨', stage(`${cover('ama', 300, 210, 0.5, 0.6, '; position: absolute; left: 0; top: 0', '')}<span class="m-login esel-glass" style="position: absolute; left: 16px; right: 16px; bottom: 16px; height: 54px; box-sizing: border-box; padding: 6px; border-radius: 27px; display: flex; gap: 6px"><span style="flex: 1 1 0; border-radius: 21px; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 1.5px ${INK}; font-size: 13px; font-weight: 600">로그인</span><span style="flex: 1.35 1 0; border-radius: 21px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 13px; font-weight: 600">내 잡지 만들기</span></span>`), [['계기', '비로그인, 640px 지나면'], ['값', 'translateY(140%) → 0'], ['시간', '360ms drawer'], ['줄이면', '제자리에서 페이드']])}
${mcard('05', '표지 → 펼침면', '제안', stage(`<span class="m-spreadtext" style="position: absolute; left: 150px; top: 108px; right: 16px; font-family: ${SERIF}; font-size: 20px; line-height: 1.2; color: ${INK}">난간에 기대서,<br>셔츠 하나로.</span><span class="m-spread" style="position: absolute; left: 70px; top: 0; width: 160px; height: 210px; overflow: hidden">${cover('dana', 160, 210, 0.58, 0.4, '', '')}</span>`, PAPER), [['계기', '‘펼쳐 보기’'], ['값', '사진이 첫 사진 자리로 줄며 이동, 글은 140ms 뒤 8px 위로'], ['시간', '360ms drawer · 돌아올 때 260ms'], ['줄이면', '200ms 크로스페이드']])}
${mcard('06', '오늘의 색 짜내기', '제안', stage(`<span style="position: absolute; left: 0; right: 0; top: 40px; display: flex; flex-direction: column; align-items: center; gap: 4px">${['camel', 'lilac', 'olive'].map((c, i) => `<span class="m-squeeze" style="animation-delay: ${i * 60}ms; display: block">${paint(c, 150, '', '')}</span>`).join('')}</span>`, PAPER), [['계기', '그날 처음 볼 때 한 번'], ['값', 'clip-path inset(0 100% 0 0) → 0'], ['시간', '520ms ease-out · 60ms 간격'], ['줄이면', '200ms 페이드']])}
${mcard('07', '발행 · 창간', '제안', stage(`<span class="m-stamp" style="position: absolute; left: 50%; top: 20px; width: 118px; height: 170px; margin-left: -59px; overflow: hidden; box-shadow: 0 10px 24px rgba(41, 42, 39, 0.2)">${cover(ME, 118, 170, 0.5, 0.5, '', '')}<span style="position: absolute; left: 0; right: 0; top: 6px; text-align: center; font-family: ${SERIF}; font-size: 40px; line-height: 0.9; letter-spacing: -0.05em; color: #FFFFFF">${ME}</span></span><span style="position: absolute; right: 18px; bottom: 18px; height: 20px; overflow: hidden; font-family: ${MONO}; font-size: 14px; color: ${INK}"><span class="m-roll" style="display: flex; flex-direction: column"><span style="height: 20px">Nº 011</span><span style="height: 20px">Nº 012</span></span></span>`, PAPER), [['계기', '‘발행’ · ‘창간하기’, 하루 한 번'], ['값', '0.96배 도장 두 번 → 호수 위로 넘김'], ['시간', '160ms × 2 · 240ms ease-out · 합 600ms 이내'], ['줄이면', '도장 없이 숫자만 바뀜']])}
${mcard('08', '가판대 표지 확대', '제안', stage(`<span class="m-zoom" style="position: absolute; left: 0; top: 0; width: 300px; height: 210px; overflow: hidden">${cover('riva', 300, 210, 0.5, 0.2, '', '')}<span style="position: absolute; left: 0; right: 0; top: 4px; text-align: center; font-family: ${SERIF}; font-size: 80px; line-height: 0.9; letter-spacing: -0.05em; color: #FFFFFF">Esel</span></span>`, PAPER), [['계기', '작은 표지를 누름'], ['값', '누른 자리에서 커짐 · 닫으면 그 자리로'], ['시간', '320ms drawer · 닫힘 240ms'], ['줄이면', '200ms 크로스페이드']])}
${mcard('09', '같은 색 열림', '제안', stage(`<span style="position: absolute; left: 18px; top: 18px; width: 96px; height: 38px; border-radius: 19px; overflow: hidden; display: flex; white-space: nowrap"><span style="flex: 1 1 0; height: 38px; padding: 0 14px 0 8px; display: flex; align-items: center; gap: 4px; background: #FFFFFF; box-shadow: inset 0 0 0 1px #E0E1DC; font-size: 14px">${icon('lock', 16, 1.7)}<span>카멜</span></span><span class="m-chip" style="position: absolute; left: 0; top: 0; right: 0; bottom: 0; display: flex; align-items: center; gap: 4px; padding: 0 14px 0 8px; background: ${PAINT.camel.hex}; font-size: 14px; font-weight: 600">${paint('camel', 32, '', '')}카멜</span></span>${[0, 1, 2].map((i) => tile(['selin', 'leo', 'noor'][i], 18 + i * 92, 70, 84, 120, `; animation-delay: ${i * 40}ms`, 'm-tile')).join('')}`, PAPER), [['계기', '오늘 호 발행 직후, 하루 한 번'], ['값', '자물쇠가 빠지며 칩이 그 색으로 칠해지고, 흐린 책등이 표지로 12px 위로'], ['시간', '400ms · 표지 300ms, 40ms 간격'], ['줄이면', '칠하기 없이 페이드']])}
${mcard('10', '당겨서 다음 호', '제안', stage(`${cover('theo', 300, 210, 0.5, 0.45, '; position: absolute; left: 0; top: 0', '')}<span class="m-pull" style="position: absolute; left: 0; right: 0; top: 8px; text-align: center; font-family: ${SERIF}; font-size: 86px; line-height: 0.9; letter-spacing: -0.05em; color: #FFFFFF">Esel</span>`), [['계기', '맨 위에서 아래로 당김'], ['값', '당긴 거리 × 0.4 · 놓으면 스프링'], ['시간', 'spring 0.45s · bounce 0.15'], ['줄이면', '스프링 없이 바로 새 호']])}
${mcard('11', '하트', '제안', stage(`<span style="position: absolute; left: 50%; top: 66px; margin-left: -40px; color: ${INK}"><svg class="m-heart" width="80" height="80" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round" aria-hidden="true"><path d="M12 20.3l-1.2-1.1C6.2 15 3.5 12.5 3.5 9.4 3.5 7 5.4 5 7.8 5c1.6 0 3.2.9 4.2 2.2C13 5.9 14.6 5 16.2 5c2.4 0 4.3 2 4.3 4.4 0 3.1-2.7 5.6-7.3 9.8L12 20.3z"></path></svg></span>`, PAPER), [['계기', '좋아요를 채울 때만'], ['값', 'scale 0.85 → 1'], ['시간', '200ms ease-out · 해제는 즉시'], ['하지 않음', '물감 튀김, 더블탭 큰 하트']])}
<section style="${CARD}; padding: 22px; display: flex; flex-direction: column; gap: 12px">
<span style="font-size: 17px; font-weight: 600">움직이지 않는 것</span>
${note('캡슐 메뉴 이동 · 화면 전환 · 안쪽 지면이 스크롤로 나타나는 효과 · 표지 사진 확대(켄 번스) · 시차 스크롤 · 전체/구독 밑줄 미끄러짐.')}
${note('이유: 하루 수십~수백 번 보는 동작이거나, 사람들이 옷을 보러 온 사진을 장식으로 움직이는 일이다.')}
</section>
</div>`, { css: motionCss });

for (const [name, html] of Object.entries(files)) fs.writeFileSync(path.join(OUT, `${name}.dc.html`), html);

if (process.argv.includes('--index')) {
  const f = path.join(OUT, 'canvas.json');
  const c = JSON.parse(fs.readFileSync(f, 'utf8'));
  for (const b of Object.values(c.boards)) if (!b.page) b.page = 'minimal';
  for (const n of Object.values(c.notes)) if (!n.page) n.page = 'minimal';
  const boards = { BoardMood: ['mood', '00 무드보드'], BoardTokens: ['tokens', '01 디자인 토큰'], BoardComponents: ['components', '02 컴포넌트'], BoardMotion: ['motion', '04 모션'] };
  for (const [name, [pid, title]] of Object.entries(boards)) {
    const file = `${name}.dc.html`;
    c.boards[file] = { x: 0, y: 0, w: W, h: sizes[name], page: pid, title, radius: 0 };
    if (!c.order.includes(file)) c.order.push(file);
  }
  const names = { mood: '00 무드보드', tokens: '01 디자인 토큰', components: '02 컴포넌트', cover: '03 화면 · 표지 SNS', join: '03 화면 · 로그인 · 창간', motion: '04 모션', feeds: '보관 · 피드 시안', atelier: '보관 · 아틀리에', minimal: '보관 · 미니멀' };
  c.pages = Object.entries(names).map(([id, name]) => ({ id, name }));
  c.launch = { view: 'canvas', page: 'mood' };
  fs.writeFileSync(f, JSON.stringify(c, null, 2) + '\n');
}
console.log('ok', Object.entries(files).map(([n, h]) => `${n}:${h.length}`).join(' '), JSON.stringify(sizes));
