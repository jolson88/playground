package qv

import "core:testing"
import rl "vendor:raylib"

@(test)
start_hovering_tests :: proc(t: ^testing.T) {
    using testing

    id := Gui_Id(1)
    gui := Gui_State{
        mouse_pos = rl.Vector2{5, 5},
    }

    res := update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})

    expect_value(t, res, Control_Result_Set{.Hover, .Hover_In})
    expect_value(t, gui.hover_id, id)
    expect_value(t, gui.updated_hover, true)
}

@(test)
become_active_tests :: proc(t: ^testing.T) {
    using testing

    // hovering and mouse just pressed
    id := Gui_Id(1)
    gui := Gui_State{
        hover_id  = id,
        mouse_pos = rl.Vector2{5, 5},
        mouse_pressed = true,
        mouse_down = true,
    }
    res := update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Active, .Active_In, .Click, .Hover})
    expect_value(t, gui.active_id, id)
    expect_value(t, gui.updated_active, true)
    expect_value(t, gui.updated_hover, true)
}

@(test)
become_inactive_tests :: proc(t: ^testing.T) {
    using testing

    // active, but mouse no longer down
    id := Gui_Id(1)
    gui := Gui_State{
        active_id = id,
        hover_id  = id,
        last_active_id = id,
        last_hover_id  = id,
        mouse_pos = rl.Vector2{5, 5},
    }
    res := update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Active_Out, .Hover})
    expect_value(t, gui.active_id, 0)
    expect_value(t, gui.updated_active, true)

    // active, mouse was pressed, but not hovering (mouse pressed outside of us)
    id = Gui_Id(1)
    gui = Gui_State{
        active_id = id,
        last_active_id = id,
        last_hover_id  = id,
        mouse_pos = rl.Vector2{12, 12},
    }
    res = update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Active_Out})
    expect_value(t, gui.active_id, 0)
    expect_value(t, gui.updated_active, true)
}

@(test)
dragging_tests :: proc(t: ^testing.T) {
    using testing

    // mouse pressed while hovering
    id := Gui_Id(1)
    gui := Gui_State{
        active_id = id,
        hover_id  = id,
        last_active_id = id,
        last_hover_id  = id,
        mouse_pos = rl.Vector2{5, 5},
        mouse_down = true,
        mouse_pressed = true,
    }
    res := update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Active, .Click, .Hover, .Dragging})
    expect_value(t, gui.active_id, id)
    expect_value(t, gui.hover_id, id)
    expect_value(t, gui.updated_active, true)
    expect_value(t, gui.updated_hover, true)

    // mouse down while still hovering
    id = Gui_Id(1)
    gui = Gui_State{
        active_id = id,
        hover_id  = id,
        last_active_id = id,
        last_hover_id  = id,
        mouse_pos = rl.Vector2{5, 5},
        mouse_down = true,
    }
    res = update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Active, .Hover, .Dragging})
    expect_value(t, gui.active_id, id)
    expect_value(t, gui.hover_id, id)
    expect_value(t, gui.updated_active, true)
    expect_value(t, gui.updated_hover, true)
}

@(test)
stop_hovering_tests :: proc(t: ^testing.T) {
    using testing

    // hovering and mouse just pressed
    id := Gui_Id(1)
    gui := Gui_State{
        hover_id  = id,
        mouse_pos = rl.Vector2{12, 12},
    }
    res := update_control(&gui, id, rl.Rectangle{0, 0, 10, 10})
    expect_value(t, res, Control_Result_Set{.Hover_Out})
    expect_value(t, gui.active_id, 0)
    expect_value(t, gui.updated_hover, true)
}
