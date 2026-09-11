class_name Neon

static func aabb(node: Node3D) -> AABB:
	var mn := Vector3(INF, INF, INF)
	var mx := -Vector3(INF, INF, INF)
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = mi.get_aabb()
		var t: Transform3D = mi.global_transform
		for i in range(8):
			mn = mn.min(t * a.get_endpoint(i))
			mx = mx.max(t * a.get_endpoint(i))
	return AABB(mn, mx - mn)

static func local_aabb(top: Node3D) -> AABB:
	var mn := Vector3(INF, INF, INF)
	var mx := -Vector3(INF, INF, INF)
	for mi in top.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D()
		var cur: Node3D = mi
		while cur != null and cur != top:
			t = cur.transform * t
			cur = cur.get_parent_node_3d()
		var a: AABB = mi.get_aabb()
		for i in range(8):
			var p := t * a.get_endpoint(i)
			mn = mn.min(p)
			mx = mx.max(p)
	return AABB(mn, mx - mn)

static func fit_local(node: Node3D, height: float) -> void:
	var a := local_aabb(node)
	if a.size.y <= 0.001:
		return
	var s: float = height / a.size.y
	node.scale = Vector3.ONE * s
	node.position = Vector3(-s * a.get_center().x, -s * a.position.y, -s * a.get_center().z)

static func fit(node: Node3D, height: float) -> void:
	var a: AABB = aabb(node)
	if a.size.y <= 0.001:
		return
	var s: float = height / a.size.y
	node.scale = Vector3.ONE * s
	a = aabb(node)
	node.position = Vector3(-a.get_center().x, -a.position.y, -a.get_center().z)

static func tint_soldier(model: Node3D) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var part := str(mi.name)
		for s in range(mi.mesh.get_surface_count()):
			var src: Material = mi.mesh.surface_get_material(s)
			if src == null:
				continue
			var m := src.duplicate() as StandardMaterial3D
			if m == null:
				mi.set_surface_override_material(s, src.duplicate())
				continue
			if part == "Vest":
				m.albedo_color = Color(0.18, 0.07, 0.34)
				m.metallic = 0.4
				m.emission_enabled = true
				m.emission = Color(0.7, 0.25, 1.0)
				m.emission_energy_multiplier = 0.7
			elif part == "scarf":
				m.albedo_color = Color(0.0, 0.4, 0.5)
				m.metallic = 0.2
				m.emission_enabled = true
				m.emission = Color(0.0, 0.9, 1.0)
				m.emission_energy_multiplier = 2.2
			elif part == "body":
				m.albedo_color = Color(0.45, 0.5, 0.62)
				m.metallic = 0.6
			mi.set_surface_override_material(s, m)

static func tint_dark(model: Node3D, tint: Color) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		for s in range(mi.mesh.get_surface_count()):
			var src: Material = mi.mesh.surface_get_material(s)
			var std: StandardMaterial3D
			if src == null:
				std = StandardMaterial3D.new()
				std.albedo_color = Color(0.05, 0.05, 0.08)
			else:
				std = src.duplicate() as StandardMaterial3D
				if std == null:
					continue
			std.albedo_color = std.albedo_color * tint
			std.roughness = maxf(std.roughness, 0.85)
			mi.set_surface_override_material(s, std)