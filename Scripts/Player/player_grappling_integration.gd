extends Node
class_name PlayerGrapplingIntegration

# Интеграция системы крюк-кошки с игроком

var grappling_hook: GrapplingHook
var player_reference: Node2D

# Параметры притягивания
@export var pull_force: float = 800.0  # Сила притягивания к объекту
@export var pull_speed: float = 1200.0  # Скорость притягивания (увеличена)
var is_pulling_to_target: bool = false
var pull_target_position: Vector2
var pull_target_object: Node2D = null  # Объект, к которому притягиваемся

# Состояние езды на астероиде
var is_riding_asteroid: bool = false
var current_asteroid: Node2D = null

func _ready():
	# Подключаем обработку ввода
	set_process_input(true)
	# Подключаем физический процесс для притягивания
	set_physics_process(true)

func setup_for_player(player: Node2D):
	"""Настраивает систему крюк-кошки для указанного игрока"""
	player_reference = player
	setup_grappling_hook()

func setup_grappling_hook():
	"""Создает и настраивает систему крюк-кошки"""
	if not player_reference:
		return
	
	# Создаем и настраиваем систему крюк-кошки
	grappling_hook = GrapplingHook.new()
	grappling_hook.name = "GrapplingHook"
	player_reference.get_parent().add_child.call_deferred(grappling_hook)
	# Устанавливаем ссылку на игрока
	grappling_hook.set_player_reference.call_deferred(player_reference)
	
	# Подключаем сигналы крюка
	grappling_hook.hook_attached.connect(_on_hook_attached)
	grappling_hook.hook_detached.connect(_on_hook_detached)
	grappling_hook.hook_hit_target.connect(_on_hook_hit_target)

func _input(event):
	"""Обработка событий ввода для крюк-кошки"""
	if not player_reference or not grappling_hook:
		return
	
	# Обработка событий мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Если едем на астероиде - слезаем с него
			if is_riding_asteroid:
				stop_riding_asteroid()
			# Если крюк активен - отпускаем его, если нет - запускаем
			elif grappling_hook.is_hook_active():
				grappling_hook.retract_hook()
			else:
				launch_grappling_hook()

func handle_grappling_hook_input():
	"""Обработка ввода крюк-кошки (вызывается из _physics_process игрока)"""
	if not grappling_hook:
		return
	
	# Убираем обработку Escape, теперь используем только ПКМ
	pass

func launch_grappling_hook():
	"""Запускает крюк-кошку в направлении курсора"""
	if not grappling_hook or not player_reference:
		return
	
	# Получаем позицию мыши в мировых координатах
	var mouse_position = player_reference.get_global_mouse_position()
	var player_position = player_reference.global_position
	
	# Запускаем крюк в направлении курсора
	var _success = grappling_hook.launch_hook(player_position, mouse_position)
	
func _physics_process(delta):
	"""Обновляет механику притягивания"""
	if is_pulling_to_target and player_reference:
		pull_player_to_target(delta)

func pull_player_to_target(delta):
	"""Притягивает игрока к цели"""
	if not player_reference:
		return
	
	# Вычисляем направление к цели
	var direction_to_target = (pull_target_position - player_reference.global_position).normalized()
	var distance_to_target = player_reference.global_position.distance_to(pull_target_position)
	
	# Если достигли цели, начинаем езду на астероиде
	if distance_to_target < 120.0:  # Увеличенное расстояние для посадки на верхушку
		is_pulling_to_target = false
		start_riding_asteroid()
		return
	
	# Применяем силу притягивания к игроку
	if player_reference.has_method("set") and "velocity" in player_reference:
		var pull_velocity = direction_to_target * pull_speed
		player_reference.velocity = player_reference.velocity.lerp(pull_velocity, 8.0 * delta)

func start_riding_asteroid():
	"""Начинает езду на астероиде"""
	if not pull_target_object or is_riding_asteroid:
		return
	
	# Проверяем, что объект - это астероид
	if pull_target_object.has_method("start_riding"):
		var success = pull_target_object.start_riding(player_reference)
		if success:
			is_riding_asteroid = true
			current_asteroid = pull_target_object
			
			# Отключаем обычное движение игрока
			disable_player_movement()
			
			# Возвращаем крюк к игроку
			if grappling_hook and grappling_hook.is_hook_active():
				grappling_hook.retract_hook()

func stop_riding_asteroid():
	"""Останавливает езду на астероиде"""
	if not is_riding_asteroid or not current_asteroid:
		return
	
	# Останавливаем езду на астероиде
	if current_asteroid.has_method("stop_riding"):
		current_asteroid.stop_riding()
	
	is_riding_asteroid = false
	current_asteroid = null
	
	# Включаем обычное движение игрока
	enable_player_movement()

func disable_player_movement():
	"""Отключает систему движения игрока"""
	if player_reference and player_reference.has_method("get"):
		# Отключаем контроллер движения игрока
		if "movement_controller" in player_reference and player_reference.movement_controller:
			player_reference.movement_controller.set_physics_process(false)
		
		# Сбрасываем вращение игрока и фиксируем его
		if player_reference.has_method("get") and "player_sprite" in player_reference:
			var sprite = player_reference.player_sprite
			if sprite:
				sprite.rotation = 0.0
				sprite.skew = 0.0
		
		# Также сбрасываем вращение самого игрока
		player_reference.rotation = 0.0

func enable_player_movement():
	"""Включает систему движения игрока"""
	if player_reference and player_reference.has_method("get"):
		# Включаем контроллер движения игрока
		if "movement_controller" in player_reference and player_reference.movement_controller:
			player_reference.movement_controller.set_physics_process(true)

# Обработчики сигналов крюк-кошки
func _on_hook_attached(position: Vector2):
	"""Вызывается когда крюк прикрепляется к объекту"""
	# Начинаем притягивание игрока к точке зацепления
	pull_target_position = position
	is_pulling_to_target = true
	
	# Вызываем метод игрока, если он существует
	if player_reference and player_reference.has_method("on_hook_attached"):
		player_reference.on_hook_attached(position)

func _on_hook_detached():
	"""Вызывается когда крюк отсоединяется"""
	# Останавливаем притягивание
	is_pulling_to_target = false
	pull_target_object = null
	
	# Вызываем метод игрока, если он существует
	if player_reference and player_reference.has_method("on_hook_detached"):
		player_reference.on_hook_detached()

func _on_hook_hit_target(body: Node2D):
	"""Вызывается когда крюк попадает в объект"""
	# Сохраняем ссылку на объект для дальнейшего использования
	pull_target_object = body
	
	# Вызываем метод игрока, если он существует
	if player_reference and player_reference.has_method("on_hook_hit_target"):
		player_reference.on_hook_hit_target(body)

# Методы для будущих механик зацепления
func start_swinging_mechanics():
	"""Начинает механику раскачивания на крюке"""
	# Здесь будет логика раскачивания
	if player_reference and player_reference.has_method("start_swinging_mechanics"):
		player_reference.start_swinging_mechanics()

func start_pulling_mechanics(_target_body: Node2D):
	"""Начинает механику подтягивания объектов"""
	# Здесь будет логика подтягивания объектов
	if player_reference and player_reference.has_method("start_pulling_mechanics"):
		player_reference.start_pulling_mechanics(_target_body)

# Утилитарные методы
func get_grappling_hook() -> GrapplingHook:
	"""Возвращает ссылку на систему крюк-кошки"""
	return grappling_hook

func is_hook_active() -> bool:
	"""Проверяет, активен ли крюк"""
	return grappling_hook != null and grappling_hook.is_hook_active()

func get_hook_state():
	"""Возвращает текущее состояние крюка"""
	if grappling_hook:
		return grappling_hook.get_hook_state()
	return null

func cleanup():
	"""Очистка ресурсов при удалении игрока"""
	if grappling_hook:
		grappling_hook.queue_free()
		grappling_hook = null
	player_reference = null 