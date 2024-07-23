package game

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
}
