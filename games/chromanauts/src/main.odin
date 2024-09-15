package chromanauts

import "core:fmt"
import "core:math"
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

	player: Player,
}

Player :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,

	thrust: rl.Vector2,
	accel: f32,
	vel: rl.Vector2,
	max_speed: f32,
	friction: f32,
}

// procedures
game_close :: proc(game: ^Game) {
	rl.UnloadFont(game.mono_font)
}

game_frame :: proc(game: ^Game) {
	player_input(game)
	player_update(game)

	render_frame(game)
}

game_init :: proc(game: ^Game, seed: Maybe(u64) = nil) {
	game.sw, game.sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	src_dir   := filepath.dir(#file, context.temp_allocator)
    font_path := filepath.join([]string{src_dir, "resources", "fonts", "DroidSansMono.ttf"}, context.temp_allocator)
	game.mono_font = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), 40, nil, 0)

	r := rand.create(seed.? or_else u64(time.time_to_unix(time.now())))
	context.random_generator = rand.default_random_generator(&r)

	game.player = Player{
		pos = rl.Vector2{100, 300},
		size = rl.Vector2{32, 16},
		accel = 8,
		max_speed = 6,
		friction = 4,
	}
}

player_input :: proc(game: ^Game) {
	using game

	dir := rl.Vector2{0, 0}
	if rl.IsKeyDown(.UP)    { dir.y = -1 }
	if rl.IsKeyDown(.DOWN)  { dir.y = +1 }
	if rl.IsKeyDown(.LEFT)  { dir.x = -1 }
	if rl.IsKeyDown(.RIGHT) { dir.x = +1 }
	player.thrust = rl.Vector2Normalize(dir)
}

player_update :: proc(game: ^Game) {
	using game
	dt := rl.GetFrameTime()

	accel_vec := player.thrust * player.accel * dt
	player.vel += accel_vec
	if rl.Vector2Length(player.vel) > player.max_speed {
		player.vel = rl.Vector2Normalize(player.vel) * player.max_speed
	}
	player.pos += player.vel
	margin: f32 = 20
	if player.pos.y + player.size.y + margin > sh {
		player.pos.y = sh - player.size.y - margin
	}
	if player.pos.y < margin { player.pos.y = margin }
	if player.pos.x < margin { player.pos.x = margin }
	if player.pos.x + player.size.x + margin > sw {
		player.pos.x = sw - player.size.x - margin
	}

	if rl.Vector2Length(player.thrust) < math.F32_EPSILON {
		player.vel *= (1 - player.friction * dt)
	}
}

render_frame :: proc(game: ^Game) {
	using game

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawFPS(5, 5)

	// player
	if rand.float32() < 0.95 {
		rl.DrawTriangle(
			player.pos + rl.Vector2{-03, player.size.y-4},
			player.pos + rl.Vector2{-03, 4},
			player.pos + rl.Vector2{-11, player.size.y/2},
			rl.ColorBrightness(rl.ORANGE, clamp(rand.float32()-0.5, -0.1, 0.1)),
		)
	}
	if player.thrust.y > 0 {
		rl.DrawTriangle(
			player.pos + rl.Vector2{09, -3},
			player.pos + rl.Vector2{21, -3},
			player.pos + rl.Vector2{15, -8},
			rl.ORANGE,
		)
	}
	if player.thrust.y < 0 {
		rl.DrawTriangle(
			player.pos + rl.Vector2{09, player.size.y+3},
			player.pos + rl.Vector2{15, player.size.y+8},
			player.pos + rl.Vector2{21, player.size.y+3},
			rl.ORANGE,
		)
	}
	if player.thrust.x > 0 {
		rl.DrawTriangle(
			player.pos + rl.Vector2{-13, player.size.y-4},
			player.pos + rl.Vector2{-13, 4},
			player.pos + rl.Vector2{-21, player.size.y/2},
			rl.ORANGE,
		)
	}
	if player.thrust.x < 0 {
		rl.DrawTriangle(
			player.pos + rl.Vector2{player.size.x+0, -3},
			player.pos + rl.Vector2{player.size.x+6, -5},
			player.pos + rl.Vector2{player.size.x+0, -7},
			rl.ORANGE,
		)
		rl.DrawTriangle(
			player.pos + rl.Vector2{player.size.x+0, player.size.y+3},
			player.pos + rl.Vector2{player.size.x+0, player.size.y+7},
			player.pos + rl.Vector2{player.size.x+6, player.size.y+5},
			rl.ORANGE,
		)
	}

	rl.DrawRectangleV(player.pos, player.size, rl.RAYWHITE)
	rl.DrawTriangle(
		player.pos + rl.Vector2{player.size.x, 2},
		player.pos + rl.Vector2{player.size.x, player.size.y-2},
		player.pos + rl.Vector2{player.size.x+player.size.y, player.size.y/2},
		rl.RED,
	)
	rl.DrawRectangleV(
		player.pos + rl.Vector2{player.size.x, 0} + rl.Vector2{-5, 0},
		rl.Vector2{5, player.size.y},
		rl.LIME
	)
	rl.DrawRectangleV(
		player.pos + rl.Vector2{player.size.x, 0} + rl.Vector2{-10, 0},
		rl.Vector2{5, player.size.y},
		rl.BLUE
	)

	rl.EndDrawing()
}

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