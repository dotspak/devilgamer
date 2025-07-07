@icon("res://icons/stateMachine.png")
class_name StateMachine
extends Node

signal transitioned(state_name)

@export var initial_state: State

@onready var state : State = initial_state

var transitions_by_name: Dictionary = {}

# ---------------------------------------------------------------------
# Lifecycle methods
# ---------------------------------------------------------------------

func _ready() -> void:
	await owner.ready
	# The state machine assigns itself to the State objects' state_machine property.
	for child : State in get_children():
		child.stateMachine = self
	state.enter()

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

func _process(delta: float) -> void:
	state.update(delta)

func _physics_process(delta: float) -> void:
	state.physics_update(delta)

# ---------------------------------------------------------------------
# API methods
# ---------------------------------------------------------------------

## Transitions the state machine to a new state.[br]
##
## @param target_state_name: The name of the state to transition to.[br]
## @return bool: Returns true if the transition was successful, and false if it wasn't.
func transition_to(target_state_name: String) -> bool:
	if not has_node(target_state_name):
		print("State not found: " + target_state_name)
		return false

	state.exit()
	state = get_node(target_state_name)
	state.enter()
	transitioned.emit(state.name)
	return true

## Adds a transition to the state machine.[br]
##
## @param transition_name: The name of the transition.[br]
## @param from: The name of the state to transition from, or an array of state names.[br]
## @param to: The name of the state to transition to.[br]
## @param condition: An optional callable that returns a boolean, which must be true for the transition to occur.[br]
## @return [StateMachine]
func add_transition(transition_name: String, from: Variant, to: String, condition: Variant=null, actions: Variant=null) -> StateMachine:
	var config := {
		"name": transition_name,
		"from": from,
		"to": to,
		"condition": condition,
		"actions": actions
	}

	# Create the transition
	if not (config.name in transitions_by_name):
		transitions_by_name[config.name] = []
	transitions_by_name[config.name].append(config)

	return self

## Triggers a transition by name.[br]
##
## @param transition_name: The name of the transition to trigger.[br]
## @return bool: Returns true if the transition was successful, and false if it wasn't.
func trigger_transition(transition_name: String) -> bool:
	if not (transition_name in transitions_by_name):
		push_error("Transition not found: " + transition_name)
		return false

	var transitions = transitions_by_name[transition_name] as Array[Dictionary]
	for transition in transitions:

		# Check `from` state
		if not (state.name in transition.from): continue

		# Check `condition`
		if "condition" in transition and transition.condition:
			if not transition.condition.call(): continue # Condition not met, do not transition
		
		# Transition to `to` state (if state exists)
		var transitioned_successfully = transition_to(transition.to)

		# Execute any `actions` on successful transition
		if transitioned_successfully and "actions" in transition and transition.actions:
			if transition.actions is Array:
				for action in transition.actions:
					action.call()
			else:
				transition.actions.call()
			return true

	# No transition was successful
	return false

func is_state(state_name : String) -> bool: return state.name == state_name
func get_state() -> String: return state.name
