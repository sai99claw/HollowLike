import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
function fixture(){
 const elements=new Map(),storage=new Map(),commands=[],copies=[],downloads=[];
 class Element{
  constructor(tag){this.tag=tag;this.children=[];this.dataset={};this.hidden=false;this.disabled=false;this.value='';this.textContent='';this.listeners={};}
  set id(v){this._id=v;elements.set(v,this);}get id(){return this._id;}
  append(...items){this.children.push(...items);}appendChild(v){this.append(v);return v;}setAttribute(k,v){this[k]=v;}addEventListener(k,fn){this.listeners[k]=fn;}focus(){this.focused=true;}select(){this.selected=true;}remove(){this.removed=true;}click(){if(this.tag==='a')downloads.push(this);else this.onclick?.();}
 }
 const canvas=new Element('canvas');canvas.id='canvas';canvas.width=1280;canvas.height=720;canvas.getBoundingClientRect=()=>({width:1920,height:1080});canvas.getContext=()=>({RENDERER:1,VENDOR:2,drawingBufferWidth:1280,drawingBufferHeight:720,getExtension:()=>null,getParameter:k=>k===1?'Test GPU':'Test vendor'});
 const doc={listeners:{},addEventListener(k,fn){this.listeners[k]=fn;},head:new Element('head'),body:new Element('body'),hidden:false,hasFocus:()=>true,createElement:t=>new Element(t),getElementById:id=>elements.get(id),execCommand:()=>true};
 const scope={window:{innerWidth:1920,innerHeight:1080,devicePixelRatio:2},document:doc,navigator:{userAgent:'Test Browser',hardwareConcurrency:8,clipboard:{writeText:async text=>copies.push(text)}},localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},setInterval:()=>0,setTimeout:fn=>fn(),Blob,URL:{createObjectURL:()=> 'blob:local-test',revokeObjectURL:()=>{}},Date,Math,JSON};
 vm.runInNewContext(readFileSync(new URL('../web_performance_v42.js',import.meta.url),'utf8'),scope);
 return {api:scope.window.PigeonPerf,elements,storage,commands,copies,downloads,scope};
}
test('record, marker, stop, copy and local download use the bridge without network',async()=>{
 const f=fixture();f.api.register(kind=>f.commands.push(kind));f.elements.get('pperf-toggle').click();assert.equal(f.elements.get('pperf-cover').hidden,false);assert.deepEqual(f.commands,['panel']);
 f.elements.get('pperf-start').click();assert.equal(f.commands.at(-1),'start');assert.equal(f.elements.get('pperf-cover').hidden,true);
 f.api.status(true);assert.equal(f.elements.get('pperf-mark').hidden,false);f.elements.get('pperf-mark').click();assert.equal(f.commands.at(-1),'mark');
 f.elements.get('pperf-toggle').click();assert.equal(f.commands.at(-1),'stop');
 f.api.show_report('=== PIGEON_PERF\ncomplete report\n=== END PIGEON_PERF ===');assert.equal(f.storage.size,1);assert.equal(f.elements.get('pperf-copy').disabled,false);
 await f.elements.get('pperf-copy').onclick();assert.equal(f.copies.length,1);assert.match(f.copies[0],/complete report/);
 f.elements.get('pperf-download').click();assert.equal(f.downloads.length,1);assert.match(f.downloads[0].download,/\.txt$/);
 f.elements.get('pperf-close').click();assert.equal(f.commands.at(-1),'resume');
});
test('environment reports actual canvas pixels and software-renderer hints',()=>{
 const f=fixture(),env=JSON.parse(f.api.environment());assert.deepEqual(env.canvas_px,[1280,720]);assert.deepEqual(env.canvas_css,[1920,1080]);assert.equal(env.dpr,2);assert.equal(env.gpu_time_ms,'unmeasured');assert.equal(env.webgl_renderer,'Test GPU');assert.equal('url' in env,false);
});
test('denied clipboard has a manual selection fallback',async()=>{
 const f=fixture();f.api.show_report('report');f.scope.navigator.clipboard.writeText=async()=>{throw Error('denied');};f.scope.document.execCommand=()=>false;
 await f.elements.get('pperf-copy').onclick();assert.equal(f.elements.get('pperf-report').selected,true);assert.match(f.elements.get('pperf-note').textContent,/Ctrl\+C/);
});
test('missing WebGL and storage do not break controls',()=>{
 const f=fixture();f.elements.get('canvas').getContext=()=>null;assert.equal(JSON.parse(f.api.environment()).gpu_time_ms,'unmeasured');assert.equal(f.elements.get('pperf-start').disabled,true);
 f.scope.localStorage.setItem=()=>{throw Error('blocked');};f.api.show_report('still available');assert.equal(f.elements.get('pperf-report').value,'still available');
});

test('hidden-tab intervals remain visible after returning to the game',()=>{
 const f=fixture();f.api.status(true);f.scope.document.hidden=true;f.scope.document.listeners.visibilitychange();f.scope.document.hidden=false;f.scope.document.listeners.visibilitychange();
 const sample=JSON.parse(f.api.sample());assert.equal(sample.hidden,false);assert.deepEqual(sample.visibility_events.map(x=>x.hidden),[true,false]);
});
