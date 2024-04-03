extends Node3D

@export var point_material: BaseMaterial3D
@export var line_material: BaseMaterial3D
@export var scalef: float = 1
@export var numpoints: int = 10

var vertices : PackedVector3Array
var lines : PackedInt32Array
var colors : PackedColorArray
var mesh_instance
# Called when the node enters the scene tree for the first time.
func _ready():
	reset_points()

func _input(event):
	if (Input.is_action_just_pressed("reset_points") and event is InputEventKey) :
		reset_points()
	elif (Input.is_action_just_pressed("action1")) :
		vertices[0] = scalef*( Vector3(randf(),randf(),randf()) - Vector3(0.5,0.5,0.5) )
		update_mesh()

func update_mesh():
	for n in get_children():
		remove_child(n)
		n.queue_free()
	
	var array_mesh = ArrayMesh.new()
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	arrs[Mesh.ARRAY_VERTEX] = vertices
	arrs[Mesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_POINTS, arrs)
	arrs[Mesh.ARRAY_INDEX] = lines
	array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_LINES, arrs)
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.set_surface_override_material(0, point_material)
	mesh_instance.set_surface_override_material(1, line_material)
	add_child(mesh_instance)

func reset_points():
	vertices = PackedVector3Array()
	lines = PackedInt32Array()
	colors = PackedColorArray()
	
	for i in range(numpoints):
		vertices.append(scalef*( Vector3(randf(),randf(),randf()) - Vector3(0.5,0.5,0.5) ))
		colors.append(Color(randf(),randf(),randf()));
		if (i > 0) :
			lines.append((i-1)/2)
			lines.append(i)
	
	update_mesh()
