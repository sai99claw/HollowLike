/* Local-only performance capture UI. No network or gameplay storage access. */
(()=>{
 'use strict';
 const doc=document,make=(tag,id,text)=>{const e=doc.createElement(tag);if(id)e.id=id;if(text)e.textContent=text;return e;};
 const style=make('style');style.textContent=`#pperf-tools{position:fixed;right:12px;bottom:48px;z-index:10002;display:flex;gap:6px}#pperf-tools button,#pperf-panel button{font:14px system-ui,sans-serif;padding:8px 12px;border:1px solid #91b9b2;border-radius:7px;background:#163b37;color:#e6f2e5;cursor:pointer;margin:0}#pperf-tools button[data-recording="true"]{background:#773d3b}#pperf-cover{position:fixed;inset:0;background:#071c24cc;z-index:10003;display:grid;place-items:center}#pperf-cover[hidden]{display:none}#pperf-panel{box-sizing:border-box;width:min(820px,94vw);max-height:92vh;overflow:auto;background:#173731;color:#e3eee5;border:1px solid #8eafa2;border-radius:12px;padding:20px;font:15px/1.6 system-ui,sans-serif;text-align:left}#pperf-panel h2{margin:0;font-size:22px;letter-spacing:1px}#pperf-panel p{margin:10px 0}#pperf-panel textarea{box-sizing:border-box;width:100%;height:40vh;background:#0b2526;color:#e8f5e8;font:12px/1.4 monospace;resize:vertical;border:1px solid #69958b;border-radius:6px;padding:10px}#pperf-actions{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}#pperf-panel button:disabled{opacity:.45;cursor:default}#pperf-note{min-height:24px;color:#f2d597}@media(max-width:600px){#pperf-tools{top:68px;bottom:auto}#pperf-panel{padding:14px}}`;
 doc.head.appendChild(style);
 const tools=make('div','pperf-tools'),toggle=make('button','pperf-toggle','效能紀錄'),mark=make('button','pperf-mark','標記卡頓');mark.hidden=true;tools.append(toggle,mark);doc.body.appendChild(tools);
 const cover=make('div','pperf-cover');cover.hidden=true;const panel=make('section','pperf-panel');panel.setAttribute('role','dialog');panel.setAttribute('aria-modal','true');panel.setAttribute('aria-label','效能紀錄');cover.appendChild(panel);doc.body.appendChild(cover);
 panel.appendChild(make('h2',null,'效能紀錄'));
 panel.appendChild(make('p',null,'開始後正常玩 30～60 秒：先在空房停留約 10 秒，再走動、換房或戰鬥。卡頓時可點「標記卡頓」。最長錄製 120 秒，停止後把下方整份報告貼回聊天。'));
 const actions=make('div','pperf-actions'),start=make('button','pperf-start','開始錄製'),copy=make('button','pperf-copy','複製整份報告'),download=make('button','pperf-download','下載 TXT'),close=make('button','pperf-close','關閉');actions.append(start,copy,download,close);panel.appendChild(actions);
 const note=make('p','pperf-note');note.setAttribute('role','status');panel.appendChild(note);
 const text=make('textarea','pperf-report');text.readOnly=true;text.setAttribute('aria-label','效能報告');panel.appendChild(text);
 panel.appendChild(make('p',null,'僅記錄效能、房間狀態與繪圖環境；不含帳號、存檔、網址參數，也不會自動上傳。GPU 耗時若無法量測會標示未知。'));
 let command=null,recording=false,started=0,report='',visibilityEvents=[];
 doc.addEventListener('visibilitychange',()=>{if(recording&&visibilityEvents.length<16)visibilityEvents.push({t_ms:Date.now()-started,hidden:doc.hidden});});
 try{report=localStorage.getItem('pigeon-perf-last')||'';}catch{}
 const focusGame=()=>doc.getElementById('canvas')?.focus();
 function sync(){start.disabled=!command;copy.disabled=!report;download.disabled=!report;text.value=report;toggle.dataset.recording=String(recording);mark.hidden=!recording;}
 function send(kind){if(command)command(kind);}
 function open(){cover.hidden=false;send('panel');note.textContent=command?'按「開始錄製」後繼續玩，按右下「停止並顯示報告」即可結束。':'等待遊戲載入後可開始；先前完成的報告仍可複製。';sync();start.focus();}
 toggle.onclick=()=>{if(recording)send('stop');else open();};
 mark.onclick=()=>{send('mark');focusGame();};
 start.onclick=()=>{report='';sync();send('start');cover.hidden=true;focusGame();};
 close.onclick=()=>{cover.hidden=true;send('resume');focusGame();};
 cover.addEventListener('keydown',event=>{if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close.onclick();}});
 copy.onclick=async()=>{if(!report)return;try{await navigator.clipboard.writeText(report);note.textContent='已複製整份報告，直接貼回聊天即可。';}catch{text.focus();text.select();let ok=false;try{ok=doc.execCommand('copy');}catch{}note.textContent=ok?'已複製整份報告，直接貼回聊天即可。':'已選取報告，請按 Ctrl+C（Mac：⌘C）手動複製。';}};
 download.onclick=()=>{if(!report)return;const blob=new Blob([report],{type:'text/plain;charset=utf-8'}),url=URL.createObjectURL(blob),a=make('a');a.href=url;a.download='pigeon-perf-v043-'+new Date().toISOString().replace(/[:.]/g,'-')+'.txt';doc.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);note.textContent='已下載 TXT；也可直接複製報告貼回聊天。';};
 setInterval(()=>{if(recording){const seconds=Math.floor((Date.now()-started)/1000);toggle.textContent='● '+seconds+'秒｜停止並顯示報告';}},1000);
 function sample(){const canvas=doc.getElementById('canvas'),r=canvas?.getBoundingClientRect();return {hidden:doc.hidden,focused:doc.hasFocus(),visibility_events:visibilityEvents,dpr:window.devicePixelRatio||1,window_px:[window.innerWidth,window.innerHeight],canvas_px:canvas?[canvas.width,canvas.height]:null,canvas_css:r?[Math.round(r.width),Math.round(r.height)]:null};}
 function environment(){const result={...sample(),user_agent:navigator.userAgent,hardware_threads:navigator.hardwareConcurrency||null,gpu_time_ms:'unmeasured'};try{const gl=doc.getElementById('canvas')?.getContext('webgl2');if(gl){const ext=gl.getExtension('WEBGL_debug_renderer_info');result.webgl_renderer=gl.getParameter(ext?ext.UNMASKED_RENDERER_WEBGL:gl.RENDERER);result.webgl_vendor=gl.getParameter(ext?ext.UNMASKED_VENDOR_WEBGL:gl.VENDOR);result.software_renderer_hint=/swiftshader|llvmpipe|software/i.test(result.webgl_renderer);result.webgl_buffer_px=[gl.drawingBufferWidth,gl.drawingBufferHeight];}}catch{result.webgl_renderer='unavailable';}return JSON.stringify(result);}
 window.PigeonPerf={register(callback){command=callback;sync();},environment,sample:()=>JSON.stringify(sample()),status(active){recording=Boolean(active);if(recording){started=Date.now();visibilityEvents=[];}toggle.textContent=recording?'● 錄製中｜停止並顯示報告':'效能紀錄';sync();},show_report(value){report=String(value);recording=false;cover.hidden=false;toggle.textContent='效能紀錄';note.textContent='錄製完成。請按「複製整份報告」貼回聊天，或下載 TXT。';try{localStorage.setItem('pigeon-perf-last',report);}catch{}sync();},open};
 sync();
})();
