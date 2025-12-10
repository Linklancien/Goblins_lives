module main

import linklancien.decision_graph as deci
import linklancien.gg_plot
import gg

struct App {
mut:
	ctx &gg.Context = unsafe { nil }
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
		frame_fn:     on_frame
		sample_count: 4
	)

	app.ctx.run()
}

fn on_frame(mut app App){

}
