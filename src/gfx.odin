package game

import "core:math/linalg"
import mu "vendor:microui"
import "vendor:wgpu"

Vertex :: struct {
	position: [3]f32,
	uv:       [2]f32,
	color:    [4]f32,
	data:     [3]f32,
}

Uniform :: union {
	DiffuseUniform,
}

DiffuseUniform :: struct {
	transform: matrix[4, 4]f32,
}

// Initialize everything related to graphics, including shaders, buffers, pipelines.
g_init :: proc() {
	diffuse_shader_module := wgpu.DeviceCreateShaderModule(
		state.renderer.device,
		&{
			label = "Diffuse shader module",
			nextInChain = &wgpu.ShaderModuleWGSLDescriptor {
				sType = .ShaderModuleWGSLDescriptor,
				code = #load("diffuse.wgsl"),
			},
		},
	)

	defer wgpu.ShaderModuleRelease(diffuse_shader_module)

	state.diffuse_uniforms_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&wgpu.BufferDescriptor {
			label = "Diffuse uniforms buffer",
			usage = {.CopyDst, .Uniform},
			size = size_of(matrix[4, 4]f32),
		},
	)

	bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		state.renderer.device,
		&{
			label = "Diffuse bind group layout",
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

	state.diffuse_bind_group = wgpu.DeviceCreateBindGroup(
		state.renderer.device,
		&{
			label = "Diffuse bind group",
			layout = bind_group_layout,
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{binding = 0, sampler = state.diffuse_map.sampler_handle},
					{binding = 1, textureView = state.diffuse_map.view_handle},
					{
						binding = 2,
						buffer = state.diffuse_uniforms_buffer,
						size = size_of(matrix[4, 4]f32),
					},
				},
			),
		},
	)


	pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		state.renderer.device,
		&{
			label = "Diffuse pipeline layout",
			bindGroupLayoutCount = 1,
			bindGroupLayouts = &bind_group_layout,
		},
	)

	state.diffuse_pipeline = wgpu.DeviceCreateRenderPipeline(
		state.renderer.device,
		&{
			label = "Diffuse render pipeline",
			layout = pipeline_layout,
			vertex = {
				module = diffuse_shader_module,
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
				module = diffuse_shader_module,
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

	state.shapes_bind_group = wgpu.DeviceCreateBindGroup(
		state.renderer.device,
		&{
			label = "Final bind group",
			layout = bind_group_layout,
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{binding = 0, sampler = state.pixel_tex.sampler_handle},
					{binding = 1, textureView = state.pixel_tex.view_handle},
					{
						binding = 2,
						buffer = state.diffuse_uniforms_buffer,
						size = size_of(matrix[4, 4]f32),
					},
				},
			),
		},
	)

	state.final_bind_group = wgpu.DeviceCreateBindGroup(
		state.renderer.device,
		&{
			label = "Final bind group",
			layout = bind_group_layout,
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{binding = 0, sampler = state.diffuse_output.sampler_handle},
					{binding = 1, textureView = state.diffuse_output.view_handle},
					{
						binding = 2,
						buffer = state.diffuse_uniforms_buffer,
						size = size_of(matrix[4, 4]f32),
					},
				},
			),
		},
	)

	g_init_ui()
}

g_init_ui :: proc() {
	state.ui.const_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&{
			label = "UI Constant buffer",
			usage = {.Uniform, .CopyDst},
			size = size_of(matrix[4, 4]f32),
		},
	)

	state.ui.atlas_texture = wgpu.DeviceCreateTexture(
		state.renderer.device,
		&{
			label = "microui default atlas",
			usage = {.TextureBinding, .CopyDst},
			dimension = ._2D,
			size = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
			format = .R8Unorm,
			mipLevelCount = 1,
			sampleCount = 1,
		},
	)
	state.ui.atlas_texture_view = wgpu.TextureCreateView(state.ui.atlas_texture, nil)

	state.ui.sampler = wgpu.DeviceCreateSampler(
		state.renderer.device,
		&{
			label = "UI sampler",
			addressModeU = .ClampToEdge,
			addressModeV = .ClampToEdge,
			addressModeW = .ClampToEdge,
			magFilter = .Nearest,
			minFilter = .Nearest,
			mipmapFilter = .Nearest,
			lodMinClamp = 0,
			lodMaxClamp = 32,
			compare = .Undefined,
			maxAnisotropy = 1,
		},
	)

	state.ui.vertex_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&{label = "UI Vertex Buffer", usage = {.Vertex, .CopyDst}, size = size_of(state.ui.vert_buf)},
	)

	state.ui.tex_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&{label = "UI Texture Buffer", usage = {.Vertex, .CopyDst}, size = size_of(state.ui.tex_buf)},
	)

	state.ui.color_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&{label = "UI Color Buffer", usage = {.Vertex, .CopyDst}, size = size_of(state.ui.color_buf)},
	)

	state.ui.index_buffer = wgpu.DeviceCreateBuffer(
		state.renderer.device,
		&{label = "UI Index Buffer", usage = {.Index, .CopyDst}, size = size_of(state.ui.index_buf)},
	)

	state.ui.bind_group_layout = wgpu.DeviceCreateBindGroupLayout(
		state.renderer.device,
		&{
      label = "UI Bind Group Layout",
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

	state.ui.bind_group = wgpu.DeviceCreateBindGroup(
		state.renderer.device,
		&{
      label = "UI Bind Group",
			layout = state.ui.bind_group_layout,
			entryCount = 3,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{binding = 0, sampler = state.ui.sampler},
					{binding = 1, textureView = state.ui.atlas_texture_view},
					{binding = 2, buffer = state.ui.const_buffer, size = size_of(matrix[4, 4]f32)},
				},
			),
		},
	)

	state.ui.module = wgpu.DeviceCreateShaderModule(
		state.renderer.device,
		&{
      label = "UI Module",
			nextInChain = &wgpu.ShaderModuleWGSLDescriptor {
				sType = .ShaderModuleWGSLDescriptor,
				code = #load("shader.wgsl"),
			},
		},
	)

	state.ui.pipeline_layout = wgpu.DeviceCreatePipelineLayout(
		state.renderer.device,
		&{label="UI Pipeline Layout", bindGroupLayoutCount = 1, bindGroupLayouts = &state.ui.bind_group_layout},
	)
	state.ui.pipeline = wgpu.DeviceCreateRenderPipeline(
		state.renderer.device,
		&{
      label = "UI Pipeline",
			layout = state.ui.pipeline_layout,
			vertex = {
				module = state.ui.module,
				entryPoint = "vs_main",
				bufferCount = 3,
				buffers = raw_data(
					[]wgpu.VertexBufferLayout {
						{
							arrayStride = 8,
							attributeCount = 1,
							attributes = &wgpu.VertexAttribute {
								format = .Float32x2,
								shaderLocation = 0,
							},
						},
						{
							arrayStride = 8,
							attributeCount = 1,
							attributes = &wgpu.VertexAttribute {
								format = .Float32x2,
								shaderLocation = 1,
							},
						},
						{
							arrayStride = 4,
							attributeCount = 1,
							attributes = &wgpu.VertexAttribute {
								format = .Uint32,
								shaderLocation = 2,
							},
						},
					},
				),
			},
			fragment = &{
				module = state.ui.module,
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

	wgpu.QueueWriteTexture(
		state.renderer.queue,
		&{texture = state.ui.atlas_texture},
		&mu.default_atlas_alpha,
		mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT,
		&{bytesPerRow = mu.DEFAULT_ATLAS_WIDTH, rowsPerImage = mu.DEFAULT_ATLAS_HEIGHT},
		&{mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
	)

	g_ui_write_consts()
}

g_ui_write_consts :: proc() {
	r := &state.renderer

	// Transformation matrix to convert from screen to device pixels and scale based on DPI.
	dpi := os_get_dpi()
	width, height := os_get_render_bounds()
	fw, fh := f32(width), f32(height)
	transform := linalg.matrix_ortho3d(0, fw, fh, 0, -1, 1) * linalg.matrix4_scale(dpi)

	wgpu.QueueWriteBuffer(r.queue, state.ui.const_buffer, 0, &transform, size_of(transform))
}
