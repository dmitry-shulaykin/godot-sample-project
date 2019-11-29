extends Node

var players = {}
var level = null
var player_index = 0

signal player_list_changed()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	pass

func _server_disconnected():
	print('_server_disconnected')
	pass

func _player_disconnected(id):
	print('_player_disconnected: ', id)
	pass

func _connected_ok():
	print('_connected_ok')
	create_map()
	begin_game_client()
	rpc("register_player", get_tree().get_network_unique_id(), get_tree().get_network_unique_id())
	pass
	
remote func register_player(id, new_player_name):
	print('register player: ', id , ", ", new_player_name)
	# id = new player id
	if (get_tree().is_network_server()):
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, 1) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	players[id] = new_player_name
	emit_signal("player_list_changed")
	# add_player(id)

func get_player_list():
	return players.values()

func get_player_name():
	return get_tree().get_network_unique_id()
	
remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

func _connected_fail():
	print('_connected_fail')
	pass

func _player_connected(id):
	print('_player_connected: ', id)
	pass

func host_game():
	print("hosting akvelon map")
	var host = WebSocketServer.new()
	var error = host.listen(8080, PoolStringArray(), true)
	print('server error: ', error)
	get_tree().set_network_peer(host)
	create_map();


func join_game():
	print('joining akvelon map')
	var client = WebSocketClient.new()
	var url = "ws://127.0.0.1:" + str(8080)
	var error = client.connect_to_url(url, PoolStringArray(), true)
	print('error: ', error)
	get_tree().set_network_peer(client)
	begin_game_client();


func begin_game_server():
	assert(get_tree().is_network_server())
	# add_player(1)

func begin_game_client():
	# add_player(get_tree().get_network_unique_id())
	# create_map()
	pass

func add_player(id):
	print('adding player', id)
	var person = load("res://scenes/person.tscn")
	var player = person.instance()
	player.set_translation(Vector3(0, 5, 0))
	player.set_network_master(id)
	level.get_node("players").add_child(player)
	print(level.get_node("players"))
	print(player)
	print('player idx = ', player_index, ' id = ', id)
	player_index += 1
	pass

func add_person():
	print('adding person')
	var person = load("res://scenes/person.tscn")
	var player = person.instance()
	player.set_translation(Vector3(0, 5, 0))
	## player.set_network_master(id)
	level.get_node("players").add_child(player)
	print(level.get_node("players"))
	print('person idx = ', player_index)
	player_index += 1
	pass

func create_map():
	# Change scene
	level = load("res://scenes/level.tscn").instance()
	get_tree().get_root().add_child(level)
	#get_tree().get_root().get_node("lobby").hide()
	pass;
