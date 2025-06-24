extends CharacterBody2D

# Максимальная скорость движения персонажа
@export var max_speed: float = 500.0
# Скорость ускорения
@export var acceleration: float = 3000.0
# Скорость замедления (трение)
@export var friction: float = 2500.0
# Максимальный угол наклона в радианах
@export var max_tilt_angle: float = 0.3

# Направление ввода
var input_vector: Vector2 = Vector2.ZERO
# Ссылка на спрайт игрока
var player_sprite: Sprite2D
# Система дыма
var smoke_system: SmokeSystem

func _ready():
	# Получаем ссылку на спрайт (пробуем разные варианты)
	find_player_sprite()
	# Подключаем систему дыма
	setup_smoke_system()

func find_player_sprite():
	# Пробуем найти спрайт разными способами
	if has_node("Sprite2D"):
		player_sprite = get_node("Sprite2D")
	elif has_node("PlayerSprite"):
		player_sprite = get_node("PlayerSprite")
	else:
		# Ищем первый найденный Sprite2D среди дочерних узлов
		for child in get_children():
			if child is Sprite2D:
				player_sprite = child
				break
	
	if not player_sprite:
		for child in get_children():
			print("- ", child.name, " (", child.get_class(), ")")

func setup_smoke_system():
	# Создаем и настраиваем систему дыма
	smoke_system = SmokeSystem.new()
	get_parent().add_child.call_deferred(smoke_system)
	# Устанавливаем себя как цель для системы дыма
	smoke_system.set_target.call_deferred(self)

func _physics_process(delta):
	# Обработка ввода и движения
	handle_input()
	move_player(delta)
	apply_tilt(delta)

func handle_input():
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

func move_player(delta):
	# Если есть ввод - ускоряемся в направлении ввода
	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Если нет ввода - замедляемся до полной остановки
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Применение движения с использованием встроенного метода CharacterBody2D
	move_and_slide()

func apply_tilt(delta):
	# Применяем наклон к спрайту, если он существует
	if not player_sprite:
		# Если спрайт не найден, применяем наклон к самому CharacterBody2D
		# (это может не работать идеально, но лучше чем ничего)
		apply_tilt_to_body(delta)
		return
		
	# Вычисляем целевой угол наклона на основе скорости
	var target_rotation: float = 0.0
	var target_skew: float = 0.0
	
	# Наклон при движении по горизонтали (влево/вправо)
	if abs(velocity.x) > abs(velocity.y):
		target_rotation = velocity.x / max_speed * max_tilt_angle
		target_skew = 0.0
	else:
		# При движении вверх - наклон назад, вниз - вперед
		target_rotation = 0.0
		target_skew = velocity.y / max_speed * max_tilt_angle
	
	# Плавно применяем поворот и наклон к спрайту
	player_sprite.rotation = lerp(player_sprite.rotation, target_rotation, 10.0 * delta)
	player_sprite.skew = lerp(player_sprite.skew, target_skew, 10.0 * delta)

func apply_tilt_to_body(delta):
	# Резервный метод - применяем наклон к самому CharacterBody2D
	var target_rotation: float = 0.0
	
	# Только поворот для основного тела (skew не поддерживается)
	if abs(velocity.x) > abs(velocity.y):
		target_rotation = velocity.x / max_speed * max_tilt_angle
	else:
		target_rotation = velocity.y / max_speed * max_tilt_angle * 0.5
	
	# Плавно применяем поворот
	rotation = lerp(rotation, target_rotation, 10.0 * delta)

# Методы для управления системой дыма
func enable_smoke(enabled: bool = true):
	if smoke_system:
		smoke_system.enable_smoke(enabled)

func clear_smoke():
	if smoke_system:
		smoke_system.clear_all_particles()
