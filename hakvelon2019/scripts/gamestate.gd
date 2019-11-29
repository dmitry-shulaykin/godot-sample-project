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