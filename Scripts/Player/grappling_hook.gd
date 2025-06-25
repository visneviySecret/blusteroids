extends Node2D
class_name GrapplingHook

# Система крюка-кошки с поддержкой движущихся объектов
# 
# Новые возможности:
# - Крюк движется вместе с движущимися объектами (корабли, враги)
# - Автоматическое определение типа объекта (движущийся/статичный)
# - Автоматический возврат при уничтожении прикрепленного объекта
# - Автоматический возврат при слишком близком расстоянии к игроку
# - Отслеживание состояния прикрепленного объекта
#
# Примеры использования:
# - hook.is_attached_to_moving_target() - проверить прикрепление к движущемуся объекту
# - hook.get_attached_target() - получить прикрепленный объект
# - hook.force_retract() - принудительно вернуть крюк
# - hook.get_distance_to_attached_target() - расстояние до объекта

# Импорт конфига коллизий
const Layers = preload("res://Scripts/config/collision_layers.gd")

# Сигналы для взаимодействия с игроком
signal hook_attached(position: Vector2)
signal hook_detached()
signal hook_hit_target(body: Node2D)

# Параметры крюка
@export var hook_speed: float = 1200.0  # Скорость полета крюка (увеличена)
@export var max_hook_distance: float = 600.0  # Максимальная дальность крюка
@export var hook_size: float = 8.0  # Размер крюка для коллизии

# Компоненты крюка
var hook_body: Area2D
var hook_collision: CollisionShape2D
var hook_sprite: Sprite2D
var line_renderer: Line2D
var hook_velocity: Vector2  # Добавляем собственную скорость

# Состояние крюка
enum HookState {
	IDLE,      # Крюк не активен
	FLYING,    # Крюк летит к цели
	ATTACHED,  # Крюк прикреплен к объекту
	RETRACTING # Крюк возвращается
}

var current_state: HookState = HookState.IDLE
var hook_direction: Vector2
var hook_start_position: Vector2
var hook_fixed_angle: float  # Фиксированный угол полета крюка
var player_reference: Node2D
var attached_target: Node2D = null  # Объект, к которому прикреплен крюк
var attachment_offset: Vector2 = Vector2.ZERO  # Смещение точки прикрепления относительно объекта
var is_attached_to_moving_object: bool = false  # Флаг для движущихся объектов

func _ready():
	setup_hook_components()

func setup_hook_components():
	# Создаем основное тело крюка как Area2D для лучшего обнаружения коллизий
	hook_body = Area2D.new()
	hook_body.name = "HookBody"
	
	# Используем конфиг коллизий
	hook_body.collision_layer = Layers.PresetConfigs.HookConfig.LAYER
	hook_body.collision_mask = Layers.PresetConfigs.HookConfig.MASK
	
	add_child(hook_body)
	
	# Создаем коллизию крюка
	hook_collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = hook_size
	hook_collision.shape = circle_shape
	hook_body.add_child(hook_collision)
	
	# Создаем визуальное представление крюка с якорем
	hook_sprite = Sprite2D.new()
	hook_sprite.texture = load("res://Assets/Images/Player/anchor.svg")
	hook_sprite.scale = Vector2(3, 3)  # Размер якоря
	hook_body.add_child(hook_sprite)
	
	# Создаем линию для веревки (белого цвета)
	line_renderer = Line2D.new()
	line_renderer.width = 3.0
	line_renderer.default_color = Color.WHITE  # Изменяем цвет на белый
	line_renderer.z_index = -1  # Рисуем позади других объектов
	add_child(line_renderer)
	
	# Подключаем сигналы коллизии для Area2D
	hook_body.body_entered.connect(_on_hook_collision)
	hook_body.area_entered.connect(_on_hook_area_collision)
	
	# Изначально скрываем крюк
	set_hook_visible(false)

func set_player_reference(player: Node2D):
	"""Устанавливает ссылку на игрока"""
	player_reference = player

func launch_hook(from_position: Vector2, target_position: Vector2):
	"""Запускает крюк в указанном направлении"""
	if current_state != HookState.IDLE:
		return false
	
	# Запоминаем угол между игроком и курсором
	hook_fixed_angle = (target_position - from_position).angle()
	hook_direction = Vector2.from_angle(hook_fixed_angle)
	
	# Устанавливаем начальные параметры
	hook_start_position = from_position
	current_state = HookState.FLYING
	
	# Позиционируем и показываем крюк
	hook_body.global_position = from_position
	hook_velocity = hook_direction * hook_speed
	
	# Поворачиваем якорь в направлении полета
	hook_sprite.rotation = hook_fixed_angle - PI/2
	
	set_hook_visible(true)
	
	return true

func _process(delta):
	update_hook_state(delta)
	update_line_renderer()
	
	# Дополнительная проверка валидности прикрепленного объекта
	if current_state == HookState.ATTACHED and attached_target:
		check_attached_target_validity()

func update_hook_state(delta):
	match current_state:
		HookState.FLYING:
			# Крюк летит под фиксированным углом от текущей позиции игрока
			if player_reference:
				# Вычисляем целевую позицию крюка на максимальной дистанции под фиксированным углом
				var target_position = player_reference.global_position + Vector2.from_angle(hook_fixed_angle) * max_hook_distance
				
				# Двигаем крюк к целевой позиции
				var direction_to_target = (target_position - hook_body.global_position).normalized()
				hook_body.global_position += direction_to_target * hook_speed * delta
				
				# Проверяем, достиг ли крюк максимальной дистанции
				var current_distance = player_reference.global_position.distance_to(hook_body.global_position)
				if current_distance >= max_hook_distance:
					# Фиксируем крюк на максимальной дистанции
					hook_body.global_position = player_reference.global_position + Vector2.from_angle(hook_fixed_angle) * max_hook_distance
					retract_hook()
			else:
				# Если нет ссылки на игрока, двигаем крюк обычным способом
				hook_body.global_position += hook_velocity * delta
			
			# Поворот якоря остается фиксированным
			hook_sprite.rotation = hook_fixed_angle - PI/2
		
		HookState.ATTACHED:
			# Крюк прикреплен - обновляем его позицию в зависимости от типа объекта
			update_attached_hook_position()
			hook_velocity = Vector2.ZERO
		
		HookState.RETRACTING:
			# Возвращаем крюк к игроку
			if player_reference:
				var direction_to_player = (player_reference.global_position - hook_body.global_position).normalized()
				hook_velocity = direction_to_player * hook_speed
				hook_body.global_position += hook_velocity * delta
				
				# Поворачиваем якорь в направлении возврата
				if hook_velocity.length() > 0:
					hook_sprite.rotation = hook_velocity.angle() + PI/2
				
				# Проверяем, достиг ли крюк игрока
				if hook_body.global_position.distance_to(player_reference.global_position) < 20.0:
					reset_hook()

func update_line_renderer():
	"""Обновляет визуализацию веревки"""
	if current_state != HookState.IDLE and player_reference:
		line_renderer.clear_points()
		line_renderer.add_point(player_reference.global_position - global_position)
		line_renderer.add_point(hook_body.global_position - global_position)
	else:
		line_renderer.clear_points()

func _on_hook_collision(body: Node):
	"""Обработчик коллизии крюка с телами"""
	if current_state != HookState.FLYING:
		return
	
	# Проверяем, что это не сам игрок
	if body == player_reference:
		return
	
	# Крюк попал в цель
	current_state = HookState.ATTACHED
	hook_velocity = Vector2.ZERO
	attached_target = body
	
	# Подключаемся к сигналам уничтожения объекта, если они есть
	connect_to_destruction_signals(body)
	
	# Определяем, является ли объект движущимся
	is_attached_to_moving_object = is_moving_object(body)
	
	# Специальная обработка для обломков кораблей
	var is_wreckage = body.has_method("is_alive") and not body.is_alive()
	
	if is_attached_to_moving_object:
		# Вычисляем смещение точки прикрепления относительно объекта
		attachment_offset = hook_body.global_position - body.global_position
	else:
		# Для статичных объектов сохраняем текущую позицию
		attachment_offset = Vector2.ZERO
	
	# Отправляем сигналы
	hook_attached.emit(hook_body.global_position)
	hook_hit_target.emit(body)
	
	# Вызываем метод объекта, если он есть
	if body.has_method("on_grappled"):
		body.on_grappled()

func connect_to_destruction_signals(object: Node):
	"""Подключается к сигналам уничтожения объекта"""
	# Подключаемся к сигналу tree_exiting (вызывается при удалении узла)
	if object.has_signal("tree_exiting") and not object.tree_exiting.is_connected(_on_attached_object_destroyed):
		object.tree_exiting.connect(_on_attached_object_destroyed)
	
	# Подключаемся к кастомным сигналам уничтожения, если они есть
	if object.has_signal("destroyed") and not object.destroyed.is_connected(_on_attached_object_destroyed):
		object.destroyed.connect(_on_attached_object_destroyed)
	
	if object.has_signal("ship_destroyed") and not object.ship_destroyed.is_connected(_on_attached_object_destroyed):
		object.ship_destroyed.connect(_on_attached_object_destroyed)

func _on_attached_object_destroyed():
	"""Вызывается при уничтожении прикрепленного объекта"""
	if current_state == HookState.ATTACHED:
		retract_hook()

func _on_hook_area_collision(area: Area2D):
	"""Обработчик коллизии крюка с областями"""
	if current_state != HookState.FLYING:
		return
	
	# Проверяем, что это не сам игрок
	if area == player_reference:
		return
	
	# Крюк попал в область
	current_state = HookState.ATTACHED
	hook_velocity = Vector2.ZERO
	attached_target = area
	
	# Подключаемся к сигналам уничтожения объекта, если они есть
	connect_to_destruction_signals(area)
	
	# Области обычно статичны, но проверяем на всякий случай
	is_attached_to_moving_object = is_moving_object(area)
	
	if is_attached_to_moving_object:
		attachment_offset = hook_body.global_position - area.global_position
	else:
		attachment_offset = Vector2.ZERO
	
	# Отправляем сигналы
	hook_attached.emit(hook_body.global_position)
	hook_hit_target.emit(area)

func retract_hook():
	"""Начинает возврат крюка"""
	if current_state == HookState.FLYING or current_state == HookState.ATTACHED:
		current_state = HookState.RETRACTING
		
		# Отключаем сигналы уничтожения объекта
		disconnect_destruction_signals()
		
		# Очищаем данные о прикреплении
		attached_target = null
		attachment_offset = Vector2.ZERO
		is_attached_to_moving_object = false
		
		hook_detached.emit()

func disconnect_destruction_signals():
	"""Отключает сигналы уничтожения от прикрепленного объекта"""
	if not attached_target:
		return
	
	# Отключаем сигнал tree_exiting
	if attached_target.has_signal("tree_exiting") and attached_target.tree_exiting.is_connected(_on_attached_object_destroyed):
		attached_target.tree_exiting.disconnect(_on_attached_object_destroyed)
	
	# Отключаем кастомные сигналы уничтожения
	if attached_target.has_signal("destroyed") and attached_target.destroyed.is_connected(_on_attached_object_destroyed):
		attached_target.destroyed.disconnect(_on_attached_object_destroyed)
	
	if attached_target.has_signal("ship_destroyed") and attached_target.ship_destroyed.is_connected(_on_attached_object_destroyed):
		attached_target.ship_destroyed.disconnect(_on_attached_object_destroyed)

func reset_hook():
	"""Сбрасывает крюк в исходное состояние"""
	current_state = HookState.IDLE
	hook_velocity = Vector2.ZERO
	
	# Отключаем сигналы уничтожения объекта
	disconnect_destruction_signals()
	
	# Очищаем данные о прикреплении
	attached_target = null
	attachment_offset = Vector2.ZERO
	is_attached_to_moving_object = false
	
	set_hook_visible(false)

func set_hook_visible(show_hook: bool):
	"""Показывает/скрывает крюк"""
	hook_body.visible = show_hook
	if not show_hook:
		line_renderer.clear_points()

func is_hook_active() -> bool:
	"""Проверяет, активен ли крюк"""
	return current_state != HookState.IDLE

func get_hook_position() -> Vector2:
	"""Возвращает текущую позицию крюка"""
	return hook_body.global_position

func get_hook_state() -> HookState:
	"""Возвращает текущее состояние крюка"""
	return current_state

# Методы для будущих механик зацепления
func can_attach_to(_body: Node) -> bool:
	"""Проверяет, можно ли прикрепиться к объекту (для будущих механик)"""
	# Здесь можно добавить логику проверки типов объектов
	return true

func get_attachment_point(body: Node) -> Vector2:
	"""Возвращает точку прикрепления на объекте (для будущих механик)"""
	if body is Node2D:
		return body.global_position
	return Vector2.ZERO

func apply_hook_force(_force: Vector2):
	"""Применяет силу к прикрепленному объекту (для будущих механик)"""
	# Здесь можно добавить логику применения силы к объектам
	pass 

func update_attached_hook_position():
	"""Обновляет позицию крюка, прикрепленного к объекту"""
	if not attached_target or not is_instance_valid(attached_target):
		# Объект был удален - отсоединяем крюк
		retract_hook()
		return
	
	# Проверяем, жив ли объект (для любых объектов с методом is_alive)
	if attached_target.has_method("is_alive") and not attached_target.is_alive():
		retract_hook()
		return
	
	# Дополнительная проверка для объектов с методом is_destroyed
	if attached_target.has_method("is_destroyed") and attached_target.is_destroyed():
		retract_hook()
		return
	
	# Проверяем, не находится ли объект в процессе удаления
	if attached_target.is_queued_for_deletion():
		retract_hook()
		return
	
	# Специальная проверка для астероидов - если они остановились по инерции
	if attached_target.has_method("is_moving_by_inertia_check") and not attached_target.is_moving_by_inertia_check():
		# Астероид остановился - теперь он статичный
		if is_attached_to_moving_object:
			is_attached_to_moving_object = false
			# Пересчитываем смещение для статичного объекта
			attachment_offset = Vector2.ZERO
	
	if is_attached_to_moving_object:
		# Обновляем позицию крюка относительно движущегося объекта
		hook_body.global_position = attached_target.global_position + attachment_offset
		
		# Проверяем расстояние до игрока для автоматического возврата
		if player_reference:
			var distance_to_player = player_reference.global_position.distance_to(hook_body.global_position)
			if distance_to_player <= 50.0:  # Пороговое расстояние
				retract_hook()
				return

func is_moving_object(object: Node) -> bool:
	"""Определяет, является ли объект движущимся"""
	# Специальная проверка для обломков кораблей
	if object.has_method("is_alive") and not object.is_alive():
		# Это обломки корабля - считаем их статичными для притягивания
		return false
	
	# Специальная проверка для астероидов, движущихся по инерции
	if object.has_method("is_moving_by_inertia_check") and object.is_moving_by_inertia_check():
		return true
	
	# Проверяем по типу объекта
	if object is CharacterBody2D or object is RigidBody2D:
		return true
	
	# Проверяем по группам
	if object.is_in_group("enemies") or object.is_in_group("moving_objects"):
		return true
	
	# Проверяем по наличию определенных методов (корабли)
	if object.has_method("get_ship_velocity") or object.has_method("get_current_speed"):
		return true
	
	# Проверяем по классу
	if object.get_script():
		var script_path = object.get_script().resource_path
		if "ship" in script_path.to_lower() or "enemy" in script_path.to_lower():
			return true
	
	# По умолчанию считаем объект статичным
	return false 

func get_attached_target() -> Node2D:
	"""Возвращает объект, к которому прикреплен крюк"""
	return attached_target

func is_attached_to_moving_target() -> bool:
	"""Проверяет, прикреплен ли крюк к движущемуся объекту"""
	return current_state == HookState.ATTACHED and is_attached_to_moving_object

func is_attached_to_target() -> bool:
	"""Проверяет, прикреплен ли крюк к какому-либо объекту"""
	return current_state == HookState.ATTACHED and attached_target != null

func get_attachment_offset() -> Vector2:
	"""Возвращает смещение точки прикрепления относительно объекта"""
	return attachment_offset

func get_distance_to_attached_target() -> float:
	"""Возвращает расстояние до прикрепленного объекта"""
	if not player_reference or not attached_target:
		return INF
	return player_reference.global_position.distance_to(attached_target.global_position)

func force_retract():
	"""Принудительно возвращает крюк (может быть вызван игроком)"""
	if current_state == HookState.ATTACHED or current_state == HookState.FLYING:
		retract_hook()

func set_auto_retract_distance(distance: float):
	"""Устанавливает расстояние автоматического возврата для движущихся объектов"""
	# Обновляем пороговое расстояние в методе update_attached_hook_position
	pass 

func check_attached_target_validity():
	"""Проверяет, валиден ли прикрепленный объект"""
	if not attached_target or not is_instance_valid(attached_target):
		retract_hook()
		return
	
	# Проверяем, жив ли объект (для любых объектов с методом is_alive)
	if attached_target.has_method("is_alive") and not attached_target.is_alive():
		retract_hook()
		return
	
	# Дополнительная проверка для объектов с методом is_destroyed
	if attached_target.has_method("is_destroyed") and attached_target.is_destroyed():
		retract_hook()
		return
	
	# Проверяем, не находится ли объект в процессе удаления
	if attached_target.is_queued_for_deletion():
		retract_hook()
		return
	
	if is_attached_to_moving_object:
		# Проверяем расстояние до игрока для автоматического возврата
		if player_reference:
			var distance_to_player = player_reference.global_position.distance_to(hook_body.global_position)
			if distance_to_player <= 50.0:  # Пороговое расстояние
				retract_hook()
				return
