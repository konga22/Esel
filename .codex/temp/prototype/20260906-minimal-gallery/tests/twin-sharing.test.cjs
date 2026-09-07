const test=require('node:test');const assert=require('node:assert/strict');
const S=require('../src/twin-sharing.js');const M=require('../src/social-state.js');
const photo={src:'own.jpg'};const friend={src:'friend.jpg'};
const ready=()=>M.approveTwinColor(M.proposeTwinColor(M.acceptTwin(M.invite(M.create()),()=>.999),'sage'));
const both=()=>M.simulateFriendPost(M.publishTwin(ready(),photo),friend);
test('private by default; individual publication exposes only the owner photo',()=>{
 const state=both();const initial=S.create();assert.deepEqual(S.entries(initial,state.twin),[]);
 const solo=S.choose(initial,state.twin,'own','solo');assert.deepEqual(S.entries(solo,state.twin),[{id:'twin-own',actors:['own']}]);
 assert.equal(initial.own,'private');assert.equal(solo.friendTag,false);
 assert.equal(M.canView(state,{date:M.TODAY,paletteId:'sage'}),false);
});
test('joint requires both uploads and two explicit consents; rejection allows solo',()=>{
 const state=both();let s=S.choose(S.create(),state.twin,'own','joint');assert.deepEqual(S.entries(s,state.twin),[]);
 s=S.choose(s,state.twin,'friend','private');assert.deepEqual(S.entries(s,state.twin),[]);
 s=S.choose(s,state.twin,'own','solo');assert.equal(S.entries(s,state.twin)[0].id,'twin-own');
 s=S.choose(s,state.twin,'friend','joint');assert.equal(S.entries(s,state.twin)[0].id,'twin-own');
 s=S.choose(s,state.twin,'own','joint');assert.deepEqual(S.entries(s,state.twin),[{id:'twin-joint',actors:['own','friend']}]);
 s=S.choose(s,state.twin,'friend','private');assert.deepEqual(S.entries(s,state.twin),[]);
});
test('two solos remain two posts and replacing them with joint creates exactly one',()=>{
 const state=both();let s=S.choose(S.choose(S.create(),state.twin,'own','solo'),state.twin,'friend','solo');assert.equal(S.entries(s,state.twin).length,2);
 for(const actor of ['own','friend'])s=S.choose(s,state.twin,actor,'joint');
 assert.equal(S.entries(s,state.twin).length,1);
});
test('tag consent is independent, explicit, symmetric and revocable',()=>{
 const s=Object.freeze(S.create());const mine=S.tag(s,'own',true);assert.equal(mine.friendTag,false);assert.equal(mine.own,'private');
 const theirs=S.tag(mine,'friend',true);assert.equal(theirs.friendTag,true);assert.equal(S.tag(theirs,'friend',false).friendTag,false);
 assert.throws(()=>S.tag(s,'intruder',true));assert.throws(()=>S.tag(s,'own','true'));
});
test('missing uploads and invalid transitions fail without mutation',()=>{
 const initial=M.create();assert.throws(()=>S.choose(S.create(),initial.twin,'own','solo'));
 const own=M.publishTwin(ready(),photo);assert.throws(()=>S.choose(S.create(),own.twin,'own','joint'));
 assert.throws(()=>S.choose(S.create(),own.twin,'friend','solo'));
 assert.throws(()=>S.choose(S.create(),own.twin,'own','invalid'));
 assert.equal(S.choose(S.create(),own.twin,'own','solo').own,'solo');
});
