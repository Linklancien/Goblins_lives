module main

import linklancien.decision_graph { Action_node, Conditionnal_node, Node, Result }
import rand
import linklancien.gg_plot
import gg

const csfn = [is_wood_cutting, is_blocked, is_ended, is_working]
const csfn_name = ['is_wood_cutting', 'is_blocked', 'is_ended', 'is_working']
const asfn = [change_to_woodcutting, change_to_idle]
const asfn_name = ['change_to_woodcutting', 'change_to_idle']

// Welt
struct Welt {
mut:
	ctx  &gg.Context = unsafe { nil }
	wood int
	gobs []Gobs
	time int
	dia  gg_plot.Diagram
}

fn (welt Welt) get_umwelt(id int) Result {
	mut umwelt := Result{}
	umwelt['task_name'] = int(welt.gobs[id].current_task.name)
	umwelt['task_state'] = int(welt.gobs[id].current_task.state)
	umwelt['task_timer'] = int(welt.gobs[id].current_task.state)
	return umwelt
}

fn (mut welt Welt) apply(changes Result, id int) {
	if current_task := changes['task_name'] {
		// change the current task of the selected gob
		name := Name.from(int(current_task)) or {
			panic('error, current_task could not change in apply')
		}
		welt.gobs[id].current_task = create_task_from_name(name)
	}
	if wood_cut := changes['wood'] {
		welt.wood += int(wood_cut)
	}
}

fn main() {
	mut welt := &Welt{}
	welt.ctx = gg.new_context(
		fullscreen:    false
		width:         600 + 2 * 50
		height:        500 + 2 * 50
		create_window: true
		window_title:  '-Goblins Lives-'
		bg_color:      gg.gray
		user_data:     welt
		frame_fn:      on_frame
		sample_count:  4
	)
	welt.gobs << create_basic()
	// welt.gobs << creat_random(2, 0.5)
	print(welt.gobs)
	welt.dia = gg_plot.plot([[f32(0)]], [[f32(0)]], [gg.red])
	welt.dia.change_pos(50, 50)
	welt.dia.change_size(600, 500)
	welt.dia.border_size(30)
	welt.dia.corner_size(15)
	welt.dia.title('Evolution of the quantity of wood')
	welt.dia.x_label('Time in frames')
	welt.dia.y_label('Wood in red')

	welt.ctx.run()
}

fn on_frame(mut welt Welt) {
	welt.time += 1
	// updates
	for i, mut gob in mut welt.gobs {
		umwelt := welt.get_umwelt(i)
		res := gob.current_task.update(umwelt)
		// act
		welt.apply(res, i)
	}

	for i, gob in welt.gobs {
		gob.reflect(mut welt, i)
	}

	welt.update_graph()

	// RENDER:
	welt.ctx.begin()
	welt.dia.render(welt.ctx)
	welt.ctx.end()
}

fn (mut welt Welt) update_graph() {
	welt.dia.extend_curve(0, [f32(welt.time)], [f32(welt.wood)])
}

// Gobs
struct Gobs {
	brain Node
mut:
	current_task Task
}

// Use:
fn (gob Gobs) reflect(mut welt Welt, id int) {
	// reflect
	res := gob.brain.do(welt.get_umwelt(id))
	// act
	welt.apply(res, id)
}

// Task
struct Task {
mut:
	name  Name
	state States
	timer int // u8 ?
}

enum Name {
	idle
	woodcutting
}

enum States {
	ended
	working
	blocked
}

fn create_task_from_name(name Name) &Task {
	match name {
		.idle {
			return &Task{}
		}
		.woodcutting {
			return &Task{
				name:  name
				state: .working
				timer: 10 // init time for this task
			}
		}
	}
}

// a: handle the case where the task is idle
// b: ckeck if timer <= 0 returns the result of the task
// c: find witch task is currently in progress
// d: check if the work can be done - (if not change state to blocked so returns)
// e: if it can be done, timer -= 1 an returns
fn (mut task Task) update(umwelt Result) Result {
	// a:
	if task.name == .idle {
		return Result{}
	}

	// b:
	if task.timer <= 0 {
		task.state = .ended
		return task.effect()
	}

	// c:
	// d:
	// e:
	doable := task.is_doable(umwelt)
	match task.state {
		.working {
			if doable {
				task.timer -= 1
			} else {
				task.state = .blocked
			}
		}
		.blocked {
			if doable {
				task.state = .working
			}
		}
		else {}
	}
	return Result{}
}

fn (task Task) is_doable(umwelt Result) bool {
	match task.name {
		.woodcutting {
			return true
			// return umwelt['localisation'] == 1.0
		}
		else {}
	}
	panic('Case not handled in is_doable ${task}, ${umwelt}')
}

fn (task Task) effect() Result {
	mut res := Result{}
	match task.name {
		.woodcutting {
			res['wood'] = 1
			return res
		}
		else {}
	}
	panic('Case not handled in effect ${task}')
}

// Init:
fn create_basic() &Gobs {
	return &Gobs{
		brain: Conditionnal_node{
			eval_name:  'is_ended'
			evaluation: is_ended
			true_next:  Action_node{
				name: 'change_to_woodcutting'
				action:     change_to_woodcutting
			}
		}
	}
}

// Form scratch
fn creat_random(depth int, proba_action f64) &Gobs {
	brain := random_neuron(depth, proba_action)
	return &Gobs{
		brain: brain
	}
}

fn random_neuron(depth int, proba_action f64) Node {
	mut node := Node{}

	if depth == 0 || rand.bernoulli(proba_action) or { panic('Bernouilli failled ${depth}') } {
		id := rand.int_in_range(0, asfn.len) or {
			panic('At depth == ${depth}, rand action failled with prob: ${proba_action}')
		}
		afn := asfn[id]
		afn_name := asfn_name[id]
		node = Action_node{
			name:   afn_name
			action: afn
		}
	} else {
		id := rand.int_in_range(0, csfn.len) or {
			panic('At depth == ${depth}, rand conditionnal failled with prob: ${proba_action}')
		}
		cfn := csfn[id]
		cfn_name := csfn_name[id]
		nodet := random_neuron(depth - 1, proba_action)
		nodef := random_neuron(depth - 1, proba_action)

		node = Conditionnal_node{
			eval_name:  cfn_name
			evaluation: cfn
			true_next:  nodet
			false_next: nodef
		}
	}

	return node
}

// brain neurons
// conditional
fn is_key_equal_value(umwelt Result, key string, value int) bool {
	return umwelt[key] == value
}

fn is_wood_cutting(umwelt Result) bool {
	return is_key_equal_value(umwelt, 'task_name', int(Name.woodcutting))
}

fn is_blocked(umwelt Result) bool {
	return is_key_equal_value(umwelt, 'task_state', int(States.blocked))
}

fn is_ended(umwelt Result) bool {
	return is_key_equal_value(umwelt, 'task_state', int(States.ended))
}

fn is_working(umwelt Result) bool {
	return is_key_equal_value(umwelt, 'task_state', int(States.working))
}

// actions
fn action_fn(umwelt Result, key string, value int) Result {
	mut res := Result{}
	res[key] = value
	return res
}

fn change_to_woodcutting(umwelt Result) Result {
	return action_fn(umwelt, 'task_name', int(Name.woodcutting))
}

fn change_to_idle(umwelt Result) Result {
	return action_fn(umwelt, 'task_name', int(Name.idle))
}

// fn change_to_exhaust(umwelt Result) Result {
// 	return action_fn(umwelt, 'task_name', int(Name.exhaust))
// }
