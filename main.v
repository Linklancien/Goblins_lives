module main

import linklancien.decision_graph { Action_node, Conditionnal_node, Node, Result }
import rand
// import linklancien.gg_plot
import gg

struct Welt {
mut:
	ctx  &gg.Context = unsafe { nil }
	gobs []Gobs
}

fn (welt Welt) get_umwelt(id int) Result {
	mut umwelt := Result{}
	umwelt['doing'] = int(welt.gobs[id].doing)
	return umwelt
}

fn (mut welt Welt) apply(changes Result, id int) {
	if doing_int := changes['doing'] {
		// change the current task of the selected gob
		welt.gobs[id].doing = Task.from(int(doing_int)) or {
			panic('error, doing could not change in apply')
		}
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
	for i, gob in welt.gobs {
		gob.reflect(mut welt, i)
	}
}

// Gobs
struct Gobs {
	brain Node
mut:
	doing Task
}

enum Task {
	idle
	exhaust
	working
}

// Init:
fn create_basic() &Gobs {
	return &Gobs{
		brain: Conditionnal_node{
			evaluation: is_working
			true_next:  Action_node{
				action: work_fn
			}
			false_next: Action_node{
				action: idle_fn
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
		// asfn := [idle_fn, exhaust_fn, work_fn]
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
	return is_key_equal_value(umwelt, 'doing', int(Task.exhaust))
}

fn is_working(umwelt Result) bool {
	println('Am I working ? ${umwelt['doing'] == int(Task.working)} ')
	return is_key_equal_value(umwelt, 'doing', int(Task.working))
}

// actions
fn action_fn(umwelt Result, key string, value int) Result{
	mut res := Result{}
	res[key] = value
	return res
}

fn idle_fn(umwelt Result) Result {
	println('I, am juste chilling')
	return action_fn(umwelt, 'doing', int(Task.working))
}

fn exhaust_fn(umwelt Result) Result {
	println('I, am not exhaust anymore')
	return  action_fn(umwelt, 'doing', int(Task.idle))
}

fn work_fn(umwelt Result) Result {
	println('I, am working')
	return  action_fn(umwelt, 'doing', int(Task.exhaust))
}

// Use:
fn (gob Gobs) reflect(mut welt Welt, id int) {
	// reflect
	res := gob.brain.do(welt.get_umwelt(id))
	// act
	welt.apply(res, id)
}
