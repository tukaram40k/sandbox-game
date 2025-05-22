extends Area2D

signal final_zone_activated

@export var required_zones_count: int = 3  # Сколько зон нужно пройти

var ready_to_craft: bool = false

func _ready() -> void:
	print("Финальная зона инициализирована")
	
	# Проверяем свойство monitoring для отладки
	print("Финальная зона monitoring:", monitoring)
	
	# Подключаем сигнал входа тела
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)
		print("Сигнал body_entered подключен")
	else:
		print("Сигнал body_entered уже был подключен")

# Функция для ручного тестирования из редактора
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and ready_to_craft:
		$"../Gorgon/AnimatedSprite2D".visible = true

func _on_body_entered(body: Node) -> void:
	print("Что-то вошло в финальную зону:", body.name)
	
	if body.name == "Player":
		print("Игрок вошел в финальную зону")
		
		var game_manager = get_node_or_null("/root/GameWorld")
		if game_manager:
			print("GameManager найден, запрашиваю количество активированных зон")
			var zones_completed = game_manager.get_completed_zones_count()
			print("Активировано зон:", zones_completed, "из", required_zones_count)
			
			if zones_completed >= required_zones_count:
				print("Условие выполнено! Активирую финальную зону")
				activate_final_zone()
			else:
				print("Условие НЕ выполнено")
				show_requirements_message(zones_completed)
		else:
			# Попытаемся получить GameManager через синглтон
			if Engine.has_singleton("GameManager"):
				var singleton_manager = Engine.get_singleton("GameWorld")
				var zones_completed = singleton_manager.get_completed_zones_count()
				print("Активировано зон (через синглтон):", zones_completed, "из", required_zones_count)
				
				if zones_completed >= required_zones_count:
					print("Условие выполнено! Активирую финальную зону")
					activate_final_zone()
				else:
					print("Условие НЕ выполнено")
					show_requirements_message(zones_completed)
			else:
				print("ОШИБКА: GameManager не найден нигде!")

func activate_final_zone() -> void:
	print("Финальная зона активирована!")
	ready_to_craft = true
	
	# Ден хуярь свою часть сюда
	# Если сделаешь хуево то этот минотавр выебет тебя в очко
	
	emit_signal("final_zone_activated")
	
	set_deferred("monitoring", false)

func show_requirements_message(completed: int) -> void:
	print("Нужно пройти еще ", required_zones_count - completed, " зон!")
