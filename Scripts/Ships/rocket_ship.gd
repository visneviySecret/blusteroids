extends CharacterBody2D
class_name RocketShip

# Базовый класс для всех кораблей в игре
# Содержит основные системы: движение, стрельба, дым, здоровье

# Импорт конфига коллизий
const Layers = preload("res://Scripts/config/collision_layers.gd")

# Импорт существующих систем
const MovementSystem = preload("../utils/common_movement_system.gd")
const Laser = preload("../Player/laser_projectile.gd")
const Smoke = preload("../Effects/smoke_system.gd")

# Предзагружаем текстуры
const DestroyedTexture = preload("res://Assets/Images/Rocket/Rocket-ship-destroyed.png")

# Базовые параметры корабля
@export var max_health: float = 30.0
@export var max_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var max_tilt_angle: float = 0.2
@export var wreckage_lifetime: float = 30.0  # Время жизни обломков в секундах
@export var rotation_speed: float = 5.0  # Скорость поворота корабля

# Параметры атаки
@export var laser_damage: float = 15.0
@export var laser_speed: float = 800.0
@export var fire_rate: float = 1.5
@export var muzzle_offset: Vector2 = Vector2(40, 0)  # Смещение точки выстрела

# Внутренние переменные
var current_health: float
var ship_sprite: Sprite2D
var collision_shape: CollisionShape2D
var is_looted: bool = false  # Параметр для отслеживания разграбления обломков
var is_fading: bool = false  # Флаг для предотвращения повторного исчезновения

# Системы корабля
var smoke_system: Smoke
var movement_params: MovementSystem.MovementParams
var projectile_parent: Node2D

# Переменные атаки
var fire_timer: float = 0.0
var can_fire: bool = true

# Переменные движения
var target_velocity: Vector2 = Vector2.ZERO

# Настройки коллизий (переопределяются в наследниках)
var ship_collision_layer: int = Layers.ENEMIES
var ship_collision_mask: int = 0
var laser_collision_layer: int = Layers.PLAYER_LASERS
var laser_collision_mask: int = Layers.LaserMasks.PLAYER_LASERS

# Коллизии для лута (обломков)
var loot_collision_layer: int = Layers.LOOT_AREA    # Слой для взаимодействия с игроком
var loot_collision_mask: int = Layers.PLAYER        # Маска для обнаружения игрока

# Коллизии для разрушенных кораблей
var wreckage_collision_layer: int = Layers.WRECKAGE # Слой для обломков, с которыми могут взаимодействовать пули
var wreckage_collision_mask: int = 0                # Обломки ни с чем не сталкиваются активно

func _ready():
	current_health = max_health
	setup_ship()
	setup_smoke_system()
	setup_projectile_parent()
	
	# Инициализируем параметры движения
	movement_params = MovementSystem.MovementParams.new(
		max_speed, acceleration, friction, max_tilt_angle, 0.0, 0.0
	)

func setup_ship():
	"""Настраивает базовые параметры корабля"""
	# Настраиваем слои коллизий
	collision_layer = ship_collision_layer
	collision_mask = ship_collision_mask
	
	# Ищем существующие компоненты
	find_existing_components()

func find_existing_components():
	"""Находит существующие компоненты корабля в сцене"""
	# Рекурсивно ищем компоненты среди всех дочерних узлов
	for child in get_children():
		if child is Sprite2D and not ship_sprite:
			ship_sprite = child
		elif child is CollisionShape2D and not collision_shape:
			collision_shape = child

func setup_smoke_system():
	"""Создает и настраивает систему дыма"""
	smoke_system = Smoke.new()
	smoke_system.smoke_spawn_rate = 0.08
	smoke_system.min_speed_for_smoke = 30.0
	get_parent().add_child.call_deferred(smoke_system)
	smoke_system.set_target.call_deferred(self)

func setup_projectile_parent():
	"""Настраивает родительский узел для размещения снарядов"""
	projectile_parent = get_parent()
	
	# Создаем отдельный слой для снарядов (переопределяется в наследниках)
	if projectile_parent:
		var projectiles_layer = Node2D.new()
		projectiles_layer.name = get_projectile_layer_name()
		projectiles_layer.z_index = 1
		projectile_parent.add_child.call_deferred(projectiles_layer)
		projectile_parent = projectiles_layer

func get_projectile_layer_name() -> String:
	"""Возвращает имя слоя для снарядов (переопределяется в наследниках)"""
	return "ProjectilesLayer"

func _physics_process(delta):
	update_fire_timer(delta)
	update_movement(delta)
	move_and_slide()

func update_fire_timer(delta):
	"""Обновляет таймер перезарядки стрельбы"""
	if fire_timer > 0:
		fire_timer -= delta
		if fire_timer <= 0:
			can_fire = true

func update_movement(delta):
	"""Обновляет движение корабля (базовая реализация)"""
	# Применяем движение через общую систему
	var input_direction = target_velocity.normalized()
	velocity = MovementSystem.apply_movement_to_velocity(
		velocity, input_direction, movement_params, delta
	)
	
	# Поворачиваем корабль по направлению движения
	if velocity.length() > 10.0:  # Поворачиваем только если корабль движется
		var target_rotation = velocity.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	
	# Применяем наклон к спрайту (если нужен дополнительный эффект)
	if ship_sprite:
		MovementSystem.apply_tilt_to_sprite(ship_sprite, velocity, movement_params, delta)

func set_target_velocity(new_velocity: Vector2):
	"""Устанавливает целевую скорость корабля"""
	target_velocity = new_velocity

func attempt_fire(direction: Vector2) -> bool:
	"""Попытка выстрелить в указанном направлении"""
	if not can_fire or not projectile_parent:
		return false
	
	shoot_laser(direction)
	
	# Запускаем перезарядку
	fire_timer = fire_rate
	can_fire = false
	return true

func shoot_laser(direction: Vector2):
	"""Создает и запускает лазерный снаряд"""
	if not projectile_parent:
		return
	
	# Вычисляем точку выстрела с учетом поворота корабля
	var rotated_offset = muzzle_offset.rotated(rotation)
	var shoot_position = global_position + rotated_offset
	
	# Создаем лазерный снаряд
	var laser = Laser.create_laser_projectile(
		shoot_position, direction, self, laser_speed, laser_damage
	)
	
	# Настраиваем внешний вид лазера
	configure_laser_appearance(laser)
	
	# Настраиваем коллизии лазера
	laser.collision_layer = laser_collision_layer
	laser.collision_mask = laser_collision_mask
	
	# Добавляем лазер в сцену
	projectile_parent.add_child.call_deferred(laser)

func configure_laser_appearance(laser: Laser):
	"""Настраивает внешний вид лазера (переопределяется в наследниках)"""
	# Базовая реализация - красный лазер
	laser.modulate = Color.RED

func take_damage(damage: float):
	"""Получает урон"""
	# Если корабль уже мертв, повторное попадание заставляет его исчезнуть
	if not is_alive():
		fade_out_wreckage()
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	# Визуальная обратная связь при получении урона
	show_damage_effect()
	
	# Уничтожаем корабль если здоровье закончилось
	if current_health <= 0:
		destroy_ship()

func show_damage_effect():
	"""Показывает эффект получения урона"""
	if not ship_sprite:
		return
	
	# Кратковременно меняем цвет на красный
	var original_modulate = ship_sprite.modulate
	ship_sprite.modulate = Color.RED
	
	# Создаем таймер для возврата цвета
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if ship_sprite:
			ship_sprite.modulate = original_modulate
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func destroy_ship():
	"""Уничтожает корабль"""
	# Создаем эффект уничтожения
	create_destruction_effect()
	
	# Очищаем систему дыма
	if smoke_system:
		smoke_system.clear_all_particles()
		smoke_system.enable_smoke(false)
	
	# Меняем текстуру на поврежденную
	change_to_destroyed_texture()
	
	# Отключаем функциональность корабля
	disable_ship_functionality()
	
	# Уведомляем о уничтожении (для переопределения в наследниках)
	on_ship_destroyed()

func change_to_destroyed_texture():
	"""Меняет текстуру корабля на поврежденную версию"""
	# Ищем спрайт если он не найден в _ready()
	if not ship_sprite:
		find_existing_components()
	
	if not ship_sprite:
		return
	
	# Используем предзагруженную текстуру
	if DestroyedTexture:
		ship_sprite.texture = DestroyedTexture
		# Немного затемняем спрайт для эффекта
		ship_sprite.modulate = Color(0.8, 0.8, 0.8, 1.0)

func disable_ship_functionality():
	"""Отключает всю функциональность уничтоженного корабля"""
	# Отключаем физику движения
	set_physics_process(false)
	
	# Настраиваем коллизии для обломков - они могут взаимодействовать с пулями
	collision_layer = wreckage_collision_layer
	collision_mask = wreckage_collision_mask
	
	# Обнуляем скорость
	velocity = Vector2.ZERO
	target_velocity = Vector2.ZERO
	
	# Отключаем возможность стрельбы
	can_fire = false
	
	# Останавливаем движение
	set_process(false)
	
	# Создаем область для лута отложенно
	setup_loot_area.call_deferred()
	
	# Устанавливаем таймер для удаления обломков
	setup_wreckage_cleanup_timer.call_deferred()

func setup_loot_area():
	"""Создает область для взаимодействия с обломками"""
	var loot_area = Area2D.new()
	loot_area.name = "LootArea"
	
	# Настраиваем коллизии для лута
	loot_area.collision_layer = loot_collision_layer
	loot_area.collision_mask = loot_collision_mask
	
	# Создаем коллизию для области лута (немного больше корабля)
	var loot_collision = CollisionShape2D.new()
	if collision_shape and collision_shape.shape:
		# Копируем форму основной коллизии, но увеличиваем её
		var original_shape = collision_shape.shape
		if original_shape is CapsuleShape2D:
			var loot_shape = CapsuleShape2D.new()
			loot_shape.radius = original_shape.radius * 1.2
			loot_shape.height = original_shape.height * 1.2
			loot_collision.shape = loot_shape
		elif original_shape is RectangleShape2D:
			var loot_shape = RectangleShape2D.new()
			loot_shape.size = original_shape.size * 1.2
			loot_collision.shape = loot_shape
		else:
			# Для других форм создаем простую окружность
			var loot_shape = CircleShape2D.new()
			loot_shape.radius = 40.0
			loot_collision.shape = loot_shape
	
	loot_area.add_child(loot_collision)
	add_child(loot_area)
	
	# Подключаем сигнал
	loot_area.body_entered.connect(_on_player_collision)

func _on_player_collision(body):
	"""Обрабатывает столкновение игрока с обломками"""
	if is_looted or is_fading:
		return
		
	# Проверяем, что это игрок
	if body.is_in_group("player"):
		loot_wreckage()

func loot_wreckage():
	"""Разграбляет обломки корабля"""
	if is_looted or is_fading:
		return
		
	is_looted = true
	
	# Дополнительно затемняем текстуру
	if ship_sprite:
		var current_modulate = ship_sprite.modulate
		ship_sprite.modulate = Color(
			current_modulate.r * 0.5,
			current_modulate.g * 0.5, 
			current_modulate.b * 0.5,
			current_modulate.a
		)
	
	# Отключаем область лута
	var loot_area = get_node_or_null("LootArea")
	if loot_area:
		loot_area.queue_free()
	
	# Сразу начинаем исчезать
	fade_out_wreckage()
	
	# Уведомляем о разграблении (для переопределения в наследниках)
	on_wreckage_looted()

func on_wreckage_looted():
	"""Вызывается при разграблении обломков (для переопределения в наследниках)"""
	pass

func setup_wreckage_cleanup_timer():
	"""Настраивает таймер для автоматического удаления обломков"""
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = wreckage_lifetime
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): 
		# Плавно исчезаем
		fade_out_wreckage()
	)
	add_child(cleanup_timer)
	cleanup_timer.start()

func fade_out_wreckage():
	"""Плавно удаляет обломки корабля"""
	# Предотвращаем повторное исчезновение
	if is_fading:
		return
		
	is_fading = true
	
	if not ship_sprite:
		queue_free()
		return
	
	# Отключаем область лута при принудительном исчезновении
	var loot_area = get_node_or_null("LootArea")
	if loot_area:
		loot_area.queue_free()
	
	# Определяем время исчезновения в зависимости от того, разграблен ли корабль
	var fade_time = 1.0 if is_looted else 1.5  # Немного быстрее при принудительном исчезновении
	
	# Создаем твин для плавного исчезновения
	var tween = create_tween()
	tween.tween_property(ship_sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func(): queue_free())

func on_ship_destroyed():
	"""Вызывается при уничтожении корабля (для переопределения в наследниках)"""
	pass

func create_destruction_effect():
	"""Создает эффект уничтожения корабля"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 2.0
	particles.speed_scale = 3.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	particles.color = get_destruction_color()
	
	# Добавляем частицы в родительскую сцену
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Удаляем частицы через некоторое время
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(timer)
	timer.start()

func get_destruction_color() -> Color:
	"""Возвращает цвет эффекта уничтожения (переопределяется в наследниках)"""
	return Color.ORANGE

# Методы для системы дыма
func get_ship_velocity() -> Vector2:
	"""Возвращает текущую скорость для системы дыма"""
	return velocity

# Утилитарные методы
func is_alive() -> bool:
	"""Проверяет, жив ли корабль"""
	return current_health > 0

func get_health_ratio() -> float:
	"""Возвращает отношение текущего здоровья к максимальному"""
	return current_health / max_health

func can_shoot() -> bool:
	"""Проверяет, может ли корабль стрелять"""
	return can_fire

func get_fire_cooldown_remaining() -> float:
	"""Возвращает оставшееся время перезарядки"""
	return max(0.0, fire_timer)

func get_current_speed() -> float:
	"""Возвращает текущую скорость корабля"""
	return velocity.length()

func heal(amount: float):
	"""Восстанавливает здоровье"""
	current_health = min(max_health, current_health + amount)

func set_max_health(new_max_health: float):
	"""Устанавливает максимальное здоровье"""
	max_health = max(1.0, new_max_health)
	current_health = min(current_health, max_health)

func set_fire_rate(new_rate: float):
	"""Устанавливает скорострельность"""
	fire_rate = max(0.1, new_rate)

func set_laser_damage(new_damage: float):
	"""Устанавливает урон лазера"""
	laser_damage = max(0.0, new_damage)

func enable_smoke(enabled: bool = true):
	"""Включает или выключает систему дыма"""
	if smoke_system:
		smoke_system.enable_smoke(enabled)

func clear_smoke():
	"""Очищает все частицы дыма"""
	if smoke_system:
		smoke_system.clear_all_particles()

# Методы для работы с лутом
func is_wreckage_looted() -> bool:
	"""Проверяет, разграблены ли обломки"""
	return is_looted

func can_be_looted() -> bool:
	"""Проверяет, можно ли разграбить обломки"""
	return not is_alive() and not is_looted and not is_fading

func force_loot():
	"""Принудительно разграбляет обломки"""
	if can_be_looted():
		loot_wreckage()

func set_loot_collision_layers(layer: int, mask: int):
	"""Настраивает слои коллизий для лута"""
	loot_collision_layer = layer
	loot_collision_mask = mask 
