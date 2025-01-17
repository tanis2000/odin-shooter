package game

import "core:fmt"
import "core:math/linalg"
import "vendor:wgpu"

Batcher :: struct {
	encoder:                wgpu.CommandEncoder,
	vertices:               [dynamic]Vertex,
	vertex_buffer_handle:   wgpu.Buffer,
	indices:                [dynamic]u32,
	index_buffer_handle:    wgpu.Buffer,
	ctx:                    BatcherContext,
	vert_index:             u32,
	idx_index:              u32,
	tri_count:              u32,
	start_count:            u32,
	state:                  BatcherState,
	back_buffer:            wgpu.SurfaceTexture,
	back_buffer_view:       wgpu.TextureView,
}

BatcherContext :: struct {
	pipeline_handle:   wgpu.RenderPipeline,
	bind_group_handle: wgpu.BindGroup,
	// If the output_handle is null, then it will render to the back buffer
	// otherwise it will render to the offscreen texture
	output_handle: wgpu.TextureView,
	clear_color:   wgpu.Color,
}

BatcherState :: enum {
	Unknown,
	Progress,
	Idle,
}

BatcherError :: enum {
	None,
	Begin_Called_Twice,
	Buffer_Too_Small,
	Call_Begin_First,
	End_Called_Twice,
	Null_Encoder,
}

BatcherTextureOptions :: struct {
	color:  [4]f32,
	flip_y: bool,
	flip_x: bool,
	data_0: f32,
	data_1: f32,
	data_2: f32,
}

b_init :: proc(max_tris: u32) -> Batcher {
	fmt.println("init")
	vertices: [dynamic]Vertex = make([dynamic]Vertex, max_tris * 3)
	indices: [dynamic]u32 = make([dynamic]u32, max_tris * 6)

  vertex_buffer_descriptor: wgpu.BufferDescriptor = {
		label = "Batcher vertex buffer",
		usage = {.CopyDst, .Vertex},
		size  = u64(len(vertices) * size_of(Vertex)),
	}

	vertex_buffer_handle := wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&vertex_buffer_descriptor,
	)

	index_buffer_descriptor: wgpu.BufferDescriptor = {
		label = "Batcher index buffer",
		usage = {.CopyDst, .Index},
		size  = u64(len(indices) * size_of(u32)),
	}

	index_buffer_handle := wgpu.DeviceCreateBuffer(state.renderer.device, &index_buffer_descriptor)

	return Batcher {
		vertices = vertices,
		vertex_buffer_handle = vertex_buffer_handle,
		indices = indices,
		index_buffer_handle = index_buffer_handle,
	}
}

b_begin :: proc(b: ^Batcher, ctx: BatcherContext) -> BatcherError {
	fmt.println("begin")
	if b.state == .Progress {
		return .Begin_Called_Twice
	}
	b.ctx = ctx
	b.state = .Progress
	b.start_count = b.tri_count
	if b.encoder == nil {
		fmt.println("Batcher: creating new encoder")
		b.encoder = wgpu.DeviceCreateCommandEncoder(state.renderer.device, nil)
	}
	return .None
}

b_has_capacity :: proc(b: Batcher) -> bool {
	return int(b.tri_count * 3) < len(b.vertices) - 1
}

b_resize :: proc(b: ^Batcher, max_tris: u32) -> BatcherError {
	if max_tris <= b.tri_count {
		return .Buffer_Too_Small
	}

	fmt.println("resizing")

	resize(&b.vertices, max_tris * 3)
	resize(&b.indices, max_tris * 6)

	wgpu.BufferDestroy(b.vertex_buffer_handle)
	wgpu.BufferDestroy(b.index_buffer_handle)

	vertex_buffer_descriptor: wgpu.BufferDescriptor = {
		label = "Batcher vertex buffer",
		usage = {.CopyDst, .Vertex},
		size  = u64(len(b.vertices) * size_of(Vertex)),
	}

	vertex_buffer_handle := wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&vertex_buffer_descriptor,
	)

	index_buffer_descriptor: wgpu.BufferDescriptor = {
		label = "Batcher index buffer",
		usage = {.CopyDst, .Index},
		size  = u64(len(b.indices) * size_of(u32)),
	}

	index_buffer_handle := wgpu.DeviceCreateBuffer(state.renderer.device, &index_buffer_descriptor)

	b.vertex_buffer_handle = vertex_buffer_handle
	b.index_buffer_handle = index_buffer_handle

	return .None
}

b_append_quad :: proc(b: ^Batcher, quad: Quad) -> BatcherError {
	if b.state == .Idle {
		return .Call_Begin_First
	}
	if !b_has_capacity(b^) {
		b_resize(b, b.tri_count * 2)
	}
	b.vertices[b.vert_index] = quad.vertices[0]
	b.vert_index += 1
	b.vertices[b.vert_index] = quad.vertices[1]
	b.vert_index += 1
	b.vertices[b.vert_index] = quad.vertices[3]
	b.vert_index += 1
	b.vertices[b.vert_index] = quad.vertices[1]
	b.vert_index += 1
	b.vertices[b.vert_index] = quad.vertices[2]
	b.vert_index += 1
	b.vertices[b.vert_index] = quad.vertices[3]
	b.vert_index += 1

	b.tri_count += 2
	i := b.vert_index - 6
	b.indices[b.idx_index + 0] = i + 0
	b.indices[b.idx_index + 1] = i + 1
	b.indices[b.idx_index + 2] = i + 2
	b.indices[b.idx_index + 3] = i + 3
	b.indices[b.idx_index + 4] = i + 4
	b.indices[b.idx_index + 5] = i + 5
	b.idx_index += 6
	return .None
}

b_append_tri :: proc(b: ^Batcher, tri: Triangle) -> BatcherError {
	if b.state == .Idle {
		return .Call_Begin_First
	}
	if !b_has_capacity(b^) {
		b_resize(b, b.tri_count * 2)
	}
	b.vertices[b.vert_index] = tri.vertices[0]
	b.vert_index += 1
	b.vertices[b.vert_index] = tri.vertices[1]
	b.vert_index += 1
	b.vertices[b.vert_index] = tri.vertices[2]
	b.vert_index += 1

	b.tri_count += 1
	i := b.vert_index - 3
	b.indices[b.idx_index + 0] = i + 0
	b.indices[b.idx_index + 1] = i + 1
	b.indices[b.idx_index + 2] = i + 2
	b.idx_index += 3
	return .None
}

b_default_batcher_texture_options :: proc() -> BatcherTextureOptions {
	return BatcherTextureOptions{flip_x = false, flip_y = false, color = {1.0, 1.0, 1.0, 1.0}}
}

b_texture :: proc(
	b: ^Batcher,
	position: [4]f32,
	t: Texture,
	options: BatcherTextureOptions,
) -> BatcherError {
	width: f32 = f32(t.image.width)
	height: f32 = f32(t.image.height)
	pos := linalg.round(position)

	color: [4]f32 = {1.0, 1.0, 1.0, 1.0}
	for i := 0; i < 4; i += 1 {
		color[i] = options.color[i]
	}
	max: f32 = !options.flip_y ? 1.0 : 0.0
	min: f32 = !options.flip_y ? 0.0 : 1.0

	quad := Quad {
		vertices = {
			{
				position = {pos[0], pos[1] + height, pos[2]},
				uv = {options.flip_x ? max : min, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0] + width, pos[1] + height, pos[2]},
				uv = {options.flip_x ? min : max, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0] + width, pos[1], pos[2]},
				uv = {options.flip_x ? min : max, max},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0], pos[1], pos[2]},
				uv = {options.flip_x ? max : min, max},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
		},
	}
	b_append_quad(b, quad)
	return .None
}

b_quad :: proc(
	b: ^Batcher,
	rect: [4]f32,
	depth: f32,
	rotation: f32,
	t: Texture,
	options: BatcherTextureOptions,
) -> BatcherError {

	width: f32 = rect[2]
	height: f32 = rect[3]
	pos := linalg.round(rect)

	color: [4]f32 = {1.0, 1.0, 1.0, 1.0}
	for i := 0; i < 4; i += 1 {
		color[i] = options.color[i]
	}
	max: f32 = !options.flip_y ? 0.5 : 0.5
	min: f32 = !options.flip_y ? 0.5 : 0.5

	quad := Quad {
		vertices = {
			{
				position = {pos[0], pos[1] + height, depth},
				uv = {options.flip_x ? max : min, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0] + width, pos[1] + height, depth},
				uv = {options.flip_x ? min : max, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0] + width, pos[1], depth},
				uv = {options.flip_x ? min : max, max},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {pos[0], pos[1], depth},
				uv = {options.flip_x ? max : min, max},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
		},
	}

	if rotation > 0 || rotation < 0 {
		q_rotate(&quad, rotation, rect.x, rect.y, 0, 0)
	}
	b_append_quad(b, quad)
	return .None
}

b_tri :: proc(
	b: ^Batcher,
	v0: [2]f32,
	v1: [2]f32,
	v2: [2]f32,
	depth: f32,
	rotation: f32,
	t: Texture,
	options: BatcherTextureOptions,
) -> BatcherError {
	color: [4]f32 = {1.0, 1.0, 1.0, 1.0}
	for i := 0; i < 4; i += 1 {
		color[i] = options.color[i]
	}
	max: f32 = !options.flip_y ? 0.5 : 0.5
	min: f32 = !options.flip_y ? 0.5 : 0.5

	tri := Triangle {
		vertices = {
			{
				position = {v0.x, v0.y, depth},
				uv = {options.flip_x ? max : min, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {v1.x, v1.y, depth},
				uv = {options.flip_x ? min : max, min},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
			{
				position = {v2.x, v2.y, depth},
				uv = {options.flip_x ? min : max, max},
				color = color,
				data = {options.data_0, options.data_1, options.data_2},
			},
		},
	}

	if rotation > 0 || rotation < 0 {
		t_rotate(&tri, rotation)
	}
	b_append_tri(b, tri)
	return .None
}


// TODO: add procs for sprites

b_end :: proc(b: ^Batcher, uniforms: Uniform, buffer: ^wgpu.Buffer) -> BatcherError {
	if b.state == .Idle {
		return .End_Called_Twice
	}
	b.state = .Idle

	tri_count := b.tri_count - b.start_count
	if tri_count < 1 {
		return .None
	}

  switch &u in uniforms {
  case DiffuseUniform:
	  wgpu.QueueWriteBuffer(state.renderer.queue, buffer^, 0, &u, size_of(u))

  }

	passLabel: {
		encoder := b.encoder
		if encoder == nil {break passLabel}
		back_buffer := wgpu.SurfaceGetCurrentTexture(state.renderer.surface)
		back_buffer_view := wgpu.TextureCreateView(back_buffer.texture, nil)
		b.back_buffer = back_buffer
		b.back_buffer_view = back_buffer_view
		//defer {
		//wgpu.TextureViewRelease(back_buffer_view)
		//wgpu.TextureRelease(back_buffer.texture)
		//}
		if back_buffer_view == nil {
			break passLabel
		}

		color_attachments: []wgpu.RenderPassColorAttachment = {
			{
				view = b.ctx.output_handle != nil ? b.ctx.output_handle : back_buffer_view,
				loadOp = b.ctx.clear_color.a == 0 ? .Load : .Clear, //.Load,
				storeOp = .Store,
				clearValue = b.ctx.clear_color,
			},
		}

		render_pass_info: wgpu.RenderPassDescriptor = {
			label                = "Batcher render pass",
			colorAttachmentCount = len(color_attachments),
			colorAttachments     = raw_data(color_attachments),
		}

		// TODO write the unifoms to the buffer

		pass := wgpu.CommandEncoderBeginRenderPass(encoder, &render_pass_info)
		defer {
			wgpu.RenderPassEncoderEnd(pass)
			wgpu.RenderPassEncoderRelease(pass)
		}
		wgpu.RenderPassEncoderSetVertexBuffer(
			pass,
			0,
			b.vertex_buffer_handle,
			0,
			wgpu.BufferGetSize(b.vertex_buffer_handle),
		)
		wgpu.RenderPassEncoderSetIndexBuffer(
			pass,
			b.index_buffer_handle,
			.Uint32,
			0,
			wgpu.BufferGetSize(b.index_buffer_handle),
		)
		wgpu.RenderPassEncoderSetPipeline(pass, b.ctx.pipeline_handle)

		wgpu.RenderPassEncoderSetBindGroup(pass, 0, b.ctx.bind_group_handle)

		wgpu.RenderPassEncoderDrawIndexed(pass, b.vert_index, 1, b.start_count, 0, 0)
	}
	return .None
}

b_finish :: proc(b: ^Batcher) -> (wgpu.CommandBuffer, BatcherError) {
	if b.encoder != nil {
		wgpu.QueueWriteBuffer(
			state.renderer.queue,
			b.vertex_buffer_handle,
			0,
			raw_data(b.vertices),
			uint(b.tri_count * 3 * size_of(Vertex)),
		)
		wgpu.QueueWriteBuffer(
			state.renderer.queue,
			b.index_buffer_handle,
			0,
			raw_data(b.indices),
			uint(b.vert_index * size_of(u32)),
		)
		b.tri_count = 0
		b.vert_index = 0
		b.idx_index = 0
		commands := wgpu.CommandEncoderFinish(b.encoder)
		wgpu.CommandEncoderRelease(b.encoder)
		b.encoder = nil
		return commands, .None
	} else {
		return nil, .Null_Encoder
	}
}

b_submit :: proc(b: ^Batcher, commands: wgpu.CommandBuffer) {
	wgpu.QueueSubmit(state.renderer.queue, {commands})
	wgpu.CommandBufferRelease(commands)
	wgpu.SurfacePresent(state.renderer.surface)
	defer {
		wgpu.TextureViewRelease(b.back_buffer_view)
		wgpu.TextureRelease(b.back_buffer.texture)
	}
}

b_deinit :: proc(b: ^Batcher) {
	if b.encoder != nil {
		wgpu.CommandEncoderRelease(b.encoder)
	}
	b.encoder = nil
	wgpu.BufferRelease(b.index_buffer_handle)
	wgpu.BufferRelease(b.vertex_buffer_handle)
	delete(b.vertices)
	delete(b.indices)
}
