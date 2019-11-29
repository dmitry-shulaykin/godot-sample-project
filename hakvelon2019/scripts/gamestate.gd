extends Node

func host_game():
	print("hosting akvelon map")
	var host = WebSocketServer.new()
	var error = host.listen(8080, PoolStringArray(), true)
	print('server error: ', error)
	get_tree().set_network_peer(host)

func join_game():
	print('joining akvelon map')
	var client = WebSocketClient.new()
	var url = "ws://127.0.0.1:" + str(8080)
	var error = client.connect_to_url(url, PoolStringArray(), true)
	print('error: ', error)
	get_tree().set_network_peer(client)


func begin_game_server():
	assert(get_tree().is_network_server())
	
	create_map()

func create_map():
	# Change scene
	var level = load("res://scenes/level.tscn").instance()
	get_tree().get_root().add_child(level)

	get_tree().get_root().get_node("lobby").hide()

	var person = load("res://scenes/person.tscn")

	for i in range(-1, 2):
		var player = person.instance()
		player.set_translation(Vector3(4*i, 4, 0))
		player.set_network_master(get_tree().get_network_unique_id())
		level.get_node("players").add_child(player)