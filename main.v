module main

import linklancien.decision_graph { Node, Action_node, Conditionnal_node }
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
	app.gobs << create_basic()
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

fn is_working(data App) bool {
	return data.gobs[data.id].doing == .working
}

fn work_fn(mut data App) {
	println('I, ${data.id}, am working')
	data.gobs[data.id].doing = .idle
}

fn idle_fn(mut data App) {
	println('I, ${data.id}, am juste chilling')
	data.gobs[data.id].doing = .working
}

// Use:
fn (gob Gobs) reflect(mut app App) {
	gob.brain.do(mut app)
}
