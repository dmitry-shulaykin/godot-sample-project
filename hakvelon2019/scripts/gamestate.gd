extends Node

var level = null
var ws = null

func join_game():
	pass

func _ready():
	print('joining akvelon map')
	ws = WebSocketClient.new()
	ws.connect("connection_established", self, "_connection_established")
	ws.connect("connection_closed", self, "_connection_closed")
	ws.connect("connection_error", self, "_connection_error")
	
	var url = "ws://localhost:8081"
	print("Connecting to " + url)
	ws.connect_to_url(url)

func _connection_established(protocol):
	print("Connection established with protocol: ", protocol)
	
func _connection_closed():
	print("Connection closed")

func _connection_error():
	print("Connection error")
    
func _process(delta):
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()
	if ws.get_peer(1).is_connected_to_host():
		ws.get_peer(1).put_var("HI")
		if ws.get_peer(1).get_available_packet_count() > 0 :
			var test = ws.get_peer(1).get_var()
			print('recieve %s' % test)

func add_person(id, login, location):
	print('adding person', id, login, location)
	var person = load("res://scenes/person.tscn")
	var player = person.instance()
	player.set_translation(Vector3(0, 5, 0))
	## player.set_network_master(id)
	var name_parts = login.split('.')
	var position_node = level.get_node('desks/' + name_parts[0] + name_parts[1])
	if position_node == null:
		return
	
	level.get_node("players").add_child(player)
	print(level.get_node("players"))
	player.set_translation(position_node.get_translation())
	
	var target = level.get_node("goto").get_translation();
	player.move_to(target)
	
	pass

func create_map():
	# Change scene
	var levelmodel = load("res://scenes/level.tscn")
	print(levelmodel)
	if levelmodel == null:
		return
	level = levelmodel.instance()
	get_tree().get_root().add_child(level)
	#get_tree().get_root().get_node("lobby").hide()
	pass;
