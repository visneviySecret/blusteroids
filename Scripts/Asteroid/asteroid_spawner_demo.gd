extends Node2D

# Демонстрационный скрипт для тестирования спавнера астероидов
# Добавьте этот скрипт к Node2D в сцене для тестирования

# Импорт класса спавнера
const AsteroidSpawner = preload("res://Scripts/Asteroid/asteroid_spawner.gd")

@export var spawner: AsteroidSpawner

func _ready():
	# Если спавнер не назначен, создаем его
	if not spawner:
		setup_spawner()
	
	# Выводим информацию о спавнере
	print("Спавнер астероидов запущен!")
	print("Настройки спавнера:")
	print("- Частота спавна: ", spawner.spawn_rate, " астероидов/сек")
	print("- Максимум астероидов: ", spawner.max_asteroids)
	print("- Диапазон скоростей: ", spawner.min_speed, "-", spawner.max_speed)
	print("- Диапазон размеров: ", spawner.min_scale, "-", spawner.max_scale)

func setup_spawner():
	"""Создает и настраивает спавнер"""
	spawner = AsteroidSpawner.new()
	spawner.name = "AsteroidSpawner"
	add_child(spawner)
	
	# Подключаем сигналы для отладки
	spawner.asteroid_spawned.connect(_on_asteroid_spawned)
	spawner.asteroid_destroyed.connect(_on_asteroid_destroyed)
	
	# Настраиваем параметры спавнера
	spawner.spawn_rate = 1.5  # 1.5 астероида в секунду
	spawner.max_asteroids = 10  # Максимум 10 астероидов
	spawner.min_speed = 60.0
	spawner.max_speed = 180.0
	spawner.min_scale = 0.6
	spawner.max_scale = 1.8

func _on_asteroid_spawned(asteroid: Asteroid):
	"""Вызывается при спавне астероида"""
	var spawn_pos = asteroid.global_position
	var screen_center = Vector2.ZERO
	if spawner.camera:
		screen_center = spawner.camera.global_position
	
	var distance_from_center = spawn_pos.distance_to(screen_center)
	print("Заспавнен астероид: ", asteroid.name, 
		  " размер: ", asteroid.scale.x, 
		  " здоровье: ", asteroid.max_health,
		  " позиция: ", spawn_pos,
		  " расстояние от центра: ", distance_from_center)

func _on_asteroid_destroyed(asteroid: Asteroid):
	"""Вызывается при уничтожении астероида"""
	print("Уничтожен астероид: ", asteroid.name)

func _input(event):
	"""Обработка ввода для управления спавнером"""
	if not spawner:
		return
	
	if event.is_action_pressed("ui_select"):  # Enter
		# Переключение спавна
		if spawner.is_processing():
			spawner.stop_spawning()
			print("Спавн остановлен")
		else:
			spawner.start_spawning()
			print("Спавн запущен")
	
	elif event.is_action_pressed("ui_cancel"):  # Escape
		# Очистка всех астероидов
		spawner.clear_all_asteroids()
		print("Все астероиды удалены")
	
	elif event.is_action_pressed("ui_up"):  # Стрелка вверх
		# Увеличение частоты спавна
		spawner.set_spawn_rate(spawner.spawn_rate + 0.5)
		print("Частота спавна: ", spawner.spawn_rate)
	
	elif event.is_action_pressed("ui_down"):  # Стрелка вниз
		# Уменьшение частоты спавна
		spawner.set_spawn_rate(spawner.spawn_rate - 0.5)
		print("Частота спавна: ", spawner.spawn_rate)
	
	elif event.is_action_pressed("ui_right"):  # Стрелка вправо
		# Увеличение максимума астероидов
		spawner.set_max_asteroids(spawner.max_asteroids + 2)
		print("Максимум астероидов: ", spawner.max_asteroids)
	
	elif event.is_action_pressed("ui_left"):  # Стрелка влево
		# Уменьшение максимума астероидов
		spawner.set_max_asteroids(spawner.max_asteroids - 2)
		print("Максимум астероидов: ", spawner.max_asteroids)

func _process(_delta):
	"""Выводит информацию о состоянии спавнера"""
	if spawner and Engine.get_process_frames() % 60 == 0:  # Каждую секунду
		var info = spawner.get_spawn_info()
		print("Активных астероидов: ", info.active_count, "/", info.max_count) 
