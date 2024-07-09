SOURCE_PKG := src
WEB_KPG := web
STACK_SIZE := 1048576
HEAP_SIZE := 67108864

run:
	#rm -rf out/debug/desktop
	mkdir -p out/debug/desktop
	odin run $(SOURCE_PKG) -out:"out/debug/desktop/$(SOURCE_PKG)" -debug

build-release:
	#rm -rf out/release
	mkdir -p out/release/desktop
	odin run $(SOURCE_PKG) -out:"out/release/desktop/$(SOURCE_PKG)"

build-web:
	#rm -rf out/debug/web
	mkdir -p out/debug/web
	mkdir -p out/debug/.intermediate
	odin build $(WEB_KPG) -target=freestanding_wasm32 -out:"out/debug/.intermediate/$(SOURCE_PKG)" -build-mode:obj -debug -show-system-calls
	emcc -o out/debug/$(WEB_KPG)/index.html $(WEB_KPG)/main.c out/debug/.intermediate/$(SOURCE_PKG).wasm.o -sUSE_SDL2=1 -sGL_ENABLE_GET_PROC_ADDRESS -DWEB_BUILD -sSTACK_SIZE=$(STACK_SIZE) -sTOTAL_MEMORY=$(HEAP_SIZE) -sERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file $(WEB_KPG)/shell.html

