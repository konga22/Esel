// Optional browser evidence: NODE_PATH=<Playwright installation> node <this file>
const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
(async () => {
  const browser = await chromium.launch({channel:'chrome',headless:true});
  try {
    for (const width of [393,320]) {
      const page = await browser.newPage({viewport:{width,height:width===393?852:740},deviceScaleFactor:1});
      const errors=[]; page.on('pageerror',e=>errors.push(e.message));
      await page.clock.install();
      await page.goto('http://localhost:4177/?scenario=rare&feed=all');
      const ids=()=>page.locator('#post-list .post').evaluateAll(items=>items.map(p=>p.id));
      assert.deepEqual(await page.locator('[data-filter]').allTextContents(),['전체','같은 색']);
      const first=await ids();
      assert.deepEqual(first,['post-sora-2026-09-06','post-elle-2026-09-06','post-haru-2026-09-06','post-sora-2026-09-05']);
      await page.locator('#post-list .post-photo').first().evaluate(img=>img.decode());
      await page.screenshot({path:path.join(__dirname,`../screenshots/feed-unified-${width}.png`)});
      await page.clock.fastForward(31000);
      assert.deepEqual(await ids(),first); // no timer-driven reordering
      await page.locator('[data-screen="feed"]').evaluate(el=>{el.scrollTop=el.scrollHeight;});
      await page.waitForFunction(()=>document.querySelectorAll('#post-list .post').length===8);
      const next=await ids();
      assert.deepEqual(next.slice(0,4),first);
      assert.equal(next[7],'post-mina-2026-09-03'); // highest unseen mock popularity
      await page.locator('[data-screen="feed"]').evaluate(el=>{el.scrollTop=0;});
      await page.clock.runFor(500);
      await page.locator('[data-filter="same"]').click();
      assert.equal(await page.locator('#post-list .post-photo').count(),0);
      await page.locator('#post-list [data-action="compose"]').click();
      await page.locator('[data-action="use-sample"]').click();
      await page.waitForFunction(()=>!document.querySelector('[data-action="publish"]').disabled);
      await page.locator('[data-action="publish"]').click();
      assert.equal(await page.locator('#post-list .post-photo').count(),2);
      await page.locator('[data-filter="all"]').click();
      assert.equal((await ids())[0],'post-my-daily-2026-09-06');
      assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth));
      assert.deepEqual(errors,[]);
      console.log(`${width}px: combined feed, 30s blend, stable prefix, lock/publish and width passed`);
      await page.close();
    }
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
