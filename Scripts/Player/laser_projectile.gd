extends Area2D
class_name LaserProjectile

# Параметры лазерного снаряда
@export var speed: float = 800.0  # Немного медленнее для лучшей видимости
@export var lifetime: float = 5.0  # Дольше живет
@export var damage: float = 10.0
@export var laser_width: float = 12.0  # Шире
@export var laser_length: float = 80.0  # Длиннее

# Переменные движения
var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var is_initialized: bool = false
var shooter: Node2D = null  # Ссылка на того, кто выпустил лазер

# Визуальные компоненты
var laser_particles: CPUParticles2D
var collision_shape: CollisionShape2D

func _ready():
	if is_initialized:
		return
		
	setup_visuals()
	setup_collision()
	
	# Подключаем сигналы коллизии только если они еще не подключены
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	is_initialized = true

func setup_visuals():
	"""Настраивает визуальное представление лазера - максимально простое и видимое"""
	# Создаем большой яркий прямоугольник лазера
	var laser_rect = ColorRect.new()
	laser_rect.size = Vector2(laser_length, laser_width)
	laser_rect.color = Color.RED
	laser_rect.position = Vector2(0, -laser_width / 2)
	add_child(laser_rect)
	
	# Добавляем еще один большой белый прямоугольник для контраста
	var bright_rect = ColorRect.new()
	bright_rect.size = Vector2(laser_length * 0.8, laser_width * 0.5)
	bright_rect.color = Color.WHITE
	bright_rect.position = Vector2(laser_length * 0.1, -laser_width * 0.25)
	add_child(bright_rect)

func setup_collision():
	"""Настраивает коллизию лазера"""
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(laser_length, laser_width)
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(laser_length / 2, 0)
	add_child(collision_shape)
	
	# Настраиваем collision layers для исключения столкновений с игроком
	# Лазер находится на слое 2, игрок на слое 1
	collision_layer = 2  # Лазер находится на слое 2
	collision_mask = 1 + 4 + 32  # Лазер сталкивается со слоями 1 (враги), 3 (препятствия) и 32 (обломки)
	
func initialize(start_position: Vector2, direction: Vector2, shooter_ref: Node2D = null):
	"""Инициализирует лазер с начальной позицией, направлением и ссылкой на стрелка"""
	global_position = start_position
	velocity = direction.normalized() * speed
	# Поворачиваем лазер в направлении движения
	rotation = direction.angle()
	
	# Сохраняем ссылку на стрелка
	shooter = shooter_ref
	
	# Убираем принудительный вызов _ready - он должен вызываться автоматически движком
	# if not has_method("setup_visuals") or get_child_count() == 0:
	#	call_deferred("_ready")

func _physics_process(delta):
	# Проверяем, что лазер инициализирован
	if not is_initialized:
		return
		
	# Движение лазера
	global_position += velocity * delta
	
	# Увеличиваем время жизни
	time_alive += delta
	
	# Уничтожаем лазер по истечении времени жизни
	if time_alive >= lifetime:
		destroy()

func _on_body_entered(body):
	"""Обработка столкновения с телом"""
	# Игнорируем столкновение со стрелком
	if body == shooter:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Создаем эффект попадания
	create_hit_effect()
	
	# Уничтожаем лазер
	destroy()

func _on_area_entered(area):
	"""Обработка столкновения с областью"""
	# Игнорируем столкновение со стрелком (если он Area2D)
	if area == shooter:
		return
	
	
	if area.has_method("take_damage"):
		area.take_damage(damage)
	
	# Создаем эффект попадания
	create_hit_effect()
	
	# Уничтожаем лазер
	destroy()

func create_hit_effect():
	"""Создает эффект попадания"""
	# Простой эффект - можно расширить позже
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.speed_scale = 2.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color.ORANGE
	
	# Добавляем частицы в родительскую сцену
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Создаем таймер для удаления частиц
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true  # Автозапуск
	timer.timeout.connect(func(): particles.queue_free())
	
	# Добавляем таймер в дерево сцены
	particles.add_child(timer)

func destroy():
	"""Уничтожает лазерный снаряд"""
	queue_free()

# Статический метод для создания лазера
static func create_laser_projectile(start_position: Vector2, direction: Vector2, shooter_ref: Node2D = null, laser_speed: float = 1000.0, laser_damage: float = 10.0) -> LaserProjectile:
	"""Создает и настраивает новый лазерный снаряд"""
	var laser = LaserProjectile.new()
	laser.speed = laser_speed
	laser.damage = laser_damage
	laser.initialize(start_position, direction, shooter_ref)
	return laser 
