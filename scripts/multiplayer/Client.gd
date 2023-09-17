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
var id = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new() 
var hostID : int
var lobbyID = ""


func _ready():
	multiplayer.connected_to_server.connect(rtc_server_connected)
	multiplayer.peer_connected.connect(rtc_peer_connected)
	multiplayer.peer_disconnected.connect(rtc_peer_disconnected)
	pass


func rtc_server_connected():
	print("RTC server connected")
	pass


func rtc_peer_connected(id):
	print("RTC peer connected " + str(id))
	pass


func rtc_peer_disconnected(id):
	print("RTC peer disconnected " + str(id))
	pass
	
	
func connect_to_server(ip):
	peer.create_client("ws://127.0.0.1:8915")
	print("Started client")


func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.id:
				id = data.id
				connected(id)
				
			if data.message == Message.userConnected:
				create_peer(data.id)
				
			if data.message == Message.lobby:
				GameManager.Players = JSON.parse_string(data.players)
				hostID = data.host
				lobbyID = data.lobbyID
				
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got candidate: " + str(data.orgPeer) + "; My ID is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
						rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
						rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)


func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer


#webrtc connection stuff
func create_peer(id):
	if id != self.id:
		var peer : WebRTCPeerConnection = WebRTCLibPeerConnection.new()
		peer.initialize({
			"iceServers" : [{"urls": ["stun:stun.l.google.com:19302"]}]
		})
		print("Binding id: " + str(id) + "; My id is " + str(self.id))
		
		peer.session_description_created.connect(self.offer_created.bind(id))
		peer.ice_candidate_created.connect(self.ice_candidate_created.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if !hostID == self.id:
			peer.create_offer()
	pass


func offer_created(type, data, id):
	if !rtcPeer.has_peer(id):
		return
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)
	pass


func send_offer(id, data):
	var message ={
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data" : data,
		"lobby" : lobbyID,
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func send_answer(id, data):
	var message ={
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data" : data,
		"lobby" : lobbyID,
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	

func ice_candidate_created(midName, indexName, sdpName, id):
	var message ={
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid" : midName,
		"index": indexName,
		"sdp": sdpName,
		"lobby" : lobbyID,
	}
	pass


func _on_start_client_pressed():
	connect_to_server("")


func _on_join_lobby_pressed():
	var message ={
		"id" : id,
		"message" : Message.lobby,
		"lobbyID" : $lobbyName.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
