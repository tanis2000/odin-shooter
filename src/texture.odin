package game

import "core:bytes"
import image "core:image/png"
import "core:fmt"
import "vendor:wgpu"

Texture :: struct {
	handle:         wgpu.Texture,
	view_handle:    wgpu.TextureView,
	sampler_handle: wgpu.Sampler,
	image:          ^image.Image,
}

TextureOptions :: struct {
	address_mode:    wgpu.AddressMode,
	filter:          wgpu.FilterMode,
	format:          wgpu.TextureFormat,
	storage_binding: bool,
}

default_texture_options :: proc() -> TextureOptions {
  return TextureOptions {
    format = .R8Unorm,
    address_mode = .ClampToEdge,
    filter = .Nearest,
    storage_binding = false,
  }
}

load_texture_from_memory :: proc(data: []u8, options: TextureOptions) -> Texture {
	img, err := image.load_from_bytes(data)
  if err != nil {
    fmt.println(err)
  }
	return create_texture(img, options)
}

create_texture :: proc(img: ^image.Image, options: TextureOptions) -> Texture {
	r := &state.renderer
	tex: Texture
	tex.image = img

	tex.handle = wgpu.DeviceCreateTexture(
		r.device,
		&{
			usage         = {.TextureBinding, .CopyDst, .RenderAttachment},
			dimension     = ._2D,
			size          = {u32(img.width), u32(img.height), 1},
			format        = options.format,
			mipLevelCount = 1,
			sampleCount   = 1,
			//storage_binding = options.storage_binding, // no clue where this actually lives in
		},
	)
	tex.view_handle = wgpu.TextureCreateView(tex.handle, nil)

	tex.sampler_handle = wgpu.DeviceCreateSampler(
		r.device,
		&{
			addressModeU = options.address_mode,
			addressModeV = options.address_mode,
			addressModeW = options.address_mode,
			magFilter = options.filter,
			minFilter = options.filter,
			mipmapFilter = .Nearest,
			lodMinClamp = 0,
			lodMaxClamp = 32,
			compare = .Undefined,
			maxAnisotropy = 1,
		},
	)

	wgpu.QueueWriteTexture(
		r.queue,
		&{texture = tex.handle},
		raw_data(img.pixels.buf),
		uint(img.width * img.height),
		&{bytesPerRow = u32(img.width), rowsPerImage = u32(img.height)},
		&{u32(img.width), u32(img.height), 1},
	)
	return tex
}
