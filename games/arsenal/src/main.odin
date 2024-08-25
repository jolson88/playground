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

Owner :: enum {
	Unknown = 0,
	Enemy,
	Player,
}

Weapon :: struct {
	type: Weapon_Type,
	handle: string,
	power: int,
	vert_spd: int,
	enemy_level, player_level: int,
	dx, dy: int,
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
enemy, player: Entity
enemy_bullets, player_bullets: [20]Entity
play_intro := false
ship_configured := false
sh, sw: int
system_typing_speed := 28
weapons := map[Weapon_Type]Weapon{
	.Missile   = Weapon{ type=.Missile,   handle="Missile",   dx=20, dy=2,  init_spd=0.4, ai_fire_rate=4,  color=.Yellow},
	.Homer     = Weapon{ type=.Homer,     handle="Homer",     dx=5,  dy=2,  init_spd=0.4, ai_fire_rate=4,  color=.Dark_Blue},
	.Nuke      = Weapon{ type=.Nuke,      handle="Nuke",      dx=40, dy=4,  init_spd=4,   ai_fire_rate=10, color=.Dark_Yellow},
	.Knife     = Weapon{ type=.Knife,     handle="Knife",     dx=15, dy=1,  init_spd=20,  ai_fire_rate=6,  color=.Gray},
	.Chain_Gun = Weapon{ type=.Chain_Gun, handle="Chain Gun", dx=20, dy=1,  init_spd=8,   ai_fire_rate=1,  color=.White},
	.Twin 	   = Weapon{ type=.Twin, 	  handle="Twin", 	  dx=25, dy=1,  init_spd=4,   ai_fire_rate=4,  color=.Dark_Green},
	.Wave      = Weapon{ type=.Wave,      handle="Wave",      dx=10, dy=2,  init_spd=14,  ai_fire_rate=10, color=.Red},
	.Barrier   = Weapon{ type=.Barrier,   handle="Barrier",   dx=4,  dy=40, init_spd=4,   ai_fire_rate=8,  color=.Blue, accel=0.1},
	.Splitter  = Weapon{ type=.Splitter,  handle="Splitter",  dx=20, dy=2,  init_spd=15,  ai_fire_rate=4,  color=.Dark_Red, vert_spd=6, max_bullets_loaded=18},
}

// procedures
game :: proc() {
	qv.create_window("Arsenal", .Seven_Twenty_P)
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
	qv.clear_screen(.Black)
	for i in 1..=60 {
		phase := math.sin_f32(0.5*f32(i)+qv.get_elapsed_time()*3)
		qv.sizeable_line(qv.Point{i*sw/60, 1}, qv.Point{sw, i*sh/60}, .Dark_Red, phase+1.2)
		qv.sizeable_line(qv.Point{1, i*sh/60}, qv.Point{i*sw/60, sh}, .Dark_Red, phase+2.0)
	}

	title := "r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
	qv.draw("bm280,350 c15 s12")
	qv.draw(title)

	author := "u15nu15r20d15nl20br5bu15 f15ng15e15bu15br20 nd30r20d30nl20bu10bl5f10 br5u30r20d10nl20bu10br5 r20g30"
	qv.draw("bm790,420 c9 s4")
	qv.draw(author)

	qv.print_centered("Press any key to start", qv.get_text_rows()-5, .Gray)
}

intro :: proc() {
	qv.clear_screen(.Black)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Welcome to the Arsenal Network", qv.Text_Point{2, 2}, .Green)

	login := "mazer"
	qv.set_typing_speed(8)
	qv.print("Login: ", qv.Text_Point{2, 4}, .Green)
	qv.wait(1000)
	qv.type(login, qv.Text_Point{9, 4}, .Cyan)

	qv.print("Password: ", qv.Text_Point{2, 5}, .Green)
	qv.wait(1200)
	qv.type("*********", qv.Text_Point{12, 5}, .Cyan)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Verifying........", qv.Text_Point{2, 7}, .Green)
	qv.print("Access granted", qv.Text_Point{2, 8}, .Green)
	qv.wait(1000)

	msg := qv.concat("Welcome to the system [", login, "]")
	qv.type(msg, qv.Text_Point{2, 10}, .Green)
	qv.type("INCOMING MESSAGE FROM COMMAND - SET PRIORITY 1", qv.Text_Point{2, 11}, .Green)

	qv.wait(1000)
	msg = qv.concat("Agent ", login, ", Kurali craft have been detected in sector alpha!")
	qv.type(msg, qv.Text_Point{2, 13}, .Red)
	qv.type("Engage and destroy all enemy craft. Kurali have destroyed Terran headquarters", qv.Text_Point{2, 14}, .Red)
	qv.type("leaving you as our sole countermeasure. Act immediately, as there may not be", qv.Text_Point{2, 15}, .Red)
	qv.type("much mo^D", qv.Text_Point{2, 16}, .Red)
	qv.type("<EOF received from client>", qv.Text_Point{2, 17}, .Green)

	qv.print("% ", qv.Text_Point{2, 19}, .Green)
	qv.wait(1500)
	qv.type("exec ./arsenal.sh", qv.Text_Point{4, 19}, .Cyan)
	qv.type("Security clearance granted ", qv.Text_Point{2, 20}, .Green)
	qv.type("Are you sure you wish to launch Arsenal? [yn] ", qv.Text_Point{2, 21}, .Green)
	qv.wait(1500)
	qv.print("y", qv.Text_Point{48, 21}, .Cyan)
	qv.type("[Ready! Press any key to launch]", qv.Text_Point{2, 24}, .White)
}

configure_ship :: proc() {
	qv.clear_screen(.Black)

	qv.set_typing_speed(system_typing_speed)
	qv.type("Choose desired weaponry...", qv.Text_Point{2, 2}, .Green)
}

load_weapons :: proc(which: Owner) {
	missile := weapons[.Missile]
	if which == .Player {
		if player.cur_weapon.type == .Missile {
			missile.player_level = player.cur_weapon.player_level
		}
		missile.power = player.cur_weapon.player_level + 4
		missile.accel = f32(player.cur_weapon.player_level + 3) / 10
	} else {
		if enemy.cur_weapon.type == .Missile {
			missile.enemy_level = enemy.cur_weapon.enemy_level
		}
		missile.power = enemy.cur_weapon.enemy_level + 4
		missile.accel = f32(enemy.cur_weapon.enemy_level + 3) / 10
	}
	weapons[.Missile] = missile

	homer := weapons[.Homer]
	if which == .Player {
		if player.cur_weapon.type == .Homer {
			homer.player_level = player.cur_weapon.player_level
		}
		homer.power = player.cur_weapon.player_level + 2
		homer.accel = f32(player.cur_weapon.player_level / 10)
		homer.vert_spd = 1 + (player.cur_weapon.player_level / 10)
	} else {
		if enemy.cur_weapon.type == .Homer {
			homer.enemy_level = enemy.cur_weapon.enemy_level
		}
		homer.power = enemy.cur_weapon.enemy_level + 2
		homer.accel = f32(enemy.cur_weapon.enemy_level / 10)
		homer.vert_spd = 1 + (enemy.cur_weapon.enemy_level / 10)
	}
   	weapons[.Homer] = homer

	nuke := weapons[.Nuke]
	if which == .Player {
		if player.cur_weapon.type == .Nuke {
			nuke.player_level = player.cur_weapon.player_level
		}
		nuke.power = player.cur_weapon.player_level * 2 + 10
		nuke.accel = f32(player.cur_weapon.player_level / 10)
		nuke.hp_max = 20 + (player.cur_weapon.player_level * 2)
		nuke.max_bullets_loaded = player.cur_weapon.player_level + 4
	} else {
		if enemy.cur_weapon.type == .Nuke {
			nuke.enemy_level = enemy.cur_weapon.enemy_level
		}
		nuke.power = enemy.cur_weapon.enemy_level * 5 + 3
		nuke.accel = f32(enemy.cur_weapon.enemy_level / 10)
		nuke.hp_max = 20 + (enemy.cur_weapon.enemy_level * 2)
		nuke.max_bullets_loaded = enemy.cur_weapon.enemy_level + 4
	}
	if nuke.max_bullets_loaded > len(player_bullets) {
		nuke.max_bullets_loaded = len(player_bullets)
	}
	weapons[.Nuke] = nuke

	knife := weapons[.Knife]
	if which == .Player {
		if player.cur_weapon.type == .Knife {
			knife.player_level = player.cur_weapon.player_level
		}
		knife.power = player.cur_weapon.player_level + 1
		knife.accel = f32(player.cur_weapon.player_level / 5)
		knife.max_bullets_loaded = player.cur_weapon.player_level + 3
	} else {
		if enemy.cur_weapon.type == .Knife {
			knife.enemy_level = enemy.cur_weapon.enemy_level
		}
		knife.power = enemy.cur_weapon.enemy_level + 1
		knife.accel = f32(enemy.cur_weapon.enemy_level / 5)
		knife.max_bullets_loaded = enemy.cur_weapon.enemy_level + 3
	}
	weapons[.Knife] = knife

	chain_gun := weapons[.Chain_Gun]
	if which == .Player {
		if player.cur_weapon.type == .Chain_Gun {
			chain_gun.player_level = player.cur_weapon.player_level
		}
		chain_gun.power = player.cur_weapon.player_level + 2
		chain_gun.accel = f32(player.cur_weapon.player_level + 3 / 10)
	} else {
		if enemy.cur_weapon.type == .Chain_Gun {
			chain_gun.enemy_level = enemy.cur_weapon.enemy_level
		}
		chain_gun.power = enemy.cur_weapon.enemy_level + 2
		chain_gun.accel = f32(enemy.cur_weapon.enemy_level + 3 / 10)
	}
	weapons[.Chain_Gun] = chain_gun

	twin := weapons[.Twin]
	if which == .Player {
		if player.cur_weapon.type == .Twin {
			twin.player_level = player.cur_weapon.player_level
		}
		twin.power = player.cur_weapon.player_level + 3
		twin.accel = f32(player.cur_weapon.player_level + 3 / 10)
	} else {
		if enemy.cur_weapon.type == .Twin {
			twin.enemy_level = enemy.cur_weapon.enemy_level
		}
		twin.power = enemy.cur_weapon.enemy_level + 3
		twin.accel = f32(enemy.cur_weapon.enemy_level + 3 / 10)
	}
	weapons[.Twin] = twin

	wave := weapons[.Wave]
	if which == .Player {
		if player.cur_weapon.type == .Wave {
			wave.player_level = player.cur_weapon.player_level
		}
		wave.power = player.cur_weapon.player_level + 5
		wave.accel = 0
	} else {
		if enemy.cur_weapon.type == .Wave {
			wave.enemy_level = enemy.cur_weapon.enemy_level
		}
		wave.power = enemy.cur_weapon.enemy_level + 5
		wave.accel = 0
	}
	weapons[.Wave] = wave

	barrier := weapons[.Barrier]
	if which == .Player {
		if player.cur_weapon.type == .Barrier {
			barrier.player_level = player.cur_weapon.player_level
			barrier.hp_max = 40 + (player.cur_weapon.player_level * 2)
			barrier.max_bullets_loaded = player.cur_weapon.player_level / 5 + 4
			barrier.power = player.cur_weapon.player_level + 2
		}
	} else {
		if enemy.cur_weapon.type == .Barrier {
			barrier.enemy_level = enemy.cur_weapon.enemy_level
			barrier.power = enemy.cur_weapon.enemy_level + 2
			barrier.hp_max = 40 + (enemy.cur_weapon.enemy_level * 2)
			barrier.max_bullets_loaded = enemy.cur_weapon.enemy_level / 5 + 4
		}
	}
	if barrier.max_bullets_loaded > len(player_bullets) {
		barrier.max_bullets_loaded = len(player_bullets)
	}
	weapons[.Barrier] = barrier

	splitter := weapons[.Splitter]
	if which == .Player {
		if player.cur_weapon.type == .Splitter {
			splitter.player_level = player.cur_weapon.player_level
		}
		splitter.power = player.cur_weapon.player_level + 4
		splitter.accel = f32(player.cur_weapon.player_level + 3 / 10)
	} else {
		if enemy.cur_weapon.type == .Splitter {
			splitter.enemy_level = enemy.cur_weapon.enemy_level
		}
		splitter.power = enemy.cur_weapon.enemy_level + 4
		splitter.accel = f32(enemy.cur_weapon.enemy_level + 3 / 10)
	}
	weapons[.Splitter] = splitter
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