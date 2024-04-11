extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var Poses : Array[Node3D]
var active_pose : int
var camera : Camera3D
# Called when the node enters the scene tree for the first time.
func _ready():
	active_pose = 0
	Poses = [$CameraRotate/CameraElevate/CameraPos1, $CameraRotate/CameraElevate/CameraPos2]
	camera = $CameraRotate/CameraElevate/Camera3D
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	camera.transform = camera.transform.interpolate_with(Poses[active_pose].transform, 0.1)
	pass

func _input(event):
	if event is InputEventScreenDrag:
		print_debug("drag")
		var relative = event.speed
		rotate_camera(relative.x)
		elevate_camera(relative.y)
	elif Input.is_action_pressed("drag_camera") and event is InputEventMouseMotion:
		var relative = event.relative
		rotate_camera(relative.x / 180)
		elevate_camera(relative.y / 180)
	elif Input.is_action_pressed("toggle_camera"):
		active_pose = 1-active_pose
	pass

func rotate_camera(angle : float):
	var box : Node3D = $CameraRotate
	var camera_y = camera.transform.basis.y
	box.transform = box.transform.rotated(box.transform.basis * camera_y, -angle).orthonormalized()
	pass

#func rotate_camera(angle : float):
	#var box = $CameraRotate
	#box.transform = box.transform.rotated(Vector3.DOWN, angle)
	#pass

func elevate_camera(angle : float):
	var box := $CameraRotate
	var camera_x = camera.transform.basis.x
	box.transform = box.transform.rotated(box.transform.basis * camera_x, -angle).orthonormalized()
	pass

#func elevate_camera(angle : float):
	#var box = $CameraRotate/CameraElevate
	#box.transform = box.transform.rotated(Vector3.LEFT, angle)
	#pass
