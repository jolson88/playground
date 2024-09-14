package kastlegame

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
	gs := init(1)
	defer close(&gs)

    for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		qv.begin()
		defer qv.present()

		qv.gui_start(&gs.gui)
		defer qv.gui_end(&gs.gui)
		
		do_game(&gs)	
	}
}

assign_to_discard :: proc(gs: ^Game_State, id: Card_Id) {
	for &c in gs.cards {
		if c.id == id {
			c.loc = .Discard_Pile
			return
		}
	}
}

close :: proc(gs: ^Game_State) {
	delete(gs.kastles)
	delete(gs.player_hand)
	delete(gs.player_kd)

	rl.UnloadFont(gs.card_font)
	rl.UnloadTexture(gs.club_tex)
	rl.UnloadTexture(gs.diamond_tex)
	rl.UnloadTexture(gs.heart_tex)
	rl.UnloadTexture(gs.spade_tex)
}

do_game :: proc(gs: ^Game_State) {
	if rl.IsKeyPressed(.R) && ODIN_DEBUG {
		// force redraw of player's hand
		for cid in gs.player_hand {
			assign_to_discard(gs, cid)
		}
		redraw_empty_hands(gs)
	}

	bg_col_pri := rl.ColorFromHSV(132, 0.53, 0.59)
	bg_col_sec := rl.ColorFromHSV(121, 0.56, 0.38)
	bg_col_trt := rl.ColorFromHSV(108, 0.77, 0.24)
	rl.ClearBackground(rl.BLACK)
	rl.DrawRectangleGradientEx(rl.Rectangle{0, 0, sw, sh}, bg_col_pri, bg_col_sec, bg_col_trt, bg_col_pri)

	render_kastles(gs)
	render_player(gs)
	
	redraw_empty_hands(gs)
}

draw_card :: proc(gs: ^Game_State, loc: Card_Location) -> Card_Id {
	for &c in gs.cards {
		if c.loc == .Draw_Pile {
			c.loc = loc
			return c.id
		}
	}

	return 0
}

get_suit :: proc(id: Card_Id) -> Card_Suit {
	return Card_Suit(u8(u64(id) >> 8 & 0xFF))
}

get_value :: proc(id: Card_Id) -> u8 {
	return u8(u64(id) & 0xFF)
}

init :: proc(seed: Maybe(u64) = nil) -> Game_State {
	sw, sh = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
	gs := Game_State{}

	src_dir   := filepath.dir(#file, context.temp_allocator)
    suit_path := filepath.join([]string{src_dir, "resources", "club.png"}, context.temp_allocator)
	suit_img  := rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	gs.club_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path   = filepath.join([]string{src_dir, "resources", "diamond.png"}, context.temp_allocator)
	suit_img    = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	gs.diamond_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "heart.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	gs.heart_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    suit_path = filepath.join([]string{src_dir, "resources", "spade.png"}, context.temp_allocator)
	suit_img  = rl.LoadImage(strings.clone_to_cstring(suit_path, context.temp_allocator))
	gs.spade_tex = rl.LoadTextureFromImage(suit_img)
	rl.UnloadImage(suit_img)

    font_path := filepath.join([]string{src_dir, "resources", "fonts", "Kingthings_Foundation.ttf"}, context.temp_allocator)
	gs.card_font = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), CARD_FONT_SIZE, nil, 0)

	// generate cards
	idx := 0
	assert(len(gs.cards) == 156, "Card stack should allow for twelve stacks for 13 cards / 3 decks of cards")
	for d in 1..=3 {
		for s in Card_Suit {
			for v in Card_Value {
				if s != .Blank && v != .Blank {
					id := u64(d) << 16 | u64(s) << 8 | u64(v)
					gs.cards[idx] = Card{ id = Card_Id(id), suit = s, value = v, loc = .Draw_Pile }
					idx += 1
				}
			}
		}
	}
	assert(idx == 156, "Should have initialized 3 decks of cards")
	r := rand.create(seed.? or_else u64(time.time_to_unix(time.now())))
	context.random_generator = rand.default_random_generator(&r)
	rand.shuffle(gs.cards[:])

	gs.kastles = [dynamic]Kastle{
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
		Kastle{ id=qv.Gui_Id(rand.uint64()) },
	}

	// deal cards
	gs.player_kd   = make([dynamic]Card_Id, 20)
	gs.player_hand = make([dynamic]Card_Id, 05)
	dealt := 0
	for dealt < len(gs.player_hand) {
		gs.player_hand[dealt] = draw_card(&gs, .Hand)
		dealt += 1
	}

	return gs
}

kastle_selected_card :: proc(gs: ^Game_State, kastle: ^Kastle) {
	kastle.top_card = gs.selected_card
	for &c in gs.cards {
		if c.id == kastle.top_card {
			c.is_dragging = false
			c.is_hovered  = false
			c.is_selected = false
			c.loc = .Kastle
			break
		}
	}
	gs.selected_card = 0
}

lookup_card :: proc(gs: ^Game_State, card_id: Card_Id) -> Card {
	for c in gs.cards {
		if c.id == card_id {
			return c
		}
	}

	return Card{}
}

redraw_empty_hands :: proc(gs: ^Game_State) {
	for cid in gs.player_hand {
		c := lookup_card(gs, cid)
		if c.loc == .Hand { 
			return
		}
	}
	redraw_until_full(gs)
}

redraw_until_full :: proc(gs: ^Game_State) {
	for i in 0..<len(gs.player_hand) {
		c := lookup_card(gs, gs.player_hand[i])
		if c.loc != .Hand {
			gs.player_hand[i] = draw_card(gs, .Hand)
		}
	}
}

render_card :: proc(gs: ^Game_State, card_id: Card_Id, pos: rl.Vector2, size: rl.Vector2) {
	card := lookup_card(gs, card_id)
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
	tex := gs.club_tex
	#partial switch card.suit {
		case .Diamonds: tex = gs.diamond_tex
		case .Hearts:   tex = gs.heart_tex
		case .Spades:   tex = gs.spade_tex
	}
	offset := rl.Vector2{5*scale_factor, 5*scale_factor}
	rl.DrawTextureEx(tex, pos + offset, 0, suit_scale/2, rl.WHITE)

	// center value
	font_size  := f32(CARD_FONT_SIZE) * scale_factor
	label_c    := strings.clone_to_cstring(card_labels[card.value], context.temp_allocator)
	label_size := rl.MeasureTextEx(gs.card_font, label_c, font_size, 0)
	offset      = rl.Vector2{size.x/2-label_size.x/2, card_height/2-label_size.y/2-12*scale_factor}
	if card.suit == .Clubs || card.suit == .Spades {
		rl.DrawTextEx(gs.card_font, label_c, pos + offset, font_size, 0, rl.BLACK)
	} else {
		rl.DrawTextEx(gs.card_font, label_c, pos + offset, font_size, 0, rl.ColorBrightness(rl.RED, -0.2))
	}

	// bottom right suit
	offset = rl.Vector2{
		f32(tex.width)  * suit_scale,
		f32(tex.height) * suit_scale
	}
	rl.DrawTextureEx(tex, pos + card_size - offset, 0, suit_scale, rl.WHITE)
}

render_kastles :: proc(gs: ^Game_State) {
	k_col_bg   := rl.Color{0, 0, 0, 50}
	k_disp_sz  := proto_card_size * 1.1
	k_pad: f32  = 20
	k_disp_w   := (k_disp_sz.x + k_pad) * f32(len(gs.kastles))
	x := (sw - k_disp_w) / 2
	for &k in gs.kastles {
		can_play := k.top_card == 0 && gs.selected_card != 0

		rect := rl.Rectangle{x, sh*0.3, k_disp_sz.x, k_disp_sz.y}
		res  := qv.update_control(&gs.gui, k.id, rect)
		if .Click in res && gs.selected_card != 0 {
			kastle_selected_card(gs, &k)
		}
		if can_play {
			rl.DrawRectangleRoundedLines(rl.Rectangle{rect.x-4, rect.y-4, rect.width+8, rect.height+8}, 0.13, 32, 2, rl.WHITE)
		}
		rl.DrawRectangleRounded(rect, 0.13, 32, k_col_bg)
		if k.top_card != 0 {
			render_card(gs, k.top_card, rl.Vector2{rect.x+10, rect.y+10}, rl.Vector2{k_disp_sz.x-20, k_disp_sz.y-20})
		}
		x += k_disp_sz.x + k_pad
	}
}

render_player :: proc(gs: ^Game_State) {
	c_disp_sz  := proto_card_size * 0.7
	c_pad: f32  = 10

	cards_in_hand := 0
	for pcid in gs.player_hand {
		c := lookup_card(gs, pcid)
		cards_in_hand += 1 if c.loc == .Hand else 0
	}
	h_disp_w   := (c_disp_sz.x + c_pad) * f32(cards_in_hand)
	x := (sw - h_disp_w) / 2
	y := sh - c_disp_sz.y - 10
	for &pcid in gs.player_hand {
		c := lookup_card(gs, pcid)
		if c.loc != .Hand {
			continue
		}

		res := qv.update_control(&gs.gui, qv.Gui_Id(pcid), rl.Rectangle{x, y, c_disp_sz.x, c_disp_sz.y})
		if .Hover_In  in res  { start_hover(gs, pcid) }
		if .Hover_Out in res  { stop_hover(gs, pcid) }
		if .Click in res {
			if gs.selected_card != 0 && gs.selected_card != pcid {
				toggle_select(gs, gs.selected_card)
			}
			toggle_select(gs, pcid)
			gs.selected_card = pcid
		}

		render_card(gs, pcid, rl.Vector2{x, y}, c_disp_sz)
		x += c_disp_sz.x + c_pad
	}
}

start_hover :: proc(gs: ^Game_State, card_id: Card_Id) {
	for &c in gs.cards {
		if c.id == card_id {
			c.is_hovered = true
			return
		}
	}
}

stop_hover :: proc(gs: ^Game_State, card_id: Card_Id) {
	for &c in gs.cards {
		if c.id == card_id {
			c.is_hovered = false
			return
		}
	}
}

toggle_select :: proc(gs: ^Game_State, card_id: Card_Id) {
	for &c in gs.cards {
		if c.id == card_id {
			c.is_selected = !c.is_selected
			return
		}
	}
}
