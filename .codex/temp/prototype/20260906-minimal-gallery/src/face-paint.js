// Local, opt-in compositing. No face/accessory detection or image upload.
window.EselFacePaint = (() => {
  function mount(host, photo, palette) {
    let mode='none', placed=false, x=.5, y=.25, size=.28, ready=false;
    const canvas=document.createElement('canvas');canvas.className='face-canvas';canvas.hidden=true;
    canvas.tabIndex=0;canvas.setAttribute('aria-label','얼굴 위치 선택. 방향키로 물감 이동');
    host.append(canvas);
    const controls=document.createElement('div');controls.className='face-tools';
    controls.innerHTML='<details><summary>얼굴 가리기</summary><p class="fine-print">모자·선글라스 착용 여부를 직접 선택해 주세요.</p><button type="button" data-mask="horizontal">미착용 · 수평</button><button type="button" data-mask="diagonal">미착용 · 대각선</button><button type="button" data-mask="none">착용함 / 가리지 않기</button><div class="mask-adjust" hidden><label>아크릴 크기 <input type="range" min="12" max="65" value="28" aria-label="아크릴 크기"></label><p class="mask-hint" role="status">사진에서 얼굴 중앙을 눌러 주세요. 위치와 크기를 확인한 뒤 게시하세요.</p></div><p class="fine-print">자동 인식이 아닌 직접 배치예요. 얼굴 식별 방지를 보장하지는 않아요.</p></details>';
    host.append(controls);
    const brush=new Image();brush.src='assets/paint-sage.png';
    let tinted;
    brush.onload=()=>{const c=document.createElement('canvas');c.width=brush.naturalWidth;c.height=brush.naturalHeight;const ctx=c.getContext('2d');ctx.drawImage(brush,0,0);const data=ctx.getImageData(0,0,c.width,c.height);const colors=(palette.maskColors||[palette.hex]).map(hex=>hex.match(/[a-f0-9]{2}/gi).map(v=>parseInt(v,16)));
      for(let i=0;i<data.data.length;i+=4){const r=data.data[i],g=data.data[i+1],b=data.data[i+2];const a=Math.min(1,Math.max(0,(235-Math.min(r,g,b))/25));const shade=.72+.28*((r+g+b)/765);const col=colors[Math.min(colors.length-1,Math.floor((i/4%c.width)/c.width*colors.length))];for(let j=0;j<3;j++)data.data[i+j]=col[j]*shade;data.data[i+3]*=a;}ctx.putImageData(data,0,0);const crop=document.createElement('canvas');let left=c.width,top=c.height,right=0,bottom=0;for(let p=0;p<data.data.length;p+=4){if(data.data[p+3]>32){const px=(p/4)%c.width,py=Math.floor(p/4/c.width);left=Math.min(left,px);right=Math.max(right,px);top=Math.min(top,py);bottom=Math.max(bottom,py);}}crop.width=Math.max(1,right-left+1);crop.height=Math.max(1,bottom-top+1);crop.getContext('2d').drawImage(c,left,top,crop.width,crop.height,0,0,crop.width,crop.height);tinted=crop;draw();};
    const image=host.querySelector('#draft-photo');
    function draw(){
      if(!image.naturalWidth)return;
      const scale=Math.min(1,1600/Math.max(image.naturalWidth,image.naturalHeight));canvas.width=Math.round(image.naturalWidth*scale);canvas.height=Math.round(image.naturalHeight*scale);
      const ctx=canvas.getContext('2d');ctx.drawImage(image,0,0,canvas.width,canvas.height);
      ready=!!tinted;
      if(mode!=='none'&&tinted){const width=canvas.width*size;ctx.save();ctx.translate(x*canvas.width,y*canvas.height);ctx.rotate(mode==='diagonal'?-Math.PI/8:0);ctx.drawImage(tinted,-width/2,-width*.25,width,width*.5);ctx.restore();}
    }
    image.addEventListener('load',draw);if(image.complete)draw();
    controls.addEventListener('click',e=>{const b=e.target.closest('[data-mask]');if(!b)return;mode=b.dataset.mask;canvas.hidden=mode==='none';image.hidden=mode!=='none';controls.querySelector('.mask-adjust').hidden=mode==='none';controls.querySelectorAll('[data-mask]').forEach(el=>el.setAttribute('aria-pressed',String(el===b)));draw();});
    controls.querySelector('input').addEventListener('input',e=>{size=Number(e.target.value)/100;draw();});
    function mark(){placed=true;controls.querySelector('.mask-hint').textContent='배치했어요. 얼굴이 충분히 가려졌는지 확인해 주세요.';draw();}
    canvas.addEventListener('pointerdown',e=>{const r=canvas.getBoundingClientRect();x=Math.max(0,Math.min(1,(e.clientX-r.left)/r.width));y=Math.max(0,Math.min(1,(e.clientY-r.top)/r.height));mark();});
    canvas.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key))return;e.preventDefault();x=Math.max(0,Math.min(1,x+(e.key==='ArrowRight'?.01:e.key==='ArrowLeft'?-.01:0)));y=Math.max(0,Math.min(1,y+(e.key==='ArrowDown'?.01:e.key==='ArrowUp'?-.01:0)));mark();});
    return {export(){if(mode==='none')return photo;if(!ready)throw new Error('아크릴을 불러오는 중이에요. 잠시 후 다시 시도해 주세요.');if(!placed)throw new Error('사진에서 얼굴 위치를 먼저 눌러 주세요.');draw();return {src:canvas.toDataURL('image/png'),kind:'masked',faceMask:{mode,x,y,size,color:palette.name}};}};
  }
  return {mount};
})();
