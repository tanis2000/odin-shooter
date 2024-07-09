package game

import mui "vendor:microui"
import u "core:unicode/utf8"
import "core:fmt"

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
	/*
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