extends StaticBody2D
class_name TestTarget

# Тестовая цель для стрельбы

@export var max_health: float = 50.0
@export var target_size: Vector2 = Vector2(64, 64)
@export var target_color: Color = Color.BLUE

var current_health: float
var target_sprite: ColorRect
var health_bar: ProgressBar

func _ready():
	current_health = max_health
	setup_visuals()
	setup_collision()

func setup_visuals():
	"""Настраивает визуальное представление цели"""
	# Создаем спрайт цели
	target_sprite = ColorRect.new()
	target_sprite.size = target_size
	target_sprite.color = target_color
	target_sprite.position = -target_size / 2
	add_child(target_sprite)
	
	# Создаем полоску здоровья
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(target_size.x, 8)
	health_bar.position = Vector2(-target_size.x / 2, -target_size.y / 2 - 12)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	add_child(health_bar)

func setup_collision():
	"""Настраивает коллизию цели"""
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = target_size
	collision_shape.shape = rect_shape
	add_child(collision_shape)

func take_damage(damage: float):
	"""Получает урон"""
	current_health -= damage
	current_health = max(0, current_health)
	
	# Обновляем полоску здоровья
	if health_bar:
		health_bar.value = current_health
	
	# Изменяем цвет в зависимости от здоровья
	update_color()
	
	# Уничтожаем цель если здоровье закончилось
	if current_health <= 0:
		destroy_target()

func update_color():
	"""Обновляет цвет цели в зависимости от здоровья"""
	if not target_sprite:
		return
		
	var health_ratio = current_health / max_health
	
	if health_ratio > 0.6:
		target_sprite.color = Color.BLUE
	elif health_ratio > 0.3:
		target_sprite.color = Color.YELLOW
	else:
		target_sprite.color = Color.RED

func destroy_target():
	"""Уничтожает цель"""
	# Создаем эффект уничтожения
	create_destruction_effect()
	
	queue_free()

func create_destruction_effect():
	"""Создает эффект уничтожения"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.speed_scale = 3.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	particles.color = target_color
	
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

func heal(amount: float):
	"""Восстанавливает здоровье"""
	current_health += amount
	current_health = min(max_health, current_health)
	
	if health_bar:
		health_bar.value = current_health
	
	update_color()

func is_alive() -> bool:
	"""Проверяет, жива ли цель"""
	return current_health > 0 