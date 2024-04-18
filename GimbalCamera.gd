extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export var point_cloud : Node3D

var Poses : Array[Node3D]
var active_pose : int
var camera : Camera3D
var place_hint : MeshInstance3D
# Called when the node enters the scene tree for the first time.
func _ready():
	active_pose = 0
	Poses = [$CameraRotate/CameraElevate/CameraPos1, $CameraRotate/CameraElevate/CameraPos2]
	camera = $CameraRotate/CameraElevate/Camera3D
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	return
	var tf := 1.0 - pow(0.01, delta) # 1 -> 0.99
	camera.transform = camera.transform.interpolate_with(Poses[active_pose].transform, tf)

func drag_camera(x : float, y: float) :
	rotate_camera(x)
	elevate_camera(y)

func place_point() :
	var mouse := get_viewport().get_mouse_position()
	var array_mesh = ArrayMesh.new()
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	var vertices : PackedVector3Array = [camera.project_position(mouse, -0.5 + local_camera_distance), camera.project_position(mouse, 2 + local_camera_distance)]
	var colors : PackedColorArray = [Color.WHITE, Color.BLACK]
	var lines : PackedInt32Array = [0, 1]
	arrs[Mesh.ARRAY_VERTEX] = vertices
	arrs[Mesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_POINTS, arrs)
	arrs[Mesh.ARRAY_INDEX] = lines
	array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_LINES, arrs)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.set_surface_override_material(0, ResourceLoader.load("res://point_material.tres", "Material") as Material)
	mesh_instance.set_surface_override_material(1, ResourceLoader.load("res://line_material.tres", "Material") as Material)
	if place_hint :
		place_hint.queue_free()
	add_child(mesh_instance)
	place_hint = mesh_instance

var local_camera_distance := 1.0

func _input(event):
	if event is InputEventScreenDrag:
		print_debug("drag") # for touchscreens
		drag_camera(event.speed.x, event.speed.y)
	elif Input.is_action_pressed("drag_camera") and event is InputEventMouseMotion:
		drag_camera(event.relative.x / 180, event.relative.y / 180)
	elif Input.is_action_just_pressed("toggle_camera"):
		active_pose = (active_pose + 1) % Poses.size()
	elif (Input.is_action_just_pressed("place_point")) :
		place_point()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP: 
		if local_camera_distance > 0.0 :
			var node : Node3D = $CameraRotate/CameraElevate/Camera3D
			node.transform = node.transform.translated_local(Vector3(0.0, 0.0, -0.05))
			local_camera_distance -= 0.05
			print(local_camera_distance)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: 
		if local_camera_distance < 1.5 :
			var node : Node3D = $CameraRotate/CameraElevate/Camera3D
			node.transform = node.transform.translated_local(Vector3(0.0, 0.0, 0.05))
			local_camera_distance += 0.05
			print(local_camera_distance)
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
