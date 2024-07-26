package game

import mu "vendor:microui"
import u "core:unicode/utf8"
import "core:fmt"
import "vendor:wgpu"
import intr "base:intrinsics"

BUFFER_SIZE :: 16384

Ui :: struct {
	const_buffer:       wgpu.Buffer,
	atlas_texture:      wgpu.Texture,
	atlas_texture_view: wgpu.TextureView,
	sampler:            wgpu.Sampler,
	tex_buffer:         wgpu.Buffer,
	vertex_buffer:      wgpu.Buffer,
	color_buffer:       wgpu.Buffer,
	index_buffer:       wgpu.Buffer,
	bind_group_layout:  wgpu.BindGroupLayout,
	bind_group:         wgpu.BindGroup,
	tex_buf:            [BUFFER_SIZE * 8]f32,
	vert_buf:           [BUFFER_SIZE * 8]f32,
	color_buf:          [BUFFER_SIZE * 16]u8,
	index_buf:          [BUFFER_SIZE * 6]u32,
	module:             wgpu.ShaderModule,
	pipeline_layout:    wgpu.PipelineLayout,
	pipeline:           wgpu.RenderPipeline,
}

test_window :: proc(ctx: ^mu.Context) {
	mu.begin(ctx)
	mu.begin_window(ctx, "test", {x = 0, y = 0, w = 300, h = 450})
    if .ACTIVE in mu.header(ctx, "Window Info") {
        win := mu.get_current_container(ctx)
        mu.layout_row(ctx, {54, -1}, 0)
        mu.label(ctx, "Position:")
        mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
        mu.label(ctx, "Size:")
        mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
    }

    if .ACTIVE in mu.header(ctx, "Test Buttons", {.EXPANDED}) {
        mu.layout_row(ctx, {86, -110, -1})
        mu.label(ctx, "Test buttons 1:")
        if .SUBMIT in mu.button(ctx, "Button 1") { write_log("Pressed button 1") }
        if .SUBMIT in mu.button(ctx, "Button 2") { write_log("Pressed button 2") }
        mu.label(ctx, "Test buttons 2:")
        if .SUBMIT in mu.button(ctx, "Button 3") { write_log("Pressed button 3") }
        if .SUBMIT in mu.button(ctx, "Button 4") { write_log("Pressed button 4") }
    }

	mu.end_window(ctx)
	mu.end(ctx)
}

update_ui_input :: proc(ctx: ^mu.Context) {
	/*
    mouse_pos : rl.Vector2 = rl.GetMousePosition()
		mu.input_mouse_move(ctx, i32(mouse_pos.x), i32(mouse_pos.y))

		mouse_wheel_pos : rl.Vector2 = rl.GetMouseWheelMoveV()
		mu.input_scroll(ctx, i32(mouse_wheel_pos.x) * 30, i32(mouse_wheel_pos.y) * -30)

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			mu.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .LEFT)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
			mu.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .LEFT)
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.MIDDLE) {
			mu.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .MIDDLE)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.MIDDLE) {
			mu.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .MIDDLE)
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
			mu.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .RIGHT)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
			mu.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .RIGHT)
		}

		//// Handle Keyboard input
		// info: This tries to imitate the behaviour of the SDL version.

		get_pressed_keys ::proc() -> [dynamic]rl.KeyboardKey {
			pressed_keys : [dynamic]rl.KeyboardKey

			for key := rl.GetKeyPressed(); key != .KEY_NULL; key = rl.GetKeyPressed() {
				append(&pressed_keys, key)
			}

			return pressed_keys
		}

		state.current_keys = get_pressed_keys() 

		// Check which keys aren't being pressed anymore
		for i: uint = 0; i < len(state.previous_keys); i += 1 {
			key:= state.previous_keys[i]
			if array_key_pos(&state.current_keys, key) == -1 {
				#partial switch key {
					case rl.KeyboardKey.LEFT_SHIFT: mu.input_key_up(ctx, .SHIFT)
					case rl.KeyboardKey.RIGHT_SHIFT: mu.input_key_up(ctx, .SHIFT)
					case rl.KeyboardKey.LEFT_CONTROL: mu.input_key_up(ctx, .CTRL)
					case rl.KeyboardKey.RIGHT_CONTROL: mu.input_key_up(ctx, .CTRL)
					case rl.KeyboardKey.LEFT_ALT: mu.input_key_up(ctx, .ALT)
					case rl.KeyboardKey.RIGHT_ALT: mu.input_key_up(ctx, .ALT)
					case rl.KeyboardKey.ENTER: mu.input_key_up(ctx, .RETURN)
					case rl.KeyboardKey.KP_ENTER: mu.input_key_up(ctx, .RETURN)
					case rl.KeyboardKey.BACKSPACE: mu.input_key_up(ctx, .BACKSPACE)
					case: // other cases are handled in section "handle_text_input"
				}
			}
		}

		// Check, which keys are newly being pressed
		for i: uint = 0; i < len(state.current_keys); i += 1 {
			key := state.current_keys[i]
			
			if array_key_pos(&state.previous_keys, key) == -1 {
				#partial switch key {
					case rl.KeyboardKey.ESCAPE: state.quit_requested = true
					case rl.KeyboardKey.LEFT_SHIFT: mu.input_key_down(ctx, .SHIFT)
					case rl.KeyboardKey.RIGHT_SHIFT: mu.input_key_down(ctx, .SHIFT)
					case rl.KeyboardKey.LEFT_CONTROL: mu.input_key_down(ctx, .CTRL)
					case rl.KeyboardKey.RIGHT_CONTROL: mu.input_key_down(ctx, .CTRL)
					case rl.KeyboardKey.LEFT_ALT: mu.input_key_down(ctx, .ALT)
					case rl.KeyboardKey.RIGHT_ALT: mu.input_key_down(ctx, .ALT)
					case rl.KeyboardKey.ENTER: mu.input_key_down(ctx, .RETURN)
					case rl.KeyboardKey.KP_ENTER: mu.input_key_down(ctx, .RETURN)
					case rl.KeyboardKey.BACKSPACE: mu.input_key_down(ctx, .BACKSPACE)
					case: // other cases are handled in section "handle_text_input"
				}			
			}
		}

		// This handles text input
		handle_text_input: {
			ra := make([]rune, 1)
			ra[0] = rl.GetCharPressed()

			if ra[0] != 0 {
				str:= u.runes_to_string(ra)
				mu.input_text(ctx, str)
			}
		}

		delete(state.previous_keys)
		state.previous_keys = state.current_keys
		*/
}

// finds the key pos in a key array
/*
array_key_pos :: proc(key_array: ^[dynamic]rl.KeyboardKey, key: rl.KeyboardKey) -> int {
	for i:= len(key_array)-1; i >=0; i -= 1 {
		if key_array[i] == key {return i}
	}
	return -1
}
	*/

write_log :: proc(str: string) {
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], str)
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], "\n")
	state.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(state.log_buf[:state.log_buf_len])
}
reset_log :: proc() {
	state.log_buf_updated = true
	state.log_buf_len = 0
}

ui_bind :: proc() {
	r := &state.renderer

	wgpu.RenderPassEncoderSetPipeline(r.curr_pass, state.ui.pipeline)
	wgpu.RenderPassEncoderSetBindGroup(r.curr_pass, 0, state.ui.bind_group)
	wgpu.RenderPassEncoderSetVertexBuffer(r.curr_pass, 0, state.ui.vertex_buffer, 0, size_of(state.ui.vert_buf))
	wgpu.RenderPassEncoderSetVertexBuffer(r.curr_pass, 1, state.ui.tex_buffer, 0, size_of(state.ui.tex_buf))
	wgpu.RenderPassEncoderSetVertexBuffer(r.curr_pass, 2, state.ui.color_buffer, 0, size_of(state.ui.color_buf))
	wgpu.RenderPassEncoderSetIndexBuffer(
		r.curr_pass,
		state.ui.index_buffer,
		.Uint32,
		0,
		size_of(state.ui.index_buf),
	)
}

ui_clear :: proc(color: mu.Color, output: wgpu.TextureView) -> bool {
	r := &state.renderer

	r.buf_idx = 0
	r.prev_buf_idx = 0

	/*r.curr_texture = wgpu.SurfaceGetCurrentTexture(r.surface)
	switch r.curr_texture.status {
	case .Success:
	// All good, could check for `r.curr_texture.suboptimal` here.
	case .Timeout, .Outdated, .Lost:
		if r.curr_texture.texture != nil {
			wgpu.TextureRelease(r.curr_texture.texture)
		}
		r_resize()
		return false
	case .OutOfMemory, .DeviceLost:
		fmt.panicf("get_current_texture status=%v", r.curr_texture.status)
	}

	r.curr_view = wgpu.TextureCreateView(r.curr_texture.texture, nil)
*/
  r.curr_view = output
	r.curr_encoder = wgpu.DeviceCreateCommandEncoder(r.device, nil)

	r.curr_pass = wgpu.CommandEncoderBeginRenderPass(
		r.curr_encoder,
		&{
			colorAttachmentCount = 1,
			colorAttachments = raw_data(
				[]wgpu.RenderPassColorAttachment {
					{
						view = r.curr_view,
						loadOp = color.a == 0 ? .Load : .Clear,
						storeOp = .Store,
						clearValue = {
							f64(color.r) / 255,
							f64(color.g) / 255,
							f64(color.b) / 255,
							f64(color.a) / 255,
						},
					},
				},
			),
		},
	)

  //ui_bind()

	return true
}

ui_render :: proc() {
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(&state.mui_ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			ui_draw_text(cmd.str, cmd.pos, cmd.color)
		case ^mu.Command_Rect:
			ui_draw_rect(cmd.rect, cmd.color)
		case ^mu.Command_Icon:
			ui_draw_icon(cmd.id, cmd.rect, cmd.color)
		case ^mu.Command_Clip:
			ui_set_clip_rect(cmd.rect)
		case ^mu.Command_Jump:
			unreachable()
		}
	}
}


ui_flush :: proc() {
	r := &state.renderer

	if r.buf_idx == 0 || r.buf_idx == r.prev_buf_idx {return}

	delta := uint(r.buf_idx - r.prev_buf_idx)
	wgpu.RenderPassEncoderDrawIndexed(r.curr_pass, u32(delta * 6), 1, r.prev_buf_idx * 6, 0, 0)

	r.prev_buf_idx = r.buf_idx
}

ui_full_flush :: proc() {
	r := &state.renderer

	ui_submit()

	r.buf_idx = 0
	r.prev_buf_idx = 0

	r.curr_encoder = wgpu.DeviceCreateCommandEncoder(r.device, nil)
	r.curr_pass = wgpu.CommandEncoderBeginRenderPass(
		r.curr_encoder,
		&{
			colorAttachmentCount = 1,
			colorAttachments = &wgpu.RenderPassColorAttachment {
				view = r.curr_view,
				loadOp = .Load,
				storeOp = .Store,
			},
		},
	)

	ui_bind()
}

ui_submit :: proc() {
	r := &state.renderer

	ui_flush()

	wgpu.QueueWriteBuffer(
		r.queue,
		state.ui.vertex_buffer,
		0,
		&state.ui.vert_buf,
		uint(r.buf_idx * 8 * size_of(f32)),
	)
	wgpu.QueueWriteBuffer(r.queue, state.ui.tex_buffer, 0, &state.ui.tex_buf, uint(r.buf_idx * 8 * size_of(f32)))
	wgpu.QueueWriteBuffer(r.queue, state.ui.color_buffer, 0, &state.ui.color_buf, uint(r.buf_idx * 16))
	wgpu.QueueWriteBuffer(
		r.queue,
		state.ui.index_buffer,
		0,
		&state.ui.index_buf,
		uint(r.buf_idx * 6 * size_of(u32)),
	)

	wgpu.RenderPassEncoderEnd(r.curr_pass)

	command_buffer := wgpu.CommandEncoderFinish(r.curr_encoder, nil)
	wgpu.QueueSubmit(r.queue, {command_buffer})

	wgpu.CommandBufferRelease(command_buffer)
	wgpu.RenderPassEncoderRelease(r.curr_pass)
	wgpu.CommandEncoderRelease(r.curr_encoder)
}


ui_push_quad :: proc(dst, src: mu.Rect, color: mu.Color) #no_bounds_check {
	r := &state.renderer

	if (r.buf_idx == BUFFER_SIZE) {
		ui_full_flush()
	}

	textvert_idx := r.buf_idx * 8
	color_idx := r.buf_idx * 16
	element_idx := u32(r.buf_idx * 4)
	index_idx := r.buf_idx * 6

	r.buf_idx += 1

	x := f32(src.x) / mu.DEFAULT_ATLAS_WIDTH
	y := f32(src.y) / mu.DEFAULT_ATLAS_HEIGHT
	w := f32(src.w) / mu.DEFAULT_ATLAS_WIDTH
	h := f32(src.h) / mu.DEFAULT_ATLAS_HEIGHT
	copy(state.ui.tex_buf[textvert_idx:], []f32{x, y, x + w, y, x, y + h, x + w, y + h})

	dx, dy, dw, dh := f32(dst.x), f32(dst.y), f32(dst.w), f32(dst.h)
	copy(state.ui.vert_buf[textvert_idx:], []f32{dx, dy, dx + dw, dy, dx, dy + dh, dx + dw, dy + dh})

	color := color
	intr.mem_copy_non_overlapping(raw_data(state.ui.color_buf[color_idx + 0:]), &color, 4)
	intr.mem_copy_non_overlapping(raw_data(state.ui.color_buf[color_idx + 4:]), &color, 4)
	intr.mem_copy_non_overlapping(raw_data(state.ui.color_buf[color_idx + 8:]), &color, 4)
	intr.mem_copy_non_overlapping(raw_data(state.ui.color_buf[color_idx + 12:]), &color, 4)

	copy(
		state.ui.index_buf[index_idx:],
		[]u32 {
			element_idx + 0,
			element_idx + 1,
			element_idx + 2,
			element_idx + 2,
			element_idx + 3,
			element_idx + 1,
		},
	)
}

ui_draw_rect :: proc(rect: mu.Rect, color: mu.Color) {
	ui_push_quad(rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}

ui_draw_text :: proc(text: string, pos: mu.Vec2, color: mu.Color) {
	dst := mu.Rect{pos.x, pos.y, 0, 0}
	for ch in text do if ch & 0xc0 != 0x80 {
		r := min(int(ch), 127)
		src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
		dst.w = src.w
		dst.h = src.h
		ui_push_quad(dst, src, color)
		dst.x += dst.w
	}
}

ui_draw_icon :: proc(id: mu.Icon, rect: mu.Rect, color: mu.Color) {
	src := mu.default_atlas[id]
	x := rect.x + (rect.w - src.w) / 2
	y := rect.y + (rect.h - src.h) / 2
	ui_push_quad({x, y, src.w, src.h}, src, color)
}

ui_set_clip_rect :: proc(rect: mu.Rect) {
	r := &state.renderer
	ui_flush()

	x := min(u32(rect.x), r.config.width)
	y := min(u32(rect.y), r.config.height)
	w := min(u32(rect.w), r.config.width - x)
	h := min(u32(rect.h), r.config.height - y)
	wgpu.RenderPassEncoderSetScissorRect(r.curr_pass, x, y, w, h)
}
