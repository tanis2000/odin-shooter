struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
    @location(3) data: vec3<f32>
}
@vertex fn vs_main(
    @builtin(vertex_index) in_vertex_index: u32,
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
    @location(3) data: vec3<f32>
) -> VertexOut {
    var output: VertexOut;
    var vert_mode = i32(data[0]);
    var time = data[2];
    var pos = position;


    output.position_clip = vec4(pos.xy, 0.0, 1.0);
    output.position = pos;
    output.uv = uv;
    output.color = color;
    output.data = data;
    return output;
}

@group(0) @binding(0) var diffuse_sampler: sampler;
@group(0) @binding(1) var diffuse: texture_2d<f32>;

@fragment fn fs_main(
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
    @location(3) data: vec3<f32>,
) -> @location(0) vec4<f32> {
    var base_color = textureSample(diffuse, diffuse_sampler, uv);

    return base_color * color;
}