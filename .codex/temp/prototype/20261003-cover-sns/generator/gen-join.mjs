// Logged-out cover → login → your first canvas (J1–J7). Screen words follow the 10-18 art-tool vocabulary.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { SANS, SERIF, MONO, INK, PAPER, MUTED, HAIR, PAINT, PEOPLE, ME, TODAY_CANDIDATES, ROOT, cover, faceStroke, cropStroke, neckDown, crop, paint, icon, masthead, mastSize, page } from './lib.mjs';
import { mastLayer, scrollLogic } from './scroll.mjs';
import { scrollCover, inner, faceLogic } from './gen-cover2.mjs';

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'project');
const files = {};
const me = PEOPLE[ME];
const btnDark = (label, href, extra = '') => `<a href="${href}" style="height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; gap: 8px; background: ${INK}; color: ${PAPER}; font-size: 16px; font-weight: 600${extra}">${label}</a>`;
const btnLine = (label, href, extra = '') => `<a href="${href}" style="height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: inset 0 0 0 1.5px ${INK}; color: ${INK}; font-size: 16px; font-weight: 600${extra}">${label}</a>`;
const steps = (n, back) => `<header style="position: relative; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="${back}" aria-label="이전" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('left', 24)}</a>
<span style="font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">첫 캔버스 ${n} / 4</span>
</header>
<div aria-hidden="true" style="display: flex; gap: 4px; padding: 0 20px">${[1, 2, 3, 4].map((i) => `<span style="flex: 1 1 0; height: 2px; border-radius: 1px; background: ${i <= n ? INK : '#D8D9D3'}"></span>`).join('')}</div>`;

// J1 비로그인 스크롤
const teaser = `<section aria-label="맛보기 끝" style="position: relative; height: 430px; overflow: hidden">
<span aria-hidden="true" style="position: absolute; left: -20px; top: -20px; filter: blur(16px); opacity: 0.85">${cover('kofi', 433, 470, 0.65, 0.15, '', '')}</span>
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; bottom: 0; background: linear-gradient(rgba(249, 249, 251, 0.15), ${PAPER} 78%)"></div>
<div style="position: absolute; left: 28px; right: 28px; top: 170px; text-align: center">
<p style="margin: 0; font-family: ${SERIF}; font-size: 27px; line-height: 1.3">오늘의 캔버스는 아직<br>열두 쪽이 더 남았어요.</p>
<p style="margin: 12px 0 0; font-size: 14px; line-height: 1.55; color: ${MUTED}">로그인하면 끝까지 보고, 내 스케치북도 만들 수 있어요.</p>
</div>
</section>`;
const sc = scrollLogic({ loginAt: 640 });
files.JoinScroll = page('첫 캔버스 1 비로그인 표지', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<div class="esel-scroll" ref="{{setScroller}}" onScroll="{{onScroll}}" style="position: absolute; left: 0; top: 0; width: 100%; height: 100%; overflow-y: auto; overscroll-behavior: contain; scrollbar-width: none">
${scrollCover({ withTabs: false })}
${inner({ key: 'ama', no: '02', py: 0.3 })}
${inner({ key: 'lise', no: '03', style: 'paint', py: 0.25 })}
${teaser}
<div aria-hidden="true" style="height: 120px"></div>
</div>
${mastLayer}
<div ref="{{setLogin}}" class="esel-glass" style="position: absolute; left: 16px; right: 16px; bottom: 34px; height: 66px; box-sizing: border-box; padding: 8px; border-radius: 33px; display: flex; gap: 8px; transform: translateY(140%); opacity: 0; pointer-events: none">
<a href="JoinLogin.dc.html" style="flex: 1 1 0; height: 50px; border-radius: 25px; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 1.5px ${INK}; font-size: 15px; font-weight: 600">로그인</a>
<a href="JoinColor.dc.html" style="flex: 1.35 1 0; height: 50px; border-radius: 25px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">내 스케치북 만들기</a>
</div>
</div>`, sc);

// J2 로그인
const option = (label, glyph, dark = false) => `<button type="button" style="height: 54px; border-radius: 27px; display: flex; align-items: center; justify-content: center; gap: 10px; font-size: 16px; font-weight: 600; ${dark ? `background: ${INK}; color: ${PAPER}` : `background: #FFFFFF; color: ${INK}; box-shadow: inset 0 0 0 1px #D8D9D3`}">${glyph}<span>${label}</span></button>`;
files.JoinLogin = page('첫 캔버스 2 로그인', `<div style="${ROOT(`background: #C9D3DC; color: ${INK}`)}">
${cover('dana', 393, 852, 0.58, 0.5, '; position: absolute; left: 0; top: 0', '')}
${masthead('Esel', INK)}
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; right: 0; bottom: 0; background: rgba(20, 20, 18, 0.32)"></div>
<section aria-label="로그인" class="esel-glass" style="position: absolute; left: 0; right: 0; bottom: 0; box-sizing: border-box; padding: 10px 20px 40px; border-radius: 28px 28px 0 0; display: flex; flex-direction: column; gap: 10px">
<span aria-hidden="true" style="align-self: center; width: 36px; height: 4px; border-radius: 2px; background: rgba(41, 42, 39, 0.25)"></span>
<div style="display: flex; align-items: center; justify-content: space-between; margin-top: 4px">
<h1 style="margin: 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400">Esel에 들어가기</h1>
<a href="JoinScroll.dc.html" aria-label="닫기" style="width: 48px; height: 48px; margin-right: -12px; display: flex; align-items: center; justify-content: center">${icon('x', 22)}</a>
</div>
<p style="margin: 0 0 6px; font-size: 14px; line-height: 1.55; color: #55574F">오늘의 표지를 끝까지 보고, 구독한 스케치북을 모아 봐요.</p>
${option('Apple로 계속하기', icon('apple', 20, 1.6), true)}
${option('Google로 계속하기', '')}
${option('이메일로 계속하기', icon('mail', 20, 1.6))}
<div style="display: flex; align-items: center; gap: 12px; margin: 8px 0 2px; font-size: 13px; color: ${MUTED}"><span style="flex: 1 1 0; height: 1px; background: #D3D4CE"></span><span>처음이라면</span><span style="flex: 1 1 0; height: 1px; background: #D3D4CE"></span></div>
<a href="JoinColor.dc.html" style="height: 50px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 16px; font-weight: 600"><span>내 스케치북 만들기</span>${icon('arrow', 18, 1.8)}</a>
<p style="margin: 0; font-size: 12px; line-height: 1.5; color: ${MUTED}; text-align: center">계속하면 [이용약관]과 [개인정보 처리방침]에 동의하게 돼요.</p>
</section>
</div>`);

// J3 첫 캔버스의 색
const TODAY = TODAY_CANDIDATES;
const colorBtn = (c) => `<button type="button" aria-pressed="{{${c}Pressed}}" onClick="{{pick_${c}}}" style="height: 92px; display: flex; align-items: center; gap: 16px; padding: 0 18px; border-radius: 22px; background: {{${c}Bg}}; box-shadow: {{${c}Ring}}">
${paint(c, 120, '', '')}
<span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 18px; font-weight: 600">${PAINT[c].name}</span><span style="font-family: ${SERIF}; font-style: italic; font-size: 16px; color: ${MUTED}">${PAINT[c].en}</span></span>
<span style="margin-left: auto; width: 26px; height: 26px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: {{${c}Dot}}; color: ${PAPER}">${icon('check', 16, 2.2)}</span>
</button>`;
files.JoinColor = page('첫 캔버스 3 색', `<div style="${ROOT(`padding-top: 54px; background: ${PAPER}; color: ${INK}`)}">
${steps(1, 'JoinLogin.dc.html')}
<div style="padding: 26px 20px 0">
<p style="margin: 0; font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em; color: ${MUTED}">2026. 9. 6. 오늘의 색</p>
<h1 style="margin: 8px 0 0; font-family: ${SERIF}; font-size: 36px; font-weight: 400; line-height: 1.2">첫 캔버스는<br>어떤 색으로 할까요?</h1>
<p style="margin: 12px 0 0; font-size: 15px; line-height: 1.55; color: #55574F">고른 색의 옷·양말·가방 무엇이든 좋아요. 그 색으로 첫 사진을 찍어요.</p>
</div>
<div role="group" aria-label="오늘의 색" style="display: flex; flex-direction: column; gap: 10px; padding: 26px 20px 0">
${TODAY.map(colorBtn).join('\n')}
</div>
<div style="position: absolute; left: 20px; right: 20px; bottom: 46px">${btnDark('{{pickedLabel}} 찍기', 'JoinShoot.dc.html')}</div>
</div>`, { logic: `const picked = (this.state && this.state.picked) || 'camel';
const names = ${JSON.stringify(Object.fromEntries(TODAY.map((c) => [c, PAINT[c].name])))};
for (const c of ${JSON.stringify(TODAY)}) {
const on = picked === c;
vals[c + 'Pressed'] = on ? 'true' : 'false';
vals[c + 'Bg'] = on ? '#FFFFFF' : 'transparent';
vals[c + 'Ring'] = on ? 'inset 0 0 0 1.5px ${INK}, 0 6px 18px rgba(41, 42, 39, 0.08)' : 'inset 0 0 0 1px #E0E1DC';
vals[c + 'Dot'] = on ? '${INK}' : 'transparent';
vals['pick_' + c] = () => this.setState({ picked: c });
}
const nm = names[picked];
const jong = (nm.charCodeAt(nm.length - 1) - 0xac00) % 28;
vals.pickedLabel = nm + (jong === 0 || jong === 8 ? '로' : '으로');` });

// J4 촬영
files.JoinShoot = page('첫 캔버스 4 촬영', `<div style="${ROOT('background: #111210; color: #FFFFFF')}">
${cover(ME, 393, 852, 0.5, 0.5, '; position: absolute; left: 0; top: 0', '카메라 미리보기: 카멜 코트와 페도라 착장')}
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 200px; background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0))"></div>
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 280px; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.65))"></div>
<header style="position: absolute; left: 0; right: 0; top: 54px; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="JoinColor.dc.html" aria-label="이전" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('left', 24)}</a>
<span style="font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">첫 캔버스 2 / 4</span>
</header>
<div style="position: absolute; left: 0; right: 0; top: 112px; display: flex; justify-content: center">
<span class="esel-glass" style="height: 44px; padding: 0 16px 0 8px; border-radius: 22px; display: flex; align-items: center; gap: 4px; color: ${INK}; font-size: 14px; font-weight: 600">${paint('camel', 52, '', '')}<span>카멜이 보이게 찍어요</span></span>
</div>
<span aria-hidden="true" style="position: absolute; left: 34px; top: 190px; width: 325px; height: 470px; box-sizing: border-box; border: 1.5px solid rgba(255, 255, 255, 0.55); border-radius: 18px"></span>
<p style="position: absolute; left: 0; right: 0; bottom: 186px; margin: 0; text-align: center; font-size: 14px">얼굴은 다음 단계에서 가릴 수 있어요.</p>
<div style="position: absolute; left: 0; right: 0; bottom: 60px; display: flex; align-items: center; justify-content: space-around; padding: 0 30px">
<button type="button" aria-label="앨범에서 고르기" style="width: 52px; height: 52px; border-radius: 12px; overflow: hidden; box-shadow: 0 0 0 2px #FFFFFF">${crop('freya', 52, 52, 1, 0.5, 0.4, 26, 26, { alt: '' })}</button>
<a href="JoinName.dc.html" aria-label="촬영" style="width: 82px; height: 82px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 4px #FFFFFF"><span style="width: 66px; height: 66px; border-radius: 50%; background: #FFFFFF"></span></a>
<button type="button" aria-label="카메라 전환" style="width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: rgba(255, 255, 255, 0.18)">${icon('flip', 24, 1.7)}</button>
</div>
</div>`);

// J5 사인 정하기
const PV = { W: 260, H: 386 };
files.JoinName = page('첫 캔버스 5 사인', `<div style="${ROOT(`padding-top: 54px; background: ${PAPER}; color: ${INK}`)}">
${steps(3, 'JoinShoot.dc.html')}
<h1 style="margin: 20px 20px 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1.2">사인을 정해요</h1>
<div style="position: absolute; left: ${(393 - PV.W) / 2}px; top: 166px; width: ${PV.W}px; height: ${PV.H}px; overflow: hidden; background: #EDEEEA; color: ${INK}; box-shadow: 0 14px 36px rgba(41, 42, 39, 0.2)">
${cover(ME, PV.W, PV.H, 0.5, 0.5)}
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 45%; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></span>
<span aria-hidden="true" style="position: absolute; left: 10px; right: 10px; top: 8px; color: #FFFFFF; display: flex; justify-content: space-between; font-family: ${MONO}; font-size: 8px; letter-spacing: 0.06em"><span>ESEL</span><span>Nº 001 · 첫 캔버스</span></span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 20px; text-align: center; font-family: ${SERIF}; font-size: {{mastPx}}; line-height: 0.9; letter-spacing: -0.05em; padding-right: 4px; white-space: nowrap; color: #FFFFFF">{{mastText}}</span>
</div>
<div style="position: absolute; left: 20px; right: 20px; top: 572px; display: flex; flex-direction: column">
<label for="mast-name" style="font-size: 12px; line-height: 16px; color: ${MUTED}">영문 닉네임 · 표지 사인이 돼요</label>
<input id="mast-name" type="text" value="{{name}}" onChange="{{onName}}" maxlength="10" autocomplete="off" autocapitalize="none" spellcheck="false" style="height: 52px; box-sizing: border-box; padding: 0; border: 0; border-bottom: 1.5px solid ${INK}; border-radius: 0; background: transparent; font-family: ${SERIF}; font-size: 28px">
<p style="margin: 8px 0 0; font-size: 13px; color: ${MUTED}">{{hint}}</p>
</div>
<div style="position: absolute; left: 20px; right: 20px; bottom: 46px">${btnDark('다음', 'JoinFace.dc.html')}</div>
</div>`, { logic: `const name = (this.state && this.state.name != null) ? this.state.name : '${ME}';
const shown = name || 'esel';
vals.name = name;
vals.mastText = shown;
vals.mastPx = Math.min(140, Math.floor((${PV.W} * 0.9) / (shown.length * 0.47))) + 'px';
vals.hint = name.length < 2 ? '영문 소문자 2~10자로 적어요.' : name + ' — 쓸 수 있는 이름이에요.';
vals.onName = (e) => this.setState({ name: String(e.target.value || '').toLowerCase().replace(/[^a-z]/g, '').slice(0, 10) });` });

// J6 얼굴 연출: 자르기 하나(그대로 · 사인 뒤로 · 목 아래) + 물감 한 획 켜기·끄기. 목 아래면 물감은 꺼진다.
const FW = { W: 210, H: 310 };
const fzoom = [FW.W, FW.H, 1.9, me.fx, me.fy, FW.W / 2, FW.H * 0.21];
const cropCard = (k, title, sub) => `<button type="button" aria-pressed="{{${k}Pressed}}" onClick="{{pick${k}}}" style="height: 64px; min-width: 0; padding: 0 10px; border-radius: 16px; display: flex; flex-direction: column; align-items: flex-start; justify-content: center; gap: 2px; background: {{${k}Bg}}; color: {{${k}Fg}}; box-shadow: inset 0 0 0 1.5px ${INK}"><span style="font-size: 15px; font-weight: 600; white-space: nowrap">${title}</span><span style="font-size: 12px; opacity: 0.8; white-space: nowrap">${sub}</span></button>`;
const onOff = (label, k) => `<button type="button" aria-pressed="{{${k}Pressed}}" onClick="{{pick${k}}}" aria-disabled="{{paintDisabled}}" style="height: 44px; flex: 1 1 0; display: flex; align-items: center"><span style="width: 100%; height: 36px; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; background: {{${k}Bg}}; color: {{${k}Fg}}; box-shadow: inset 0 0 0 1.5px ${INK}">${label}</span></button>`;
files.JoinFace = page('첫 캔버스 6 얼굴', `<div style="${ROOT(`padding-top: 54px; background: ${PAPER}; color: ${INK}`)}">
${steps(4, 'JoinName.dc.html')}
<h1 style="margin: 20px 20px 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1.2">얼굴은 어떻게 할까요?</h1>
<p style="margin: 6px 20px 0; font-size: 14px; color: #55574F">올릴 때마다 바꿀 수 있어요. 가려도 똑같이 멋져요.</p>
<div style="position: absolute; left: ${(393 - FW.W) / 2}px; top: 196px; width: ${FW.W}px; height: ${FW.H}px; overflow: hidden; background: #EDEEEA; color: ${INK}; box-shadow: 0 14px 36px rgba(41, 42, 39, 0.2)">
<span style="position: absolute; left: 0; top: 0; display: {{vPlain}}">${cover(ME, FW.W, FW.H, 0.5, 0.5)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vZoom}}">${crop(ME, ...fzoom)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vNeck}}">${neckDown(ME, FW.W, FW.H)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; top: 0; width: ${FW.W}px; height: ${FW.H}px; display: {{vPlainPaint}}">${faceStroke(ME, FW.W, FW.H, 0.5, 0.5)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; top: 0; width: ${FW.W}px; height: ${FW.H}px; display: {{vZoomPaint}}">${cropStroke(ME, ...fzoom)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 45%; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 14px; text-align: center; font-family: ${SERIF}; font-size: ${mastSize(ME, FW.W, 110)}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: 4px; color: {{mastColor}}">${ME}</span>
</div>
<div style="position: absolute; left: 20px; right: 20px; top: 518px; display: flex; flex-direction: column; gap: 8px">
<div role="group" aria-label="자르기" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px">
${cropCard('Plain', '그대로', '얼굴을 보여요')}
${cropCard('Zoom', '사인 뒤로', '사인으로 가려요')}
${cropCard('Neck', '목 아래', '옷만 보여요')}
</div>
<div style="height: 64px; box-sizing: border-box; padding: 0 6px 0 8px; border-radius: 16px; display: flex; align-items: center; gap: 6px; box-shadow: inset 0 0 0 1px ${HAIR}; opacity: {{paintRowOpacity}}">
${paint(me.color, 52, '', '')}
<span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 15px; font-weight: 600">물감 한 획</span><span style="font-size: 12px; color: #55574F">오늘의 색으로 눈을 가려요</span></span>
<div role="group" aria-label="물감 한 획" style="margin-left: auto; display: flex; gap: 6px; width: 116px">
${onOff('끔', 'Off')}
${onOff('켬', 'On')}
</div>
</div>
<p style="margin: 0; font-size: 12px; line-height: 18px; color: ${MUTED}; display: {{neckNote}}">목 아래는 얼굴이 없어 물감을 쓰지 않아요.</p>
</div>
<div style="position: absolute; left: 20px; right: 20px; bottom: 46px">${btnDark('첫 캔버스 올리기', 'JoinDone.dc.html')}</div>
</div>`, { logic: faceLogic({ crop: 'plain', paint: true }) });

// J7 첫 캔버스
files.JoinDone = page('첫 캔버스 7 첫 캔버스', `<div style="${ROOT(`background: #D9D2C6; color: ${INK}`)}">
<span style="position: absolute; left: 0; top: 0; width: 393px; height: 852px">${cover(ME, 393, 852, 0.5, 0.5)}${faceStroke(ME, 393, 852, 0.5, 0.5)}</span>
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 340px; background: linear-gradient(rgba(0, 0, 0, 0.42), rgba(0, 0, 0, 0))"></div>
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 420px; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.7))"></div>
<div style="position: absolute; left: 20px; right: 20px; top: 58px; display: flex; justify-content: space-between; font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em; color: #FFFFFF"><span>ESEL</span><span>Nº 001 · 첫 캔버스 · 2026. 9. 6.</span></div>
${masthead(ME, '#FFFFFF', { size: mastSize(ME, 393, 200), top: 84 })}
<div style="position: absolute; left: 20px; right: 20px; bottom: 46px; color: #FFFFFF">
<p style="margin: 0; font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">첫 캔버스를 축하해요</p>
<p style="margin: 8px 0 0; font-family: ${SERIF}; font-size: 30px; line-height: 1.25">${ME}의 첫 캔버스가<br>오늘 팔레트에 올라갔어요.</p>
<div style="display: flex; align-items: center; gap: 8px; margin: 12px 0 18px; font-size: 14px; font-weight: 600">${paint('camel', 56, '', '')}<span>카멜 · 같은 색 64명과 함께</span></div>
${btnDark('오늘의 표지 보러 가기', 'CoverScroll.dc.html', `; background: ${PAPER}; color: ${INK}`)}
<a href="CoverShelf.dc.html" style="height: 48px; margin-top: 6px; display: flex; align-items: center; justify-content: center; font-size: 15px; font-weight: 600">내 스케치북 보기</a>
</div>
</div>`);

for (const [name, html] of Object.entries(files)) fs.writeFileSync(path.join(OUT, `${name}.dc.html`), html);

if (process.argv.includes('--index')) {
  const f = path.join(OUT, 'canvas.json');
  const c = JSON.parse(fs.readFileSync(f, 'utf8'));
  if (!c.pages.some((p) => p.id === 'join')) c.pages.push({ id: 'join', name: '로그인 · 첫 캔버스' });
  const titles = { JoinScroll: 'J1 비로그인 표지 · 스크롤하면 로그인', JoinLogin: 'J2 로그인', JoinColor: 'J3 첫 캔버스의 색', JoinShoot: 'J4 촬영', JoinName: 'J5 사인 정하기', JoinFace: 'J6 얼굴 연출', JoinDone: 'J7 첫 캔버스' };
  Object.keys(files).forEach((name, i) => {
    const file = `${name}.dc.html`;
    c.boards[file] = { x: (i % 4) * 473, y: Math.floor(i / 4) * 1240, w: 393, h: 852, page: 'join', title: titles[name], is_interactive: true, radius: 28 };
    if (!c.order.includes(file)) c.order.push(file);
  });
  c.notes['join-title'] = { x: 0, y: -260, text: '로그인 · 첫 캔버스 — 표지를 보다가, 내 스케치북을 만든다', kind: 'title1', maxW: 1812, page: 'join' };
  c.launch = { view: 'canvas', page: 'join' };
  fs.writeFileSync(f, JSON.stringify(c, null, 2) + '\n');
}
console.log('ok', Object.entries(files).map(([n, h]) => `${n}:${h.length}`).join(' '));
