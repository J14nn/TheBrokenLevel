extends Area2D

func _on_body_entered(body):
	if body.name == "Spieler":
		Global.leitern += 1

func _on_body_exited(body):
	if body.name == "Spieler":
		Global.leitern = max(Global.leitern - 1, 0)
