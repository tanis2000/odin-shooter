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
	ctx: runtime.Context,
	screen_width: int,
	screen_height: int,
	//current_keys: [dynamic]rl.KeyboardKey,
	//previous_keys: [dynamic]rl.KeyboardKey,
	quit_requested: bool,

	log_buf:         [1<<16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,

	mui_ctx: mui.Context,
	bg: mui.Color,
	os: OS,
	renderer:        Renderer,

    cursor:          [2]i32,
}{
	bg = {90, 95, 100, 255},
}

main :: proc() {
	state.ctx = context
	mui.init(&state.mui_ctx)
	state.mui_ctx.text_width = mui.default_atlas_text_width
	state.mui_ctx.text_height = mui.default_atlas_text_height

	state.screen_width = WINDOW_WIDTH
	state.screen_height = WINDOW_HEIGHT
	os_init()
	r_init_and_run()
	// rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Shooter")
	// rl.SetExitKey(.KEY_NULL)
	// rl.SetTargetFPS(60)
	// rl.InitAudioDevice()
	// if !rl.IsAudioDeviceReady() || !rl.IsWindowReady() {
	// 	time.sleep(10)
	// }
	// rl.SetMasterVolume(1)
	// camera: rl.Camera2D = {
	// }
	// shader := rl.LoadShaderFromMemory(strings.clone_to_cstring(vertex_source), strings.clone_to_cstring(fragment_source))

	// init_renderer(state.screen_width, state.screen_height)
	// for !rl.WindowShouldClose() {
	// 	update()
	// }
}

frame :: proc(dt: f32) {
	free_all(context.temp_allocator)
	//mui.begin(state.mui_ctx)
	update_ui_input(&state.mui_ctx)
	test_window(&state.mui_ctx)
	//mui.end(state.mui_ctx)
	r_render()
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
