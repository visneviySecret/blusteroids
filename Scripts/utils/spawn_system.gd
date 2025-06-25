class_name SpawnSystem

# Общая система спавна объектов за пределами экрана
# Переиспользуемая логика для кораблей, астероидов и других объектов

# Структура для параметров спавна
class SpawnParams:
	var screen_margin: float = 100.0  # Отступ за пределы экрана
	var min_distance_from_target: float = 0.0  # Минимальная дистанция от цели (игрока)
	var max_distance_from_target: float = 0.0  # Максимальная дистанция от цели (игрока)
	var additional_offset: float = 0.0  # Дополнительный отступ (например, для больших объектов)
	
	func _init(margin: float = 100.0, min_dist: float = 0.0, max_dist: float = 0.0, offset: float = 0.0):
		screen_margin = margin
		min_distance_from_target = min_dist
		max_distance_from_target = max_dist
		additional_offset = offset

# Статические методы для спавна

static func get_offscreen_spawn_position(viewport: Viewport, target_node: Node2D = null, params: SpawnParams = null) -> Vector2:
	"""Вычисляет позицию спавна за пределами экрана"""
	if not params:
		params = SpawnParams.new()
	
	# Получаем размеры экрана
	var screen_size = viewport.get_visible_rect().size
	var camera = viewport.get_camera_2d()
	
	# Определяем центр экрана
	var camera_center = Vector2.ZERO
	if camera:
		camera_center = camera.global_position
	elif target_node:
		camera_center = target_node.global_position
	
	# Вычисляем границы экрана с учетом позиции камеры
	var screen_rect = Rect2(
		camera_center - screen_size * 0.5,
		screen_size
	)
	
	# Общий отступ = базовый отступ + дополнительный
	var total_margin = params.screen_margin + params.additional_offset
	
	# Расширяем границы для спавна за пределами экрана
	var spawn_rect = Rect2(
		screen_rect.position - Vector2(total_margin, total_margin),
		screen_rect.size + Vector2(total_margin * 2, total_margin * 2)
	)
	
	# Выбираем случайную сторону экрана для спавна
	var side = randi() % 4
	var spawn_position = Vector2.ZERO
	
	match side:
		0: # Верх
			spawn_position = Vector2(
				randf_range(spawn_rect.position.x, spawn_rect.position.x + spawn_rect.size.x),
				spawn_rect.position.y
			)
		1: # Право
			spawn_position = Vector2(
				spawn_rect.position.x + spawn_rect.size.x,
				randf_range(spawn_rect.position.y, spawn_rect.position.y + spawn_rect.size.y)
			)
		2: # Низ
			spawn_position = Vector2(
				randf_range(spawn_rect.position.x, spawn_rect.position.x + spawn_rect.size.x),
				spawn_rect.position.y + spawn_rect.size.y
			)
		3: # Лево
			spawn_position = Vector2(
				spawn_rect.position.x,
				randf_range(spawn_rect.position.y, spawn_rect.position.y + spawn_rect.size.y)
			)
	
	# Применяем ограничения по дистанции от цели (если заданы)
	if target_node and (params.min_distance_from_target > 0 or params.max_distance_from_target > 0):
		spawn_position = apply_distance_constraints(spawn_position, target_node.global_position, params)
	
	return spawn_position

static func apply_distance_constraints(spawn_pos: Vector2, target_pos: Vector2, params: SpawnParams) -> Vector2:
	"""Применяет ограничения по дистанции от цели"""
	var distance_to_target = spawn_pos.distance_to(target_pos)
	
	# Проверяем минимальную дистанцию
	if params.min_distance_from_target > 0 and distance_to_target < params.min_distance_from_target:
		var direction_from_target = (spawn_pos - target_pos).normalized()
		spawn_pos = target_pos + direction_from_target * params.min_distance_from_target
	
	# Проверяем максимальную дистанцию
	if params.max_distance_from_target > 0 and distance_to_target > params.max_distance_from_target:
		var direction_to_target = (target_pos - spawn_pos).normalized()
		spawn_pos = target_pos + direction_to_target * params.max_distance_from_target
	
	return spawn_pos

static func get_simple_offscreen_position(viewport: Viewport, camera: Camera2D = null, margin: float = 100.0) -> Vector2:
	"""Упрощенная версия для простого спавна за пределами экрана"""
	var params = SpawnParams.new(margin)
	return get_offscreen_spawn_position(viewport, null, params)

static func get_spawn_direction_to_screen_center(spawn_pos: Vector2, viewport: Viewport, camera: Camera2D = null) -> Vector2:
	"""Возвращает направление от позиции спавна к центру экрана"""
	var screen_center = Vector2.ZERO
	if camera:
		screen_center = camera.global_position
	
	return (screen_center - spawn_pos).normalized()

static func get_random_screen_target(viewport: Viewport, camera: Camera2D = null) -> Vector2:
	"""Возвращает случайную точку на экране как цель для движения"""
	var screen_size = viewport.get_visible_rect().size
	var screen_center = Vector2.ZERO
	if camera:
		screen_center = camera.global_position
	
	return Vector2(
		screen_center.x + randf_range(-screen_size.x/2, screen_size.x/2),
		screen_center.y + randf_range(-screen_size.y/2, screen_size.y/2)
	)

# Утилитарные методы для проверки

static func is_position_outside_screen(pos: Vector2, viewport: Viewport, camera: Camera2D = null, margin: float = 0.0) -> bool:
	"""Проверяет, находится ли позиция за пределами экрана"""
	var screen_size = viewport.get_visible_rect().size
	var screen_center = Vector2.ZERO
	if camera:
		screen_center = camera.global_position
	
	var half_width = screen_size.x / 2 + margin
	var half_height = screen_size.y / 2 + margin
	
	var relative_pos = pos - screen_center
	
	return (abs(relative_pos.x) > half_width or abs(relative_pos.y) > half_height)

static func get_deletion_bounds(viewport: Viewport, camera: Camera2D = null, scale_factor: float = 2.0) -> Rect2:
	"""Возвращает границы для удаления объектов (обычно в 2 раза больше экрана)"""
	var screen_size = viewport.get_visible_rect().size
	var screen_center = Vector2.ZERO
	if camera:
		screen_center = camera.global_position
	
	var extended_size = screen_size * scale_factor
	return Rect2(
		screen_center - extended_size / 2.0,
		extended_size
	) 