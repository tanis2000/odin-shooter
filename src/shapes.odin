package game

import "core:math/linalg"

sh_draw_rect :: proc(rect: [4]f32) {
	opts := b_default_batcher_texture_options()
	b_quad(&state.shapes_batcher, rect, 0, 0, state.pixel_tex, opts)
}

sh_draw_rect_outline :: proc(rect: [4]f32) {
	opts := b_default_batcher_texture_options()
	b_quad(&state.shapes_batcher, {rect.x, rect.y, rect.z, 1}, 0, 0, state.pixel_tex, opts)
	b_quad(&state.shapes_batcher, {rect.x, rect.y, 1, rect.w}, 0, 0, state.pixel_tex, opts)
	b_quad(
		&state.shapes_batcher,
		{rect.x + rect.z - 1, rect.y, 1, rect.w},
		0,
		0,
		state.pixel_tex,
		opts,
	)
	b_quad(
		&state.shapes_batcher,
		{rect.x, rect.y + rect.w - 1, rect.z, 1},
		0,
		0,
		state.pixel_tex,
		opts,
	)
}

sh_draw_line :: proc(start: [2]f32, end: [2]f32) {
	angle := linalg.to_degrees(linalg.atan2(end.y - start.y, end.x - start.x))
	length := linalg.distance(start, end)
	rect: [4]f32 = {start.x, start.y, length, 1}
	opts := b_default_batcher_texture_options()
	b_quad(&state.shapes_batcher, rect, 0, angle, state.pixel_tex, opts)
}

sh_draw_triangle :: proc(v0: [2]f32, v1: [2]f32, v2: [2]f32) {
}

sh_draw_circle :: proc(center: [2]f32, radius: f32) {
	circle_segments := 32
	increment := linalg.PI * 2.0 / f32(circle_segments)
	theta: f32 = 0.0
	v0: [2]f32 = {linalg.cos(theta) * radius + center.x, linalg.sin(theta) * radius + center.y}
	theta += increment
	count := 0
	for i := 1; i < circle_segments - 1; i += 1 {
    v1: [2]f32 = {linalg.cos(theta) * radius + center.x, linalg.sin(theta) * radius + center.y}
    v2: [2]f32 = {linalg.sin(theta+increment) * radius + center.x, linalg.cos(theta+increment) * radius + center.y}
    sh_draw_triangle(v0, v1, v2)
    theta += increment
	}
}
