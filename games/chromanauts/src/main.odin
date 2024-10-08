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
Bullet :: struct {
	status: Bullet_Status,
	pos: rl.Vector2,
	size: rl.Vector2,
	accel: f32,
	vel: rl.Vector2,
	
	color: rl.Color,
}

Bullet_Status :: enum {
	Dead = 0,
	Alive,
	Exploding,
}

Enemy :: struct {
	status: Enemy_Status,
	pos_base: rl.Vector2,
	pos_offset: rl.Vector2,
	vel: rl.Vector2,

	color: rl.Color,
}

Enemy_Status :: enum {
	Dead = 0,
	Alive,
	Exploding,
}

Game :: struct {
	sh, sw: f32,

	mono_font: rl.Font,
	starfield: [200]Star,

	enemies: [200]Enemy,
	player: Player,
	player_bullets: [200]Bullet,
}

Player :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,

	thrust: rl.Vector2,
	accel: f32,
	vel: rl.Vector2,
	max_speed: f32,
	friction: f32,

	firing_requested: bool,
	fire_rate: f32,				// Number of bullets per second that the player can fire
	weapon_cd: f32,				// Remaining cooldown time in seconds until the weapon can fire again
}

Star :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
	color: rl.Color,
}

// procedures
game_close :: proc(game: ^Game) {
	rl.UnloadFont(game.mono_font)
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
		fire_rate = 4,
	}
	for &s in game.starfield {
		redness: f32 = clamp(rand.float32() * 2, 0.5, 1.0)
		color := rl.Color{200, u8(200*redness), u8(200*redness), 255}
		s.pos = rl.Vector2{game.sw * rand.float32(), game.sh * rand.float32()}
		s.vel = rl.Vector2{-20 * rand.float32(), 0}
		s.color = color
	}
}

game_render :: proc(game: ^Game) {
	using game

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	defer rl.EndDrawing()

	// stars
	for s in starfield {
		rl.DrawRectangleV(s.pos, rl.Vector2{2, 2}, s.color)
	}

	player_render(game)

	// bullets
	for pb in player_bullets {
		if pb.status == .Alive {
			rl.DrawRectangleV(pb.pos, pb.size, pb.color)
		}
	}
}

game_tick :: proc(game: ^Game) {
	using game
	dt := rl.GetFrameTime()

	player_input(game)
	player_tick(game)
	player.weapon_cd -= dt

	// stars
	for &s in starfield {
		s.pos += s.vel * dt
		if s.pos.x < 0 {
			s.pos.x = sw
		}
	}

	// bullets
	for &pb in player_bullets {
		if pb.status == .Alive {
			pb.vel.x += pb.accel * dt
			pb.pos += pb.vel * dt
			if pb.pos.x > sw {
				pb.status = .Dead
			}
		}
	}
}

player_can_fire :: proc(game: ^Game) -> bool {
	using game

	return player.weapon_cd <= 0
}

player_fire :: proc(game: ^Game) {
	using game

	if player_can_fire(game) {
		player.weapon_cd = (1 / player.fire_rate)
		for &b in player_bullets {
			if b.status == .Dead {
				b.status = .Alive
				b.pos = player.pos + rl.Vector2{player.size.x+15, player.size.y/2}
				b.size = rl.Vector2{10, 4}
				b.color = rl.RED
				b.vel = rl.Vector2{600, 0}
				b.accel = 100
				break
			}
		}
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

	player.firing_requested = true if rl.IsKeyDown(.SPACE) else false
}

player_render :: proc(game: ^Game) {
	using game

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
	rl.DrawRectangleV(player.pos, player.size, rl.RAYWHITE)
	rl.DrawRectangleV(
		player.pos + rl.Vector2{player.size.x/3, 5},
		rl.Vector2{((player.size.x/3)*2) + 10, 6},
		rl.RED,
	)
	rl.DrawRectangleV(
		player.pos + rl.Vector2{player.size.x/2, 1},
		rl.Vector2{player.size.x/2, 4},
		rl.BLUE,
	)
	rl.DrawRectangleV(
		player.pos + rl.Vector2{player.size.x/2, player.size.y-5},
		rl.Vector2{player.size.x/2, 4},
		rl.LIME,
	)
}

player_tick :: proc(game: ^Game) {
	using game
	dt := rl.GetFrameTime()

	// movement
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

	// weapon
	if player.firing_requested && player_can_fire(game) {
		player_fire(game)
	}
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
	rl.HideCursor()

	game := Game{}
	game_init(&game)
	defer game_close(&game)

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		game_tick(&game)
		game_render(&game)
	}
}