class_name DataBase extends Node

func _init():
	var _table = Table.new("client")
	columns_client(_table, true)
	columns_client(_table, false)
	
	_table = Table.new("mac")
	_table.create_column(true, g_man.dbms, DataType.LONG, 1, "id_macs")
	_table.create_column(true, g_man.dbms, DataType.STRING, 40, "mac")
	
	_table = Table.new("s_client__mac")
	_table.create_column(true, g_man.dbms, DataType.INT, 1, "approved")
	_table.create_column(true, g_man.dbms, DataType.LONG, 1, "id_mac")
	
	
	
func columns_client(_table, server: bool):
	_table.create_column(server, g_man.dbms, DataType.STRING, 3256, "rsa private")
	_table.create_column(server, g_man.dbms, DataType.INT, 3256, "rsa public")
	_table.create_column(server, g_man.dbms, DataType.STRING, 30, "username")
	_table.create_column(server, g_man.dbms, DataType.STRING, 30, "password")
	_table.create_column(server, g_man.dbms, DataType.LONG, 1, "secret")
	
#region general table
#region table
enum DataType{
	ENULL = 0,
	BOOL = 1,
	INT = 2,
	FLOAT = 3,
	STRING = 4,
	VECTOR3 = 9,
	ARRAY = 28,
	LONG = 30 # my reservation
	#21 - 28 is array
	#29 max
}

class ColumnBase:
	func _init(dataType, tableName, columnName, length):
		_type = dataType
		_tableName = tableName
		_columnName = columnName
		_length = length
		
	var _type: DataType
	var _tableName: String
	var _columnName: String
	var _length: int

class Table:
	class Column:
		func _init(dataType, tableName, columnName, length):
			columnBase = ColumnBase.new(dataType, tableName, columnName, length)
		var columnBase: ColumnBase
	
	func _init(tableName : String):
		self._tableName = tableName
		
	var _tableName: String
	
	func create_column(server: bool, dataBaseDir: String, type: DataType, length: int, fileNameColumn: String):
		if length > 1 and type != 4:
			type = DataType.ARRAY
		var column = Column.new(type, _tableName, fileNameColumn, length)
		
		var path = DataBase.path(server, dataBaseDir, _tableName)
		
		#save Table
		if(not DirAccess.dir_exists_absolute(path)):
			DirAccess.make_dir_recursive_absolute(path)
		
		var fileName = String("{path}/{columnName}.meta".format({path = path, columnName = fileNameColumn}))
		var fileAccess = DataBase.file_create_or_rea_or_write(fileName, FileAccess.WRITE_READ)
		#fileAccess.seek(0)
		
		#length of file size per row
		var dataSize = column.columnBase._length
		fileAccess.store_32(dataSize)
		#we save column type
		fileAccess.store_8(type)
		#5Bytes in total for meta data
		fileAccess.close()
		
		fileAccess = DataBase.file_create_or_rea_or_write(String("{path}/{columnName}".format({path = path, columnName = fileNameColumn})), FileAccess.WRITE_READ)
#endregion table

#region FileSystem
	#region Path
#const metaDataLength = 5

static func path(server : bool, DataBaseDir : String, tableNamePath : String):
	var fullPath;
	if server:
		fullPath = String("{data}/{base}/sun/{path}".format({data = OS.get_user_data_dir(), base = DataBaseDir, path = tableNamePath}))
	else:
		fullPath = String("{data}/{base}/planet/{path}".format({data = OS.get_user_data_dir(), base = DataBaseDir, path = tableNamePath}))
	return fullPath
	#endregion Path
	#region file not overwriting
static func file_create_or_rea_or_write(file_path, file_mode : FileAccess.ModeFlags):
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
	var _path = path(server, dataBaseDir, tableName);
	if not DirAccess.dir_exists_absolute(String("{_path}").format({_path = _path, column = columnName})):
		printerr(String("directory doesn't exist server[{server}] table name[{tableName}] column[{columnName}]\n").format({server = server, tableName = tableName, columnName = columnName}))
		return ""
	return String("{path}/{columnName}").format({path = _path, columnName = columnName})
	#endregion dir exists
#endregion FileSystem

#region saveload backeup files
static func load_back(dir, i):
	var backStr = String("{dir}.b").format({dir = dir})
	if(! FileAccess.file_exists(backStr)):
		i = 0;
		return i
	var fileAccess = file_create_or_rea_or_write(backStr, FileAccess.READ)
	i = fileAccess.get_8()
	fileAccess.close()
	return i
	
static func save_back(dir, i):
	var fileAccess = file_create_or_rea_or_write(String("{dir}.b").format({dir = dir}), FileAccess.READ_WRITE)
	fileAccess.store_8(i)
	fileAccess.close()
	
	
static func save_back_data(_path, columnName, type, length, id, data):
	#save backeup
	if DirAccess.dir_exists_absolute(_path):
		#it has to overwrite it so that the last portion is available for reading string of a file
		var fileAccess = FileAccess.open(String("{path}/.backup").format({path = _path}), FileAccess.WRITE)
		fileAccess.store_32(length)
		fileAccess.store_8(type)
		fileAccess.store_64(id)
		fileAccess.store_buffer(data)
		var seek_position = 13 + get_data_length(type, length)
		fileAccess.seek(seek_position)
		fileAccess.store_string(columnName)#I could use buffer and I would know the length of the string!!!
		fileAccess.close()
		
static func load_back_data(_path, length):
	DirAccess.dir_exists_absolute(_path)
	var fileName = String("{path}.backup").format({path = _path})
	FileAccess.file_exists(fileName)
	var columnName = ""
	#get meta
	var fileAccess = FileAccess.open(String("{fileName}").format({fileName = fileName}), FileAccess.READ)
	length = fileAccess.get_32()
	var type = fileAccess.get_8()
	var id = fileAccess.get_64()
	var dataLength = get_data_length(type, length)
	var buffer = fileAccess.get_buffer(dataLength)
	var data
	var seek_position = 13 + get_data_length(type, length)
	#load filename
	fileAccess.seek(seek_position)
	while not fileAccess.eof_reached():
		data = fileAccess.get_8()
		#it'll read 0 if it's end of file so we must not set it
		if not fileAccess.eof_reached():
			columnName += char(data)
	fileAccess.close()
	
	fileAccess = file_create_or_rea_or_write(String("{path}{columnName}".format({path = _path, columnName = columnName})), FileAccess.READ_WRITE)
	fileAccess.seek(id * dataLength)
	fileAccess.store_buffer(buffer)
	fileAccess.close()
	save_back(_path, 0)
#endregion end saveload backeup files

#region header
static func get_header(fileName):
	fileName = String("{fileName}.meta").format({fileName = fileName})
	if not FileAccess.file_exists(fileName):
		return null
	var fileAccess = file_create_or_rea_or_write(fileName, FileAccess.READ)
	fileAccess.seek(0)
	var length = fileAccess.get_32()
	var type = fileAccess.get_8()
	return [length, type]
#endregion header

#region converting
#first 4 bytes are for data type
static func get_data_length(type: DataType, length):
	if type == DataType.BOOL:
		return 8
	if type == DataType.INT:
		return 8 #4 for int 8 for long
	if type == DataType.FLOAT:
		return 12
	if type == DataType.STRING:
		return 8 + length
	if type == DataType.VECTOR3:
		return 16
	if type == DataType.ARRAY:
		return 8 + 16 * length
	if type == DataType.LONG:
		return 12
#endregion converting


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
	var fileName = directory_exists(server, dataBaseDir, tableName, columnName);
	if not FileAccess.file_exists(String("{fileName}.meta").format({fileName = fileName})):
		push_error(String("Exception fileName: {fileName}.meta does not exist\n").format({fileName = columnName}))
		return
	#started creating a file
	save_back(path, 1);
	#///read column config
	var length
	var converted
	var fileAccess = file_create_or_rea_or_write(fileName, FileAccess.READ_WRITE)
	var metaData = get_header(fileName)
	length = metaData[0]
	if length == 0:
		push_error(String("something is wrong {fileName}").format({fileName = fileName}))
		return
	var dataLength = get_data_length(metaData[1], length)
	#convert data to bytes
	converted = var_to_bytes(data)
	if not type_check(converted[0], metaData[1]):
		return
	##4 in front because it is type variable saved with it
	if converted.size() > dataLength:
		if length > 1:
			converted[4] = length
		converted = converted.slice(0, dataLength)
	#save to backeup
	save_back_data(_path, columnName, metaData[1], length, id, converted);
	#backeup has been sucessfully written
	_path += "/"
	save_back(_path, 2)
	
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
	save_back(path, 0)
#endregion insert

#region type check
static func type_check(converted, metaData):
	if converted == metaData:
		return true
	#if it's converted int and meta data long
	if converted == 2 and (metaData == 30):
		return true
	if converted == 0:
		return true
	push_error(String("wrong data type is trying to be used data:[{converted}] / meta:[{metaData}]").format({converted = DataType.find_key(converted), metaData = DataType.find_key(metaData)}))
	return false
#endregion type check
#region select
static func select(server: bool, dataBaseDir, tableName, columnName, id: int):
		#if id < 1:
			#printerr("id is too small: [", id, "] ", get_stack())
			#return
		var fileName = directory_exists(server, dataBaseDir, tableName, columnName);
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
		var metaData = get_header(fileName)
		if metaData == null:
			return
		var length = metaData[0]
		intengrety = load_back(_path, intengrety)
		#Save backedUp file that we didn't save correctly to disc but to the bakedUpFile
		if intengrety == 2:
			load_back_data(_path, length)
		
		##read file section
		#get to the id section
		var dataLength = get_data_length(metaData[1], length)
		
		if not FileAccess.file_exists(fileName):
			return
		var fileAccess = FileAccess.open(fileName, FileAccess.READ)
		fileAccess.seek(dataLength * id)
		# needs to read 4 bytes more than it is needed to the process is skipped in the end
		var buffer = fileAccess.get_buffer(dataLength+4)

		fileAccess.close()
		if buffer.size() == 0:
			return
		if not type_check(buffer[0], metaData[1]):
			return
		var text = bytes_to_var(buffer)
		return text
		
static func last_id(server: bool, dataBaseDir, tableName, columnName):
	var fileName = directory_exists(server, dataBaseDir, tableName, columnName);
	if fileName == "":
		printerr(String("table does not exists: {tableName}\ncolumn: {columnName}").format({tableName = tableName, columnName = columnName}))
		return
	#we load intengrety of files in this path
	var intengrety = -1
	var _path = path(server, dataBaseDir, tableName)
	_path += '/';
	
	#read length
	var fileAccess = FileAccess.open(fileName, FileAccess.READ)
	var metaData = get_header(fileName)
	if metaData == null:
		fileAccess.close()
		return 0
	var length = metaData[0]
	
	intengrety = load_back(path, intengrety);
	#Save backedUp file that we didn't save correctly to disc but to the bakedUpFile
	if intengrety == 2:
		load_back_data(path, length);
	
	##read file section
	#get to the id section
	var dataLength = get_data_length(metaData[1], length)
	var totalLength = 0
	if FileAccess.file_exists(fileName):
		totalLength = fileAccess.get_length()
	@warning_ignore("integer_division")
	var idCount = (totalLength) / dataLength
	if fileAccess:
		fileAccess.close()
	return idCount
#endregion select

#region delete
static func delete_column(server: bool, dataBaseDir, tableName, columnName):
		var fileName = directory_exists(server, dataBaseDir, tableName, columnName)
		if fileName == null:
			return
		DirAccess.remove_absolute(fileName)
		DirAccess.remove_absolute(String("{fileName}.meta").format({fileName = fileName}))
#endregion delete
#endregion general table
#region multitable
## to quickly get left or right join or simply get reference from right id to left column or vise versa
class MultiTable:
	const PRI = "_id_pri"
	const SEC = "_id_sec"
	func _init(dataBaseDir, path):
		tableName = path
		dataBasePathText = dataBaseDir
		
		nlPrimaryColumn = NullList.new()
		nlSecondaryColumn = NullList.new()
		nlAllRows = NullList.new()
		#nlPrimaryMaster = NullList.new()
		
		var table = Table.new(path)
		table.create_column(true, dataBaseDir, DataType.LONG, 1, "id")
		table.create_column(true, dataBaseDir, DataType.LONG, 1, PRI)
		table.create_column(true, dataBaseDir, DataType.LONG, 1, SEC)
		var lastId = DataBase.last_id(true, dataBaseDir, path, "id")
		if lastId:
			for i in range(1, lastId):
				var id = DataBase.select(true, dataBaseDir, path, "id", i)
				if id != 0:
					var pri = DataBase.select(true, dataBaseDir, path, PRI, i)
					var sec = DataBase.select(true, dataBaseDir, path, SEC, i)
					add_row(pri, sec)
				
	var tableName:String
	var dataBasePathText:String
	var nlPrimaryColumn:NullList
	var nlSecondaryColumn:NullList
	var nlAllRows:NullList
	#var nlPrimaryMaster
	
	class Column:
		func _init(id):
			id = id
		var opositeColumn = {}
	class MultiColumn:
		func _init(_left, _right):
			left = _left
			right = _right
		var left
		var right
		var id = 0
	
	#///<summary>add row if it doesn't exist yet</summary>
	#///<param name="mainKey">if null add new row else overwrite row</param>
	#///<returns>id row is written on</returns>
	func add_row(pri, sec):
		if pri == 0 || sec == 0:
			printerr(String("cannot make multi key too little info {pri} {sec} on {tableNameText}\n{stack}").format({pri = pri, sec = sec, tableNameText = tableName, stack = get_stack()}))
		#if(primary == 0 || secondary == 0){Debug.LogError($"cannot make multi key too little info {mainKey} {primary} {secondary} on {tableNameText}"); return 0;}
		var pc = nlPrimaryColumn.get_index_data(pri)
		var sc = nlSecondaryColumn.get_index_data(sec)
		
		#we create row if it doesn't exist
		if pc == null:
			pc = Column.new(pri)
			nlPrimaryColumn.set_index_data(pri, pc)
		if sc == null:
			sc = Column.new(sec)
			nlSecondaryColumn.set_index_data(sec, sc)
			
		#if mainKey != 0:
			#var mc = nlAllRows.get_index_data(mainKey)
			#if mc != null:
				#Delete(mainKey)
		#else:
		#//we stop if it already exists on both ends 1 should be enough
		if pc.opositeColumn.has(sec):
			return pc.opositeColumn[sec]
		elif sc.opositeColumn.has(pri):
			push_error(String("when does this happen [{tableNameText}] [{pri}] [{columnDataPri}] [{sec}]").format({tableNameText = tableName, pri = pri, columnDataPri = sc.opositeColumn[pri], sec = sec}))
			return sc.opositeColumn[pri]
		#//we add savable rows for database
		var row = MultiColumn.new(pri, sec);
		#main key should never be given in
		#if mainKey == 0:
		row.id = nlAllRows.set_data(row);
#
		#//if it doesn't exist on other end
		pc.opositeColumn[sec] = row.id
		sc.opositeColumn[pri] = row.id
		
		DataBase.insert(true, dataBasePathText, tableName, "id", row.id, row.id, "equals")
		DataBase.insert(true, dataBasePathText, tableName, PRI, row.id, row.left, "equals");
		DataBase.insert(true, dataBasePathText, tableName, SEC, row.id, row.right, "equals");
		return row.id
	
	func delete_row(idRow: int):
		var mc = nlAllRows.get_index_data(idRow);
		if mc != null:
			
			var leftC = nlPrimaryColumn.get_index_data(mc.left);
			leftC.opositeColumn.erase(mc.right);
			
			var rightC = nlSecondaryColumn.get_index_data(mc.right);
			rightC.opositeColumn.erase(mc.left);
			
			DataBase.insert(true, dataBasePathText, tableName, "id", mc.id, 0, "equals");
			nlAllRows.remove_at(mc.id);
		else:
			printerr(String("you want to delete row: {idRow} which doesn't exist").format({idRow = idRow}));
	
	#///<summary>
	#/// if it returns 0 nothing was deleted
	#/// if one is 0 all rows are deleted with that oposite id - last idRow is returned
	#/// </summary>
	func delete(left, right):
		#Debug.LogError(nslPrimaryColumn.get_index_data(left).opositeColumn[right]);
		var ret = 0;
		var lc = nlPrimaryColumn.get_index_data(left);
		if lc != null:
			#delete all rows with right from left id
			if right == 0:
				#get left column 
				var colLeft = nlPrimaryColumn.get_index_data(left);
				if colLeft == null:
					return 0;
				#get all right keys
				var arrayRight = colLeft.opositeColumn.keys()
				for keyRight in arrayRight:
					ret = lc.opositeColumn[keyRight]
				#foreach (var keyRight in arrayRight)
				#{
					#ret = lc.opositeColumn[keyRight];
					#//delete from left column all right keys
					#// lc.opositeColumn.Remove(keyRight);
					#// //delete from right columns all left keys
					#// nlSecondaryMaster.get_index_data(keyRight).opositeColumn.Remove(left);
#
					var mc = nlAllRows.get_index_data(ret)
					if mc != null:
						delete_row(ret);
				return ret
				#end of deleting all rows with all right with left id
			if lc.opositeColumn.has(right):
				ret = lc.opositeColumn[right];
				#//delete from left column the right value
				#// lc.opositeColumn.Remove(right);
				#// //delete from right column just 1 left value
				#// nlSecondaryMaster.get_index_data(right).opositeColumn.Remove(left);

				var mc = nlAllRows.get_index_data(ret);
				if mc != null:
					delete_row(ret);
		var rc = nlSecondaryColumn.get_index_data(right);
		if rc != null:
			#//delete all rows with right from left id
			if left == 0:
				var colRight = nlSecondaryColumn.get_index_data(right);
				if colRight == null:
					return 0;
				#get all left keys
				var arrayLeft = colRight.opositeColumn.keys()
				for keyLeft in arrayLeft:
					ret = rc.opositeColumn[keyLeft];
					#//delete from right column all left keys
					#// rc.opositeColumn.Remove(keyLeft);
					#// //delete from right columns just 1 left key
					#// nlPrimaryMaster.get_index_data(keyLeft).opositeColumn.Remove(right);
#
					var mc = nlAllRows.get_index_data(ret);
					if mc != null:
						delete_row(ret);
				return ret;
				#//end of deleting all rows with all right with left id
			if rc.opositeColumn.has(left):
				ret = rc.opositeColumn[left];
				#//delete from right column the left value
				#// rc.opositeColumn.Remove(left);
				#// //delete from left column just 1 right value
				#// nlPrimaryMaster.get_index_data(left).opositeColumn.Remove(right);
#
				var mc = nlAllRows.get_index_data(ret);
				#//so that we get rid of error row does not exist as we are destroying it double times
				if mc != null:
					delete_row(ret);
		return ret;
	
	func count(idPrimary: int, idSecondary: int):
		if idPrimary != 0:
			var colP = nlPrimaryColumn.get_index_data(idPrimary)
			if colP == null:
				return 0
			return colP.opositeColumn.size();
		if idSecondary == 0:
			return 0
		var colS = nlSecondaryColumn.get_index_data(idSecondary);
		if colS == null:
			return 0
		return colS.opositeColumn.size()
	
	## full rows no exceptions even duplicates
	func select_left_row(startAt := 0, length := 0):
		startAt = max(0, startAt)
		var _count = nlAllRows.count()
		var newCount = _count
		if length != 0:
			newCount = min(_count, startAt + length)
		var array = []
		for i in range(startAt, newCount):
			var mc = nlAllRows.get_index_data(i + 1 + startAt)
			if mc:
				array.append(mc.left)
		return array
	
	## full rows no exceptions even duplicates
	## <returns>all ids from right row</returns>
	func select_right_row(startAt = 0, length = 0):
		startAt = max(0, startAt)
		var _count = nlAllRows.count();
		var newCount = _count;
		if length != 0:
			newCount = min(_count, startAt + length)
		var array = []
		for i in range(startAt, newCount):
			var mc = nlAllRows.get_index_data(i + 1 + startAt)
			if mc:
				array.append(mc.right)
		return array;
	
	
	
	## if you set id for something you'll get oposite. if both are set something you get inner join</summary>
	## idPrimary left join
	## idSecondary right join
	## returns if both are being set it's left and right use with caution as left and right could be 2 same numbers</returns>
	func select(idPrimary, idSecondary):
		if idPrimary != 0 && idSecondary != 0:
			# It returns both IDs from left and right. It should be used only for checking if any ROW exists.
			var colp = nlPrimaryColumn.get_index_data(idPrimary)
			if colp == null:
				return []
			var p = colp.opositeColumn.keys()
			var cols = nlSecondaryColumn.get_index_data(idSecondary)
			if cols == null:
				return []
			var s = cols.opositeColumn.keys()
			for item in s:
				if not p.has(item):
					p.append(item)
			return p
		elif idPrimary != 0:
			var col = nlPrimaryColumn.get_index_data(idPrimary)
			if col == null:
				return []
			return col.opositeColumn.keys()
		elif idSecondary != 0:
			var col = nlSecondaryColumn.get_index_data(idSecondary)
			if col == null:
				return []
			return col.opositeColumn.keys()
		return []
	
	
	
	
	
	func select_range(idPrimary, idSecondary, start_at, _count):
		start_at = max(0, start_at)
		if idPrimary != 0 && idSecondary != 0:
			#Debug.log("check if correct CONFIGURED as now it's tested and working " + str(start_at) + ", " + str(_count) + " TEST them all only after test remove each one by one!!!")
			var colp = nlPrimaryColumn.get_index_data(idPrimary)
			if colp == null:
				#Debug.log("0 returns length: 0")
				return []
			var p = colp.opositeColumn.keys()
			var cols = nlSecondaryColumn.get_index_data(idSecondary)
			if cols == null:
				#Debug.log("1 returns length: 0")
				return []
			var s = cols.opositeColumn.keys()

			start_at = min(start_at + _count, s.size()) - _count
			start_at = max(0, start_at)

			for i in range(_count):
				if not p.has(s[i]):
					p.append(s[i])
			#Debug.log("0 returns length: " + str(p.size()) + " " + str(_count))
			return p.to_array()
		elif idPrimary != 0:
			var col = nlPrimaryColumn.get_index_data(idPrimary)
			if col == null:
				#Debug.log("2 returns length: 0")
				return []

			start_at = min(start_at + _count, col.opositeColumn.size()) - _count
			start_at = max(0, start_at)

			var ret = null
			for i in range(_count):
				if col.opositeColumn.size() > start_at + i:
					ret.append(col.opositeColumn.keys()[start_at + i])
			return ret
		elif idSecondary != 0:
			var col = nlSecondaryColumn.get_index_data(idSecondary)
			if col == null:
				#Debug.log("3 returns length: 0")
				return []
			
			start_at = min(start_at + _count, col.opositeColumn.size()) - _count
			start_at = max(0, start_at)

			var ret = null
			for i in range(_count):
				if col.opositeColumn.size() > start_at + i:
					ret.append(col.opositeColumn.keys()[start_at + i])
			#Debug.log("2 returns length: " + str(ret.size()) + " " + str(_count))
			return ret
		#Debug.log("idPrimary and idSecondary are both 0 so it returns long[0]")
		return []
	
	
	## get oposite ids
	func select_id_row_p_s(idPrimary, idSecondary):
		if idPrimary != 0:
			var col = nlPrimaryColumn.get_index_data(idPrimary)
			if col == null:
				return 0
			if col.opositeColumn.has(idSecondary):
				return col.opositeColumn[idSecondary]
			return 0

	## get oposite id rows
	func select_id_rows(idPrimary, idSecondary):
		var ids = []
		if idPrimary == 0:
			var col = nlSecondaryColumn.get_index_data(idSecondary)
			if col:
				ids = col.opositeColumn.values()
		else:
			var col = nlPrimaryColumn.get_index_data(idPrimary)
			if col:
				ids = col.opositeColumn.values()
		return ids

	## get oposite ids
	func select_oposite_ids(idPrimary, idSecondary):
		var ids = []
		if idPrimary == 0:
			var col = nlSecondaryColumn.get_index_data(idSecondary)
			if col:
				ids = col.opositeColumn.keys()
		elif idSecondary == 0:
			var col = nlPrimaryColumn.get_index_data(idPrimary)
			if col:
				ids = col.opositeColumn.keys()
		return ids

	## get p, s from specific row
	func select_id_row(idRow):
		var two = []
		var mc = nlAllRows.get_index_data(idRow)
		if mc == null:
			return 0
		two.append(mc.left)
		two.append(mc.right)
		return two

	func left_join(ids):
		var left = {}
		for id in ids:
			left[id] = select_oposite_ids(id, 0)
		var list = []
		for item in left:
			for lon in left[item]:
				if not list.has(lon):
					list.append(lon)
		return list.to_array()
	
	
	func right_join(ids):
		var right = {}
		for id in ids:
			right[id] = select_oposite_ids(0, id)
		var list = []
		for item in right:
			for lon in right[item]:
				if not list.has(lon):
					list.append(lon)
		return list.to_array()

	func last_id():
		return nlAllRows.count()

	func clear():
		var _count = last_id()
		for i in range(1, _count + 1):
			delete_row(i)
#endregion multitable

#TODO:
	#public enum Operating{
		#/// <summary>
		#/// it only overwrites data that was given everything that's later on array it's left as it is
		#/// </summary>
		#equals,
		#/// <summary>
		#/// it overwrites all array if it's 0 data it writes 0 to the end of array
		#/// </summary>
		#overwrite,
		#plus,
		#minus,
		#multiply,
		#divide
	
	
	## manual:
	## create normal table
	## var table = DataBase.Table.new("tableName")
	## 
	## create column / attribute
	## table.create_column(true, "DBMS root", DataType.long, 1, "attribut")
	##
	## Create multi table connection between 2 tables
	## var multiTable = DataBase.MultiTable.new("DBMS root", "tableName")
	## you need to store this one because it has stored values in RAM indexes about full table
	##
	## Create link between 2 tables
	## multiTable.add_row(123, 321)
	##
	## Delete row or certain links
	## multiTable.delete(0, 321) <- deletes all links on left side linked to right row 321
