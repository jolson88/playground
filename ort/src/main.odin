package ort

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Split_Flap_Charset :: " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

Split_Flap :: struct {
	pos:  rl.Vector2,

	cols: u32,
	rows: u32,
	cells: [dynamic]u8,
	cells_target: [dynamic]u8,
	margin:  f32,
	padding: f32,

	font: rl.Font,
	font_size:   f32,
	text_width:  f32,
	text_height: f32,

	refresh_rate: f32, 	// Number of seconds to elapse between cycles / character advancements
	ttc: f32,			// Number of seconds remaining until the next cycling of characters
}

split_flap_destroy :: proc(sf: ^Split_Flap) {
	delete(sf.cells)
	delete(sf.cells_target)
}

split_flap_init :: proc(sf: ^Split_Flap, font: rl.Font, font_size: f32) {
	text_size := rl.MeasureTextEx(font, "Y", font_size, 0)

	sf.font         = font
	sf.font_size    = font_size
	sf.text_width   = text_size.x
	sf.text_height  = text_size.y
	sf.cells        = make([dynamic]u8, sf.cols*sf.rows, sf.cols*sf.rows)
	sf.cells_target = make([dynamic]u8, sf.cols*sf.rows, sf.cols*sf.rows)
}

split_flap_tick :: proc(sf: ^Split_Flap, dt: f32) {
	using sf

	ttc -= dt
	if ttc < 0 {
		ttc = refresh_rate
	}
}

split_flap_render :: proc(sf: ^Split_Flap) {
	dim := rl.Vector2{
		sf.margin*2 + f32(sf.cols)*sf.text_width  + sf.padding*f32(sf.cols-1),
		sf.margin*2 + f32(sf.rows)*sf.text_height + sf.padding*f32(sf.rows-1),
	}

	rl.DrawRectangleV(sf.pos, dim, rl.DARKGRAY)

	pos := sf.pos + rl.Vector2{sf.margin, sf.margin}

	for c, idx in sf.cells {
		row := u32(idx) / sf.cols
		col := u32(idx) % sf.cols
		pos := rl.Vector2{
			sf.pos.x + sf.margin + (f32(col)*sf.text_width  + f32(col)*sf.padding),
			sf.pos.y + sf.margin + (f32(row)*sf.text_height + f32(row)*sf.padding),
		}
		rl.DrawRectangleV(pos, rl.Vector2{sf.text_width, sf.text_height}, rl.BLACK)
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

	rl.InitWindow(1280, 720, "Ort - Examples")
	rl.SetTargetFPS(60)

	src_dir   := filepath.dir(#file, context.temp_allocator)
    font_path := filepath.join([]string{src_dir, "resources", "fonts", "DroidSansMono.ttf"}, context.temp_allocator)
	mono_font := rl.LoadFont(strings.clone_to_cstring(font_path, context.temp_allocator))
	defer rl.UnloadFont(mono_font)

	sf := Split_Flap{
		pos  = rl.Vector2{20, 20},
		cols = 40,
		rows = 12,
		margin = 10,
		padding = 5,
		refresh_rate = 1 / 60,
	}
	split_flap_init(&sf, mono_font, 24)
	defer split_flap_destroy(&sf)

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		dt := rl.GetFrameTime()

		split_flap_tick(&sf, dt)

		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		split_flap_render(&sf)

		rl.EndDrawing()
	}
}