@tool

extends Node2D

@export var color: Color:
	get:
		return modulate
	set(value):
		modulate = value
