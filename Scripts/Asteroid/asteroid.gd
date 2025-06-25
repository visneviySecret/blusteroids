extends RigidBody2D
class_name Asteroid

# Сигналы
signal destroyed  # Испускается при уничтожении астероида

# Импорт общей системы движения
const MovementSystem = preload("../utils/common_movement_system.gd")

# Импорт конфига коллизий
const Layers = preload("res://Scripts/config/collision_layers.gd")

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

# Параметры движения для общей системы
var movement_params: MovementSystem.MovementParams

func _ready():
	current_health = max_health
	setup_asteroid()
	# Инициализируем параметры движения
	movement_params = MovementSystem.MovementParams.new(
		max_speed, acceleration, friction, max_tilt_angle, dodge_force, dodge_cooldown
	)

func setup_asteroid():
	"""Настраивает астероид"""
	# Добавляем в группу для зацепления крюком
	add_to_group("grappleable_objects")
	
	# Отключаем гравитацию для астероида, чтобы он завис в воздухе
	gravity_scale = 0.0
	# Делаем астероид кинематическим, чтобы он не реагировал на физику по умолчанию
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Настраиваем слои коллизий используя конфиг
	# Астероид находится на слое препятствий
	collision_layer = Layers.OBSTACLES
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
	
	# Устанавливаем z-index игрока ниже астероида
	if rider.has_method("set"):
		rider.z_index = 9
	
	# Разморозить астероид для движения
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	# Вычисляем верхнюю точку астероида
	var asteroid_top_y = calculate_asteroid_top()
	
	# Размещаем игрока на верхушке астероида
	rider_offset = Vector2(0, asteroid_top_y - 30)  # -30 для зазора над астероидом
	
	# Сразу перемещаем игрока в правильную позицию
	update_rider_position()
	
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
	
	# Восстанавливаем исходный z-index игрока
	if rider and rider.has_method("set"):
		rider.z_index = 20  # Устанавливаем высокий z-index после схода
	
	is_being_ridden = false
	rider = null
	
	# Заморозить астероид снова
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	asteroid_velocity = Vector2.ZERO

func update_movement(delta):
	"""Обновляет движение астероида (используя общую систему)"""
	# Получаем ввод от игрока
	input_vector = MovementSystem.get_wasd_input()
	
	# Обновляем таймер доджа
	var dodge_result = MovementSystem.update_dodge_timer(dodge_timer, delta)
	dodge_timer = dodge_result[0]
	is_dodging = dodge_result[1]
	
	# Обработка доджа (пробел) - только при нажатии
	if Input.is_action_just_pressed("ui_accept"):
		perform_dodge()
	
	# Применяем движение
	apply_movement(delta)
	
	# Применяем наклон
	apply_tilt(delta)

func get_input():
	"""Получает ввод от игрока (теперь использует общую систему)"""
	input_vector = MovementSystem.get_wasd_input()

func apply_movement(delta):
	"""Применяет движение к астероиду (используя общую систему)"""
	asteroid_velocity = MovementSystem.apply_movement_to_velocity(
		asteroid_velocity, input_vector, movement_params, delta
	)
	
	# Применяем скорость к астероиду
	var collision = move_and_collide(asteroid_velocity * delta)
	if collision:
		# Простая обработка столкновений - останавливаемся
		asteroid_velocity = MovementSystem.handle_collision_stop(asteroid_velocity)

func apply_tilt(delta):
	"""Применяет наклон к астероиду при движении (используя общую систему)"""
	MovementSystem.apply_tilt_to_sprite(asteroid_sprite, asteroid_velocity, movement_params, delta)

func update_dodge_timer(delta):
	"""Обновляет таймер перезарядки доджа (теперь использует общую систему)"""
	var dodge_result = MovementSystem.update_dodge_timer(dodge_timer, delta)
	dodge_timer = dodge_result[0]
	is_dodging = dodge_result[1]

func perform_dodge():
	"""Выполняет додж астероида в направлении движения (используя общую систему)"""
	if not MovementSystem.can_perform_dodge(dodge_timer, input_vector):
		return
	
	# Выполняем додж
	asteroid_velocity = MovementSystem.perform_dodge_on_velocity(
		asteroid_velocity, input_vector, dodge_force
	)
	
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
	"""Проверяет, может ли астероид выполнить додж (используя общую систему)"""
	return MovementSystem.can_perform_dodge(dodge_timer, input_vector) and is_being_ridden

func get_asteroid_velocity() -> Vector2:
	"""Возвращает текущую скорость астероида"""
	return asteroid_velocity

func is_moving() -> bool:
	"""Проверяет, движется ли астероид (используя общую систему)"""
	return MovementSystem.is_moving_from_input(input_vector) and is_being_ridden

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
	print("Крюк зацепился за астероид")
	
	# Добавляем визуальный эффект зацепления
	if asteroid_sprite:
		# Кратковременно подсвечиваем астероид
		var original_modulate = asteroid_sprite.modulate
		asteroid_sprite.modulate = Color.YELLOW  # Желтое свечение при зацеплении
		
		# Создаем таймер для возврата цвета
		var timer = Timer.new()
		timer.wait_time = 0.3
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if asteroid_sprite:
				asteroid_sprite.modulate = original_modulate
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

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
	# Испускаем сигнал уничтожения ПЕРЕД началом процесса уничтожения
	destroyed.emit()
	print("Астероид уничтожен - испущен сигнал destroyed")
	
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