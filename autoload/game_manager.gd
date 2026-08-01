extends Node2D

var unit_container: Node2D
var particle_container: Node2D
var structure_container: Node2D
var player_controller: PlayerController


# Data registered by the structure manager on _ready()
var alive_teams: Dictionary = {}
var structures_per_team: Dictionary = {}


#func try_send_units(request: UnitSendRequest) -> void:
	#if not request.source_id or not request.target_id:
		#Globals.send_error("source structure or target structure not selected")
		#return
#
	#if request.source_id == request.target_id:
		#Globals.send_error("source and target structure are the same")
		#return
#
	#StructureManager.request_send_units(request)


func start_match():
	alive_teams.clear()
	structures_per_team.clear()
	DebugMenu.set_val("Is game over?", false)

# called by structure manager on game start. increases the team's structure count***
func register_structure_to_team(team: int) -> void:
	if team == 0:
		return
	
	if not structures_per_team.has(team):
		structures_per_team[team] = 0
	structures_per_team[team] += 1
	
	DebugMenu.set_val("Team " + str(team) + " structures", structures_per_team[team])


func unregister_structure_from_team(team: int)  -> void:
	if not structures_per_team.has(team):
		return
	structures_per_team[team] -= 1
	check_team_defeat(team)
	
	DebugMenu.set_val("Team " + str(team) + " structures", structures_per_team[team])
	
	check_game_over()


func transfer_structure(old_team: int, new_team: int) -> void:
	unregister_structure_from_team(old_team)
	register_structure_to_team(new_team)

func check_team_defeat(team: int) -> void:
	if structures_per_team[team] <= 0:
		alive_teams.erase(team)

func check_game_over():
	if alive_teams.size() <= 1:
		end_match()


func end_match():
	print("Game over!")
	DebugMenu.set_val("Is game over?", true)
