extends Node
class_name PlayerGrapplingIntegration

# Интеграция системы крюк-кошки с игроком

var grappling_hook: GrapplingHook
var player_reference: Node2D

func _ready():
	# Подключаем обработку ввода
	set_process_input(true)

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
			launch_grappling_hook()

func handle_grappling_hook_input():
	"""Обработка ввода крюк-кошки (вызывается из _physics_process игрока)"""
	if not grappling_hook:
		return
	
	# Отсоединение крюка при нажатии Escape
	if Input.is_action_just_pressed("ui_cancel"):
		if grappling_hook.is_hook_active():
			grappling_hook.retract_hook()

func launch_grappling_hook():
	"""Запускает крюк-кошку в направлении курсора"""
	if not grappling_hook or not player_reference:
		return
	
	# Получаем позицию мыши в мировых координатах
	var mouse_position = player_reference.get_global_mouse_position()
	var player_position = player_reference.global_position
	
	# Запускаем крюк в направлении курсора
	var success = grappling_hook.launch_hook(player_position, mouse_position)
	
# Обработчики сигналов крюк-кошки
func _on_hook_attached(position: Vector2):
	"""Вызывается когда крюк прикрепляется к объекту"""
	# Вызываем метод игрока, если он существует
	if player_reference and player_reference.has_method("on_hook_attached"):
		player_reference.on_hook_attached(position)

func _on_hook_detached():
	"""Вызывается когда крюк отсоединяется"""
	# Здесь можно добавить логику завершения зацепления
	
	# Вызываем метод игрока, если он существует
	if player_reference and player_reference.has_method("on_hook_detached"):
		player_reference.on_hook_detached()

func _on_hook_hit_target(body: Node2D):
	"""Вызывается когда крюк попадает в объект"""
	# Здесь можно добавить специфичную логику для разных типов объектов
	
	# Пример будущей логики:
	# if body.has_method("can_be_grappled") and body.can_be_grappled():
	#     start_swinging_mechanics()
	# elif body.is_in_group("movable_objects"):
	#     start_pulling_mechanics(body)
	
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