extends Resource
class_name MouseCursor

export var point:StreamTexture
export var click:StreamTexture
export var shape:int
export var hotspot:Vector2


func press():
	Input.set_custom_mouse_cursor(click,shape, hotspot)

func release():
	Input.set_custom_mouse_cursor(point,shape, hotspot)
