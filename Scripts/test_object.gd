extends StaticBody2D
class_name TestObject

# Простой тестовый объект для проверки крюк-кошки

var object_sprite: Sprite2D
var object_collision: CollisionShape2D

func _ready():
	setup_test_object()

func setup_test_object():
	# Создаем визуальное представление
	object_sprite = Sprite2D.new()
	object_sprite.texture = create_test_texture()
	add_child(object_sprite)
	
	# Создаем коллизию
	object_collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(50, 50)
	object_collision.shape = rect_shape
	add_child(object_collision)
	
	# Добавляем в группу для идентификации
	add_to_group("grappleable_objects")

func create_test_texture() -> ImageTexture:
	# Создаем простую текстуру для тестового объекта
	var image = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_GRAY)
	
	# Рисуем границы
	for x in range(50):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, 49, Color.WHITE)
	for y in range(50):
		image.set_pixel(0, y, Color.WHITE)
		image.set_pixel(49, y, Color.WHITE)
	
	# Добавляем центральную точку
	for x in range(20, 30):
		for y in range(20, 30):
			image.set_pixel(x, y, Color.GRAY)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func can_be_grappled() -> bool:
	"""Проверяет, можно ли зацепиться за этот объект"""
	return true

func on_grappled():
	"""Вызывается когда к объекту цепляется крюк"""
	print("Объект ", name, " был зацеплен крюком!")
	# Можно добавить визуальные эффекты или звуки 