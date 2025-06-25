# Система конфигурации коллизий

## Описание

Централизованная система управления слоями коллизий для проекта Blasteroids. Все константы слоев и масок коллизий теперь находятся в одном месте для удобства управления и предотвращения ошибок.

## Файлы

- `collision_layers.gd` - Основной файл конфигурации со всеми константами
- `collision_example.gd` - Примеры использования новой системы
- `README.md` - Данная документация

## Основные компоненты

### Слои коллизий (collision_layer)

Определяют, на каком слое находится объект:

```gdscript
const ENEMIES: int = 1          # Слой 1 - Живые враги
const PLAYER_LASERS: int = 2    # Слой 2 - Лазеры игрока
const PLAYER: int = 4           # Слой 3 - Игрок
const ENEMY_LASERS: int = 8     # Слой 4 - Лазеры врагов
const LOOT_AREA: int = 16       # Слой 5 - Область лута
const WRECKAGE: int = 32        # Слой 6 - Обломки кораблей
```

### Маски коллизий (collision_mask)

Определяют, с какими слоями может сталкиваться объект:

```gdscript
# Игрок может сталкиваться с врагами, их лазерами, препятствиями и подбираемыми предметами
PlayerMasks.BASIC = ENEMIES + ENEMY_LASERS + OBSTACLES + PICKUPS

# Лазеры игрока попадают по врагам, препятствиям и обломкам
LaserMasks.PLAYER_LASERS = ENEMIES + OBSTACLES + WRECKAGE
```

### Предустановленные конфигурации

Готовые настройки для быстрого применения:

```gdscript
# Конфигурация для игрока
PresetConfigs.Player.LAYER = PLAYER
PresetConfigs.Player.MASK = PlayerMasks.BASIC

# Конфигурация для врага
PresetConfigs.Enemy.LAYER = ENEMIES
PresetConfigs.Enemy.MASK = EnemyMasks.BASIC
```

## Использование

### Импорт конфигурации

```gdscript
# В начале скрипта
const Layers = preload("res://Scripts/config/collision_layers.gd")
```

### Базовая настройка коллизий

```gdscript
# Старый способ (НЕ используйте):
enemy.collision_layer = 1
enemy.collision_mask = 2 + 64

# Новый способ (рекомендуется):
enemy.collision_layer = Layers.ENEMIES
enemy.collision_mask = Layers.EnemyMasks.BASIC

# Или используя предустановки:
enemy.collision_layer = Layers.PresetConfigs.Enemy.LAYER
enemy.collision_mask = Layers.PresetConfigs.Enemy.MASK
```

### Динамическое изменение коллизий

```gdscript
# Добавить слой к маске
enemy.collision_mask = Layers.add_layer_to_mask(
    enemy.collision_mask,
    Layers.PLAYER
)

# Убрать слой из маски
enemy.collision_mask = Layers.remove_layer_from_mask(
    enemy.collision_mask,
    Layers.OBSTACLES
)
```

### Отладка коллизий

```gdscript
# Проверить, может ли объект сталкиваться с определенным слоем
if Layers.can_collide_with(object.collision_mask, Layers.ENEMIES):
    print("Может сталкиваться с врагами")

# Получить список всех активных слоев в маске
var active_layers = Layers.get_active_layers_in_mask(object.collision_mask)
print("Активные слои: ", active_layers)

# Получить название слоя
print("Название слоя: ", Layers.get_layer_name(Layers.ENEMIES))
```

## Утилитарные функции

### Проверка слоев

- `is_on_layer(collision_layer, target_layer)` - Проверяет, находится ли объект на определенном слое
- `can_collide_with(collision_mask, target_layer)` - Проверяет, может ли объект сталкиваться с определенным слоем

### Модификация масок

- `add_layer_to_mask(current_mask, layer_to_add)` - Добавляет слой к маске
- `remove_layer_from_mask(current_mask, layer_to_remove)` - Убирает слой из маски

### Отладка

- `get_layer_name(layer)` - Возвращает человекочитаемое название слоя
- `get_active_layers_in_mask(mask)` - Возвращает список всех активных слоев в маске

## Миграция существующего кода

### До (старый способ):

```gdscript
# В RocketShip
ship_collision_layer = 1
laser_collision_mask = 1 + 4 + 32

# В EnemyShip
ship_collision_layer = 1
laser_collision_layer = 8
laser_collision_mask = 4

# В LaserProjectile
collision_layer = 2
collision_mask = 1 + 4 + 32
```

### После (новый способ):

```gdscript
# В RocketShip
ship_collision_layer = Layers.ENEMIES
laser_collision_mask = Layers.LaserMasks.PLAYER_LASERS

# В EnemyShip
ship_collision_layer = Layers.ENEMIES
laser_collision_layer = Layers.ENEMY_LASERS
laser_collision_mask = Layers.LaserMasks.ENEMY_LASERS

# В LaserProjectile
collision_layer = Layers.PLAYER_LASERS
collision_mask = Layers.LaserMasks.PLAYER_LASERS
```

## Преимущества новой системы

1. **Централизованное управление** - Все слои в одном месте
2. **Читаемость кода** - Понятные имена вместо чисел
3. **Предотвращение ошибок** - Меньше шансов перепутать числа
4. **Легкость изменений** - Изменения в одном месте влияют на весь проект
5. **Отладка** - Утилиты для проверки и отображения коллизий
6. **Документация** - Встроенные комментарии и описания

## Слои коллизий в проекте

| Слой | Значение | Назначение           | Описание                        |
| ---- | -------- | -------------------- | ------------------------------- |
| 1    | 1        | Враги                | Живые вражеские корабли         |
| 2    | 2        | Лазеры игрока        | Снаряды игрока                  |
| 3    | 4        | Игрок                | Основной персонаж               |
| 4    | 8        | Лазеры врагов        | Снаряды врагов                  |
| 5    | 16       | Область лута         | Зоны взаимодействия с обломками |
| 6    | 32       | Обломки              | Остатки уничтоженных кораблей   |
| 7    | 64       | Препятствия          | Статичные объекты окружения     |
| 8    | 128      | Подбираемые предметы | Бонусы и улучшения              |
| 9    | 256      | Окружение            | Декоративные элементы           |
| 10   | 512      | Эффекты              | Визуальные эффекты с коллизиями |

## Рекомендации

1. **Всегда используйте константы** вместо жестко заданных чисел
2. **Импортируйте конфиг** в начале каждого скрипта, работающего с коллизиями
3. **Используйте предустановки** для стандартных объектов
4. **Применяйте утилиты** для динамического изменения коллизий
5. **Документируйте изменения** при добавлении новых слоев
