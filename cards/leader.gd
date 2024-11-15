class_name Leader
extends Card

@export var is_leader_optional_or_undecided: bool = false  # whether the card can act on soldiers only
@export var apply_to_leader: bool = true  # if leader is optional, whether applies to leader
@export var leader_territory: int = -1  # leader territory when effect triggered, need to store as leader can move


func _ready() -> void:
	self.card_type = "leader"
	super._ready()


func reset_card():
	self.is_leader_optional_or_undecided = false
	self.apply_to_leader = true
	super.reset_card()


func update_card_on_selection():
	# specific to leader, get initial leader territory and store it
	self.leader_territory = TerritoryHelper.get_player_leader_occupied(GameState.current_player)
