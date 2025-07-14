package game

import intr "base:intrinsics"

import "core:fmt"
import "core:math/linalg"

import mu "vendor:microui"
import "vendor:wgpu"

Renderer :: struct {
	instance:           wgpu.Instance,
	surface:            wgpu.Surface,
	adapter:            wgpu.Adapter,
	device:             wgpu.Device,
	config:             wgpu.SurfaceConfiguration,
	queue:              wgpu.Queue,
	curr_encoder:       wgpu.CommandEncoder,
	curr_pass:          wgpu.RenderPassEncoder,
	curr_texture:       wgpu.SurfaceTexture,
	curr_view:          wgpu.TextureView,
	prev_buf_idx:       u32,
	buf_idx:            u32,
}

r_init_and_run :: proc() {
	r := &state.renderer

	r.instance = wgpu.CreateInstance(nil)
	r.surface = os_get_surface(r.instance)

	wgpu.InstanceRequestAdapter(
		r.instance,
		&{compatibleSurface = r.surface},
    { callback = handle_request_adapter },
	)
}

@(private = "file")
handle_request_adapter :: proc "c" (
	status: wgpu.RequestAdapterStatus,
	adapter: wgpu.Adapter,
	message: string,
	userdata1: rawptr,
  userdata2: rawptr,
) {
	context = state.ctx
	if status != .Success || adapter == nil {
		fmt.panicf("request adapter failure: [%v] %s", status, message)
	}
	state.renderer.adapter = adapter
	wgpu.AdapterRequestDevice(adapter, nil, { callback = handle_request_device })
}

@(private = "file")
handle_request_device :: proc "c" (
	status: wgpu.RequestDeviceStatus,
	device: wgpu.Device,
	message: string,
	userdata1: rawptr,
  userdata2: rawptr
) {
	context = state.ctx
	if status != .Success || device == nil {
		fmt.panicf("request device failure: [%v] %s", status, message)
	}
	state.renderer.device = device
	on_adapter_and_device()
}

@(private = "file")
on_adapter_and_device :: proc() {
	r := &state.renderer

	width, height := os_get_render_bounds()

	r.config = wgpu.SurfaceConfiguration {
		device      = r.device,
		usage       = {.RenderAttachment},
		format      = .BGRA8Unorm,
		width       = width,
		height      = height,
		presentMode = .Fifo,
		alphaMode   = .Opaque,
	}

	r.queue = wgpu.DeviceGetQueue(r.device)

	wgpu.SurfaceConfigure(r.surface, &r.config)

	post_init()
	os_run()
}

r_resize :: proc() {
	r := &state.renderer

	width, height := os_get_render_bounds()
	r.config.width, r.config.height = width, height
	wgpu.SurfaceConfigure(r.surface, &r.config)

  //TODO: move this elsewhere and make sure we do the same for the batchers just in case
	g_ui_write_consts()
}

r_present :: proc() {
	r := &state.renderer

	wgpu.SurfacePresent(r.surface)

	wgpu.TextureViewRelease(r.curr_view)
	wgpu.TextureRelease(r.curr_texture.texture)
}

