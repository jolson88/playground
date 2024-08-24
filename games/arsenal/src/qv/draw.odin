package qv

import "core:strconv"
import "core:strings"
import "core:unicode"

Draw_Error :: enum {
    None = 0,
    Command_Too_Short,
    Expected_Comma,
    Expected_Number,
    Unexpected_End_Of_Command,
    Unrecognized_Command,
}

Draw_Command_Type :: enum {
    Unknown = 0,
    One_Dimension,
    Two_Dimensions,
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

Draw_Command :: struct {
    type: Draw_Command_Type,
    direction: Draw_Direction,
    param_1, param_2: int,
    return_to_pos: bool,
    pen_up: bool,
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
    if cur_idx^ >= len(src) {
        return 0, .Unexpected_End_Of_Command
    }

    num_start := cur_idx^
    num_end := num_start+1
    if !unicode.is_digit(rune(src[num_start])) {
        return 0, .Expected_Number
    }
    for c in src[num_end:] {
        if !unicode.is_digit(rune(c)) {
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
            cmd.type = .One_Dimension
            cmd.direction = direction_map[cmd_code]
            skip_whitespace(src, cur_idx)
            cmd.param_1 = parse_number(src, cur_idx) or_return
        case 'n':
            cur_idx^ = cur_idx^+1
            cmd = parse_command(src, cur_idx) or_return
            cmd.return_to_pos = true
        case 'b':
            cur_idx^ = cur_idx^+1
            cmd = parse_command(src, cur_idx) or_return
            cmd.pen_up = true
        case 'm':
            cur_idx^ = cur_idx^+1
            cmd.type = .Two_Dimensions
            skip_whitespace(src, cur_idx)
            cmd.param_1 = parse_number(src, cur_idx) or_return
            skip_whitespace(src, cur_idx)
            if src[cur_idx^] != ',' {
                return cmd, .Expected_Comma
            }
            cur_idx^ = cur_idx^+1
            skip_whitespace(src, cur_idx)
            cmd.param_2 = parse_number(src, cur_idx) or_return
        case:
            return cmd, .Unrecognized_Command
    }

    return cmd, .None
}