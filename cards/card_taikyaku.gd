extends Card


func _ready() -> void:
	card_name = "TaiKyaku/ Retreat"
	_card_name = "taikyaku"
	card_name_jp = "退却"
	description = "Return 2 of your soldiers to hand from any number of territories."
	effect = [
		{"deploy": -1, "player": "current", "territory_selection_required": true, "emit": true},
		{"deploy": -1, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have at least one two soldiers on the board.
	"""
	
	if GameState.players[player]["soldier"] > GameState.total_soldiers - 2:
		return false
	
	return true


func get_card_step_territories(step: int) -> Array:
	# step 1 and 2: soldier occupied
	if step == 0 or step == 1:
		return TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
	
	return []
