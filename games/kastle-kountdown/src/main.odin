package mazer

import "core:fmt"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "qv"
import rl "vendor:raylib"

// structs
Card_Suit :: enum {
	Clubs,
	Diamonds,
	Hearts,
	Spades,
}

// variables
sw, sh: f32

bg_col_pri := rl.ColorFromHSV(132, 0.53, 0.59)
bg_col_sec := rl.ColorFromHSV(121, 0.56, 0.38)
bg_col_trt := rl.ColorFromHSV(108, 0.77, 0.24)

club_tex:    rl.Texture2D
diamond_tex: rl.Texture2D
heart_tex:   rl.Texture2D
spade_tex:   rl.Texture2D


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

	qv.create_window("Kastle Kountdown", .Seven_Twenty_P)	

	init()
	defer close()
    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		qv.begin()
		defer qv.present()
		
		do_game()	
	}
}

close :: proc() {
	rl.UnloadTexture(club_tex)
}

do_game :: proc() {
	rl.ClearBackground(rl.BLACK)
	rl.DrawRectangleGradientEx(rl.Rectangle{0, 0, sw, sh}, bg_col_pri, bg_col_sec, bg_col_trt, bg_col_pri)

	card_size := rl.Vector2{130, 200}

	pos := rl.Vector2{sw/4, sh/4}
	draw_card(pos, card_size, .Clubs)
	pos.x = pos.x+card_size.x+30
	draw_card(pos, card_size, .Diamonds)
	pos.x = pos.x+card_size.x+30
	draw_card(pos, card_size, .Hearts)
	pos.x = pos.x+card_size.x+30
	draw_card(pos, card_size, .Spades)
}

draw_card :: proc(pos: rl.Vector2, card_size: rl.Vector2, suit: Card_Suit) {
	suit_scale: f32 = 0.29
	card_bg_col := rl.ColorFromHSV(55, 0.06, 0.91)
	card_shadow := rl.ColorAlpha(rl.ColorFromHSV(102, 0.6, 0.15), 0.3)

	rl.DrawRectangleRounded(rl.Rectangle{pos.x+2, pos.y+4, card_size.x, card_size.y}, 0.13, 32, card_shadow)
	rl.DrawRectangleRounded(rl.Rectangle{pos.x, pos.y, card_size.x, card_size.y}, 0.13, 32, card_bg_col)

	// top left
	switch suit {
		case .Clubs:    rl.DrawTextureEx(club_tex,    rl.Vector2{pos.x+card_size.x*0.03, pos.y+card_size.y*0.03}, 0, suit_scale/2, rl.WHITE)
		case .Diamonds: rl.DrawTextureEx(diamond_tex, rl.Vector2{pos.x+card_size.x*0.03, pos.y+card_size.y*0.03}, 0, suit_scale/2, rl.WHITE)
		case .Hearts:   rl.DrawTextureEx(heart_tex,   rl.Vector2{pos.x+card_size.x*0.03, pos.y+card_size.y*0.03}, 0, suit_scale/2, rl.WHITE)
		case .Spades:   rl.DrawTextureEx(spade_tex,   rl.Vector2{pos.x+card_size.x*0.03, pos.y+card_size.y*0.03}, 0, suit_scale/2, rl.WHITE)
	}
	// bottom right
	switch suit {
		case .Clubs:    rl.DrawTextureEx(club_tex,    rl.Vector2{pos.x+card_size.x*0.4, pos.y+card_size.y*0.65}, 0, suit_scale, rl.WHITE)
		case .Diamonds: rl.DrawTextureEx(diamond_tex, rl.Vector2{pos.x+card_size.x*0.4, pos.y+card_size.y*0.65}, 0, suit_scale, rl.WHITE)
		case .Hearts:   rl.DrawTextureEx(heart_tex,   rl.Vector2{pos.x+card_size.x*0.4, pos.y+card_size.y*0.65}, 0, suit_scale, rl.WHITE)
		case .Spades:   rl.DrawTextureEx(spade_tex,   rl.Vector2{pos.x+card_size.x*0.4, pos.y+card_size.y*0.65}, 0, suit_scale, rl.WHITE)
	}
}

init :: proc() {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	src_dir   := filepath.dir(#file, context.temp_allocator)
    suit_path := filepath.join([]string{src_dir, "resources", "club.png"}, context.temp_allocator)
	suit_img  := rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	club_tex   = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path   = filepath.join([]string{src_dir, "resources", "diamond.png"}, context.temp_allocator)
	suit_img    = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	diamond_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "heart.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	heart_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "spade.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	spade_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)
}
