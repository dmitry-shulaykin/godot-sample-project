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
	var sink = velocity.y # we want to stor eonly the downward velocity for this game ( you would not normaly do this
	# This removes any latteral movements we dont want 
	velocity = Vector3( 0.0, sink , 0.0 )
	if is_on_floor():
    	velocity += gravity * 0.1 * delta
	else:
    	velocity += gravity * delta
	
	if (is_network_master()):
		# get teh imput here  
		# var bombing = Input.is_action_pressed("set_bomb")
		if (Input.is_action_pressed("move_left")):
			print('left')
			velocity += Vector3.LEFT * speed
			self.set_rotation( Vector3( 0 , -.5*PI , 0 ) )
		if (Input.is_action_pressed("move_right")):
			print('move_right')
			velocity += Vector3.RIGHT * speed
			self.set_rotation( Vector3( 0 , .5*PI , 0 ))
		if (Input.is_action_pressed("move_up")):
			print('move_up')
			velocity += Vector3.FORWARD * speed
			self.set_rotation( Vector3( 0 , PI , 0 ) )
		if (Input.is_action_pressed("move_down")):
			print('move_down')
			velocity += Vector3.BACK * speed
			self.set_rotation( Vector3( 0 ,2*PI , 0 ) )
		
		rset("slave_motion", velocity)
		# var mpos : Vector3 = self.get_translation() 
		rset("slave_pos", self.get_translation()  )
		rset("slave_dir" , self.get_rotation() )
	else:
		print('slave')
		self.set_translation(slave_pos)
		self.set_rotation(slave_dir)
		velocity = slave_motion

	var new_anim = "standing"
	if (velocity.z < 0):
		new_anim = "walk_up"
	elif (velocity.z > 0):
		new_anim = "walk_down"
	elif (velocity.x < 0):
		new_anim = "walk_left"
	elif (velocity.x > 0):
		new_anim = "walk_right"
	
	# possibly add the animations for the directions  
	if (new_anim != current_anim):
		current_anim = new_anim 
		if ( current_anim == "stunned" ): # or ( current_anim == "standing" ):
			get_node("AnimationPlayer").play(current_anim)
		else:
			get_node("AnimationPlayer").stop()
		print(current_anim)
		
	velocity = move_and_slide( velocity , Vector3.UP)
	if (not is_network_master() ):
		print('slave')
		slave_pos = self.get_translation() # To avoid jitter

	# var pos = get_translation()
	# var cam = get_tree().get_root().get_camera()
	# var screenpos = cam.unproject_position(pos)
	# get_node("PlayerName").set_position(Vector2(screenpos.x , screenpos.y ) )
