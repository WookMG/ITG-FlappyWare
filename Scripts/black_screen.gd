extends TextureRect
const FULL_BLACK = 1
const TRANSPARENT = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_black_out()

func fade_black_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", FULL_BLACK, 0.5)
	return tween

func fade_black_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", TRANSPARENT, 0.5)
	return tween
