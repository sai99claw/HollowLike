import {spawn,spawnSync} from 'node:child_process';
import {readdirSync,readFileSync} from 'node:fs';
const cli='node_modules/wrangler/bin/wrangler.js';
const env={...process.env,GOMAXPROCS:'2'};
for(const file of readdirSync('drizzle').filter(name=>name.endsWith('.sql'))){
 const sql=readFileSync('drizzle/'+file,'utf8').replaceAll('CREATE TABLE ','CREATE TABLE IF NOT EXISTS ').replaceAll('CREATE INDEX ','CREATE INDEX IF NOT EXISTS ');
 const result=spawnSync(process.execPath,[cli,'d1','execute','DB','--local','--config','wrangler.preview.json','--command',sql],{stdio:'inherit',env});if(result.status!==0)process.exit(result.status||1);
}
const incoming=process.argv.slice(2),portIndex=incoming.indexOf('--port');
const port=portIndex>=0?incoming[portIndex+1]:(process.env.PORT||'3000');
const child=spawn(process.execPath,[cli,'dev','--no-bundle','--config','wrangler.preview.json','--local','--ip','0.0.0.0','--port',port,'--inspector-port','0'],{stdio:'inherit',env});
for(const signal of ['SIGTERM','SIGINT'])process.on(signal,()=>child.kill(signal));child.on('exit',code=>process.exit(code??1));
