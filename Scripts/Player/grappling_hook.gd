extends Node2D
class_name GrapplingHook

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

func _ready():
	setup_hook_components()

func setup_hook_components():
	# Создаем основное тело крюка как Area2D для лучшего обнаружения коллизий
	hook_body = Area2D.new()
	hook_body.name = "HookBody"
	hook_body.collision_layer = 2  # Устанавливаем слой коллизии
	hook_body.collision_mask = 1   # Маска для столкновений с объектами
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
	hook_sprite.scale = Vector2(4, 4)  # Размер якоря
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
			# Крюк прикреплен - останавливаем движение, но сохраняем поворот
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
	
	# Отправляем сигналы
	hook_attached.emit(hook_body.global_position)
	hook_hit_target.emit(body)
	
	# Вызываем метод объекта, если он есть
	if body.has_method("on_grappled"):
		body.on_grappled()
	
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
	
	# Отправляем сигналы
	hook_attached.emit(hook_body.global_position)
	hook_hit_target.emit(area)

func retract_hook():
	"""Начинает возврат крюка"""
	if current_state == HookState.FLYING or current_state == HookState.ATTACHED:
		current_state = HookState.RETRACTING
		hook_detached.emit()

func reset_hook():
	"""Сбрасывает крюк в исходное состояние"""
	current_state = HookState.IDLE
	hook_velocity = Vector2.ZERO
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
