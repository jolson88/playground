package mazer

import "core:fmt"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "qv"
import rl "vendor:raylib"

// structs
Card_Suit  :: enum { Clubs, Diamonds, Hearts, Spades }

Card_Value :: enum {
	Ace,  Two, Three, Four,
	Five, Six, Seven, Eight,
	Nine, Ten, Jack,  Queen,
	King,
}

// variables
sw, sh: f32

bg_col_pri  := rl.ColorFromHSV(132, 0.53, 0.59)
bg_col_sec  := rl.ColorFromHSV(121, 0.56, 0.38)
bg_col_trt  := rl.ColorFromHSV(108, 0.77, 0.24)
card_labels := map[Card_Value]string{
	.Ace  = "A", .Two = "2",  .Three = "3", .Four  = "4",
	.Five = "5", .Six = "6",  .Seven = "7", .Eight = "8",
	.Nine = "9", .Ten = "10", .Jack  = "J", .Queen = "Q",
	.King = "K",
}

card_font:   rl.Font
card_font_size: i32 = 120
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
	rl.UnloadFont(card_font)
	rl.UnloadTexture(club_tex)
	rl.UnloadTexture(diamond_tex)
	rl.UnloadTexture(heart_tex)
	rl.UnloadTexture(spade_tex)
}

do_game :: proc() {
	rl.ClearBackground(rl.BLACK)
	rl.DrawRectangleGradientEx(rl.Rectangle{0, 0, sw, sh}, bg_col_pri, bg_col_sec, bg_col_trt, bg_col_pri)

	card_width: f32 = 130

	pos := rl.Vector2{sw/4, sh/4}
	draw_card(pos, card_width, .Ace, .Clubs)
	pos.x = pos.x+card_width+30
	card_width = 110
	draw_card(pos, card_width, .Seven, .Diamonds)
	pos.x = pos.x+card_width+30
	card_width = 90
	draw_card(pos, card_width, .Ten, .Hearts)
	pos.x = pos.x+card_width+30
	card_width = 70
	draw_card(pos, card_width, .Queen, .Spades)
}

draw_card :: proc(pos: rl.Vector2, card_width: f32, value: Card_Value, suit: Card_Suit) {
	proto_card_size  := rl.Vector2{130, 200}
	aspect_ratio: f32 = proto_card_size.x / proto_card_size.y
	scale_factor: f32 = card_width / proto_card_size.x
	card_height: f32  = card_width / aspect_ratio
	card_size        := rl.Vector2{card_width, card_height}
	suit_scale: f32   = 0.29 * scale_factor

	card_bg_col := rl.ColorFromHSV(55, 0.10, 0.88)
	card_shadow := rl.ColorAlpha(rl.ColorFromHSV(102, 0.6, 0.15), 0.3)

	rl.DrawRectangleRounded(rl.Rectangle{pos.x+4, pos.y+6, card_width, card_height}, 0.13, 32, card_shadow)
	rl.DrawRectangleRounded(rl.Rectangle{pos.x, pos.y, card_width, card_height}, 0.13, 32, card_bg_col)

	// top left suit
	tex    := club_tex
	#partial switch suit {
		case .Diamonds: tex = diamond_tex
		case .Hearts:   tex = heart_tex
		case .Spades:   tex = spade_tex
	}
	offset := rl.Vector2{5*scale_factor, 5*scale_factor}
	rl.DrawTextureEx(tex, pos + offset, 0, suit_scale/2, rl.WHITE)

	// center value
	font_size  := f32(card_font_size) * scale_factor
	label_c    := strings.clone_to_cstring(card_labels[value], context.temp_allocator)
	label_size := rl.MeasureTextEx(card_font, label_c, font_size, 0)
	offset      = rl.Vector2{card_width/2-label_size.x/2, card_height/2-label_size.y/2-12*scale_factor}
	if suit == .Clubs || suit ==.Spades {
		rl.DrawTextEx(card_font, label_c, pos + offset, font_size, 0, rl.BLACK)
	} else {
		rl.DrawTextEx(card_font, label_c, pos + offset, font_size, 0, rl.ColorBrightness(rl.RED, -0.2))
	}

	// bottom right suit
	offset = rl.Vector2{
		f32(tex.width)  * suit_scale,
		f32(tex.height) * suit_scale
	}
	rl.DrawTextureEx(tex, pos + card_size - offset, 0, suit_scale, rl.WHITE)
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

    font_path := filepath.join([]string{src_dir, "resources", "fonts", "Kingthings_Foundation.ttf"}, context.temp_allocator)
	card_font  = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), card_font_size, nil, 0)
}
