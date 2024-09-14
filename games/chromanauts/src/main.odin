package chromanauts

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

// structures
Game :: struct {
	sh, sw: f32,
	mono_font: rl.Font,
}

// procedures
main :: proc() {
    when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("\n=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("\n=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	rl.InitWindow(1280, 720, "Chromanauts")
	rl.SetTargetFPS(60)

	game := Game{}
	game_init(&game)
	defer game_close(&game)

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		
		game_frame(&game)	
	}
}

game_close :: proc(game: ^Game) {
	rl.UnloadFont(game.mono_font)
}

game_frame :: proc(game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)
	rl.EndDrawing()
}

game_init :: proc(game: ^Game, seed: Maybe(u64) = nil) {
	game.sw, game.sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	src_dir   := filepath.dir(#file, context.temp_allocator)
    font_path := filepath.join([]string{src_dir, "resources", "fonts", "DroidSansMono.ttf"}, context.temp_allocator)
	game.mono_font = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), 40, nil, 0)

	r := rand.create(seed.? or_else u64(time.time_to_unix(time.now())))
	context.random_generator = rand.default_random_generator(&r)
}
