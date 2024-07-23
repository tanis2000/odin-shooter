package game

import "core:bytes"
import "core:fmt"
import image "core:image/png"
import "vendor:wgpu"

Texture :: struct {
	handle:         wgpu.Texture,
	view_handle:    wgpu.TextureView,
	sampler_handle: wgpu.Sampler,
	image:          image.Image,
}

TextureOptions :: struct {
	address_mode:    wgpu.AddressMode,
	filter:          wgpu.FilterMode,
	format:          wgpu.TextureFormat,
	storage_binding: bool,
}

default_texture_options :: proc() -> TextureOptions {
	return TextureOptions {
		format = .RGBA8Unorm,
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
	return create_texture(img^, options)
}

create_texture :: proc(img: image.Image, options: TextureOptions) -> Texture {
	r := &state.renderer
	tex: Texture
	tex.image = img

	tex.handle = wgpu.DeviceCreateTexture(
		r.device,
		&{
			label         = "texture loaded from disk",
			usage         = {.TextureBinding, .CopyDst, .RenderAttachment},
			dimension     = ._2D,
			size          = {u32(img.width), u32(img.height), 1},
			format        = options.format,
			mipLevelCount = 1,
			sampleCount   = 1,
		},
	)
	tex.view_handle = wgpu.TextureCreateView(
		tex.handle,
		&{format = options.format, dimension = ._2D, arrayLayerCount = 1, mipLevelCount = 1},
	)

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
		uint(img.width * 4 * img.height),
		&{bytesPerRow = u32(img.width * 4), rowsPerImage = u32(img.height)},
		&{u32(img.width), u32(img.height), 1},
	)
	return tex
}

t_create_empty :: proc(width: u32, height: u32, opts: TextureOptions) -> Texture {
  img : image.Image = {
    width = int(width),
    height = int(height),
    channels = 4,
    depth = 8,
  }
  buf := make([]byte, width * height)
  bytes.buffer_init(&img.pixels, buf)
  return create_texture(img, opts)
}

