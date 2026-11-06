class_name SanctuaryArt
extends RefCounted
const ROOT="res://assets/sanctuary_v12/"
const Room=preload("res://scripts/sanctuary_room.gd")
const Items=preload("res://scripts/world_item_art.gd")
static var manifest:Dictionary={}
static var sheets:Dictionary={}
static var textures:Dictionary={}
static func texture(id:String) -> Texture2D:
	if textures.has(id):return textures[id]
	if manifest.is_empty() and FileAccess.file_exists(ROOT+"manifest.json"):manifest=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	if not manifest.get("parts",{}).has(id):return null
	var definition:Dictionary=manifest["parts"][id];var file:String=definition["file"]
	if not sheets.has(file):sheets[file]=load(ROOT+file)
	var region:Array=definition["region"];var atlas:=AtlasTexture.new();atlas.atlas=sheets[file];atlas.region=Rect2(region[0],region[1],region[2],region[3]);textures[id]=atlas;return atlas
static func part(c:CanvasItem,id:String,rect:Rect2,tint:Color=Color.WHITE) -> bool:
	var tex:Texture2D=texture(id)
	if tex==null:return false
	c.draw_texture_rect(tex,rect,false,tint);return true
static func background(c:CanvasItem,room:Dictionary) -> void:
	if room.get("type","")=="merchant":
		part(c,"awning",Rect2(185,Room.FLOOR-445,1135,430),Color(1,1,1,.83));part(c,"sign",Rect2(62,Room.FLOOR-292,145,116))
	else:
		part(c,"sign",Rect2(1120,580,135,110),Color(.7,.88,.82,.5))
static func market(c:CanvasItem,stock:Array,player:Vector2,time:float,base:Transform2D,font:Font) -> void:
	c.draw_set_transform_matrix(base)
	for at in Room.TABLES:part(c,"table",Rect2(at-Vector2(165,102),Vector2(330,102)))
	var focused:int=Room.nearest_stock(stock,player)
	for i in stock.size():
		var item:Dictionary=stock[i];var at:Vector2=item["pos"]
		if item.get("sold",false):
			c.draw_arc(at+Vector2(0,16),17,0,TAU,20,Color(.58,.62,.56,.34),1,true);continue
		var color:=Color("b798ec") if item["kind"]=="rune" else Color("c4e8d9")
		if item["kind"]=="rune" and int(item["value"])>=11:color=Color("eaca7f")
		c.draw_circle(at,27,Color(color,.055));c.draw_circle(at,20,Color(color,.08))
		Items.draw_icon(c,Items.stock_icon(item),Rect2(at-Vector2(26,26)+Vector2(0,sin(time*1.4+i)*2),Vector2(52,52)),base)
		if focused==i:c.draw_arc(at,32,0,TAU,32,Color(color,.8),1.5,true)
		c.draw_string(font,at+Vector2(-17,41),str(item["price"])+"金",HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
static func dummy(c:CanvasItem,at:Vector2,_time:float,base:Transform2D,size:Vector2=Vector2(84,120),flash:bool=false) -> void:
	c.draw_set_transform_matrix(base)
	part(c,"dummy",Rect2(at-Vector2(size.x*.5,size.y),size),Color(1.8,1.8,1.8) if flash else Color.WHITE)
static func pool_back(c:CanvasItem,pool:Rect2,time:float,base:Transform2D) -> void:
	if pool.size.x<=0:return
	c.draw_set_transform_matrix(base)
	part(c,"pool_back",Rect2(pool.position-Vector2(25,58),Vector2(pool.size.x+50,67)))
	part(c,"water",Rect2(pool.position-Vector2(0,10),Vector2(pool.size.x,26)),Color(.8,1,1,.8))
	part(c,"steam",Rect2(pool.position-Vector2(-30,120+sin(time*.45)*5),Vector2(pool.size.x-60,105)),Color(1,1,1,.3))
static func pool_front(c:CanvasItem,pool:Rect2,_time:float,base:Transform2D) -> void:
	if pool.size.x<=0:return
	c.draw_set_transform_matrix(base)
	part(c,"pool_front",Rect2(pool.position+Vector2(-25,25),Vector2(pool.size.x+50,38)))

static var merchant_background:Texture2D
static var merchant_mid:Texture2D
static func merchant_far(c:CanvasItem) -> void:
	if merchant_background==null:merchant_background=load("res://assets/motion_v13/merchant-background.png")
	c.draw_texture_rect(merchant_background,Rect2(-80,-40,1760,1300),false,Color(.8,.88,.88,1))
static func merchant_middle(c:CanvasItem) -> void:
	if merchant_mid==null:merchant_mid=load("res://assets/motion_v13/merchant-middle.png")
	c.draw_texture_rect(merchant_mid,Rect2(-100,-20,1800,1230),false,Color(1,1,1,.72))
