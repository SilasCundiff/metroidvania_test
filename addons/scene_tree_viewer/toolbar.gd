@tool
extends HBoxContainer
## Note: There is a bug where if you doubleclick specifically this addons Toolbar node 
## in the Scene tree, it will display an error in the console. However, this error doesn't appear
## to impact anything, and I can't figure out the cause of it.


@onready var line_edit = $HBoxContainer2/LineEdit
@onready var menu_button = $HBoxContainer2/MenuButton
@onready var popup_menu = menu_button.get_popup()
@onready var options_button = $HBoxContainer2/FilterOptions
@onready var options_menu = options_button.get_popup()
@onready var scene_tree = $"../MarginContainer/Tree"

@onready var filter_type = "both"  # Default filter type
@onready var addons_visible: bool = false
@onready var expanded: bool = false
@onready var sort_asc: bool = true

signal on_addons_visibility_changed
signal on_pathname_visibility_changed

func _ready():
	line_edit.connect("text_changed", Callable(self, "_on_text_changed"))

	# Add menu items if not already added
	if popup_menu and popup_menu.get_item_count() == 0:
		popup_menu.add_item("Expand All", 0)
		popup_menu.add_item("Sort Desc", 1)
		popup_menu.add_item("Show Addons", 2)
		popup_menu.set_item_as_checkable(2, true)
		popup_menu.add_item("Show Paths", 3)
		popup_menu.set_item_as_checkable(3, true)
	# Connect menu button options
	if popup_menu:
		popup_menu.connect("id_pressed", Callable(self, "_on_menu_option_pressed"))
	var icon = get_theme_icon("MenuButton", "EditorIcons")
	menu_button.icon = icon
	
	# Add options items if not already added
	if options_menu and options_menu.get_item_count() == 0:
		options_menu.add_item("Both", 0)
		options_menu.add_item("Name", 1)
		options_menu.add_item("Node", 2)
	# Connect options button items
	if options_menu:
		options_menu.connect("id_pressed", Callable(self, "_on_options_selected"))

	_update_filter_label()

func _on_text_changed(new_text):
	_filter_tree_items(scene_tree, new_text)

func _on_options_selected(index):
	match index:
		0:
			filter_type = "both"
		1:
			filter_type = "name"
		2:
			filter_type = "node"
	_update_filter_label()
	if line_edit.text != "":
		_filter_tree_items(scene_tree, line_edit.text)

func _update_filter_label():
	options_button.text = filter_type.capitalize()

func _filter_tree_items(tree: Tree, filter_text: String):
	var root = tree.get_root()
	if root:
		_recursive_filter(root, filter_text.to_lower())

func _recursive_filter(tree_item: TreeItem, filter_text: String) -> bool:
	var has_visible_child = false
	var child = tree_item.get_first_child()
	
	while child:
		var child_visible = _recursive_filter(child, filter_text)
		has_visible_child = has_visible_child or child_visible
		child = child.get_next()

	var text_name = tree_item.get_text(0).to_lower()
	var text_node = ""
	var metadata = tree_item.get_metadata(0)
	if metadata:
		text_node = metadata["type"].to_lower()

	var is_visible = filter_text == "" or _fuzzy_match(filter_text, text_name) or _fuzzy_match(filter_text, text_node) or has_visible_child
	if filter_type == "name":
		is_visible = filter_text == "" or _fuzzy_match(filter_text, text_name) or has_visible_child
	elif filter_type == "node":
		is_visible = filter_text == "" or _fuzzy_match(filter_text, text_node) or has_visible_child
	elif filter_type == "both":
		is_visible = filter_text == "" or _fuzzy_match(filter_text, text_name) or _fuzzy_match(filter_text, text_node) or has_visible_child

	tree_item.visible = is_visible

	return is_visible

func _fuzzy_match(pattern: String, text: String) -> bool:
	var pattern_len = pattern.length()
	var text_len = text.length()

	if pattern_len == 0:
		return true
	if pattern_len > text_len:
		return false

	var pattern_idx = 0
	var text_idx = 0
	var score = 0

	while text_idx < text_len:
		if pattern[pattern_idx] == text[text_idx]:
			score += 1
			pattern_idx += 1
			if pattern_idx == pattern_len:
				break
		else:
			# Penalty for non-matching characters to make search stricter
			score -= 0.5
		text_idx += 1

	# Adjust the score based on how much of the pattern was matched
	score -= (pattern_len - pattern_idx) * 1.5  # Increased penalty for unmatched pattern characters
	
	# Minimum threshold score to consider a match
	return score >= pattern_len * 0.8  # Higher threshold for stricter match

func _on_menu_option_pressed(id):
	match id:
		0:
			_change_collapsed_state(scene_tree)
		1:
			_sort_tree(scene_tree)
		2:
			_change_addon_visibility()
		3: 
			_change_pathname_visibility()


func _change_collapsed_state(tree: Tree):
	var root = tree.get_root()
	expanded = !expanded
	if !expanded:
		popup_menu.set_item_text(0, "Expand All")
	elif expanded:
		popup_menu.set_item_text(0, "Collapse All")
	if root:
		_recursive_expand_collapse(root, expanded, true)
	pass

func _change_addon_visibility():
	var root = scene_tree.get_root()
	popup_menu.set_item_checked(2, !popup_menu.is_item_checked(2))
	on_addons_visibility_changed.emit(popup_menu.is_item_checked(2))
	if line_edit.text != "":
		_filter_tree_items(scene_tree, line_edit.text)

func _change_pathname_visibility():
	var root = scene_tree.get_root()
	popup_menu.set_item_checked(3, !popup_menu.is_item_checked(3))
	on_pathname_visibility_changed.emit(popup_menu.is_item_checked(3))
	if line_edit.text != "":
		_filter_tree_items(scene_tree, line_edit.text)

func _recursive_expand_collapse(tree_item: TreeItem, expanded: bool, is_root: bool = false):
	if not is_root:
		tree_item.set_collapsed(not expanded)
	var child = tree_item.get_first_child()
	while child:
		_recursive_expand_collapse(child, expanded)
		child = child.get_next()

func _sort_tree(tree: Tree):
	var root = tree.get_root()
	sort_asc = !sort_asc
	
	if sort_asc:
		popup_menu.set_item_text(1, "Sort Desc")
	elif !sort_asc:
		popup_menu.set_item_text(1, "Sort Asc")
	if root:
		_recursive_sort(root)

func _recursive_sort(tree_item: TreeItem):
	var children = []
	var child = tree_item.get_first_child()
	while child:
		children.append(child)
		child = child.get_next()
	
	children.reverse()
	
	for c in children:
		tree_item.remove_child(c)
	
	for c in children:
		tree_item.add_child(c)
		_recursive_sort(c)
