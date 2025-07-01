extends Control
class_name StartMenu

# Скрипт начального экрана с туториалом

@export var main_scene: PackedScene

# Ссылки на UI элементы
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var tutorial_button: Button = $VBoxContainer/ButtonContainer/TutorialButton
@onready var exit_button: Button = $VBoxContainer/ButtonContainer/ExitButton
@onready var tutorial_panel: Panel = $TutorialPanel
@onready var close_button: Button = $TutorialPanel/TutorialContainer/CloseButton
@onready var star_field: Control = $Background/StarField

# Параметры анимированного фона
var stars: Array[StarParticle] = []
var star_count: int = 100

# Структура для звезд
class StarParticle:
	var position: Vector2
	var velocity: Vector2
	var size: float
	var brightness: float
	var color: Color
	
	func _init(pos: Vector2, vel: Vector2, star_size: float, star_brightness: float, star_color: Color):
		position = pos
		velocity = vel
		size = star_size
		brightness = star_brightness
		color = star_color

func _ready():
	# Подключаем сигналы кнопок
	start_button.pressed.connect(_on_start_button_pressed)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	close_button.pressed.connect(_on_close_tutorial_button_pressed)
	
	# Создаем звездное поле
	create_star_field()
	
	# Настраиваем стили кнопок
	setup_button_styles()
	
	# Настраиваем стили текста
	setup_text_styles()

func _process(delta):
	# Обновляем анимацию звезд
	update_star_field(delta)

func create_star_field():
	"""Создает анимированное звездное поле"""
	stars.clear()
	var screen_size = get_viewport().get_visible_rect().size
	
	for i in range(star_count):
		var star_pos = Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		)
		var star_vel = Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		var star_size = randf_range(1, 3)
		var star_brightness = randf_range(0.3, 1.0)
		var star_color = Color.WHITE
		
		# Разные цвета для звезд
		match randi() % 4:
			0: star_color = Color.WHITE
			1: star_color = Color.LIGHT_BLUE
			2: star_color = Color.LIGHT_YELLOW
			3: star_color = Color.LIGHT_CYAN
		
		stars.append(StarParticle.new(star_pos, star_vel, star_size, star_brightness, star_color))

func update_star_field(delta: float):
	"""Обновляет позицию звезд"""
	var screen_size = get_viewport().get_visible_rect().size
	
	for star in stars:
		star.position += star.velocity * delta
		
		# Переносим звезды которые вышли за границы экрана
		if star.position.x < 0:
			star.position.x = screen_size.x
		elif star.position.x > screen_size.x:
			star.position.x = 0
		
		if star.position.y < 0:
			star.position.y = screen_size.y
		elif star.position.y > screen_size.y:
			star.position.y = 0
	
	# Перерисовываем звездное поле
	star_field.queue_redraw()

func _draw():
	"""Отрисовка звездного поля"""
	for star in stars:
		var final_color = star.color
		final_color.a = star.brightness
		draw_circle(star.position, star.size, final_color)

func setup_button_styles():
	"""Настраивает стили кнопок"""
	# Увеличиваем размер шрифта для кнопок
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.3, 0.6, 0.8)
	button_style.border_color = Color.CYAN
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.3, 0.4, 0.7, 0.9)
	button_hover_style.border_color = Color.YELLOW
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_bottom = 2
	button_hover_style.corner_radius_top_left = 5
	button_hover_style.corner_radius_top_right = 5
	button_hover_style.corner_radius_bottom_left = 5
	button_hover_style.corner_radius_bottom_right = 5
	
	# Применяем стили ко всем кнопкам
	for button in [start_button, tutorial_button, exit_button, close_button]:
		if button:
			button.add_theme_stylebox_override("normal", button_style.duplicate())
			button.add_theme_stylebox_override("hover", button_hover_style.duplicate())
			button.add_theme_stylebox_override("pressed", button_hover_style.duplicate())
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_color_override("font_hover_color", Color.YELLOW)

func setup_text_styles():
	"""Настраивает стили текста"""
	# Настраиваем заголовок
	var title_label = $VBoxContainer/Title
	if title_label:
		title_label.add_theme_color_override("font_color", Color.CYAN)
		# Попытка увеличить размер шрифта (может не сработать если нет темы)
		var title_font = ThemeDB.fallback_font
		title_label.add_theme_font_size_override("font_size", 48)
	
	# Настраиваем подзаголовок
	var subtitle_label = $VBoxContainer/Subtitle
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		subtitle_label.add_theme_font_size_override("font_size", 18)
	
	# Настраиваем заголовок туториала
	var tutorial_title = $TutorialPanel/TutorialContainer/TutorialTitle
	if tutorial_title:
		tutorial_title.add_theme_color_override("font_color", Color.GOLD)
		tutorial_title.add_theme_font_size_override("font_size", 24)

# Обработчики событий кнопок

func _on_start_button_pressed():
	"""Запускает основную игру"""
	if main_scene:
		get_tree().change_scene_to_packed(main_scene)
	else:
		# Резервный способ загрузки
		get_tree().change_scene_to_file("res://Scene/main_scene.tscn")

func _on_tutorial_button_pressed():
	"""Показывает подробный туториал"""
	tutorial_panel.visible = true
	# Анимация появления (опционально)
	var tween = create_tween()
	tutorial_panel.modulate.a = 0.0
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.3)

func _on_close_tutorial_button_pressed():
	"""Закрывает подробный туториал"""
	# Анимация исчезновения (опционально)
	var tween = create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): tutorial_panel.visible = false)

func _on_exit_button_pressed():
	"""Выходит из игры"""
	get_tree().quit()

# Обработка ввода
func _input(event):
	"""Обработка клавиатурного ввода"""
	if event.is_action_pressed("ui_cancel"):  # Escape
		if tutorial_panel.visible:
			_on_close_tutorial_button_pressed()
		else:
			_on_exit_button_pressed()
	elif event.is_action_pressed("ui_accept"):  # Enter
		if not tutorial_panel.visible:
			_on_start_button_pressed()

# Переопределяем отрисовку для звездного поля
func _draw():
	"""Отрисовка звездного поля в фоне"""
	for star in stars:
		var final_color = star.color
		final_color.a = star.brightness
		draw_circle(star.position, star.size, final_color) 