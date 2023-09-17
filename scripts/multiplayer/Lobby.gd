extends RefCounted
class_name Lobby

var HostID : int
var Players : Dictionary = {}

func _init(id):
	HostID = id


func add_player(id, name):
	Players[id] ={
		"name" : name,
		"id" : id,
		"index" : Players.size() + 1,
	}
	return Players[id]
