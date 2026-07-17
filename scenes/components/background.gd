extends ColorRect

@export var camera: Camera2D

func _process(_delta):
	if material is ShaderMaterial:
		material.set_shader_parameter("offset", camera.global_position)
