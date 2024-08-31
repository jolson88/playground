package mazer

import "core:fmt"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "qv"
import rl "vendor:raylib"

CARD_FONT_SIZE :: 120

Card :: struct {
	suit: Card_Suit,
	value: Card_Value,
	pos: rl.Vector2,
}

Card_Suit  :: enum { Clubs, Diamonds, Hearts, Spades }

Card_Value :: enum {
	Ace,  Two, Three, Four,
	Five, Six, Seven, Eight,
	Nine, Ten, Jack,  Queen,
	King,
}

Game_State :: struct {
	card_font:   rl.Font,
	club_tex:    rl.Texture2D,
	diamond_tex: rl.Texture2D,
	heart_tex:   rl.Texture2D,
	spade_tex:   rl.Texture2D,

	gui: qv.Gui_State,
	card_1: Card,
	card_2: Card,
	card_3: Card,
	card_4: Card,
}

// variables
sw, sh: f32
card_labels := map[Card_Value]string{
	.Ace  = "A", .Two = "2",  .Three = "3", .Four  = "4",
	.Five = "5", .Six = "6",  .Seven = "7", .Eight = "8",
	.Nine = "9", .Ten = "10", .Jack  = "J", .Queen = "Q",
	.King = "K",
}
card_width: f32 = 130
game_state: Game_State
proto_card_size := rl.Vector2{130, 200}

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

		qv.gui_start(&game_state.gui)
		defer qv.gui_end(&game_state.gui)
		
		do_game()	
	}
}

close :: proc() {
	rl.UnloadFont(game_state.card_font)
	rl.UnloadTexture(game_state.club_tex)
	rl.UnloadTexture(game_state.diamond_tex)
	rl.UnloadTexture(game_state.heart_tex)
	rl.UnloadTexture(game_state.spade_tex)
}

do_game :: proc() {
	bg_col_pri  := rl.ColorFromHSV(132, 0.53, 0.59)
	bg_col_sec  := rl.ColorFromHSV(121, 0.56, 0.38)
	bg_col_trt  := rl.ColorFromHSV(108, 0.77, 0.24)

	rl.ClearBackground(rl.BLACK)
	rl.DrawRectangleGradientEx(rl.Rectangle{0, 0, sw, sh}, bg_col_pri, bg_col_sec, bg_col_trt, bg_col_pri)

	draw_card(&game_state.card_1, card_width)
	draw_card(&game_state.card_2, card_width)
	draw_card(&game_state.card_3, card_width)
	draw_card(&game_state.card_4, card_width)
}

draw_card :: proc(card: ^Card, card_width: f32) {
	aspect_ratio: f32 = proto_card_size.x / proto_card_size.y
	scale_factor: f32 = card_width / proto_card_size.x
	card_height: f32  = card_width / aspect_ratio
	card_size        := rl.Vector2{card_width, card_height}
	suit_scale: f32   = 0.29 * scale_factor

	card_shadow := rl.ColorAlpha(rl.ColorFromHSV(102, 0.6, 0.15), 0.3)
	card_bg_col := rl.ColorFromHSV(42, 0.10, 0.88)
	card_bg_hov := rl.ColorFromHSV(38, 0.24, 0.86)
	card_bg_act := rl.ColorFromHSV(35, 0.33, 0.84)

	card_col := card_bg_col
	res := qv.update_control(&game_state.gui, qv.Gui_Id(uintptr(card)), rl.Rectangle{card.pos.x, card.pos.y, card_size.x, card_size.y})
	if .Hover in res {
		card_col = card_bg_hov
	}
	if .Active in res {
		card_col = card_bg_act
	}

	rl.DrawRectangleRounded(rl.Rectangle{card.pos.x+4, card.pos.y+6, card_width, card_height}, 0.13, 32, card_shadow)
	rl.DrawRectangleRounded(rl.Rectangle{card.pos.x,   card.pos.y,   card_width, card_height}, 0.13, 32, card_col)

	// top left suit
	tex := game_state.club_tex
	#partial switch card.suit {
		case .Diamonds: tex = game_state.diamond_tex
		case .Hearts:   tex = game_state.heart_tex
		case .Spades:   tex = game_state.spade_tex
	}
	offset := rl.Vector2{5*scale_factor, 5*scale_factor}
	rl.DrawTextureEx(tex, card.pos + offset, 0, suit_scale/2, rl.WHITE)

	// center value
	font_size  := f32(CARD_FONT_SIZE) * scale_factor
	label_c    := strings.clone_to_cstring(card_labels[card.value], context.temp_allocator)
	label_size := rl.MeasureTextEx(game_state.card_font, label_c, font_size, 0)
	offset      = rl.Vector2{card_width/2-label_size.x/2, card_height/2-label_size.y/2-12*scale_factor}
	if card.suit == .Clubs || card.suit == .Spades {
		rl.DrawTextEx(game_state.card_font, label_c, card.pos + offset, font_size, 0, rl.BLACK)
	} else {
		rl.DrawTextEx(game_state.card_font, label_c, card.pos + offset, font_size, 0, rl.ColorBrightness(rl.RED, -0.2))
	}

	// bottom right suit
	offset = rl.Vector2{
		f32(tex.width)  * suit_scale,
		f32(tex.height) * suit_scale
	}
	rl.DrawTextureEx(tex, card.pos + card_size - offset, 0, suit_scale, rl.WHITE)
}

init :: proc() {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	src_dir   := filepath.dir(#file, context.temp_allocator)
    suit_path := filepath.join([]string{src_dir, "resources", "club.png"}, context.temp_allocator)
	suit_img  := rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	game_state.club_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path   = filepath.join([]string{src_dir, "resources", "diamond.png"}, context.temp_allocator)
	suit_img    = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	game_state.diamond_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "heart.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	game_state.heart_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "spade.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	game_state.spade_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    font_path := filepath.join([]string{src_dir, "resources", "fonts", "Kingthings_Foundation.ttf"}, context.temp_allocator)
	game_state.card_font = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), CARD_FONT_SIZE, nil, 0)

	game_state.card_1 = Card{
		suit  = .Clubs,
		value = .Ace,
		pos   = rl.Vector2{sw/4, sh/4},
	}
	game_state.card_2 = Card{
		suit  = .Diamonds,
		value = .Seven,
		pos   = rl.Vector2{game_state.card_1.pos.x+card_width+30, game_state.card_1.pos.y},
	}
	game_state.card_3 = Card{
		suit  = .Hearts,
		value = .Ten,
		pos   = rl.Vector2{game_state.card_2.pos.x+card_width+30, game_state.card_2.pos.y},
	}
	game_state.card_4 = Card{
		suit  = .Spades,
		value = .Queen,
		pos   = rl.Vector2{game_state.card_3.pos.x+card_width+30, game_state.card_3.pos.y},
	}
}
