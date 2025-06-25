extends Node
class_name PlayerMovementController

# Контроллер движения и управления игроком

# Параметры движения
@export var max_speed: float = 500.0
@export var acceleration: float = 3000.0
@export var friction: float = 2500.0
@export var max_tilt_angle: float = 0.3

# Параметры доджа
@export var dodge_force: float = 800.0
@export var dodge_cooldown: float = 1.0

# Ссылки на компоненты игрока
var player_body: CharacterBody2D
var player_sprite: Sprite2D

# Переменные движения
var input_vector: Vector2 = Vector2.ZERO

# Переменные доджа
var dodge_timer: float = 0.0
var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO

# Параметры движения для общей системы
var movement_params: CommonMovementSystem.MovementParams

func _ready():
	# Подключаем обработку ввода
	set_process_input(true)
	# Инициализируем параметры движения
	movement_params = CommonMovementSystem.MovementParams.new(
		max_speed, acceleration, friction, max_tilt_angle, dodge_force, dodge_cooldown
	)

func setup_for_player(player: CharacterBody2D, sprite: Sprite2D = null):
	"""Настраивает контроллер для указанного игрока"""
	player_body = player
	player_sprite = sprite
	
	# Если спрайт не передан, пытаемся найти его
	if not player_sprite:
		find_player_sprite()

func find_player_sprite():
	"""Ищет спрайт игрока среди дочерних узлов"""
	if not player_body:
		return
		
	# Пробуем найти спрайт разными способами
	if player_body.has_node("Sprite2D"):
		player_sprite = player_body.get_node("Sprite2D")
	elif player_body.has_node("PlayerSprite"):
		player_sprite = player_body.get_node("PlayerSprite")
	else:
		# Ищем первый найденный Sprite2D среди дочерних узлов
		for child in player_body.get_children():
			if child is Sprite2D:
				player_sprite = child
				break
	
func _input(event):
	"""Обработка событий ввода"""
	if not player_body:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			perform_dodge()

func update_movement(delta):
	"""Основной метод обновления движения (вызывается из _physics_process игрока)"""
	if not player_body:
		return
		
	# Обновляем таймер доджа (используя общую систему)
	var dodge_result = CommonMovementSystem.update_dodge_timer(dodge_timer, delta)
	dodge_timer = dodge_result[0]
	is_dodging = dodge_result[1]
	
	# Обрабатываем ввод (используя общую систему)
	handle_input()
	
	# Применяем движение
	apply_movement(delta)
	
	# Применяем наклон
	apply_tilt(delta)

func handle_input():
	"""Обработка ввода движения (теперь использует общую систему)"""
	# Получаем ввод через общую систему, но также поддерживаем стрелки
	input_vector = CommonMovementSystem.get_wasd_input()
	
	# Дополнительно проверяем стрелки для совместимости
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	
	# Нормализация вектора для диагонального движения
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

func apply_movement(delta):
	"""Применяет движение к игроку (используя общую систему)"""
	if not player_body:
		return
	
	# Используем общую систему для вычисления новой скорости
	player_body.velocity = CommonMovementSystem.apply_movement_to_velocity(
		player_body.velocity, input_vector, movement_params, delta
	)
	
	# Применение движения с использованием встроенного метода CharacterBody2D
	player_body.move_and_slide()

func apply_tilt(delta):
	"""Применяет наклон к спрайту игрока (используя общую систему)"""
	if not player_body:
		return
	
	if player_sprite:
		# Используем расширенную версию с поддержкой skew
		CommonMovementSystem.apply_player_tilt_to_sprite(player_sprite, player_body.velocity, movement_params, delta)
	else:
		# Если спрайт не найден, применяем наклон к самому CharacterBody2D
		CommonMovementSystem.apply_tilt_to_body(player_body, player_body.velocity, movement_params, delta)

func apply_tilt_to_body(delta):
	"""Резервный метод - применяем наклон к самому CharacterBody2D (теперь использует общую систему)"""
	if player_body:
		CommonMovementSystem.apply_tilt_to_body(player_body, player_body.velocity, movement_params, delta)

# === СИСТЕМА ДОДЖА ===

func perform_dodge():
	"""Выполняет додж в направлении движения (используя общую систему)"""
	if not player_body:
		return
	
	# Проверяем возможность доджа через общую систему
	if not CommonMovementSystem.can_perform_dodge(dodge_timer, input_vector):
		return
	
	# Выполняем додж через общую систему
	player_body.velocity = CommonMovementSystem.perform_dodge_on_velocity(
		player_body.velocity, input_vector, dodge_force
	)
	
	# Запускаем перезарядку
	dodge_timer = dodge_cooldown
	is_dodging = true

# === УТИЛИТАРНЫЕ МЕТОДЫ ===

func can_dodge() -> bool:
	"""Проверяет, может ли игрок выполнить додж (используя общую систему)"""
	return CommonMovementSystem.can_perform_dodge(dodge_timer, input_vector)

func is_dodge_on_cooldown() -> bool:
	"""Проверяет, находится ли додж на перезарядке"""
	return dodge_timer > 0

func get_dodge_cooldown_remaining() -> float:
	"""Возвращает оставшееся время перезарядки доджа"""
	return max(0.0, dodge_timer)

func get_dodge_cooldown_progress() -> float:
	"""Возвращает прогресс перезарядки доджа (0.0 - готов, 1.0 - только что использован)"""
	if dodge_cooldown <= 0:
		return 0.0
	return get_dodge_cooldown_remaining() / dodge_cooldown

func get_current_speed() -> float:
	"""Возвращает текущую скорость игрока (используя общую систему)"""
	if player_body:
		return CommonMovementSystem.get_speed_from_velocity(player_body.velocity)
	return 0.0

func get_player_velocity() -> Vector2:
	"""Возвращает текущую скорость игрока как вектор"""
	if player_body:
		return player_body.velocity
	return Vector2.ZERO

func get_input_direction() -> Vector2:
	"""Возвращает текущее направление ввода"""
	return input_vector

func is_moving() -> bool:
	"""Проверяет, движется ли игрок (используя общую систему)"""
	return CommonMovementSystem.is_moving_from_input(input_vector)

func cleanup():
	"""Очистка ресурсов"""
	player_body = null
	player_sprite = null 
