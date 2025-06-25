extends CharacterBody2D

# Импорт конфига коллизий
const Layers = preload("res://Scripts/config/collision_layers.gd")
# Импорт системы топлива
const PlayerFuelSystem = preload("res://Scripts/Player/player_fuel_system.gd")

# Основной скрипт игрока - координирует работу компонентов

# Ссылка на спрайт игрока
var player_sprite: Sprite2D
# Система дыма
var smoke_system: SmokeSystem
# Интеграция крюк-кошки
var grappling_integration: PlayerGrapplingIntegration
# Контроллер движения
var movement_controller: PlayerMovementController
# Система стрельбы
var shooting_system: PlayerShootingSystem
# Система топлива
var fuel_system: PlayerFuelSystem

func _ready():
	# Добавляем игрока в группу для обнаружения врагами
	add_to_group("player")
	
	# Настраиваем слои коллизий используя конфиг
	collision_layer = Layers.PLAYER
	collision_mask = Layers.PlayerMasks.BASIC
	
	# Получаем ссылку на спрайт
	find_player_sprite()
	# Подключаем все системы
	setup_smoke_system()
	setup_grappling_integration()
	setup_movement_controller()
	setup_shooting_system()
	setup_fuel_system()

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
	add_child.call_deferred(grappling_integration)
	# Настраиваем для этого игрока (отложенно)
	grappling_integration.setup_for_player.call_deferred(self)

func setup_movement_controller():
	# Создаем и настраиваем контроллер движения
	movement_controller = PlayerMovementController.new()
	movement_controller.name = "MovementController"
	add_child.call_deferred(movement_controller)
	# Настраиваем для этого игрока (отложенно)
	movement_controller.setup_for_player.call_deferred(self, player_sprite)

func setup_shooting_system():
	# Создаем и настраиваем систему стрельбы
	shooting_system = PlayerShootingSystem.new()
	shooting_system.name = "ShootingSystem"
	add_child.call_deferred(shooting_system)
	# Настраиваем для этого игрока (отложенно)
	shooting_system.setup_for_player.call_deferred(self)

func setup_fuel_system():
	# Создаем и настраиваем систему топлива
	fuel_system = PlayerFuelSystem.new()
	fuel_system.name = "FuelSystem"
	add_child.call_deferred(fuel_system)
	# Настраиваем для этого игрока (отложенно)
	fuel_system.setup_for_player.call_deferred(self)
	# Подключаем сигналы
	fuel_system.fuel_depleted.connect(_on_fuel_depleted)
	fuel_system.fuel_restored.connect(_on_fuel_restored)

func _physics_process(delta):
	# Обновляем движение через контроллер
	if movement_controller:
		movement_controller.update_movement(delta)
	
	# Обновляем систему топлива
	if fuel_system:
		fuel_system.update_fuel(delta)
	
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
	if movement_controller and fuel_system:
		return movement_controller.can_dodge() and fuel_system.can_dodge()
	elif movement_controller:
		return movement_controller.can_dodge()
	return false

func is_moving() -> bool:
	"""Проверяет, движется ли игрок (нажимает клавиши)"""
	if movement_controller:
		return movement_controller.is_moving()
	return false

# Утилитарные методы для стрельбы
func can_shoot() -> bool:
	"""Проверяет, может ли игрок стрелять"""
	if shooting_system:
		return shooting_system.can_fire()
	return false

func get_fire_cooldown_remaining() -> float:
	"""Возвращает оставшееся время перезарядки стрельбы"""
	if shooting_system:
		return shooting_system.get_fire_cooldown_remaining()
	return 0.0

func set_fire_rate(new_rate: float):
	"""Устанавливает скорострельность"""
	if shooting_system:
		shooting_system.set_fire_rate(new_rate)

func set_laser_damage(new_damage: float):
	"""Устанавливает урон лазера"""
	if shooting_system:
		shooting_system.set_laser_damage(new_damage)

func take_damage(_damage: float):
	"""Получает урон от врагов"""
	# Здесь можно добавить систему здоровья игрока
	# Пока что просто выводим сообщение

# Опциональные методы для обработки событий крюка (можно переопределить в наследниках)
func on_hook_attached(_position_to_attach: Vector2):
	"""Вызывается когда крюк прикрепляется к объекту"""
	pass

func on_hook_detached():
	"""Вызывается когда крюк отсоединяется"""
	pass

func on_hook_hit_target(_body: Node2D):
	"""Вызывается когда крюк попадает в объект"""
	pass

func start_swinging_mechanics():
	"""Начинает механику раскачивания на крюке"""
	pass

func start_pulling_mechanics(_target_body: Node2D):
	"""Начинает механику подтягивания объектов"""
	pass

# Обработчики сигналов топлива
func _on_fuel_depleted():
	"""Вызывается когда топливо закончилось"""
	print("Топливо закончилось! Скорость снижена.")

func _on_fuel_restored():
	"""Вызывается когда топливо восстановилось"""
	print("Топливо восстановлено! Нормальная скорость.")

# Утилитарные методы для топлива
func get_current_fuel() -> float:
	"""Возвращает текущее количество топлива"""
	if fuel_system:
		return fuel_system.get_current_fuel()
	return 0.0

func get_fuel_percentage() -> float:
	"""Возвращает процент топлива (0.0 - 1.0)"""
	if fuel_system:
		return fuel_system.get_fuel_percentage()
	return 0.0

func is_fuel_depleted() -> bool:
	"""Проверяет, закончилось ли топливо"""
	if fuel_system:
		return fuel_system.is_fuel_depleted()
	return false

func refill_fuel():
	"""Полностью заправляет топливо"""
	if fuel_system:
		fuel_system.refill_fuel()
