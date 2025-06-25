extends Node
class_name CameraManager

# Синглтон для управления камерой
static var instance: CameraManager
var current_camera: CameraFollow

func _ready():
	# Устанавливаем синглтон
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# Находим камеру в сцене
	find_camera()

func find_camera():
	"""Ищет камеру в сцене"""
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		current_camera = cameras[0]
	else:
		# Ищем по типу
		var all_cameras = []
		find_cameras_recursive(get_tree().root, all_cameras)
		if all_cameras.size() > 0:
			current_camera = all_cameras[0]

func find_cameras_recursive(node: Node, cameras: Array):
	"""Рекурсивно ищет камеры в дереве узлов"""
	if node is CameraFollow:
		cameras.append(node)
	
	for child in node.get_children():
		find_cameras_recursive(child, cameras)

# Статические методы для удобного доступа

static func get_camera() -> CameraFollow:
	"""Возвращает текущую камеру"""
	if instance:
		return instance.current_camera
	return null

static func shake(intensity: float, duration: float, frequency: float = 20.0):
	"""Встряхивает камеру"""
	var camera = get_camera()
	if camera:
		camera.shake_camera(intensity, duration, frequency)

static func zoom(factor: float, speed: float = 2.0):
	"""Изменяет зум камеры"""
	var camera = get_camera()
	if camera:
		camera.set_zoom_factor(factor, speed)

static func reset_zoom(speed: float = 2.0):
	"""Сбрасывает зум камеры"""
	var camera = get_camera()
	if camera:
		camera.reset_zoom(speed)

static func tilt(angle: float, speed: float = 3.0):
	"""Наклоняет камеру"""
	var camera = get_camera()
	if camera:
		camera.tilt_camera(angle, speed)

static func reset_tilt(speed: float = 3.0):
	"""Убирает наклон камеры"""
	var camera = get_camera()
	if camera:
		camera.reset_tilt(speed)

static func set_follow_speed(speed: float):
	"""Устанавливает скорость следования"""
	var camera = get_camera()
	if camera:
		camera.set_follow_speed(speed)

static func set_target(target: Node2D):
	"""Устанавливает цель для камеры"""
	var camera = get_camera()
	if camera:
		camera.set_target(target)

# Предустановленные эффекты

static func explosion_effect():
	"""Эффект взрыва"""
	var camera = get_camera()
	if camera:
		camera.explosion_effect()

static func hit_effect():
	"""Эффект попадания"""
	var camera = get_camera()
	if camera:
		camera.hit_effect()

static func combat_mode():
	"""Режим боя"""
	var camera = get_camera()
	if camera:
		camera.combat_zoom()

static func exploration_mode():
	"""Режим исследования"""
	var camera = get_camera()
	if camera:
		camera.exploration_zoom()

# Утилитарные методы

static func is_camera_available() -> bool:
	"""Проверяет, доступна ли камера"""
	return get_camera() != null

static func get_camera_position() -> Vector2:
	"""Возвращает позицию камеры"""
	var camera = get_camera()
	if camera:
		return camera.global_position
	return Vector2.ZERO 