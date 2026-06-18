extends Node

enum Faction {PLAYER, NEUTRAL, AI1, AI2}

func send_note(message) -> void:
	print("|NOTE|  " + str(message))

func send_error(message) -> void:
	print("|ERROR|  " + str(message))
