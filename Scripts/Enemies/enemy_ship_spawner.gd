extends Node2D
class_name EnemyShipSpawner

# Система спавна врагов-кораблей

# Импорт общей системы спавна
const SpawnSystem = preload("../utils/spawn_system.gd")

# Параметры спавна
@export var max_enemies: int = 3
@export var spawn_distance_min: float = 800.0  # Минимальное расстояние спавна от игрока
@export var spawn_distance_max: float = 1200.0  # Максимальное расстояние спавна от игрока
@export var spawn_interval: float = 10.0  # Интервал между спавнами
@export var enemy_orbit_radius: float = 250.0  # Радиус орбиты для врагов
@export var screen_margin: float = 100.0  # Отступ за пределы экрана

# Ссылки
var player_reference: Node2D = null
var spawned_enemies: Array[EnemyShip] = []
var spawn_timer: float = 0.0
var looted_ships_count: int = 0  # Счетчик разграбленных кораблей

# Параметры спавна для общей системы
var spawn_params: SpawnSystem.SpawnParams

# Загружаем сцену ракеты
const RocketScene = preload("res://Scene/rocket.tscn")

func _ready():
	find_player()
	# Настраиваем параметры спавна для общей системы
	spawn_params = SpawnSystem.SpawnParams.new(
		screen_margin,           # screen_margin
		spawn_distance_min,      # min_distance_from_target
		spawn_distance_max,      # max_distance_from_target
		0.0                      # additional_offset (не нужен для кораблей)
	)
	# Спавним первого врага сразу
	spawn_timer = spawn_interval

func find_player():
	"""Ищет игрока в сцене"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]

func _process(delta):
	spawn_timer += delta
	
	# Убираем мертвых врагов из списка
	cleanup_dead_enemies()
	
	# Спавним новых врагов если нужно
	if spawn_timer >= spawn_interval and spawned_enemies.size() < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func cleanup_dead_enemies():
	"""Убирает мертвых врагов из списка (они остаются как обломки на поле)"""
	# Подсчитываем разграбленные корабли перед очисткой
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_wreckage_looted") and enemy.is_wreckage_looted():
			looted_ships_count += 1
	
	spawned_enemies = spawned_enemies.filter(func(enemy): return is_instance_valid(enemy) and enemy.is_alive())

func spawn_enemy():
	"""Спавнит нового врага-корабля используя сцену rocket.tscn"""
	if not player_reference:
		return
	
	# Создаем врага из готовой сцены
	var enemy = RocketScene.instantiate() as EnemyShip
	enemy.name = "EnemyShip_" + str(spawned_enemies.size())
	
	# Позиционируем врага за пределами экрана используя общую систему
	var spawn_position = SpawnSystem.get_offscreen_spawn_position(get_viewport(), player_reference, spawn_params)
	enemy.global_position = spawn_position
	
	# Устанавливаем центр орбиты
	var orbit_center = player_reference.global_position + Vector2(
		randf_range(-200, 200),
		randf_range(-200, 200)
	)
	enemy.set_orbit_center(orbit_center)
	
	# Добавляем в сцену
	get_parent().add_child(enemy)
	spawned_enemies.append(enemy)

func get_enemy_count() -> int:
	"""Возвращает количество живых врагов"""
	return spawned_enemies.size()

func clear_all_enemies():
	"""Удаляет всех врагов (включая обломки)"""
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
	
	# Также удаляем все обломки кораблей на поле
	clear_all_destroyed_ships()

func clear_all_destroyed_ships():
	"""Удаляет все уничтоженные корабли (обломки) с поля"""
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy.has_method("is_alive") and not enemy.is_alive():
			# Подсчитываем разграбленные перед удалением
			if enemy.has_method("is_wreckage_looted") and enemy.is_wreckage_looted():
				looted_ships_count += 1
			enemy.queue_free()

func set_max_enemies(count: int):
	"""Устанавливает максимальное количество врагов"""
	max_enemies = max(0, count)

func set_spawn_interval(interval: float):
	"""Устанавливает интервал спавна"""
	spawn_interval = max(0.1, interval)

func set_spawn_distance_range(min_distance: float, max_distance: float):
	"""Устанавливает диапазон дистанций спавна"""
	spawn_distance_min = max(100.0, min_distance)
	spawn_distance_max = max(spawn_distance_min + 100.0, max_distance)

func set_screen_margin(margin: float):
	"""Устанавливает отступ за пределы экрана"""
	screen_margin = max(50.0, margin)

func get_looted_ships_count() -> int:
	"""Возвращает количество разграбленных кораблей"""
	return looted_ships_count

func reset_loot_counter():
	"""Сбрасывает счетчик разграбленных кораблей"""
	looted_ships_count = 0

func get_active_wreckage_count() -> int:
	"""Возвращает количество активных обломков на поле"""
	var wreckage_count = 0
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy.has_method("is_alive") and not enemy.is_alive() and enemy.has_method("can_be_looted") and enemy.can_be_looted():
			wreckage_count += 1
	return wreckage_count 
