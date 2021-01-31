extends PopupPanel

func open(txt: String, duration):
	$c/Label.text = txt
	popup_centered()
	$Timer.start(duration)


func _on_Timer_timeout():
	hide()
