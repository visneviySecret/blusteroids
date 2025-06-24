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

func _ready():
	# Подключаем обработку ввода
	set_process_input(true)

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
		
	# Обновляем таймер доджа
	update_dodge_timer(delta)
	
	# Обрабатываем ввод
	handle_input()
	
	# Применяем движение
	apply_movement(delta)
	
	# Применяем наклон
	apply_tilt(delta)

func handle_input():
	"""Обработка ввода движения"""
	# Сброс вектора ввода
	input_vector = Vector2.ZERO
	
	# Проверка нажатых клавиш WASD
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	
	# Нормализация вектора для диагонального движения
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

func apply_movement(delta):
	"""Применяет движение к игроку"""
	if not player_body:
		return
		
	# Если есть ввод - ускоряемся в направлении ввода
	if input_vector.length() > 0:
		player_body.velocity = player_body.velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Если нет ввода - замедляемся до полной остановки
		player_body.velocity = player_body.velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Применение движения с использованием встроенного метода CharacterBody2D
	player_body.move_and_slide()

func apply_tilt(delta):
	"""Применяет наклон к спрайту игрока"""
	if not player_sprite or not player_body:
		# Если спрайт не найден, применяем наклон к самому CharacterBody2D
		apply_tilt_to_body(delta)
		return
		
	# Вычисляем целевой угол наклона на основе скорости
	var target_rotation: float = 0.0
	var target_skew: float = 0.0
	
	# Наклон при движении по горизонтали (влево/вправо)
	if abs(player_body.velocity.x) > abs(player_body.velocity.y):
		target_rotation = player_body.velocity.x / max_speed * max_tilt_angle
		target_skew = 0.0
	else:
		# При движении вверх - наклон назад, вниз - вперед
		target_rotation = 0.0
		target_skew = player_body.velocity.y / max_speed * max_tilt_angle
	
	# Плавно применяем поворот и наклон к спрайту
	player_sprite.rotation = lerp(player_sprite.rotation, target_rotation, 10.0 * delta)
	player_sprite.skew = lerp(player_sprite.skew, target_skew, 10.0 * delta)

func apply_tilt_to_body(delta):
	"""Резервный метод - применяем наклон к самому CharacterBody2D"""
	if not player_body:
		return
		
	var target_rotation: float = 0.0
	
	# Только поворот для основного тела (skew не поддерживается)
	if abs(player_body.velocity.x) > abs(player_body.velocity.y):
		target_rotation = player_body.velocity.x / max_speed * max_tilt_angle
	else:
		target_rotation = player_body.velocity.y / max_speed * max_tilt_angle * 0.5
	
	# Плавно применяем поворот
	player_body.rotation = lerp(player_body.rotation, target_rotation, 10.0 * delta)

# === СИСТЕМА ДОДЖА ===

func update_dodge_timer(delta):
	"""Обновляет таймер перезарядки доджа"""
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false

func perform_dodge():
	"""Выполняет додж в направлении движения"""
	if not player_body:
		return
		
	# Проверяем, можем ли мы выполнить додж
	if dodge_timer > 0:
		return  # Додж на перезарядке
	
	# Проверяем, нажимает ли игрок клавиши движения
	if input_vector.length() == 0:
		return  # Игрок не нажимает клавиши движения
	
	# Выполняем додж в направлении ввода
	dodge_direction = input_vector.normalized()
	player_body.velocity += dodge_direction * dodge_force
	
	# Запускаем перезарядку
	dodge_timer = dodge_cooldown
	is_dodging = true

# === УТИЛИТАРНЫЕ МЕТОДЫ ===

func can_dodge() -> bool:
	"""Проверяет, может ли игрок выполнить додж"""
	return dodge_timer <= 0 and input_vector.length() > 0

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
	"""Возвращает текущую скорость игрока"""
	if player_body:
		return player_body.velocity.length()
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
	"""Проверяет, движется ли игрок"""
	return input_vector.length() > 0

func cleanup():
	"""Очистка ресурсов"""
	player_body = null
	player_sprite = null 