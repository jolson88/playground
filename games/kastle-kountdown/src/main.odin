package mazer

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:time"
import "qv"
import rl "vendor:raylib"

CARD_FONT_SIZE :: 120

Card_Id :: distinct u64

Card :: struct {
	id:    Card_Id,
	suit:  Card_Suit,
	value: Card_Value,
	loc:   Card_Location,
	
	is_discarded: bool,
	is_dragging:  bool,
	is_hovered:   bool,
	is_selected:  bool,
}

Card_Location :: enum u8 {
	Draw_Pile,
	Kountdown_Pile,
	Hand,
	Kastle,
	Discard_Pile,
}

Card_Suit  :: enum u8 {
	Blank,
	Clubs,
	Diamonds,
	Hearts,
	Spades,
}

Card_Value :: enum u8 {
	Blank,
	Ace,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
	Nine,
	Ten,
	Jack,
	Queen,
	King,
}

Game_State :: struct {
	card_font:   rl.Font,
	club_tex:    rl.Texture2D,
	diamond_tex: rl.Texture2D,
	heart_tex:   rl.Texture2D,
	spade_tex:   rl.Texture2D,

	gui:   qv.Gui_State,
	cards: [156]Card,
	selected_card: Card_Id,

	kastles:     [dynamic]Kastle,
	player_hand: [dynamic]Card_Id,
	player_kd:   [dynamic]Card_Id,
}

Kastle :: struct {
	id: qv.Gui_Id,
	top_card: Card_Id,
}

// variables
sw, sh: f32
card_labels := map[Card_Value]string{
	.Ace  = "A", .Two = "2",  .Three = "3", .Four  = "4",
	.Five = "5", .Six = "6",  .Seven = "7", .Eight = "8",
	.Nine = "9", .Ten = "10", .Jack  = "J", .Queen = "Q",
	.King = "K",
}
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
	init(1)
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
	delete(game_state.kastles)
	delete(game_state.player_hand)
	delete(game_state.player_kd)

	rl.UnloadFont(game_state.card_font)
	rl.UnloadTexture(game_state.club_tex)
	rl.UnloadTexture(game_state.diamond_tex)
	rl.UnloadTexture(game_state.heart_tex)
	rl.UnloadTexture(game_state.spade_tex)
}

do_game :: proc() {
	bg_col_pri := rl.ColorFromHSV(132, 0.53, 0.59)
	bg_col_sec := rl.ColorFromHSV(121, 0.56, 0.38)
	bg_col_trt := rl.ColorFromHSV(108, 0.77, 0.24)

	rl.ClearBackground(rl.BLACK)
	rl.DrawRectangleGradientEx(rl.Rectangle{0, 0, sw, sh}, bg_col_pri, bg_col_sec, bg_col_trt, bg_col_pri)

	render_kastles()
	render_player()

	#reverse for pcid, idx in game_state.player_hand {
		c := retrieve_card(pcid)
		if c.loc != .Hand {
			ordered_remove(&game_state.player_hand, idx)
		}	
	}
}

draw_card :: proc(loc: Card_Location) -> Card {
	card: Card
	for &c in game_state.cards {
		if c.loc == .Draw_Pile {
			c.loc = loc
			card = c
			break
		}
	}
	return card
}

init :: proc(seed: Maybe(u64) = nil) {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
	game_state = Game_State{}

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

	// generate cards
	idx := 0
	assert(len(game_state.cards) == 156, "Card stack should allow for twelve stacks for 13 cards / 3 decks of cards")
	for deck in 1..=3 {
		for s in Card_Suit {
			for v in Card_Value {
				if s != .Blank && v != .Blank {
					id := Card_Id(u8(deck) << 16 | u8(s) << 8 | u8(v))
					game_state.cards[idx] = Card{ id = id, suit = s, value = v, loc = .Draw_Pile }
					idx += 1
				}
			}
		}
	}
	assert(idx == 156, "Should have initialized 3 decks of cards")
	r := rand.create(seed.? or_else u64(time.time_to_unix(time.now())))
	context.random_generator = rand.default_random_generator(&r)
	rand.shuffle(game_state.cards[:])

	game_state.kastles = [dynamic]Kastle{
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
	}

	// deal cards
	game_state.player_kd   = make([dynamic]Card_Id, 20)
	game_state.player_hand = make([dynamic]Card_Id, 05)
	dealt := 0
	for dealt < len(game_state.player_hand) {
		c := draw_card(.Hand)
		game_state.player_hand[dealt] = c.id
		dealt += 1
	}

	fmt.println("\n--- Initialized game ---\n")
}

mark_card_as_kastled :: proc(id: Card_Id) {
	for &c in game_state.cards {
		if c.id == id {
			c.is_dragging = false
			c.is_hovered  = false
			c.is_selected = false
			c.loc = .Kastle
			return
		}
	}
}

render_card :: proc(card_id: Card_Id, pos: rl.Vector2, size: rl.Vector2) {
	card := retrieve_card(card_id)
	aspect_ratio: f32 = proto_card_size.x / proto_card_size.y
	scale_factor: f32 = size.x / proto_card_size.x
	card_height:  f32 = size.x / aspect_ratio
	card_size        := rl.Vector2{size.x, card_height}
	suit_scale:   f32 = 0.29 * scale_factor

	card_shadow := rl.ColorAlpha(rl.ColorFromHSV(102, 0.6, 0.15), 0.3)
	card_bg_col := rl.ColorFromHSV(42, 0.10, 0.88)
	card_bg_hov := rl.ColorFromHSV(38, 0.22, 0.86)
	card_bg_act := rl.ColorFromHSV(35, 0.36, 0.84)

	shadow_offset := rl.Vector2{4, 6}
	card_col      := card_bg_col
	if card.is_hovered  { card_col = card_bg_hov }
	if card.is_selected { card_col = card_bg_act; shadow_offset = rl.Vector2{8, 12} }
	rl.DrawRectangleRounded(
		rl.Rectangle{
			pos.x+shadow_offset.x,
			pos.y+shadow_offset.y,
			size.x,
			card_height
		},
		0.13, 32,
		card_shadow
	)
	rl.DrawRectangleRounded(
		rl.Rectangle{pos.x, pos.y, size.x, card_height},
		0.13, 32,
		card_col
	)

	// top left suit
	tex := game_state.club_tex
	#partial switch card.suit {
		case .Diamonds: tex = game_state.diamond_tex
		case .Hearts:   tex = game_state.heart_tex
		case .Spades:   tex = game_state.spade_tex
	}
	offset := rl.Vector2{5*scale_factor, 5*scale_factor}
	rl.DrawTextureEx(tex, pos + offset, 0, suit_scale/2, rl.WHITE)

	// center value
	font_size  := f32(CARD_FONT_SIZE) * scale_factor
	label_c    := strings.clone_to_cstring(card_labels[card.value], context.temp_allocator)
	label_size := rl.MeasureTextEx(game_state.card_font, label_c, font_size, 0)
	offset      = rl.Vector2{size.x/2-label_size.x/2, card_height/2-label_size.y/2-12*scale_factor}
	if card.suit == .Clubs || card.suit == .Spades {
		rl.DrawTextEx(game_state.card_font, label_c, pos + offset, font_size, 0, rl.BLACK)
	} else {
		rl.DrawTextEx(game_state.card_font, label_c, pos + offset, font_size, 0, rl.ColorBrightness(rl.RED, -0.2))
	}

	// bottom right suit
	offset = rl.Vector2{
		f32(tex.width)  * suit_scale,
		f32(tex.height) * suit_scale
	}
	rl.DrawTextureEx(tex, pos + card_size - offset, 0, suit_scale, rl.WHITE)
}

render_kastles :: proc() {
	k_col_bg   := rl.Color{0, 0, 0, 50}
	k_disp_sz  := proto_card_size * 1.1
	k_pad: f32  = 20
	k_disp_w   := (k_disp_sz.x + k_pad) * f32(len(game_state.kastles))
	x := (sw - k_disp_w) / 2
	for &k in game_state.kastles {
		rect := rl.Rectangle{x, sh*0.3, k_disp_sz.x, k_disp_sz.y}
		res  := qv.update_control(&game_state.gui, k.id, rect)
		if .Click in res && game_state.selected_card != 0 {
			k.top_card = game_state.selected_card
			game_state.selected_card = 0
			mark_card_as_kastled(k.top_card)
		}
		if k.top_card != 0 {
			render_card(k.top_card, rl.Vector2{rect.x, rect.y}, k_disp_sz)
		} else {
			rl.DrawRectangleRounded(rect, 0.13, 32, k_col_bg)
		}
		x += k_disp_sz.x + k_pad
	}
}

render_player :: proc() {
	c_disp_sz  := proto_card_size * 0.7
	c_pad: f32  = 10
	h_disp_w   := (c_disp_sz.x + c_pad) * f32(len(game_state.player_hand))
	x := (sw - h_disp_w) / 2
	y := sh - c_disp_sz.y - 10
	for &pcid in game_state.player_hand {
		res := qv.update_control(&game_state.gui, qv.Gui_Id(pcid), rl.Rectangle{x, y, c_disp_sz.x, c_disp_sz.y})
		if .Hover_In  in res  { start_hover(pcid) }
		if .Hover_Out in res  { stop_hover(pcid) }
		if .Click in res {
			if game_state.selected_card != 0 && game_state.selected_card != pcid {
				toggle_select(game_state.selected_card)
			}
			toggle_select(pcid)
			game_state.selected_card = pcid
		}

		render_card(pcid, rl.Vector2{x, y}, c_disp_sz)
		x += c_disp_sz.x + c_pad
	}
}

retrieve_card :: proc(card_id: Card_Id) -> Card {
	for c in game_state.cards {
		if c.id == card_id {
			return c
		}
	}

	return Card{}
}

start_hover :: proc(card_id: Card_Id) {
	for &c in game_state.cards {
		if c.id == card_id {
			c.is_hovered = true
			return
		}
	}
}

stop_hover :: proc(card_id: Card_Id) {
	for &c in game_state.cards {
		if c.id == card_id {
			c.is_hovered = false
			return
		}
	}
}

toggle_select :: proc(card_id: Card_Id) {
	for &c in game_state.cards {
		if c.id == card_id {
			c.is_selected = !c.is_selected
			return
		}
	}
}
