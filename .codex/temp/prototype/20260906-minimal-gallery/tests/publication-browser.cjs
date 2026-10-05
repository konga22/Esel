const {chromium}=require('playwright');const assert=require('node:assert/strict');const path=require('node:path');
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});try{
 for(const width of [393,320]){
  const page=await browser.newPage({viewport:{width,height:width===393?852:740}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const click=a=>page.locator(`[data-action="${a}"]`).click();
  const tools=()=>page.locator('#twin-content [data-action="demo-settings"]').click();
  const back=async()=>{await page.locator('.app-nav [data-nav="profile"]').click();await click('open-twin');};
  const feed=()=>page.locator('.app-nav [data-nav="feed"]').click();
  const pub=async mode=>{await click('publication');await page.locator(`[data-public="${mode}"]`).click();await page.locator('#publication-dialog [data-close]').click();};
  const shot=async name=>{await page.locator('#notice').waitFor({state:'hidden'});await page.screenshot({path:path.join(__dirname,`../screenshots/publication-${name}-${width}.png`)});};
  await page.goto('http://localhost:4177/?scenario=rare');await back();await click('invite');await tools();await click('accept-twin');await page.locator('[data-twin-color="sage"]').click();await click('propose-twin');await tools();await click('approve-twin');
  await click('twin-compose');await click('use-sample');await page.waitForFunction(()=>!document.querySelector('[data-action="publish"]').disabled);await click('publish');await tools();await click('friend-post');
  await click('publication');await shot('options');await page.locator('#publication-dialog [data-close]').click();
  await pub('joint');await feed();assert.equal(await page.locator('.twin-public').count(),0);
  await back();await tools();await page.locator('[data-friend-public="private"]').click();await pub('solo');await feed();assert.equal(await page.locator('.twin-public').count(),1);assert.equal(await page.locator('.twin-public .post-photo').count(),1);assert.equal(await page.locator('.twin-public [data-member]').count(),0);
  await back();await tools();await click('friend-tag');await feed();
  const tag=page.locator('.twin-public [data-member="friend"]');assert.equal(await tag.textContent(),'@twin_friend');await tag.click();assert.equal(await page.locator('#member-dialog img').count(),0);await page.locator('#member-dialog [data-close]').click();
  await page.locator('.twin-public .post-photo').evaluate(img=>img.decode());await shot('solo-tag');
  await back();await click('publication');await click('own-tag');await page.locator('#publication-dialog [data-close]').click();await tools();await page.locator('[data-friend-public="solo"]').click();await feed();assert.equal(await page.locator('.twin-public').count(),2);assert.equal(await page.locator('.twin-public [data-member="own"]').count(),1);
  await back();await pub('joint');await tools();await page.locator('[data-friend-public="joint"]').click();await feed();assert.equal(await page.locator('.twin-public').count(),1);assert.equal(await page.locator('.twin-public .post-photo').count(),2);assert.equal(await page.locator('.twin-public [data-member]').count(),2);
  await page.locator('.twin-public .post-photo').evaluateAll(imgs=>Promise.all(imgs.map(img=>img.decode())));await shot('joint');
  await page.locator('.twin-public [data-member="friend"]').click();assert.equal(await page.locator('#member-dialog img').count(),1);await page.locator('#member-dialog [data-close]').click();
  await back();await tools();await click('friend-tag');await feed();assert.equal(await page.locator('.twin-public [data-member="friend"]').count(),0);
  await page.locator('[data-filter="same"]').click();assert.equal(await page.locator('#post-list .post-photo').count(),0);
  await back();await pub('private');await feed();await page.locator('[data-filter="all"]').click();assert.equal(await page.locator('.twin-public').count(),0);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth));assert.deepEqual(errors,[]);console.log(`${width}px: private/solo/joint, refusal, reciprocal tags/profiles, withdrawal and personal gate passed`);await page.close();
 }
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
