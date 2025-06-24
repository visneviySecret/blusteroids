extends Node
class_name PlayerShootingSystem

# Система стрельбы игрока

# Параметры стрельбы
@export var fire_rate: float = 0.2  # Интервал между выстрелами (секунды)
@export var laser_speed: float = 1000.0
@export var laser_damage: float = 10.0
@export var muzzle_offset: Vector2 = Vector2(30, 0)  # Смещение точки выстрела относительно игрока

# Ссылки на компоненты
var player_body: CharacterBody2D
var projectile_parent: Node2D  # Родительский узел для снарядов

# Переменные стрельбы
var fire_timer: float = 0.0
var can_shoot: bool = true

# Загружаем класс лазерного снаряда
const LaserProjectileScript = preload("res://Scripts/Player/laser_projectile.gd")

func _ready():
	# Подключаем обработку ввода
	set_process_input(true)

func setup_for_player(player: CharacterBody2D):
	"""Настраивает систему стрельбы для указанного игрока"""
	player_body = player
	
	# Находим родительский узел для снарядов
	setup_projectile_parent()

func setup_projectile_parent():
	"""Настраивает родительский узел для размещения снарядов"""
	if player_body:
		# Ищем родительскую сцену
		projectile_parent = player_body.get_parent()
		
		# Создаем отдельный слой для снарядов
		if projectile_parent:
			var projectiles_layer = Node2D.new()
			projectiles_layer.name = "ProjectilesLayer"
			projectiles_layer.z_index = 1  # Размещаем выше игрока
			# Используем call_deferred для избежания ошибки "Parent node is busy"
			projectile_parent.add_child.call_deferred(projectiles_layer)
			projectile_parent = projectiles_layer

func _input(event):
	"""Обработка событий ввода"""
	if not player_body:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			attempt_shoot()

func _process(delta):
	"""Обновление системы стрельбы"""
	update_fire_timer(delta)

func update_fire_timer(delta):
	"""Обновляет таймер перезарядки стрельбы"""
	if fire_timer > 0:
		fire_timer -= delta
		if fire_timer <= 0:
			can_shoot = true

func attempt_shoot():
	"""Попытка выстрелить"""
	if not can_shoot or not player_body:
		return
	
	# Получаем направление к курсору мыши
	var mouse_position = player_body.get_global_mouse_position()
	var shoot_direction = (mouse_position - player_body.global_position).normalized()
	
	# Выполняем выстрел
	shoot_laser(shoot_direction)
	
	# Запускаем перезарядку
	fire_timer = fire_rate
	can_shoot = false

func shoot_laser(direction: Vector2):
	"""Создает и запускает лазерный снаряд"""
	if not projectile_parent:
		return
	
	# Вычисляем точку выстрела с учетом поворота игрока
	var rotated_offset = muzzle_offset.rotated(direction.angle())
	var shoot_position = player_body.global_position + rotated_offset
	
	# Создаем лазерный снаряд используя статический метод, передавая ссылку на игрока
	var laser = LaserProjectileScript.create_laser_projectile(shoot_position, direction, player_body, laser_speed, laser_damage)
	
	# Добавляем лазер в сцену отложенно
	projectile_parent.add_child.call_deferred(laser)
	
	# Убираем эффект вспышки выстрела
	# create_simple_muzzle_flash(shoot_position)
	
# === УТИЛИТАРНЫЕ МЕТОДЫ ===

func can_fire() -> bool:
	"""Проверяет, может ли игрок стрелять"""
	return can_shoot

func get_fire_cooldown_remaining() -> float:
	"""Возвращает оставшееся время перезарядки"""
	return max(0.0, fire_timer)

func get_fire_cooldown_progress() -> float:
	"""Возвращает прогресс перезарядки (0.0 - готов, 1.0 - только что выстрелил)"""
	if fire_rate <= 0:
		return 0.0
	return get_fire_cooldown_remaining() / fire_rate

func set_fire_rate(new_rate: float):
	"""Устанавливает новую скорострельность"""
	fire_rate = max(0.01, new_rate)  # Минимум 0.01 секунды

func set_laser_damage(new_damage: float):
	"""Устанавливает новый урон лазера"""
	laser_damage = max(0.0, new_damage)

func cleanup():
	"""Очистка ресурсов"""
	player_body = null
	projectile_parent = null 
