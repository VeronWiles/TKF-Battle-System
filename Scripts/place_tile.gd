class_name PlaceTile
extends Area2D

@export var base_color: Color
@export var unselectable_color: Color
@export var delete_color: Color
var grid: Grid
var placed: bool = false
var delete: bool = false

func _ready():
	grid = get_parent()

func ChangeColor(new_color: Color):
	find_child("ColorRect").color = new_color

func PlaceTileClicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !placed && !delete:
			grid.SpawnUnit(position, self)
		if delete && placed:
			grid.RemoveUnit(position, self)
