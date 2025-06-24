extends CharacterBody2D

# Основной скрипт игрока - координирует работу компонентов

# Ссылка на спрайт игрока
var player_sprite: Sprite2D
# Система дыма
var smoke_system: SmokeSystem
# Интеграция крюк-кошки
var grappling_integration: PlayerGrapplingIntegration
# Контроллер движения
var movement_controller: PlayerMovementController

func _ready():
	# Получаем ссылку на спрайт
	find_player_sprite()
	# Подключаем все системы
	setup_smoke_system()
	setup_grappling_integration()
	setup_movement_controller()

func find_player_sprite():
	# Пробуем найти спрайт разными способами
	if has_node("Sprite2D"):
		player_sprite = get_node("Sprite2D")
	elif has_node("PlayerSprite"):
		player_sprite = get_node("PlayerSprite")
	else:
		# Ищем первый найденный Sprite2D среди дочерних узлов
		for child in get_children():
			if child is Sprite2D:
				player_sprite = child
				break
	
	if not player_sprite:
		print("Player: Спрайт не найден")
		for child in get_children():
			print("- ", child.name, " (", child.get_class(), ")")

func setup_smoke_system():
	# Создаем и настраиваем систему дыма
	smoke_system = SmokeSystem.new()
	get_parent().add_child.call_deferred(smoke_system)
	# Устанавливаем себя как цель для системы дыма
	smoke_system.set_target.call_deferred(self)

func setup_grappling_integration():
	# Создаем и настраиваем интеграцию крюк-кошки
	grappling_integration = PlayerGrapplingIntegration.new()
	grappling_integration.name = "GrapplingIntegration"
	add_child(grappling_integration)
	# Настраиваем для этого игрока
	grappling_integration.setup_for_player(self)

func setup_movement_controller():
	# Создаем и настраиваем контроллер движения
	movement_controller = PlayerMovementController.new()
	movement_controller.name = "MovementController"
	add_child(movement_controller)
	# Настраиваем для этого игрока
	movement_controller.setup_for_player(self, player_sprite)

func _physics_process(delta):
	# Обновляем движение через контроллер
	if movement_controller:
		movement_controller.update_movement(delta)
	
	# Обработка ввода крюк-кошки (клавиатурные команды)
	if grappling_integration:
		grappling_integration.handle_grappling_hook_input()

# Методы для управления системой дыма
func enable_smoke(enabled: bool = true):
	if smoke_system:
		smoke_system.enable_smoke(enabled)

func clear_smoke():
	if smoke_system:
		smoke_system.clear_all_particles()

# Утилитарные методы для крюк-кошки
func get_grappling_hook():
	"""Возвращает ссылку на систему крюк-кошки"""
	if grappling_integration:
		return grappling_integration.get_grappling_hook()
	return null

func is_hook_active() -> bool:
	"""Проверяет, активен ли крюк"""
	if grappling_integration:
		return grappling_integration.is_hook_active()
	return false

# Утилитарные методы для движения
func get_player_velocity() -> Vector2:
	"""Возвращает текущую скорость игрока"""
	if movement_controller:
		return movement_controller.get_player_velocity()
	return velocity

func get_current_speed() -> float:
	"""Возвращает текущую скорость игрока"""
	if movement_controller:
		return movement_controller.get_current_speed()
	return velocity.length()

func can_dodge() -> bool:
	"""Проверяет, может ли игрок выполнить додж"""
	if movement_controller:
		return movement_controller.can_dodge()
	return false

func is_moving() -> bool:
	"""Проверяет, движется ли игрок (нажимает клавиши)"""
	if movement_controller:
		return movement_controller.is_moving()
	return false

# Опциональные методы для обработки событий крюка (можно переопределить в наследниках)
func on_hook_attached(position: Vector2):
	"""Вызывается когда крюк прикрепляется к объекту"""
	pass

func on_hook_detached():
	"""Вызывается когда крюк отсоединяется"""
	pass

func on_hook_hit_target(body: Node2D):
	"""Вызывается когда крюк попадает в объект"""
	pass

func start_swinging_mechanics():
	"""Начинает механику раскачивания на крюке"""
	pass

func start_pulling_mechanics(target_body: Node2D):
	"""Начинает механику подтягивания объектов"""
	pass
