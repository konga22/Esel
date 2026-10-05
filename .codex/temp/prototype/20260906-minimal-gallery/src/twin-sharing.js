(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.EselTwinSharing=api;})(globalThis,function(){
  'use strict';
  const create=()=>({own:'private',friend:'private',ownTag:false,friendTag:false});
  function choose(sharing,twin,actor,mode){
    if(!['own','friend'].includes(actor)||!['private','solo','joint'].includes(mode))throw new Error('올바른 공개 방식을 골라 주세요.');
    if(mode!=='private'&&(twin.status!=='ready'||!twin[actor+'Post']))throw new Error('내 트윈 사진을 먼저 남겨 주세요.');
    if(mode==='joint'&&(!twin.ownPost||!twin.friendPost))throw new Error('둘 다 사진을 남긴 뒤 함께 공개할 수 있어요.');
    return {...sharing,[actor]:mode};
  }
  function tag(sharing,actor,allowed){
    if(!['own','friend'].includes(actor)||typeof allowed!=='boolean')throw new Error('태그 동의를 확인해 주세요.');
    return {...sharing,[actor+'Tag']:allowed};
  }
  function entries(sharing,twin){
    if(twin.status!=='ready')return [];
    const valid=actor=>twin[actor+'Post']?.photo?.src && twin[actor+'Post'].paletteId===(actor==='own'?twin.paletteId:twin.friendPaletteId);
    if(sharing.own==='joint'&&sharing.friend==='joint'&&valid('own')&&valid('friend'))return [{id:'twin-joint',actors:['own','friend']}];
    return ['own','friend'].filter(actor=>sharing[actor]==='solo'&&valid(actor)).map(actor=>({id:'twin-'+actor,actors:[actor]}));
  }
  return {create,choose,tag,entries};
});
