extends Node2D

@onready var blue: Sprite2D = $Blue
@export var blueSpeed: float = 1
@export var blueFlipSpeed: float = 0.01
var blueFlipped = [false] #<- leave these as arrays for the function to work

@onready var yellow: Sprite2D = $Yellow
@export var yellowSpeed: float = 1
@export var yellowFlipSpeed: float = 0.01
var yellowFlipped = [false]

@onready var green: Sprite2D = $Green
@export var greenSpeed: float = 1
@export var greenFlipSpeed: float = 0.01
var greenFlipped = [false]

@onready var pink: Sprite2D = $Pink
@export var pinkSpeed: float = 1
@export var pinkFlipSpeed: float = 0.01
var pinkFlipped = [false]

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D



@export var rotationSpeedConstant: float = 0.01
@export var flipSpeedConstant: float = 1

func _ready() -> void:
	blueSpeed = blueSpeed * rotationSpeedConstant
	yellowSpeed = yellowSpeed * rotationSpeedConstant
	greenSpeed = greenSpeed * rotationSpeedConstant
	pinkSpeed = pinkSpeed * rotationSpeedConstant

func _physics_process(delta: float) -> void:
	blue.rotate(blueSpeed)
	yellow.rotate(yellowSpeed)
	green.rotate(greenSpeed)
	pink.rotate(pinkSpeed)
	
	shiftSize(blue, blueFlipped, blueFlipSpeed)
	shiftSize(yellow, yellowFlipped, yellowFlipSpeed)
	shiftSize(green, greenFlipped, greenFlipSpeed)
	shiftSize(pink, pinkFlipped, pinkFlipSpeed)
	
	path_follow_2d.progress += 10 * delta

func shiftSize(node: Node, flipped: Array, speed: float) -> void:
	if !flipped[0]:
		node.scale.x = node.scale.x - (speed * flipSpeedConstant)
		if node.scale.x < -1:
			node.scale.x = -1
			flipped[0] = !flipped[0]
			
	else:
		node.scale.x = node.scale.x + (speed * flipSpeedConstant)
		if node.scale.x > 1:
			node.scale.x = 1
			flipped[0] = !flipped[0]
