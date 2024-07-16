@tool
extends Control

@onready var scene_tree = $MainVBox/MarginContainer/Tree
@onready var editor_interface = Engine.get_singleton("EditorInterface")
@onready var editor_file_system = editor_interface.get_resource_filesystem()
@onready var show_addons: bool = false
@onready var show_path: bool = false

var click_timer = null

func _ready():
	if editor_interface:
		update_scene_tree()
		scene_tree.connect("item_selected", Callable(self, "_on_item_selected").bind(scene_tree))
		scene_tree.connect("item_activated", Callable(self, "_on_item_activated").bind(scene_tree))
	
		# Connect the filesystem_changed signal to update the trees when the filesystem changes
		editor_file_system.connect("filesystem_changed", Callable(self, "_on_filesystem_changed"))
	else:
		print("Editor interface not found")

func update_scene_tree():
	var collapsed_states = _get_collapsed_states(scene_tree)
	clear_children(scene_tree)
	
	# Create root item
	var root_item = scene_tree.create_item()
	root_item.set_text(0, "Root")
	
	# Get all top-level directories in res://
	var top_level_dirs = get_all_top_level_dirs("res://")

	# Add directories and scenes to the tree
	for dir_path in top_level_dirs:
		if (dir_path != "res:///addons" or show_addons) and (dir_path != "res:///.godot"):
			var dir_name = dir_path.replace("res:///", "").capitalize()
			var dir_item = create_tree_item(dir_name, scene_tree, root_item, null, false, dir_path, "Directory")
			dir_item.set_collapsed(true)
			var scene_paths = get_all_scene_paths(dir_path)
			add_scene_paths_to_tree(scene_paths, dir_item, scene_tree)
	
	_set_collapsed_states(scene_tree, collapsed_states)

func get_all_top_level_dirs(base_path: String) -> Array:
	var dirs = []
	var dir = DirAccess.open(base_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not (file_name == "." or file_name == ".."):
				dirs.append(base_path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return dirs

func get_all_scene_paths(dir_path: String, exclude_dirs: Array = []) -> Array:
	var paths = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not (file_name == "." or file_name == ".."):
				# Recursively search subdirectories
				var sub_dir_paths = get_all_scene_paths(dir_path + "/" + file_name, exclude_dirs)
				paths.append_array(sub_dir_paths)
			elif file_name.ends_with(".tscn"):
				paths.append(dir_path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return paths

func add_scene_paths_to_tree(scene_paths: Array, root_item: TreeItem, tree: Tree):
	var path_map = {}

	# Organize scenes by their directory paths
	for scene_path in scene_paths:
		var dir_path = scene_path.get_base_dir() + "/"
		if not path_map.has(dir_path):
			path_map[dir_path] = []
		path_map[dir_path].append(scene_path)

	# Create tree items for directories and their scenes
	for dir_path in path_map.keys():
		var dir_item = create_tree_item(dir_path, tree, root_item, null, false, dir_path, "Directory")
		dir_item.set_collapsed(true)
		for scene_path in path_map[dir_path]:
			var packed_scene = ResourceLoader.load(scene_path)
			if packed_scene and packed_scene is PackedScene:
				var scene_tree_item = create_tree_item(scene_path.get_file(), tree, dir_item, null, true, scene_path, "PackedScene")
				log_node_tree(packed_scene.instantiate(), scene_tree_item, 0, tree, scene_path, scene_path)

func log_node_tree(node: Node, parent_item: TreeItem, depth: int, tree: Tree, parent_path: String, parent_scene_path: String):
	if node == null or parent_item == null:
		return
	var node_path = parent_path + "/" + node.name
	var tree_item = create_tree_item(node.name, tree, parent_item, node, false, node_path, node.get_class(), parent_scene_path)
	if depth == 0:
		tree_item.set_collapsed(true)
	for child in node.get_children():
		log_node_tree(child, tree_item, depth + 1, tree, node_path, parent_scene_path)

func reformat_path(path: String) -> String:
	# Split the path by "/" and convert to Array[String]
	var parts_packed: PackedStringArray = path.split("/")
	var parts: Array[String] = []
	for part in parts_packed:
		parts.append(part)

	# Return the last non-empty part
	for i in range(parts.size() - 1, -1, -1):
		if parts[i] != "":
			return parts[i]
	return ""


func create_tree_item(text: String, tree: Tree, parent: TreeItem = null, node: Node = null, is_scene_file: bool = false, full_path: String = "", node_type: String = "", parent_scene_path: String = "") -> TreeItem:
	var tree_item: TreeItem
	if parent:
		tree_item = parent.create_child()
	else:
		tree_item = tree.create_item()

	if !show_path and node_type == "Directory":
		var formatted_dir_name = reformat_path(text)
		tree_item.set_text(0, formatted_dir_name.capitalize())
	else:
		tree_item.set_text(0, text.replace("///", "//"))
	
	tree_item.set_metadata(0, {
		"path": full_path,
		"name": text,
		"type": node_type,
		"parent_scene_path": parent_scene_path
	})
	
	if is_scene_file:
		var icon = get_theme_icon("PackedScene", "EditorIcons")
		if icon:
			tree_item.set_icon(0, icon)
	else:
		if node:
			var type = node.get_class()
			var icon = get_icon_for_type(type)
			if icon:
				tree_item.set_icon(0, icon)
		else:
			var icon = get_theme_icon("Folder", "EditorIcons")
			if icon:
				tree_item.set_icon(0, icon)

	return tree_item

func get_icon_for_type(type: String) -> Texture2D:
	var icon = get_theme_icon(type, "EditorIcons")
	if not icon:
		icon = get_theme_icon("Node", "EditorIcons")  # Fallback to a default icon
	return icon

func clear_children(tree: Tree):
	tree.clear()

func _on_item_selected(scene_tree: Tree):
	if click_timer == null:
		click_timer = Timer.new()
		click_timer.one_shot = true
		click_timer.wait_time = 0.2
		click_timer.connect("timeout", Callable(self, "_on_single_click").bind(scene_tree))
		add_child(click_timer)
	click_timer.start()

func _on_single_click(scene_tree: Tree):
	click_timer = null
	var item = scene_tree.get_selected()
	if item:
		var metadata = item.get_metadata(0)
		if metadata == null:
			return
		if metadata == null or (metadata["type"] == "Directory" and metadata["parent_scene_path"] == ""):
			var scene_path = metadata["path"]
			if ResourceLoader.exists(scene_path, "PackedScene"):
				editor_interface.edit_resource(ResourceLoader.load(scene_path))
		else:
			var parent_scene_path = metadata["parent_scene_path"]
			if ResourceLoader.exists(parent_scene_path, "PackedScene"):
				editor_interface.edit_resource(ResourceLoader.load(parent_scene_path))


func _on_item_activated(scene_tree: Tree):
	var item = scene_tree.get_selected()
	if item:
		var metadata = item.get_metadata(0)
		if metadata == null or (metadata["type"] == "Directory" and metadata["parent_scene_path"] == ""):
			return
		var scene_path = metadata.get("path", "")
		var parent_scene_path = metadata.get("parent_scene_path", "")

		if metadata["type"] == "PackedScene":
			_handle_scene_activation(scene_path)
		else:
			_handle_scene_activation(parent_scene_path)

func _handle_scene_activation(scene_path: String):
	if scene_path == "":
		return
		
	var open_scenes = editor_interface.get_open_scenes()
	
	if open_scenes.has(scene_path):
		# Close and reopen the scene to bring it to focus
		editor_interface.close_scene(scene_path.replace("///", "//"))
		editor_interface.open_scene_from_path(scene_path.replace("///", "//"))
	else:
		# Open the scene
		editor_interface.open_scene_from_path(scene_path.replace("///", "//"))
# Signal handler for filesystem changes
func _on_filesystem_changed():
	update_scene_tree()

func _get_collapsed_states(tree: Tree) -> Dictionary:
	var states = {}
	var root = tree.get_root()
	if root:
		_recursive_get_collapsed_states(root, states)
	return states

func _recursive_get_collapsed_states(tree_item: TreeItem, states: Dictionary):
	var metadata = tree_item.get_metadata(0)
	if metadata and metadata.has("path"):
		var path = metadata["path"]
		states[path] = tree_item.is_collapsed()

	var child = tree_item.get_first_child()
	while child:
		_recursive_get_collapsed_states(child, states)
		child = child.get_next()

func _set_collapsed_states(tree: Tree, states: Dictionary):
	var root = tree.get_root()
	if root:
		_recursive_set_collapsed_states(root, states)

func _recursive_set_collapsed_states(tree_item: TreeItem, states: Dictionary):
	var metadata = tree_item.get_metadata(0)
	if metadata and metadata.has("path"):
		var path = metadata["path"]
		if states.has(path):
			tree_item.set_collapsed(states[path])

	var child = tree_item.get_first_child()
	while child:
		_recursive_set_collapsed_states(child, states)
		child = child.get_next()

func _on_addons_visibility_changed(addons_visible):
	show_addons = addons_visible
	update_scene_tree()


func _on_pathname_visibility_changed(path_visible):
	show_path = path_visible
	update_scene_tree()
	pass # Replace with function body.
