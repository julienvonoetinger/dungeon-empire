extends SceneTree

const ModelFitScript := preload("res://scripts/world/model_fit.gd")

func _initialize() -> void:
	var bounds := AABB(Vector3.ZERO, Vector3(2.0, 4.0, 1.0))
	var scalar: float = ModelFitScript.uniform_scale(bounds, 1.0)
	assert(is_equal_approx(scalar, 0.5), "fit must use the largest horizontal footprint")
	var applied := Vector3.ONE * scalar
	assert(applied.x == applied.y and applied.y == applied.z, "model fit must be uniform on every axis")
	assert(ModelFitScript.uniform_scale(AABB(), 1.0) == 1.0, "empty bounds must retain unit scale")
	assert(not ModelFitScript.last_validation_error().is_empty(), "empty bounds must report a validation error")
	print("OK: uniform model fitting")
	quit()
