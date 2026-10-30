from pathlib import Path
import json,shutil
from release_budget import validate_budget
root=Path(__file__).resolve().parent.parent
dist=root/'dist';client=dist/'client';client.mkdir(exist_ok=True)
for p in list(dist.iterdir()):
 if p.is_file():shutil.move(str(p),str(client/p.name))
server=dist/'server';server.mkdir(exist_ok=True)
shutil.copy2(root/'server/index.js',server/'index.js')
shutil.copy2(root/'web_feedback_v30.js',client/'web_feedback_v30.js')
meta=dist/'.openai';meta.mkdir(exist_ok=True)
shutil.copy2(root/'.openai/hosting.json',meta/'hosting.json')
(server/'wrangler.json').write_text(json.dumps({'name':'pigeon-feedback','main':'index.js','compatibility_date':'2026-05-22','assets':{'directory':'../client','binding':'ASSETS','run_worker_first':['/api/*','/feedback']},'d1_databases':[{'binding':'DB','database_name':'pigeon-feedback','database_id':'00000000-0000-0000-0000-000000000000'}]}))
validate_budget(dist)
print('Worker, static client and D1 manifest staged')
