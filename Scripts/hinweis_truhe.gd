extends Area2D

var offen: bool = false
var help_clicked: bool = false
@export var searchAvailable: bool = true
@export var LabelText: String = "test"
@export var onEdge: bool = false
@export var WordsToFind: String = "Spieler"

func _ready() -> void:
	$Hint/HintText.parse_bbcode("[center]" + LabelText + "[/center]")
func _process(_delta: float) -> void:
	if (!searchAvailable):
		$Hint/HelpButton.disabled = true
		$Hint/HelpButton/Sprite2D.visible = false
	if (help_clicked):
		$Hint/HelpButton.disabled = true
	else:
		$Hint/HelpButton.disabled = false
	
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Spieler":
		if !offen:
			$TruheSprite.play("default")
			offen = true
		$Hint.visible = true
		if searchAvailable:
			$Hint/HelpButton/ButtonAnimation.play("Appear")
			$Hint/HelpButton/Timer.start()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Spieler":
		if offen:
			$Hint.visible = false
			$TruheSprite.play("close")
			$Hint/HelpButton/Timer.wait_time = 2.0
			$Hint/HelpButton/Timer.start()
			help_clicked = false			
			offen = false
				


func _on_help_button_pressed() -> void:
	$Hint/HelpButton/ButtonAnimation.play("Click")
	$Hint/HelpButton/Timer.wait_time = 10.0
	$Hint/HelpButton/Timer.start()
	help_clicked = true

func _on_timer_timeout() -> void:
	if !help_clicked && $Hint.visible:
		$Hint/HelpButton/ButtonAnimation.play("Attention")
		$Hint/HelpButton/Timer.start()
	else:
		$Hint/HelpButton/ButtonAnimation.play("Appear")
		$Hint/HelpButton/Timer.wait_time = 2.0
		$Hint/HelpButton/Timer.start()
		help_clicked = false
