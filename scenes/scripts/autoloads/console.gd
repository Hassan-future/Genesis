extends Node

@warning_ignore("unused_signal")
signal output







func _time_request() -> String:
	var time = Time.get_time_dict_from_system()
	var time_text = ("%02d:%02d:%02d" % [time.hour, time.minute, time.second])
	return time_text


func _date_request() -> String:
	var date = Time.get_date_dict_from_system()
	var date_text = ("%04d:%02d:%02d" % [date.year, date.month, date.day])
	return date_text
