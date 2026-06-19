extends Node

const TEAM_COLORS: Dictionary[int, Color] = {
	0: Color(0.408, 0.468, 0.514, 1.0),
	1: Color(0.917, 0.822, 0.285, 1.0),
	2: Color(0.297, 0.626, 0.326, 1.0),
	3: Color(0.887, 0.287, 0.396, 1.0),
	4: Color(0.243, 0.429, 0.795, 1.0),
	5: Color(1.0, 1.0, 1.0, 1.0),
	6: Color(1.0, 1.0, 1.0, 1.0)
}

func get_team_color(team: int) -> Color:
	return TEAM_COLORS.get(team, Color.WHITE)


func send_note(message) -> void:
	print("|NOTE|  " + str(message))

func send_error(message) -> void:
	print("|ERROR|  " + str(message))
