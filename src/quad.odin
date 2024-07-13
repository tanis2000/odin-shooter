package game

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
