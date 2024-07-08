class_name SavableMulti extends Node

func _init(server: bool, dbms: String, path: String, default_class):
	_default_class = default_class
	_savable = Savable.new(server, dbms, path, default_class)
	var path_multi = path# String("multi_{path}_{server}").format({path = path, server = server})
	_multi = DataBase.MultiTable.new(dbms, path_multi)
	#_multi.add_row(0, 0)
	

var _savable: Savable
var _multi: DataBase.MultiTable
var _default_class

func get_id_rows(idPrimary: int, idSecondary: int):
	return _multi.select_id_row_p_s(idPrimary, idSecondary)
	
func get_left_rows():
	return _multi.select_left_row();
	
func get_rigth_rows():
	return _multi.select_right_row();
	
func try_get_p_s(idPrimary: int, idSecondary: int):
	var id_row = _multi.select_id_row_p_s(idPrimary, idSecondary)
	if id_row != 0:
		return _savable.get_index_data(id_row)
	return null
	
## get all data for the opposite column
func get_all(idPrimary: int, idSecondary: int):
	if idPrimary != 0 && idSecondary != 0:
		var row = get_id_rows(idPrimary, idSecondary)
		return get_index_data(row)
	else:
		var rows = []
		var id_rows = _multi.select(idPrimary, idSecondary)
		rows.resize(len(id_rows))
		for i in len(id_rows):
			var p = idPrimary
			var s = idSecondary
			if idPrimary == 0:
				p = id_rows[i]
			if idSecondary == 0:
				s = id_rows[i]
			rows[i] = _multi.select_id_row_p_s(p, s)
		var ret = []
		ret.resize(len(rows))
		for i in len(rows):
			ret[i] = get_index_data(rows[i])
		return ret
## if both columns are set and something exists old is returned
## idPrimary is usually something
## idSecondary is usually 0
## returns New data and an opposite column is made by SavableId
func new_data(idPrimary: int, idSecondary: int):
	var idRow = _multi.select_id_row_p_s(idPrimary, idSecondary)
	if idRow != 0:
		return _savable.get_index_data(idRow)
	var data = _default_class.copy()
	if idPrimary != 0:
		_savable.set_data(data)
		_multi.add_row(idPrimary, data.id)
		return data
	if idSecondary != 0:
		_savable.set_data(data)
		_multi.add_row(data.id, idSecondary)
		return data
	printerr(String("{data} has not ben set correctly and base is empty").format({data = data.to_string()}))
	return data
	
## if it doesn't exist it creates on idRow if more exists it takes only first row
## if idPrimary 0 it tries to fetch it from other row
## if idSecondary 0 it tries to fetch it from other row
## returns new or old if exists on idRow
func get_p_s_data(idPrimary: int, idSecondary:int):
	if idPrimary == 0:
		var id_rows = _multi.select(0, idSecondary)
		if len(id_rows) > 0:
			idPrimary = id_rows[0]
	elif idSecondary == 0:
		var id_rows = _multi.select(idPrimary, 0)
		if len(id_rows) > 0:
			idSecondary = id_rows[0]
	var id_row = _multi.add_row(idPrimary, idSecondary)
	var data = _savable.get_index_data(id_row)
	#if it doesn't exist on the disc create one
	if data == null:
		data = _default_class.copy()
		#save on a disc
		_savable.set_index_data(id_row, data)
	return data

#func TryGet(idRow: int):
	#var data = get_index_data(idRow)
	#return data
	
func get_index_data(idRow: int):
	return _savable.get_index_data(idRow);

## deletes only 1 row WARNING if 1 column is 0 it deletes all references but not the data needs update
func delete_p_s(idPrimary: int, idSecondary: int) -> void:
	var id_row = _multi.delete(idPrimary, idSecondary)
	if id_row != 0:
		_savable.remove_at(id_row)

func delete_id_row(idRow: int):
	_multi.delete_row(idRow)
	_savable.remove_at(idRow);
func RemoveAll():
	_multi.clear()
	_savable.remove_all()
