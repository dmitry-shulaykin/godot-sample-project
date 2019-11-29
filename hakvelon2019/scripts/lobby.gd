extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_connect_btn_pressed():
	get_node("connect_pnl").hide()
	gamestate.join_game()
	pass # Replace with function body.


func _on_host_btn_pressed():
	get_node("connect_pnl").hide()
	gamestate.host_game()
	pass # Replace with function body.

