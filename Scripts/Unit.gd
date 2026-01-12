class_name Unit
extends Resource

@export var unit_name: String
@export var health: int
@export var movement: int
@export var picture: Texture2D
@export var is_big: bool
@export var is_huge: bool
@export var flight: bool
@export var player: bool
@export var attacks_count: int = 1
@export var attacks: Array[Attack]
@export var gimmick: Grid.GimmicksList
