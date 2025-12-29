class_name AttackTile
extends Area2D

var overlapped_unit: Area2D

func OverlapsUnit(area:Area2D):
	if area.is_in_group("Unit"):
		overlapped_unit = area
