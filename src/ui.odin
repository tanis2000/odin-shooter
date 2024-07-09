package game

import c "core:c/libc"
import gl "vendor:OpenGL"
import mui "vendor:microui"
import rl "vendor:raylib"
import SDL "vendor:sdl2"
import u "core:unicode/utf8"
import "core:fmt"

screen_texture: rl.RenderTexture2D
atlas_texture: rl.RenderTexture2D

init_renderer :: proc(width, height: int) {
	// Load microui atlas
	atlas_texture = rl.LoadRenderTexture(mui.DEFAULT_ATLAS_WIDTH, mui.DEFAULT_ATLAS_HEIGHT)
	image: rl.Image = rl.GenImageColor(
		mui.DEFAULT_ATLAS_WIDTH,
		mui.DEFAULT_ATLAS_HEIGHT,
		rl.Color{0, 0, 0, 0},
	)
	for alpha, i in mui.default_atlas_alpha {
		x := c.int(i % mui.DEFAULT_ATLAS_WIDTH)
		y := c.int(i / mui.DEFAULT_ATLAS_WIDTH)
		color := rl.Color{255, 255, 255, alpha}
		rl.ImageDrawPixel(&image, x, y, color)
	}
	rl.BeginTextureMode(atlas_texture)
	{
		rl.UpdateTexture(atlas_texture.texture, rl.LoadImageColors(image))
	}
	rl.EndTextureMode()

	// Create the screen texture
	screen_texture = rl.LoadRenderTexture(c.int(width), c.int(height))
}

test_window :: proc(ctx: ^mui.Context) {
	mui.begin(ctx)
	mui.begin_window(ctx, "test", {x = 0, y = 0, w = 300, h = 450})
    if .ACTIVE in mui.header(ctx, "Window Info") {
        win := mui.get_current_container(ctx)
        mui.layout_row(ctx, {54, -1}, 0)
        mui.label(ctx, "Position:")
        mui.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
        mui.label(ctx, "Size:")
        mui.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
    }

    if .ACTIVE in mui.header(ctx, "Test Buttons", {.EXPANDED}) {
        mui.layout_row(ctx, {86, -110, -1})
        mui.label(ctx, "Test buttons 1:")
        if .SUBMIT in mui.button(ctx, "Button 1") { write_log("Pressed button 1") }
        if .SUBMIT in mui.button(ctx, "Button 2") { write_log("Pressed button 2") }
        mui.label(ctx, "Test buttons 2:")
        if .SUBMIT in mui.button(ctx, "Button 3") { write_log("Pressed button 3") }
        if .SUBMIT in mui.button(ctx, "Button 4") { write_log("Pressed button 4") }
    }

	mui.end_window(ctx)
	mui.end(ctx)
}

update_ui_input :: proc(ctx: ^mui.Context) {
    mouse_pos : rl.Vector2 = rl.GetMousePosition()
		mui.input_mouse_move(ctx, i32(mouse_pos.x), i32(mouse_pos.y))

		mouse_wheel_pos : rl.Vector2 = rl.GetMouseWheelMoveV()
		mui.input_scroll(ctx, i32(mouse_wheel_pos.x) * 30, i32(mouse_wheel_pos.y) * -30)

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			mui.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .LEFT)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
			mui.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .LEFT)
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.MIDDLE) {
			mui.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .MIDDLE)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.MIDDLE) {
			mui.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .MIDDLE)
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
			mui.input_mouse_down(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .RIGHT)
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
			mui.input_mouse_up(ctx, i32(mouse_pos.x), i32(mouse_pos.y), .RIGHT)
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
					case rl.KeyboardKey.LEFT_SHIFT: mui.input_key_up(ctx, .SHIFT)
					case rl.KeyboardKey.RIGHT_SHIFT: mui.input_key_up(ctx, .SHIFT)
					case rl.KeyboardKey.LEFT_CONTROL: mui.input_key_up(ctx, .CTRL)
					case rl.KeyboardKey.RIGHT_CONTROL: mui.input_key_up(ctx, .CTRL)
					case rl.KeyboardKey.LEFT_ALT: mui.input_key_up(ctx, .ALT)
					case rl.KeyboardKey.RIGHT_ALT: mui.input_key_up(ctx, .ALT)
					case rl.KeyboardKey.ENTER: mui.input_key_up(ctx, .RETURN)
					case rl.KeyboardKey.KP_ENTER: mui.input_key_up(ctx, .RETURN)
					case rl.KeyboardKey.BACKSPACE: mui.input_key_up(ctx, .BACKSPACE)
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
					case rl.KeyboardKey.LEFT_SHIFT: mui.input_key_down(ctx, .SHIFT)
					case rl.KeyboardKey.RIGHT_SHIFT: mui.input_key_down(ctx, .SHIFT)
					case rl.KeyboardKey.LEFT_CONTROL: mui.input_key_down(ctx, .CTRL)
					case rl.KeyboardKey.RIGHT_CONTROL: mui.input_key_down(ctx, .CTRL)
					case rl.KeyboardKey.LEFT_ALT: mui.input_key_down(ctx, .ALT)
					case rl.KeyboardKey.RIGHT_ALT: mui.input_key_down(ctx, .ALT)
					case rl.KeyboardKey.ENTER: mui.input_key_down(ctx, .RETURN)
					case rl.KeyboardKey.KP_ENTER: mui.input_key_down(ctx, .RETURN)
					case rl.KeyboardKey.BACKSPACE: mui.input_key_down(ctx, .BACKSPACE)
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
				mui.input_text(ctx, str)
			}
		}

		delete(state.previous_keys)
		state.previous_keys = state.current_keys
}

render_ui :: proc(ctx: ^mui.Context) {
	rl.BeginTextureMode(screen_texture)
	{
		rl.EndScissorMode()
		rl.ClearBackground({90, 95, 100, 255})
	}
	rl.EndTextureMode()
	cmd: ^mui.Command
	for (mui.next_command(ctx, &cmd)) {
		switch v in cmd.variant {
		case ^mui.Command_Text:
			render_text(v.str, v.pos, v.color)
		case ^mui.Command_Rect:
			render_rect(v.rect, v.color)
		case ^mui.Command_Clip:
			render_clip(v.rect)
		case ^mui.Command_Icon:
			render_icon(v.id, v.rect, v.color)
		case ^mui.Command_Jump:
			unreachable()
		}
	}
    rl.BeginDrawing()
	{
		rl.ClearBackground(rl.RAYWHITE)
		rl.DrawTextureRec(screen_texture.texture, rl.Rectangle {0, 0, f32(state.screen_width), -f32(state.screen_height)}, rl.Vector2 {0,0}, rl.WHITE)
	}
	rl.EndDrawing()
}

render_rect :: proc(rect: mui.Rect, color: mui.Color) {
    rl.BeginTextureMode(screen_texture)
    {
        rl.DrawRectangle(rect.x, rect.y, rect.w, rect.h, mu_to_rl_color(color))
    }
    rl.EndTextureMode()
}

render_text :: proc(str: string, pos: mui.Vec2, color: mui.Color) {
	dst := rl.Rectangle{f32(pos.x), f32(pos.y), 0, 0}
	for ch in str do if ch & 0xc0 != 0x80 {
		r := min(int(ch), 127)
		src := mui.default_atlas[mui.DEFAULT_ATLAS_FONT + r]
		render_texture(&screen_texture, &dst, src, mu_to_rl_color(color))
		dst.x += dst.width
	}
}

render_clip :: proc(rect: mui.Rect) {
	rl.BeginTextureMode(screen_texture)
	{
		rl.BeginScissorMode(rect.x, rect.y, rect.w, rect.h)
	}
	rl.EndTextureMode()
}

render_icon :: proc(id: mui.Icon, rect: mui.Rect, color: mui.Color) {

}

render_texture :: proc(
	renderer: ^rl.RenderTexture2D,
	dst: ^rl.Rectangle,
	src: mui.Rect,
	color: rl.Color,
) {
	dst.width = f32(src.w)
	dst.height = f32(src.h)

	rl.BeginTextureMode(renderer^)
	{
		rl.DrawTextureRec(
			atlas_texture.texture,
			mu_to_rl_Rect(src),
			rl.Vector2{dst.x, dst.y},
			color,
		)
	}
	rl.EndTextureMode()
}

// convert microui color to raylib color
mu_to_rl_color :: proc(in_color: mui.Color) -> (out_color: rl.Color) {
	return {in_color.r, in_color.g, in_color.b, in_color.a}
}

// convert microui Rect to raylib Rectangle
mu_to_rl_Rect :: proc(in_rect: mui.Rect) -> (out_rect: rl.Rectangle) {
	return {f32(in_rect.x), f32(in_rect.y), f32(in_rect.w), f32(in_rect.h)}
}

// finds the key pos in a key array
array_key_pos :: proc(key_array: ^[dynamic]rl.KeyboardKey, key: rl.KeyboardKey) -> int {
	for i:= len(key_array)-1; i >=0; i -= 1 {
		if key_array[i] == key {return i}
	}
	return -1
}

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