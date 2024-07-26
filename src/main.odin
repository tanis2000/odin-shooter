package game

import "base:runtime"
//import "core:fmt"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:time"
import mui "vendor:microui"
import "vendor:wgpu"
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
	ctx:                     runtime.Context,
	screen_width:            int,
	screen_height:           int,
	//current_keys: [dynamic]rl.KeyboardKey,
	//previous_keys: [dynamic]rl.KeyboardKey,
	quit_requested:          bool,
	log_buf:                 [1 << 16]byte,
	log_buf_len:             int,
	log_buf_updated:         bool,
	mui_ctx:                 mui.Context,
	bg:                      mui.Color,
	os:                      OS,
	renderer:                Renderer,
	cursor:                  [2]i32,

	// Pipelines
	diffuse_pipeline:        wgpu.RenderPipeline,
	diffuse_uniforms_buffer: wgpu.Buffer,
	diffuse_bind_group:      wgpu.BindGroup,
	diffuse_output:          Texture,

	// Shapes pipeline
	shapes_bind_group:       wgpu.BindGroup,

	// Final pipeline
	final_bind_group:        wgpu.BindGroup,

	// Textures and sprites batcher
	batcher:                 Batcher,
	diffuse_map:             Texture,
	atlas:                   []u8,
	// Shapes batcher
	shapes_batcher:          Batcher,
	pixel_tex:               Texture,
	pixel_atlas:             []u8,
	// Final image Batcher 
	final_batcher:           Batcher,

	// UI
	ui:                      Ui,
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
	state.diffuse_map = load_texture_from_memory(state.atlas, default_texture_options())
	state.batcher = b_init(1024)

	state.pixel_atlas = #load("../assets/img/pixel.png")
	state.pixel_tex = load_texture_from_memory(state.pixel_atlas, default_texture_options())
	state.shapes_batcher = b_init(1024)

	state.final_batcher = b_init(1024)

	opts := default_texture_options()
	opts.format = .BGRA8Unorm
	width, height := os_get_render_bounds()
	state.diffuse_output = t_create_empty(width, height, opts)

	g_init()
}

frame :: proc(dt: f32) {
	free_all(context.temp_allocator)
	update_ui_input(&state.mui_ctx)
	test_window(&state.mui_ctx)

	// Transformation matrix to convert from screen to device pixels and scale based on DPI.
	dpi := os_get_dpi()
	width, height := os_get_render_bounds()
	fw, fh := f32(width), f32(height)
	diffuse_uniforms: DiffuseUniform = {
		transform = linalg.matrix_ortho3d(0, fw, fh, 0, -1, 1) * linalg.matrix4_scale(dpi),
	}

	// Render the sprites
	b_begin(
		&state.batcher,
		{
			pipeline_handle = state.diffuse_pipeline,
			bind_group_handle = state.diffuse_bind_group,
			output_handle = state.diffuse_output.view_handle,
			clear_color = {0.25, 0.65, 0.45, 1},
		},
	)
	opts := b_default_batcher_texture_options()
	opts.flip_y = true
	opts.flip_x = true
	b_texture(&state.batcher, {0, 0, 0, 0}, state.diffuse_map, opts)
	b_end(&state.batcher, diffuse_uniforms, &state.diffuse_uniforms_buffer)
	commands, _ := b_finish(&state.batcher)
	b_submit(&state.batcher, commands)

	// Render the flat shapes
	b_begin(
		&state.shapes_batcher,
		{
			pipeline_handle = state.diffuse_pipeline,
			bind_group_handle = state.shapes_bind_group,
			output_handle = state.diffuse_output.view_handle,
			clear_color = {0, 0, 0, 0},
		},
	)
	opts = b_default_batcher_texture_options()
	sh_draw_rect({0, 0, 100, 100})
	sh_draw_rect_outline({110, 0, 50, 50})
	sh_draw_line({100, 100}, {200, 200})
	sh_draw_circle({250, 100}, 32)
	b_end(&state.shapes_batcher, diffuse_uniforms, &state.diffuse_uniforms_buffer)
	commands, _ = b_finish(&state.shapes_batcher)
	b_submit(&state.shapes_batcher, commands)

  // UI
  ui_clear({0, 0, 0, 0}, state.diffuse_output.view_handle)
  ui_bind()
  ui_render()
  ui_submit()

	// Render the diffuse stuff to the framebuffer surface
	b_begin(
		&state.final_batcher,
		{
			pipeline_handle = state.diffuse_pipeline,
			bind_group_handle = state.final_bind_group,
			clear_color = {0.96, 0.75, 0.31, 1},
		},
	)
	//diffuse_uniforms.transform = linalg.identity_matrix(matrix[4,4]f32)*linalg.matrix4_translate_f32({-1, -1, 0})
	//diffuse_uniforms.transform = linalg.transpose(diffuse_uniforms.transform)
	diffuse_uniforms.transform =
		linalg.matrix4_scale_f32({1, -1, 1}) * linalg.matrix_ortho3d(0, fw, fh, 0, -1, 1)
	opts = b_default_batcher_texture_options()
	b_texture(&state.final_batcher, {0, 0, 0, 0}, state.diffuse_output, opts)
	b_end(&state.final_batcher, diffuse_uniforms, &state.diffuse_uniforms_buffer)
	commands, _ = b_finish(&state.final_batcher)
	b_submit(&state.final_batcher, commands)
	// Uncomment this to enable again the UI. Will need to fix this up to draw both on the same surface, though
	//r_render()
  //r_present()
}
