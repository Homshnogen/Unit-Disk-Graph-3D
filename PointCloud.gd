extends Node3D

@export var point_material : BaseMaterial3D
@export var line_material : BaseMaterial3D
@export var scalef : float = 5 # size of the point cloud
@export var numpoints : int = 100

var vertices : PackedVector3Array
var lines : PackedInt32Array
var colors : PackedColorArray
var mesh_instance : MeshInstance3D

var cells : Dictionary # (Vector3i, Cell)

signal bfs_next

class bfs_Controller:
	var running := true

var bfs_state : bfs_Controller

# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Vector3(1/scalef, 1/scalef, 1/scalef)
	bfs_state = bfs_Controller.new()
	reset_points()
	bfs_reset()

func _input(event):
	if (Input.is_action_just_pressed("reset_points") and event is InputEventKey) :
		reset_points()
		bfs_reset()
	elif (Input.is_action_just_pressed("action1")) :
		vertices[0] = scalef*( Vector3(randf(),randf(),randf()) - Vector3(0.5,0.5,0.5) )
		update_mesh()

var compound_time := 0.0
func _process(delta):
	compound_time += delta
	if (compound_time >= 0.125) :
		compound_time -= 0.125
		bfs_next.emit()
		update_mesh()

func bfs_reset(): # handles instances of bfs call memory
	bfs_state.running = false
	bfs_next.emit()
	bfs_state = bfs_Controller.new()
	bfs(bfs_state)
		
func setup_search(): # organizes vertices into unit grid cells which are aware of their neighbors
	cells.clear()
	for i in range(vertices.size()):
		var point := vertices[i]
		var key := Vector3i(floori(point.x), floori(point.y), floori(point.z))
		var cell : Cell = cells.get(key);
		if (cell == null) :
			cells[key] = Cell.new(key)
			cell = cells[key]
			for key2 in cells :
				if (key - (key2 as Vector3i)).length_squared() <= 3 : # within one unit in each dimension
					(cells[key2] as Cell).neighbors.append(cell)
					cell.neighbors.append(cells[key2])
		cell.points.append(i)

func bfs(state : bfs_Controller):
	setup_search()
	var bfs_points := []
	for i in range(vertices.size()) :
		bfs_points.push_back(i)
	var bfs_queue := []
	lines = []
	var colori = 0.0
	await bfs_next
	if !state.running :
		return
	
	while (!bfs_points.is_empty()) :
		if bfs_queue.is_empty() :
			bfs_queue.push_back(bfs_points.pop_back())
			colors[bfs_queue[0]] = Color.from_hsv(colori/vertices.size(), 0.5, 0.8)
			colori += 1.0
			await bfs_next
			if !state.running :
				return
		var point := vertices[bfs_queue[0]]
		var cell : Cell = cells[Vector3i(floori(point.x), floori(point.y), floori(point.z))] # must exist
		var i := 0
		while i < cell.points.size() :
			var v = cell.points[i]
			if v == bfs_queue[0] :
				cell.points.remove_at(i)
			elif point.distance_squared_to(vertices[v]) < 1.0 : 
				bfs_queue.push_back(v) # add near point to queue
				colors[v] = Color.from_hsv(colori/vertices.size(), 0.5, 0.8)
				colori += 1.0
				bfs_points.remove_at(bfs_points.find(v))
				lines.append_array([bfs_queue[0], v]) # add line to near point
				cell.points.remove_at(i)
				await bfs_next
				if !state.running :
					return
			else :
				i += 1
		var n := 0
		while n < cell.neighbors.size() :
			var neighbor := cell.neighbors[n]
			i = 0
			while i < neighbor.points.size() :
				var v = neighbor.points[i]
				if point.distance_squared_to(vertices[v]) < 1.0 : 
					bfs_queue.push_back(v) # add near point to queue
					colors[v] = Color.from_hsv(colori/vertices.size(), 0.5, 0.8)
					colori += 1.0
					bfs_points.remove_at(bfs_points.find(v)) 
					lines.append_array([bfs_queue[0], v]) # add line to near point
					neighbor.points.remove_at(i)
					await bfs_next
					if !state.running :
						return
				else :
					i += 1
			#if neighbor.points.is_empty() :
				#for n2 in neighbor.neighbors :
					#n2.neighbors.remove_at(n2.neighbors.find(neighbor))
				#cells.erase(neighbor.key)
			#else
			n += 1
		#if cell.points.is_empty() :
			#for n2 in cell.neighbors :
				#n2.neighbors.remove_at(n2.neighbors.find(cell))
			#cells.erase(cell.key)
		bfs_queue.pop_front()
	state.running = false

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
		colors.append(Color.WHITE);
	
	update_mesh()

class Cell:
	var neighbors : Array[Cell]
	var points : PackedInt32Array # index of vertex in vertices, used for lines
	var key : Vector3i
	func _init(pos : Vector3i) :
		key = pos
		neighbors = []
		points = []
		
