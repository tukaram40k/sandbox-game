extends Area2D

# Экспортируемая переменная для удобной настройки в редакторе
@export var zone_name: String = "Zone1"  # Уникальное имя зоны
var is_activated = false

func _ready() -> void:
	# Подключаем сигнал входа тела
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Проверяем что вошёл игрок и зона ещё не активирована
	if body.name == "Player" and not is_activated:
		is_activated = true
		print("Активирована зона:", zone_name)
		
		# Сообщаем GameManager об активации
		if Engine.has_singleton("GameWorld"):
			var game_manager = Engine.get_singleton("GameWorld")
			game_manager.register_zone_activation(zone_name)
		else:
			# Попытка получить через глобальный путь автозагрузки
			var game_manager = get_node_or_null("/root/GameWorld")
			if game_manager:
				game_manager.register_zone_activation(zone_name)
			else:
				print("ОШИБКА: GameManager не найден в зоне", zone_name)
		
		# невидимый спрайт
		$TailPartSprite.visible = false
		
		# Отключаем коллизию
		set_deferred("monitoring", false)
