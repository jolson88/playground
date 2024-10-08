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

Rect :: struct {
	left, right, top, bottom: f32,
	delta: f32,
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
	color: rl.Color,
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
DEFAULT_TYPING_SPEED_CPS :: 32
INTRO_DISABLED           :: false
SHIP_EXP_RATE			 :: 200

sh, sw: int
cur_screen: Arsenal_Screen
enemy, player: Entity
enemy_bullets, player_bullets: [20]Entity
enemy_bullets_loaded, player_bullets_loaded: int
ship_death_radius: f32
x_right_threshold, x_left_threshold: f32

ships_configured := false
weapon_chosen    := false
weapons := map[Weapon_Type]Weapon{
	.Missile   = Weapon{ type=.Missile,   handle="Missile",   dx=20, dy=4,   init_spd=0.4, ai_fire_rate=4,  color=rl.YELLOW,  player_level=1, enemy_level=1},
	.Homer     = Weapon{ type=.Homer,     handle="Homer",     dx=10, dy=6,   init_spd=40,  ai_fire_rate=4,  color=rl.SKYBLUE, player_level=1, enemy_level=1},
	.Nuke      = Weapon{ type=.Nuke,      handle="Nuke",      dx=40, dy=8,   init_spd=4,   ai_fire_rate=10, color=rl.BROWN,   player_level=1, enemy_level=1},
	.Knife     = Weapon{ type=.Knife,     handle="Knife",     dx=15, dy=4,   init_spd=800, ai_fire_rate=6,  color=rl.GRAY,    player_level=1, enemy_level=1},
	.Chain_Gun = Weapon{ type=.Chain_Gun, handle="Chain Gun", dx=20, dy=2,   init_spd=8,   ai_fire_rate=2,  color=rl.WHITE,   player_level=1, enemy_level=1},
	.Twin 	   = Weapon{ type=.Twin, 	  handle="Twin", 	  dx=25, dy=2,   init_spd=4,   ai_fire_rate=4,  color=rl.GREEN,   player_level=1, enemy_level=1},
	.Wave      = Weapon{ type=.Wave,      handle="Wave",      dx=10, dy=6,   init_spd=500, ai_fire_rate=6,  color=rl.MAGENTA, player_level=1, enemy_level=1},
	.Barrier   = Weapon{ type=.Barrier,   handle="Barrier",   dx=8,  dy=120, init_spd=200, ai_fire_rate=8,  color=rl.BLUE,    player_level=1, enemy_level=1, accel=0.4},
	.Splitter  = Weapon{ type=.Splitter,  handle="Splitter",  dx=20, dy=4,   init_spd=15,  ai_fire_rate=4,  color=rl.GREEN,   player_level=1, enemy_level=1, vert_spd=300, max_bullets_loaded=18},
}

// procedures
check_collisions :: proc() {
	r1, r2: Rect

	for &pb in player_bullets {
		if pb.status == .Dead {
			continue
		}
		for &eb in enemy_bullets {
			if eb.status == .Dead {
				continue
			}
			r1.right = pb.x
			r1.top = pb.y
			r1.bottom = pb.y + player.cur_weapon.dy
			r2.left = eb.x - enemy.cur_weapon.dx
			r2.top = eb.y
			r2.bottom = eb.y + enemy.cur_weapon.dy

			if pb.x - pb.prev_x < player.cur_weapon.dx {
				r1.delta = player.cur_weapon.dx
			} else {
				r1.delta = pb.x - pb.prev_x
			}
			if eb.prev_x - eb.x < enemy.cur_weapon.dx {
				r2.delta = enemy.cur_weapon.dx
			} else {
				r2.delta = eb.prev_x - eb.x
			}
			r1.left = r1.right - r1.delta
			r2.right = r2.left + r2.delta
			if !(r1.left > r2.right || r2.left > r1.right || r1.top > r2.bottom || r2.top > r1.bottom) {
				if player.cur_weapon.type == .Nuke || player.cur_weapon.type == .Barrier {
					pb.hp = pb.hp - enemy.cur_weapon.power
					if pb.hp <= 0 {
						pb.status = .Exploding
						pb.exp_counter = 40
					}
				} else {
					if player.cur_weapon.type != .Knife {
						pb.status = .Exploding
						pb.exp_counter = 10
					}
				}
					
				if enemy.cur_weapon.type == .Nuke || enemy.cur_weapon.type == .Barrier {
					eb.hp = eb.hp - player.cur_weapon.power
					if eb.hp <= 0 {
						eb.status = .Exploding
						eb.exp_counter = 40
					}
				} else {
					if enemy.cur_weapon.type != .Knife {
						eb.status = .Exploding
						eb.exp_counter = 10
					}
				}
			}
		}
		 
		if enemy.status != .Exploding {
			r1.right = pb.x
			r1.top = pb.y
			r1.bottom = pb.y + player.cur_weapon.dy
			if pb.x - pb.prev_x < player.cur_weapon.dx {
				r1.delta = player.cur_weapon.dx
			} else {
				r1.delta = pb.x - pb.prev_x
			}
			r1.left = r1.right - r1.delta
			r2.left = enemy.x - enemy.dx
			r2.right = enemy.x
			r2.top = enemy.y
			r2.bottom = enemy.y + enemy.dy
		
			if !(r1.left > r2.right || r2.left > r1.right || r1.top > r2.bottom || r2.top > r1.bottom) {
				pb.status = .Exploding
				if player.cur_weapon.type == .Nuke {
					pb.exp_counter = 40
				} else {
					pb.exp_counter = 10
				}
				enemy.status = .Exploding
				enemy.exp_counter = 20
				enemy.hp = enemy.hp - player.cur_weapon.power
				if enemy.hp < 0 { enemy.hp = 0 }
			}
		}
	}
 
	for &eb in enemy_bullets {
		if eb.status == .Normal && player.status != .Exploding {
			r1.right = player.x
			r1.top = player.y
			r1.bottom = player.y + player.dy
			r1.left = player.x - player.dx
			
			r2.left = eb.x - enemy.cur_weapon.dx
			r2.top = eb.y
			r2.bottom = eb.y + enemy.cur_weapon.dy
			if eb.prev_x - eb.x < enemy.cur_weapon.dx {
				r2.delta = enemy.cur_weapon.dx
			} else {
				r2.delta = eb.prev_x - eb.x
			}
			r2.right = r2.left + r2.delta
			if !(r1.left > r2.right || r2.left > r1.right || r1.top > r2.bottom || r2.top > r1.bottom) {
				eb.status = .Exploding
				if enemy.cur_weapon.type == .Nuke {
					eb.exp_counter = 40
				} else {
					eb.exp_counter = 10
				}
				player.status = .Exploding
				player.exp_counter = 20
				player.hp = player.hp - enemy.cur_weapon.power
				if player.hp < 0 { player.hp = 0 }
			}
		}
	}
}

destruction :: proc() {
	winner_color := rl.RED
	winner_label := "Player"
	if player.hp > enemy.hp {
		if ship_death_radius < 300 {
			ship_death_radius = ship_death_radius + (SHIP_EXP_RATE * rl.GetFrameTime())
			qv.circle(enemy.x+enemy.dx/2, enemy.y+enemy.dy/2, ship_death_radius,   rl.BLUE)
			qv.circle(enemy.x+enemy.dx/2, enemy.y+enemy.dy/2, ship_death_radius-6, rl.BLACK)
		}
		for &b in enemy_bullets { b.status = .Dead }
		enemy_bullets_loaded = 0
	} else {
		if ship_death_radius < 300 {
			ship_death_radius = ship_death_radius + (SHIP_EXP_RATE * rl.GetFrameTime())
			qv.circle(player.x+player.dx/2, player.y+player.dy/2, ship_death_radius,   rl.RED)
			qv.circle(player.x+player.dx/2, player.y+player.dy/2, ship_death_radius-6, rl.BLACK)
		}
		for &b in player_bullets { b.status = .Dead }
		player_bullets_loaded = 0
		winner_color = rl.BLUE
		winner_label = "Computer"	
	}

	qv.print_centered(fmt.tprintf("%s Wins!", winner_label), 10, rl.BLUE)
	qv.print_centered("Hit [ENTER] to player again, [ESC] to exit", qv.get_text_rows() - 10, rl.WHITE)
}

display_stats :: proc() {
	qv.print(fmt.tprintf("HP: %i/%i", player.hp, player.hp_max), qv.Text_Point{2, 1}, rl.RED)
	qv.print(fmt.tprintf("[%s-%i]", player.cur_weapon.handle, player.cur_weapon.player_level), qv.Text_Point{21, 1}, rl.RED)
 
	qv.print(fmt.tprintf("[%s-%i]", enemy.cur_weapon.handle, enemy.cur_weapon.player_level), qv.Text_Point{75, 1}, rl.BLUE)
	qv.print(fmt.tprintf("HP: %i/%i", enemy.hp, enemy.hp_max), qv.Text_Point{95, 1}, rl.BLUE)
}

do_battle :: proc() {
	check_collisions()

	should_exit := player_control()
	if should_exit {
		return
	}
	enemy_control()

	qv.clear_screen(rl.BLACK)
	display_stats()
	player_graphics()
	enemy_graphics()

	player_bullets_update()
	enemy_bullets_update()
	
	if player.hp <= 0 || enemy.hp <= 0 {
		destruction()
	}
}

do_configure_ship :: proc() {
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

	qv.clear_screen(rl.BLACK)
	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)
	qv.type("A R S E N A L", qv.Text_Point{2, 2}, rl.DARKGREEN)
	qv.type("Terran craft",  qv.Text_Point{2, 4}, rl.RED)
	qv.type(fmt.tprintf("HP:    %i", player.hp),  qv.Text_Point{2, 5}, rl.GREEN)
	qv.type(fmt.tprintf("Speed: %v", player.spd), qv.Text_Point{2, 6}, rl.GREEN)
   
	qv.type("Kulari craft",  qv.Text_Point{40, 4}, rl.BLUE)
	qv.type(fmt.tprintf("HP:     %i", enemy.hp),  qv.Text_Point{40, 5}, rl.DARKGREEN)
	qv.type(fmt.tprintf("Speed:  %v", enemy.spd), qv.Text_Point{40, 6}, rl.DARKGREEN)
	qv.type("Weapon: ", qv.Text_Point{40, 7}, rl.DARKGREEN)
	qv.type(enemy.cur_weapon.handle, qv.Text_Point{48, 7}, enemy.cur_weapon.color)
 
	qv.type("Make a weapon selection ([ENTER] to confirm):", qv.Text_Point{2, 9}, rl.DARKGREEN)
	for wt in Weapon_Type {
		if chosen_weapon_type == wt {
			qv.print("- ", qv.Text_Point{2, 10+int(wt)}, weapons[wt].color)
		}
		qv.print(weapons[wt].handle, qv.Text_Point{4, 10+int(wt)}, weapons[wt].color)
	}

	if weapon_chosen && !ships_configured {
		enemy_bullets_loaded = 0
		enemy.direction = .Down if rand.float32() > 0.5 else .Up
		enemy.hp = enemy.hp_max
		enemy.x = f32(sw - 40)
		enemy.y = f32(sh / 2)
		enemy.status = .Normal
		load_weapons(.Enemy)
		enemy.cur_weapon = weapons[enemy.cur_weapon.type]
		load_weapons(.Enemy)

		player_bullets_loaded = 0
		player.hp = player.hp_max
		player.x = 30
		player.y = f32(sh / 2)
		player.status = .Normal
		player.cur_weapon = weapons[chosen_weapon_type]
		load_weapons(.Player)
		player.cur_weapon = weapons[chosen_weapon_type]

		ships_configured = true
	}

	if ships_configured {
		qv.type(player.cur_weapon.handle, qv.Text_Point{2, 24}, player.cur_weapon.color)
		qv.type(" selected. Hit [ENTER] to enage Kulari craft", qv.Text_Point{2+len(player.cur_weapon.handle), 24}, rl.WHITE)
		if (qv.ready_to_continue(wait_for_keypress = true)) {
			cur_screen = .Battle
			qv.reset_frame_memory()
		}
	}
}

do_intro :: proc() {
	qv.clear_screen(rl.BLACK)

	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)

	qv.type("Welcome to the Arsenal Network", qv.Text_Point{2, 2}, rl.GREEN)

	login := "mazer"
	qv.set_typing_speed(8)
	qv.print("Login: ", qv.Text_Point{2, 4}, rl.GREEN)
	qv.wait(1000)
	qv.type(login, qv.Text_Point{9, 4}, rl.SKYBLUE)
	qv.print("Password: ", qv.Text_Point{2, 5}, rl.GREEN)
	qv.wait(1200)
	qv.type("*********", qv.Text_Point{12, 5}, rl.SKYBLUE)

	qv.set_typing_speed(DEFAULT_TYPING_SPEED_CPS)

	qv.type("Verifying........", qv.Text_Point{2, 7}, rl.GREEN)
	qv.print("Access granted", qv.Text_Point{2, 8}, rl.GREEN)
	qv.wait(1000)

	msg := qv.concat("Welcome to the system [", login, "]")
	qv.type(msg, qv.Text_Point{2, 10}, rl.GREEN)
	qv.type("INCOMING MESSAGE FROM COMMAND - SET PRIORITY 1", qv.Text_Point{2, 11}, rl.GREEN)
	qv.wait(1000)
	msg = qv.concat("Agent ", login, ", Kurali craft have been detected in sector alpha!")
	qv.type(msg, qv.Text_Point{2, 13}, rl.RED)
	qv.type("Engage and destroy all enemy craft. Kurali have destroyed Terran headquarters", qv.Text_Point{2, 14}, rl.RED)
	qv.type("leaving you as our sole countermeasure. Act immediately, as there may not be", qv.Text_Point{2, 15}, rl.RED)
	qv.type("much mo^D", qv.Text_Point{2, 16}, rl.RED)
	qv.type("<EOF received from client>", qv.Text_Point{2, 17}, rl.YELLOW)

	qv.print("% ", qv.Text_Point{2, 19}, rl.GREEN)
	qv.wait(1500)
	qv.type("exec ./arsenal.sh", qv.Text_Point{4, 19}, rl.SKYBLUE)
	qv.type("Security clearance granted ", qv.Text_Point{2, 20}, rl.GREEN)
	qv.type("Are you sure you wish to launch Arsenal? [yn] ", qv.Text_Point{2, 21}, rl.GREEN)
	qv.wait(1500)
	qv.print("y", qv.Text_Point{48, 21}, rl.SKYBLUE)

	qv.type("[Ready! Press any key to launch]", qv.Text_Point{2, 24}, rl.WHITE)
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
	qv.set_drawing_speed(40)
	for !rl.WindowShouldClose() {
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
			do_configure_ship()
		case .Battle:
			do_battle()
		case .Victory:
			do_victory()
		}
	}
	qv.close()
}

do_title :: proc() {
	qv.clear_screen(rl.BLACK)
	for i in 1..=40 {
		phase := math.sin_f32(0.5*f32(i)+f32(rl.GetTime()*3))
		qv.sizeable_line(f32(i*sw/40), 1, f32(sw), f32(i*sh/40), rl.RED, phase+1.2)
		qv.sizeable_line(1, f32(i*sh/40), f32(i*sw/40), f32(sh), rl.RED, phase+1.2)
	}

	title := "r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
	qv.draw("bm280,350 c15 s12")
	qv.draw(title)

	author := "u15nu15r20d15nl20br5bu15 f15ng15e15bu15br20 nd30r20d30nl20bu10bl5f10 br5u30r20d10nl20bu10br5 r20g30"
	qv.draw("bm790,420 c9 s4")
	qv.draw(author)

	qv.print_centered("Press any key to start", qv.get_text_rows()-5, rl.GRAY)
	if (qv.ready_to_continue(wait_for_keypress = true)) {
		init()
		cur_screen = .Intro
		qv.reset_frame_memory()
	}
}

do_victory :: proc() {
	Upgrade_Choice :: enum {
		Not_Selected = 0,
		Level,
		HP,
		Speed,
	}
	@(static) current_upgrade: int = 1
	chosen_upgrade: Upgrade_Choice

	for pk := rl.GetKeyPressed(); pk != .KEY_NULL; pk=rl.GetKeyPressed() {
		#partial switch pk {
		case .UP:
			current_upgrade = current_upgrade-1 if current_upgrade > 1 else 3
		case .DOWN:
			current_upgrade = current_upgrade+1 if current_upgrade < 3 else 1
		case .ENTER:
			chosen_upgrade = Upgrade_Choice(current_upgrade)
		}
	}

	qv.clear_screen(rl.BLACK)
	qv.print("Select one of the following options:", qv.Text_Point{2, 2}, rl.DARKGREEN)
	qv.print(
		fmt.tprintf("Upgrade %s to level %i", player.cur_weapon.handle, player.cur_weapon.player_level+1),
		qv.Text_Point{4, 3},
		rl.DARKGREEN,
	)
	qv.print(
		fmt.tprintf("Upgrade hull HP to %i", player.hp_max+20),
		qv.Text_Point{4, 4},
		rl.DARKGREEN,
	)
	qv.print(
		fmt.tprintf("Upgrade speed to %v", player.spd+20),
		qv.Text_Point{4, 5},
		rl.DARKGREEN,
	)
	qv.print("-", qv.Text_Point{2, 2+current_upgrade}, rl.DARKGREEN)
 
	if chosen_upgrade != .Not_Selected {
		#partial switch chosen_upgrade {
		case .Level:
			player.cur_weapon.player_level = player.cur_weapon.player_level+1
		case .HP:
			player.hp_max = player.hp_max+20
		case .Speed:
			player.spd = player.spd+20
		}
		enemy.hp_max = enemy.hp_max+10
		enemy.spd = enemy.spd+5
		enemy.cur_weapon.enemy_level = enemy.cur_weapon.enemy_level+2

		enemy.hp  = enemy.hp_max
		player.hp = player.hp_max
		load_weapons(.Enemy)
		load_weapons(.Player)
		for &b in enemy_bullets  { b.status = .Dead }
		for &b in player_bullets { b.status = .Dead }
		enemy_bullets_loaded  = 0
		player_bullets_loaded = 0

		cur_screen = .Battle
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
					if b.direction == .Down { b.y = b.y+enemy.cur_weapon.vert_spd*rl.GetFrameTime() }
					if b.direction == .Up   { b.y = b.y-enemy.cur_weapon.vert_spd*rl.GetFrameTime() }
				case .Wave:
					b.y = f32(b.yi) - 40*math.sin_f32((b.x-f32(b.xi)) / 60)
				case .Splitter:
					if b.x < x_left_threshold {
						if b.direction == .Down { b.y = b.y+enemy.cur_weapon.vert_spd*rl.GetFrameTime() }
						if b.direction == .Up   { b.y = b.y-enemy.cur_weapon.vert_spd*rl.GetFrameTime() }
					}
				}
				qv.rectangle(b.x, b.y, b.x+enemy.cur_weapon.dx, b.y+enemy.cur_weapon.dy, enemy.cur_weapon.color)
			}
		case .Exploding:
			b.exp_counter = b.exp_counter-1
			if b.exp_counter > 0 {
				b.x = b.x+b.spd*rl.GetFrameTime()
				qv.circle(b.x+enemy.cur_weapon.dx/2, b.y+enemy.cur_weapon.dy/2, f32(b.exp_counter*3), enemy.cur_weapon.color)
			} else {
				b.status = .Dead
				enemy_bullets_loaded = enemy_bullets_loaded-1
			}
		}
	}

}

enemy_control :: proc() {
	if enemy.hp <= 0 {
		return
	}

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
						b.x = enemy.x - enemy.dx
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
						b.x = enemy.x - enemy.dx
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

	if enemy.hp > 0 {
		qv.rectangle(enemy.x, enemy.y, enemy.x+enemy.dx, enemy.y+enemy.dy, rl.BLUE)
	}
   
	if enemy.status == .Exploding {
		enemy.exp_counter = enemy.exp_counter - 1
		if enemy.exp_counter <= 0 {
			enemy.status = .Normal
		}
		qv.circle(enemy.x+enemy.dx/2, enemy.y+enemy.dy/2, f32(enemy.exp_counter * 5), rl.BLUE)
	}
}

init :: proc() {
	ships_configured = false
	weapon_chosen = false
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
	enemy.cur_weapon = weapons[rand.choice_enum(Weapon_Type)]
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
		homer.vert_spd = 20+f32(player.cur_weapon.player_level*8)
	} else {
		if enemy.cur_weapon.type == .Homer {
			homer.enemy_level = enemy.cur_weapon.enemy_level
		}
		homer.power = enemy.cur_weapon.enemy_level + 2
		homer.accel = f32(enemy.cur_weapon.enemy_level) * ACCEL_FACTOR
		homer.vert_spd = 20+f32(enemy.cur_weapon.enemy_level*8)
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
		knife.accel = f32(player.cur_weapon.player_level) * ACCEL_FACTOR
		knife.max_bullets_loaded = player.cur_weapon.player_level + 3
	} else {
		if enemy.cur_weapon.type == .Knife {
			knife.enemy_level = enemy.cur_weapon.enemy_level
		}
		knife.power = enemy.cur_weapon.enemy_level + 1
		knife.accel = f32(enemy.cur_weapon.enemy_level) * ACCEL_FACTOR
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
			barrier.hp_max = 40 + (enemy.cur_weapon.enemy_level * 2)
			barrier.max_bullets_loaded = enemy.cur_weapon.enemy_level / 5 + 4
			barrier.power = enemy.cur_weapon.enemy_level + 2
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
					if b.direction == .Down { b.y = b.y + player.cur_weapon.vert_spd*rl.GetFrameTime() }
					if b.direction == .Up   { b.y = b.y - player.cur_weapon.vert_spd*rl.GetFrameTime() }
				case .Wave:
					b.y = f32(b.yi) - 40*math.sin_f32((b.x-f32(b.xi)) / 60)
				case .Splitter:
					if b.x > x_right_threshold {
						if b.direction == .Down { b.y = b.y + player.cur_weapon.vert_spd*rl.GetFrameTime() }
						if b.direction == .Up   { b.y = b.y - player.cur_weapon.vert_spd*rl.GetFrameTime() }
					}
				}
				qv.rectangle(b.x, b.y, b.x+player.cur_weapon.dx, b.y+player.cur_weapon.dy, player.cur_weapon.color)
			}
		case .Exploding:
			b.exp_counter = b.exp_counter-1
			if b.exp_counter > 0 {
				b.x = b.x-b.spd*rl.GetFrameTime()
				qv.circle(b.x+player.cur_weapon.dx/2, b.y+player.cur_weapon.dy/2, f32(b.exp_counter*3), player.cur_weapon.color)
			} else {
				b.status = .Dead
				player_bullets_loaded = player_bullets_loaded-1
			}
		}
	}
}

player_control :: proc() -> bool {
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
		case .ENTER:
			if player.hp <= 0 || enemy.hp <= 0 {
				ship_death_radius = 0
				qv.reset_frame_memory()

				if player.hp > 0 {
					cur_screen = .Victory
				} else {
					init()
					cur_screen = .Configure_Ship
				}
				return true
			}
		case .F:
			if player.cur_weapon.type == .Chain_Gun || enemy.hp <= 0 {
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
							b.x = player.x + player.dx
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
							b.x = player.x + player.dx
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
								if b.status == .Dead {
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

	if chaingun_cooldown <= 0 && player.cur_weapon.type == .Chain_Gun && player.hp > 0 {
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
	return false
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

	if player.hp > 0 {
		qv.rectangle(player.x, player.y, player.x+player.dx, player.y+player.dy, rl.RED)
	}
   
	if player.status == .Exploding {
		player.exp_counter = player.exp_counter - 1
		if player.exp_counter <= 0 {
			player.status = .Normal
		}
		qv.circle(player.x+player.dx/2, player.y+player.dy/2, f32(player.exp_counter * 5), rl.RED)
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

    do_loop()
}