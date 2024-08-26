package qv

import "core:fmt"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

// structures
Default_Color :: enum {
    Black        = 0,
    Dark_Blue    = 1,
    Dark_Green   = 2,
    Dark_Cyan    = 3,
    Brown        = 4,
    Dark_Magenta = 5,
    Dark_Yellow  = 6,
    Dark_White   = 7,
    Gray         = 8,
    Blue         = 9,
    Green        = 10,
    Cyan         = 11,
    Red          = 12,
    Magenta      = 13,
    Yellow       = 14,
    White        = 15,
}

Palette_Color :: union {
    Default_Color,
    Palette_Entry
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

Point :: struct {
    x, y: f32
}

Screen_Mode :: enum {
    Ten_Eighty_P = 0,
    Seven_Twenty_P = 1,
}

Text_Point :: struct {
    col: int,
    row: int,
}

@(private)
Pen_State :: struct {
    pos:    rl.Vector2,
    col:    int,
    scale:  f32
}

@(private)
Qv_State :: struct {
    // screen
    screen_width, screen_height: int,
    screen_mode: Screen_Mode,
    frame_dur: f32,

    // colors
    palette: [256]rl.Color,

    // text
    text_font: rl.Font,
    text_char_width: int,
    text_char_spacing: int,
    text_line_height: int,
    text_line_spacing: int,
    text_rows: int,
    text_cols: int,
    
    // timing
    completed_timers: map[string]bool,

    // typing
    typing_has_started_on_frame: bool,
    is_typing: bool,
    typing_cps: int,
    typing_entries: map[string]Typing_Entry,
    typing_text: string,
}

@(private)
Typing_Entry :: struct {
    is_done: bool,
    start: f64,
    text: string,
}

// variables
@(private) cyan := rl.ColorFromHSV(182, 0.73, 1.0)
@(private) default_palette := [256]rl.Color{
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
    rl.BLACK, rl.ColorBrightness(rl.BLUE, -0.5), rl.ColorBrightness(rl.GREEN, -0.5), rl.ColorBrightness(cyan, -0.5), rl.ColorFromHSV(28, 0.77, 0.65), rl.ColorBrightness(rl.MAGENTA, -0.5), rl.ColorBrightness(rl.YELLOW, -0.5), rl.LIGHTGRAY, rl.GRAY, rl.BLUE, rl.GREEN, cyan, rl.RED, rl.MAGENTA, rl.YELLOW, rl.WHITE,
}
@(private) state: Qv_State
@(private) pen_state: Pen_State

// procedures
begin :: proc() {
    state.typing_has_started_on_frame = false
    rl.BeginDrawing()
}

//qv.circle(qv.Point{player.x+player.dx/2, player.y+player.dy/2}, player.exp_counter * 8, .Red)

circle :: proc(center: Point, radius: f32, color: Palette_Color) {
    real_color := get_color(color)

    rl.DrawCircle(i32(center.x), i32(center.y), radius, real_color)
}

clear_screen :: proc(color: Palette_Color) {
    rl.ClearBackground(get_color(color))
}

close :: proc() {
    delete(state.typing_entries)
    delete(state.completed_timers)
    rl.CloseWindow()
}

concat :: proc(args: ..string) -> string {
    return strings.concatenate(args, context.temp_allocator)
}

create_window :: proc(title: string, screen_mode: Screen_Mode) {
    if (screen_mode == .Ten_Eighty_P) {
        state.screen_width  = 1920
        state.screen_height = 1080
    } else if (screen_mode == .Seven_Twenty_P) {
        state.screen_width  = 1280
        state.screen_height = 720
    }
    rl.InitWindow(i32(state.screen_width), i32(state.screen_height), strings.clone_to_cstring(title, context.temp_allocator))
    rl.SetTargetFPS(60)
    state.frame_dur = 60 / 1000
    state.palette = default_palette
}

draw :: proc(src: string) {
    if should_return() {
        return
    }
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

get_elapsed_time :: proc() -> f32 {
    return f32(rl.GetTime())
}

get_screen_width :: proc() -> int {
    return state.screen_width
}

get_screen_height :: proc() -> int {
    return state.screen_height
}

get_text_char_width :: proc() -> int {
    return state.text_char_width
}

get_text_columns :: proc() -> int {
    return state.text_cols
}

get_text_line_height :: proc() -> int {
    return state.text_line_height
}

get_text_rows :: proc() -> int {
    return state.text_rows
}

line :: proc(start: Point, end: Point, color: Palette_Color) {
    if should_return() {
        return
    }

    sizeable_line(start, end, color, 1)
}

present :: proc() {
    rl.EndDrawing()
}

print :: proc(text: string, pos: Text_Point, color: Palette_Color) {
    if should_return() {
        return
    }

    rl.DrawTextEx(state.text_font,
        strings.clone_to_cstring(text, context.temp_allocator),
        get_vector_from_text_point(pos),
        f32(state.text_font.baseSize),
        f32(state.text_char_spacing),
        get_color(color)
    )
}

print_centered :: proc(text: string, row: int, color: Palette_Color) {
	print(text, Text_Point{(get_text_columns()-len(text)) / 2, row}, color)
}

ready_to_continue :: proc(wait_for_keypress: bool) -> bool {
    if !wait_for_keypress || rl.WindowShouldClose() {
        return true
    }
    if state.is_typing {
        return false
    }

    should_continue := rl.GetKeyPressed() != .KEY_NULL;
    for rl.GetKeyPressed() != .KEY_NULL {} // Clear remaining key presses for a fresh start
    return should_continue
}

rectangle :: proc(top_left: Point, bottom_right: Point, color: Palette_Color) {
    real_color := get_color(color)

    rl.DrawRectangle(
        i32(top_left.x), i32(top_left.y),
        i32(bottom_right.x - top_left.x), i32(bottom_right.y - top_left.y),
        real_color
    )
}

reset_frame_memory :: proc() {
    clear(&state.completed_timers)
    clear(&state.typing_entries)
}

set_text_style :: proc(size: int, char_spacing: int, line_spacing: int) {
    // MEM: Cache previously loaded fonts so continued use doesn't result in resource exhaustion
    src_dir := filepath.dir(#file, context.temp_allocator)
    font_path := filepath.join([]string{src_dir, "resources", "DroidSansMono.ttf"}, context.temp_allocator)
    state.text_font = rl.LoadFontEx(strings.clone_to_cstring(font_path, context.temp_allocator), i32(size), nil, 0)

    char_count, line_count: int
    cur_x, cur_y: int
    measured_string := rl.MeasureTextEx(state.text_font, "T", f32(size), 0)
    state.text_char_width   = int(measured_string.x)+char_spacing
    state.text_line_height  = int(measured_string.y)+line_spacing
    state.text_char_spacing = char_spacing
    state.text_line_spacing = line_spacing
    for cur_x < state.screen_width {
        char_count = char_count+1
        cur_x = cur_x+state.text_char_width
    }
    for cur_y < state.screen_height {
        line_count = line_count+1
        cur_y = cur_y+state.text_line_height
    }
    state.text_rows = line_count
    state.text_cols = char_count
}

set_typing_speed :: proc(cps: int) {
    state.typing_cps = cps
}

should_close :: proc() -> bool {
    return rl.WindowShouldClose()
}

sizeable_line :: proc(start: Point, end: Point, color: Palette_Color, thickness: f32) {
    real_color := get_color(color)
    line_impl(rl.Vector2{f32(start.x), f32(start.y)}, rl.Vector2{f32(end.x), f32(end.y)}, thickness, real_color)
}

type :: proc(text: string, pos: Text_Point, color: Palette_Color) {
    text_started := text in state.typing_entries
    if (state.is_typing && state.typing_text != text) {
        text_already_finished := state.typing_entries[text].is_done
        if !text_already_finished {
            return
        }
    }

    if !text_started {
        state.is_typing = true
        state.typing_text = text
        state.typing_entries[text] = Typing_Entry{
            start=rl.GetTime(),
            text=text,
        }
    }
    entry := state.typing_entries[text]
    if entry.is_done {
        print(text, pos, color)
        return
    }

    elapsed_secs := rl.GetTime() - entry.start
    typed_chars  := int(f32(state.typing_cps) * f32(elapsed_secs))
    if (typed_chars >= len(text)) {
        typed_chars = len(text)
        entry.is_done = true
        state.typing_entries[text] = entry
        state.is_typing = false
        state.typing_text = ""
    }
    state.typing_has_started_on_frame = true
    rl.DrawTextEx(state.text_font,
        strings.clone_to_cstring(text[:typed_chars], context.temp_allocator),
        get_vector_from_text_point(pos),
        f32(state.text_font.baseSize),
        f32(state.text_char_spacing),
        get_color(color),
    )
}

wait :: proc(ms: int, loc := #caller_location) {
    if should_return() {
        return
    }
    key := strings.concatenate({loc.file_path, loc.procedure, fmt.tprintf("%i", loc.column), fmt.tprintf("%i", loc.line)}, context.temp_allocator)
    if key in state.completed_timers {
        return
    }

    rl.EndDrawing()
    rl.WaitTime(f64(ms / 1000))
    state.completed_timers[key] = true
    rl.BeginDrawing()
}

@(private)
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

@(private)
get_color_from_int :: proc(palette_entry: int) -> rl.Color {
    return state.palette[palette_entry]
}

@(private)
get_vector_from_text_point :: proc(pos: Text_Point) -> rl.Vector2 {
    x := (pos.col-1)*state.text_char_width
    y := (pos.row-1)*state.text_line_height
    return rl.Vector2{f32(x+state.text_char_spacing), f32(y)}
}

@(private)
line_impl :: proc(start: rl.Vector2, end: rl.Vector2, thickness: f32, color: rl.Color) {
    rl.DrawLineEx(start, end, thickness, color)
}

@(private)
should_return :: proc() -> bool {
    typing_in_progress := state.typing_has_started_on_frame && state.is_typing
    return rl.WindowShouldClose() || typing_in_progress
}