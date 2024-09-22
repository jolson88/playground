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
	cell_color:  [dynamic]rl.Color,
	cell_target: [dynamic]Charset_Index,
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
	delete(sf.cell_color)
	delete(sf.cell_target)
}

sf_init :: proc(sf: ^Split_Flap, font: rl.Font, font_size: f32, allocator := context.allocator) {
	text_size := rl.MeasureTextEx(font, "Y", font_size, 0)

	sf.font         = font
	sf.font_size    = font_size
	sf.text_width   = text_size.x
	sf.text_height  = text_size.y
	sf.charset      = Split_Flap_Charset
	sf.cells        = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cell_color  = make([dynamic]rl.Color, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cell_target = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)

	for idx in 0..<len(sf.cell_color) {
		sf.cell_color[idx] = rl.WHITE
	}
}

sf_tick :: proc(sf: ^Split_Flap, dt: f32) {
	using sf

	ttc -= dt
	if ttc < 0 {
		for c, idx in sf.cells {
			if c != sf.cell_target[idx] {
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
			sf.cell_color[idx]
		)
	}
}

sf_set_color :: proc(sf: ^Split_Flap, row: u32, col: u32, color: rl.Color) {
	if col >= sf.cols || row >= sf.rows {
		return
	}
	sf.cell_color[(row*sf.cols)+col] = color
}


sf_set_text :: proc(sf: ^Split_Flap, row: u32, text: string) {
	if row >= sf.rows {
		return
	}
	for idx in 0..<min(u32(len(text)), sf.cols) {
		char_idx := strings.index(sf.charset, text[idx:idx+1])
		sf.cell_target[(row*sf.cols)+idx] = Charset_Index(char_idx if char_idx >= 0 else 0)
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
		refresh_rate = 1.0 / 20.0,
	}
	sf_init(&sf, mono_font, 24)

	curr_flight: int = 0
	flights := []string{
		"6104 08:14 DALLAS           C17 BOARDING",
		" 837 08:32 CHARLOTTE        D11 BOARDING",
		"9776 08:44 HOUSTON          C14 DELAYED ",
		"5914 08:50 CHARLOTTE        C02 DELAYED ",
		"8122 08:50 LOS ANGELES      F11 ON-TIME ",
		"6402 08:55 MINNEAPOLIS      C15 DELAYED ",
		"4048 09:00 SEATTLE          E01 BOARDING",
		"4279 09:12 DETROIT          E10 ON-TIME ",
		"3284 09:15 LAS VEGAS        C02 ON-TIME ",
		"2768 09:31 NEW YORK         D06 DELAYED ",
		"1901 10:55 HOUSTON          A07 ON-TIME ",
		"6638 11:13 DETROIT          E05 ON-TIME ",
		"6318 12:55 MINNEAPOLIS      D12 ON-TIME ",
		"1138 12:57 SALT LAKE CITY   B11 DELAYED ",
		"4933 13:13 CHARLOTTE        D06 DELAYED ",
		"2883 13:36 BOSTON           D15 DELAYED ",
		"4115 14:50 PHILADELPHIA     C04 DELAYED ",
		" 520 15:17 PHILADELPHIA     E13 ON-TIME ",
		"8152 16:12 ATLANTA          F17 ON-TIME ",
		"7737 16:58 MINNEAPOLIS      E06 DELAYED ",
		"2086 17:06 HOUSTON          D09 ON-TIME ",
		" 725 17:58 HOUSTON          F15 DELAYED ",
		"9825 18:42 CHICAGO          B05 ON-TIME ",
		"8962 18:56 MINNEAPOLIS      D01 DELAYED ",
		"4077 19:12 NEW YORK         F02 ON-TIME ",
		"1996 20:03 SALT LAKE CITY   B06 DELAYED ",
		"4079 20:12 PHILADELPHIA     D13 DELAYED ",
		"4940 20:34 BOSTON           A11 ON-TIME ",
		"1492 20:47 PHILADELPHIA     E08 ON-TIME ",
		"6791 20:50 SAN DIEGO        E13 DELAYED ",
		"5330 20:56 DETROIT          C14 ON-TIME ",
		"3912 20:59 NEW YORK         D07 ON_TIME ",
		"5274 21:49 PHILADELPHIA     C11 DELAYED ",
		"9443 22:22 DENVER           D08 ON-TIME ",
		"7786 22:37 DENVER           F18 DELAYED ",
		"3128 23:09 SAN DIEGO        B17 ON-TIME ",
	}
	for curr_flight < int(sf.rows) {
		sf_set_text(&sf, u32(curr_flight), flights[curr_flight])
		curr_flight += 1
	}
	defer sf_destroy(&sf)

	// time to yellow
	for r in 0..<sf.rows {
		for c in 5..=9 {
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
		}
	}
	// gate to yellow
	for r in 0..<sf.rows {
		for c in 28..=30 {
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
		}
	}

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		dt := rl.GetFrameTime()

		if rl.IsKeyPressed(.T) {
			for r in 0..<sf.rows {
				sf_set_text(&sf, r, flights[curr_flight])
				curr_flight = curr_flight+1 if curr_flight<len(flights)-1 else 0
			}
		}

		sf_tick(&sf, dt)

		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		sf_render(&sf)

		rl.EndDrawing()
	}
}