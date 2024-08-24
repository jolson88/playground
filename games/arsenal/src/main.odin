package arsenal

import "core:fmt"
import "core:math"
import "core:mem"
import "qv"

// structures
Arsenal_Screen :: enum {
	Title = 0,
	Intro,
	Configure_Ship,
}

Direction :: enum {
	None = 0,
	Down,
	Left,
	Right,
	Up,
}

Entity :: struct {
	x, y: int,
	prev_x, prev_y: int,
	dx, dy: int,
	xi, yi: int,
	hp: int,
	hp_max: int,
	spd: f32,
	status: Entity_Status,
	direction: Direction,
	counter: int,
	exp_counter: int,
	cur_weapon: Weapon,
}

Entity_Status :: enum {
	Dead = 0,
	Alive,
	Exploding,
}

Weapon :: struct {
	type: Weapon_Type,
	handle: string,
	power: int,
	vert_spd: int,
	player_level: int,
	enemy_level: int,
	dx: int,
	dy: int,
	accel: f32,
	init_spd: f32,
	hp_max: int,
	max_bullets_loaded: int,
	ai_fire_rate: int,
	color: qv.Palette_Color,
}

Weapon_Type :: enum {
	None = 0,
	Missile,
	Homer,
	Nuke,
	Knife,
	Chain_Gun,
	Twin,
	Wave,
	Barrier,
	Splitter,
}

// variables
cur_screen: Arsenal_Screen
play_intro := false
ship_configured := false
sh, sw: int
system_typing_speed := 28
weapons := map[Weapon_Type]Weapon{
	.Missile=Weapon{}
}

// procedures
game :: proc() {
	qv.create_window("Arsenal", .SEVEN_TWENTY_P, .FOUR_BIT)
	sw = qv.get_screen_width()
	sh = qv.get_screen_height()
	
	qv.set_text_style(24, 0, 4)
	for !qv.should_close() {
		qv.begin()
		defer qv.present()

		switch cur_screen {
		case .Title:
			title()
			if (qv.ready_to_continue(wait_for_keypress = true)) {
				cur_screen = .Intro
				qv.reset_frame_memory()
			}
		case .Intro:
			if !play_intro {
				cur_screen = .Configure_Ship
				continue
			}
			intro()
			if (qv.ready_to_continue(wait_for_keypress = true)) {
				cur_screen = .Configure_Ship
				qv.reset_frame_memory()
			}
		case .Configure_Ship:
			configure_ship()
			if ship_configured {
				cur_screen = .Title
				qv.reset_frame_memory()
			}
		}
	}
	qv.close()
}

title :: proc() {
	qv.clear_screen(.BLACK)
	for i in 1..=60 {
		phase := math.sin_f32(0.5*f32(i)+qv.get_elapsed_time()*3)
		qv.sizeable_line(qv.Point{i*sw/60, 1}, qv.Point{sw, i*sh/60}, .DARK_RED, phase+1.2)
		qv.sizeable_line(qv.Point{1, i*sh/60}, qv.Point{i*sw/60, sh}, .DARK_RED, phase+2.0)
	}

	title := "r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
	qv.draw("bm280,350 c15 s12")
	qv.draw(title)

	author := "u15nu15r20d15nl20br5bu15 f15ng15e15bu15br20 nd30r20d30nl20bu10bl5f10 br5u30r20d10nl20bu10br5 r20g30"
	qv.draw("bm790,420 c9 s4")
	qv.draw(author)

	qv.print_centered("Press any key to start", qv.get_text_rows()-5, .GRAY)
}

intro :: proc() {
	qv.clear_screen(.BLACK)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Welcome to the Arsenal Network", qv.Text_Point{2, 2}, .GREEN)

	login := "mazer"
	qv.set_typing_speed(8)
	qv.print("Login: ", qv.Text_Point{2, 4}, .GREEN)
	qv.wait(1000)
	qv.type(login, qv.Text_Point{9, 4}, .CYAN)

	qv.print("Password: ", qv.Text_Point{2, 5}, .GREEN)
	qv.wait(1200)
	qv.type("*********", qv.Text_Point{12, 5}, .CYAN)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Verifying........", qv.Text_Point{2, 7}, .GREEN)
	qv.print("Access granted", qv.Text_Point{2, 8}, .GREEN)
	qv.wait(1000)

	msg := qv.concat("Welcome to the system [", login, "]")
	qv.type(msg, qv.Text_Point{2, 10}, .GREEN)
	qv.type("INCOMING MESSAGE FROM COMMAND - SET PRIORITY 1", qv.Text_Point{2, 11}, .GREEN)

	qv.wait(1000)
	msg = qv.concat("Agent ", login, ", Kurali craft have been detected in sector alpha!")
	qv.type(msg, qv.Text_Point{2, 13}, .RED)
	qv.type("Engage and destroy all enemy craft. Kurali have destroyed Terran headquarters", qv.Text_Point{2, 14}, .RED)
	qv.type("leaving you as our sole countermeasure. Act immediately, as there may not be", qv.Text_Point{2, 15}, .RED)
	qv.type("much mo^D", qv.Text_Point{2, 16}, .RED)
	qv.type("<EOF received from client>", qv.Text_Point{2, 17}, .GREEN)

	qv.print("% ", qv.Text_Point{2, 19}, .GREEN)
	qv.wait(1500)
	qv.type("exec ./arsenal.sh", qv.Text_Point{4, 19}, .CYAN)
	qv.type("Security clearance granted ", qv.Text_Point{2, 20}, .GREEN)
	qv.type("Are you sure you wish to launch Arsenal? [yn] ", qv.Text_Point{2, 21}, .GREEN)
	qv.wait(1500)
	qv.print("y", qv.Text_Point{48, 21}, .CYAN)
	qv.type("[Ready! Press any key to launch]", qv.Text_Point{2, 24}, .WHITE)
}

configure_ship :: proc() {
	qv.clear_screen(.BLACK)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Choose desired weaponry...", qv.Text_Point{2, 2}, .GREEN)
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

    game()
}