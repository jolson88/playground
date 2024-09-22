package ort

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Split_Flap_Charset :: " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890:"

Charset_Index :: distinct u8

Split_Flap :: struct {
	pos:  rl.Vector2,

	cols: u32,
	rows: u32,
	cells: [dynamic]Charset_Index,
	cells_target: [dynamic]Charset_Index,
	colors: [dynamic]rl.Color,
	margin:  f32,
	padding: f32,

	font: rl.Font,
	font_size:   f32,
	text_width:  f32,
	text_height: f32,
	charset: string,

	refresh_rate: f32, 	// Number of seconds to elapse between cycles / character advancements
	ttc: f32,			// Number of seconds remaining until the next cycling of characters
}

sf_destroy :: proc(sf: ^Split_Flap) {
	delete(sf.cells)
	delete(sf.cells_target)
	delete(sf.colors)
}

sf_init :: proc(sf: ^Split_Flap, font: rl.Font, font_size: f32, allocator := context.allocator) {
	text_size := rl.MeasureTextEx(font, "Y", font_size, 0)

	sf.font         = font
	sf.font_size    = font_size
	sf.text_width   = text_size.x
	sf.text_height  = text_size.y
	sf.charset      = Split_Flap_Charset
	sf.cells        = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cells_target = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.colors       = make([dynamic]rl.Color, sf.cols*sf.rows, sf.cols*sf.rows, allocator)

	for idx in 0..<len(sf.colors) {
		sf.colors[idx] = rl.WHITE
	}
}

sf_rand :: proc(sf: ^Split_Flap) {
	for i := 0; i < len(sf.cells_target); i += 1 {
		sf.cells_target[i] = Charset_Index(rand.int_max(len(Split_Flap_Charset)))
	}
}

sf_tick :: proc(sf: ^Split_Flap, dt: f32) {
	using sf

	ttc -= dt
	if ttc < 0 {
		for c, idx in sf.cells {
			if c != sf.cells_target[idx] {
				new_c := 0 if c==Charset_Index(len(sf.charset)-1) else c+1
				sf.cells[idx] = new_c
			}
		}
		ttc = refresh_rate
	}
}

sf_render :: proc(sf: ^Split_Flap) {
	dim := rl.Vector2{
		sf.margin*2 + f32(sf.cols)*sf.text_width  + sf.padding*f32(sf.cols-1),
		sf.margin*2 + f32(sf.rows)*sf.text_height + sf.padding*f32(sf.rows-1),
	}

	rl.DrawRectangleV(sf.pos, dim, rl.DARKGRAY)
	for c, idx in sf.cells {
		row := u32(idx) / sf.cols
		col := u32(idx) % sf.cols
		pos := rl.Vector2{
			sf.pos.x + sf.margin + (f32(col)*sf.text_width  + f32(col)*sf.padding),
			sf.pos.y + sf.margin + (f32(row)*sf.text_height + f32(row)*sf.padding),
		}
		rl.DrawRectangleV(pos, rl.Vector2{sf.text_width, sf.text_height}, rl.BLACK)
		char_idx := sf.cells[idx]
		rl.DrawTextEx(
			sf.font,
			strings.clone_to_cstring(sf.charset[char_idx:char_idx+1], context.temp_allocator),
			pos,
			sf.font_size,
			0,
			sf.colors[idx]
		)
	}
}

sf_set_color :: proc(sf: ^Split_Flap, row: u32, col: u32, color: rl.Color) {
	if col >= sf.cols || row >= sf.rows {
		return
	}
	sf.colors[(row*sf.cols)+col] = color
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
		refresh_rate = 1.0 / 20.0,
	}
	sf_init(&sf, mono_font, 24)
	defer sf_destroy(&sf)

	// time to yellow
	for r in 0..<sf.rows {
		for c in 5..=9 {
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
		}
	}
	// gate to yellow
	for r in 0..<sf.rows {
		for c in 25..=27 {
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
		}
	}

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		dt := rl.GetFrameTime()

		if rl.IsKeyDown(.SPACE) {
			sf_rand(&sf)
		}

		sf_tick(&sf, dt)

		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		sf_render(&sf)

		rl.EndDrawing()
	}
}