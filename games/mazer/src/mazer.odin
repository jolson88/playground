package mazer

import "core:fmt"
import "core:math"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "qv"
import rl "vendor:raylib"

// structs
Planet :: struct {
	color: rl.Color,
	pos: rl.Vector2,
	radius: f32,
	population: i64,
}

Player :: struct {
	angle: f32,				// Our current position around the planet in radians per second
	angular_vel: f32,		// The rotational velocity we have in radians per second
	color: rl.Color,
	distance: f32,			// The distance between ship's center and planet's center
	engine_torque: f32,		// Torque in newton meters
	friction: f32,			// General damping factor for when engines aren't active
	mass: f32,				// Mass in kilograms
	pos: rl.Vector2,
	score: i64,
}

Battle :: struct {
	wave: i64,
}

// variables
MAX_POP_DIGITS   :: 12
MAX_SCORE_DIGITS :: 8
sw, sh: f32
hud_font: rl.Font
hud_font_size: i32 = 36

battle: Battle
planet: Planet
player: Player

segment_lookup := map[rune][7]bool{
	'0' = [7]bool{ true,  true,  true,  true,  true,  true,  false },
	'1' = [7]bool{ false, true,  true,  false, false, false, false },
	'2' = [7]bool{ true,  true,  false, true,  true,  false, true  },
	'3' = [7]bool{ true,  true,  true,  true,  false, false, true  },
	'4' = [7]bool{ false, true,  true,  false, false, true,  true  },
	'5' = [7]bool{ true,  false, true,  true,  false, true,  true  },
	'6' = [7]bool{ true,  false, true,  true,  true,  true,  true  },
	'7' = [7]bool{ true,  true,  true,  false, false, false, false },
	'8' = [7]bool{ true,  true,  true,  true,  true,  true,  true  },
	'9' = [7]bool{ true,  true,  true,  true,  false, true,  true  },
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

	qv.create_window("Mazer", .Seven_Twenty_P)	

    src_dir := filepath.dir(#file, context.temp_allocator)
    hud_font_path := filepath.join([]string{src_dir, "resources", "fonts", "heavy_data.ttf"}, context.temp_allocator)
    hud_font = rl.LoadFontEx(strings.clone_to_cstring(hud_font_path, context.temp_allocator), hud_font_size, nil, 0)
    defer rl.UnloadFont(hud_font)

	init()
    for !rl.WindowShouldClose() {
		qv.begin()
		defer qv.present()
		
		do_battle()	
	}
}

do_battle :: proc() {
	rl.ClearBackground(rl.BLACK)

	player_input()

	render_planet()
	render_player()
	render_hud()
}

init :: proc() {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	planet.pos        = rl.Vector2{sw*0.05, sh*0.9}
	planet.color      = rl.DARKGREEN
	planet.population = 6_000_000_000
	planet.radius     = 30

	player.angle         = 5.5
	player.color         = rl.BLUE
	player.distance      = 40
	player.engine_torque = 30_000
	player.friction      = 1.8
	player.mass	         = 7_000
	player.score		 = 0
}

player_input :: proc() {
	angular_accel: f32
	dt := rl.GetFrameTime()
	if rl.IsKeyDown(.RIGHT) { angular_accel = +player.engine_torque / player.mass }
	if rl.IsKeyDown(.LEFT)  { angular_accel = -player.engine_torque / player.mass }

	player.angular_vel = player.angular_vel + angular_accel * dt
	player.angular_vel = player.angular_vel * (1 - player.friction * dt)

	player.angle = player.angle + player.angular_vel * dt
	if (player.angle > math.TAU) { player.angle = player.angle-math.TAU }
	if (player.angle < 0)        { player.angle = player.angle+math.TAU }
	
	player.pos.x = planet.pos.x + player.distance * math.cos_f32(player.angle)
	player.pos.y = planet.pos.y + player.distance * math.sin_f32(player.angle)
}

render_hud :: proc() {
	segment_digit_height: f32 = 28
	segment_padding: f32 = 4

	label      := "score"
	label_c    := strings.clone_to_cstring(label, context.temp_allocator)
	label_size := rl.MeasureTextEx(hud_font, label_c, f32(hud_font_size), 0)
	label_x    := (sw - label_size.x) / 2
	rl.DrawTextEx(hud_font, label_c, rl.Vector2{label_x, segment_digit_height}, f32(hud_font_size), 0, rl.BLUE)
	seven_segment_display(
		player.score, MAX_SCORE_DIGITS,
		rl.Vector2{sw/2, (segment_digit_height/2)+segment_padding},
		segment_digit_height,
		segment_padding,
		rl.LIGHTGRAY
	)

	label      = "population"
	label_c    = strings.clone_to_cstring(label, context.temp_allocator)
	label_size = rl.MeasureTextEx(hud_font, label_c, f32(hud_font_size), 0)
	label_x    = 60
	rl.DrawTextEx(hud_font, label_c, rl.Vector2{label_x, segment_digit_height}, f32(hud_font_size), 0, rl.BLUE)
	seven_segment_display(
		planet.population, MAX_POP_DIGITS,
		rl.Vector2{label_x+(label_size.x/2), (segment_digit_height/2)+segment_padding},
		segment_digit_height,
		segment_padding,
		rl.LIGHTGRAY
	)

	label      = "wave"
	label_c    = strings.clone_to_cstring(label, context.temp_allocator)
	label_size = rl.MeasureTextEx(hud_font, label_c, f32(hud_font_size), 0)
	label_x    = sw-label_size.x-60
	rl.DrawTextEx(hud_font, label_c, rl.Vector2{label_x, segment_digit_height}, f32(hud_font_size), 0, rl.BLUE)
	seven_segment_display(
		battle.wave, 3,
		rl.Vector2{label_x+(label_size.x/2), (segment_digit_height/2)+segment_padding},
		segment_digit_height,
		segment_padding,
		rl.LIGHTGRAY
	)
}

render_planet :: proc() {
	rl.DrawCircleV(planet.pos, planet.radius, planet.color)
}

render_player :: proc() {
    ship_len: f32   = 15
    ship_width: f32 = 15

    direction := rl.Vector2{math.cos_f32(player.angle), math.sin_f32(player.angle)}
    p1 := rl.Vector2{ player.pos.x + direction.y * ship_width / 2, player.pos.y - direction.x * ship_width / 2 }
    p2 := rl.Vector2{ player.pos.x - direction.y * ship_width / 2, player.pos.y + direction.x * ship_width / 2 }
	p3 := player.pos + direction * ship_len

    rl.DrawTriangle(p1, p2, p3, player.color);
}

seven_segment_display :: proc(val: i64, digits: i8, center: rl.Vector2, digit_height: f32, padding: f32, color: rl.Color) {
	digit_width := digit_height / 2
	display_width  := digit_width*f32(digits) + padding*f32(digits)
	display_height := digit_height
	seg_size: f32 = 3
	seg_width: f32 = digit_width-(seg_size*2)
	seg_height: f32 = (digit_height-seg_size*3)/2

	// Generate a string of length `digits`, padded left with 0s, of the value `val`
	num_buf := make_slice([]u8, digits*2, context.temp_allocator)
	for i in 0..<len(num_buf) {
		num_buf[i] = '0'
	}
	if val > 0 {
		num_raw := fmt.tprintf("%i", val)
		for i := 0; i < math.min(int(digits), len(num_raw)); i=i+1 {
			num_buf[len(num_buf)-1-i] = num_raw[len(num_raw)-1-i]
		}
	}
	num := string(num_buf[digits:digits*2])

	seg_x: f32 = center.x-(display_width/2)
	seg_y: f32 = center.y-(display_height/2)
	for r in num {
		segments := segment_lookup[r]
		for seg_on, seg in segments {
			if !seg_on {
				continue
			}
			switch seg {
			case 0: rl.DrawRectangleV(rl.Vector2{seg_x+seg_size, seg_y}, rl.Vector2{seg_width, seg_size}, color)
			case 1: rl.DrawRectangleV(rl.Vector2{seg_x+seg_width+seg_size, seg_y+seg_size}, rl.Vector2{seg_size, seg_height}, color)
			case 2: rl.DrawRectangleV(rl.Vector2{seg_x+seg_width+seg_size, seg_y+seg_size*2+seg_height}, rl.Vector2{seg_size, seg_height}, color)
			case 3: rl.DrawRectangleV(rl.Vector2{seg_x+seg_size, seg_y+seg_size*2+seg_height*2}, rl.Vector2{seg_width, seg_size}, color)
			case 4: rl.DrawRectangleV(rl.Vector2{seg_x, seg_y+seg_height+seg_size*2}, rl.Vector2{seg_size, seg_height}, color)
			case 5: rl.DrawRectangleV(rl.Vector2{seg_x, seg_y+seg_size}, rl.Vector2{seg_size, seg_height}, color)
			case 6: rl.DrawRectangleV(rl.Vector2{seg_x+seg_size, seg_y+seg_size+seg_height}, rl.Vector2{seg_width, seg_size}, color)
			}
		}
		seg_x = seg_x+digit_width+padding
	}
}