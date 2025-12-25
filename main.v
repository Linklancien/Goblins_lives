module main

import linklancien.decision_graph { Action_node, Conditionnal_node, Node, Result }
import rand
// import linklancien.gg_plot
import gg

// Welt
struct Welt {
mut:
	ctx  &gg.Context = unsafe { nil }
	wood int
	gobs []Gobs
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
		name :=  Name.from(int(current_task)) or {
			panic('error, current_task could not change in apply')
		}
		welt.gobs[id].current_task = create_from_name(name)
	}
	if wood_cut := changes['wood']{
		welt.wood += int(wood_cut)
	}
}

fn main() {
	mut welt := &Welt{}
	welt.ctx = gg.new_context(
		fullscreen:    false
		width:         600
		height:        600
		create_window: true
		window_title:  '-Goblins Lives-'
		bg_color:      gg.gray
		user_data:     welt
		frame_fn:      on_frame
		sample_count:  4
	)
	welt.gobs << create_basic()
	// welt.gobs << creat_random(2, 0.5)
	println(welt.gobs)
	welt.ctx.run()
}

fn on_frame(mut welt Welt) {
	for i, mut gob in mut welt.gobs{
		umwelt := welt.get_umwelt(i)
		gob.current_task.update(umwelt)
		println('time: ${gob.current_task.timer}')
	}
	
	for i, gob in welt.gobs {
		gob.reflect(mut welt, i)
	}
	println('wood: ${welt.wood}')
}

// Gobs
struct Gobs {
	brain Node
mut:
	current_task Task
}

// Task
struct Task{
mut:
  name Name
  state States
  timer int // u8 ?
}

enum Name{
	idle
	woodcutting
}

enum States{
  ended
  working
  blocked
}

fn create_from_name(name Name) &Task{
	match name{
		.idle{
			return &Task{}
		}
		.woodcutting{
			return &Task{
				name: name
				state: .working
				timer: 10 //init time for this task
			}
		}
	}
}

// a: handle the case where the task is idle
// b: ckeck if timer <= 0 returns the result of the task
// c: find witch task is currently in progress
// d: check if the work can be done - (if not change state to blocked so returns)
// e: if it can be done, timer -= 1 an returns
fn (mut task Task) update(umwelt Result) Result{
	// a:
	if task.name == .idle {
		return Result{}
	}
	
	// b:
	if task.timer <= 0{
		task.state = .ended
		return task.effect()
	}
	
	// c:
	// d:
	// e:
	doable := task.is_doable(umwelt)
	match task.state{
		.working{
			if doable{
				task.timer -= 1
			}
			else{
				task.state = .blocked	
			}
		}
		.blocked{
			if doable{
				task.state = .working	
			}
		}
		else{}
	}
	return Result{}
}

fn (task Task) is_doable(umwelt Result) bool{
	match task.name{
		.woodcutting{
			return true
			// return umwelt['localisation'] == 1.0
		}
		else{}
	}
	panic('Case not handled in is_doable ${task}, ${umwelt}')
}

fn (task Task) effect() Result{
	mut res := Result{}
	match task.name{
		.woodcutting{
			res["wood"] = 1
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
			evaluation: is_ended
			true_next:  Action_node{
				action: change_to_woodcutting
			}
		}
	}
}

fn creat_random(depth int, proba_action f64) &Gobs {
	brain := random_brain(depth, proba_action)
	return &Gobs{
		brain: brain
	}
}

fn random_brain(depth int, proba_action f64) Node {
	mut node := Node{}

	if depth == 0 && rand.bernoulli(proba_action) or { panic('Bernouilli failled ${depth}') } {
		// asfn := [change_to_work_fn, change_to_idle_fn, work_fn]
		// afn := rand.element[Action_fn](asfn) or {
		// 	panic('At depth == ${depth}, rand action failled with prob: ${proba_action}')
		// }
		// node = Action_node{
		// 	action: afn²
		// }
	} else {
		// csfn := [is_exhaust, is_working]
		// cfn := rand.element[Evaluation_fn](csfn) or {
		// 	panic('At depth == ${depth}, rand conditionnal failled with prob: ${proba_action}')
		// }
		// nodet := random_brain(depth - 1, proba_action)
		// nodef := random_brain(depth - 1, proba_action)

		// node = Conditionnal_node{
		// 	evaluation: cfn
		// 	true_next:  nodet
		// 	false_next: nodef
		// }
	}

	return node
}

// brain neurones
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

// Use:
fn (gob Gobs) reflect(mut welt Welt, id int) {
	// reflect
	res := gob.brain.do(welt.get_umwelt(id))
	// act
	welt.apply(res, id)
}
