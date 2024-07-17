package game

import "core:math/linalg"

Quad :: struct {
	vertices: [4]Vertex,
}

/*q_set_data :: proc(q: ^Quad, data: VertexData) {
  for _, i in q.vertices {
    using v := &q.vertices[i]
    v.data = data.value
  }
}*/

q_set_color :: proc(q: ^Quad, color: [4]f32) {
	for _, i in q.vertices {
		using v := &q.vertices[i]
		v.color = color
	}
}

q_set_viewport :: proc(
	q: ^Quad,
	x: f32,
	y: f32,
	width: f32,
	height: f32,
	tex_width: f32,
	tex_height: f32,
) {
	inv_w := 1.0 / tex_width
	inv_h := 1.0 / tex_height

	q.vertices[0].uv = {x * inv_w, y * inv_h}
	q.vertices[1].uv = {(x + width) * inv_w, y * inv_h}
	q.vertices[2].uv = {(x + width) * inv_w, (y + height) * inv_h}
	q.vertices[3].uv = {x * inv_w, (y + height) * inv_h}
}

q_rotate :: proc(q: ^Quad, rotation: f32, pos_x: f32, pos_y:f32, origin_x: f32, origin_y:f32) {
  for _, i in q.vertices {
    //using vert := q.vertices[i]
    p : [4]f32={q.vertices[i].position.x, q.vertices[i].position.y, q.vertices[i].position.z, 0}
    offset : [4]f32 = {pos_x, pos_y, 0, 0}
    radians := linalg.to_radians(rotation)
    translation_matrix := linalg.matrix4_translate([3]f32{origin_x, origin_y, 0})
    rotation_matrix := linalg.matrix4_rotate(radians, [3]f32{0, 0, 1})
    p -= offset
    p = translation_matrix * rotation_matrix * p
    p += offset
    q.vertices[i].position = p.xyz
  }
}
