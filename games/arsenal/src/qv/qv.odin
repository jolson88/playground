package qv

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Qv_State :: struct {
    screen_width, screen_height: int,
    screen_mode: Screen_Mode,

    palette_mode: Palette_Mode,
    palette: [256]rl.Color,
}

// screen
Screen_Mode :: enum {
    TEN_EIGHTY_P = 0,
    SEVEN_TWENTY_P = 1,
}

// colors
Palette_Mode :: enum {
    FOUR_BIT = 0,
    ONE_BIT = 1,
    TWO_BIT,
    EIGHT_BIT,
}

Palette_Color :: enum {
    BLACK,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    WHITE,
    GRAY,
    LIGHT_BLUE,
    LIGHT_GREEN,
    LIGHT_CYAN,
    LIGHT_RED,
    LIGHT_MAGENTA,
    YELLOW,
    BRIGHT_WHITE,
}

Point :: struct {
    x, y: int
}

// variables
state: Qv_State

// procedures
clear :: proc(color: Palette_Color) {
    rl.ClearBackground(state.palette[color])
}

create_window :: proc(title: string, screen_mode: Screen_Mode, palette_mode: Palette_Mode) {
    if (screen_mode == .TEN_EIGHTY_P) {
        state.screen_width  = 1920
        state.screen_height = 1080
    } else if (screen_mode == .SEVEN_TWENTY_P) {
        state.screen_width  = 1280
        state.screen_height = 720
    }
    rl.InitWindow(i32(state.screen_width), i32(state.screen_height), strings.clone_to_cstring(title, context.temp_allocator))
    rl.SetTargetFPS(60)
    set_palette_mode(palette_mode)
}

screen_width :: proc() -> int {
    return state.screen_width
}

screen_height :: proc() -> int {
    return state.screen_height
}

should_close :: proc() -> bool {
    return rl.WindowShouldClose()
}

begin :: proc() {
    rl.BeginDrawing()
}

present :: proc() {
    rl.EndDrawing()
}

set_palette_mode :: proc(mode: Palette_Mode) {
    state.palette_mode = mode

    cyan := rl.ColorFromHSV(182, 0.73, 1.0)
    switch mode {
        case .ONE_BIT:
            state.palette[0] = rl.BLACK
            state.palette[1] = rl.WHITE
        case .TWO_BIT:
            state.palette[0] = rl.BLACK
            state.palette[1] = cyan
            state.palette[2] = rl.MAGENTA
            state.palette[3] = rl.GRAY
        case .FOUR_BIT:
            state.palette[0]  = rl.BLACK
            state.palette[1]  = rl.ColorBrightness(rl.BLUE,    -0.5)
            state.palette[2]  = rl.ColorBrightness(rl.GREEN,   -0.5)
            state.palette[3]  = rl.ColorBrightness(cyan,       -0.5)
            state.palette[4]  = rl.ColorBrightness(rl.RED,     -0.5)
            state.palette[5]  = rl.ColorBrightness(rl.MAGENTA, -0.5)
            state.palette[6]  = rl.ColorBrightness(rl.YELLOW,  -0.5)
            state.palette[7]  = rl.LIGHTGRAY
            state.palette[8]  = rl.GRAY
            state.palette[9]  = rl.BLUE
            state.palette[10] = rl.GREEN
            state.palette[11] = cyan
            state.palette[12] = rl.RED
            state.palette[13] = rl.MAGENTA
            state.palette[14] = rl.YELLOW
            state.palette[15] = rl.WHITE
        case .EIGHT_BIT:
            fmt.eprintln("8-bit palette mode not supported yet")
    }
}

line :: proc(start: Point, end: Point, color: Palette_Color) {
    real_color := state.palette[color]
    rl.DrawLineEx(rl.Vector2{f32(start.x), f32(start.y)}, rl.Vector2{f32(end.x), f32(end.y)}, 1, real_color)
}