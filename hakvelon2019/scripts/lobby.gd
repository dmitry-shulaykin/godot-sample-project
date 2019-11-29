extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var locations = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#gamestate.connect("player_list_changed", self, "refresh_lobby")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_host_btn_pressed():
	get_node("connect_pnl").hide()
	
	gamestate.join_game()
	
	get_node("ppl_pnl").show();
	pass # Replace with function body.

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("ppl_pnl/ppl_lst").clear()
	get_node("ppl_pnl/ppl_lst").add_item(str(gamestate.get_player_name()) + " (You)")
	for p in players:
		get_node("ppl_pnl/ppl_lst").add_item(str(p))

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	# print(json.result)
	print('request completed')
	for employee in json.result:
		var id = employee['Id']
		var login = employee['Login']
		var location = employee['Dislocation']
		if !locations.has(location):
    		locations.append(location)

		if location == "412 - AX Data Movement":
			gamestate.add_person(id, login, location)

	get_node("loc_pnl/loc_lst").clear()
	for location in locations:
		get_node("loc_pnl/loc_lst").add_item(location)
		
