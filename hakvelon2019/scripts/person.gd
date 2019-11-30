extends KinematicBody

var gravity : Vector3 = Vector3.DOWN * 12.0
var speed : float = 4.0
var current_anim = ""
var velocity : Vector3 = Vector3()

var path = []
var path_ind = 0
const move_speed = 5
onready var nav = get_parent().get_parent().get_node('floor_nav')
var nname = ""
var m_id = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("name").text = nname
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos = get_translation()
	var cam = get_tree().get_root().get_camera()
	var screenpos = cam.unproject_position(pos)
	get_node("name").set_position(Vector2(screenpos.x , screenpos.y))
	get_node("name").text = nname
	pass

func _physics_process(delta):
	var sink = velocity.y # we want to stor eonly the downward velocity for this game ( you would not normaly do this
	# This removes any latteral movements we dont want 
	velocity = Vector3( 0.0, sink , 0.0 )
	if is_on_floor():
    	velocity += gravity * 0.1 * delta
	else:
    	velocity += gravity * delta

	if path_ind < path.size():
        var move_vec = (path[path_ind] - global_transform.origin)
        if move_vec.length() < 0.1:
            path_ind += 1
        else:
            move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
	else:
		velocity = move_and_slide( velocity , Vector3.UP)
		get_node("AnimationPlayer").play("Idle");

func move_to(target_pos):
    path = nav.get_simple_path(global_transform.origin, target_pos)
    path_ind = 0
	
func set_names(id, nm):
	nname = nm
	m_id = id

