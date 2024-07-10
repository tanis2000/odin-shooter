# NOTE: changing this requires changing the same values in the `web/index.html`.
INITIAL_MEMORY_PAGES := 2000
MAX_MEMORY_PAGES     := 65536

PAGE_SIZE := 65536
INITIAL_MEMORY_BYTES := $(shell expr $(INITIAL_MEMORY_PAGES) \* $(PAGE_SIZE))
MAX_MEMORY_BYTES     := $(shell expr $(MAX_MEMORY_PAGES) \* $(PAGE_SIZE))

WGPU_JS    := $(shell odin root)/vendor/wgpu/wgpu.js
RUNTIME_JS := $(shell odin root)/vendor/wasm/js/runtime.js

run:
	#rm -rf out/debug/desktop
	mkdir -p out/debug/desktop
	odin run src -out:"out/debug/desktop/game" -debug

build-release:
	#rm -rf out/release/web
	mkdir -p out/release/web
	odin build src -target=js_wasm32 -out:"out/release/web/game.wasm" -extra-linker-flags:"--export-table --import-memory --initial-memory=$(INITIAL_MEMORY_BYTES) --max-memory=$(MAX_MEMORY_BYTES)"
	cp $(WGPU_JS) out/release/web/wgpu.js
	cp $(RUNTIME_JS) out/release/web/runtime.js
	cp web/index.html out/release/web/index.html

build-web:
	#rm -rf out/debug/web
	mkdir -p out/debug/web
	odin build src -target=js_wasm32 -out:"out/debug/web/game.wasm" -debug -extra-linker-flags:"--export-table --import-memory --initial-memory=$(INITIAL_MEMORY_BYTES) --max-memory=$(MAX_MEMORY_BYTES)"
	cp $(WGPU_JS) out/debug/web/wgpu.js
	cp $(RUNTIME_JS) out/debug/web/runtime.js
	cp web/index.html out/debug/web/index.html

run-web:
	echo "Starting server on port 8999"
	python3 -m http.server -d ./out/debug/web 8999

