extends Node
class_name CameraEffects

# Ссылка на камеру
var camera: Camera2D
# Параметры встряски
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_frequency: float = 20.0
var original_position: Vector2

# Параметры зума
var target_zoom: Vector2
var zoom_speed: float = 2.0
var default_zoom: Vector2 = Vector2(1, 1)

# Параметры наклона (для эффекта поворота)
var target_rotation: float = 0.0
var rotation_speed: float = 3.0

func _ready():
	# Находим камеру
	if get_parent() is Camera2D:
		camera = get_parent()
		target_zoom = camera.zoom
		default_zoom = camera.zoom

func _process(delta):
	if not camera:
		return
	
	update_shake(delta)
	update_zoom(delta)
	update_rotation(delta)

func update_shake(delta):
	"""Обновляет эффект встряски камеры"""
	if shake_timer > 0:
		shake_timer -= delta
		
		# Генерируем случайное смещение
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		# Применяем смещение с учетом частоты
		var shake_factor = sin(shake_timer * shake_frequency * PI * 2)
		shake_offset *= shake_factor
		
		# Применяем к позиции камеры
		camera.offset = shake_offset
		
		# Уменьшаем интенсивность со временем
		shake_intensity = lerp(shake_intensity, 0.0, delta * 2.0)
	else:
		# Встряска закончилась, возвращаем камеру в исходное положение
		camera.offset = Vector2.ZERO
		shake_intensity = 0.0

func update_zoom(delta):
	"""Обновляет плавное изменение зума"""
	if camera.zoom != target_zoom:
		camera.zoom = camera.zoom.lerp(target_zoom, zoom_speed * delta)

func update_rotation(delta):
	"""Обновляет плавный поворот камеры"""
	if camera.rotation != target_rotation:
		camera.rotation = lerp_angle(camera.rotation, target_rotation, rotation_speed * delta)

# Публичные методы для управления эффектами

func shake_camera(intensity: float, duration: float, frequency: float = 20.0):
	"""Запускает встряску камеры"""
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shake_frequency = frequency

func set_zoom(new_zoom: Vector2, speed: float = 2.0):
	"""Устанавливает новый зум камеры"""
	target_zoom = new_zoom
	zoom_speed = speed

func set_zoom_factor(factor: float, speed: float = 2.0):
	"""Устанавливает зум через коэффициент"""
	set_zoom(default_zoom * factor, speed)

func reset_zoom(speed: float = 2.0):
	"""Возвращает зум к значению по умолчанию"""
	set_zoom(default_zoom, speed)

func set_rotation(angle: float, speed: float = 3.0):
	"""Устанавливает поворот камеры"""
	target_rotation = angle
	rotation_speed = speed

func reset_rotation(speed: float = 3.0):
	"""Возвращает поворот камеры к 0"""
	set_rotation(0.0, speed)

# Предустановленные эффекты

func explosion_shake():
	"""Встряска от взрыва"""
	shake_camera(15.0, 0.5, 25.0)

func hit_shake():
	"""Легкая встряска от попадания"""
	shake_camera(8.0, 0.3, 30.0)

func landing_shake():
	"""Встряска от приземления"""
	shake_camera(12.0, 0.4, 20.0)

func zoom_in_combat():
	"""Приближение для боя"""
	set_zoom_factor(1.2, 1.5)

func zoom_out_exploration():
	"""Отдаление для исследования"""
	set_zoom_factor(0.8, 1.0)

func tilt_on_turn(direction: float):
	"""Наклон камеры при повороте"""
	set_rotation(direction * 0.1, 5.0)

# Утилитарные методы

func is_shaking() -> bool:
	"""Проверяет, трясется ли камера"""
	return shake_timer > 0

func get_current_zoom() -> Vector2:
	"""Возвращает текущий зум"""
	if camera:
		return camera.zoom
	return Vector2.ONE

func stop_all_effects():
	"""Останавливает все эффекты и возвращает камеру в нормальное состояние"""
	shake_timer = 0
	shake_intensity = 0
	camera.offset = Vector2.ZERO
	reset_zoom(3.0)
	reset_rotation(3.0) 