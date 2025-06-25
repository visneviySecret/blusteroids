extends Node
class_name PlayerFuelSystem

# Система управления топливом игрока

# Параметры топлива
@export var max_fuel: float = 100.0
@export var fuel_consumption_rate: float = 20.0  # топливо в секунду при движении
@export var dodge_fuel_cost: float = 15.0  # стоимость доджа
@export var fuel_regeneration_rate: float = 10.0  # восстановление в секунду при покое
@export var low_fuel_speed_multiplier: float = 0.3  # множитель скорости при нехватке топлива

# Текущее состояние
var current_fuel: float
var is_out_of_fuel: bool = false

# Ссылки на компоненты
var fuel_bar: ProgressBar
var player_body: CharacterBody2D
var movement_controller: PlayerMovementController

# Сигналы
signal fuel_depleted
signal fuel_restored
signal fuel_changed(new_fuel: float, max_fuel: float)

func _ready():
	# Инициализируем топливо на максимум
	current_fuel = max_fuel

func setup_for_player(player: CharacterBody2D):
	"""Настраивает систему топлива для указанного игрока"""
	player_body = player
	
	# Ищем полоску топлива
	find_fuel_bar()
	
	# Получаем ссылку на контроллер движения
	movement_controller = player.get_node("MovementController")
	
	# Обновляем UI
	update_fuel_bar()

func find_fuel_bar():
	"""Ищет полоску топлива среди дочерних узлов игрока"""
	if not player_body:
		return
		
	if player_body.has_node("FuelBar"):
		fuel_bar = player_body.get_node("FuelBar")
	else:
		# Ищем среди всех дочерних узлов
		for child in player_body.get_children():
			if child is ProgressBar and child.name.to_lower().contains("fuel"):
				fuel_bar = child
				break

func update_fuel(delta: float):
	"""Обновляет уровень топлива в зависимости от действий игрока"""
	if not movement_controller:
		return
	
	var fuel_change = 0.0
	
	# Проверяем, движется ли игрок
	if movement_controller.is_moving():
		# Тратим топливо на движение
		fuel_change -= fuel_consumption_rate * delta
	else:
		# Восстанавливаем топливо при покое
		fuel_change += fuel_regeneration_rate * delta
	
	# Применяем изменение топлива
	change_fuel(fuel_change)

func consume_fuel_for_dodge() -> bool:
	"""Тратит топливо на додж. Возвращает true если хватило топлива"""
	if current_fuel >= dodge_fuel_cost:
		change_fuel(-dodge_fuel_cost)
		return true
	return false

func change_fuel(amount: float):
	"""Изменяет количество топлива"""
	var old_fuel = current_fuel
	current_fuel = clamp(current_fuel + amount, 0.0, max_fuel)
	
	# Проверяем состояние топлива
	check_fuel_state()
	
	# Обновляем UI
	update_fuel_bar()
	
	# Отправляем сигнал если топливо изменилось
	if current_fuel != old_fuel:
		fuel_changed.emit(current_fuel, max_fuel)

func check_fuel_state():
	"""Проверяет состояние топлива и отправляет соответствующие сигналы"""
	var was_out_of_fuel = is_out_of_fuel
	is_out_of_fuel = current_fuel <= 0.0
	
	# Отправляем сигналы при изменении состояния
	if not was_out_of_fuel and is_out_of_fuel:
		fuel_depleted.emit()
	elif was_out_of_fuel and not is_out_of_fuel:
		fuel_restored.emit()

func update_fuel_bar():
	"""Обновляет визуальное отображение полоски топлива"""
	if fuel_bar:
		fuel_bar.max_value = max_fuel
		fuel_bar.value = current_fuel

# === ГЕТТЕРЫ ===

func get_current_fuel() -> float:
	"""Возвращает текущее количество топлива"""
	return current_fuel

func get_max_fuel() -> float:
	"""Возвращает максимальное количество топлива"""
	return max_fuel

func get_fuel_percentage() -> float:
	"""Возвращает процент топлива (0.0 - 1.0)"""
	if max_fuel <= 0:
		return 0.0
	return current_fuel / max_fuel

func is_fuel_depleted() -> bool:
	"""Проверяет, закончилось ли топливо"""
	return is_out_of_fuel

func can_dodge() -> bool:
	"""Проверяет, хватает ли топлива для доджа"""
	return current_fuel >= dodge_fuel_cost

func get_speed_multiplier() -> float:
	"""Возвращает множитель скорости в зависимости от топлива"""
	if is_out_of_fuel:
		return low_fuel_speed_multiplier
	return 1.0

# === СЕТТЕРЫ ===

func set_max_fuel(new_max: float):
	"""Устанавливает максимальное количество топлива"""
	max_fuel = new_max
	current_fuel = min(current_fuel, max_fuel)
	update_fuel_bar()

func refill_fuel():
	"""Полностью заправляет топливо"""
	change_fuel(max_fuel - current_fuel)

func set_fuel_consumption_rate(new_rate: float):
	"""Устанавливает скорость потребления топлива"""
	fuel_consumption_rate = new_rate

func set_fuel_regeneration_rate(new_rate: float):
	"""Устанавливает скорость восстановления топлива"""
	fuel_regeneration_rate = new_rate

func add_fuel_bonus(amount: float):
	"""Добавляет бонусное топливо с визуальным эффектом"""
	if amount <= 0:
		return
	
	# Добавляем топливо
	change_fuel(amount)
	
	# Создаем визуальный эффект
	show_fuel_bonus_effect(amount)
	
func show_fuel_bonus_effect(amount: float):
	"""Показывает визуальный эффект получения топлива"""
	if not fuel_bar:
		return
	
	# Создаем лейбл для отображения бонуса
	var bonus_label = Label.new()
	bonus_label.text = "+%.0f топлива" % amount
	bonus_label.modulate = Color.GREEN
	bonus_label.z_index = 100
	
	# Позиционируем лейбл над полоской топлива
	bonus_label.position = fuel_bar.position + Vector2(0, -30)
	bonus_label.size = Vector2(100, 20)
	
	# Добавляем к родителю полоски топлива
	fuel_bar.get_parent().add_child(bonus_label)
	
	# Создаем анимацию исчезновения
	var tween = bonus_label.create_tween()
	tween.parallel().tween_property(bonus_label, "position:y", bonus_label.position.y - 50, 2.0)
	tween.parallel().tween_property(bonus_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): bonus_label.queue_free()) 