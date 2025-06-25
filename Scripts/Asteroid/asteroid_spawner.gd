extends Node2D
class_name AsteroidSpawner

# Спавнер астероидов с вариативностью размера и скорости
# Астероиды появляются за пределами экрана и летят через экран

# Импорт общей системы спавна
const SpawnUtils = preload("../utils/spawn_system.gd")

# Сигналы
signal asteroid_spawned(asteroid: Asteroid)
signal asteroid_destroyed(asteroid: Asteroid)

# Параметры спавна
@export var spawn_rate: float = 6.0  # Астероидов в секунду
@export var max_asteroids: int = 15  # Максимальное количество астероидов на экране
@export var spawn_distance: float = 300.0  # Расстояние за пределами экрана для спавна

# Параметры размера астероидов
@export var min_scale: float = 1.5  # Минимальный размер (50%)
@export var max_scale: float = 4.0  # Максимальный размер (200%)

# Параметры скорости астероидов
@export var min_speed: float = 100.0   # Минимальная скорость
@export var max_speed: float = 300.0  # Максимальная скорость

# Параметры здоровья в зависимости от размера
@export var base_health: float = 5.0
@export var health_scale_multiplier: float = 1.1  # Увеличение здоровья для больших астероидов

# Ссылки на ресурсы
@export var asteroid_scene: PackedScene
@export var asteroid_textures: Array[Texture2D] = []

# Внутренние переменные
var spawn_timer: float = 0.0
var active_asteroids: Array[Asteroid] = []
var camera: Camera2D

# Область удаления (в 2 раза больше экрана)
var deletion_bounds: Rect2

# Параметры спавна для общей системы
var spawn_params: SpawnUtils.SpawnParams

func _ready():
	setup_spawner()
	
	# Если сцена астероида не назначена, пытаемся загрузить по умолчанию
	if not asteroid_scene:
		asteroid_scene = preload("res://Scene/asteroid.tscn")
	
	# Если текстуры не назначены, загружаем базовые
	if asteroid_textures.is_empty():
		load_default_textures()

func setup_spawner():
	"""Настраивает спавнер"""
	# Находим камеру (если есть)
	camera = find_camera()
	
	# Создаем параметры спавна для общей системы
	var max_asteroid_size = max_scale * 100.0  # Примерный размер астероида
	spawn_params = SpawnUtils.SpawnParams.new(
		spawn_distance,  # screen_margin
		0.0,             # min_distance_from_target (не используется для астероидов)
		0.0,             # max_distance_from_target (не используется для астероидов)  
		max_asteroid_size # additional_offset для больших астероидов
	)
	
	# Устанавливаем область удаления (в 2 раза больше экрана)
	update_deletion_bounds()

func find_camera() -> Camera2D:
	"""Находит камеру в сцене"""
	# Ищем камеру среди детей корневого узла
	var root = get_tree().current_scene
	return find_camera_recursive(root)

func find_camera_recursive(node: Node) -> Camera2D:
	"""Рекурсивно ищет камеру"""
	if node is Camera2D:
		return node as Camera2D
	
	for child in node.get_children():
		var result = find_camera_recursive(child)
		if result:
			return result
	
	return null

func load_default_textures():
	"""Загружает текстуры астероидов по умолчанию"""
	var texture_paths = [
		"res://Assets/Images/Asteroid/asteroid1.svg",
		"res://Assets/Images/Asteroid/asteroid2.svg",
		"res://Assets/Images/Asteroid/asteroid3.svg"
	]
	
	for path in texture_paths:
		if ResourceLoader.exists(path):
			var texture = load(path) as Texture2D
			if texture:
				asteroid_textures.append(texture)

func update_deletion_bounds():
	"""Обновляет границы удаления астероидов"""
	deletion_bounds = SpawnUtils.get_deletion_bounds(get_viewport(), camera, 2.0)

func _process(delta):
	update_spawner(delta)
	cleanup_asteroids()

func update_spawner(delta):
	"""Обновляет спавнер астероидов"""
	# Обновляем границы удаления
	update_deletion_bounds()
	
	# Проверяем, нужно ли спавнить новые астероиды
	spawn_timer -= delta
	
	if spawn_timer <= 0.0 and active_asteroids.size() < max_asteroids:
		spawn_asteroid()
		spawn_timer = 1.0 / spawn_rate  # Сброс таймера

func spawn_asteroid():
	"""Спавнит новый астероид"""
	if not asteroid_scene:
		return
	
	# Создаем астероид
	var asteroid = asteroid_scene.instantiate() as Asteroid
	if not asteroid:
		return
	
	# Настраиваем астероид
	setup_asteroid_properties(asteroid)
	
	# Определяем позицию спавна используя общую систему
	var spawn_position = SpawnUtils.get_offscreen_spawn_position(get_viewport(), null, spawn_params)
	asteroid.global_position = spawn_position
	
	# Определяем направление движения используя общую систему
	var target_position = SpawnUtils.get_random_screen_target(get_viewport(), camera)
	var direction = (target_position - spawn_position).normalized()
	
	# Устанавливаем скорость
	var speed = randf_range(min_speed, max_speed)
	set_asteroid_velocity(asteroid, direction * speed)
	
	# Добавляем в сцену
	get_parent().add_child(asteroid)
	
	# Подключаем сигналы
	connect_asteroid_signals(asteroid)
	
	# Добавляем в список активных
	active_asteroids.append(asteroid)
	
	# Испускаем сигнал
	asteroid_spawned.emit(asteroid)

func setup_asteroid_properties(asteroid: Asteroid):
	"""Настраивает свойства астероида"""
	# Случайный размер
	var scale_factor = randf_range(min_scale, max_scale)
	asteroid.scale = Vector2(scale_factor, scale_factor)
	
	# Здоровье в зависимости от размера
	var health = base_health * pow(scale_factor, health_scale_multiplier)
	asteroid.max_health = health
	asteroid.current_health = health
	
	# Случайная текстура (если доступны)
	if not asteroid_textures.is_empty():
		var texture = asteroid_textures[randi() % asteroid_textures.size()]
		set_asteroid_texture(asteroid, texture)
	
	# Случайный поворот
	asteroid.rotation = randf() * TAU

func set_asteroid_texture(asteroid: Asteroid, texture: Texture2D):
	"""Устанавливает текстуру астероида"""
	# Ищем Sprite2D в астероиде
	var sprite = find_sprite_in_asteroid(asteroid)
	if sprite:
		sprite.texture = texture

func find_sprite_in_asteroid(asteroid: Asteroid) -> Sprite2D:
	"""Находит Sprite2D в астероиде"""
	for child in asteroid.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null

func set_asteroid_velocity(asteroid: Asteroid, velocity: Vector2):
	"""Устанавливает скорость астероида"""
	# Используем новый метод автономного движения
	asteroid.set_autonomous_velocity(velocity)
	
	# Добавляем небольшое вращение
	asteroid.angular_velocity = randf_range(-2.0, 2.0)

func connect_asteroid_signals(asteroid: Asteroid):
	"""Подключает сигналы астероида"""
	# Подключаемся к сигналу уничтожения
	if asteroid.has_signal("destroyed"):
		asteroid.destroyed.connect(_on_asteroid_destroyed.bind(asteroid))
	
	# Подключаемся к сигналу tree_exiting
	asteroid.tree_exiting.connect(_on_asteroid_removed.bind(asteroid))

func cleanup_asteroids():
	"""Удаляет астероиды, вышедшие за границы"""
	var asteroids_to_remove: Array[Asteroid] = []
	
	for asteroid in active_asteroids:
		if not is_instance_valid(asteroid):
			asteroids_to_remove.append(asteroid)
			continue
		
		# Проверяем, вышел ли астероид за границы удаления
		if not deletion_bounds.has_point(asteroid.global_position):
			asteroids_to_remove.append(asteroid)
			asteroid.queue_free()
	
	# Удаляем из списка
	for asteroid in asteroids_to_remove:
		active_asteroids.erase(asteroid)

func _on_asteroid_destroyed(asteroid: Asteroid):
	"""Вызывается при уничтожении астероида"""
	active_asteroids.erase(asteroid)
	asteroid_destroyed.emit(asteroid)

func _on_asteroid_removed(asteroid: Asteroid):
	"""Вызывается при удалении астероида из сцены"""
	active_asteroids.erase(asteroid)

# Публичные методы для управления спавнером

func start_spawning():
	"""Запускает спавн астероидов"""
	set_process(true)

func stop_spawning():
	"""Останавливает спавн астероидов"""
	set_process(false)

func clear_all_asteroids():
	"""Удаляет все активные астероиды"""
	for asteroid in active_asteroids:
		if is_instance_valid(asteroid):
			asteroid.queue_free()
	active_asteroids.clear()

func set_spawn_rate(new_rate: float):
	"""Устанавливает частоту спавна"""
	spawn_rate = max(0.1, new_rate)

func set_max_asteroids(new_max: int):
	"""Устанавливает максимальное количество астероидов"""
	max_asteroids = max(1, new_max)

func set_speed_range(new_min: float, new_max: float):
	"""Устанавливает диапазон скоростей"""
	min_speed = max(10.0, new_min)
	max_speed = max(min_speed + 10.0, new_max)

func set_scale_range(new_min: float, new_max: float):
	"""Устанавливает диапазон размеров"""
	min_scale = max(0.1, new_min)
	max_scale = max(min_scale + 0.1, new_max)

func get_active_asteroid_count() -> int:
	"""Возвращает количество активных астероидов"""
	return active_asteroids.size()

func get_spawn_info() -> Dictionary:
	"""Возвращает информацию о спавнере"""
	return {
		"active_count": active_asteroids.size(),
		"max_count": max_asteroids,
		"spawn_rate": spawn_rate,
		"speed_range": [min_speed, max_speed],
		"scale_range": [min_scale, max_scale]
	} 
