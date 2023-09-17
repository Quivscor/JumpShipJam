extends Node

enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn,
}

var peer : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
@export var hostPort = 8915


func _ready():
	if "--server" in OS.get_cmdline_args():
		print("Hosting on " + str(hostPort))
		peer.create_server(hostPort)
	
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	pass


func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.lobby:
				join_lobby(data.id, data.lobbyID)
				
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("Source ID is: " + str(data.orgPeer))
				send_to_player(data.peer, data)


func peer_connected(id):
	print("Peer connected: " + str(id))
	users[id] ={
		"id" : id,
		"message" : Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	pass


func peer_disconnected(id):
	pass


func join_lobby(userID, lobbyID):
	if lobbyID == "":
		lobbyID = generate_random_string()
		lobbies[lobbyID] = Lobby.new(userID)
		
	var player = lobbies[lobbyID].add_player(userID, "")
	
	for p in lobbies[lobbyID].Players:
		var data = {
			"message" : Message.userConnected,
			"id" : userID,
		}
		send_to_player(p, data)
		
		var data2 = {
			"message" : Message.userConnected,
			"id" : p,
		}
		send_to_player(userID, data2)
		
		var lobbyInfo = {
			"message" : Message.lobby,
			"players" : JSON.stringify(lobbies[lobbyID].Players),
			"host" : lobbies[lobbyID].HostID,
			"lobbyID" : lobbyID,
		}
		send_to_player(p, lobbyInfo)
	
	var data = {
		"message" : Message.userConnected,
		"id" : userID,
		"host" : lobbies[lobbyID].HostID,
		"name" : "",
		"player" : lobbies[lobbyID].Players[userID],
		"lobby" : lobbyID,
	}
	send_to_player(userID, data)


var Characters = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
func generate_random_string():
	var result = ""
	for i in range(32):
		var randomIndex = randi() % Characters.length()
		result += Characters[randomIndex]
	return result


func send_to_player(userID, data):
	peer.get_peer(userID).put_packet(JSON.stringify(data).to_utf8_buffer())


func start_server():
	peer.create_server(hostPort)
	print("Started server")


func _on_start_server_pressed():
	start_server()
