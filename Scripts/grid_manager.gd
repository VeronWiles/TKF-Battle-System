class_name Grid
extends Node2D

const GRID_SQUARE_SIZE: int = 90

@export var grid_x_limit: int = 0
@export var grid_y_limit: int = 0
@export var place_mode: bool = false
@export var place_prefab: PackedScene
@export var movement_prefab: PackedScene
@export var unit_prefab: PackedScene
@export var big_unit_prefab: PackedScene
@export var huge_unit_prefab: PackedScene
@export var player_units_list: Array[Unit]
@export var enemy_units_list: Array[Unit]

var enemy_round: int = 0
var player_round: int = 0
var selected_unit: Unit
var selected_attack: Attack
var select_move_unit: Area2D
var place_tiles: Array[Area2D]
var placed_units_list: Array[Area2D]
var movement_tiles_list: Array[Node2D]
var delete_place_mode: bool = false
var player_place_mode: bool = true
var movement_mode: bool = false
var player_or_enemy: int = 0
var original_position: Vector2
var original_movement_left: int
var original_bonus_movement: int
var rot: int = 0
var spawn_attack
var attack_tiles: Array[Area2D]
var annie_list: Dictionary = {"Healing Vial":5, "Portable Shield":5, "Spring Trap":3, "Special Refresher":1}
var annie_list_used: Dictionary = {"Healing Vial":0, "Portable Shield":0, "Spring Trap":0, "Special Refresher":0}

func _process(_delta):
	if movement_mode:
		if Input.is_action_just_pressed("MoveUp") && !place_mode:
			CheckAndMove(0,-1)
		if Input.is_action_just_pressed("MoveDown") && !place_mode:
			CheckAndMove(0,1)
		if Input.is_action_just_pressed("MoveLeft") && !place_mode:
			CheckAndMove(-1,0)
		if Input.is_action_just_pressed("MoveRight") && !place_mode:
			CheckAndMove(1,0)

# General Actions

func ChangeMovementStat(num: int, length: int, unit: UnitTile):
	unit.movement_bonus += num
	unit.movement_bonus_length = length

func ChangeCurrentHealthStat(num: int, unit: UnitTile):
	if unit.current_health + num < 0:
		unit.current_health = 0
	elif unit.current_health + num > unit.max_health:
		unit.current_health = unit.max_health
	else:
		unit.current_health += num

func ChangeMaxHealthStat(num: int, length: int, unit: UnitTile):
	if unit.max_health_bonus + num <= -unit.max_health:
		unit.max_health_bonus = -unit.max_health+1
		unit.current_health = 1
	else:
		unit.max_health_bonus += num
		if unit.current_health + num < 1:
			unit.current_health = 1
		else:
			unit.current_health += num
	unit.max_health_bonus_length = length

func ChangeShieldStat(num: int, length: int, unit: UnitTile):
	if num > 0:
		unit.shield_length = length
	if unit.shield + num < 0:
		ChangeCurrentHealthStat(unit.shield + num, unit)
		unit.shield = 0
	elif unit.shield + num >= 99:
		unit.shield = 99
	else:
		unit.shield += num
	
	if unit.shield == 0:
		unit.shield_length = 0

func ChangeUnitPosition(x:int, y:int, unit: UnitTile):
	unit.position = Vector2(x*GRID_SQUARE_SIZE,y*GRID_SQUARE_SIZE)
	if unit == select_move_unit:
		original_position = select_move_unit.position

func ChangeAttackStat(num: int, length: int, unit: UnitTile):
	unit.changed_attack += num
	unit.changed_attack_length = length

func SetBleed(num: int, length: int, unit: UnitTile):
	unit.bleed = num
	unit.bleed_length = length

func SetTaunt(length: int, unit: UnitTile):
	unit.taunted = true
	unit.taunt_length = length
	unit.taunt_target = select_move_unit

func SetBrainwash(length: int, unit: UnitTile):
	unit.brainwashed = true
	unit.brainwashed_length = length

func SetStun(length: int, unit: UnitTile):
	unit.stun = true
	unit.stun_length = length

func RoundChange():
	if player_round == enemy_round:
		player_round += 1
		for u in placed_units_list:
			if u.stats.player:
				u.NewRound()
	else:
		enemy_round += 1
		for u in placed_units_list:
			if !u.stats.player:
				u.NewRound()

func WaveEnd():
	pass

# Unit Actions
## Movement
func CheckAndMove(x,y):
	var in_move_list: bool = false
	if select_move_unit == null:
		return
	var new_pos: Vector2 = Vector2(select_move_unit.position.x+(x*GRID_SQUARE_SIZE),select_move_unit.position.y+(y*GRID_SQUARE_SIZE))
	if select_move_unit.stats.is_big:
		if new_pos.x < 0 || new_pos.x > (grid_x_limit-2)*GRID_SQUARE_SIZE:
			return
		if new_pos.y < 0 || new_pos.y > (grid_y_limit-2)*GRID_SQUARE_SIZE:
			return
		for u in placed_units_list:
			if u.stats.is_big:
				if ((u.position.x+GRID_SQUARE_SIZE == new_pos.x && u.position.y == new_pos.y) || (u.position.x+GRID_SQUARE_SIZE == new_pos.x && u.position.y+GRID_SQUARE_SIZE == new_pos.y) || (u.position.x+GRID_SQUARE_SIZE == new_pos.x && u.position.y-GRID_SQUARE_SIZE == new_pos.y)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y+GRID_SQUARE_SIZE == new_pos.y) || (u.position.x-GRID_SQUARE_SIZE == new_pos.x && u.position.y+GRID_SQUARE_SIZE == new_pos.y)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			elif u.stats.is_huge:
				if ((u.position.x+(GRID_SQUARE_SIZE*2) == new_pos.x && u.position.y == new_pos.y) || (u.position.x+(GRID_SQUARE_SIZE*2) == new_pos.x && u.position.y+(GRID_SQUARE_SIZE*2) == new_pos.y) || (u.position.x+(GRID_SQUARE_SIZE*2) == new_pos.x && u.position.y-GRID_SQUARE_SIZE == new_pos.y) || (u.position.x+(GRID_SQUARE_SIZE*2) == new_pos.x && u.position.y+GRID_SQUARE_SIZE == new_pos.y)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y+(GRID_SQUARE_SIZE*2) == new_pos.y) || (u.position.x+GRID_SQUARE_SIZE == new_pos.x && u.position.y+(GRID_SQUARE_SIZE*2) == new_pos.y)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			else:
				if (u.position == new_pos || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x && u.position.y == new_pos.y+GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			
		for m in movement_tiles_list:
			if new_pos == m.position && m.position.x != select_move_unit.position.x+GRID_SQUARE_SIZE && m.position.y != select_move_unit.position.y+GRID_SQUARE_SIZE:
				in_move_list = true
			if (m.position.x == select_move_unit.position.x+(GRID_SQUARE_SIZE*2) && new_pos.x == select_move_unit.position.x+GRID_SQUARE_SIZE) || (m.position.y == select_move_unit.position.y+(GRID_SQUARE_SIZE*2) && new_pos.y == select_move_unit.position.y+GRID_SQUARE_SIZE):
				in_move_list = true
		if (!in_move_list):
			return
		else:
			in_move_list = false
	elif select_move_unit.stats.is_huge:
		if new_pos.x < 0 || new_pos.x > (grid_x_limit-3)*GRID_SQUARE_SIZE:
			return
		if new_pos.y < 0 || new_pos.y > (grid_y_limit-3)*GRID_SQUARE_SIZE:
			return
		for u in placed_units_list:
			if u.stats.is_big:
				if ((u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			elif u.stats.is_huge:
				if ((u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			else:
				if (u.position == new_pos || (u.position.x == new_pos.x && u.position.y == new_pos.y+GRID_SQUARE_SIZE)|| (u.position.x == new_pos.x && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+GRID_SQUARE_SIZE) || (u.position.x == new_pos.x+(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
				if ((u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x+GRID_SQUARE_SIZE && u.position.y == new_pos.y+(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			
		for m in movement_tiles_list:
			if new_pos == m.position && m.position.x != select_move_unit.position.x+GRID_SQUARE_SIZE && m.position.y != select_move_unit.position.y+GRID_SQUARE_SIZE:
				in_move_list = true
			if (m.position.x == select_move_unit.position.x+(GRID_SQUARE_SIZE*3) && new_pos.x == select_move_unit.position.x+GRID_SQUARE_SIZE) || (m.position.y == select_move_unit.position.y+(GRID_SQUARE_SIZE*3) && new_pos.y == select_move_unit.position.y+GRID_SQUARE_SIZE):
				in_move_list = true
		if (!in_move_list):
			return
		else:
			in_move_list = false
	else:
		if new_pos.x < 0 || new_pos.x > (grid_x_limit-1)*GRID_SQUARE_SIZE:
			return
		if new_pos.y < 0 || new_pos.y > (grid_y_limit-1)*GRID_SQUARE_SIZE:
			return
		for u in placed_units_list:
			if u.stats.is_big:
				if (u.position == new_pos || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y)) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			elif u.stats.is_huge:
				if (u.position == new_pos || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2)) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y) || (u.position.x == new_pos.x-(GRID_SQUARE_SIZE*2) && u.position.y == new_pos.y-GRID_SQUARE_SIZE) || (u.position.x == new_pos.x-GRID_SQUARE_SIZE && u.position.y == new_pos.y-(GRID_SQUARE_SIZE*2))) && !select_move_unit.stats.flight && u != select_move_unit:
					return
			if u.position == new_pos && !select_move_unit.stats.flight:
				return
		for m in movement_tiles_list:
			if new_pos == m.position:
				in_move_list = true
		if (!in_move_list):
			return
		else:
			in_move_list = false
			
	select_move_unit.position = new_pos
	if select_move_unit.movement_bonus > 0:
		select_move_unit.movement_bonus -= 1
	else:
		select_move_unit.movement_left -= 1
	ShowMovementTiles()

func RemoveMovementTiles():
	if movement_tiles_list.size() > 0:
		for m in movement_tiles_list:
			m.queue_free()
		movement_tiles_list.clear()

func ShowMovementTiles():
	RemoveMovementTiles()
	
	if !select_move_unit:
		return
	
	var pos:Vector2 = select_move_unit.position
	var final_pos: Vector2
	var unit_movement: int = select_move_unit.movement_left+select_move_unit.movement_bonus
	if select_move_unit.stats.is_big:
		for x in range(-unit_movement,unit_movement+2):
			for y in range(-unit_movement,unit_movement+2):
				var check_pos:Vector2 = Vector2(pos.x+(x*GRID_SQUARE_SIZE), pos.y+(y*GRID_SQUARE_SIZE))
				final_pos = check_pos
				if check_pos.x > pos.x:
					check_pos.x -= GRID_SQUARE_SIZE
				if check_pos.y > pos.y:
					check_pos.y -= GRID_SQUARE_SIZE
				if (pos.distance_to(check_pos)/GRID_SQUARE_SIZE) > unit_movement:
					continue
				else:
					if final_pos.x < 0 || final_pos.y < 0 || final_pos.x > GRID_SQUARE_SIZE*(grid_x_limit-1) || final_pos.y > GRID_SQUARE_SIZE*(grid_y_limit-1):
						continue
					var move_tile:Node2D = movement_prefab.instantiate()
					move_tile.position = final_pos
					add_child(move_tile)
					movement_tiles_list.append(move_tile)
	elif select_move_unit.stats.is_huge:
		for x in range(-unit_movement,unit_movement+3):
			for y in range(-unit_movement,unit_movement+3):
				var check_pos:Vector2 = Vector2(pos.x+(x*GRID_SQUARE_SIZE), pos.y+(y*GRID_SQUARE_SIZE))
				final_pos = check_pos
				if check_pos.x > pos.x && check_pos.x != pos.x+GRID_SQUARE_SIZE:
					check_pos.x -= GRID_SQUARE_SIZE*2
				elif check_pos.x > pos.x && check_pos.x == pos.x+GRID_SQUARE_SIZE:
					check_pos.x -= GRID_SQUARE_SIZE
				if check_pos.y > pos.y && check_pos.y != pos.y+GRID_SQUARE_SIZE:
					check_pos.y -= GRID_SQUARE_SIZE*2
				elif check_pos.y > pos.y && check_pos.y == pos.y+GRID_SQUARE_SIZE:
					check_pos.y -= GRID_SQUARE_SIZE
				if (pos.distance_to(check_pos)/GRID_SQUARE_SIZE) > unit_movement:
					continue
				else:
					if final_pos.x < 0 || final_pos.y < 0 || final_pos.x > GRID_SQUARE_SIZE*(grid_x_limit-1) || final_pos.y > GRID_SQUARE_SIZE*(grid_y_limit-1):
						continue
					var move_tile:Node2D = movement_prefab.instantiate()
					move_tile.position = final_pos
					add_child(move_tile)
					movement_tiles_list.append(move_tile)
	else:
		for x in range(-unit_movement,unit_movement+1):
			for y in range(-unit_movement,unit_movement+1):
				var check_pos:Vector2 = Vector2(pos.x+(x*GRID_SQUARE_SIZE), pos.y+(y*GRID_SQUARE_SIZE))
				if (pos.distance_to(check_pos)/GRID_SQUARE_SIZE) > unit_movement || check_pos.x < 0 || check_pos.y < 0 || check_pos.x > GRID_SQUARE_SIZE*(grid_x_limit-1) || check_pos.y > GRID_SQUARE_SIZE*(grid_y_limit-1):
					continue
				else:
					var move_tile:Node2D = movement_prefab.instantiate()
					move_tile.position = check_pos
					add_child(move_tile)
					movement_tiles_list.append(move_tile)

func ToggleMovementMode(toggle:bool):
	if !select_move_unit:
		get_parent().find_child("Battle Menu").find_child("Movement Toggle").button_pressed = false
		return
	
	CancelAttack()
	
	movement_mode = toggle
	
	if movement_mode:
		ShowMovementTiles()
	else:
		RemoveMovementTiles()

func ResetMovement():
	if !select_move_unit:
		return
		
	select_move_unit.position = original_position
	select_move_unit.movement_left = original_movement_left
	select_move_unit.movement_bonus = original_bonus_movement
	if movement_mode:
		ShowMovementTiles()

## Attacks
func ListAttacks():
	get_parent().find_child("Battle Menu").find_child("Attack Select").clear()
	get_parent().find_child("Battle Menu").find_child("Attack Options").visible = true
	for a:Attack in select_move_unit.stats.attacks:
		get_parent().find_child("Battle Menu").find_child("Attack Select").add_item(a.attack_name)

func UpdateAttackSelect(index: int):
	var attack_name: String = get_parent().find_child("Battle Menu").find_child("Attack Select").get_item_text(index)
	for a:Attack in select_move_unit.stats.attacks:
		if a.attack_name == attack_name:
			selected_attack = a

func ShowAttack():
	if !spawn_attack:
		spawn_attack = selected_attack.pattern.instantiate() 
		spawn_attack.position = select_move_unit.position
		spawn_attack.find_child("Pivot").rotation = rot*90
		add_child(spawn_attack)
		for tile in spawn_attack.find_child("Pivot").get_children():
			attack_tiles.append(tile)

func RotateAttack():
	if spawn_attack:
		rot += 1
		if rot >= 4:
			rot = 0
		spawn_attack.find_child("Pivot").rotation = deg_to_rad(rot*90)

func UseAttack():
	if spawn_attack:
		for at:AttackTile in attack_tiles:
			if at.overlapped_unit:
				if select_move_unit.stats.player && at.overlapped_unit.stats.player && selected_attack.heals && at.overlapped_unit != select_move_unit:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.heal > 0:
						ChangeCurrentHealthStat(selected_attack.heal, at.overlapped_unit)
					if selected_attack.movement_buff_length > 0:
						ChangeMovementStat(selected_attack.movement_buff,  selected_attack.movement_buff_length, at.overlapped_unit)
					if selected_attack.attack_buff_length > 0:
						ChangeAttackStat(selected_attack.attack_buff, selected_attack.attack_buff_length, at.overlapped_unit)
					if selected_attack.shield_length > 0:
						ChangeAttackStat(selected_attack.shield, selected_attack.shield_length, at.overlapped_unit)
				if select_move_unit.stats.player && !at.overlapped_unit.stats.player && selected_attack.damages:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.damage > 0:
						if at.overlapped_unit.shield > 0:
							if selected_attack.shield_pierce > 0:
								ChangeCurrentHealthStat(selected_attack.shield_pierce, at.overlapped_unit)
							ChangeShieldStat(selected_attack.damage, 0, at.overlapped_unit)
						else:
							ChangeCurrentHealthStat(selected_attack.damage, at.overlapped_unit)
					if selected_attack.bleed_length > 0:
						SetBleed(selected_attack.bleed, selected_attack.bleed_length, at.overlapped_unit)
					if selected_attack.movement_debuff_length > 0:
						ChangeMovementStat(selected_attack.movement_debuff, selected_attack.movement_debuff_length, at.overlapped_unit)
					if selected_attack.attack_debuff_length > 0:
						ChangeAttackStat(selected_attack.attack_debuff, selected_attack.attack_debuff_length, at.overlapped_unit)
					if selected_attack.stun_length > 0:
						SetStun(selected_attack.stun_length, at.overlapped_unit)
					if selected_attack.taunt_length > 0:
						SetStun(selected_attack.taunt_length, at.overlapped_unit)
					if selected_attack.brainwash_length > 0:
						SetStun(selected_attack.brainwash_length, at.overlapped_unit)
				if select_move_unit.stats.player && at.overlapped_unit.stats.player && selected_attack.affects_self && at.overlapped_unit == select_move_unit:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.heal > 0:
						ChangeCurrentHealthStat(selected_attack.heal, at.overlapped_unit)
					if selected_attack.movement_buff_length > 0:
						ChangeMovementStat(selected_attack.movement_buff,  selected_attack.movement_buff_length, at.overlapped_unit)
					if selected_attack.attack_buff_length > 0:
						ChangeAttackStat(selected_attack.attack_buff, selected_attack.attack_buff_length, at.overlapped_unit)
					if selected_attack.shield_length > 0:
						ChangeAttackStat(selected_attack.shield, selected_attack.shield_length, at.overlapped_unit)

				if !select_move_unit.stats.player && at.overlapped_unit.stats.player && selected_attack.damages:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.damage > 0:
						if at.overlapped_unit.shield > 0:
							if selected_attack.shield_pierce > 0:
								ChangeCurrentHealthStat(selected_attack.shield_pierce, at.overlapped_unit)
							ChangeShieldStat(selected_attack.damage, 0, at.overlapped_unit)
						else:
							ChangeCurrentHealthStat(selected_attack.damage, at.overlapped_unit)
					if selected_attack.bleed_length > 0:
						SetBleed(selected_attack.bleed, selected_attack.bleed_length, at.overlapped_unit)
					if selected_attack.movement_debuff_length > 0:
						ChangeMovementStat(selected_attack.movement_debuff, selected_attack.movement_debuff_length, at.overlapped_unit)
					if selected_attack.attack_debuff_length > 0:
						ChangeAttackStat(selected_attack.attack_debuff, selected_attack.attack_debuff_length, at.overlapped_unit)
					if selected_attack.stun_length > 0:
						SetStun(selected_attack.stun_length, at.overlapped_unit)
					if selected_attack.taunt_length > 0:
						SetStun(selected_attack.taunt_length, at.overlapped_unit)
					if selected_attack.brainwash_length > 0:
						SetStun(selected_attack.brainwash_length, at.overlapped_unit)
				if !select_move_unit.stats.player && !at.overlapped_unit.stats.player && selected_attack.heals && at.overlapped_unit != select_move_unit:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.heal > 0:
						ChangeCurrentHealthStat(selected_attack.heal, at.overlapped_unit)
					if selected_attack.movement_buff_length > 0:
						ChangeMovementStat(selected_attack.movement_buff,  selected_attack.movement_buff_length, at.overlapped_unit)
					if selected_attack.attack_buff_length > 0:
						ChangeAttackStat(selected_attack.attack_buff, selected_attack.attack_buff_length, at.overlapped_unit)
					if selected_attack.shield_length > 0:
						ChangeAttackStat(selected_attack.shield, selected_attack.shield_length, at.overlapped_unit)
				if !select_move_unit.stats.player && !at.overlapped_unit.stats.player && selected_attack.affects_self && at.overlapped_unit == select_move_unit:
					print("Affected ", at.overlapped_unit.stats.unit_name)
					if selected_attack.heal > 0:
						ChangeCurrentHealthStat(selected_attack.heal, at.overlapped_unit)
					if selected_attack.movement_buff_length > 0:
						ChangeMovementStat(selected_attack.movement_buff,  selected_attack.movement_buff_length, at.overlapped_unit)
					if selected_attack.attack_buff_length > 0:
						ChangeAttackStat(selected_attack.attack_buff, selected_attack.attack_buff_length, at.overlapped_unit)
					if selected_attack.shield_length > 0:
						ChangeAttackStat(selected_attack.shield, selected_attack.shield_length, at.overlapped_unit)

func CancelAttack():
	if spawn_attack:
		attack_tiles.clear()
		spawn_attack.queue_free()
		spawn_attack = null

## Unit Selection
func SetCurrentUnit(u: UnitTile):
	select_move_unit = u
	original_position = select_move_unit.position
	original_movement_left = select_move_unit.movement_left
	original_bonus_movement = select_move_unit.movement_bonus
	CancelAttack()
	ListAttacks()
	UpdateAttackSelect(0)

# Place Menu
## UI Management

func StartPlaceMode():
	if movement_mode:
		ToggleMovementMode(false)
	CancelAttack()
	get_parent().find_child("Battle Menu").find_child("Movement Toggle").button_pressed = false
	get_parent().find_child("Place Menu").visible = true
	for u in player_units_list:
		get_parent().find_child("Place Menu").find_child("Unit Select").add_item(u.unit_name)
	get_parent().find_child("Battle Menu").visible = false
	UpdateUnitSelect(0)
	place_mode = true
	select_move_unit = null
	for x in range(0,grid_x_limit):
		for y in range(0,grid_y_limit):
			var place_tile:Area2D = place_prefab.instantiate()
			place_tile.position.x = x*GRID_SQUARE_SIZE
			place_tile.position.y = y*GRID_SQUARE_SIZE
			place_tile.ChangeColor(place_tile.base_color)
			add_child(place_tile)
			place_tiles.append(place_tile)
	for place in place_tiles:
		for unit in placed_units_list:
			if unit.stats.is_big:
				if unit.position == place.position || (unit.position.x == place.position.x-GRID_SQUARE_SIZE && unit.position.y == place.position.y-GRID_SQUARE_SIZE) || (unit.position.x == place.position.x && unit.position.y == place.position.y-GRID_SQUARE_SIZE) || (unit.position.x == place.position.x-GRID_SQUARE_SIZE && unit.position.y == place.position.y):
					place.placed = true
					place.ChangeColor(place.unselectable_color)
			elif unit.stats.is_huge:
				if unit.position == place.position || (unit.position.x == place.position.x-GRID_SQUARE_SIZE && unit.position.y == place.position.y-GRID_SQUARE_SIZE) || (unit.position.x == place.position.x && unit.position.y == place.position.y-GRID_SQUARE_SIZE) || (unit.position.x == place.position.x-GRID_SQUARE_SIZE && unit.position.y == place.position.y) || (unit.position.x == place.position.x-(GRID_SQUARE_SIZE*2) && unit.position.y == place.position.y-(GRID_SQUARE_SIZE*2)) || (unit.position.x == place.position.x && unit.position.y == place.position.y-(GRID_SQUARE_SIZE*2)) || (unit.position.x == place.position.x-(GRID_SQUARE_SIZE*2) && unit.position.y == place.position.y) || (unit.position.x == place.position.x-(GRID_SQUARE_SIZE*2) && unit.position.y == place.position.y-GRID_SQUARE_SIZE) || (unit.position.x == place.position.x-GRID_SQUARE_SIZE && unit.position.y == place.position.y-(GRID_SQUARE_SIZE*2)):
					place.placed = true
					place.ChangeColor(place.unselectable_color)
			elif unit.position == place.position:
				place.placed = true
				place.ChangeColor(place.unselectable_color)

func ToggleDeletePlaceMode(toggle: bool):
	delete_place_mode = toggle
	
	if place_tiles.size() > 0:
		for place in place_tiles:
			if delete_place_mode:
				place.delete = true
				place.ChangeColor(place.delete_color)
			else:
				place.delete = false
				place.self_modulate = Color.WHITE
				if place.placed:
					place.ChangeColor(place.unselectable_color)
				else:
					place.ChangeColor(place.base_color)

func EndPlaceMode():
	get_parent().find_child("Place Menu").visible = false
	get_parent().find_child("Place Menu").find_child("Delete Toggle").button_pressed = false
	get_parent().find_child("Place Menu").find_child("Unit Select").clear()
	get_parent().find_child("Battle Menu").visible = true
	for i in place_tiles:
		i.queue_free()
	place_tiles = []
	delete_place_mode = false
	player_place_mode = true
	place_mode = false
	player_or_enemy = 0

## Unit Manegement

func SpawnUnit(pos, tile):
	var big_array = []
	var huge_array = []
	if selected_unit.is_big:
		for check_tile in place_tiles:
			if check_tile.position == pos || (check_tile.position.x == pos.x+GRID_SQUARE_SIZE && check_tile.position.y == pos.y+GRID_SQUARE_SIZE) || (check_tile.position.x == pos.x && check_tile.position.y == pos.y+GRID_SQUARE_SIZE) || (check_tile.position.x == pos.x+GRID_SQUARE_SIZE && check_tile.position.y == pos.y):
				if check_tile.placed:
					return
				else:
					big_array.append(check_tile)
		if big_array.size() < 4:
			return
		for spawn_tile in big_array:
			spawn_tile.ChangeColor(spawn_tile.unselectable_color)
			spawn_tile.placed = true
	elif selected_unit.is_huge:
		for check_tile in place_tiles:
			if check_tile.position == pos || (check_tile.position.x == pos.x+GRID_SQUARE_SIZE && check_tile.position.y == pos.y+GRID_SQUARE_SIZE) || (check_tile.position.x == pos.x && check_tile.position.y == pos.y+GRID_SQUARE_SIZE) || (check_tile.position.x == pos.x+GRID_SQUARE_SIZE && check_tile.position.y == pos.y) || (check_tile.position.x == pos.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == pos.y+(GRID_SQUARE_SIZE*2)) || (check_tile.position.x == pos.x && check_tile.position.y == pos.y+(GRID_SQUARE_SIZE*2)) || (check_tile.position.x == pos.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == pos.y) || (check_tile.position.x == pos.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == pos.y+GRID_SQUARE_SIZE) || (check_tile.position.x == pos.x+GRID_SQUARE_SIZE && check_tile.position.y == pos.y+(GRID_SQUARE_SIZE*2)):
				if check_tile.placed || check_tile.position.x >= GRID_SQUARE_SIZE*grid_x_limit || check_tile.position.y >= GRID_SQUARE_SIZE*grid_y_limit:
					return
				else:
					huge_array.append(check_tile)
		if huge_array.size() < 9:
			return
		for spawn_tile in huge_array:
			spawn_tile.ChangeColor(spawn_tile.unselectable_color)
			spawn_tile.placed = true
	else:
		tile.ChangeColor(tile.unselectable_color)
		tile.placed = true
	var player_tile:Area2D
	if selected_unit.is_big:
		player_tile = big_unit_prefab.instantiate()
	elif selected_unit.is_huge:
		player_tile = huge_unit_prefab.instantiate()
	else:
		player_tile = unit_prefab.instantiate()
	player_tile.position = pos
	player_tile.stats = selected_unit
	var id: int = 0
	for u in placed_units_list:
		if u.stats.unit_name == player_tile.stats.unit_name:
			id += 1
	player_tile.unit_id = id
	player_tile.find_child("Sprite2D").texture = selected_unit.picture
	add_child(player_tile)
	placed_units_list.append(player_tile)
	if id > 0:
		print("Placed ", player_tile.stats.unit_name, " ", char(65+id), " at ", (int(pos.x/GRID_SQUARE_SIZE)+1), ",", char(65+int(pos.y/GRID_SQUARE_SIZE)), ".")
	else:
		print("Placed ", player_tile.stats.unit_name, " at ", (int(pos.x/GRID_SQUARE_SIZE)+1), ",", char(65+int(pos.y/GRID_SQUARE_SIZE)), ".")

func RemoveUnit(pos, tile):
	var big_array = []
	var huge_array = []
	var select_unit: Area2D = null
	for unit in placed_units_list:
		if unit.stats.is_big:
			if unit.position == pos || (unit.position.x == pos.x-GRID_SQUARE_SIZE && unit.position.y == pos.y-GRID_SQUARE_SIZE) || (unit.position.x == pos.x && unit.position.y == pos.y-GRID_SQUARE_SIZE) || (unit.position.x == pos.x-GRID_SQUARE_SIZE && unit.position.y == pos.y):
				select_unit = unit
		elif unit.stats.is_huge:
			if unit.position == pos || (unit.position.x == pos.x-GRID_SQUARE_SIZE && unit.position.y == pos.y-GRID_SQUARE_SIZE) || (unit.position.x == pos.x && unit.position.y == pos.y-GRID_SQUARE_SIZE) || (unit.position.x == pos.x-GRID_SQUARE_SIZE && unit.position.y == pos.y) || (unit.position.x == pos.x-(GRID_SQUARE_SIZE*2) && unit.position.y == pos.y-(GRID_SQUARE_SIZE*2)) || (unit.position.x == pos.x && unit.position.y == pos.y-(GRID_SQUARE_SIZE*2)) || (unit.position.x == pos.x-(GRID_SQUARE_SIZE*2) && unit.position.y == pos.y) || (unit.position.x == pos.x-(GRID_SQUARE_SIZE*2) && unit.position.y == pos.y-GRID_SQUARE_SIZE) || (unit.position.x == pos.x && unit.position.y-GRID_SQUARE_SIZE == pos.y-(GRID_SQUARE_SIZE*2)):
				select_unit = unit
		else:
			if unit.position == pos:
				select_unit = unit
	
	if select_unit.stats.is_big:
		for check_tile in place_tiles:
			if check_tile.position == select_unit.position || (check_tile.position.x == select_unit.position.x+GRID_SQUARE_SIZE && check_tile.position.y == select_unit.position.y+GRID_SQUARE_SIZE) || (check_tile.position.x == select_unit.position.x && check_tile.position.y == select_unit.position.y+GRID_SQUARE_SIZE) || (check_tile.position.x == select_unit.position.x+GRID_SQUARE_SIZE && check_tile.position.y == select_unit.position.y):
					big_array.append(check_tile)
		for delete_tile in big_array:
			delete_tile.placed = false
	elif select_unit.stats.is_huge:
		for check_tile in place_tiles:
			if check_tile.position == select_unit.position || (check_tile.position.x == select_unit.position.x+GRID_SQUARE_SIZE && check_tile.position.y == select_unit.position.y+GRID_SQUARE_SIZE) || (check_tile.position.x == select_unit.position.x && check_tile.position.y == select_unit.position.y+GRID_SQUARE_SIZE) || (check_tile.position.x == select_unit.position.x+GRID_SQUARE_SIZE && check_tile.position.y == select_unit.position.y) || (check_tile.position.x == select_unit.position.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == select_unit.position.y+(GRID_SQUARE_SIZE*2)) || (check_tile.position.x == select_unit.position.x && check_tile.position.y == select_unit.position.y+(GRID_SQUARE_SIZE*2)) || (check_tile.position.x == select_unit.position.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == select_unit.position.y) || (check_tile.position.x == select_unit.position.x+(GRID_SQUARE_SIZE*2) && check_tile.position.y == select_unit.position.y+GRID_SQUARE_SIZE) || (check_tile.position.x == select_unit.position.x+GRID_SQUARE_SIZE && check_tile.position.y == select_unit.position.y+(GRID_SQUARE_SIZE*2)):
					huge_array.append(check_tile)
		for delete_tile in huge_array:
			delete_tile.placed = false
	else:
		tile.placed = false
	
	if select_unit != null:
		select_unit.queue_free()
		placed_units_list.erase(select_unit)

func UpdateUnitSelect(index: int):
	var unit_name: String = get_parent().find_child("Place Menu").find_child("Unit Select").get_item_text(index)
	match player_or_enemy:
		0:
			for u in player_units_list:
				if u.unit_name == unit_name:
					get_parent().find_child("Place Menu").find_child("Unit Picture Select").texture = u.picture
					selected_unit = u
		1:
			for u in enemy_units_list:
				if u.unit_name == unit_name:
					get_parent().find_child("Place Menu").find_child("Unit Picture Select").texture = u.picture
					selected_unit = u

func SwitchUnitType():
	get_parent().find_child("Place Menu").find_child("Unit Select").clear()
	if !player_place_mode:
		for u in player_units_list:
			get_parent().find_child("Place Menu").find_child("Unit Select").add_item(u.unit_name)
		player_or_enemy = 0
		UpdateUnitSelect(0)
		player_place_mode = true
	else:
		for u in enemy_units_list:
			get_parent().find_child("Place Menu").find_child("Unit Select").add_item(u.unit_name)
		player_or_enemy = 1
		UpdateUnitSelect(0)
		player_place_mode = false

# Gimmicks
## Gimmicks Setup

func ResetGimmicks():
	get_parent().find_child("Battle Menu").find_child("Annie Options").visible = false

func SetGimmick(gim: GimmicksList):
	match gim:
		GimmicksList.NONE:
			pass
		GimmicksList.ANNIE:
			get_parent().find_child("Battle Menu").find_child("Annie Options").visible = true

## Gimmicks Enum
enum GimmicksList {
	NONE,
	ANNIE
}
