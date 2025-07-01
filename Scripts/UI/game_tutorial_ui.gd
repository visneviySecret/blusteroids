extends CanvasLayer
class_name GameTutorialUI

# Скрипт управления туториалом в игре

# Ссылки на UI элементы
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var tutorial_panel: Panel = $TutorialOverlay/TutorialPanel
@onready var close_button: Button = $TutorialOverlay/TutorialPanel/TutorialContainer/HeaderContainer/CloseButton
@onready var quick_help_button: Button = $TutorialOverlay/QuickHelpButton
@onready var tutorial_title: Label = $TutorialOverlay/TutorialPanel/TutorialContainer/HeaderContainer/TutorialTitle

# Состояние туториала
var is_tutorial_visible: bool = true
var is_first_time: bool = true

# Время отображения для автоскрытия
var auto_hide_timer: float = 0.0
var auto_hide_delay: float = 15.0  # Автоматически скрыть через 15 секунд

func _ready():
	# Подключаем сигналы кнопок
	close_button.pressed.connect(_on_close_button_pressed)
	quick_help_button.pressed.connect(_on_quick_help_button_pressed)
	
	# Настраиваем стили
	setup_ui_styles()
	
	# Показываем туториал при первом запуске
	if is_first_time:
		show_tutorial_with_delay()
	else:
		hide_tutorial()

func _input(event):
	"""Обработка клавиатурного ввода"""
	if event.is_action_pressed("toggle_tutorial"):  # Клавиша T
		toggle_tutorial()
	elif event.is_action_pressed("ui_cancel") and is_tutorial_visible:  # Escape
		hide_tutorial()

func _process(delta):
	"""Обновление таймера автоскрытия"""
	if is_tutorial_visible and is_first_time:
		auto_hide_timer += delta
		if auto_hide_timer >= auto_hide_delay:
			hide_tutorial()
			is_first_time = false

func show_tutorial_with_delay():
	"""Показывает туториал с небольшой задержкой"""
	await get_tree().create_timer(0.5).timeout
	show_tutorial()

func show_tutorial():
	"""Показывает туториал"""
	is_tutorial_visible = true
	tutorial_panel.visible = true
	
	# Анимация появления
	var tween = create_tween()
	tutorial_panel.modulate.a = 0.0
	tutorial_panel.position.x = tutorial_panel.position.x + 50
	
	tween.parallel().tween_property(tutorial_panel, "modulate:a", 0.9, 0.3)
	tween.parallel().tween_property(tutorial_panel, "position:x", tutorial_panel.position.x - 50, 0.3)
	
	# Обновляем кнопку быстрой помощи
	quick_help_button.text = "СКРЫТЬ (T)"

func hide_tutorial():
	"""Скрывает туториал"""
	is_tutorial_visible = false
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.parallel().tween_property(tutorial_panel, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(tutorial_panel, "position:x", tutorial_panel.position.x + 50, 0.3)
	tween.tween_callback(func(): tutorial_panel.visible = false)
	
	# Обновляем кнопку быстрой помощи
	quick_help_button.text = "ТУТОРИАЛ (T)"
	
	# Сбрасываем таймер
	auto_hide_timer = 0.0

func toggle_tutorial():
	"""Переключает видимость туториала"""
	if is_tutorial_visible:
		hide_tutorial()
	else:
		show_tutorial()
	
	# После первого ручного переключения отключаем автоскрытие
	is_first_time = false

func setup_ui_styles():
	"""Настраивает стили UI элементов"""
	# Стиль панели туториала
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.3, 0.95)
	panel_style.border_color = Color.CYAN
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	
	tutorial_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Стиль кнопки закрытия
	var close_button_style = StyleBoxFlat.new()
	close_button_style.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_button_style.border_color = Color.RED
	close_button_style.border_width_left = 1
	close_button_style.border_width_right = 1
	close_button_style.border_width_top = 1
	close_button_style.border_width_bottom = 1
	close_button_style.corner_radius_top_left = 3
	close_button_style.corner_radius_top_right = 3
	close_button_style.corner_radius_bottom_left = 3
	close_button_style.corner_radius_bottom_right = 3
	
	var close_button_hover_style = close_button_style.duplicate()
	close_button_hover_style.bg_color = Color(1.0, 0.3, 0.3, 0.9)
	
	close_button.add_theme_stylebox_override("normal", close_button_style)
	close_button.add_theme_stylebox_override("hover", close_button_hover_style)
	close_button.add_theme_stylebox_override("pressed", close_button_hover_style)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_font_size_override("font_size", 18)
	
	# Стиль кнопки быстрой помощи
	var help_button_style = StyleBoxFlat.new()
	help_button_style.bg_color = Color(0.2, 0.6, 0.2, 0.8)
	help_button_style.border_color = Color.GREEN
	help_button_style.border_width_left = 1
	help_button_style.border_width_right = 1
	help_button_style.border_width_top = 1
	help_button_style.border_width_bottom = 1
	help_button_style.corner_radius_top_left = 5
	help_button_style.corner_radius_top_right = 5
	help_button_style.corner_radius_bottom_left = 5
	help_button_style.corner_radius_bottom_right = 5
	
	var help_button_hover_style = help_button_style.duplicate()
	help_button_hover_style.bg_color = Color(0.3, 0.7, 0.3, 0.9)
	
	quick_help_button.add_theme_stylebox_override("normal", help_button_style)
	quick_help_button.add_theme_stylebox_override("hover", help_button_hover_style)
	quick_help_button.add_theme_stylebox_override("pressed", help_button_hover_style)
	quick_help_button.add_theme_color_override("font_color", Color.WHITE)
	quick_help_button.add_theme_font_size_override("font_size", 12)
	
	# Стиль заголовка
	tutorial_title.add_theme_color_override("font_color", Color.GOLD)
	tutorial_title.add_theme_font_size_override("font_size", 20)

# Обработчики событий

func _on_close_button_pressed():
	"""Закрытие туториала по кнопке X"""
	hide_tutorial()
	is_first_time = false

func _on_quick_help_button_pressed():
	"""Переключение туториала по кнопке быстрой помощи"""
	toggle_tutorial()

# Публичные методы для внешнего управления

func force_show_tutorial():
	"""Принудительно показывает туториал (для внешних вызовов)"""
	show_tutorial()
	is_first_time = false

func force_hide_tutorial():
	"""Принудительно скрывает туториал (для внешних вызовов)"""
	hide_tutorial()
	is_first_time = false

func is_tutorial_showing() -> bool:
	"""Проверяет, отображается ли туториал"""
	return is_tutorial_visible

func set_auto_hide_delay(delay: float):
	"""Устанавливает задержку автоскрытия"""
	auto_hide_delay = delay

func disable_auto_hide():
	"""Отключает автоматическое скрытие"""
	is_first_time = false
	auto_hide_timer = 0.0 