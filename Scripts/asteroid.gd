extends RigidBody2D
class_name Asteroid

# Скрипт астероида с возможностью зацепления и уничтожения

@export var max_health: float = 20.0  # 2 попадания лазера по 10 урона
@export var asteroid_size: Vector2 = Vector2(100, 100)

# Параметры движения (когда игрок на астероиде)
@export var max_speed: float = 400.0  # Чуть медленнее игрока
@export var acceleration: float = 2500.0
@export var friction: float = 2000.0
@export var max_tilt_angle: float = 0.2
@export var dodge_force: float = 600.0  # Чуть слабее игрока
@export var dodge_cooldown: float = 1.0

var current_health: float
var asteroid_sprite: Sprite2D
var collision_shape: CollisionShape2D

# Состояние езды
var is_being_ridden: bool = false
var rider: Node2D = null
var rider_offset: Vector2 = Vector2.ZERO  # Будет вычисляться динамически

# Переменные движения
var input_vector: Vector2 = Vector2.ZERO
var asteroid_velocity: Vector2 = Vector2.ZERO

# Переменные доджа
var dodge_timer: float = 0.0
var is_dodging: bool = false

func _ready():
	current_health = max_health
	setup_asteroid()

func setup_asteroid():
	"""Настраивает астероид"""
	# Добавляем в группу для зацепления крюком
	add_to_group("grappleable_objects")
	
	# Отключаем гравитацию для астероида, чтобы он завис в воздухе
	gravity_scale = 0.0
	# Делаем астероид кинематическим, чтобы он не реагировал на физику по умолчанию
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Настраиваем слои коллизий
	# Астероид находится на слое 3 (препятствия), чтобы крюк и лазеры могли с ним сталкиваться
	collision_layer = 4  # Слой 3 (2^2 = 4)
	collision_mask = 0   # Астероид не должен сталкиваться с другими объектами сам
	
	# Находим существующие компоненты (они уже созданы в сцене)
	find_existing_components()

func _physics_process(delta):
	"""Обновляет движение астероида, если на нем едет игрок"""
	if is_being_ridden and rider:
		update_movement(delta)
		update_rider_position()

func start_riding(player: Node2D):
	"""Начинает езду игрока на астероиде"""
	if is_being_ridden:
		return false
	
	is_being_ridden = true
	rider = player
	
	# Разморозить астероид для движения
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	# Вычисляем верхнюю точку астероида
	var asteroid_top_y = calculate_asteroid_top()
	
	# Размещаем игрока на верхушке астероида
	rider_offset = Vector2(375, asteroid_top_y - 50)  # -30 для зазора над астероидом
	
	# Сразу перемещаем игрока в правильную позицию
	update_rider_position()
	
	print("Игрок сел на астероид!")
	return true

func calculate_asteroid_top() -> float:
	"""Вычисляет Y-координату верхней точки астероида относительно его центра"""
	var top_offset = -50.0  # Значение по умолчанию
	
	if collision_shape and collision_shape.shape:
		var shape_position = collision_shape.position.y  # Смещение коллизии относительно центра
		
		if collision_shape.shape is CapsuleShape2D:
			var capsule = collision_shape.shape as CapsuleShape2D
			top_offset = shape_position - (capsule.height / 2.0)
		elif collision_shape.shape is RectangleShape2D:
			var rect = collision_shape.shape as RectangleShape2D
			top_offset = shape_position - (rect.size.y / 2.0)
		elif collision_shape.shape is CircleShape2D:
			var circle = collision_shape.shape as CircleShape2D
			top_offset = shape_position - circle.radius
	
	return top_offset

func stop_riding():
	"""Останавливает езду на астероиде"""
	if not is_being_ridden:
		return
	
	is_being_ridden = false
	rider = null
	
	# Заморозить астероид снова
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	asteroid_velocity = Vector2.ZERO
	
	print("Игрок слез с астероида!")

func update_movement(delta):
	"""Обновляет движение астероида (копия логики из PlayerMovementController)"""
	# Получаем ввод от игрока
	get_input()
	
	# Обновляем таймер доджа
	update_dodge_timer(delta)
	
	# Обработка доджа (пробел) - только при нажатии
	if Input.is_action_just_pressed("ui_accept"):
		perform_dodge()
	
	# Применяем движение
	apply_movement(delta)
	
	# Применяем наклон
	apply_tilt(delta)

func get_input():
	"""Получает ввод от игрока (копия логики из PlayerMovementController)"""
	input_vector = Vector2.ZERO
	
	# Используем те же клавиши, что и игрок (WASD)
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	
	input_vector = input_vector.normalized()

func apply_movement(delta):
	"""Применяет движение к астероиду (копия логики из PlayerMovementController)"""
	if input_vector != Vector2.ZERO:
		# Ускорение в направлении ввода
		asteroid_velocity = asteroid_velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Применяем трение
		asteroid_velocity = asteroid_velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Применяем скорость к астероиду
	var collision = move_and_collide(asteroid_velocity * delta)
	if collision:
		# Простая обработка столкновений - останавливаемся
		asteroid_velocity = Vector2.ZERO

func apply_tilt(delta):
	"""Применяет наклон к астероиду при движении"""
	if not asteroid_sprite:
		return
	
	var target_rotation: float = 0.0
	
	# Наклон в зависимости от скорости
	if abs(asteroid_velocity.x) > abs(asteroid_velocity.y):
		target_rotation = asteroid_velocity.x / max_speed * max_tilt_angle
	else:
		target_rotation = asteroid_velocity.y / max_speed * max_tilt_angle * 0.5
	
	# Плавно применяем поворот
	asteroid_sprite.rotation = lerp(asteroid_sprite.rotation, target_rotation, 8.0 * delta)

func update_dodge_timer(delta):
	"""Обновляет таймер перезарядки доджа"""
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false

func perform_dodge():
	"""Выполняет додж астероида в направлении движения"""
	# Проверяем, можем ли мы выполнить додж
	if dodge_timer > 0:
		return  # Додж на перезарядке
	
	# Проверяем, нажимает ли игрок клавиши движения
	if input_vector.length() == 0:
		return  # Игрок не нажимает клавиши движения
	
	# Выполняем додж в направлении ввода
	var dodge_direction = input_vector.normalized()
	asteroid_velocity += dodge_direction * dodge_force
	
	# Запускаем перезарядку
	dodge_timer = dodge_cooldown
	is_dodging = true

func update_rider_position():
	"""Обновляет позицию игрока, чтобы он двигался вместе с астероидом"""
	if rider:
		rider.global_position = global_position + rider_offset
		
		# Фиксируем вращение игрока, чтобы он не наклонялся
		rider.rotation = 0.0
		
		# Также фиксируем вращение спрайта игрока, если он есть
		if rider.has_method("get") and "player_sprite" in rider:
			var sprite = rider.player_sprite
			if sprite:
				sprite.rotation = 0.0
				sprite.skew = 0.0

func can_dodge() -> bool:
	"""Проверяет, может ли астероид выполнить додж"""
	return dodge_timer <= 0 and input_vector.length() > 0 and is_being_ridden

func get_asteroid_velocity() -> Vector2:
	"""Возвращает текущую скорость астероида"""
	return asteroid_velocity

func is_moving() -> bool:
	"""Проверяет, движется ли астероид"""
	return input_vector.length() > 0 and is_being_ridden

func find_existing_components():
	"""Находит существующие компоненты астероида в сцене"""
	# Ищем спрайт
	for child in get_children():
		if child is Sprite2D:
			asteroid_sprite = child
		elif child is CollisionShape2D:
			collision_shape = child

func can_be_grappled() -> bool:
	"""Проверяет, можно ли зацепиться за этот астероид"""
	return true

func on_grappled():
	"""Вызывается когда к астероиду цепляется крюк"""
	# Можно добавить визуальные эффекты или звуки
	pass

func take_damage(damage: float):
	"""Получает урон от лазера"""
	current_health -= damage
	current_health = max(0, current_health)
	
	# Визуальная обратная связь при получении урона
	show_damage_effect()
	
	# Уничтожаем астероид если здоровье закончилось
	if current_health <= 0:
		destroy_asteroid()

func show_damage_effect():
	"""Показывает эффект получения урона"""
	if not asteroid_sprite:
		return
	
	# Кратковременно меняем цвет на красный
	var original_modulate = asteroid_sprite.modulate
	asteroid_sprite.modulate = Color.RED
	
	# Создаем таймер для возврата цвета
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if asteroid_sprite:
			asteroid_sprite.modulate = original_modulate
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func destroy_asteroid():
	"""Уничтожает астероид"""
	# Создаем эффект уничтожения
	create_destruction_effect()
	
	# Удаляем астероид
	queue_free()

func create_destruction_effect():
	"""Создает эффект уничтожения астероида"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 1.5
	particles.speed_scale = 2.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color.GRAY
	
	# Добавляем частицы в родительскую сцену
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Удаляем частицы через некоторое время
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(timer)
	timer.start()

func is_alive() -> bool:
	"""Проверяет, жив ли астероид"""
	return current_health > 0

func get_health_ratio() -> float:
	"""Возвращает отношение текущего здоровья к максимальному"""
	return current_health / max_health 