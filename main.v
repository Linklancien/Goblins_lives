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
		welt.gobs[id].current_task = Task.from(int(current_task)) or {
			panic('error, current_task could not change in apply')
		}
	}
	if wood_cut := changes['wood']{
		welt.wood += wood_cut
	}
}

fn main() {
	mut welt := &Welt{}
	welt.ctx = gg.new_context(
		fullscreen:    false
		width:         600
		height:        600
		create_window: true
		window_titlc:  '-Goblins Lives-'
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
	for i, gob in welt.gobs {
		gob.reflect(mut welt, i)
	}
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

enum Sates{
  working
  blocked
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
		return task.effect()
	}
	
	// c:
	// d:
	// e:
	doable := taks.is_doable(umwelt)
	match task.state{
		working{
			if doable{
				task.timer -= 1
			}
			else{
				task.state = .blocked	
			}
		}
		blocked{
			if doable{
				task.state = .working	
			}
		}
	}
	return Result{}
}

fn (task Task) is_doable(umwelt Result) bool{
	match task.name{
		woodcutting{
			return umwelt['localisation'] == 1.0
		}
	}
	panic('Case not handled ${task}, ${uwmelt}')
}

fn (task Task) effect() Result{
	mut res := Result{}
	match task.name{
		woodcutting{
			res["wood"] = 1
			return res
		}
	}
}

// Init:
fn create_basic() &Gobs {
	return &Gobs{
		brain: Conditionnal_node{
			evaluation: is_working
			true_next:  Action_node{
				action: change_to_idle
			}
			false_next: Action_node{
				action: change_to_work
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
		// 	action: afn
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

fn is_exhaust(umwelt Result) bool {
	return is_key_equal_value(umwelt, 'task_name', int(Task.exhaust))
}

fn is_working(umwelt Result) bool {
	println('Am I working ? ${umwelt['task_name'] == int(Task.working)} ')
	return is_key_equal_value(umwelt, 'task_name', int(Task.working))
}

// actions
fn action_fn(umwelt Result, key string, value int) Result {
	mut res := Result{}
	res[key] = value
	return res
}

fn change_to_work(umwelt Result) Result {
	println('I, am juste chilling')
	return action_fn(umwelt, 'task_name', int(Task.working))
}

fn change_to_idle(umwelt Result) Result {
	println('I, am not exhaust anymore')
	return action_fn(umwelt, 'task_name', int(Task.idle))
}

fn change_to_exhaust(umwelt Result) Result {
	println('I, am working')
	return action_fn(umwelt, 'task_name', int(Task.exhaust))
}

