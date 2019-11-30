extends Node

var level = null
var ws = null
var room_markers = {}
var persons_list = {}


func join_game():
	print('joining akvelon map')
	ws = WebSocketClient.new()
	ws.connect("connection_established", self, "_connection_established")
	ws.connect("connection_closed", self, "_connection_closed")
	ws.connect("connection_error", self, "_connection_error")
	ws.connect("data_received", self, "_data_recieved")
	
	var url = "ws://localhost:8081"
	print("Connecting to " + url)
	ws.connect_to_url(url)
	pass

func _ready():
	pass

	
func _data_recieved():
	pass

func _connection_established(protocol):
	print("Connection established with protocol: ", protocol)
	
func _connection_closed():
	print("Connection closed")

func _connection_error():
	print("Connection error")
    
func _process(delta):
	if !ws:
		return
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()
	if ws.get_peer(1).is_connected_to_host():
		# ws.get_peer(1).put_var("HI")
		if ws.get_peer(1).get_available_packet_count() > 0 :
			var packet = ws.get_peer(1).get_packet()
			var buffer = StreamPeerBuffer.new()
			buffer.set_data_array(packet)
			
			var event = buffer.get_string()
			var result = JSON.parse(event).result
			var type = result['event_type']
			print('Recieve: ', type)
			
			if type == 'load_person':
				var person = result['person']
				add_person(person['id'], person['first_name'], person['last_name'], person['room'])
				print(person)

func add_person(id, nname, surname, location):
	print('adding person', nname, surname, location)
	var person = load("res://scenes/person.tscn")
	var person_instance = person.instance()
	var room = location
	var room_node = level.get_node('room_markers/'+room)
	if room_node == null:
		print('null room', room)
	
	person_instance.set_translation(room_node.get_translation())
	person_instance.set_names(id, nname, surname)
	## player.set_network_master(id)
	#if position_node == null:
		#return
	
	level.get_node("persons").add_child(person_instance)
	#print(level.get_node("persons"))
	# player.set_translation(position_node.get_translation())
	
	var target = level.get_node("goto").get_translation();
	#player.move_to(target)
	persons_list[id] = person_instance
	pass

func person_move(id, room):
	var person = persons_list[id]
	var room_pos = level.get_node('room_markers/'+room).get_translation()
	person.move_to(person)
	

func add_room_markers(markers):
	for marker in room_markers.values():
		level.get_node("room_markers").remove_child(marker)
	room_markers = {}

	var room_marker_model = load("res://scenes/room_marker.tscn")
	for room in markers:
		var room_instance = room_marker_model.instance()
		room_instance.set_name(room['name'])
		var pos = room['position']
		room_instance.set_translation(Vector3(pos['x'], pos['y'], pos['z']))
		room_instance.set_name(room['name'])
		room_markers[room['name']] = room_instance
		level.get_node("room_markers").add_child(room_instance)

func hide_location_markers():
	pass
	
func show_location_markers():
	pass

func create_map():
	# Change scene
	var levelmodel = load("res://scenes/level.tscn")
	level = levelmodel.instance()
	get_tree().get_root().add_child(level)
	#get_tree().get_root().get_node("lobby").hide()
	pass;
