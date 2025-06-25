extends Node2D
class_name SmokeSystem

# Импорт класса частицы дыма
const SmokeParticle = preload("res://Scripts/Effects/smoke_particle.gd")

# Параметры системы частиц дыма
@export var smoke_spawn_rate: float = 0.05  # Интервал между спавном частиц (в секундах)
@export var smoke_velocity_factor: float = 0.3  # Множитель скорости для частиц
@export var min_speed_for_smoke: float = 50.0  # Минимальная скорость для генерации дыма

# Внутренние переменные
var smoke_timer: float = 0.0
var particle_parent: Node2D
var target_node: Node2D  # Узел, за которым следуем (игрок)

func _ready():
	# Настраиваем систему частиц
	setup_particle_system.call_deferred()

func setup_particle_system():
	# Ищем родительскую сцену для размещения частиц
	particle_parent = get_parent()
	
	# Создаем отдельный слой для частиц ниже игрока
	if particle_parent:
		var smoke_layer = Node2D.new()
		smoke_layer.name = "SmokeLayer"
		smoke_layer.z_index = -1  # Размещаем на слой ниже
		particle_parent.add_child.call_deferred(smoke_layer)
		particle_parent = smoke_layer

func set_target(node: Node2D):
	"""Устанавливает целевой узел (игрока), за которым будем следить"""
	target_node = node

func _process(delta):
	if target_node:
		update_smoke_system(delta)

func update_smoke_system(delta):
	if not target_node:
		return
		
	# Получаем скорость целевого узла
	var current_speed = 0.0
	if target_node.has_method("get_player_velocity"):
		current_speed = target_node.get_player_velocity().length()
	elif target_node.has_method("get_velocity"):
		current_speed = target_node.get_velocity().length()
	elif "velocity" in target_node:
		current_speed = target_node.velocity.length()
	
	# Проверяем, движется ли цель достаточно быстро
	if current_speed > min_speed_for_smoke:
		smoke_timer += delta
		
		# Спавним частицы с определенным интервалом
		if smoke_timer >= smoke_spawn_rate:
			spawn_smoke_particle()
			smoke_timer = 0.0
	else:
		# Сбрасываем таймер, если цель не движется
		smoke_timer = 0.0

func spawn_smoke_particle():
	if not particle_parent or not target_node:
		return
	
	# Создаем новую частицу дыма
	var smoke = Node2D.new()
	smoke.set_script(SmokeParticle)
	
	# Получаем скорость цели
	var target_velocity = Vector2.ZERO
	if target_node.has_method("get_player_velocity"):
		target_velocity = target_node.get_player_velocity()
	elif target_node.has_method("get_velocity"):
		target_velocity = target_node.get_velocity()
	elif "velocity" in target_node:
		target_velocity = target_node.velocity
	
	# Вычисляем центр коллизии игрока
	var collision_center = get_target_collision_center()
	
	# Позиционируем частицу в центре коллизии
	smoke.position = collision_center
	
	# Задаем начальную скорость частицы (противоположную движению цели)
	var particle_velocity = -target_velocity * smoke_velocity_factor
	particle_velocity += Vector2(
		randf_range(-50, 50),   # Случайное отклонение
		randf_range(-30, 30)
	)
	
	smoke.initial_velocity = particle_velocity
	
	# Добавляем частицу в сцену отложенно
	particle_parent.add_child.call_deferred(smoke)

func get_target_collision_center() -> Vector2:
	"""Вычисляет центр коллизии целевого узла (игрока)"""
	if not target_node:
		return Vector2.ZERO
	
	# Начинаем с глобальной позиции игрока
	var center_position = target_node.global_position
	
	# Ищем CollisionShape2D среди дочерних узлов
	for child in target_node.get_children():
		if child is CollisionShape2D:
			var collision_shape = child as CollisionShape2D
			
			# Получаем позицию коллизии с учетом масштаба
			var collision_offset = collision_shape.position * collision_shape.scale
			
			# Добавляем смещение коллизии к позиции игрока с учетом масштаба игрока
			if "scale" in target_node:
				collision_offset *= target_node.scale
			
			center_position += collision_offset
			break
	
	return center_position

func enable_smoke(enabled: bool = true):
	"""Включает или выключает генерацию дыма"""
	set_process(enabled)

func clear_all_particles():
	"""Удаляет все существующие частицы дыма"""
	if particle_parent:
		for child in particle_parent.get_children():
			if child.get_script() == SmokeParticle:
				child.queue_free() 