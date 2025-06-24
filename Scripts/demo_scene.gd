extends Node2D

# Демонстрационная сцена для тестирования крюк-кошки

func _ready():
	setup_demo_scene()

func setup_demo_scene():
	# Создаем несколько тестовых объектов для зацепления
	create_test_objects()

func create_test_objects():
	# Создаем тестовые объекты в разных позициях
	var positions = [
		Vector2(200, 100),
		Vector2(400, 150),
		Vector2(600, 200),
		Vector2(300, 300),
		Vector2(500, 350)
	]
	
	for i in range(positions.size()):
		var test_obj = TestObject.new()
		test_obj.name = "TestObject_" + str(i + 1)
		test_obj.position = positions[i]
		add_child(test_obj)
		

func _input(event):
	# Дополнительные элементы управления для демо
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Перезагрузка сцены
				get_tree().reload_current_scene()
			KEY_ESCAPE:
				# Выход из игры
				get_tree().quit() 