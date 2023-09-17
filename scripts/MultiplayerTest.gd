extends Control

var peer : ENetMultiplayerPeer
@export var playerObject : PackedScene

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


func peer_connected(id):
	print("Player Connected " + str(id))


func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()


func connected_to_server():
	print("Connected!")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())


func connection_failed():
	print("Connection failed!")


@rpc("any_peer") func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name": name,
			"id": id	
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)


func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(135)
	if error != OK:
		print("Cannot host: " + str(error))
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())


func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 135)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)


func _on_start_pressed():
	StartGame.rpc()


@rpc("any_peer", "call_local") func StartGame():
	var scene : Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
