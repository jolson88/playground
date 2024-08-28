package mazer

import "core:fmt"
import "core:mem"
import "qv"
import rl "vendor:raylib"

planet_center: rl.Vector2
planet_color: rl.Color
planet_radius: f32

player_distance: f32 		// The distance from the center of the planet in pixels

shield_radius: f32
shield_segments: i32
shield_color: rl.Color

sw, sh: f32					// The screen width and screen height

do_battle :: proc() {
	rl.ClearBackground(rl.BLACK)

	rl.DrawCircleV(planet_center, planet_radius, planet_color)
	rl.DrawRing(planet_center, shield_radius, shield_radius+5, 0, 360, shield_segments, shield_color)
}

init :: proc() {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	planet_center = rl.Vector2{sw/2, sh*0.75}
	planet_color  = rl.DARKGREEN
	planet_radius = 30

	shield_color  = rl.DARKBLUE
	shield_radius = planet_radius+12
	shield_segments = 8
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

	qv.create_window("Mazer", .Seven_Twenty_P)	

	init()
    for !rl.WindowShouldClose() {
		qv.begin()
		defer qv.present()
		
		do_battle()	
	}
}