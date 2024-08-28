package mazer

import "core:fmt"
import "core:math"
import "core:mem"
import "qv"
import rl "vendor:raylib"

planet_color: rl.Color
planet_pos: rl.Vector2
planet_radius: f32

player_color: rl.Color
player_angle: f32			// The angle in radians of the ship's position around the planet
player_distance: f32 		// The distance from the center of the planet in pixels
player_pos: rl.Vector2
player_speed_rps: f32		// The player's speed in radians per second around the planet

shield_radius: f32
shield_segments: i32
shield_color: rl.Color

sw, sh: f32					// The screen width and screen height

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
}

init :: proc() {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	planet_pos      = rl.Vector2{sw*0.1, sh*0.85}
	planet_color    = rl.DARKGREEN
	planet_radius   = 30

	player_angle     = 5.5
	player_color     = rl.LIGHTGRAY
	player_distance  = 65
	player_speed_rps = 2

	shield_color    = rl.DARKBLUE
	shield_radius   = planet_radius+12
	shield_segments = 8
}

player_input :: proc() {
	dt := rl.GetFrameTime()
	if rl.IsKeyDown(.RIGHT) { player_angle = player_angle + player_speed_rps * dt }
	if rl.IsKeyDown(.LEFT)  { player_angle = player_angle - player_speed_rps * dt }

	if (player_angle > math.TAU) { player_angle = player_angle-math.TAU }
	if (player_angle < 0)        { player_angle = player_angle+math.TAU }
	
	player_pos.x = planet_pos.x + player_distance * math.cos_f32(player_angle)
	player_pos.y = planet_pos.y + player_distance * math.sin_f32(player_angle)
}

render_planet :: proc() {
	rl.DrawCircleV(planet_pos, planet_radius, planet_color)
	rl.DrawRing(planet_pos, shield_radius, shield_radius+5, 0, 360, shield_segments, shield_color)
}

render_player :: proc() {
	rl.DrawCircleV(player_pos, 6, rl.LIGHTGRAY)
}