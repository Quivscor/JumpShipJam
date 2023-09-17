extends CharacterBody3D

@onready var camera_rig = $CharacterModel/CameraRig
@onready var camera = $CharacterModel/CameraRig/Camera3D
@onready var cursor = $Cursor

@export var speed : float = 5.0


func _enter_tree():
	set_multiplayer_authority(name.to_int())


func _ready():
	if is_multiplayer_authority():
		camera_rig.set_as_top_level(true)
		cursor.set_as_top_level(true)
	else:
		camera.queue_free()
		camera_rig.queue_free()
		cursor.queue_free()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _physics_process(delta):
	if is_multiplayer_authority():
		look_at_cursor()
		move(delta)
		camera_follow()

	move_and_slide()


func move(delta):
	var moveDir : Vector3 = Vector3()
	
	moveDir.z = Input.get_axis("up", "down")
	moveDir.x = Input.get_axis("left", "right")
	
	moveDir.y = 0
	moveDir = moveDir.normalized()
	
	velocity = moveDir * speed * delta


func look_at_cursor():
	var position : Vector3 = global_transform.origin
	var dropPlane : Plane = Plane(Vector3.UP, position.y)
	var rayLength : float = 1000
	var mousePos : Vector2 = get_viewport().get_mouse_position()
	var from : Vector3 = camera.project_ray_origin(mousePos)
	var to : Vector3 = from + camera.project_ray_normal(mousePos) * rayLength
	
	var cursorPos : Vector3 = dropPlane.intersects_ray(from, to)
	
	cursor.global_transform.origin = cursorPos + Vector3.UP
	
	look_at(cursorPos, Vector3.UP)


func camera_follow():
	var playerPos : Vector3 = global_transform.origin
	camera_rig.global_transform.origin = playerPos
