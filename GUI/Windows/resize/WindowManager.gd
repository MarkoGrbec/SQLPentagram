extends Control

var start : Vector2
var initialPosition : Vector2
var isMoving : bool
var isResizing : bool
var resizeX : bool
var resizeY : bool
var initialSize : Vector2
var id_window: int
@export var GrabThreshold := 20
@export var ResizeThreshold := 10
@export var border := 20
@export var min_window_size := Vector2(555, 222)

static var id_windows = {}

func last_sibling():
	get_parent().move_child(self, get_parent().get_child_count())

func set_id_window(id:int, text:String):
	reset_window_position()
	id_window = id
	if id_windows.has(id):
		g_man.mold_window.set_instructions_only([text, "window id:", id, "does not have unique id there for won't save it's position size correctly it conflicts with:", id_windows[id], get_stack()])
	else:
		id_windows[id] = text

func reset_window_position():
	var pos = get_global_position()
	if pos.x < border:
		pos.x = border
	if pos.y < border:
		pos.y = border
	set_position(pos)
	var newWidith = clamp(get_size().x, min_window_size.x, g_man.canvas_rect.size.x - get_global_rect().position.x - border)
	var newHeight = clamp(get_size().y, min_window_size.y, g_man.canvas_rect.size.y - get_global_rect().position.y - border)
	set_size(Vector2(newWidith, newHeight))

func _input(event):
#region button down
	if Input.is_action_just_pressed("LeftMouseButton"):
		var rect = get_global_rect()
		var localMousePos = event.position - get_global_position()
		var left_right = localMousePos.x > 0 && localMousePos.x < rect.size.x
		var up_down = localMousePos.y > 0 && localMousePos.y < rect.size.y
#region drag
		if localMousePos.y < GrabThreshold && localMousePos.y > -ResizeThreshold && left_right:
			reset_window_position()
			# set it as last sibling
			last_sibling()
			start = event.position
			initialPosition = get_global_position()
			isMoving = true
#endregion drag
#region resize
		else:
			if abs(localMousePos.x - rect.size.x) < ResizeThreshold && up_down:
				reset_window_position()
				start.x = event.position.x
				initialSize.x = get_size().x
				resizeX = true
				isResizing = true
			
			if abs(localMousePos.y - rect.size.y) < ResizeThreshold && left_right:
				reset_window_position()
				start.y = event.position.y
				initialSize.y = get_size().y
				resizeY = true
				isResizing = true
			
			if localMousePos.x < ResizeThreshold &&  localMousePos.x > -ResizeThreshold && up_down:
				reset_window_position()
				start.x = event.position.x
				initialPosition.x = get_global_position().x
				initialSize.x = get_size().x
				isResizing = true
				resizeX = true
				
			if localMousePos.y < ResizeThreshold &&  localMousePos.y > -ResizeThreshold && left_right:
				reset_window_position()
				start.y = event.position.y
				initialPosition.y = get_global_position().y
				initialSize.y = get_size().y
				isResizing = true
				resizeY = true
#endregion resize
#endregion button down
#region button hold
	if Input.is_action_pressed("LeftMouseButton"):
		if isMoving:
			var position_x = clamp(initialPosition.x + (event.position.x - start.x), border, g_man.canvas_rect.size.x - get_global_rect().size.x - border)
			var position_y = clamp(initialPosition.y + (event.position.y - start.y), border, g_man.canvas_rect.size.y - get_global_rect().size.y - border)
			set_position(Vector2(position_x, position_y))
		if isResizing:
			var newWidith = get_size().x
			var newHeight = get_size().y
			
			#right sizing
			if resizeX:
				newWidith = clamp(initialSize.x - (start.x - event.position.x), min_window_size.x, g_man.canvas_rect.size.x - get_global_rect().position.x - border)
			if resizeY:
				newHeight = clamp(initialSize.y - (start.y - event.position.y), min_window_size.y, g_man.canvas_rect.size.y - get_global_rect().position.y - border)
			
			#left sizing AGAIN
			if initialPosition.x != 0:
				var right_offset = g_man.canvas_rect.size.x - initialPosition.x - initialSize.x
				newWidith = initialSize.x + (initialPosition.x - (clamp(event.position.x, border, g_man.canvas_rect.size.x - right_offset - min_window_size.x)))
				
				set_position(Vector2(clamp(initialPosition.x - (newWidith - initialSize.x), border, g_man.canvas_rect.size.x - right_offset - min_window_size.x), get_position().y))
			
			## it gets here does by resizing on top ##TODO clamp
			#if initialPosition.y != 0:
				#newHeight = initialSize.y + (start.y - event.position.y)
				#set_position(Vector2(get_position().x, initialPosition.y - (newHeight - initialSize.y)))
			
			set_size(Vector2(newWidith, newHeight))
			
#endregion button hold
#region button released
	if Input.is_action_just_released("LeftMouseButton"):
			
		isMoving = false
		initialPosition = Vector2(0,0)
		resizeX = false
		resizeY = false
		isResizing = false
#endregion button released

func set_min_size():
	set_size(min_window_size)
