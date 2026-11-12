const reply=(data,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
const page='<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>枝間鴿行・意見反饋</title><body style="background:#142d2c"><script src="/web_feedback_v30.js"></script><script>PigeonFeedback.open();</script></body></html>';
export default {async fetch(request,env){
 const url=new URL(request.url);
 if(url.pathname==='/feedback'&&request.method==='GET')return new Response(page,{headers:{'Content-Type':'text/html;charset=utf-8','Cache-Control':'no-store'}});
 if(url.pathname!='/api/feedback')return env.ASSETS.fetch(request);
 if(request.method!=='POST')return reply({error:'只接受提交意見。'},405);
 if(request.headers.get('origin')!==url.origin)return reply({error:'請從遊戲頁面送出。'},403);
 if(!request.headers.get('content-type')?.includes('application/json'))return reply({error:'格式錯誤。'},415);
 const reader=request.body?.getReader();if(!reader)return reply({error:'請填寫意見。'},400);
 let size=0,chunks=[];while(true){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>12000){await reader.cancel();return reply({error:'內容太長。'},413);}chunks.push(value);}
 let input;try{const bytes=new Uint8Array(size);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length;}input=JSON.parse(new TextDecoder().decode(bytes));}catch{return reply({error:'格式錯誤。'},400);}
 if(!input||typeof input!=='object'||Array.isArray(input))return reply({error:'格式錯誤。'},400);
 const message=typeof input.message==='string'?input.message.trim():'';
 const nickname=typeof input.nickname==='string'?input.nickname.trim():'';
 const category=['問題回報','操作與手感','美術與音效','玩法建議','其他'].includes(input.category)?input.category:'其他';
 if(message.length<3||message.length>2000||nickname.length>40)return reply({error:'意見請填3～2000字；暱稱最多40字。'},400);
 const id=typeof input.id==='string'&&/^[a-f0-9-]{36}$/.test(input.id)?input.id:crypto.randomUUID();
 try{await env.DB.prepare('INSERT INTO player_feedback (id,nickname,category,message,version,created_at) VALUES (?,?,?,?,?,?) ON CONFLICT(id) DO NOTHING').bind(id,nickname||'匿名玩家',category,message,'v0.77',new Date().toISOString()).run();return reply({ok:true,id});}catch{return reply({error:'暫時無法儲存，請稍後再試。'},503);}
}};
