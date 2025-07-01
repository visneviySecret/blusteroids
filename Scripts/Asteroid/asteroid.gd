extends RigidBody2D
class_name Asteroid

# Сигналы
signal destroyed  # Испускается при уничтожении астероида

# Импорт общей системы движения
const MovementSystem = preload("../utils/common_movement_system.gd")
const VisualEffects = preload("../utils/visual_effects_system.gd")

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

# Параметры инерционного движения (после спрыгивания игрока)
@export var inertia_friction: float = 0.0  # Трение для замедления астероида
@export var inertia_min_speed: float = 15.0  # Минимальная скорость для остановки астероида

# Параметры топливного астероида
@export var is_fuel_asteroid: bool = false  # Является ли астероид топливным
@export var fuel_amount: float = 50.0  # Количество топлива в астероиде
@export var max_fuel_amount: float = 50.0  # Максимальное количество топлива
@export var fuel_extraction_rate: float = 10.0  # Скорость добычи топлива в секунду
@export var fuel_asteroid_texture: Texture2D  # Специальная текстура для топливного астероида

var current_health: float
var asteroid_sprite: Sprite2D
var collision_shape: CollisionShape2D
var fuel_progress_bar: TextureProgressBar  # Прогресс бар топлива

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

# Переменные инерционного движения
var inertia_velocity: Vector2 = Vector2.ZERO  # Скорость движения по инерции
var is_moving_by_inertia: bool = false  # Флаг движения по инерции

# Переменные автономного движения (для спавнера)
var autonomous_velocity: Vector2 = Vector2.ZERO  # Скорость автономного движения
var is_moving_autonomously: bool = false  # Флаг автономного движения

# Параметры инерции для астероида
var inertia_params: MovementSystem.InertiaParams

# Параметры движения для общей системы
var movement_params: MovementSystem.MovementParams

# Переменные для контроля показа лейблов
var fuel_label_timer: float = 0.0
var fuel_label_interval: float = 1.0  # Показывать лейбл каждую секунду

func _ready():
	current_health = max_health
	setup_asteroid()
	# Инициализируем параметры движения
	movement_params = MovementSystem.MovementParams.new(
		max_speed, acceleration, friction, max_tilt_angle, dodge_force, dodge_cooldown
	)
	
	# Инициализируем параметры инерции
	inertia_params = MovementSystem.InertiaParams.new(
		inertia_friction, inertia_min_speed, 0.6, 0.5
	)
	
	# Скрываем прогресс бар топлива для обычных астероидов
	if fuel_progress_bar and not is_fuel_asteroid:
		fuel_progress_bar.visible = false

func setup_asteroid():
	"""Настраивает астероид"""
	# Добавляем в группы
	add_to_group("grappleable_objects")
	add_to_group("asteroids")
	
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
	"""Обновляет движение астероида в зависимости от режима"""
	if is_being_ridden and rider:
		# Движение с игроком
		update_movement(delta)
		update_rider_position()
		
		# Обработка добычи топлива если это топливный астероид
		if is_fuel_asteroid:
			var player_fuel_system = find_player_fuel_system()
			if player_fuel_system:
				update_fuel_extraction(delta, player_fuel_system)
		
	elif is_moving_by_inertia:
		# Инерционное движение после спрыгивания игрока
		update_inertia_movement(delta)
	elif is_moving_autonomously:
		# Автономное движение (для спавнера)
		update_autonomous_movement(delta)

func start_riding(player: Node2D):
	"""Начинает езду игрока на астероиде"""
	if is_being_ridden:
		return false
	
	# Останавливаем автономное движение
	if is_moving_autonomously:
		stop_autonomous_movement()
	
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
	
	# Учитываем масштаб астероида при вычислении верхней точки
	return top_offset * scale.y

func stop_riding():
	"""Останавливает езду на астероиде"""
	if not is_being_ridden:
		return
	
	# Сохраняем текущую скорость движения для инерции
	var current_velocity = asteroid_velocity
	
	# Восстанавливаем исходный z-index игрока
	if rider and rider.has_method("set"):
		rider.z_index = 20  # Устанавливаем высокий z-index после схода
	
	is_being_ridden = false
	rider = null
	
	# Заморозить астероид снова
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	asteroid_velocity = Vector2.ZERO
	
	# Устанавливаем инерционное движение
	set_inertia_velocity(current_velocity)

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

func get_current_speed() -> float:
	"""Возвращает текущую скорость астероида"""
	if is_being_ridden:
		return asteroid_velocity.length()
	elif is_moving_by_inertia:
		return inertia_velocity.length()
	else:
		return 0.0

func get_asteroid_velocity() -> Vector2:
	"""Возвращает текущую скорость астероида"""
	if is_being_ridden:
		return asteroid_velocity
	elif is_moving_by_inertia:
		return inertia_velocity
	else:
		return Vector2.ZERO

func is_moving() -> bool:
	"""Проверяет, движется ли астероид (используя общую систему)"""
	if is_being_ridden:
		return MovementSystem.is_moving_from_input(input_vector)
	elif is_moving_by_inertia:
		return inertia_velocity.length() > inertia_min_speed
	elif is_moving_autonomously:
		return autonomous_velocity.length() > 0
	else:
		return false

func find_existing_components():
	"""Находит существующие компоненты астероида в сцене"""
	# Ищем спрайт и прогресс бар топлива
	for child in get_children():
		if child is Sprite2D:
			asteroid_sprite = child
		elif child is CollisionShape2D:
			collision_shape = child
		elif child is TextureProgressBar and child.name == "AsteroidFuel":
			fuel_progress_bar = child

func can_be_grappled() -> bool:
	"""Проверяет, можно ли зацепиться за этот астероид"""
	return true

func on_grappled():
	"""Вызывается когда к астероиду цепляется крюк"""
	# Добавляем визуальный эффект зацепления через общую систему
	if asteroid_sprite:
		var glow_color = Color.YELLOW  # Желтое свечение по умолчанию
		
		# Разные цвета для разных состояний
		if is_being_ridden:
			glow_color = Color.CYAN  # Голубое для астероида с игроком
		elif is_moving_by_inertia:
			glow_color = Color.ORANGE  # Оранжевое для движущегося по инерции
		
		VisualEffects.show_grappling_effect(asteroid_sprite, glow_color, 0.3)

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
	
	# Используем общую систему визуальных эффектов
	VisualEffects.show_damage_effect(asteroid_sprite, Color.RED, 0.2)

func destroy_asteroid():
	"""Уничтожает астероид"""
	# Испускаем сигнал уничтожения ПЕРЕД началом процесса уничтожения
	destroyed.emit()
	
	# Создаем эффект уничтожения
	create_destruction_effect()
	
	# Удаляем астероид
	queue_free()

func create_destruction_effect():
	"""Создает эффект уничтожения астероида"""
	if not get_parent():
		return
	
	# Используем общую систему визуальных эффектов
	VisualEffects.create_destruction_particles(get_parent(), global_position, Color.GRAY, 30)

func is_alive() -> bool:
	"""Проверяет, жив ли астероид"""
	return current_health > 0

func get_health_ratio() -> float:
	"""Возвращает отношение текущего здоровья к максимальному"""
	return current_health / max_health

func set_inertia_velocity(new_velocity: Vector2):
	"""Устанавливает скорость инерционного движения астероида"""
	# Останавливаем автономное движение
	if is_moving_autonomously:
		stop_autonomous_movement()
	
	var inertia_data = MovementSystem.set_inertia_from_velocity(new_velocity, inertia_min_speed)
	inertia_velocity = inertia_data[0]
	is_moving_by_inertia = inertia_data[1]
	
	# Разморозить астероид для инерционного движения
	if is_moving_by_inertia:
		freeze = false
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

func get_inertia_velocity() -> Vector2:
	"""Возвращает текущую скорость инерционного движения"""
	return inertia_velocity

func is_moving_by_inertia_check() -> bool:
	"""Проверяет, движется ли астероид по инерции"""
	return MovementSystem.is_inertia_active(inertia_velocity, inertia_min_speed)

func stop_inertia_movement():
	"""Принудительно останавливает инерционное движение"""
	inertia_velocity = Vector2.ZERO
	is_moving_by_inertia = false
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func update_inertia_movement(delta):
	"""Обновляет инерционное движение астероида после спрыгивания игрока"""
	if not is_moving_by_inertia:
		return
	
	# Обновляем инерционное движение через общую систему
	var new_velocity = MovementSystem.update_inertia_movement(inertia_velocity, inertia_params, delta)
	
	if new_velocity == Vector2.ZERO:
		# Движение остановилось
		stop_inertia_movement()
		return
	
	inertia_velocity = new_velocity
	
	# Применяем скорость к астероиду
	var collision = move_and_collide(inertia_velocity * delta)
	if collision:
		# Обрабатываем столкновение через общую систему
		var collision_normal = collision.get_normal()
		var collision_result = MovementSystem.handle_inertia_collision(inertia_velocity, collision_normal, inertia_params)
		
		if collision_result == Vector2.ZERO:
			# Слабый удар - останавливаемся
			stop_inertia_movement()
			return
		else:
			# Сильный удар - отскок
			inertia_velocity = collision_result
	
	# Применяем наклон к астероиду при движении
	if asteroid_sprite:
		MovementSystem.apply_tilt_to_sprite(asteroid_sprite, inertia_velocity, movement_params, delta)

# Методы автономного движения для спавнера

func set_autonomous_velocity(velocity: Vector2):
	"""Устанавливает автономную скорость движения астероида (для спавнера)"""
	autonomous_velocity = velocity
	is_moving_autonomously = velocity != Vector2.ZERO
	
	if is_moving_autonomously:
		# Разморозить астероид для автономного движения
		freeze = false
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

func update_autonomous_movement(delta):
	"""Обновляет автономное движение астероида"""
	if not is_moving_autonomously:
		return
	
	# Применяем автономную скорость к астероиду
	var collision = move_and_collide(autonomous_velocity * delta)
	if collision:
		# При столкновении во время автономного движения - просто останавливаемся
		stop_autonomous_movement()

func stop_autonomous_movement():
	"""Останавливает автономное движение"""
	autonomous_velocity = Vector2.ZERO
	is_moving_autonomously = false
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func get_autonomous_velocity() -> Vector2:
	"""Возвращает текущую автономную скорость"""
	return autonomous_velocity

func is_moving_autonomously_check() -> bool:
	"""Проверяет, движется ли астероид автономно"""
	return is_moving_autonomously 

# === МЕТОДЫ ТОПЛИВНОГО АСТЕРОИДА ===

func setup_as_fuel_asteroid(fuel_texture: Texture2D = null):
	"""Настраивает астероид как топливный"""
	is_fuel_asteroid = true
	fuel_amount = max_fuel_amount
	
	# Добавляем в группу топливных астероидов
	add_to_group("fuel_asteroids")
	
	# Устанавливаем специальную текстуру если предоставлена
	if fuel_texture and asteroid_sprite:
		asteroid_sprite.texture = fuel_texture
		fuel_asteroid_texture = fuel_texture
	
	# Настраиваем прогресс бар топлива
	setup_fuel_progress_bar()

func setup_fuel_progress_bar():
	"""Настраивает прогресс бар топлива"""
	if fuel_progress_bar:
		fuel_progress_bar.max_value = max_fuel_amount
		fuel_progress_bar.value = fuel_amount
		fuel_progress_bar.visible = is_fuel_asteroid
		print("Настройка прогресс бара топлива: max=%.2f, current=%.2f, visible=%s" % [max_fuel_amount, fuel_amount, is_fuel_asteroid])
	else:
		print("Предупреждение: прогресс бар топлива не найден!")

func update_fuel_extraction(delta: float, player_fuel_system: PlayerFuelSystem):
	"""Обновляет добычу топлива когда игрок находится на астероиде"""
	if not is_fuel_asteroid or not is_being_ridden or fuel_amount <= 0:
		return
	
	# Вычисляем количество топлива для добычи
	var fuel_to_extract = fuel_extraction_rate * delta
	fuel_to_extract = min(fuel_to_extract, fuel_amount)
	
	# Обновляем таймер для лейблов
	fuel_label_timer += delta
	
	# Добавляем топливо игроку
	if player_fuel_system:
		# Накапливаем топливо для показа в лейбле
		if fuel_label_timer >= fuel_label_interval:
			var accumulated_fuel = fuel_extraction_rate * fuel_label_timer
			accumulated_fuel = min(accumulated_fuel, fuel_amount)
			player_fuel_system.add_fuel_bonus(accumulated_fuel)
			fuel_label_timer = 0.0
		else:
			# Добавляем топливо без визуального эффекта
			player_fuel_system.change_fuel(fuel_to_extract)
	
	# Уменьшаем топливо в астероиде
	fuel_amount -= fuel_to_extract
	fuel_amount = max(0, fuel_amount)
	
	# Обновляем прогресс бар
	update_fuel_progress_bar()
	
	# Если топливо закончилось, превращаем в обычный астероид
	if fuel_amount <= 0:
		convert_to_normal_asteroid()

func update_fuel_progress_bar():
	"""Обновляет визуальное отображение прогресс бара топлива"""
	if fuel_progress_bar:
		fuel_progress_bar.value = fuel_amount

func convert_to_normal_asteroid():
	"""Превращает топливный астероид в обычный после исчерпания топлива"""
	is_fuel_asteroid = false
	
	# Убираем из группы топливных астероидов
	remove_from_group("fuel_asteroids")
	
	# Скрываем прогресс бар
	if fuel_progress_bar:
		fuel_progress_bar.visible = false
	
	# Возвращаем обычную текстуру если есть
	restore_normal_texture()

func restore_normal_texture():
	"""Возвращает обычную текстуру астероида"""
	if asteroid_sprite and fuel_asteroid_texture:
		# Загружаем базовую текстуру астероида
		var normal_texture = load("res://Assets/Images/Asteroid/Asteroid.svg") as Texture2D
		if normal_texture:
			asteroid_sprite.texture = normal_texture

func get_fuel_amount() -> float:
	"""Возвращает текущее количество топлива в астероиде"""
	return fuel_amount

func get_fuel_percentage() -> float:
	"""Возвращает процент топлива в астероиде"""
	if max_fuel_amount <= 0:
		return 0.0
	return fuel_amount / max_fuel_amount

func is_fuel_depleted() -> bool:
	"""Проверяет, исчерпано ли топливо в астероиде"""
	return fuel_amount <= 0

func can_extract_fuel() -> bool:
	"""Проверяет, можно ли добывать топливо из астероида"""
	return is_fuel_asteroid and fuel_amount > 0 and is_being_ridden 

func find_player_fuel_system() -> PlayerFuelSystem:
	"""Находит систему топлива игрока"""
	if not rider:
		return null
	
	# Ищем PlayerFuelSystem среди дочерних узлов игрока
	for child in rider.get_children():
		if child is PlayerFuelSystem:
			return child as PlayerFuelSystem
	
	return null 
