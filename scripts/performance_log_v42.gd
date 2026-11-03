class_name PerformanceLogV42
extends RefCounted
const VERSION:String="v0.43"
const MAX_SECONDS:float=120.0
const MAX_WINDOWS:int=180
const MAX_GAPS:int=8192
var active:bool=false
var started:int=0
var bucket_started:int=0
var previous_frame:int=-1
var frames:int=0
var bucket_frames:int=0
var gaps:Array[float]=[]
var gap_cursor:int=0
var bucket_gaps:Array[float]=[]
var gap_sum:float=0
var gap_count:int=0
var gap_max:float=0
var slow_count:int=0
var windows:Array[Dictionary]=[]
var marks:Array[Dictionary]=[]
var worst:Array[Dictionary]=[]
var totals:Dictionary={}
var bucket_spans:Dictionary={}
var metadata:Dictionary={}
var last_context:Dictionary={}
var last_report:String=""
func _now(value:int) -> int:return Time.get_ticks_usec() if value<0 else value
func start(info:Dictionary,context:Dictionary,now:int=-1) -> void:
	active=true;started=_now(now);bucket_started=started;previous_frame=-1;frames=0;bucket_frames=0;gap_cursor=0;gap_sum=0;gap_count=0;gap_max=0;slow_count=0
	gaps.clear();bucket_gaps.clear();windows.clear();marks.clear();worst.clear();totals.clear();bucket_spans.clear();last_report="";metadata=info.duplicate(true);last_context=context.duplicate(true)
func span(name:String,usec:int) -> void:
	if not active:return
	for destination:Dictionary in [totals,bucket_spans]:
		if not destination.has(name):destination[name]={"us":0.0,"calls":0,"max_us":0}
		var item:Dictionary=destination[name];item["us"]+=maxi(0,usec);item["calls"]+=1;item["max_us"]=maxi(int(item["max_us"]),usec)
func begin_frame(now:int=-1) -> void:
	if not active:return
	var current:int=_now(now)
	if previous_frame>=0:
		var gap:float=maxf(0,(current-previous_frame)/1000.0)
		gap_sum+=gap;gap_count+=1;gap_max=maxf(gap_max,gap)
		if gap>33.333:slow_count+=1
		if gaps.size()<MAX_GAPS:gaps.append(gap)
		else:gaps[gap_cursor]=gap;gap_cursor=(gap_cursor+1)%MAX_GAPS
		if bucket_gaps.size()<2048:bucket_gaps.append(gap)
		if worst.size()<10 or gap>float(worst[-1]["gap_ms"]):
			worst.append({"t_s":snappedf((current-started)/1000000.0,.001),"gap_ms":snappedf(gap,.001),"room":last_context.get("room",-1),"type":last_context.get("type",""),"screen":last_context.get("screen",""),"paused":last_context.get("paused",false)})
			worst.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a["gap_ms"])>float(b["gap_ms"]))
			if worst.size()>10:worst.resize(10)
	previous_frame=current;frames+=1;bucket_frames+=1
static func percentile(values:Array[float],fraction:float) -> float:
	if values.is_empty():return 0
	var sorted:Array[float]=values.duplicate();sorted.sort()
	return snappedf(sorted[clampi(ceili(sorted.size()*fraction)-1,0,sorted.size()-1)],.001)
func flush(context:Dictionary,now:int=-1) -> void:
	if not active:return
	var current:int=_now(now)
	if bucket_frames>0 or not bucket_spans.is_empty():
		var window:Dictionary=context.duplicate(true)
		window.merge({"t_s":snappedf((current-started)/1000000.0,.001),"span_s":maxf(.001,(current-bucket_started)/1000000.0),"frames":bucket_frames,"gap_p95_ms":percentile(bucket_gaps,.95),"cpu":bucket_spans.duplicate(true)},true)
		if windows.size()<MAX_WINDOWS:windows.append(window)
	last_context=context.duplicate(true);bucket_started=current;bucket_frames=0;bucket_gaps.clear();bucket_spans.clear()
func finish_frame(provider:Callable,now:int=-1) -> bool:
	if not active:return false
	var current:int=_now(now)
	if current-bucket_started>=1000000:flush(provider.call(),current)
	if current-started>=int(MAX_SECONDS*1000000) or windows.size()>=MAX_WINDOWS:
		stop(provider.call(),current);return true
	return false
func mark(context:Dictionary,kind:String="manual",now:int=-1) -> void:
	if not active:return
	var current:int=_now(now)
	if marks.size()<32:marks.append({"t_s":snappedf((current-started)/1000000.0,.001),"kind":kind,"room":context.get("room",-1),"type":context.get("type",""),"paused":context.get("paused",false)})
	flush(context,current)
static func cpu(window:Dictionary,name:String) -> float:
	return snappedf(float(window.get("cpu",{}).get(name,{}).get("us",0))/1000.0/maxi(1,int(window.get("frames",0))),.001)
func stop(context:Dictionary,now:int=-1) -> String:
	if not active:return last_report
	var current:int=_now(now);flush(context,current);active=false
	var seconds:float=maxf(.001,(current-started)/1000000.0)
	var lines:PackedStringArray=["=== PIGEON_PERF "+VERSION+" ===","ENV "+JSON.stringify(metadata),"SUMMARY "+JSON.stringify({"seconds":snappedf(seconds,.001),"frames":frames,"mean_fps":snappedf(frames/seconds,.01),"gap_mean_ms":snappedf(gap_sum/maxi(1,gap_count),.001),"gap_p50_ms":percentile(gaps,.50),"gap_p95_ms":percentile(gaps,.95),"gap_p99_ms":percentile(gaps,.99),"gap_max_ms":snappedf(gap_max,.001),"over_33ms_pct":snappedf(100.0*slow_count/maxi(1,gap_count),.01),"percentile_samples":gaps.size()}),"CPU_SPANS (inclusive; nested rows overlap, do not sum)","name\tms_per_render_frame\tms_per_call\tmax_call_ms\tcalls"]
	var names:Array=totals.keys();names.sort()
	for name:String in names:
		var item:Dictionary=totals[name]
		lines.append("%s\t%.3f\t%.3f\t%.3f\t%d"%[name,float(item["us"])/1000.0/maxi(1,frames),float(item["us"])/1000.0/maxi(1,int(item["calls"])),float(item["max_us"])/1000.0,int(item["calls"])])
	lines.append("SECONDS_JSONL (one snapshot per second/scene change; ms timings, MiB memory)")
	for window:Dictionary in windows:
		var row:Dictionary=window.duplicate(true);row.erase("cpu")
		row["fps"]=snappedf(float(window["frames"])/float(window["span_s"]),.01)
		row["process_ms_frame"]=cpu(window,"process.total");row["physics_ms_frame"]=cpu(window,"physics.total");row["draw_main_ms_frame"]=cpu(window,"draw.main")
		var cached:float=0
		for name:String in window["cpu"]:
			if name.begins_with("draw.cache") or name=="draw.actors":cached+=cpu(window,name)
		row["draw_cached_ms_frame"]=snappedf(cached,.001)
		lines.append(JSON.stringify(row))
	lines.append("MARKS "+JSON.stringify(marks));lines.append("WORST_FRAMES "+JSON.stringify(worst))
	lines.append("NOTE: CPU spans measure script work only. Frame gaps also include engine/render/driver/browser/VSync waits; GPU milliseconds are NOT measured. Zero VRAM counters may mean unsupported. Percentiles retain at most8192 frame intervals. No automatic upload.")
	lines.append("=== END PIGEON_PERF ===");last_report="\n".join(lines);return last_report
