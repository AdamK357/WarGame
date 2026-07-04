extends RefCounted
class_name BaseRequest

func to_dict() -> Dictionary:
	var dict := {}
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			dict[p.name] = get(p.name)
	return dict

static func from_dict(data: Dictionary, cls: Object) -> Object:
	var obj = cls.new()
	for p in obj.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var name = p.name
			if data.has(name):
				obj.set(name, data[name])
	return obj
