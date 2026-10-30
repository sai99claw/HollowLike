/* Screen-space controls: CSS pixels, independent of Godot camera and letterboxing. */
(() => {
  'use strict';
  const style = document.createElement('style');
  style.textContent = `
  #pigeon-touch{--u:clamp(48px,13vmin,70px);position:fixed;inset:0;z-index:6;pointer-events:none;user-select:none;-webkit-user-select:none;touch-action:none}
  #pigeon-touch[hidden]{display:none}
  #pigeon-touch .pt-button{margin:0;padding:0;width:var(--u);height:var(--u);border:1.5px solid #d9cda5ba;border-radius:50%;background:#0b202b99;color:#fff2d6;font:600 clamp(12px,3vmin,16px) system-ui,sans-serif;box-shadow:inset 0 0 14px #8bcbb015,0 2px 10px #07181466;pointer-events:auto;touch-action:none;outline:none;-webkit-tap-highlight-color:transparent}
  #pigeon-touch .pt-button.active{background:#649586cc;box-shadow:0 0 15px #acdfc266}
  #pt-actions{position:absolute;right:max(18px,env(safe-area-inset-right));bottom:max(16px,env(safe-area-inset-bottom));display:grid;grid-template-columns:repeat(2,var(--u));gap:10px}
  #pt-heal{position:absolute;right:max(18px,env(safe-area-inset-right));top:calc(max(16px,env(safe-area-inset-top)) + 42px)}
  #pt-stick{position:absolute;left:max(22px,env(safe-area-inset-left));bottom:max(20px,env(safe-area-inset-bottom));width:calc(var(--u)*1.95);height:calc(var(--u)*1.95);border-radius:50%;border:1.5px solid #cad7c99c;background:radial-gradient(circle,#4d726844,#10253588);box-shadow:inset 0 0 25px #030f2466;pointer-events:auto;touch-action:none}
  #pt-knob{position:absolute;inset:29%;border:1.5px solid #edf0c9bc;border-radius:50%;background:radial-gradient(circle at 35% 28%,#d8e3c9e0,#6e9c91e0);box-shadow:0 3px 10px #0005;pointer-events:none}
  #pt-stick::after{content:'↑';position:absolute;top:4%;left:45%;color:#f1ecd18a;font-size:15px;pointer-events:none}
  `;
  document.head.appendChild(style);
  const root = document.createElement('div');root.id='pigeon-touch';root.hidden=true;
  root.innerHTML='<div id="pt-stick" role="group" aria-label="虛擬搖桿"><div id="pt-knob"></div></div><div id="pt-actions"><button class="pt-button" data-action="sub">副武器</button><button class="pt-button" data-action="attack">主武器</button><button class="pt-button" data-action="dash">衝</button><button class="pt-button" data-action="jump">跳躍</button></div><button id="pt-heal" class="pt-button" data-action="heal">回血</button>';
  document.body.appendChild(root);
  let callback=null, stickId=null;
  const pressed=new Map(), fingers=new Map();
  const emit=(action,on)=>{if(!!pressed.get(action)===on)return;pressed.set(action,on);if(callback)callback(JSON.stringify({action,pressed:on}));};
  const stick=root.querySelector('#pt-stick'), knob=root.querySelector('#pt-knob');
  const resetStick=()=>{stickId=null;knob.style.transform='';['left','right','up','down'].forEach(a=>emit(a,false));};
  const releaseAll=()=>{fingers.clear();resetStick();for(const a of pressed.keys())emit(a,false);root.querySelectorAll('.active').forEach(b=>b.classList.remove('active'));};
  const moveStick=e=>{
    if(e.pointerId!==stickId)return;
    const r=stick.getBoundingClientRect(), radius=r.width/2;
    let x=(e.clientX-r.left-radius)/radius,y=(e.clientY-r.top-radius)/radius;
    const length=Math.hypot(x,y);if(length>1){x/=length;y/=length;}
    knob.style.transform='translate('+x*radius*.63+'px,'+y*radius*.63+'px)';
    emit('left',x<-.26);emit('right',x>.26);emit('up',y<-.48 && Math.abs(y)>Math.abs(x)*1.2);emit('down',y>.48);e.preventDefault();
  };
  stick.addEventListener('pointerdown',e=>{if(stickId!==null)return;stickId=e.pointerId;stick.setPointerCapture(e.pointerId);moveStick(e);});
  stick.addEventListener('pointermove',moveStick);
  ['pointerup','pointercancel','lostpointercapture'].forEach(type=>stick.addEventListener(type,e=>{if(e.pointerId===stickId)resetStick();}));
  root.querySelectorAll('[data-action]').forEach(button=>{
    const action=button.dataset.action;
    button.addEventListener('pointerdown',e=>{fingers.set(e.pointerId,action);button.setPointerCapture(e.pointerId);button.classList.add('active');emit(action,true);e.preventDefault();});
    const release=e=>{if(!fingers.has(e.pointerId))return;fingers.delete(e.pointerId);if(![...fingers.values()].includes(action)){emit(action,false);button.classList.remove('active');}e.preventDefault();};
    ['pointerup','pointercancel','lostpointercapture'].forEach(type=>button.addEventListener(type,release));
    button.addEventListener('contextmenu',e=>e.preventDefault());
  });
  window.addEventListener('blur',releaseAll);
  document.addEventListener('visibilitychange',()=>{if(document.hidden)releaseAll();});
  window.addEventListener('resize',releaseAll);
  window.visualViewport?.addEventListener('resize',releaseAll);
  window.PigeonTouch={attach(fn){releaseAll();callback=fn;},detach(){releaseAll();callback=null;root.hidden=true;},setVisible(on){if(!on)releaseAll();root.hidden=!on;},releaseAll};
})();
