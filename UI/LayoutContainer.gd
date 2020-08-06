tool
extends Container
class_name LayoutContainer

enum ALIGN {
	BEGIN,
	CENTER
	END
}

export var vertical:bool = false setget set_vertical
export(ALIGN) var h_align = ALIGN.BEGIN setget set_h_align
export(ALIGN) var v_align = ALIGN.BEGIN setget set_v_align

func set_vertical(value:bool):
	vertical = value
	queue_sort()
func set_h_align(value:int):
	h_align = value
	queue_sort()
func set_v_align(value:int):
	v_align = value
	queue_sort()

class Lane extends Reference:
	var controls = []
	var size:float = 0.0
	var depth:float = 0.0

func is_block(c:Control) -> bool:
	if vertical:
		return bool(c.size_flags_vertical & SIZE_EXPAND)
	return bool(c.size_flags_horizontal & SIZE_EXPAND)

func _get_property_list():
	var constants = [
		"h_seperation",
		"v_seperation"
	]
	var props = []
	for constant in constants:
		var property = {
			name = "custom_constants/" + constant,
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "-16384,16384",
			usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_CHECKABLE
		}
		if get("custom_constants/" + constant) != null:
			property.usage |= PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_CHECKED
		props.append(property)
	return props

func _resort():
	rect_min_size = Vector2.ZERO
	var max_size:Vector2 = rect_size
	var max_size_comp = max_size.y if vertical else max_size.x
	# expanded elements take up a full row
	# non expanded elements act inline
	var lanes = [Lane.new()]
	var offset = 0.0
	var total_lane_size = 0.0
	
	var h_seperation_override = get("custom_constants/h_seperation")
	var v_seperation_override = get("custom_constants/v_seperation")
	
	var h_seperation = get_constant("h_seperation", "LayoutContainer")
	var v_seperation = get_constant("v_seperation", "LayoutContainer")
	
	if h_seperation_override != null:
		h_seperation = h_seperation_override
	if v_seperation_override != null:
		v_seperation = v_seperation_override
		
	var lane_seperation = h_seperation if vertical else v_seperation
	var item_seperation = v_seperation if vertical else h_seperation
	
	for child in get_children():
		var c = child as Control
		if not c or not c.is_visible_in_tree():
			continue
		if c.is_set_as_toplevel():
			continue
		
		var lane:Lane = lanes.back()
		
		var display_block = is_block(c)
		
		var size = c.get_combined_minimum_size()
			
		var c_lane_size = size.x if vertical else size.y
		
		if vertical and size.y > rect_min_size.y:
			rect_min_size.y = size.y
		if not vertical and size.x > rect_min_size.x:
			rect_min_size.x = size.x
		
		if display_block:
			offset = 0.0
			lane.depth = max_size_comp
			var new_lane = Lane.new()
			
			if lane.controls.empty():
				lane.controls.append(c)
				lane.size = c_lane_size
			else:
				new_lane.controls.append(c)
				new_lane.size = c_lane_size
				total_lane_size += new_lane.size + lane_seperation
				lanes.append(new_lane)
				new_lane = Lane.new()
			
			total_lane_size += lane.size + lane_seperation
			lanes.append(new_lane)
		else:
			var min_size_comp = size.y if vertical else size.x
			
			if offset + min_size_comp + item_seperation > max_size_comp:
				var new_lane = Lane.new()
				if lane.controls.empty():
					lane.controls.append(c)
					lane.depth = min_size_comp
				else:
					new_lane.controls.append(c)
					new_lane.depth += min_size_comp
					new_lane.size = c_lane_size
				total_lane_size += lane.size + lane_seperation
				
				lanes.append(new_lane)
				offset = min_size_comp
			else:
				offset += min_size_comp
				lane.depth += min_size_comp
				if not lane.controls.empty():
					offset += item_seperation
					lane.depth += item_seperation
				lane.controls.append(c)
				if c_lane_size > lane.size:
					lane.size = c_lane_size
	
	total_lane_size += lanes.back().size
	
	if vertical:
		rect_min_size.x = total_lane_size
	else:
		rect_min_size.y = total_lane_size
	
	var lane_offset = 0.0
	var flipped = false
	var lane_flipped = false
	var h_center = h_align == ALIGN.CENTER
	var v_center = v_align == ALIGN.CENTER
	
	if (vertical and v_align == ALIGN.END) or (not vertical and h_align == ALIGN.END):
		lane_flipped = true
	if (vertical and h_align == ALIGN.END) or (not vertical and v_align == ALIGN.END):
		flipped = true
		lane_offset = max_size.x if vertical else max_size.y
		lanes.invert()
	
	
	if (vertical and h_center) or (not vertical and v_center):
		lane_offset = max_size.x if vertical else max_size.y
		lane_offset = lane_offset*0.5 - total_lane_size*0.5
	
	for lane in lanes:
		
		if lane.controls.empty():
			continue
		
		if flipped:
			lane_offset -= lane.size + lane_seperation
		
		var rect:Rect2
		if vertical:
			rect = Rect2(lane_offset, 0.0, lane.size, 0)
			if lane_flipped:
				rect.position.y = max_size_comp
			if v_center:
				rect.position.y = (max_size_comp - lane.depth)*0.5
		else:
			rect = Rect2(0.0, lane_offset, 0, lane.size)
			if lane_flipped:
				rect.position.x = max_size_comp
			if h_center:
				rect.position.x = (max_size_comp - lane.depth)*0.5
			
		
		if lane.controls.size() == 1 and is_block(lane.controls[0]):
			if vertical:
				rect.size.y = max_size_comp
			else:
				rect.size.x = max_size_comp
			
			fit_child_in_rect(lane.controls[0], rect)
		else:
			if lane_flipped:
				lane.controls.invert()
			for c in lane.controls:
				var size = c.get_combined_minimum_size()
				var min_size_comp = size.y if vertical else size.x
				if vertical:
					rect.size.y = min_size_comp
				else:
					rect.size.x = min_size_comp
					
				if lane_flipped:
					if vertical:
						rect.position.y -= min_size_comp + item_seperation
					else:
						rect.position.x -= min_size_comp + item_seperation
				
				fit_child_in_rect(c, rect)
				
				if not lane_flipped:
					if vertical:
						rect.position.y += min_size_comp + item_seperation
					else:
						rect.position.x += min_size_comp + item_seperation
		
		if not flipped:
			lane_offset += lane.size + lane_seperation


func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN, NOTIFICATION_RESIZED:
			_resort()
		_:
			pass
	
