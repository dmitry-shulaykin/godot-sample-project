extends Camera

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const ray_length = 1000
# Called when the node enters the scene tree for the first time.
func _ready():
	 pass
 
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		print('selected: ', get_object_under_mouse())
		#if result:
#			get_tree().call_group("units", "move_to", result.position)

func get_object_under_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = project_ray_origin(mouse_pos)
	var ray_to = ray_from + project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to)
	return selection