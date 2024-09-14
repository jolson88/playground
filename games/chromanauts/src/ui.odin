package chromanauts

import rl "vendor:raylib"

Control_Result :: enum u32 {
    Active, Active_In, Active_Out,
	Hover, Hover_In, Hover_Out,
    Click,
    Dragging, Drag_Start, Drag_End, Drag_Over,
}
Control_Result_Set :: distinct bit_set[Control_Result; u32]

Gui_Id :: distinct u64

Gui_State :: struct {
    active_id, last_active_id: Gui_Id,
    drag_id,   last_drag_id:   Gui_Id,
    hover_id,  last_hover_id:  Gui_Id,
    updated_active, updated_drag, updated_hover: bool,

    current_time: f64,
    delta_time: f64,

    mouse_pos, last_mouse_pos: rl.Vector2,
    mouse_down, mouse_pressed, mouse_released: bool,
}

gui_end :: proc(gui: ^Gui_State) {
	gui.last_active_id = gui.active_id
	gui.last_hover_id  = gui.hover_id

	if !gui.updated_active {
		gui.active_id = 0
	}
	gui.updated_active = false

	if !gui.updated_drag {
		gui.drag_id = 0
	}
	gui.updated_drag = false

	if !gui.updated_hover {
		gui.hover_id = 0
	}
	gui.updated_hover = false

	gui.last_mouse_pos = gui.mouse_pos
}

gui_start :: proc(gui: ^Gui_State) {
    prev_time := gui.current_time
    gui.current_time = rl.GetTime()
    gui.delta_time   = gui.current_time - prev_time

    gui.mouse_down     = false
    gui.mouse_pressed  = false
    gui.mouse_released = false
    gui.mouse_pos      = rl.GetMousePosition()

    if rl.IsMouseButtonDown(.LEFT)     { gui.mouse_down     = true }
    if rl.IsMouseButtonPressed(.LEFT)  { gui.mouse_pressed  = true }
    if rl.IsMouseButtonReleased(.LEFT) { gui.mouse_released = true }

    switch {
    case gui.active_id != 0: rl.SetMouseCursor(.CROSSHAIR)
    case gui.hover_id  != 0: rl.SetMouseCursor(.POINTING_HAND)
    case:                    rl.SetMouseCursor(.DEFAULT)
    }
}

set_active :: proc(gui: ^Gui_State, id: Gui_Id) {
    gui.active_id = id
    gui.updated_active = true
}

set_drag :: proc(gui: ^Gui_State, id: Gui_Id) {
    gui.drag_id = id
    gui.updated_active = true
    gui.updated_drag   = true
}

set_hover :: proc(gui: ^Gui_State, id: Gui_Id) {
    gui.hover_id = id
    gui.updated_hover = true
}

update_control :: proc(gui: ^Gui_State, id: Gui_Id, rect: rl.Rectangle) -> (res: Control_Result_Set) {
    hovering := rl.CheckCollisionPointRec(gui.mouse_pos, rect)

    if hovering && gui.hover_id != id {
        if gui.active_id != 0 && gui.active_id != id {
            res += {.Drag_Over}
        } else {
            if gui.hover_id == 0 {
                set_hover(gui, id)
                res += {.Hover_In}
            }
        }
    }

    // we're being hovered over
    if gui.hover_id == id {
        gui.updated_hover = true
        if !hovering {
            set_hover(gui, 0)
            res += {.Hover_Out}
        }
        if gui.mouse_pressed && gui.active_id != id {
            set_active(gui, id)
            res += {.Active_In, .Click}
        }
    }

    // we're active
    if gui.active_id == id {
        gui.updated_active = true
        if (gui.mouse_pressed && !hovering) || !gui.mouse_down {
            set_active(gui, 0)
        } else {
            if gui.mouse_down && gui.drag_id == id {
                gui.updated_drag   = true
                res += {.Dragging}
            }
            if gui.mouse_down && gui.drag_id != id && !gui.mouse_pressed {
                // we ignore mouse_pressed because initial mouse_press should register a
                // .Click res and .Drag_Start should start on following frame
                set_drag(gui, id)
                res += {.Drag_Start}
            }
        }
    }

    // we used to be active, but aren't anymore
    if gui.last_active_id == id && gui.active_id != id {
        res += {.Active_Out}
    }

    // Are we still active or hovering?
    if gui.hover_id  == id { res += {.Hover}  }
    if gui.active_id == id { res += {.Active} }

    return
}
