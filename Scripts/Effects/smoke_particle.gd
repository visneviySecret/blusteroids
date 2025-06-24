extends Node2D

# Параметры частицы дыма
@export var initial_velocity: Vector2 = Vector2.ZERO
@export var lifetime: float = 10.0
@export var fade_speed: float = 1.0
@export var scale_speed: float = 0.5
@export var drift_force: float = 50.0

# Внутренние переменные
var velocity: Vector2
var age: float = 0.0
var initial_scale: float
var initial_alpha: float

# Компоненты
var sprite: Sprite2D

func _ready():
	# Создаем спрайт для частицы
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Создаем простую текстуру для дыма (белый круг)
	create_smoke_texture()
	
	# Инициализация
	velocity = initial_velocity
	initial_scale = randf_range(0.3, 0.8)
	initial_alpha = randf_range(0.6, 1.0)
	
	sprite.scale = Vector2(initial_scale, initial_scale)
	sprite.modulate.a = initial_alpha
	
	# Случайный цвет дыма (от белого до серого)
	var smoke_color = Color(1.0, 1.0, 1.0, initial_alpha)
	smoke_color = smoke_color.lerp(Color(0.7, 0.7, 0.7, initial_alpha), randf())
	sprite.modulate = smoke_color

func create_smoke_texture():
	# Создаем простую круглую текстуру для дыма
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center = Vector2(16, 16)
	
	for x in range(32):
		for y in range(32):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			var alpha = 1.0 - (distance / 16.0)
			alpha = max(0.0, alpha)
			alpha = pow(alpha, 2.0)  # Делаем края мягче
			
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _process(delta):
	age += delta
	
	# Проверяем время жизни
	if age >= lifetime:
		queue_free()
		return
	
	# Обновляем позицию
	position += velocity * delta
	
	# Применяем дрейф (случайное движение)
	var drift = Vector2(
		randf_range(-drift_force, drift_force),
		randf_range(-drift_force, drift_force)
	) * delta
	position += drift
	
	# Замедляем частицу
	velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
	
	# Обновляем визуальные эффекты
	var life_ratio = age / lifetime
	
	# Увеличиваем размер
	var current_scale = initial_scale + (scale_speed * life_ratio)
	sprite.scale = Vector2(current_scale, current_scale)
	
	# Уменьшаем прозрачность
	var current_alpha = initial_alpha * (1.0 - life_ratio * fade_speed)
	sprite.modulate.a = current_alpha 