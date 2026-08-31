extends Node

var failures: Array[String] = []

func _ready() -> void:
	var arena = load("res://scenes/dungeon/DungeonArena.tscn").instantiate()
	add_child(arena)
	var navigation_region: NavigationRegion3D = arena.get_node("NavigationRegion3D")

	await get_tree().process_frame
	if navigation_region.is_baking():
		await navigation_region.bake_finished
	elif navigation_region.navigation_mesh.get_polygon_count() == 0:
		navigation_region.bake_navigation_mesh(false)

	await get_tree().physics_frame
	await get_tree().physics_frame

	_validate_structure(navigation_region)
	await _validate_navigation(navigation_region)

	if failures.is_empty():
		print("ARENA VALIDATION PASSED: %d navigation polygons, %d static colliders" % [
			navigation_region.navigation_mesh.get_polygon_count(),
			_count_static_bodies(navigation_region)
		])
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _validate_structure(navigation_region: NavigationRegion3D) -> void:
	_check(_count_static_bodies(navigation_region) == 23, "Arena should contain exactly 23 modular StaticBody3D pieces.")
	for node in navigation_region.find_children("*", "StaticBody3D", true, false):
		var has_collision := false
		for child in node.get_children():
			if child is CollisionShape3D and child.shape != null:
				has_collision = true
				break
		_check(has_collision, "%s is missing a CollisionShape3D." % node.get_path())

func _validate_navigation(navigation_region: NavigationRegion3D) -> void:
	var navigation_mesh := navigation_region.navigation_mesh
	_check(navigation_mesh.get_polygon_count() > 0, "Navigation mesh bake produced no polygons.")

	var test_routes := [
		[Vector3(0, 0, 0), Vector3(-32, 0, -25), "center to northwest spawn"],
		[Vector3(0, 0, 0), Vector3(32, 0, 25), "center to southeast spawn"],
		[Vector3(-24, 0, -21), Vector3(-24, 0, -5), "west narrow corridor"],
		[Vector3(24, 0, 5), Vector3(24, 0, 21), "east narrow corridor"],
		[Vector3(-2, 0, -21), Vector3(16, 0, -21), "north narrow corridor"],
		[Vector3(-16, 0, 21), Vector3(2, 0, 21), "south narrow corridor"]
	]

	var map_rid := navigation_region.get_navigation_map()
	for _frame in range(10):
		await get_tree().physics_frame
	_check(NavigationServer3D.map_get_iteration_id(map_rid) > 0, "Navigation map did not finish its first synchronization.")

	for route in test_routes:
		var start: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, route[0])
		var finish: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, route[1])
		var path := NavigationServer3D.map_get_path(map_rid, start, finish, true)
		_check(start.distance_to(route[0]) < 2.0, "%s start is not on the navigation mesh." % route[2])
		_check(finish.distance_to(route[1]) < 2.0, "%s finish is not on the navigation mesh." % route[2])
		_check(path.size() >= 2, "No usable path found for %s." % route[2])


func _count_static_bodies(root: Node) -> int:
	return root.find_children("*", "StaticBody3D", true, false).size()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
