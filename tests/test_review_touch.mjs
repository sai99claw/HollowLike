import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
class Element {
  constructor(action='') { this.dataset={action};this.style={};this.listeners={};this.classList={add(){},remove(){}}; }
  addEventListener(type,handler){this.listeners[type]=handler;}
  setPointerCapture(){}
  getBoundingClientRect(){return {left:0,top:0,width:200,height:200};}
}
const stick=new Element(),knob=new Element();
const buttons=['sub','attack','dash','jump','heal'].map(a=>new Element(a));
const root=new Element();root.querySelector=s=>s==='#pt-stick'?stick:knob;
root.querySelectorAll=s=>s==='[data-action]'?buttons:[];
const document={head:{appendChild(){}},body:{appendChild(){}},createElement:tag=>tag==='style'?new Element():root,addEventListener(){}};
const window={addEventListener(){}};
vm.runInNewContext(fs.readFileSync(new URL('../web_touch_v29.js',import.meta.url),'utf8'),{window,document,Math,Map});
const held={};window.PigeonTouch.attach(json=>{const {action,pressed}=JSON.parse(json);held[action]=pressed;});window.PigeonTouch.setVisible(true);
const point=(x,y)=>({pointerId:1,clientX:100+x*100,clientY:100+y*100,preventDefault(){}});
stick.listeners.pointerdown(point(.8,-.8));
assert.equal(held.right,true);assert.equal(!!held.up,false,'diagonal touch must not block horizontal dash with Up');
stick.listeners.pointermove(point(0,-1));assert.equal(held.up,true,'deliberate vertical gesture still interacts/aims up');
stick.listeners.pointermove(point(.8,.8));assert.equal(held.down,true,'Down remains active so Down+C cannot accidentally dash forward');
stick.listeners.pointerup(point(.8,.8));
for(const action of ['left','right','up','down'])assert.equal(!!held[action],false,'release clears '+action);
console.log('Review web touch directions: passed');
