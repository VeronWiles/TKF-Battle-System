class_name UnitTile
extends Area2D

var stats: Unit
var grid: Grid
var unit_id: int = 0
var movement_left: int
var movement_bonus: int
var movement_bonus_length: int
var current_health: int
var max_health: int
var max_health_bonus: int
var max_health_bonus_length: int
var shield: int
var shield_length: int
var has_shield: bool = false
var changed_attack: int
var changed_attack_length: int
var has_special: bool = true
var attacks_left: int
var taunted: bool = false
var taunt_length: int
var taunt_target: Area2D
var brainwashed: bool = false
var brainwashed_length: int
var bleed: int
var bleed_length: int
var stun: bool = false
var stun_length: int

func _ready():
	movement_left = stats.movement
	max_health = stats.health
	current_health = max_health
	attacks_left = stats.attacks_count
	grid = get_parent()
	
func NewRound():
	if stun:
		attacks_left = 0
		movement_left = 0
	else:
		CheckAzu()
		attacks_left = stats.attacks_count
		movement_left = stats.movement
	
	if movement_bonus_length > 0:
		movement_bonus_length -= 1
		if movement_bonus_length == 0:
			movement_bonus = 0
	if max_health_bonus_length > 0:
		max_health_bonus_length -= 1
		if max_health_bonus_length == 0:
			current_health -= max_health_bonus
			if current_health < 1:
				current_health = 1
			max_health_bonus = 0
	if shield_length > 0:
		shield_length -= 1
		if shield_length == 0:
			shield = 0
	if changed_attack_length > 0:
		changed_attack_length -= 1
		if changed_attack_length == 0:
			changed_attack = 0
	if taunt_length > 0:
		taunt_length -= 1
		if taunt_length == 0:
			taunted = false
			taunt_target = null
	if brainwashed_length > 0:
		brainwashed_length -= 1
		if brainwashed_length == 0:
			brainwashed = false
	if bleed_length > 0:
		bleed_length -= 1
		grid.ChangeCurrentHealthStat(bleed, self)
		if bleed_length == 0:
			bleed = 0
	if stun_length > 0:
		stun_length -= 1
		if stun_length == 0:
			stun = false
	

func UnitTileClicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !grid.place_mode && !stun:
			grid.SetCurrentUnit(self)
		if grid.movement_mode && !stun:
			grid.ToggleMovementMode(false)

func CheckAzu():
	if stats.gimmick == Grid.GimmicksList.AZU:
		if movement_left == stats.movement:
			grid.azu_move = false
			grid.ChangeMovementStat(5, 1, self)
		else:
			grid.azu_move = true
			grid.ChangeMovementStat(0, 0, self)
