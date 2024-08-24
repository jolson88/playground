package arsenal

import "core:fmt"
import "core:math"
import "core:mem"
import "qv"

Arsenal_Screen :: enum {
	Title = 0,
	Intro,
}

sw, sh: int
cur_screen: Arsenal_Screen

game :: proc() {
	qv.create_window("Arsenal", .SEVEN_TWENTY_P, .FOUR_BIT)
	sw = qv.get_screen_width()
	sh = qv.get_screen_height()
	
	qv.set_text_style(24, 0, 4)
	qv.set_typing_speed(22)
	for !qv.should_close() {
		qv.begin()

		switch cur_screen {
		case .Title:
			title()
			if (qv.ready_to_continue(wait_for_keypress = true)) {
				cur_screen = .Intro
				qv.reset_typing_memory()
			}

		case .Intro:
			intro()
			if (qv.ready_to_continue(wait_for_keypress = true)) {
				cur_screen = .Title
				qv.reset_typing_memory()
			}
		}

		qv.present()
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

	qv.type("Welcome to the Arsenal database", qv.Text_Point{1, 1}, .GREEN)

	// login := qv.request_input("Login: ", qv.Char_Point{2, 1}, .GREEN, .LIGHT_BLUE)
	// password := qv.request_secret_input("Password: ", qv.Char_Point{3, 1}, .GREEN, .LIGHT_BLUE)

	qv.type("Verifying........", qv.Text_Point{1, 4}, .GREEN)
	qv.print("Access granted", qv.Text_Point{1, 5}, .GREEN)

	// msg := qv.concat("Welcome to the system ", login)
	// qv.type(msg, qv.Char_Point{7, 1}, .GREEN)
	// qv.type("INCOMING MESSAGE FROM COMMAND - SET PRIORITY 1", qv.Char_Point{8, 1}, .GREEN)
	
	// msg = qv.concat("Agent ", login, ", Kurali craft have been detected in sector alpha!")
	// qv.type(msg, qv.Char_Point{10, 1}, .RED)
	// qv.type("Engage and destroy all enemy craft. Kurali have destroyed Terran headquarters", qv.Char_Point{11, 1}, .RED)
	// qv.type("leaving you as our sole countermeasure. Act immediately, as there may not be", qv.Char_Point{12, 1}, .RED)
	// qv.type("much mo^D", qv.Char_Point{13, 1}, .RED)
	// qv.type("<EOF received from client>", qv.Char_Point{14, 1}, .GREEN)

	// qv.print("% ", qv.Char_Point{16, 1}, .GREEN)
	// qv.type("execute arsenal", qv.Char_Point{16, 3}, .LIGHT_BLUE)
	// qv.type("You have security clearence. ", qv.Char_Point{17, 1}, .GREEN)
	// qv.type("Are you sure you wish to launch Arsenal? [yn] ", qv.Char_Point{18, 1}, .GREEN)
	// qv.print("y", qv.Char_Point{18, 47}, .LIGHT_BLUE)
	// qv.type("[Hit any key to execute]", qv.Char_Point{20, 1}, .GREEN)
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