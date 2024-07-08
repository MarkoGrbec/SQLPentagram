class_name DBMSReadWriter extends Node

func _ready():
	get_parent().set_id_window(100, "database")
	var table = DataBase.Table.new("myDBMSviuer")
	table.create_column(false, "DBMS", DataBase.DataType.LONG, 1, "id")
	table.create_column(false, "DBMS", DataBase.DataType.STRING, 120, "dbms_root")
	table.create_column(false, "DBMS", DataBase.DataType.FLOAT, 1, "x")
	table.create_column(false, "DBMS", DataBase.DataType.FLOAT, 1, "y")
	
	database_path = DataBase.select(false, "DBMS", "myDBMSviuer", "dbms_root", 1)
	if database_path:
		root_text.text = database_path

var list_server_table_names = []
var list_client_table_names = []
var database_path
var server_tab:TabContainer
var client_tab:TabContainer

signal on_insert

func _input(event):
	if event.is_action_pressed("dataBase"):
		get_parent().last_sibling()
		get_parent().show()

const GUI_SERVER_CLIENT_TAB = preload("res://GUI/Windows/Database/GUIServerClientTab.tscn")
@onready var root_text = $"DBMSRootText/header container/root text/root text"
@onready var data_base_table_container = $MarginContainer/DataBaseTableContainer

func _on_root_text_submit(new_text):
	destroy_tables()
	database_path = new_text
	show_all_tables()

#region show all tables
func show_all_tables():
	# check if dir exists
	if (! DirAccess.dir_exists_absolute(database_path)):
		DatabaseDoesNotExists(" wrong dir ")
		return
#
	var subDirs = DirAccess.get_directories_at(database_path)
	#if dir has any sub directories
	if not subDirs:
		DatabaseDoesNotExists(" empty dir ")
		return
#
	var server:String = DataBase.path(true, database_path, "")
	var client:String = DataBase.path(false, database_path, "")
	client = client.substr(len(client) - 7, 6)
	server = server.substr(len(server) - 4, 3)
	#if sub dirs are correct at all if it's truly database
	if subDirs[0] != server && subDirs[0] != client:
		DatabaseDoesNotExists(subDirs[0])
		return
	
	DataBase.insert(false, "DBMS", "myDBMSviuer", "dbms_root", 1, database_path)
	
	var server_path = String("{path}/{server}").format({path = database_path, server = server})
	#load all servers tables:
	if DirAccess.dir_exists_absolute(server_path):
		server_tab = GUI_SERVER_CLIENT_TAB.instantiate()
		data_base_table_container.add_child(server_tab)
		server_tab.name = "server"
		server_tab.tab_clicked.connect(_on_database_server_table_container_tab_clicked)
		subDirs = DirAccess.get_directories_at(server_path)
		for item in subDirs:
			var tableName = item
			OpenTable(true, tableName)
	# load all client tables:
	var client_path = String("{path}/{client}").format({path = database_path, client = client})
	if DirAccess.dir_exists_absolute(client_path):
		client_tab = GUI_SERVER_CLIENT_TAB.instantiate()
		data_base_table_container.add_child(client_tab)
		client_tab.name = "client"
		client_tab.tab_clicked.connect(_on_database_client_table_container_tab_clicked)
		subDirs = DirAccess.get_directories_at(client_path)
		for item in subDirs:
			var tableName = item
			OpenTable(false, tableName)

const TABLE = preload("res://GUI/Windows/Database/table.tscn")

func OpenTable(server:bool, tableName:String):
	var table_tab = TABLE.instantiate()
	if server:
		server_tab.add_child(table_tab)
	else:
		client_tab.add_child(table_tab)
	table_tab.name = tableName
	# add button to the list for removal reference
	if server:
		list_server_table_names.push_back(table_tab)
	else:
		list_client_table_names.push_back(table_tab)
	table_tab.server = server
	table_tab.table_name = tableName
	table_tab.path = database_path
	table_tab.dbms = self
	
func _on_database_server_table_container_tab_clicked(tab):
	list_server_table_names[tab].destroy()
	list_server_table_names[tab].ShowAllAttributes()
	
func _on_database_client_table_container_tab_clicked(tab):
	list_client_table_names[tab].destroy()
	list_client_table_names[tab].ShowAllAttributes()
#endregion
#region saveData
func save_data():
	on_insert.emit()
	remove_signal()
#endregion
#region destroyButtons
func destroy_tables():
	remove_signal()
	destroy_table(list_server_table_names)
	destroy_table(list_client_table_names)
	if server_tab:
		server_tab.queue_free()
	if client_tab:
		client_tab.queue_free()

func destroy_table(list):
	for item in list:
		item.destroy()
		item.queue_free()
	list.clear()

func remove_signal():
	for item in on_insert.get_connections():
		on_insert.disconnect(item.callable)
#endregion
#region debug
func DatabaseDoesNotExists(actually):
	push_error(String("{path} DataBase does not exist actually: [{actually}] exists").format({path = database_path, actually = actually}))
#endregion debug

#region file system
	#region Path
#const metaDataLength = 5

static func path(server : bool, DataBaseDir : String, tableNamePath : String):
	var fullPath
	if server:
		fullPath = String("{base}/sun/{path}".format({base = DataBaseDir, path = tableNamePath}))
	else:
		fullPath = String("{base}/planet/{path}".format({base = DataBaseDir, path = tableNamePath}))
	return fullPath
	#endregion Path
	#region file not overwriting
static func file_create_or_read_or_write(file_path, file_mode : FileAccess.ModeFlags):
	if(file_mode == FileAccess.READ):
		if FileAccess.file_exists(file_path):
			return FileAccess.open(file_path, file_mode)
		else:
			printerr(String("file {path} does not exist").format({path = file_path}), get_stack())
			return null
	else: if file_mode == FileAccess.WRITE or FileAccess.READ_WRITE:
		if FileAccess.file_exists(file_path):
			file_mode = FileAccess.READ_WRITE
		else:
			file_mode = FileAccess.WRITE
			
		var file = FileAccess.open(file_path, file_mode)
		return file
	#endregion file not overwriting
	#region dir exists
static func directory_exists(server : bool, dataBaseDir, tableName, columnName):
	var _path = path(server, dataBaseDir, tableName)
	if not DirAccess.dir_exists_absolute(String("{_path}").format({_path = _path, column = columnName})):
		printerr(String("directory doesn't exist server[{server}] table name[{tableName}] column[{columnName}]\n").format({server = server, tableName = tableName, columnName = columnName}))
		return ""
	return String("{path}/{columnName}").format({path = _path, columnName = columnName})
	#endregion dir exists
#endregion file system
#region select
static func select(server: bool, dataBaseDir, tableName, columnName, id: int):
		var fileName = directory_exists(server, dataBaseDir, tableName, columnName)
		if fileName == "":
			push_error(String("table does not exists: {tableName}\ncolumn: {columnName}").format({tableName = tableName, columnName = columnName}))
			return
		if not FileAccess.file_exists(fileName):
			push_error("table: ", tableName, " file: ", columnName, " doesn't exist")
		#we load intengrety of files in this path
		var intengrety = -1
		var _path = path(server, dataBaseDir, tableName)
		_path += '/'
		#read length
		var metaData = DataBase.get_header(fileName)
		if metaData == null:
			return
		var length = metaData[0]
		intengrety = DataBase.load_back(_path, intengrety)
		#Save backedUp file that we didn't save correctly to disc but to the bakedUpFile
		if intengrety == 2:
			DataBase.load_back_data(_path, length)
		
		##read file section
		#get to the id section
		var dataLength = DataBase.get_data_length(metaData[1], length)
		
		if not FileAccess.file_exists(fileName):
			return
		var fileAccess = FileAccess.open(fileName, FileAccess.READ)
		fileAccess.seek(dataLength * id)
		# needs to read 4 bytes more than it is needed to the process is skipped in the end
		var buffer = fileAccess.get_buffer(dataLength+4)

		fileAccess.close()
		if buffer.size() == 0:
			return
		if not DataBase.type_check(buffer[0], metaData[1]):
			return
		var text = bytes_to_var(buffer)
		return text
		
static func last_id(server: bool, dataBaseDir, tableName, columnName):
	var fileName = directory_exists(server, dataBaseDir, tableName, columnName)
	if fileName == "":
		printerr(String("table does not exists: {tableName}\ncolumn: {columnName}").format({tableName = tableName, columnName = columnName}))
		return
	#we load intengrety of files in this path
	var intengrety = -1
	var _path = path(server, dataBaseDir, tableName)
	_path += '/'
	
	#read length
	var fileAccess = FileAccess.open(fileName, FileAccess.READ)
	var metaData = DataBase.get_header(fileName)
	if metaData == null:
		fileAccess.close()
		return 0
	var length = metaData[0]
	
	intengrety = DataBase.load_back(path, intengrety)
	#Save backedUp file that we didn't save correctly to disc but to the bakedUpFile
	if intengrety == 2:
		DataBase.load_back_data(path, length)
	
	##read file section
	#get to the id section
	var dataLength = DataBase.get_data_length(metaData[1], length)
	var totalLength = 0
	if FileAccess.file_exists(fileName):
		totalLength = fileAccess.get_length()
	@warning_ignore("integer_division")
	var idCount = (totalLength) / dataLength
	if fileAccess:
		fileAccess.close()
	return idCount
#endregion select
#region insert
## server, dataBaseDir, tableName, columnName, id, data, oper
static func insert(server : bool, dataBaseDir : String, tableName, columnName, id: int, data, _oper = "equals"):
	#if id < 1:
		#printerr("id is less than 1 it should never be 0 is ment for null", get_stack())
		#return
	if(data == null):
		push_error("data is null")
		return
	var _path = path(server, dataBaseDir, tableName)
	var fileName = directory_exists(server, dataBaseDir, tableName, columnName)
	if not FileAccess.file_exists(String("{fileName}.meta").format({fileName = fileName})):
		printerr(String("Exception fileName: {fileName}.meta does not exist\n").format({fileName = columnName}), get_stack())
		return
	# started creating a file
	DataBase.save_back(path, 1)
	# read column config
	var length
	var converted
	var fileAccess = file_create_or_read_or_write(fileName, FileAccess.READ_WRITE)
	var metaData = DataBase.get_header(fileName)
	length = metaData[0]
	if length == 0:
		printerr(String("something is wrong {fileName}").format({fileName = fileName}), get_stack())
		return
	var dataLength = DataBase.get_data_length(metaData[1], length)
	#convert data to bytes
	converted = var_to_bytes(data)
	if not DataBase.type_check(converted[0], metaData[1]):
		return
	##4 in front because it is type variable saved with it
	if converted.size() > dataLength:
		if length > 1:
			converted[4] = length
		converted = converted.slice(0, dataLength)
	#save to backeup
	DataBase.save_back_data(_path, columnName, metaData[1], length, id, converted)
	#backeup has been sucessfully written
	_path += "/"
	DataBase.save_back(_path, 2)
	
	#saved permenantly
	fileAccess.seek(id * dataLength)
	fileAccess.store_buffer(converted)
	
	#read if end of file
	var total_length = fileAccess.get_length()
	@warning_ignore("integer_division")
	if total_length / dataLength >= id:
	#write 4 more bytes for string to read properly else it reads nothing if it comes to eof
		fileAccess.store_32(0)
	fileAccess.close()
	DataBase.save_back(path, 0)
#endregion insert


func _on_exit():
	get_parent().hide()



