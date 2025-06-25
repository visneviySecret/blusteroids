extends Camera2D
class_name CameraFollow

# Импорт класса эффектов
const CameraEffects = preload("res://Scripts/Camera/camera_effects.gd")

# Цель, за которой следует камера
var target: Node2D
# Скорость следования камеры
@export var follow_speed: float = 5.0
# Смещение камеры относительно цели
@export var camera_offset: Vector2 = Vector2.ZERO
# Зона нечувствительности (камера не двигается если цель в этой зоне)
@export var deadzone_size: Vector2 = Vector2(50, 50)
# Максимальное расстояние от цели
@export var max_distance: float = 200.0
# Включить ли предсказание движения
@export var enable_prediction: bool = true
# Сила предсказания движения
@export var prediction_strength: float = 0.3
# Сглаживание камеры
@export var smoothing_enabled: bool = true

# Внутренние переменные
var target_position: Vector2
var previous_target_position: Vector2
var velocity_prediction: Vector2

# Система эффектов
var effects_system: CameraEffects

func _ready():
	# Делаем эту камеру текущей
	make_current()
	
	# Создаем систему эффектов
	setup_effects_system()
	
	# Если цель не установлена, пытаемся найти игрока
	if not target:
		find_player_target()

func setup_effects_system():
	"""Настраивает систему эффектов камеры"""
	effects_system = CameraEffects.new()
	effects_system.name = "CameraEffects"
	add_child(effects_system)

func find_player_target():
	"""Ищет игрока в сцене"""
	# Ищем в группе игроков
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		set_target(players[0])
	else:
		# Ищем по имени узла
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			set_target(player_node)

func set_target(new_target: Node2D):
	"""Устанавливает новую цель для слежения"""
	target = new_target
	if target:
		target_position = target.global_position
		previous_target_position = target_position
		# Сразу устанавливаем камеру на позицию цели
		global_position = target_position + camera_offset

func _process(delta):
	if not target or not is_instance_valid(target):
		return
	
	update_camera_position(delta)

func update_camera_position(delta):
	"""Обновляет позицию камеры"""
	var current_target_pos = target.global_position
	
	# Вычисляем предсказание движения
	if enable_prediction:
		var target_velocity = (current_target_pos - previous_target_position) / delta
		velocity_prediction = target_velocity * prediction_strength
	else:
		velocity_prediction = Vector2.ZERO
	
	# Целевая позиция с учетом смещения и предсказания
	target_position = current_target_pos + camera_offset + velocity_prediction
	
	# Проверяем зону нечувствительности
	var distance_to_target = global_position.distance_to(target_position)
	var deadzone_distance = deadzone_size.length() / 2.0
	
	if distance_to_target <= deadzone_distance:
		# Находимся в зоне нечувствительности, не двигаемся
		previous_target_position = current_target_pos
		return
	
	# Ограничиваем максимальное расстояние
	if distance_to_target > max_distance:
		var direction = (target_position - global_position).normalized()
		target_position = global_position + direction * max_distance
	
	# Плавное движение камеры
	if smoothing_enabled:
		global_position = global_position.lerp(target_position, follow_speed * delta)
	else:
		global_position = target_position
	
	previous_target_position = current_target_pos

func set_follow_speed(speed: float):
	"""Устанавливает скорость следования"""
	follow_speed = speed

func set_camera_offset(new_offset: Vector2):
	"""Устанавливает смещение камеры"""
	camera_offset = new_offset

func set_deadzone(size: Vector2):
	"""Устанавливает размер зоны нечувствительности"""
	deadzone_size = size

func enable_smoothing(enabled: bool):
	"""Включает/выключает сглаживание"""
	smoothing_enabled = enabled

func reset_to_target():
	"""Мгновенно перемещает камеру к цели"""
	if target:
		global_position = target.global_position + camera_offset
		target_position = global_position
		previous_target_position = target.global_position

# Методы для работы с эффектами

func shake_camera(intensity: float, duration: float, frequency: float = 20.0):
	"""Запускает встряску камеры"""
	if effects_system:
		effects_system.shake_camera(intensity, duration, frequency)

func set_zoom_factor(factor: float, speed: float = 2.0):
	"""Устанавливает зум камеры"""
	if effects_system:
		effects_system.set_zoom_factor(factor, speed)

func reset_zoom(speed: float = 2.0):
	"""Возвращает зум к значению по умолчанию"""
	if effects_system:
		effects_system.reset_zoom(speed)

func tilt_camera(angle: float, speed: float = 3.0):
	"""Наклоняет камеру"""
	if effects_system:
		effects_system.set_rotation(angle, speed)

func reset_tilt(speed: float = 3.0):
	"""Убирает наклон камеры"""
	if effects_system:
		effects_system.reset_rotation(speed)

# Предустановленные эффекты

func explosion_effect():
	"""Эффект взрыва"""
	if effects_system:
		effects_system.explosion_shake()

func hit_effect():
	"""Эффект попадания"""
	if effects_system:
		effects_system.hit_shake()

func combat_zoom():
	"""Приближение для боя"""
	if effects_system:
		effects_system.zoom_in_combat()

func exploration_zoom():
	"""Отдаление для исследования"""
	if effects_system:
		effects_system.zoom_out_exploration()

# Утилитарные методы
func get_target() -> Node2D:
	"""Возвращает текущую цель"""
	return target

func is_following() -> bool:
	"""Проверяет, следует ли камера за целью"""
	return target != null and is_instance_valid(target)

func get_distance_to_target() -> float:
	"""Возвращает расстояние до цели"""
	if target:
		return global_position.distance_to(target.global_position)
	return 0.0

func get_effects_system() -> CameraEffects:
	"""Возвращает систему эффектов"""
	return effects_system 
