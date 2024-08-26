package arsenal

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "qv"
import rl "vendor:raylib"

// structures
Arsenal_Screen :: enum {
	Title = 0,
	Intro,
	Configure_Ship,
	Battle,
	Destruction,
	Victory,
}

Direction :: enum {
	Down,
	Left,
	Right,
	Up,
}

Entity :: struct {
	x, y: f32,
	prev_x, prev_y: f32,
	dx, dy: f32,
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
	Normal,
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
	vert_spd: f32,
	enemy_level, player_level: int,
	dx, dy: f32,
	accel: f32,
	init_spd: f32,
	hp_max: int,
	max_bullets_loaded: int,
	ai_fire_rate: int,
	color: qv.Palette_Color,
}

Weapon_Type :: enum {
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
CHAINGUN_COOLDOWN_MS     :: 50
DEFAULT_TYPING_SPEED_CPS :: 200
INTRO_DISABLED           :: true

sh, sw: int
cur_screen: Arsenal_Screen
enemy, player: Entity
enemy_bullets, player_bullets: [20]Entity
enemy_bullets_loaded, player_bullets_loaded: int
x_right_threshold, x_left_threshold: f32

ships_configured := false
weapon_chosen    := false
weapons := map[Weapon_Type]Weapon{
	.Missile   = Weapon{ type=.Missile,   handle="Missile",   dx=20, dy=4,  init_spd=0.4, ai_fire_rate=4,  color=.Yellow,  player_level=1, enemy_level=1},
	.Homer     = Weapon{ type=.Homer,     handle="Homer",     dx=6,  dy=6,  init_spd=0.4, ai_fire_rate=4,  color=.Cyan,    player_level=1, enemy_level=1},
	.Nuke      = Weapon{ type=.Nuke,      handle="Nuke",      dx=40, dy=8,  init_spd=4,   ai_fire_rate=10, color=.Brown,   player_level=1, enemy_level=1},
	.Knife     = Weapon{ type=.Knife,     handle="Knife",     dx=15, dy=2,  init_spd=20,  ai_fire_rate=6,  color=.Gray,    player_level=1, enemy_level=1},
	.Chain_Gun = Weapon{ type=.Chain_Gun, handle="Chain Gun", dx=20, dy=2,  init_spd=8,   ai_fire_rate=2,  color=.White,   player_level=1, enemy_level=1},
	.Twin 	   = Weapon{ type=.Twin, 	  handle="Twin", 	  dx=25, dy=2,  init_spd=4,   ai_fire_rate=4,  color=.Green,   player_level=1, enemy_level=1},
	.Wave      = Weapon{ type=.Wave,      handle="Wave",      dx=10, dy=4,  init_spd=14,  ai_fire_rate=10, color=.Magenta, player_level=1, enemy_level=1},
	.Barrier   = Weapon{ type=.Barrier,   handle="Barrier",   dx=4,  dy=80, init_spd=4,   ai_fire_rate=8,  color=.Blue,    player_level=1, enemy_level=1, accel=0.1},
	.Splitter  = Weapon{ type=.Splitter,  handle="Splitter",  dx=20, dy=4,  init_spd=15,  ai_fire_rate=4,  color=.Green,   player_level=1, enemy_level=1, vert_spd=6, max_bullets_loaded=18},
}

// procedures
check_collisions :: proc() {

}

destruction :: proc() {

}

display_stats :: proc() {
	qv.print(fmt.tprintf("HP: %i/%i", player.hp, player.hp_max), qv.Text_Point{2, 1}, .Red)
	qv.print(fmt.tprintf("[%s-%i]", player.cur_weapon.handle, player.cur_weapon.player_level), qv.Text_Point{21, 1}, .Red)
 
	qv.print(fmt.tprintf("[%s-%i]", enemy.cur_weapon.handle, enemy.cur_weapon.player_level), qv.Text_Point{75, 1}, .Blue)
	qv.print(fmt.tprintf("HP: %i/%i", enemy.hp, enemy.hp_max), qv.Text_Point{95, 1}, .Blue)
}

do_game :: proc() {
	check_collisions()

	player_control()
	enemy_control()

	qv.clear_screen(.Black)
	display_stats()
	player_graphics()
	enemy_graphics()

	player_bullets_update()
	enemy_bullets_update()
}

do_intro :: proc() {
	qv.clear_screen(.Black)

	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)

	qv.type("Welcome to the Arsenal Network", qv.Text_Point{2, 2}, .Green)

	login := "mazer"
	qv.set_typing_speed(8)
	qv.print("Login: ", qv.Text_Point{2, 4}, .Green)
	qv.wait(1000)
	qv.type(login, qv.Text_Point{9, 4}, .Cyan)
	qv.print("Password: ", qv.Text_Point{2, 5}, .Green)
	qv.wait(1200)
	qv.type("*********", qv.Text_Point{12, 5}, .Cyan)

	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)

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
	qv.type("<EOF received from client>", qv.Text_Point{2, 17}, .Yellow)

	qv.print("% ", qv.Text_Point{2, 19}, .Green)
	qv.wait(1500)
	qv.type("exec ./arsenal.sh", qv.Text_Point{4, 19}, .Cyan)
	qv.type("Security clearance granted ", qv.Text_Point{2, 20}, .Green)
	qv.type("Are you sure you wish to launch Arsenal? [yn] ", qv.Text_Point{2, 21}, .Green)
	qv.wait(1500)
	qv.print("y", qv.Text_Point{48, 21}, .Cyan)

	qv.type("[Ready! Press any key to launch]", qv.Text_Point{2, 24}, .White)
	if (qv.ready_to_continue(wait_for_keypress = true)) {
		cur_screen = .Configure_Ship
		qv.reset_frame_memory()
	}
}

do_loop :: proc() {
	qv.create_window("Arsenal", .Seven_Twenty_P)
	sw = qv.get_screen_width()
	sh = qv.get_screen_height()
	x_right_threshold = f32(sw) * 0.6
	x_left_threshold  = f32(sw) * 0.4
	
	qv.set_text_style(24, 0, 4)
	for !qv.should_close() {
		qv.begin()
		defer qv.present()

		switch cur_screen {
		case .Title:
			do_title()
		case .Intro:
			if INTRO_DISABLED {
				cur_screen = .Configure_Ship
				continue
			}
			do_intro()
		case .Configure_Ship:
			load_settings()
		case .Battle:
			do_game()
		case .Destruction:
			destruction()
		case .Victory:
			victory()
		}
	}
	qv.close()
}

do_title :: proc() {
	qv.clear_screen(.Black)
	for i in 1..=60 {
		phase := math.sin_f32(0.5*f32(i)+qv.get_elapsed_time()*3)
		qv.sizeable_line(qv.Point{f32(i*sw/60), 1}, qv.Point{f32(sw), f32(i*sh/60)}, .Red, phase+1.2)
		qv.sizeable_line(qv.Point{1, f32(i*sh/60)}, qv.Point{f32(i*sw/60), f32(sh)}, .Red, phase+2.0)
	}

	title := "r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
	qv.draw("bm280,350 c15 s12")
	qv.draw(title)

	author := "u15nu15r20d15nl20br5bu15 f15ng15e15bu15br20 nd30r20d30nl20bu10bl5f10 br5u30r20d10nl20bu10br5 r20g30"
	qv.draw("bm790,420 c9 s4")
	qv.draw(author)

	qv.print_centered("Press any key to start", qv.get_text_rows()-5, .Gray)
	if (qv.ready_to_continue(wait_for_keypress = true)) {
		init()
		cur_screen = .Intro
		qv.reset_frame_memory()
	}
}

enemy_bullets_update :: proc() {
	for &b in enemy_bullets {
		#partial switch b.status {
		case .Normal:
			b.spd = b.spd + enemy.cur_weapon.accel
			if b.x < 0 {
				b.status = .Dead
				enemy_bullets_loaded = enemy_bullets_loaded-1
			} else {
				b.prev_x = b.x
				b.prev_y = b.y
				b.x = b.x - b.spd * rl.GetFrameTime()
				#partial switch enemy.cur_weapon.type {
				case .Homer:
					if b.y > player.y { b.direction = .Up }
					if b.y < player.y { b.direction = .Down }
					if b.direction == .Down { b.y = b.y+enemy.cur_weapon.vert_spd }
					if b.direction == .Up   { b.y = b.y-enemy.cur_weapon.vert_spd }
				case .Wave:
					b.y = f32(b.yi) - 20*math.sin_f32((b.x-f32(b.xi)) / 50)
				case .Splitter:
					if b.x < x_left_threshold {
						if b.direction == .Down { b.y = b.y+enemy.cur_weapon.vert_spd }
						if b.direction == .Up   { b.y = b.y-enemy.cur_weapon.vert_spd }
					}
				}
				qv.rectangle(qv.Point{b.x, b.y}, qv.Point{b.x+enemy.cur_weapon.dx, b.y+enemy.cur_weapon.dy}, enemy.cur_weapon.color)
			}
		case .Exploding:
			b.exp_counter = b.exp_counter-1
			if b.exp_counter > 0 {
				b.x = b.x+b.spd*rl.GetFrameTime()
				qv.circle(qv.Point{b.x+enemy.cur_weapon.dx/2, b.y+enemy.cur_weapon.dy/2}, f32(b.exp_counter*4), enemy.cur_weapon.color)
			} else {
				b.status = .Dead
				enemy_bullets_loaded = enemy_bullets_loaded-1
			}
		}
	}

}

enemy_control :: proc() {
	@(static)chaingun_cooldown: f32
	max_bullets_loaded: int
  
	if int(rand.float32() * 20) + 1 == 1 {
		enemy.direction = .Up if enemy.direction == .Down else .Down
	}
	if enemy.cur_weapon.type != .Chain_Gun && int(rand.float32() * f32(enemy.cur_weapon.ai_fire_rate)) + 1 == 1 {
		cur_type := enemy.cur_weapon.type
		if cur_type == .Splitter || cur_type == .Barrier || cur_type == .Nuke || cur_type == .Knife {
			max_bullets_loaded = enemy.cur_weapon.max_bullets_loaded
		} else {
			max_bullets_loaded = len(enemy_bullets)
		}
		
		#partial switch cur_type {
		case .Twin:
			if enemy_bullets_loaded < max_bullets_loaded {
				enemy_bullets_loaded = enemy_bullets_loaded+1
				for &b in enemy_bullets {
					if b.status == .Dead {
						b.status = .Normal
						b.x = enemy.x + enemy.dx
						b.y = enemy.y + enemy.dy*2
						b.spd = enemy.cur_weapon.init_spd
						break
					}
				}
			}
			if enemy_bullets_loaded < max_bullets_loaded {
				enemy_bullets_loaded = enemy_bullets_loaded+1
				for &b in enemy_bullets {
					if b.status == .Dead {
						b.status = .Normal
						b.x = enemy.x + enemy.dx
						b.y = enemy.y - enemy.dy*2
						b.spd = enemy.cur_weapon.init_spd
						break
					}
				}
			}
		case .Splitter:
			if enemy_bullets_loaded < max_bullets_loaded {
				for i in 1..=3 {
					if enemy_bullets_loaded < max_bullets_loaded {
						enemy_bullets_loaded = enemy_bullets_loaded+1
						for &b in enemy_bullets {
							if b.status == .Dead {
								b.status = .Normal
								b.x   = enemy.x+enemy.dx+1
								b.y   = enemy.y+(enemy.dy/2) - 1 - (enemy.cur_weapon.dy / 2)
								b.yi  = int(b.y)
								b.xi  = int(b.x)
								b.spd = enemy.cur_weapon.init_spd
								if i == 1 { b.direction = .Down }
								if i == 2 { b.direction = .Up }
								if i == 3 { b.direction = .Left }
								break
							}
						}
					}
				}
			}
		case:
			if enemy_bullets_loaded < max_bullets_loaded {
				enemy_bullets_loaded = enemy_bullets_loaded+1
				for &b in enemy_bullets {
					if b.status == .Dead {
						b.status = .Normal
						b.x = enemy.x-enemy.cur_weapon.dx-1
						b.y = enemy.y+(enemy.dy/2) - (enemy.cur_weapon.dy/2)
						b.yi = int(b.y)
						b.xi = int(b.x)
						b.spd = enemy.cur_weapon.init_spd
						if enemy.cur_weapon.type == .Nuke || enemy.cur_weapon.type == .Barrier {
							b.hp = enemy.cur_weapon.hp_max
						}
						break
					}
				}
			}
		}
	}

	if chaingun_cooldown <= 0 && enemy.cur_weapon.type == .Chain_Gun {
		if enemy_bullets_loaded < len(enemy_bullets) {
			for &b in enemy_bullets {
				if b.status == .Dead {
					b.status = .Normal
					b.x = enemy.x - enemy.dx + 1
					b.y = enemy.y - enemy.dy / 2 - 1
					b.spd = enemy.cur_weapon.init_spd

					enemy_bullets_loaded = enemy_bullets_loaded+1
					chaingun_cooldown = CHAINGUN_COOLDOWN_MS
					break
				}
			}
		}
	}
			
	chaingun_cooldown = chaingun_cooldown-(rl.GetFrameTime()*1000)
}

enemy_graphics :: proc() {
	#partial switch enemy.direction {
	case .Up: 
		new_y := enemy.y-enemy.spd*rl.GetFrameTime()
		if new_y < 20 {
			enemy.y = 20
			enemy.direction = .Down
		} else {
			enemy.y = new_y
		}
	case .Down:
		new_y := enemy.y+enemy.spd*rl.GetFrameTime()
		if new_y > f32(sh)-enemy.dy {
			enemy.y = f32(sh)-enemy.dy
			enemy.direction = .Up
		} else {
			enemy.y = new_y
		}
	}	

	qv.rectangle(qv.Point{enemy.x, enemy.y}, qv.Point{enemy.x+enemy.dx, enemy.y+enemy.dy}, .Blue)
   
	if enemy.status == .Exploding {
		enemy.exp_counter = enemy.exp_counter - 1
		if enemy.exp_counter <= 0 {
			enemy.status = .Normal
		}
		qv.circle(qv.Point{enemy.x+enemy.dx/2, enemy.y+enemy.dy/2}, f32(enemy.exp_counter * 8), .Blue)
	}
}

init :: proc() {
	player.cur_weapon.player_level = 1
	enemy.cur_weapon.enemy_level = 1
		  
	player.x = 30
	player.y = f32(sh / 2)
	player.hp = 50
	player.hp_max = 50
	player.spd = 180
	player.dx = 24
	player.dy = 24
	player.status = .Normal
 
	enemy.x = f32(sw - 40)
	enemy.y = f32(sh / 2)
	enemy.hp = 100
	enemy.hp_max = 100
	enemy.spd = 180
	enemy.dx = 24
	enemy.dy = 24
	enemy.status = .Normal
	load_weapons(.Enemy)

	enemy.cur_weapon = weapons[.Knife]
	// TODO: Re-enable random after weapons testing
	//enemy.cur_weapon = weapons[rand.choice_enum(Weapon_Type)]
	load_weapons(.Enemy)
}

load_settings :: proc() {
	@(static) chosen_weapon_type: Weapon_Type
	if !weapon_chosen {
		for kp := rl.GetKeyPressed(); kp != .KEY_NULL; kp=rl.GetKeyPressed() {
			#partial switch kp {
			case .UP:
				new_weapon_idx := int(chosen_weapon_type)-1 if chosen_weapon_type != .Missile else int(Weapon_Type.Splitter)
				chosen_weapon_type = Weapon_Type(new_weapon_idx)
			case .DOWN:
				new_weapon_idx := int(chosen_weapon_type)+1 if chosen_weapon_type != .Splitter else int(Weapon_Type.Missile)
				chosen_weapon_type = Weapon_Type(new_weapon_idx)
			case .ENTER:
				weapon_chosen = true
			}
		}
	}

	qv.clear_screen(.Black)
	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)
	qv.type("A R S E N A L", qv.Text_Point{2, 2}, .Dark_Green)
	qv.type("Terran craft",  qv.Text_Point{2, 4}, .Red)
	qv.type(fmt.tprintf("HP:    %i", player.hp),  qv.Text_Point{2, 5}, .Green)
	qv.type(fmt.tprintf("Speed: %v", player.spd), qv.Text_Point{2, 6}, .Green)
   
	qv.type("Kulari craft",  qv.Text_Point{40, 4}, .Blue)
	qv.type(fmt.tprintf("HP:     %i", enemy.hp),  qv.Text_Point{40, 5}, .Dark_Green)
	qv.type(fmt.tprintf("Speed:  %v", enemy.spd), qv.Text_Point{40, 6}, .Dark_Green)
	qv.type("Weapon: ", qv.Text_Point{40, 7}, .Dark_Green)
	qv.type(enemy.cur_weapon.handle, qv.Text_Point{48, 7}, enemy.cur_weapon.color)
 
	qv.type("Make a weapon selection ([ENTER] to confirm):", qv.Text_Point{2, 9}, .Dark_Green)
	for wt in Weapon_Type {
		if chosen_weapon_type == wt {
			qv.print("- ", qv.Text_Point{2, 10+int(wt)}, weapons[wt].color)
		}
		qv.print(weapons[wt].handle, qv.Text_Point{4, 10+int(wt)}, weapons[wt].color)
	}

	if weapon_chosen && !ships_configured {
		player_bullets_loaded = 0
		player.hp = player.hp_max
		player.x = 30
		player.y = f32(sh / 2)
		player.status = .Normal
		load_weapons(.Player)
		player.cur_weapon = weapons[chosen_weapon_type]
	
		enemy_bullets_loaded = 0
		enemy.direction = .Down if rand.float32() > 0.5 else .Up
		enemy.hp = enemy.hp_max
		enemy.x = f32(sw - 40)
		enemy.y = f32(sh / 2)
		enemy.status = .Normal
		load_weapons(.Enemy)

		ships_configured = true
	}

	if ships_configured {
		qv.type(player.cur_weapon.handle, qv.Text_Point{2, 24}, player.cur_weapon.color)
		qv.type(" selected. Hit [ENTER] to enage Kulari craft", qv.Text_Point{2+len(player.cur_weapon.handle), 24}, .White)
		if (qv.ready_to_continue(wait_for_keypress = true)) {
			cur_screen = .Battle
			qv.reset_frame_memory()
		}
	}
}

load_weapons :: proc(which: Owner) {
	ACCEL_FACTOR :: 1.5
	missile := weapons[.Missile]
	if which == .Player {
		if player.cur_weapon.type == .Missile {
			missile.player_level = player.cur_weapon.player_level
		}
		missile.power = player.cur_weapon.player_level + 4
		missile.accel = f32(player.cur_weapon.player_level+3) * ACCEL_FACTOR
	} else {
		if enemy.cur_weapon.type == .Missile {
			missile.enemy_level = enemy.cur_weapon.enemy_level
		}
		missile.power = enemy.cur_weapon.enemy_level + 4
		missile.accel = f32(enemy.cur_weapon.enemy_level+3) * ACCEL_FACTOR
	}
	weapons[.Missile] = missile

	homer := weapons[.Homer]
	if which == .Player {
		if player.cur_weapon.type == .Homer {
			homer.player_level = player.cur_weapon.player_level
		}
		homer.power = player.cur_weapon.player_level + 2
		homer.accel = f32(player.cur_weapon.player_level)  * ACCEL_FACTOR
		homer.vert_spd = 1 + f32(player.cur_weapon.player_level) / 10
	} else {
		if enemy.cur_weapon.type == .Homer {
			homer.enemy_level = enemy.cur_weapon.enemy_level
		}
		homer.power = enemy.cur_weapon.enemy_level + 2
		homer.accel = f32(enemy.cur_weapon.enemy_level) * ACCEL_FACTOR
		homer.vert_spd = 1 + f32(enemy.cur_weapon.enemy_level) / 10
	}
   	weapons[.Homer] = homer

	nuke := weapons[.Nuke]
	if which == .Player {
		if player.cur_weapon.type == .Nuke {
			nuke.player_level = player.cur_weapon.player_level
		}
		nuke.power = player.cur_weapon.player_level * 2 + 10
		nuke.accel = f32(player.cur_weapon.player_level) * ACCEL_FACTOR
		nuke.hp_max = 20 + (player.cur_weapon.player_level * 2)
		nuke.max_bullets_loaded = player.cur_weapon.player_level + 4
	} else {
		if enemy.cur_weapon.type == .Nuke {
			nuke.enemy_level = enemy.cur_weapon.enemy_level
		}
		nuke.power = enemy.cur_weapon.enemy_level * 5 + 3
		nuke.accel = f32(enemy.cur_weapon.enemy_level) * ACCEL_FACTOR
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
		knife.accel = f32(player.cur_weapon.player_level) * ACCEL_FACTOR * 0.5
		knife.max_bullets_loaded = player.cur_weapon.player_level + 3
	} else {
		if enemy.cur_weapon.type == .Knife {
			knife.enemy_level = enemy.cur_weapon.enemy_level
		}
		knife.power = enemy.cur_weapon.enemy_level + 1
		knife.accel = f32(enemy.cur_weapon.enemy_level) * ACCEL_FACTOR * 0.5
		knife.max_bullets_loaded = enemy.cur_weapon.enemy_level + 3
	}
	weapons[.Knife] = knife

	chain_gun := weapons[.Chain_Gun]
	if which == .Player {
		if player.cur_weapon.type == .Chain_Gun {
			chain_gun.player_level = player.cur_weapon.player_level
		}
		chain_gun.power = player.cur_weapon.player_level + 2
		chain_gun.accel = f32(player.cur_weapon.player_level + 3) * ACCEL_FACTOR
	} else {
		if enemy.cur_weapon.type == .Chain_Gun {
			chain_gun.enemy_level = enemy.cur_weapon.enemy_level
		}
		chain_gun.power = enemy.cur_weapon.enemy_level + 2
		chain_gun.accel = f32(enemy.cur_weapon.enemy_level + 3) * ACCEL_FACTOR
	}
	weapons[.Chain_Gun] = chain_gun

	twin := weapons[.Twin]
	if which == .Player {
		if player.cur_weapon.type == .Twin {
			twin.player_level = player.cur_weapon.player_level
		}
		twin.power = player.cur_weapon.player_level + 3
		twin.accel = f32(player.cur_weapon.player_level + 3) * ACCEL_FACTOR
	} else {
		if enemy.cur_weapon.type == .Twin {
			twin.enemy_level = enemy.cur_weapon.enemy_level
		}
		twin.power = enemy.cur_weapon.enemy_level + 3
		twin.accel = f32(enemy.cur_weapon.enemy_level + 3) * ACCEL_FACTOR
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
		splitter.accel = f32(player.cur_weapon.player_level + 3) * ACCEL_FACTOR
	} else {
		if enemy.cur_weapon.type == .Splitter {
			splitter.enemy_level = enemy.cur_weapon.enemy_level
		}
		splitter.power = enemy.cur_weapon.enemy_level + 4
		splitter.accel = f32(enemy.cur_weapon.enemy_level + 3) * ACCEL_FACTOR
	}
	weapons[.Splitter] = splitter
}

player_bullets_update :: proc() {
	for &b in player_bullets {
		#partial switch b.status {
		case .Normal:
			b.spd = b.spd + player.cur_weapon.accel
			if b.x+player.cur_weapon.dx > f32(sw) {
				b.status = .Dead
				player_bullets_loaded = player_bullets_loaded-1
			} else {
				b.prev_x = b.x
				b.prev_y = b.y
				b.x = b.x + b.spd * rl.GetFrameTime()
				#partial switch player.cur_weapon.type {
				case .Homer:
					if b.y > enemy.y { b.direction = .Up }
					if b.y < enemy.y { b.direction = .Down }
					if b.direction == .Down { b.y = b.y + player.cur_weapon.vert_spd }
					if b.direction == .Up   { b.y = b.y - player.cur_weapon.vert_spd }
				case .Wave:
					b.y = f32(b.yi) - 20*math.sin_f32((b.x-f32(b.xi)) / 50)
				case .Splitter:
					if b.x > x_right_threshold {
						if b.direction == .Down { b.y = b.y + player.cur_weapon.vert_spd }
						if b.direction == .Up   { b.y = b.y - player.cur_weapon.vert_spd }
					}
				}
				qv.rectangle(qv.Point{b.x, b.y}, qv.Point{b.x+player.cur_weapon.dx, b.y+player.cur_weapon.dy}, player.cur_weapon.color)
			}
		case .Exploding:
			b.exp_counter = b.exp_counter-1
			if b.exp_counter > 0 {
				b.x = b.x-b.spd*rl.GetFrameTime()
				qv.circle(qv.Point{b.x+player.cur_weapon.dx/2, b.y+player.cur_weapon.dy/2}, f32(b.exp_counter*4), player.cur_weapon.color)
			} else {
				b.status = .Dead
				player_bullets_loaded = player_bullets_loaded-1
			}
		}
	}
}

player_control :: proc() {
	@(static)chaingun_cooldown: f32
	max_bullets_loaded: int

	for pk := rl.GetKeyPressed(); pk != .KEY_NULL; pk = rl.GetKeyPressed() {
		#partial switch pk {
		case .UP:
			player.direction = .Up
		case .LEFT:
			player.direction = .Left
		case .RIGHT:
			player.direction = .Right
		case .DOWN:
			player.direction = .Down
		case .F:
			if player.cur_weapon.type == .Chain_Gun {
				continue
			}
			cur_type := player.cur_weapon.type
			if cur_type == .Splitter || cur_type == .Barrier || cur_type == .Nuke || cur_type == .Knife {
				max_bullets_loaded = player.cur_weapon.max_bullets_loaded
			} else {
				max_bullets_loaded = len(player_bullets)
			}
			
			#partial switch cur_type {
			case .Twin:
				if player_bullets_loaded < max_bullets_loaded {
					player_bullets_loaded = player_bullets_loaded+1
					for &b in player_bullets {
						if b.status == .Dead {
							b.status = .Normal
							b.x = player.x - player.dx
							b.y = player.y - player.dy*2
							b.spd = player.cur_weapon.init_spd
							break
						}
					}
				}
				if player_bullets_loaded < max_bullets_loaded {
					player_bullets_loaded = player_bullets_loaded+1
					for &b in player_bullets {
						if b.status == .Dead {
							b.status = .Normal
							b.x = player.x - player.dx
							b.y = player.y + player.dy*2
							b.spd = player.cur_weapon.init_spd
							break
						}
					}
				}
			case .Splitter:
				if player_bullets_loaded < max_bullets_loaded {
					for i in 1..=3 {
						if player_bullets_loaded < max_bullets_loaded {
							player_bullets_loaded = player_bullets_loaded+1
							for &b in player_bullets {
								b.status = .Normal
								b.x   = player.x+player.dx+1
								b.y   = player.y+(player.dy/2) - 1 - (player.cur_weapon.dy / 2)
								b.yi  = int(b.y)
								b.xi  = int(b.x)
								b.spd = player.cur_weapon.init_spd
								if i == 1 { b.direction = .Right }
								if i == 2 { b.direction = .Up }
								if i == 3 { b.direction = .Down }
								break
							}
						}
					}
				}
			case:
				if player_bullets_loaded < max_bullets_loaded {
					player_bullets_loaded = player_bullets_loaded+1
					for &b in player_bullets {
						if b.status == .Dead {
							b.status = .Normal
							b.x = player.x+player.dx+1
							b.y = player.y+(player.dy/2) - 1 - (player.cur_weapon.dy / 2)
							b.yi = int(b.y)
							b.xi = int(b.x)
							b.spd = player.cur_weapon.init_spd
							if player.cur_weapon.type == .Nuke || player.cur_weapon.type == .Barrier {
								b.hp = player.cur_weapon.hp_max
							}
							break
						}
					}
				}
			}
		}
	}

	if chaingun_cooldown <= 0 && player.cur_weapon.type == .Chain_Gun {
		if player_bullets_loaded < len(player_bullets) {
			for &b in player_bullets {
				if b.status == .Dead {
					b.status = .Normal
					b.x = player.x + player.dx + 1
					b.y = player.y + player.dy / 2 - 1
					b.spd = player.cur_weapon.init_spd

					player_bullets_loaded = player_bullets_loaded+1
					chaingun_cooldown = CHAINGUN_COOLDOWN_MS
					break
				}
			}
		}
	}
			
	chaingun_cooldown = chaingun_cooldown-(rl.GetFrameTime()*1000)
}

player_graphics :: proc() {
	switch player.direction {
	case .Up: 
		new_y := player.y-player.spd*rl.GetFrameTime()
		player.y = new_y if new_y > 20 else 20
	case .Left:
		new_x := player.x-player.spd*rl.GetFrameTime()
		player.x = new_x if new_x > 0 else 0
	case .Right:
		new_x := player.x+player.spd*rl.GetFrameTime()
		player.x = new_x if new_x < f32(sw)/4-player.dx else f32(sw)/4-player.dx
	case .Down:
		new_y := player.y+player.spd*rl.GetFrameTime()
		player.y = new_y if new_y < f32(sh)-player.dy else f32(sh)-player.dy
	}	

	qv.rectangle(qv.Point{player.x, player.y}, qv.Point{player.x+player.dx, player.y+player.dy}, .Red)
   
	if player.status == .Exploding {
		player.exp_counter = player.exp_counter - 1
		if player.exp_counter <= 0 {
			player.status = .Normal
		}
		qv.circle(qv.Point{player.x+player.dx/2, player.y+player.dy/2}, f32(player.exp_counter * 8), .Red)
	}
}

victory :: proc() {
	qv.clear_screen(.Black)
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

    do_loop()
}