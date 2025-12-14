module main

import linklancien.decision_graph { Action_fn, Action_node, Conditionnal_node, Evaluation_fn, Node }
import rand
// import linklancien.gg_plot
import gg

struct App {
mut:
	ctx  &gg.Context = unsafe { nil }
	id   int
	gobs []Gobs
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		fullscreen:    false
		width:         600
		height:        600
		create_window: true
		window_title:  '-Goblins Lives-'
		bg_color:      gg.gray
		user_data:     app
		frame_fn:      on_frame
		sample_count:  4
	)
	// app.gobs << create_basic()
	app.gobs << creat_random(2, 0.5)
	println(app.gobs)
	app.ctx.run()
}

fn on_frame(mut app App) {
	for i, gob in app.gobs {
		app.id = i
		gob.reflect(mut app)
	}
}

// Gobs
struct Gobs {
	brain Node[App]
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
		brain: Conditionnal_node[App]{
			evaluation: is_working
			true_next:  Action_node[App]{
				action: work_fn
			}
			false_next: Action_node[App]{
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

fn random_brain(depth int, proba_action f64) Node[App] {
	mut node := Node[App]{}

	if depth == 0 && rand.bernoulli(proba_action) or { panic('Bernouilli failled ${depth}') } {
		asfn := [idle_fn, exhaust_fn, work_fn]
		afn := rand.element[Action_fn[App]](asfn) or {
			panic('At depth == ${depth}, rand action failled with prob: ${proba_action}')
		}
		node = Action_node[App]{
			action: afn
		}
	} else {
		csfn := [is_exhaust, is_working]
		cfn := rand.element[Evaluation_fn[App]](csfn) or {
			panic('At depth == ${depth}, rand conditionnal failled with prob: ${proba_action}')
		}
		nodet := random_brain(depth - 1, proba_action)
		nodef := random_brain(depth - 1, proba_action)

		node = Conditionnal_node[App]{
			evaluation: cfn
			true_next:  nodet
			false_next: nodef
		}
	}

	return node
}

// brain neurones
// conditional
fn is_exhaust(data App) bool {
	return data.gobs[data.id].doing == .exhaust
}

fn is_working(data App) bool {
	return data.gobs[data.id].doing == .working
}

// actions
fn idle_fn(mut data App) {
	println('I, ${data.id}, am juste chilling')
	data.gobs[data.id].doing = .working
}

fn exhaust_fn(mut data App) {
	println('I, ${data.id}, am not exhaust anymore')
	data.gobs[data.id].doing = .idle
}

fn work_fn(mut data App) {
	println('I, ${data.id}, am working')
	data.gobs[data.id].doing = .exhaust
}

// Use:
fn (gob Gobs) reflect(mut app App) {
	gob.brain.do(mut app)
}
