package qv

import "core:strconv"
import "core:strings"
import "core:unicode"

Draw_Error :: enum {
    None,
    Command_Too_Short,
    Expected_Number,
    Unrecognized_Command,
}

Draw_Command_Type :: enum {
    Unknown = 0,
    Move,
    Draw
}

Draw_Command :: struct {
    type: Draw_Command_Type,
    direction: Draw_Direction,
    param_1, param_2: int,
}

Draw_Direction :: enum {
    Unknown = 0,
    Up,
    Down,
    Right,
    Left,
    UpRight,
    DownRight,
    DownLeft,
    UpLeft,
}

direction_map := map[u8]Draw_Direction{
    'u' = .Up,
    'd' = .Down,
    'r' = .Right,
    'l' = .Left,
    'e' = .UpRight,
    'f' = .DownRight,
    'g' = .DownLeft,
    'h' = .UpLeft
}

skip_whitespace :: proc(src: string, cur_idx: ^int) {
    cur_idx := cur_idx
    for c in src[cur_idx^:] {
        if strings.is_space(c) {
            cur_idx^ = cur_idx^+1
            continue
        }
        break
    }
}

parse_number :: proc(src:string, cur_idx: ^int) -> (val: int, err: Draw_Error) {
    num_start := cur_idx^
    num_end := num_start+1
    if !unicode.is_number(rune(src[num_start])) {
        return 0, .Expected_Number
    }
    for c in src[num_end:] {
        if !unicode.is_number(rune(src[num_start])) {
            break
        }
        num_end = num_end+1
    }
    cur_idx^ = num_end
    return strconv.atoi(src[num_start:num_end]), .None
}

parse_command :: proc(src: string, cur_idx: ^int) -> (cmd: Draw_Command, err: Draw_Error) {
    if len(src) <= cur_idx^+1 { // Minimum valid cmd is two chars (e.g. "r1")
        return Draw_Command{}, .Command_Too_Short
    }

    cmd = Draw_Command{}
    cmd_code := src[cur_idx^];
    switch cmd_code {
        case 'r': fallthrough
        case 'l': fallthrough
        case 'u': fallthrough
        case 'd': fallthrough
        case 'e': fallthrough
        case 'f': fallthrough
        case 'g': fallthrough
        case 'h':
            cur_idx^ = cur_idx^+1
            cmd.type = .Draw
            cmd.direction = direction_map[cmd_code]
            cmd.param_1 = parse_number(src, cur_idx) or_return
        case:
            return cmd, .Unrecognized_Command
    }

    return cmd, .None
}
