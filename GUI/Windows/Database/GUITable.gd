class_name GUITable extends Node

var server
var table_name
var path

const LINE_CONTAINER = preload("res://GUI/Windows/Database/line_container.tscn")
@onready var column_container = $"margin container/column container"
var _listAttributes = []
var dbms

#region ShowAllAttributes
func ShowAllAttributes():
	var servText = "planet"
	if server:
		servText = "sun"
	var long_path = String("{path}/{servText}/{table_name}").format({path = path, servText = servText, table_name = table_name})
	var subFiles = DirAccess.get_files_at(long_path)
	# first it's ID for all same
	ShowAttributesValues(servText, table_name, "id")
	#
	for item in subFiles:
		#var attribute = item.Remove(0, longPath.Length + 1)
		if item != "id":
			ShowAttributesValues(servText, table_name, item)

func ShowAttributesValues(servText, table_name, attributeName:String):
	if attributeName.contains(".b") || attributeName.contains(".backup") || attributeName.contains(".meta"):
		return
	var content = LINE_CONTAINER.instantiate()
	column_container.add_child(content)
	# add button to the list for removal reference
	_listAttributes.push_back(content)
	
	content.dbms = dbms
	content.server = servText == "sun"
	content.server_text = servText
	content.table_name = table_name
	content.column_name = attributeName
	content.database_path = path
	content.instantiate_all_cells()
#endregion
func destroy():
	for item in _listAttributes:
		item.destroy()
		item.queue_free()
	_listAttributes.clear()
