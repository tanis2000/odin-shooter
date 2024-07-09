package main

import game "../src"
import "core:math/rand"
import "core:mem"
import "base:runtime"
import rl "vendor:raylib"

foreign import "odin_env"

ctx: runtime.Context

tempAllocatorData: [mem.Megabyte * 4]byte
tempAllocatorArena: mem.Arena

mainMemoryData: [mem.Megabyte * 16]byte
mainMemoryArena: mem.Arena

@(export, link_name = "game_init")
game_init :: proc "c" () {
	ctx = runtime.default_context()
	context = ctx

	mem.arena_init(&mainMemoryArena, mainMemoryData[:])
	mem.arena_init(&tempAllocatorArena, tempAllocatorData[:])

	ctx.allocator = mem.arena_allocator(&mainMemoryArena)
	ctx.temp_allocator = mem.arena_allocator(&tempAllocatorArena)

	rl.InitWindow(game.WINDOW_WIDTH, game.WINDOW_HEIGHT, "Shooter")
	rl.SetTargetFPS(60)
}

@(export, link_name = "game_update")
game_update :: proc "contextless" () {
	context = ctx

	free_all(context.temp_allocator)
	game.update()
}
