extends Node

var tscn_file_path: String = "res://addons/scene_nav/scene_dock.tscn"


func _ready():
	print("test 2")
	var file := FileAccess.open(tscn_file_path, FileAccess.READ)
	
	var error = file.open(tscn_file_path, FileAccess.READ)
	if error == OK:
		var content := file.get_as_text()
		file.close()
		print(content)
	else:
		print("Failed to open the file.")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_my_button_pressed():
	print("clicked!!!")
	pass # Replace with function body.


func get_file():
	var file := FileAccess.open(tscn_file_path, FileAccess.READ)
	
	var error = file.open(tscn_file_path, FileAccess.READ)
	if error == OK:
		var content := file.get_as_text()
		file.close()
		print(content)
	else:
		print("Failed to open the file.")
