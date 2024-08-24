package qv

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

cyan := rl.ColorFromHSV(182, 0.73, 1.0)
default_one_bit_palette   := [2]rl.Color{rl.BLACK, rl.WHITE}
default_two_bit_palette   := [4]rl.Color{rl.BLACK, cyan, rl.MAGENTA, rl.GRAY}
default_four_bit_palette  := [16]rl.Color{rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE}
default_eight_bit_palette := [256]rl.Color{
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorBrightness(rl.RED, -0.5), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
}

Qv_State :: struct {
    screen_width, screen_height: int,
    screen_mode: Screen_Mode,

    palette_mode: Palette_Mode,
    one_bit_palette:   [2]rl.Color,
    two_bit_palette:   [4]rl.Color,
    four_bit_palette:  [16]rl.Color,
    eight_bit_palette: [256]rl.Color,
}

Pen_State :: struct {
    pos:    rl.Vector2,
    col:    int,
    scale:  f32
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

Default_Color :: enum {
    BLACK = 0,
    DARK_BLUE = 1,
    DARK_GREEN,
    DARK_CYAN,
    DARK_RED,
    DARK_MAGENTA,
    BROWN,
    DARK_WHITE,
    GRAY,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    YELLOW,
    WHITE,
}

Palette_Entry :: enum {
    P00 = 0, P01 = 1, P02, P03, P04, P05, P06, P07, P08, P09, P0A, P0B, P0C, P0D, P0E, P0F,
    P10, P11, P12, P13, P14, P15, P16, P17, P18, P19, P1A, P1B, P1C, P1D, P1E, P1F,
    P20, P21, P22, P23, P24, P25, P26, P27, P28, P29, P2A, P2B, P2C, P2D, P2E, P2F,
    P30, P31, P32, P33, P34, P35, P36, P37, P38, P39, P3A, P3B, P3C, P3D, P3E, P3F,
    P40, P41, P42, P43, P44, P45, P46, P47, P48, P49, P4A, P4B, P4C, P4D, P4E, P4F,
    P50, P51, P52, P53, P54, P55, P56, P57, P58, P59, P5A, P5B, P5C, P5D, P5E, P5F,
    P60, P61, P62, P63, P64, P65, P66, P67, P68, P69, P6A, P6B, P6C, P6D, P6E, P6F,
    P70, P71, P72, P73, P74, P75, P76, P77, P78, P79, P7A, P7B, P7C, P7D, P7E, P7F,
    P80, P81, P82, P83, P84, P85, P86, P87, P88, P89, P8A, P8B, P8C, P8D, P8E, P8F,
    P90, P91, P92, P93, P94, P95, P96, P97, P98, P99, P9A, P9B, P9C, P9D, P9E, P9F,
    PA0, PA1, PA2, PA3, PA4, PA5, PA6, PA7, PA8, PA9, PAA, PAB, PAC, PAD, PAE, PAF,
    PB0, PB1, PB2, PB3, PB4, PB5, PB6, PB7, PB8, PB9, PBA, PBB, PBC, PBD, PBE, PBF,
    PC0, PC1, PC2, PC3, PC4, PC5, PC6, PC7, PC8, PC9, PCA, PCB, PCC, PCD, PCE, PCF,
    PD0, PD1, PD2, PD3, PD4, PD5, PD6, PD7, PD8, PD9, PDA, PDB, PDC, PDD, PDE, PDF,
    PE0, PE1, PE2, PE3, PE4, PE5, PE6, PE7, PE8, PE9, PEA, PEB, PEC, PED, PEE, PEF,
    PF0, PF1, PF2, PF3, PF4, PF5, PF6, PF7, PF8, PF9, PFA, PFB, PFC, PFD, PFE, PFF,
}

Palette_Color :: union {
    Default_Color,
    Palette_Entry
}

Point :: struct {
    x, y: int
}

// variables
state: Qv_State
pen_state: Pen_State

// procedures
clear :: proc(color: Palette_Color) {
    rl.ClearBackground(get_color(color))
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

    state.one_bit_palette   = default_one_bit_palette
    state.two_bit_palette   = default_two_bit_palette
    state.four_bit_palette  = default_four_bit_palette
    state.eight_bit_palette = default_eight_bit_palette
    set_palette_mode(palette_mode)
}

elapsed_time :: proc() -> f64 {
    return rl.GetTime()
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
}

get_color :: proc(color: Palette_Color) -> rl.Color {
    color_index: int
    switch c in color {
    case Default_Color:
        color_index = int(c)
    case Palette_Entry:
        color_index = int(c)
    }
    return get_color_from_int(color_index)
    
}

get_color_from_int :: proc(palette_entry: int) -> rl.Color {
    switch state.palette_mode {
    case .ONE_BIT:
        return state.one_bit_palette[palette_entry]
    case .TWO_BIT:
        return state.two_bit_palette[palette_entry]
    case .FOUR_BIT:
        return state.four_bit_palette[palette_entry]
    case .EIGHT_BIT:
        return state.eight_bit_palette[palette_entry]
    }

    return rl.BLACK
}

line :: proc(start: Point, end: Point, color: Palette_Color) {
    sizeable_line(start, end, color, 1)
}

sizeable_line :: proc(start: Point, end: Point, color: Palette_Color, thickness: f32) {
    real_color := get_color(color)
    line_impl(rl.Vector2{f32(start.x), f32(start.y)}, rl.Vector2{f32(end.x), f32(end.y)}, thickness, real_color)
}

@(private)
line_impl :: proc(start: rl.Vector2, end: rl.Vector2, thickness: f32, color: rl.Color) {
    rl.DrawLineEx(start, end, thickness, color)
}

draw :: proc(src: string) {
    cmds, idx, err := parse_draw_commands(src, context.temp_allocator)
    if err != .None {
        fmt.eprintf("Invalid draw command (%v): %s. Failed at %i", err, src, idx)
        return
    }

    for cmd in cmds {
        switch cmd.type {
        case .One_Dimension:
            begin_pos := pen_state.pos
            dest_pos  := begin_pos
            switch cmd.direction {
            case .Up:        dest_pos.y=dest_pos.y-(f32(cmd.param_1)*pen_state.scale)
            case .UpRight:   dest_pos.y=dest_pos.y-(f32(cmd.param_1)*pen_state.scale); dest_pos.x=dest_pos.x+(f32(cmd.param_1)*pen_state.scale)
            case .Right:     dest_pos.x=dest_pos.x+(f32(cmd.param_1)*pen_state.scale)
            case .DownRight: dest_pos.x=dest_pos.x+(f32(cmd.param_1)*pen_state.scale); dest_pos.y=dest_pos.y+(f32(cmd.param_1)*pen_state.scale)
            case .Down:      dest_pos.y=dest_pos.y+(f32(cmd.param_1)*pen_state.scale)
            case .DownLeft:  dest_pos.y=dest_pos.y+(f32(cmd.param_1)*pen_state.scale); dest_pos.x=dest_pos.x-(f32(cmd.param_1)*pen_state.scale)
            case .Left:      dest_pos.x=dest_pos.x-(f32(cmd.param_1)*pen_state.scale)
            case .UpLeft:    dest_pos.x=dest_pos.x-(f32(cmd.param_1)*pen_state.scale); dest_pos.y=dest_pos.y-(f32(cmd.param_1)*pen_state.scale)
            case .Unknown:   // Do Nothing
            }
            if !cmd.pen_up {
                col := get_color_from_int(pen_state.col)
                line_impl(begin_pos, dest_pos, pen_state.scale, col)
            }
            if !cmd.return_to_pos {
                pen_state.pos = dest_pos
            }
        case .Two_Dimensions:
            begin_pos := rl.Vector2{}
            dest_pos  := rl.Vector2{f32(cmd.param_1), f32(cmd.param_2)}
            if !cmd.pen_up {
                col := get_color_from_int(pen_state.col)
                line_impl(begin_pos, dest_pos, pen_state.scale, col)
            }
            if !cmd.return_to_pos {
                pen_state.pos = dest_pos
            }
        case .Color:
            pen_state.col = cmd.param_1
        case .Scale:
            // Similar to QBasic 1.1, a scale of 4 means 1 pixel
            pen_state.scale = f32(cmd.param_1) / 4
        case .Unknown:
            // Do nothing
        }
    }
}