extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node('request_names').request('http://localhost:3000/names')
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _on_Button_pressed():
	pass # Replace with function body.


func _on_request_names_request_completed(result, response_code, headers, body):
	var resp = JSON.parse(body.get_string_from_utf8()).result
	gamestate.set_persons_names(resp)
	gamestate.create_map();
	gamestate.join_game();
	get_node("start").hide();
	pass # Replace with function body.
