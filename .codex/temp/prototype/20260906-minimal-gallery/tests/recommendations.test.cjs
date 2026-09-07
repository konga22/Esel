const test=require('node:test');const assert=require('node:assert/strict');const M=require('../src/social-state.js');
test('each person receives three colors with exactly one shared recommendation',()=>{
 for(let n=0;n<50;n++){const s=M.acceptTwin(M.invite(M.create()));const r=s.twin.recommendations;assert.equal(new Set(r.own).size,3);assert.equal(new Set(r.friend).size,3);assert.deepEqual(r.own.filter(c=>r.friend.includes(c)),[s.twin.sharedId]);const old=JSON.stringify(r);M.proposeTwinColor(s,r.own[1]);assert.equal(JSON.stringify(r),old);}
});
test('different recommended colors can be selected and published without changing personal color',()=>{
 let s=M.acceptTwin(M.invite(M.create()),()=>.999);s=M.proposeTwinColor(s,'blue');s=M.approveTwinColor(s,'violet');s=M.publishTwin(s,{src:'own'});s=M.simulateFriendPost(s,{src:'friend'});assert.equal(M.twinVisible(s),true);assert.equal(s.twin.ownPost.paletteId,'blue');assert.equal(s.twin.friendPost.paletteId,'violet');assert.equal(s.selected,'sage');assert.equal(s.post,null);
});
test('unknown or other-person-only recommendations cannot be selected',()=>{
 const s=M.acceptTwin(M.invite(M.create()),()=>.999);assert.throws(()=>M.proposeTwinColor(s,'violet'));const p=M.proposeTwinColor(s,'blue');assert.throws(()=>M.approveTwinColor(p,'blue'));assert.throws(()=>M.acceptTwin(M.invite(M.create()),()=>1));
});
