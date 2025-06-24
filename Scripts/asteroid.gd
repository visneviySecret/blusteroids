extends RigidBody2D
class_name Asteroid

# Скрипт астероида с возможностью зацепления и уничтожения

@export var max_health: float = 20.0  # 2 попадания лазера по 10 урона
@export var asteroid_size: Vector2 = Vector2(100, 100)

var current_health: float
var asteroid_sprite: Sprite2D
var collision_shape: CollisionShape2D

func _ready():
	current_health = max_health
	setup_asteroid()

func setup_asteroid():
	"""Настраивает астероид"""
	# Добавляем в группу для зацепления крюком
	add_to_group("grappleable_objects")
	
	# Отключаем гравитацию для астероида, чтобы он завис в воздухе
	gravity_scale = 0.0
	# Делаем астероид кинематическим, чтобы он не реагировал на физику
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Настраиваем слои коллизий
	# Астероид находится на слое 3 (препятствия), чтобы крюк и лазеры могли с ним сталкиваться
	collision_layer = 4  # Слой 3 (2^2 = 4)
	collision_mask = 0   # Астероид не должен сталкиваться с другими объектами сам
	
	# Находим существующие компоненты (они уже созданы в сцене)
	find_existing_components()

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