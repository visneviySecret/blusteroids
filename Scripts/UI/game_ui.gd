extends CanvasLayer
class_name GameUI

# Скрипт управления игровым интерфейсом

# Ссылки на UI элементы
@onready var fuel_bar: ProgressBar = $UIContainer/TopLeftUI/FuelBar
@onready var fuel_text: Label = $UIContainer/TopLeftUI/FuelText
@onready var enemies_killed_label: Label = $UIContainer/TopLeftUI/StatsContainer/EnemiesKilled
@onready var asteroids_destroyed_label: Label = $UIContainer/TopLeftUI/StatsContainer/AsteroidsDestroyed

# Ссылки на игровые объекты
var player: CharacterBody2D
var player_fuel_system: PlayerFuelSystem

# Статистика игры
var enemies_killed: int = 0
var asteroids_destroyed: int = 0

func _ready():
	# Ищем игрока в сцене
	find_player()
	
	# Настраиваем стили UI
	setup_ui_styles()
	
	# Обновляем UI
	update_ui()

func find_player():
	"""Находит игрока в сцене"""
	# Ищем игрока в родительской сцене
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
		# Ищем систему топлива игрока
		if player:
			for child in player.get_children():
				if child is PlayerFuelSystem:
					player_fuel_system = child
					# Подключаем сигналы изменения топлива
					player_fuel_system.fuel_changed.connect(_on_fuel_changed)
					break

func _process(_delta):
	"""Обновляем UI каждый кадр"""
	update_fuel_display()

func update_ui():
	"""Обновляет весь UI"""
	update_fuel_display()
	update_statistics()

func update_fuel_display():
	"""Обновляет отображение топлива"""
	if not player_fuel_system:
		return
	
	var current_fuel = player_fuel_system.get_current_fuel()
	var max_fuel = player_fuel_system.get_max_fuel()
	
	# Обновляем прогресс бар
	fuel_bar.max_value = max_fuel
	fuel_bar.value = current_fuel
	
	# Обновляем текст
	fuel_text.text = "%.0f / %.0f" % [current_fuel, max_fuel]
	
	# Меняем цвет в зависимости от уровня топлива
	var fuel_percentage = current_fuel / max_fuel
	if fuel_percentage > 0.6:
		fuel_bar.modulate = Color.GREEN
		fuel_text.modulate = Color.WHITE
	elif fuel_percentage > 0.3:
		fuel_bar.modulate = Color.YELLOW
		fuel_text.modulate = Color.YELLOW
	else:
		fuel_bar.modulate = Color.RED
		fuel_text.modulate = Color.RED

func update_statistics():
	"""Обновляет статистику игры"""
	enemies_killed_label.text = "Врагов уничтожено: %d" % enemies_killed
	asteroids_destroyed_label.text = "Астероидов разрушено: %d" % asteroids_destroyed

func setup_ui_styles():
	"""Настраивает стили UI элементов"""
	# Стиль для полоски топлива
	var fuel_bar_style = StyleBoxFlat.new()
	fuel_bar_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	fuel_bar_style.border_color = Color.WHITE
	fuel_bar_style.border_width_left = 1
	fuel_bar_style.border_width_right = 1
	fuel_bar_style.border_width_top = 1
	fuel_bar_style.border_width_bottom = 1
	fuel_bar_style.corner_radius_top_left = 3
	fuel_bar_style.corner_radius_top_right = 3
	fuel_bar_style.corner_radius_bottom_left = 3
	fuel_bar_style.corner_radius_bottom_right = 3
	
	fuel_bar.add_theme_stylebox_override("background", fuel_bar_style)
	
	var fuel_fill_style = StyleBoxFlat.new()
	fuel_fill_style.bg_color = Color.GREEN
	fuel_fill_style.corner_radius_top_left = 3
	fuel_fill_style.corner_radius_top_right = 3
	fuel_fill_style.corner_radius_bottom_left = 3
	fuel_fill_style.corner_radius_bottom_right = 3
	
	fuel_bar.add_theme_stylebox_override("fill", fuel_fill_style)
	
	# Стили для лейблов
	var ui_labels = [
		$UIContainer/TopLeftUI/FuelLabel,
		$UIContainer/TopLeftUI/StatsLabel
	]
	
	for label in ui_labels:
		if label:
			label.add_theme_color_override("font_color", Color.CYAN)
			label.add_theme_font_size_override("font_size", 14)
	
	# Стили для текста статистики
	var stats_labels = [enemies_killed_label, asteroids_destroyed_label, fuel_text]
	for label in stats_labels:
		if label:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 12)

# Обработчики событий

func _on_fuel_changed(new_fuel: float, max_fuel: float):
	"""Обработчик изменения топлива"""
	# UI обновляется автоматически в _process
	pass

# Публичные методы для обновления статистики

func add_enemy_killed():
	"""Добавляет одного убитого врага к статистике"""
	enemies_killed += 1
	update_statistics()

func add_asteroid_destroyed():
	"""Добавляет один разрушенный астероид к статистике"""
	asteroids_destroyed += 1
	update_statistics()

func reset_statistics():
	"""Сбрасывает статистику"""
	enemies_killed = 0
	asteroids_destroyed = 0
	update_statistics()

# Методы для доступа к статистике

func get_enemies_killed() -> int:
	"""Возвращает количество убитых врагов"""
	return enemies_killed

func get_asteroids_destroyed() -> int:
	"""Возвращает количество разрушенных астероидов"""
	return asteroids_destroyed

func get_total_score() -> int:
	"""Возвращает общий счет (пример расчета)"""
	return enemies_killed * 100 + asteroids_destroyed * 10 