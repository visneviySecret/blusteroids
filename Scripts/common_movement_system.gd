extends RefCounted
class_name CommonMovementSystem

# Общая система движения для игрока и астероида

# Структура для параметров движения
class MovementParams:
	var max_speed: float
	var acceleration: float
	var friction: float
	var max_tilt_angle: float
	var dodge_force: float
	var dodge_cooldown: float
	
	func _init(speed: float, accel: float, frict: float, tilt: float, dodge_f: float, dodge_cd: float):
		max_speed = speed
		acceleration = accel
		friction = frict
		max_tilt_angle = tilt
		dodge_force = dodge_f
		dodge_cooldown = dodge_cd

# Статические методы для обработки ввода
static func get_wasd_input() -> Vector2:
	"""Получает ввод WASD и возвращает нормализованный вектор"""
	var input_vector = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	
	return input_vector.normalized()

# Статические методы для движения
static func apply_movement_to_velocity(current_velocity: Vector2, input_vector: Vector2, params: MovementParams, delta: float) -> Vector2:
	"""Применяет движение к скорости на основе ввода"""
	if input_vector.length() > 0:
		# Ускорение в направлении ввода
		return current_velocity.move_toward(input_vector * params.max_speed, params.acceleration * delta)
	else:
		# Применяем трение
		return current_velocity.move_toward(Vector2.ZERO, params.friction * delta)

# Статические методы для наклона
static func calculate_tilt_rotation(velocity: Vector2, max_speed: float, max_tilt_angle: float) -> float:
	"""Вычисляет угол наклона на основе скорости"""
	var target_rotation: float = 0.0
	
	# Наклон в зависимости от скорости
	if abs(velocity.x) > abs(velocity.y):
		target_rotation = velocity.x / max_speed * max_tilt_angle
	else:
		target_rotation = velocity.y / max_speed * max_tilt_angle * 0.5
	
	return target_rotation

static func apply_tilt_to_sprite(sprite: Sprite2D, velocity: Vector2, params: MovementParams, delta: float):
	"""Применяет наклон к спрайту"""
	if not sprite:
		return
	
	var target_rotation = calculate_tilt_rotation(velocity, params.max_speed, params.max_tilt_angle)
	sprite.rotation = lerp(sprite.rotation, target_rotation, 8.0 * delta)

# Расширенная версия для игрока с поддержкой skew
static func apply_player_tilt_to_sprite(sprite: Sprite2D, velocity: Vector2, params: MovementParams, delta: float):
	"""Применяет наклон к спрайту игрока с поддержкой skew"""
	if not sprite:
		return
	
	# Вычисляем целевой угол наклона и skew
	var target_rotation: float = 0.0
	var target_skew: float = 0.0
	
	# Наклон при движении по горизонтали (влево/вправо)
	if abs(velocity.x) > abs(velocity.y):
		target_rotation = velocity.x / params.max_speed * params.max_tilt_angle
		target_skew = 0.0
	else:
		# При движении вверх - наклон назад, вниз - вперед
		target_rotation = 0.0
		target_skew = velocity.y / params.max_speed * params.max_tilt_angle
	
	# Плавно применяем поворот и наклон к спрайту
	sprite.rotation = lerp(sprite.rotation, target_rotation, 10.0 * delta)
	sprite.skew = lerp(sprite.skew, target_skew, 10.0 * delta)

# Fallback для основного тела (без skew)
static func apply_tilt_to_body(body: Node2D, velocity: Vector2, params: MovementParams, delta: float):
	"""Резервный метод - применяем наклон к основному телу"""
	if not body:
		return
	
	var target_rotation = calculate_tilt_rotation(velocity, params.max_speed, params.max_tilt_angle)
	# Плавно применяем поворот
	body.rotation = lerp(body.rotation, target_rotation, 10.0 * delta)

# Статические методы для доджа
static func update_dodge_timer(dodge_timer: float, delta: float) -> Array:
	"""Обновляет таймер доджа. Возвращает [новый_таймер, is_dodging]"""
	var new_timer = dodge_timer
	var is_dodging = false
	
	if new_timer > 0:
		new_timer -= delta
		if new_timer <= 0:
			is_dodging = false
	
	return [new_timer, is_dodging]

static func can_perform_dodge(dodge_timer: float, input_vector: Vector2) -> bool:
	"""Проверяет, можно ли выполнить додж"""
	return dodge_timer <= 0 and input_vector.length() > 0

static func perform_dodge_on_velocity(current_velocity: Vector2, input_vector: Vector2, dodge_force: float) -> Vector2:
	"""Выполняет додж и возвращает новую скорость"""
	if input_vector.length() == 0:
		return current_velocity
	
	var dodge_direction = input_vector.normalized()
	return current_velocity + dodge_direction * dodge_force

# Утилитарные методы
static func get_speed_from_velocity(velocity: Vector2) -> float:
	"""Возвращает скорость из вектора скорости"""
	return velocity.length()

static func is_moving_from_input(input_vector: Vector2) -> bool:
	"""Проверяет, есть ли движение по вводу"""
	return input_vector.length() > 0

# Методы для работы с коллизиями
static func handle_collision_stop(velocity: Vector2) -> Vector2:
	"""Останавливает движение при столкновении"""
	return Vector2.ZERO 