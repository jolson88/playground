package ort

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Charset_Index :: distinct u8

Split_Flap_Charset :: enum {
	Default = 0,
	Alpha,
	Numeric,
}

Split_Flap :: struct {
	loc: rl.Rectangle,
	cols: u32,
	rows: u32,
	pad: f32,
	cells:        [dynamic]Charset_Index,
	cell_charset: [dynamic]Split_Flap_Charset,
	cell_color:   [dynamic]rl.Color,
	cell_target:  [dynamic]Charset_Index,

	font: rl.Font,
	font_size: f32,
	charsets: map[Split_Flap_Charset]string,

	refresh_rate: f32, 	// Number of seconds to elapse between cycles / character advancements
	ttc: f32,			// Number of seconds remaining until the next cycling of characters
}

sf_destroy :: proc(sf: ^Split_Flap) {
	delete(sf.cells)
	delete(sf.cell_charset)
	delete(sf.cell_color)
	delete(sf.cell_target)
	delete(sf.charsets)
}

sf_init :: proc(sf: ^Split_Flap, loc: rl.Rectangle, cols: u32, refresh_rate: f32, pad: f32, font: rl.Font, allocator := context.allocator) {
	sf.loc = loc
	sf.cols = cols
	sf.refresh_rate = refresh_rate
	sf.pad = pad
	sf.font = font

	space_width := sf.pad*2 + sf.pad*f32(sf.cols-1)
	width_rem   := loc.width - space_width
	text_width  := math.floor_f32(width_rem / f32(sf.cols))
	sf.font_size = text_width*2

	est_rows: u32 = 1
	height := sf.pad*2 + sf.font_size
	for height < loc.height {
		est_rows += 1
		height += sf.font_size + sf.pad
	}
	sf.rows = est_rows-1

	sf.cells        = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cell_charset = make([dynamic]Split_Flap_Charset, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cell_color   = make([dynamic]rl.Color, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.cell_target  = make([dynamic]Charset_Index, sf.cols*sf.rows, sf.cols*sf.rows, allocator)
	sf.charsets     = map[Split_Flap_Charset]string{
		Split_Flap_Charset.Default = " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890:",
		Split_Flap_Charset.Alpha   = " ABCDEFGHIJKLMNOPQRSTUVWXYZ",
		Split_Flap_Charset.Numeric = " 1234567890:,.",
	}

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
				new_c := 0 if c==Charset_Index(len(sf.charsets[sf.cell_charset[idx]])-1) else c+1
				sf.cells[idx] = new_c
			}
		}
		ttc = refresh_rate
	}
}

sf_render :: proc(sf: ^Split_Flap, pos: rl.Vector2) {
	rl.DrawRectangleRec(sf.loc, rl.BLACK)
	for c, idx in sf.cells {
		row := u32(idx) / sf.cols
		col := u32(idx) % sf.cols
		render_pos := rl.Vector2{
			pos.x + sf.pad + (f32(col)*(sf.font_size/2) + f32(col)*sf.pad),
			pos.y + sf.pad + (f32(row)*sf.font_size + f32(row)*sf.pad),
		}
		char_idx := sf.cells[idx]
		char := sf.charsets[sf.cell_charset[idx]][char_idx:char_idx+1]
		rl.DrawTextEx(
			sf.font,
			strings.clone_to_cstring(char, context.temp_allocator),
			render_pos,
			sf.font_size,
			0,
			sf.cell_color[idx]
		)
	}
}

sf_set_charset :: proc(sf: ^Split_Flap, row: u32, col: u32, charset: Split_Flap_Charset) {
	if col >= sf.cols || row >= sf.rows {
		return
	}
	sf.cell_charset[(row*sf.cols)+col] = charset
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
		cell_idx := (row*sf.cols)+idx
		char_idx := strings.index(sf.charsets[sf.cell_charset[cell_idx]], text[idx:idx+1])
		sf.cell_target[cell_idx] = Charset_Index(char_idx if char_idx >= 0 else 0)
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
	mono_font := rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), 48, nil, 0)
	defer rl.UnloadFont(mono_font)

	sf: Split_Flap
	sf_init(&sf,
		rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
		41,
		1.0 / 20.0,
		5,
		mono_font
	)

	curr_flight: int = 0
	flights := []string{
		"6104 08:14 DALLAS            C17 BOARDING",
		" 837 08:32 CHARLOTTE         D11 BOARDING",
		"9776 08:44 HOUSTON           C14 DELAYED ",
		"5914 08:50 CHARLOTTE         C02 DELAYED ",
		"8122 08:50 LOS ANGELES       F11 ON-TIME ",
		"6402 08:55 MINNEAPOLIS       C15 DELAYED ",
		"4048 09:00 SEATTLE           E01 BOARDING",
		"4279 09:12 DETROIT           E10 ON-TIME ",
		"3284 09:15 LAS VEGAS         C02 ON-TIME ",
		"2768 09:31 NEW YORK          D06 DELAYED ",
		"1901 10:55 HOUSTON           A07 ON-TIME ",
		"6638 11:13 DETROIT           E05 ON-TIME ",
		"6318 12:55 MINNEAPOLIS       D12 ON-TIME ",
		"1138 12:57 SALT LAKE CITY    B11 DELAYED ",
		"4933 13:13 CHARLOTTE         D06 DELAYED ",
		"2883 13:36 BOSTON            D15 DELAYED ",
		"4115 14:50 PHILADELPHIA      C04 DELAYED ",
		" 520 15:17 PHILADELPHIA      E13 ON-TIME ",
		"8152 16:12 ATLANTA           F17 ON-TIME ",
		"7737 16:58 MINNEAPOLIS       E06 DELAYED ",
		"2086 17:06 HOUSTON           D09 ON-TIME ",
		" 725 17:58 HOUSTON           F15 DELAYED ",
		"9825 18:42 CHICAGO           B05 ON-TIME ",
		"8962 18:56 MINNEAPOLIS       D01 DELAYED ",
		"4077 19:12 NEW YORK          F02 ON-TIME ",
		"1996 20:03 SALT LAKE CITY    B06 DELAYED ",
		"4079 20:12 PHILADELPHIA      D13 DELAYED ",
		"4940 20:34 BOSTON            A11 ON-TIME ",
		"1492 20:47 PHILADELPHIA      E08 ON-TIME ",
		"6791 20:50 SAN DIEGO         E13 DELAYED ",
		"5330 20:56 DETROIT           C14 ON-TIME ",
		"3912 20:59 NEW YORK          D07 ON_TIME ",
		"5274 21:49 PHILADELPHIA      C11 DELAYED ",
		"9443 22:22 DENVER            D08 ON-TIME ",
		"7786 22:37 DENVER            F18 DELAYED ",
		"3128 23:09 SAN DIEGO         B17 ON-TIME ",
	}
	defer sf_destroy(&sf)

	for r in 0..<sf.rows {
		// flight number
		for c in 0..=3 {
			sf_set_charset(&sf, r, u32(c), .Numeric)
		}
		// time
		for c in 5..=9 {
			sf_set_charset(&sf, r, u32(c), .Numeric)
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
		}
		// destination
		for c in 11..=26 {
			sf_set_charset(&sf, r, u32(c), .Alpha)
		}
		// gate
		for c in 29..=31 {
			sf_set_color(&sf, r, u32(c), rl.YELLOW)
			sf_set_charset(&sf, r, u32(c), .Alpha if c==29 else .Numeric)
		}
		// status
		for c in 32..=39 {
			sf_set_charset(&sf, r, u32(c), .Alpha)
		}
	}
	for curr_flight < int(sf.rows) {
		sf_set_text(&sf, u32(curr_flight), flights[curr_flight])
		curr_flight += 1
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

		sf_render(&sf, rl.Vector2{0, 0})

		rl.EndDrawing()
	}
}