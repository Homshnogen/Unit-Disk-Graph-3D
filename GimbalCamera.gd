extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	pass

func rotate_camera(angle : float):
	var box : Node3D = $CameraRotate
	box.transform = box.transform.rotated(box.transform.basis.y, -angle).orthonormalized()
	pass

#func rotate_camera(angle : float):
	#var box = $CameraRotate
	#box.transform = box.transform.rotated(Vector3.DOWN, angle)
	#pass

func elevate_camera(angle : float):
	var box := $CameraRotate
	box.transform = box.transform.rotated(box.transform.basis.x, -angle).orthonormalized()
	pass

#func elevate_camera(angle : float):
	#var box = $CameraRotate/CameraElevate
	#box.transform = box.transform.rotated(Vector3.LEFT, angle)
	#pass
