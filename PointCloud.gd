extends Node3D

@export var point_material : BaseMaterial3D
@export var line_material : BaseMaterial3D
@export var scalef : float = 5 # size of the point cloud
@export var numpoints : int = 100

var vertices : PackedVector3Array
var lines : PackedInt32Array
var colors : PackedColorArray
var point_cloud_mesh : MeshInstance3D
var sphere : Node3D
var sphere_material : StandardMaterial3D
var cube : Node3D
var cube_material : StandardMaterial3D

var cells : Dictionary # (Vector3i, Cell)

signal bfs_next
signal reset_graph

func add_vertex(point : Vector3) :
	vertices.append(to_local(point))
	numpoints += 1
	bfs_reset()
	update_mesh()
	
func pop_vertex() :
	if vertices.size() > 1 :
		vertices.resize(vertices.size()-1)
		numpoints -= 1
		bfs_reset()
		update_mesh()

class bfs_Controller:
	var running := true

var bfs_state : bfs_Controller

func rescale(new_scale : float) :
	if (new_scale > 1 && new_scale < 10) :
		var factor = new_scale/scalef
		scalef = new_scale
		scale = Vector3(1/scalef, 1/scalef, 1/scalef)
		for i in vertices.size() :
			vertices[i] *= factor
		bfs_reset()
		update_mesh()


# Called when the node enters the scene tree for the first time.
func _ready():
	sphere = $Sphere
	var sphere_mesh : MeshInstance3D = $Sphere/MeshInstance3D
	sphere_material = sphere_mesh.mesh.surface_get_material(0)
	cube = $Cube
	var cube_mesh : MeshInstance3D = $Cube/MeshInstance3D
	cube_material = cube_mesh.mesh.surface_get_material(0)
	scale = Vector3(1/scalef, 1/scalef, 1/scalef)
	bfs_state = bfs_Controller.new()
	reset_points()
	bfs_reset()

var show_cube := false

func _input(event):
	if Input.is_action_just_pressed("random_points") :
		reset_points()
		bfs_reset()
		update_mesh()
	elif Input.is_action_just_pressed("reset_points") :
		bfs_reset()
		update_mesh()
	elif Input.is_action_just_pressed("step_forward") :
		bfs_next.emit()
		update_mesh()
	elif Input.is_action_just_pressed("scale_down") :
		rescale(scalef + 0.2)
	elif Input.is_action_just_pressed("scale_up") :
		rescale(scalef - 0.2)
	elif Input.is_action_just_pressed("hide_cube") :
		show_cube = !show_cube
		if (bfs_state.running) :
			sphere.visible = show_cube
			cube.visible = show_cube

var compound_time := 0.0
# maybe make this into enum state (paused, auto, instant)
var bfs_tick := 0.375

func _process(delta):
	match GlobalState.state:
		GlobalState.STATE_INSTANT :
			if (bfs_state.running) :
				while (bfs_state.running) :
					bfs_next.emit()
				update_mesh()
		GlobalState.STATE_AUTO :
			compound_time += delta
			if (compound_time >= bfs_tick) :
				compound_time -= bfs_tick
				bfs_next.emit()
				update_mesh()
		# GlobalState.STATE_PAUSED :
	

func bfs_reset(): # handles instances of bfs call memory
	bfs_state.running = false
	bfs_next.emit()
	reset_graph.emit()
	lines = PackedInt32Array()
	colors = PackedColorArray()
	colors.resize(vertices.size())
	for i in vertices.size() :
		colors[i] = Color.WHITE
	bfs_state = bfs_Controller.new()
	bfs(bfs_state)
		
func setup_search(): # organizes vertices into unit grid cells which are aware of their neighbors
	cells.clear()
	for i in range(vertices.size()):
		var point := vertices[i]
		var key := Vector3i(floori(point.x), floori(point.y), floori(point.z))
		var cell : Cell = cells.get(key);
		if (cell == null) :
			cell = Cell.new(key)
			var key2 := Vector3i() # should be copy
			for kx in range(-1, 2) :
				key2.x = key.x + kx
				for ky in range(-1, 2) :
					key2.y = key.y + ky
					for kz in range(-1, 2) :
						key2.z = key.z + kz
						if cells.has(key2) :
							(cells[key2] as Cell).neighbors.append(cell)
							cell.neighbors.append(cells[key2])
			cells[key] = cell
			
			#for key2 in cells : # this is slower than it needs to be
				#if (key - (key2 as Vector3i)).length_squared() <= 3 : # within one unit in each dimension
					#(cells[key2] as Cell).neighbors.append(cell)
					#cell.neighbors.append(cells[key2])
		cell.points.append(i)

func bfs(state : bfs_Controller):
	sphere.visible = false
	sphere.position = Vector3.ZERO
	sphere_material.albedo_color.h = 1.0
	sphere_material.albedo_color.s = 1.0
	sphere_material.albedo_color.v = 1.0
	cube.visible = false
	cube.position = Vector3.ZERO
	setup_search()
	var bfs_points := []
	for i in range(vertices.size(), 0, -1) :
		bfs_points.push_back(i-1)
	var bfs_queue := []
	lines = []
	var colori = 0.0
	await bfs_next
	if !state.running :
		return
	sphere.visible = show_cube
	sphere_material.albedo_color.s = 0.8
	sphere_material.albedo_color.v = 0.3
	cube.visible = show_cube
	while (!bfs_points.is_empty()) :
		if bfs_queue.is_empty() :
			bfs_queue.push_back(bfs_points.pop_back())
			colors[bfs_queue[0]] = Color.from_hsv(colori/vertices.size(), 0.5, 0.8)
			colori += 1.0
		var point := vertices[bfs_queue[0]]
		sphere.position = point
		sphere_material.albedo_color.h = colors[bfs_queue[0]].h
		cube.position = Vector3(floor(point.x)+0.5, floor(point.y)+0.5, floor(point.z)+0.5)
		await bfs_next
		if !state.running :
			return
		
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
	sphere.visible = false
	sphere.position = Vector3.ZERO
	sphere_material.albedo_color.h = 1.0
	sphere_material.albedo_color.s = 1.0
	sphere_material.albedo_color.v = 1.0
	cube.visible = false
	state.running = false

func update_mesh():
	if point_cloud_mesh :
		point_cloud_mesh.queue_free()
	
	var array_mesh = ArrayMesh.new()
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	arrs[Mesh.ARRAY_VERTEX] = vertices
	arrs[Mesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_POINTS, arrs)
	if (lines.size() > 0) :
		arrs[Mesh.ARRAY_INDEX] = lines
		array_mesh.add_surface_from_arrays(PrimitiveMesh.PRIMITIVE_LINES, arrs)
	
	point_cloud_mesh = MeshInstance3D.new()
	point_cloud_mesh.mesh = array_mesh
	point_cloud_mesh.set_surface_override_material(0, point_material)
	if (lines.size() > 0) :
		point_cloud_mesh.set_surface_override_material(1, line_material)
	add_child(point_cloud_mesh)

func reset_points():
	vertices = PackedVector3Array()
	
	for i in range(numpoints):
		vertices.append(scalef*( Vector3(randf(),randf(),randf()) - Vector3(0.5,0.5,0.5) ))
	
	update_mesh()

class Cell:
	var neighbors : Array[Cell]
	var points : PackedInt32Array # index of vertex in vertices, used for lines
	var key : Vector3i
	func _init(pos : Vector3i) :
		key = pos
		neighbors = []
		points = []
		
