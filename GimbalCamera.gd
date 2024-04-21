extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export var point_cloud : Node3D

var Poses : Array[Node3D]
var active_pose : int
var camera : Camera3D
var place_hint : MeshInstance3D
var place_hint_vertices : PackedVector3Array
var place_hint_point : Vector3
var place_hint_point_mesh : MeshInstance3D
# Called when the node enters the scene tree for the first time.
func _ready():
	active_pose = 0
	Poses = [$CameraRotate/CameraElevate/CameraPos1, $CameraRotate/CameraElevate/CameraPos2]
	camera = $CameraRotate/CameraElevate/Camera3D
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (place_hint_vertices) :
		var mouse := get_viewport().get_mouse_position()
		var C1 := camera.unproject_position(place_hint_vertices[0])
		var D1 := camera.unproject_position(place_hint_vertices[1]) - C1
		var t1 := (mouse - C1).dot(D1) / D1.dot(D1)
		var point1 := C1 + t1*D1 # point that is closest to mouse on screen
		if point1.x > get_viewport().size.x :
			var diff = get_viewport().size.x - point1.x
			point1 += D1 * (diff/D1.x)
		elif point1.x < 0.0 :
			var diff = -point1.x
			point1 += D1 * (diff/D1.x)
		if point1.y > get_viewport().size.y :
			var diff = get_viewport().size.y - point1.y
			point1 += D1 * (diff/D1.y)
		elif point1.y < 0.0 :
			var diff = -point1.y
			point1 += D1 * (diff/D1.y)
		
		var B2 := camera.project_ray_normal(point1)
		var A2 := camera.project_ray_origin(point1)
		var C2 := place_hint_vertices[0]
		var D2 := place_hint_vertices[1] - C2
		
		var t2 := (A2-C2-B2*B2.dot(A2-C2)).x/(D2-B2*B2.dot(D2)).x # point through point1 that intersects line
		
		#var mousevec := camera.project_ray_normal(mouse)
		#var camerapos := camera.project_ray_origin(mouse)
		#var pln := mousevec.cross(camera.project_ray_normal(point1))
		#var t2 := pln.dot(camerapos-place_hint_vertices[0]) / pln.dot(place_hint_vertices[1] - place_hint_vertices[0])
		
		# var point2d = C + t*D
		#var mousevec := camera.project_ray_normal(mouse)
		#var camerapos := camera.project_ray_origin(mouse)
		#var D := (place_hint_vertices[1]-place_hint_vertices[0])
		#var cos := D.dot(mousevec)
		#var t := (camerapos - place_hint_vertices[0]).dot(D - cos*mousevec) / (D.dot(D) - cos*cos)
			#var pln := mousevec.cross(camera.project_ray_normal(Vector2(mouse.x, mouse.y + 1)))
			#var t := pln.dot(camerapos-place_hint_vertices[0]) / pln.dot(place_hint_vertices[1] - place_hint_vertices[0])
		t2 = clampf(t2, 0.00001, 0.99999)
		place_hint_point = place_hint_vertices[0] + t2*(place_hint_vertices[1]-place_hint_vertices[0])
		#point = camera.project_position(point1, 1.0)
		
		var array_mesh = ArrayMesh.new()
		var arrs = []
		arrs.resize(Mesh.ARRAY_MAX)
		var colors : PackedColorArray = [Color.RED]
		arrs[Mesh.ARRAY_VERTEX] = PackedVector3Array([place_hint_point])
		arrs[Mesh.ARRAY_COLOR] = colors
		array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_POINTS, arrs)
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		mesh_instance.set_surface_override_material(0, ResourceLoader.load("res://point_material.tres", "Material") as Material)
		if place_hint_point_mesh :
			place_hint_point_mesh.queue_free()
		add_child(mesh_instance)
		place_hint_point_mesh = mesh_instance
	return
	var tf := 1.0 - pow(0.01, delta) # 1 -> 0.99
	camera.transform = camera.transform.interpolate_with(Poses[active_pose].transform, tf)

func drag_camera(x : float, y: float) :
	rotate_camera(x)
	elevate_camera(y)

func place_point() :
	if place_hint :
		place_hint.queue_free()
		place_hint = null
		place_hint_point_mesh.queue_free()
		place_hint_point_mesh = null
		place_hint_vertices = []
		point_cloud.add_vertex(place_hint_point)
		
	else :
		var mouse := get_viewport().get_mouse_position()
		var array_mesh = ArrayMesh.new()
		var arrs = []
		arrs.resize(Mesh.ARRAY_MAX)
		place_hint_vertices = [camera.project_position(mouse, -0.5 + local_camera_distance), camera.project_position(mouse, 2 + local_camera_distance)]
		var colors : PackedColorArray = [Color.WHITE, Color.BLACK]
		var lines : PackedInt32Array = [0, 1]
		arrs[Mesh.ARRAY_VERTEX] = place_hint_vertices
		arrs[Mesh.ARRAY_COLOR] = colors
		# array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_POINTS, arrs)
		arrs[Mesh.ARRAY_INDEX] = lines
		array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_LINES, arrs)
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		# mesh_instance.set_surface_override_material(0, ResourceLoader.load("res://point_material.tres", "Material") as Material)
		mesh_instance.set_surface_override_material(0, ResourceLoader.load("res://line_material.tres", "Material") as Material)
		add_child(mesh_instance)
		place_hint = mesh_instance

var local_camera_distance := 1.0
var sphere_view := false
func _input(event):
	if event is InputEventScreenDrag:
		print_debug("drag") # for touchscreens
		drag_camera(event.speed.x, event.speed.y)
	elif Input.is_action_pressed("drag_camera") and event is InputEventMouseMotion:
		drag_camera(event.relative.x / 180, event.relative.y / 180)
	elif Input.is_action_just_pressed("toggle_camera"):
		active_pose = (active_pose + 1) % Poses.size()
	elif Input.is_action_just_pressed("pop_point"):
		if place_hint :
			place_hint.queue_free()
			place_hint = null
			place_hint_point_mesh.queue_free()
			place_hint_point_mesh = null
			place_hint_vertices = []
		else :
			point_cloud.pop_vertex()
	elif (Input.is_action_just_pressed("place_point")) :
		place_point()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP: 
		if local_camera_distance > 0.0 :
			var node : Node3D = $CameraRotate/CameraElevate/Camera3D
			node.transform = node.transform.translated_local(Vector3(0.0, 0.0, -0.05))
			local_camera_distance -= 0.05
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: 
		if local_camera_distance < 1.5 :
			var node : Node3D = $CameraRotate/CameraElevate/Camera3D
			node.transform = node.transform.translated_local(Vector3(0.0, 0.0, 0.05))
			local_camera_distance += 0.05
	elif Input.is_action_just_pressed("test") :
		if place_hint_vertices :
			var mouse := get_viewport().get_mouse_position()
			var C := camera.unproject_position(place_hint_vertices[0])
			var D := camera.unproject_position(place_hint_vertices[1]) - C
			print_debug(place_hint_point, point_cloud.to_local(place_hint_point))
	elif Input.is_action_just_pressed("sphere_view") :
		sphere_view = !sphere_view
		if sphere_view :
			reparent(get_node("/root/Main/PointCloud/Sphere"))
			position = Vector3.ZERO
		else :
			reparent(get_node("/root/Main"))
			position = Vector3.ZERO
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
