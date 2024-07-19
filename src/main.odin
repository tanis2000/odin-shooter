package game

import "base:runtime"
//import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"
import mui "vendor:microui"
//import "core:strings"

WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

Player :: struct {
	name: string,
}

EntityVariant :: union {
	Player,
}

Entity :: struct {
	position: [3]f32,
	variant:  EntityVariant,
}

state := struct {
	ctx:             runtime.Context,
	screen_width:    int,
	screen_height:   int,
	//current_keys: [dynamic]rl.KeyboardKey,
	//previous_keys: [dynamic]rl.KeyboardKey,
	quit_requested:  bool,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	mui_ctx:         mui.Context,
	bg:              mui.Color,
	os:              OS,
	renderer:        Renderer,
	cursor:          [2]i32,
  // Textures and sprites batcher
	batcher:         Batcher,
	tex:             Texture,
	atlas:           []u8,
  // Shapes batcher
	shapes_batcher:  Batcher,
	pixel_tex:       Texture,
	pixel_atlas:     []u8,
} {
	bg = {90, 95, 100, 255},
}

main :: proc() {
	state.ctx = context
	defer free(&state.mui_ctx)
	mui.init(&state.mui_ctx)
	state.mui_ctx.text_width = mui.default_atlas_text_width
	state.mui_ctx.text_height = mui.default_atlas_text_height

	state.screen_width = WINDOW_WIDTH
	state.screen_height = WINDOW_HEIGHT
	os_init()
	r_init_and_run()
}

post_init :: proc() {
	state.atlas = #load("../assets/img/hero.png")
	state.tex = load_texture_from_memory(state.atlas, default_texture_options())
	state.batcher = b_init(1024, state.tex.view_handle)

	state.pixel_atlas = #load("../assets/img/pixel.png")
	state.pixel_tex = load_texture_from_memory(state.pixel_atlas, default_texture_options())
	state.shapes_batcher = b_init(1024, state.pixel_tex.view_handle)
}

frame :: proc(dt: f32) {
	free_all(context.temp_allocator)
	update_ui_input(&state.mui_ctx)
	test_window(&state.mui_ctx)
/*	
  b_begin(&state.batcher, {clear_color = {0.25, 0.65, 0.45, 1}})
	opts := b_default_batcher_texture_options()
	opts.flip_y = true
	opts.flip_x = true
	b_texture(&state.batcher, {0, 0, 0, 0}, state.tex, opts)
	b_end(&state.batcher, &state.renderer.const_buffer)
	commands, _ := b_finish(&state.batcher)
	b_submit(&state.batcher, commands)
*/
  
  b_begin(&state.shapes_batcher, {clear_color={0.6, 0.6, 0.5, 1.0}})
	opts := b_default_batcher_texture_options()
	//b_quad(&state.shapes_batcher, {0, 0, 100, 100}, 0, state.pixel_tex, opts)
	//sh_draw_rect({0, 0, 100, 100})
  //sh_draw_rect_outline({110, 0, 50, 50})
  //sh_draw_line({100, 100}, {200,200})
  sh_draw_circle({250, 100}, 32)
  b_end(&state.shapes_batcher, &state.renderer.const_buffer)
	commands, _ := b_finish(&state.shapes_batcher)
	b_submit(&state.shapes_batcher, commands)


	// Uncomment this to enable again the UI. Will need to fix this up to draw both on the same surface, though
	//r_render()
}

vertex_source := `#version 330 core
layout(location=0) in vec3 a_position;
layout(location=1) in vec4 a_color;
out vec4 v_color;
uniform mat4 u_transform;
void main() {
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_color = a_color;
}
`
fragment_source := `#version 330 core
in vec4 v_color;
out vec4 o_color;
void main() {
	o_color = v_color;
}
`
