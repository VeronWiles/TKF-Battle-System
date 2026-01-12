class_name Attack
extends Resource

@export_category("Basic Info")
@export var attack_name: String
@export var pattern: PackedScene
@export var damages: bool
@export var heals: bool
@export var affects_self: bool
@export var is_special: bool

@export_category("Damaging")
@export var damage: int
@export var bleed: int
@export var bleed_length: int
@export var movement_debuff: int
@export var movement_debuff_length: int
@export var shield_pierce: int
@export var attack_debuff: int
@export var attack_debuff_length: int
@export var stun_length: int
@export var taunt_length: int
@export var brainwash_length: int

@export_category("Healing")
@export var heal: int
@export var movement_buff: int
@export var movement_buff_length: int
@export var attack_buff: int
@export var attack_buff_length: int
@export var shield: int
@export var shield_length: int

@export_category("Other")
@export var displacement: int
