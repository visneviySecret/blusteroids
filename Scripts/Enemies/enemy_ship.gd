extends RocketShip
class_name EnemyShip

# Корабль-враг с ИИ, наследуется от RocketShip

# Параметры обнаружения игрока
@export var detection_range: float = 400.0  # Дальность обнаружения игрока
@export var attack_range: float = 300.0     # Дальность атаки
@export var flee_range: float = 150.0       # Дистанция, при которой корабль убегает

# Параметры орбитального движения
@export var orbit_radius: float = 200.0     # Радиус орбиты
@export var orbit_speed: float = 2.0        # Скорость орбитального движения
@export var orbit_center: Vector2 = Vector2.ZERO  # Центр орбиты

# Параметры ИИ
@export var aim_accuracy: float = 0.9       # Точность прицеливания (0-1)

# Состояния корабля
enum ShipState {
	ORBITING,    # Движется по орбите
	PURSUING,    # Преследует игрока
	ATTACKING,   # Атакует игрока
	FLEEING      # Убегает от игрока
}

# Переменные ИИ
var current_state: ShipState = ShipState.ORBITING
var player_reference: Node2D = null
var orbit_angle: float = 0.0

func _ready():
	# Настраиваем параметры коллизий для врага
	ship_collision_layer = Layers.ENEMIES         # Слой врагов
	ship_collision_mask = Layers.EnemyMasks.BASIC # Базовая маска врагов
	laser_collision_layer = Layers.ENEMY_LASERS   # Слой лазеров врагов
	laser_collision_mask = Layers.LaserMasks.ENEMY_LASERS # Маска лазеров врагов
	
	# Настраиваем коллизии для обломков
	wreckage_collision_layer = Layers.WRECKAGE    # Слой обломков
	wreckage_collision_mask = 0                   # Обломки пассивны
	
	# Вызываем родительский _ready()
	super._ready()
	
	# Настраиваем ИИ
	setup_ai()

func setup_ai():
	"""Настраивает ИИ врага"""
	# Добавляем в группу врагов
	add_to_group("enemies")
	
	# Ищем игрока
	find_player()
	
	# Устанавливаем случайный начальный угол орбиты
	orbit_angle = randf() * TAU

func find_player():
	"""Ищет игрока в сцене"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]

func get_projectile_layer_name() -> String:
	"""Переопределяем имя слоя для снарядов врагов"""
	return "EnemyProjectilesLayer"

func configure_laser_appearance(laser: LaserProjectile):
	"""Настраиваем внешний вид лазера врага - оранжевый цвет"""
	laser.modulate = Color.ORANGE

func get_destruction_color() -> Color:
	"""Цвет эффекта уничтожения врага - оранжевый"""
	return Color.ORANGE

func _physics_process(delta):
	# Обновляем ИИ
	update_ai_state()
	update_ai_movement(delta)
	
	# Вызываем родительский метод
	super._physics_process(delta)

func update_ai_state():
	"""Обновляет состояние ИИ корабля"""
	if not player_reference:
		current_state = ShipState.ORBITING
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	match current_state:
		ShipState.ORBITING:
			if distance_to_player <= detection_range:
				current_state = ShipState.PURSUING
		
		ShipState.PURSUING:
			if distance_to_player <= flee_range:
				current_state = ShipState.FLEEING
			elif distance_to_player <= attack_range:
				current_state = ShipState.ATTACKING
			elif distance_to_player > detection_range:
				current_state = ShipState.ORBITING
		
		ShipState.ATTACKING:
			if distance_to_player <= flee_range:
				current_state = ShipState.FLEEING
			elif distance_to_player > attack_range:
				current_state = ShipState.PURSUING
		
		ShipState.FLEEING:
			if distance_to_player > detection_range:
				current_state = ShipState.ORBITING
			elif distance_to_player > flee_range:
				current_state = ShipState.PURSUING

func update_ai_movement(delta):
	"""Обновляет движение ИИ в зависимости от состояния"""
	match current_state:
		ShipState.ORBITING:
			update_orbital_movement(delta)
		
		ShipState.PURSUING:
			update_pursuing_movement(delta)
			
		ShipState.ATTACKING:
			update_attacking_movement(delta)
			attempt_ai_fire()
			
		ShipState.FLEEING:
			update_fleeing_movement(delta)

func update_orbital_movement(delta):
	"""Обновляет орбитальное движение"""
	orbit_angle += orbit_speed * delta
	if orbit_angle > TAU:
		orbit_angle -= TAU
	
	var orbit_position = orbit_center + Vector2.from_angle(orbit_angle) * orbit_radius
	var direction_to_orbit = (orbit_position - global_position).normalized()
	set_target_velocity(direction_to_orbit * max_speed * 0.6)

func update_pursuing_movement(_delta):
	"""Обновляет движение преследования"""
	if not player_reference:
		return
	
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	set_target_velocity(direction_to_player * max_speed)

func update_attacking_movement(_delta):
	"""Обновляет движение во время атаки"""
	if not player_reference:
		return
	
	# Движемся по кругу вокруг игрока, сохраняя дистанцию
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	var perpendicular = Vector2(-direction_to_player.y, direction_to_player.x)
	
	# Комбинируем движение к игроку и по кругу
	var circle_movement = perpendicular * max_speed * 0.7
	var approach_movement = direction_to_player * max_speed * 0.3
	
	set_target_velocity(circle_movement + approach_movement)

func update_fleeing_movement(_delta):
	"""Обновляет движение убегания"""
	if not player_reference:
		return
	
	var direction_from_player = (global_position - player_reference.global_position).normalized()
	set_target_velocity(direction_from_player * max_speed)

func attempt_ai_fire():
	"""ИИ пытается выстрелить в игрока"""
	if not player_reference:
		return
	
	# Вычисляем направление к игроку с учетом точности
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	
	# Добавляем неточность
	var accuracy_offset = (1.0 - aim_accuracy) * 0.5
	var random_offset = Vector2(
		randf_range(-accuracy_offset, accuracy_offset),
		randf_range(-accuracy_offset, accuracy_offset)
	)
	
	var shoot_direction = (direction_to_player + random_offset).normalized()
	
	# Используем базовый метод стрельбы
	attempt_fire(shoot_direction)

# Методы для управления ИИ
func set_orbit_center(center: Vector2):
	"""Устанавливает центр орбиты"""
	orbit_center = center

func get_current_state() -> ShipState:
	"""Возвращает текущее состояние корабля"""
	return current_state

func set_player_target(player: Node2D):
	"""Устанавливает цель для преследования"""
	player_reference = player

func get_distance_to_player() -> float:
	"""Возвращает расстояние до игрока"""
	if not player_reference:
		return INF
	return global_position.distance_to(player_reference.global_position)

func is_player_in_detection_range() -> bool:
	"""Проверяет, находится ли игрок в зоне обнаружения"""
	return get_distance_to_player() <= detection_range

func is_player_in_attack_range() -> bool:
	"""Проверяет, находится ли игрок в зоне атаки"""
	return get_distance_to_player() <= attack_range

func is_player_too_close() -> bool:
	"""Проверяет, слишком ли близко игрок"""
	return get_distance_to_player() <= flee_range

func on_wreckage_looted():
	"""Переопределяем метод лутания - даем игроку топливо"""
	if not player_reference:
		return
	
	# Генерируем случайное количество топлива от 5 до 30 единиц
	var fuel_bonus = randf_range(5.0, 30.0)
	
	# Добавляем топливо игроку через систему топлива
	var fuel_system = player_reference.get_fuel_system()
	if fuel_system and fuel_system.has_method("add_fuel_bonus"):
		fuel_system.add_fuel_bonus(fuel_bonus)
	elif fuel_system and fuel_system.has_method("change_fuel"):
		fuel_system.change_fuel(fuel_bonus)
	else:
		# Резервный способ через прямой доступ к узлу
		var fuel_node = player_reference.get_node_or_null("FuelSystem")
		if fuel_node and fuel_node.has_method("add_fuel_bonus"):
			fuel_node.add_fuel_bonus(fuel_bonus)
		elif fuel_node and fuel_node.has_method("change_fuel"):
			fuel_node.change_fuel(fuel_bonus)
