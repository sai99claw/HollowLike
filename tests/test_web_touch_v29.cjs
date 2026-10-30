// Exercise the actual browser control script without requiring a WebGL context.
const fs=require('node:fs'), vm=require('node:vm'), assert=require('node:assert/strict');
class Element {
  constructor(id=''){this.id=id;this.handlers={};this.style={};this.hidden=false;this.dataset={};this.classes=new Set();this.classList={add:x=>this.classes.add(x),remove:x=>this.classes.delete(x)};}
  addEventListener(type,fn){(this.handlers[type]??=[]).push(fn);}
  dispatch(type,values={}){const e={pointerId:1,clientX:84,clientY:364,preventDefault(){},...values};for(const fn of this.handlers[type]??[])fn(e);}
  appendChild(node){if(node.id==='pigeon-touch')root=node;}
  set innerHTML(_){this.stick=new Element('pt-stick');this.knob=new Element('pt-knob');this.buttons=['sub','attack','dash','jump','heal'].map(a=>{const b=new Element();b.dataset.action=a;return b;});}
  querySelector(selector){return selector==='#pt-stick'?this.stick:this.knob;}
  querySelectorAll(selector){return selector==='[data-action]'?this.buttons:this.buttons.filter(b=>b.classes.has('active'));}
  setPointerCapture(){}
  getBoundingClientRect(){return{left:20,top:300,width:128,height:128};}
}
let root;
const doc=new Element(), win=new Element();doc.head=new Element();doc.body=new Element();doc.createElement=()=>new Element();win.visualViewport=new Element();
vm.runInNewContext(fs.readFileSync(require('node:path').join(__dirname,'../web_touch_v29.js'),'utf8'),{document:doc,window:win});
const api=win.PigeonTouch,events=[];api.attach(data=>events.push(JSON.parse(data)));api.setVisible(true);
const held=a=>events.filter(e=>e.action===a).at(-1)?.pressed??false;
assert.equal(root.hidden,false);
root.stick.dispatch('pointerdown',{pointerId:7,clientX:148});
root.buttons[3].dispatch('pointerdown',{pointerId:8});root.buttons[1].dispatch('pointerdown',{pointerId:9});
assert(held('right')&&held('jump')&&held('attack'));
root.buttons[3].dispatch('pointerup',{pointerId:8});assert(!held('jump')&&held('right')&&held('attack'));
root.buttons[1].dispatch('pointerdown',{pointerId:10});root.buttons[1].dispatch('pointerup',{pointerId:9});assert(held('attack'));
root.buttons[1].dispatch('pointercancel',{pointerId:10});assert(!held('attack'));
root.stick.dispatch('pointermove',{pointerId:7,clientX:84,clientY:300});assert(held('up')&&!held('right'));
root.stick.dispatch('lostpointercapture',{pointerId:7});assert(!held('up'));
root.buttons[4].dispatch('pointerdown',{pointerId:11});api.setVisible(false);assert(!held('heal')&&root.hidden);
api.setVisible(true);root.buttons[2].dispatch('pointerdown',{pointerId:12});win.dispatch('blur');assert(!held('dash'));
root.buttons[0].dispatch('pointerdown',{pointerId:13});win.visualViewport.dispatch('resize');assert(!held('sub'));
api.detach();assert(root.hidden);
console.log('PASS web touch: multitouch, independent release, cancellation, menu hide, blur and screen resize');
