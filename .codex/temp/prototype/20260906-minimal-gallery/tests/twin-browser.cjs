// Optional: run with NODE_PATH pointing to a Playwright installation; uses installed Chrome.
const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
(async()=>{
  const browser=await chromium.launch({channel:'chrome',headless:true});
  try {
    for(const width of [393,320]) {
      const page=await browser.newPage({viewport:{width,height:width===393?852:740}});
      const errors=[]; page.on('pageerror',e=>errors.push(e.message));
      const click=action=>page.locator(`[data-action="${action}"]`).click();
      const friend=async action=>{await page.locator('#twin-content [data-action="demo-settings"]').click();await click(action);};
      const sample=async()=>{await click('use-sample');await page.waitForFunction(()=>!document.querySelector('[data-action="publish"]').disabled);await click('publish');};
      const shot=async name=>{await page.locator('#notice').waitFor({state:'hidden'});await page.screenshot({path:path.join(__dirname,`../screenshots/twin-${name}-${width}.png`)});};
      await page.goto('http://localhost:4177/?scenario=rare');
      // 320px: personal post already exists; 393px: twin must not create one.
      if(width===320){await click('compose');await sample();}
      await page.locator('.app-nav [data-nav="profile"]').click();await click('open-twin');
      assert.equal(await page.locator('#twin-content .paint-pair').count(),0);
      await click('invite');
      assert.ok((await page.locator('#twin-link').inputValue()).endsWith('?twin=invite'));
      assert.equal(await page.locator('[data-twin-color]').count(),0);
      await shot('invite');
      await friend('accept-twin');
      assert.equal(await page.locator('[data-twin-color]').count(),3);
      assert.equal(await page.locator('[data-action="propose-twin"]').isDisabled(),true);
      await page.locator('[data-twin-color="blue"]').click();
      await click('propose-twin');assert.equal(await page.locator('[data-action="twin-compose"]').count(),0);
      await friend('decline-twin');
      await page.locator('[data-twin-color="sage"]').click();
      await shot('choose');await click('propose-twin');
      await friend('approve-twin');
      assert.ok((await page.locator('.twin-palette').textContent()).includes('세이지'));
      // Different completion order at each width.
      if(width===320) await friend('friend-post');
      assert.equal(await page.locator('.twin-frame img').count(),0);
      await click('twin-compose');
      assert.ok((await page.locator('.compose-label').textContent()).includes('세이지'));
      await click('cancel-compose');
      await click('twin-compose');await sample();
      if(width===393){assert.equal(await page.locator('.twin-frame img').count(),0);await friend('friend-post');}
      assert.equal(await page.locator('.twin-frame img').count(),2);
      await page.locator('.twin-frame img').evaluateAll(imgs=>Promise.all(imgs.map(img=>img.decode())));
      await shot('shared-complete');
      assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth));
      assert.deepEqual(await page.locator('#twin-content button').evaluateAll(items=>items.filter(el=>{const r=el.getBoundingClientRect();return r.width<48||r.height<48;}).map(el=>el.textContent)),[]);
      await page.locator('.app-nav [data-nav="today"]').click();
      assert.equal(await page.locator('[data-select="rare"]').getAttribute('aria-pressed'),'true');
      assert.equal(await page.locator('[data-select="rare"]').isDisabled(),width===320);
      await page.locator('.app-nav [data-nav="feed"]').click();await page.locator('[data-filter="same"]').click();
      assert.equal(await page.locator('#post-list .post-photo').count(),width===320?1:0);
      assert.deepEqual(errors,[]);
      // Legacy color-bearing invite URLs cannot select/award a personal palette.
      await page.goto('http://localhost:4177/?twin=rare');
      assert.equal(await page.locator('[data-twin-color]').count(),0);
      await page.locator('.app-nav [data-nav="today"]').click();
      assert.equal(await page.locator('[data-select="sage"]').getAttribute('aria-pressed'),'true');
      console.log(`${width}px: invite → accept → propose/decline/approve → separate twin upload, reveal order and personal isolation passed`);
      await page.close();
    }
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
