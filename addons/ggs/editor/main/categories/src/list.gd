@tool
extends ggsItemList

signal loaded

@export_group("Nodes")
@export var ContextMenu: PopupMenu
@export var FlashEffect: ColorRect


func _ready() -> void:
	item_selected.connect(_on_item_selected)
	item_clicked.connect(_on_item_clicked)
	empty_clicked.connect(_on_empty_clicked)
	ContextMenu.id_pressed.connect(_on_ContextMenu_id_pressed)
	
	load_list()


#region Load Categories
func load_list() -> void:
	var categories: PackedStringArray = _load_from_disc()
	create_from_arr(categories)
	
	GGS.State.selected_category = ""
	FlashEffect.run()
	loaded.emit()


func _load_from_disc() -> PackedStringArray:
	var settings_path: String = GGS.Pref.res.paths["settings"]
	var dir: DirAccess = DirAccess.open(settings_path)
	
	# Temporarily converted to Array so we can use filter().
	var list: Array = Array(dir.get_directories()).filter(_remove_underscored)
	return PackedStringArray(list)


func _remove_underscored(element: String) -> bool:
	return not element.begins_with("_")

#endregion

#region Item Interaction
func _on_item_selected(item_index: int) -> void:
	GGS.State.selected_category = get_item_text(item_index)

#endregion

#region Context Menu Visibility
func _show_context_menu(at_position: Vector2, disable_category_actions: bool) -> void:
	# For some reason the menu won't popup at the exact cursor location
	# without this offset.
	var offset: Vector2 = Vector2(0, -22)
	
	ContextMenu.position = global_position + at_position - offset
	ContextMenu.set_category_actions_disabled(disable_category_actions)
	ContextMenu.popup()


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	
	_show_context_menu(at_position, false)


func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	
	_show_context_menu(at_position, true)

#endregion

#region Context Menu Interaction
func _on_ContextMenu_id_pressed(id: int) -> void:
	var selected_cat: String = GGS.State.selected_category
	match id:
		ContextMenu.ItemId.RENAME:
			var RenamePopup: ConfirmationDialog = GGS.Util.popup_rename.instantiate()
			RenamePopup.prev_name = selected_cat
			RenamePopup.rename_confirmed.connect(_on_rename_confirmed)
			add_child(RenamePopup)
		
		ContextMenu.ItemId.DELETE:
			var DeletePopup: ConfirmationDialog = GGS.Util.popup_delete.instantiate()
			DeletePopup.item_name = selected_cat
			DeletePopup.set_content(DeletePopup.Type.CATEGORY)
			DeletePopup.delete_confirmed.connect(_on_delete_confirmed)
			add_child(DeletePopup)
		
		ContextMenu.ItemId.FILESYSTEM_GODOT:
			_show_in_filesystem_dock(selected_cat)
		
		ContextMenu.ItemId.FILESYSTEM_OS:
			_show_in_os_filesystem(selected_cat)
		
		ContextMenu.ItemId.RELOAD:
			load_list()


# Rename #
func _on_rename_confirmed(prev_name: String, new_name: String) -> void:
	var settings_path: String = GGS.Pref.res.paths["settings"]
	var dir: DirAccess = DirAccess.open(settings_path)
	dir.rename(prev_name, new_name)
	load_list()
	EditorInterface.get_resource_filesystem().scan()


# Delete #
func _on_delete_confirmed(cat_name: String) -> void:
	var settings_path: String = GGS.Pref.res.paths["settings"]
	var path: String = settings_path.path_join(cat_name)
	path = ProjectSettings.globalize_path(path)
	OS.move_to_trash(path)
	load_list()
	EditorInterface.get_resource_filesystem().scan()


# Show in FileSystem Dock
func _show_in_filesystem_dock(cat_name: String) -> void:
	var settings_path: String = GGS.Pref.res.paths["settings"]
	var file: String = settings_path.path_join(cat_name)
	EditorInterface.get_file_system_dock().navigate_to_path(file)


# Open in OS File Manager #
func _show_in_os_filesystem(cat_name: String) -> void:
	var settings_path: String = GGS.Pref.res.paths["settings"]
	var file: String = settings_path.path_join(cat_name)
	var path: String = ProjectSettings.globalize_path(file)
	OS.shell_show_in_file_manager(path)

#endregion
