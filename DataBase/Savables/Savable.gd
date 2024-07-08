class_name Savable extends Node

#region constructors
## server, path, instance it can be class with copy() non parameters DO NOT delete THIS instance of a class
func _init(server: bool, dbms: String, path:String, default_instance):
	_dbms = dbms
	var table = DataBase.Table.new(path)
	table.create_column(server, _dbms, DataBase.DataType.LONG, 1, "id")
	_null_data_list = NullList.new()
	_default_instance = default_instance
	_path = path
	_server = server
	_multi_null = DataBase.MultiTable.new(_dbms, String("multi{server}p{path}nulls").format({server = server, path = path}))
	var ids = _multi_null.select(0, 1)
	
	for item in ids:
		_null_data_list.remove_at(item)
	#we make starter 0 id as null
	var data = _default_instance.copy()
	data._server = _server
	data._path = _path
	data.id = 0
	DataBase.insert(server, _dbms, _path, "id", data.id, data.id)
#func _init(server: bool, _path:String):
	#Server = server
	#Path = _path
	#_nullDataList = new NullList<T>()
	#var db = DbmsSqLite.GetSin(time)
	#db.GetNulls(Path, _nullDataList)
	#PartlyLoadAll1(time)

#endregion
#region inputs
var _null_data_list: NullList
var _multi_null
#DataBase.MultiTable _multiLeftRight
var _default_instance
var _path: String
var _server: bool
var _dbms
#endregion end inputs
#set for deletion
#region SQLite full/partLoad
#public void PartlyLoadAll1(float time)
#{
	#var db = DbmsSqLite.GetSin(time)
	#IDataReader r
	#var fatherColumn = false
	#if (DbmsSqLite.ColumnExists(Path, "father"))
	#{
		#r = db.SelectQuery($"SELECT id, father FROM {Path}")
		#fatherColumn = true
	#}
	#else
	#{
		#r = db.SelectQuery($"SELECT id FROM {Path}")
	#}
	#while (r.Read())
	#{
		#var t = new T()
		#t.ID = DbmsSqLite.GetLongValue(r, 0)
		#t.server = Server
#
		#//father
		#if (fatherColumn)
		#{
			#t.idFather = DbmsSqLite.GetLongValue(r, 1)
			#_nullDataList.Set(t.ID, t)
			#if (t.idFather != 0)
			#{
				#SetFather(t.ID, t.idFather, false)
			#}
			#t.PartlyLoad(t.ID)
		#}
		#else
		#{
			#t.PartlyLoad(t.ID)
			#_nullDataList.Set(t.ID, t)
		#}
	#}
#}
#endregion
#//set for deletion
#region SQLite get/set
#/// <summary>
#/// get T of id load it if it's not loaded already partly or fully
#/// </summary>
#/// <param name="id">id row</param>
#/// <param name="partlyLoad">null fully load, true partly load, false fully load</param>
#/// <returns></returns>
#public T Get1(long id, params bool[] partlyLoad)
#{
	#var t = _nullDataList.Get(id)
	#if (t is null)
	#{
		#t = new T()
		#t.ID = id
	#}
	#//if t is null || load only part || don't load at all
	#if (!(t?.partlyLoad < 2))
	#{
		#return t
	#}
	#//t is never null so we set it's path
	#t.path = _path
	#t.Path = Path
	#if (partlyLoad.Length > 0)
	#{
		#if (partlyLoad[0])
		#{
			#if (t.partlyLoad >= 1) return t
			#t.partlyLoad = 1
			#t.PartlyLoad(id)
		#}
		#else
		#{
			#t.partlyLoad = 2
			#t.Load(t.ID)
		#}
	#}
	#else
	#{
		#t.partlyLoad = 2
		#t.Load(t.ID)
	#}
	#return t
#}
#
#/// <summary>
#/// get first result only from multi column
#/// </summary>
#/// <param name="left">left column - id1</param>
#/// <param name="right">right column - id2</param>
#/// <param name="partlyLoad">if partly load</param>
#/// <returns>only first row of selected query</returns>
#public T Get1(long left, long right, params bool[] partlyLoad)
#{
	#var db = DbmsSqLite.GetSin(Time.time)
	#var readIdRows = left == 0 ?
		#db.SelectQuery(
			#$"SELECT id FROM {Path} WHERE {DbmsSqLite.ColumnId2} = {right}") :
		#db.SelectQuery(right == 0 ?
			#$"SELECT id FROM {Path} WHERE {DbmsSqLite.ColumnId1} = {left}" :
			#$"SELECT id FROM {Path} WHERE {DbmsSqLite.ColumnId1} = {left} AND {DbmsSqLite.ColumnId2} = {right}")
	#if (readIdRows.Read())
	#{
		#return Get1(DbmsSqLite.GetLongValue(readIdRows, 0), partlyLoad)
	#}
	#return null
#}
#
#public long[] SqLiteGetIdRows(long left, long right)
#{
	#var r = GetRawData(left, right)
	#var list = new List<long>()
	#while (r.Read())
	#{
		#list.Add(DbmsSqLite.GetLongValue(r, 0))
	#}
	#return list.ToArray()
#}
#public IDataReader GetRawData(long left, long right, params string[] columns)
#{
	#var select = columns.Aggregate("", (current, item) => current + $", {item}")
#
	#var db = DbmsSqLite.GetSin(Time.time)
	#return left == 0 ?
		#db.SelectQuery(
			#$"SELECT id{select} FROM {Path} WHERE {DbmsSqLite.ColumnId2} = {right}") :
		#db.SelectQuery(right == 0 ?
			#$"SELECT id{select} FROM {Path} WHERE {DbmsSqLite.ColumnId1} = {left}" :
			#$"SELECT id{select} FROM {Path} WHERE {DbmsSqLite.ColumnId1} = {left} AND {DbmsSqLite.ColumnId2} = {right}")
#}
#/// <summary>
#/// set T in to savable
#/// </summary>
#/// <param name="t"></param>
#/// <param name="partly">0 don't save, 1 partly save, 2 full save, null full save</param>
#/// <returns></returns>
#public long Set1(T t, params byte[] partly)
#{
	#t.path = _path
	#t.Path = Path
	#t.ID = _nullDataList.Set(t)
	#PartlySave(t, partly)
	#return t.ID
#}
##SQLite
#func partly_save(data, partly: int = 0):
	#data.path = _path
	#var db = DbmsSqLite.GetSin(Time.time)
	#db.Update(false, false, Path, t.ID, "id", $"{t.ID}")
	#// DataBase.Insert(Server, _path, DataBase.fileName.id, id, id, DataBase.Operating.equals)
	#t.server = Server
	#if(partly.Length > 0){
		#if(partly[0] == 1){
			#t.partlyLoad = 2
			#t.PartlySave()
		#}
		#else if(partly[0] == 2){
			#t.partlyLoad = 2
			#t.Save()
		#}
	#}
	#else{
		#t.partlyLoad = 2
		#t.Save()
	#}
#}
#endregion
#
#region PartlyLoad SaveAll
#func save_all():
	#var count = _nullDataList.count()
	#for i in count:
		#var data = _nullDataList.Get(i)
		#if data is not null:
			#t.save_all()
		#else:
			#DbmsSqLite.GetSin(Time.time).ExecuteQuery($"DELETE FROM {Path} WHERE id = {i}")
#///<summary>load full list with children and fathers and only PartlyLoadData configured At: (T)</summary>
func partly_load_all():
	var lastId = DataBase.last_id(_server, g_man.dbms, _path, "id")
	print("last id:", lastId)
	if lastId:
		for i in range(1, lastId, 1):
			var data = get_index_data(i, true)
			if data == null:
				continue
			data._path = _path
			data._server = _server
			#// //if table and column exists
			#// if (!System.IO.File.Exists(
			#//         DataBase.DirectoryExists(Server, _path.ToString(),
			#//             DataBase.fileName.father.ToString()
			#//         )
			#//     )
			#//    )
			#//     continue
			#// //override idFather
			#// t.idFather = (long)DataBase.Select(Server, _path, DataBase.fileName.father, id, true)
			#// if (t.idFather != 0)
			#// {
			#//     SetFather(t.ID, t.idFather, false)
			#// }
#endregion
## set Father and save it : if one doesn't exist it won't work</summary>
## idChild contains Father
## idFather children (idChild)
## save if father is going to be saved usually is yes
func SetFather(id_child: int, id_father: int, save: bool = true):
	var tC = get_index_data(id_child, true)
	var tF = get_index_data(id_father, true)
	#if one is null it won't work correctly so it isn't a Father or a child
	if tF == null || tC == null:
		print(String("path: {path}, {id_child} child:{tC} {id_father} Father:{tF}").format({path = _path, id_child = id_child, tC = tC == null, id_father = id_father, tF = tF == null}))
		return
	tC.id_father = id_father
	
	#we add container if needed
	if tF.threads_children == null:
		tF.reset_container(true)
	
	#//check if it doesn't contain same child
	if tF.threads_children != null && tF.threads_children.has(id_child):
		printerr(String("father {tF} already contains {id_child}".format({tF = tF.id, id_child = id_child})))
		return
	
	tF.SetFather(id_child)
	print(String("set Father: {tC} /{save}/ {tF}").format({tC = tC.id, tF = tF.id, save = save}))
	if(save):
		DataBase.insert(_server, g_man.dbms, _path, "father", id_child, id_father)

func get_new():
	var new_instance = _default_instance.copy()
	new_instance._path = _path
	new_instance._server = _server
	return new_instance

func try_get(id, partly_load):
	var data = get_index_data(id, partly_load)
	if data != null:
		return data
	return false
	
## get id of saved item</param>
func get_index_data(id, partly_load:bool = false):
	if not id || id == 0:
		return
	var data = _null_data_list.get_index_data(id)
	if data == null:
		#needs to be created we don't have is but it may exist in database
		if _multi_null.select_id_row_p_s(id, 1) == 0:
			data = _default_instance.copy()
			data._server = _server
			data._path = _path
			var new_id = DataBase.select(_server, g_man.dbms, _path, "id", id)
			if new_id == null || new_id == 0:
				#we save null to the multi DB
				remove_at(id)
				return
			data.id = new_id
			#if it was deleted
			if data.id == 0:
				return
			set_index_data(data.id, data, 0)
			# load only part
			if partly_load:
				data.partly_loaded = 1
				data.partly_load()
			# fully load
			else:
				data.partly_loaded = 2
				data.fully_load()
			return data
		return
	#data is never null so we set it's path
	data.id = id
	data._path = _path
	data._server = _server
	#if fully was already loaded
	if data.partly_loaded > 1:
		return data
	#load only part
	if partly_load:
		if data.partly_loaded >= 1:
			return data
		data.partly_loaded = 1
		data.partly_load()
		return data
	#if it's going to be fully loaded
	if data.partly_loaded < 2:
		data.partly_loaded = 2
		data.fully_load()
	return data
## get the opposite column
#func get_id_rows(left, right): return _multiLeftRight.Select(left, right)
#func remove_id_rows(left, right): _multiLeftRight.Delete(left, right)
#func Set(left, right): _multiLeftRight.add_row(0, left, right)
## if you make gap inside it stays a gap forever /
## unless you make new ones in gap /
## proceed with caution or treat it as private
func set_index_data(id, data, partly_save := 2):
	data._path = _path
	data._server = _server
	_null_data_list.set_index_data(id, data)
	remove_multi(id)
	data.id = id
	
	DataBase.insert(_server, g_man.dbms, _path, "id", id, id)
	
	data.partly_loaded = 2
	if partly_save == 1:
		data.partly_save()
	elif partly_save == 2:
		data.fully_save()
	return data
## id is automatically added
## 0 don't save,
## 1 partly save,
## 2 fully save,
## id where it's added is returned
func set_data(data, save: int = 2):
	data._path = _path
	data._server = _server
	if _multi_null.select(0, 1).size() == 0:
		data.id = DataBase.last_id(_server, g_man.dbms, _path, "id")
	else:
		data.id = _multi_null.select(0, 1)[0]
	remove_multi(data.id)
	if data.id == 0:
		printerr("ERROR data.id is 0\n", get_stack())
		return 0
	set_index_data(data.id, data, save)
	return data.id

## get old data or set new data under index
func get_or_set(id:int, partly_load:bool = false):
	var data = get_index_data(id, partly_load)
	if data:
		return data
	data = _default_instance.copy()
	set_index_data(id, data, 0)
	return data

func remove_at(id:int):
	_null_data_list.remove_at(id)
	DataBase.insert(_server, g_man.dbms, _path, "id", id, 0)
	add_multi(id)

#
func remove_multi(id): _multi_null.delete(id, 1)
func add_multi(id): _multi_null.add_row(id, 1)
func last_id(): DataBase.last_id(_server, g_man.dbms, _path, "id")

func remove_all():
	var _count = last_id()
	for i in _count:
		remove_at(i)
