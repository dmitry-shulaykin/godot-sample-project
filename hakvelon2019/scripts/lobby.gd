extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var locations = []
var selected_room = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	#gamestate.connect("player_list_changed", self, "refresh_lobby")
	get_node("loc_pnl/loc_lst").connect("item_selected", self, "_room_name_selected")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):



func _on_host_btn_pressed():
	get_node("connect_pnl").hide()
	
	gamestate.join_game()
	gamestate.create_map()
	get_node("ppl_pnl").show();
	
	pass # Replace with function body.

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("ppl_pnl/ppl_lst").clear()
	get_node("ppl_pnl/ppl_lst").add_item(str(gamestate.get_player_name()) + " (You)")
	for p in players:
		get_node("ppl_pnl/ppl_lst").add_item(str(p))

func _on_rooms_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	# print(json.result)
	print('request completed')
	
	for location in json.result:
    	locations.append(location)
	
	gamestate.add_room_markers(json.result)	

func _on_room_names_request_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	get_node("loc_pnl/loc_lst").clear()
	for room_name in json.result:
    	get_node("loc_pnl/loc_lst").add_item(room_name)
	
	pass # Replace with function body.


func _on_desks_request_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_create_room_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_update_room_position_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_update_desk_position_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_delete_room_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_delete_desk_request_completed(result, response_code, headers, body):
	pass # Replace with function body.

func _make_post_request(url, data_to_send):
    # Convert data to json string:
    var query = JSON.print(data_to_send)
    # Add 'Content-Type' header:
    var headers = ["Content-Type: application/json"]
    $HTTPRequest.request(url, headers, true, HTTPClient.METHOD_POST, query)

func _make_delete_request(url):
    $HTTPRequest.request(url, headers, true, HTTPClient.METHOD_DELETE)



