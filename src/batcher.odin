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
	quad_count:             u32,
	start_count:            u32,
	state:                  BatcherState,
	pipeline_handle:        wgpu.RenderPipeline,
	bind_group_handle:      wgpu.BindGroup,
	tex_view:               wgpu.TextureView,
	back_buffer:            wgpu.SurfaceTexture,
	back_buffer_view:       wgpu.TextureView,
	uniforms_buffer_handle: wgpu.Buffer,
}

BatcherContext :: struct {
	//pipeline_handle:   wgpu.RenderPipeline,
	//bind_group_randle: wgpu.BindGroup,
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

b_init :: proc(max_quads: u32) -> Batcher {
	fmt.println("init")
	vertices: [dynamic]Vertex = make([dynamic]Vertex, max_quads * 4)
	indices: [dynamic]u32 = make([dynamic]u32, max_quads * 6)
	i: u32 = 0
	for i < max_quads {
		indices[i * 2 * 3 + 0] = i * 4 + 0
		indices[i * 2 * 3 + 1] = i * 4 + 1
		indices[i * 2 * 3 + 2] = i * 4 + 3
		indices[i * 2 * 3 + 3] = i * 4 + 1
		indices[i * 2 * 3 + 4] = i * 4 + 2
		indices[i * 2 * 3 + 5] = i * 4 + 3
		i += 1
	}


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

	uniforms_buffer_handle := wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&wgpu.BufferDescriptor {
			label = "Batcher uniforms buffer",
			usage = {.CopyDst, .Uniform},
			size = size_of(matrix[4, 4]f32),
		},
	)
	/*
	texture := wgpu.DeviceCreateTexture(
		state.renderer.device,
		&{
			label = "Batcher texture",
			usage = {.TextureBinding, .CopyDst},
			dimension = ._2D,
			size = {u32(state.tex.image.width), u32(state.tex.image.height), 1},
			format = .RGBA8Unorm,
			mipLevelCount = 1,
			sampleCount = 1,
		},
	)
  */

	tex_view := wgpu.TextureCreateView(state.tex.handle)

	bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		state.renderer.device,
		&{
			label = "Batcher bind group layout",
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupLayoutEntry {
					{binding = 0, visibility = {.Fragment}, sampler = {type = .Filtering}},
					{
						binding = 1,
						visibility = {.Fragment},
						texture = {
							sampleType = .Float,
							viewDimension = ._2D,
							multisampled = false,
						},
					},
					{
						binding = 2,
						visibility = {.Vertex},
						buffer = {type = .Uniform, minBindingSize = size_of(matrix[4, 4]f32)},
					},
				},
			),
		},
	)

	bind_group := wgpu.DeviceCreateBindGroup(
		state.renderer.device,
		&{
			label = "Batcher bind group",
			layout = bind_group_layout,
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{binding = 0, sampler = state.tex.sampler_handle},
					{binding = 1, textureView = tex_view},
					{
						binding = 2,
						buffer = uniforms_buffer_handle,
						size = size_of(matrix[4, 4]f32),
					},
				},
			),
		},
	)

	module := wgpu.DeviceCreateShaderModule(
		state.renderer.device,
		&{
			label = "Batcher diffuse shader module",
			nextInChain = &wgpu.ShaderModuleWGSLDescriptor {
				sType = .ShaderModuleWGSLDescriptor,
				code = #load("diffuse.wgsl"),
			},
		},
	)

	pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		state.renderer.device,
		&{
			label = "Batcher pipeline layout",
			bindGroupLayoutCount = 1,
			bindGroupLayouts = &bind_group_layout,
		},
	)
	pipeline := wgpu.DeviceCreateRenderPipeline(
		state.renderer.device,
		&{
			label = "Batcher render pipeline",
			layout = pipeline_layout,
			vertex = {
				module = module,
				entryPoint = "vs_main",
				bufferCount = 1,
				buffers = raw_data(
					[]wgpu.VertexBufferLayout {
						{
							arrayStride = size_of(Vertex),
							stepMode = .Vertex,
							attributeCount = 4,
							attributes = raw_data(
								[]wgpu.VertexAttribute {
									{
										format = .Float32x3,
										offset = u64(offset_of(Vertex, position)),
										shaderLocation = 0,
									},
									{
										format = .Float32x2,
										offset = u64(offset_of(Vertex, uv)),
										shaderLocation = 1,
									},
									{
										format = .Float32x4,
										offset = u64(offset_of(Vertex, color)),
										shaderLocation = 2,
									},
									{
										format = .Float32x3,
										offset = u64(offset_of(Vertex, data)),
										shaderLocation = 3,
									},
								},
							),
						},
					},
				),
			},
			fragment = &{
				module = module,
				entryPoint = "fs_main",
				targetCount = 1,
				targets = &wgpu.ColorTargetState {
					format = .BGRA8Unorm,
					blend = &{
						alpha = {
							srcFactor = .SrcAlpha,
							dstFactor = .OneMinusSrcAlpha,
							operation = .Add,
						},
						color = {
							srcFactor = .SrcAlpha,
							dstFactor = .OneMinusSrcAlpha,
							operation = .Add,
						},
					},
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			},
			primitive = {topology = .TriangleList, cullMode = .None},
			multisample = {count = 1, mask = 0xFFFFFFFF},
		},
	)


	return Batcher {
		vertices = vertices,
		vertex_buffer_handle = vertex_buffer_handle,
		indices = indices,
		index_buffer_handle = index_buffer_handle,
		pipeline_handle = pipeline,
		bind_group_handle = bind_group,
		tex_view = tex_view,
		uniforms_buffer_handle = uniforms_buffer_handle,
	}
}

b_write_uniforms :: proc(b: Batcher) {
	r := &state.renderer

	// Transformation matrix to convert from screen to device pixels and scale based on DPI.
	dpi := os_get_dpi()
	width, height := os_get_render_bounds()
	fw, fh := f32(width), f32(height)
	transform := linalg.matrix_ortho3d(0, fw, fh, 0, -1, 1) * linalg.matrix4_scale(dpi)

	wgpu.QueueWriteBuffer(r.queue, b.uniforms_buffer_handle, 0, &transform, size_of(transform))
}


b_begin :: proc(b: ^Batcher, ctx: BatcherContext) -> BatcherError {
	fmt.println("begin")
	if b.state == .Progress {
		return .Begin_Called_Twice
	}
	b.ctx = ctx
	b.state = .Progress
	b.start_count = b.quad_count
	if b.encoder == nil {
		fmt.println("Batcher: creating new encoder")
		b.encoder = wgpu.DeviceCreateCommandEncoder(state.renderer.device, nil)
	}
	return .None
}

b_has_capacity :: proc(b: Batcher) -> bool {
	return int(b.quad_count * 4) < len(b.vertices) - 1
}

b_resize :: proc(b: ^Batcher, max_quads: u32) -> BatcherError {
	if max_quads <= b.quad_count {
		return .Buffer_Too_Small
	}

	fmt.println("resizing")

	resize(&b.vertices, max_quads * 4)
	resize(&b.indices, max_quads * 6)
	i: u32 = 0
	for i < max_quads {
		b.indices[i * 2 * 3 + 0] = i * 4 + 0
		b.indices[i * 2 * 3 + 1] = i * 4 + 1
		b.indices[i * 2 * 3 + 2] = i * 4 + 3
		b.indices[i * 2 * 3 + 3] = i * 4 + 1
		b.indices[i * 2 * 3 + 4] = i * 4 + 2
		b.indices[i * 2 * 3 + 5] = i * 4 + 3
		i += 1
	}

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

b_append :: proc(b: ^Batcher, quad: Quad) -> BatcherError {
	if b.state == .Idle {
		return .Call_Begin_First
	}
	if !b_has_capacity(b^) {
		b_resize(b, b.quad_count * 2)
	}
	for vertex in quad.vertices {
		b.vertices[b.vert_index] = vertex
		b.vert_index += 1
	}
	b.quad_count += 1
	return .None
}

b_default_batcher_texture_options :: proc() -> BatcherTextureOptions {
  return BatcherTextureOptions {
    flip_x= false,
    flip_y = false,
    color = {1.0, 1.0, 1.0, 1.0},
  }
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

	quad: Quad = {
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
	b_append(b, quad)
	return .None
}

// TODO: add procs for sprites

b_end :: proc(b: ^Batcher, buffer: ^wgpu.Buffer) -> BatcherError {
	if b.state == .Idle {
		return .End_Called_Twice
	}
	b.state = .Idle

	quad_count := b.quad_count - b.start_count
	if quad_count < 1 {
		return .None
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
				loadOp = .Clear,
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
		wgpu.RenderPassEncoderSetPipeline(pass, b.pipeline_handle)

		wgpu.RenderPassEncoderSetBindGroup(pass, 0, b.bind_group_handle)

		wgpu.RenderPassEncoderDrawIndexed(pass, quad_count * 6, 1, b.start_count * 6, 0, 0)
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
			uint(b.quad_count * 4 * size_of(Vertex)),
		)
		wgpu.QueueWriteBuffer(
			state.renderer.queue,
			b.index_buffer_handle,
			0,
			raw_data(b.indices),
			uint(b.quad_count * 6 * size_of(u32)),
		)
    b_write_uniforms(b^)
		b.quad_count = 0
		b.vert_index = 0
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
