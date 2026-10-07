extends Label


var old_score := 0
var target_score := 0
var current_score := 0

var old_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
	

func update_score(new_score: int) -> void:
	if old_tween != null:
		old_tween.kill()
	var tween := create_tween()
	var time := minf(float(new_score - old_score) / 300, 1.0)
	print(new_score - old_score, " ", time)
	tween.tween_method(update_score_text, 0.0, 1.0, time).set_ease(Tween.EASE_OUT)
	target_score = new_score
	old_score = current_score
	old_tween = tween

func update_score_text(progress: float) -> void:
	current_score = int(lerp(old_score, target_score, progress))
	text = "%d" % (current_score)
