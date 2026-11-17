extends Node3D
## Divisor central tracejado, criado em código.

@export var half_height := 4.3
@export var dash_count := 13


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.16, 0.34, 0.16)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6
	for i in dash_count:
		var dash := MeshInstance3D.new()
		dash.mesh = mesh
		dash.material_override = mat
		dash.position = Vector3(0.0, lerpf(-half_height, half_height, float(i) / float(dash_count - 1)), 0.0)
		add_child(dash)
