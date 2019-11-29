extends KinematicBody

puppet var slave_pos : Vector3 = Vector3()
puppet var slave_dir : Vector3 = Vector3()
puppet var slave_motion : Vector3 = Vector3()

var gravity : Vector3 = Vector3.DOWN * 12.0
var speed : float = 4.0
var current_anim = ""
var velocity : Vector3 = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	pass;
	# var pos = get_translation()
	# var cam = get_tree().get_root().get_camera()
	# var screenpos = cam.unproject_position(pos)
	# get_node("PlayerName").set_position(Vector2(screenpos.x , screenpos.y ) )
