class_name WorldPlacementV27
extends RefCounted
const INSET:=Vector2(0,10)
static func prop_base(base:Transform2D=Transform2D.IDENTITY) -> Transform2D:return base*Transform2D(0,INSET)
