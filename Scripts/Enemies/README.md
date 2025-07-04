# Система кораблей

## Описание

Модульная система кораблей для игры Blasteroids с базовым классом `RocketShip` и специализированными наследниками.

## Архитектура

### RocketShip (Scripts/Ships/rocket_ship.gd)

Базовый класс для всех кораблей в игре.

**Основные системы:**

- Движение с использованием `CommonMovementSystem`
- Стрельба лазерами с настраиваемыми параметрами
- Система дыма при движении
- Система здоровья и получения урона
- Визуальные эффекты (урон, уничтожение)

**Настраиваемые параметры:**

- `max_health`: Максимальное здоровье
- `max_speed`: Максимальная скорость
- `acceleration`: Ускорение
- `friction`: Трение
- `laser_damage`: Урон лазера
- `fire_rate`: Скорострельность
- `muzzle_offset`: Смещение точки выстрела
- `rotation_speed`: Скорость поворота корабля (по умолчанию 5.0)

### EnemyShip (Scripts/Enemies/enemy_ship.gd)

Корабль-враг с ИИ, наследуется от `RocketShip`.

**Особенности:**

- 4 состояния поведения: орбитальное движение, преследование, атака, бегство
- Интеллектуальное поведение в зависимости от расстояния до игрока
- Настраиваемая точность стрельбы
- Оранжевые лазеры для отличия от игрока

**Дополнительные параметры:**

- `detection_range`: Дальность обнаружения игрока
- `attack_range`: Дальность атаки
- `flee_range`: Дистанция убегания
- `orbit_radius`: Радиус орбитального движения
- `aim_accuracy`: Точность прицеливания (0-1)

## Использование

### Создание базового корабля

```gdscript
# Создание простого корабля
var ship = RocketShip.new()
ship.max_health = 50.0
ship.max_speed = 400.0
ship.laser_damage = 20.0
```

### Создание врага

```gdscript
# Создание врага с ИИ
var enemy = EnemyShip.new()
enemy.detection_range = 500.0
enemy.attack_range = 350.0
enemy.aim_accuracy = 0.8
```

### Использование спавнера

1. Создайте Node2D узел в вашей сцене
2. Добавьте к нему скрипт `enemy_ship_spawner.gd`
3. Настройте параметры в инспекторе:
   - `max_enemies`: Максимальное количество врагов
   - `spawn_interval`: Интервал между спавнами
   - `spawn_distance_min`: Минимальная дистанция спавна от игрока
   - `spawn_distance_max`: Максимальная дистанция спавна от игрока
   - `screen_margin`: Отступ за пределы экрана

**Особенности спавна:**

- Враги появляются за пределами экрана (с учетом камеры)
- Спавн происходит на одной из 4 сторон экрана (верх, право, низ, лево)
- Учитывается минимальная и максимальная дистанция от игрока
- Автоматически определяется размер экрана и позиция камеры
- Используется готовая сцена `rocket.tscn` для отображения врагов

**Система обломков:**

- При уничтожении враги не удаляются, а превращаются в обломки
- Текстура меняется на `Rocket-ship-destroyed.png`
- Обломки имеют коллизию с пулями и крюком (слой 32)
- Обломки остаются на поле в течение `wreckage_lifetime` секунд (по умолчанию 30)
- Повторное попадание пули в обломки заставляет их исчезнуть
- Затем плавно исчезают в течение 1.5-2 секунд
- Обломки не могут двигаться или стрелять

**Система лута:**

- У каждого корабля есть параметр `is_looted = false`
- Обломки имеют область взаимодействия (Area2D) для обнаружения игрока
- Когда игрок касается обломков, они становятся разграбленными (`is_looted = true`)
- Разграбленные обломки дополнительно затемняются (в 2 раза)
- Разграбленные обломки исчезают быстрее (1 секунда вместо 2)
- Спавнер отслеживает количество разграбленных кораблей

## Переопределяемые методы

### В наследниках RocketShip можно переопределить:

- `get_projectile_layer_name()`: Имя слоя для снарядов
- `configure_laser_appearance(laser)`: Внешний вид лазеров
- `get_destruction_color()`: Цвет эффекта уничтожения
- `on_ship_destroyed()`: Действия при уничтожении

### Пример переопределения:

```gdscript
func configure_laser_appearance(laser: LaserProjectile):
    laser.modulate = Color.GREEN  # Зеленые лазеры
    laser.scale = Vector2(1.5, 1.5)  # Увеличенный размер
```

## Слои коллизий

- **Слой 1 (значение 1)**: Враги
- **Слой 2 (значение 2)**: Лазеры игрока
- **Слой 3 (значение 4)**: Игрок
- **Слой 4 (значение 8)**: Лазеры врагов
- **Слой 5 (значение 16)**: Область лута (взаимодействие с игроком)
- **Слой 6 (значение 32)**: Обломки кораблей (взаимодействие с пулями и крюком)

## Состояния ИИ врагов

1. **ORBITING**: Движется по орбите вокруг заданной точки
2. **PURSUING**: Преследует игрока при обнаружении
3. **ATTACKING**: Атакует игрока лазерами, двигаясь по кругу
4. **FLEEING**: Убегает, если игрок подошел слишком близко

## API базового класса RocketShip

### Управление движением

- `set_target_velocity(velocity: Vector2)`: Установить целевую скорость
- `get_current_speed()`: Получить текущую скорость
- `get_ship_velocity()`: Получить вектор скорости

### Управление стрельбой

- `attempt_fire(direction: Vector2)`: Попытка выстрелить
- `can_shoot()`: Проверить возможность стрельбы
- `get_fire_cooldown_remaining()`: Время до следующего выстрела

### Управление здоровьем

- `take_damage(damage: float)`: Получить урон
- `heal(amount: float)`: Восстановить здоровье
- `is_alive()`: Проверить, жив ли корабль
- `get_health_ratio()`: Получить отношение здоровья

### Управление эффектами

- `enable_smoke(enabled: bool)`: Включить/выключить дым
- `clear_smoke()`: Очистить частицы дыма

### Управление лутом

- `is_wreckage_looted()`: Проверить, разграблены ли обломки
- `can_be_looted()`: Проверить возможность разграбления
- `force_loot()`: Принудительно разграбить обломки
- `set_loot_collision_layers(layer, mask)`: Настроить коллизии лута
- `on_wreckage_looted()`: Переопределяемый метод при разграблении

### API спавнера

- `get_looted_ships_count()`: Количество разграбленных кораблей
- `reset_loot_counter()`: Сбросить счетчик лута
- `get_active_wreckage_count()`: Количество активных обломков на поле

## Преимущества новой архитектуры

1. **Переиспользование кода**: Общая логика в базовом классе
2. **Легкость расширения**: Простое создание новых типов кораблей
3. **Единообразие**: Все корабли работают одинаково
4. **Модульность**: Четкое разделение базовой логики и специализации
5. **Совместимость**: Поддержка существующего кода
