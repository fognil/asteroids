class_name ScreenWrap
## Utility for wrapping objects around the viewport edges.

static func wrap_position(pos: Vector2, margin: float = 0.0) -> Vector2:
	var vp_size := _get_viewport_size()
	var new_pos := pos
	
	if new_pos.x < -margin:
		new_pos.x = vp_size.x + margin
	elif new_pos.x > vp_size.x + margin:
		new_pos.x = -margin
	
	if new_pos.y < -margin:
		new_pos.y = vp_size.y + margin
	elif new_pos.y > vp_size.y + margin:
		new_pos.y = -margin
	
	return new_pos

static func _get_viewport_size() -> Vector2:
	# Use the actual visible viewport size, which respects stretch mode "expand"
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_visible_rect().size
	# Fallback to project settings
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)

## Helper for other scripts to get viewport size without hardcoding 1920×1080
static func get_viewport_size() -> Vector2:
	return _get_viewport_size()
