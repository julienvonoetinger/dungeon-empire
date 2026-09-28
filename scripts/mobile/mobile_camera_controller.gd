class_name MobileCameraController
extends RefCounted

var zoom: float = 2.0
var yaw: float = 45.0
var pan: Vector2 = Vector2.ZERO
var follow_enabled: bool = false

func pan_by(delta: Vector2) -> void:
	pan += delta
	follow_enabled = false

func zoom_by(factor: float) -> void:
	if is_finite(factor) and factor > 0.0:
		zoom = clampf(zoom * factor, 1.2, 4.0)

func rotate_steps(steps: int) -> void:
	yaw = 45.0 + posmod(roundi((yaw - 45.0) / 90.0) + steps % 4, 4) * 90.0

func reset() -> void:
	zoom = 2.0
	yaw = 45.0
	pan = Vector2.ZERO
	follow_enabled = false
