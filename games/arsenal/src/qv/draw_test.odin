package qv

import "core:testing"

/*
    title := "s8 r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
    qv.draw("bm90,250 c15")
    qv.draw(title)
*/

/*
Testing scenarios needing to be covered:
- failure if a number is found when command was expected
- scaling command
- color command
- integers that would overflow (erroring for a number > 999999 for simplicity)
- parse all commands in a string
*/

@(test)
parse_command_length_test :: proc(t: ^testing.T) {
    using testing

    idx: int
    cmd, err := parse_command("r", &idx)
    expect_value(t, err, Draw_Error.Command_Too_Short)
}

@(test)
parse_unrecognized_command_test :: proc(t: ^testing.T) {
    using testing

    src := "x203"
    idx: int
    cmd, err := parse_command(src, &idx)
    expect_value(t, err, Draw_Error.Unrecognized_Command)
    expect_value(t, src[idx], 'x')
}

@(test)
parse_expected_number_test :: proc(t: ^testing.T) {
    using testing

    src := "ru203"
    idx: int
    cmd, err := parse_command(src, &idx)
    expect_value(t, err, Draw_Error.Expected_Number)
    expect_value(t, src[idx], 'u')
}

@(test)
parse_whitespace_test :: proc(t: ^testing.T) {
    using testing

    idx: int
    cmd, err := parse_command("r 20", &idx)
    expect_value(t, idx, 4)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Right,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("m 1080 ,  720", &idx)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, idx, 13)
    expect_value(t, cmd, Draw_Command{
        type=.Two_Dimensions,
        param_1=1080,
        param_2=720,
    })
}

@(test)
parse_command_modifier_test :: proc(t: ^testing.T) {
    using testing

    idx: int
    cmd, err := parse_command("nr20", &idx)
    expect_value(t, idx, 4)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Right,
        param_1=20,
        return_to_pos=true,
    })

    idx = 0
    cmd, err = parse_command("br20", &idx)
    expect_value(t, idx, 4)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Right,
        param_1=20,
        pen_up=true,
    })

    idx = 0
    cmd, err = parse_command("nbr20", &idx)
    expect_value(t, idx, 5)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Right,
        param_1=20,
        return_to_pos=true,
        pen_up=true,
    })
}

@(test)
parse_directional_commands_test :: proc(t: ^testing.T) {
    using testing

    idx: int
    cmd, err := parse_command("r20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Right,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("l20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Left,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("u20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Up,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("d20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.Down,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("e20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.UpRight,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("f20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.DownRight,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("g20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.DownLeft,
        param_1=20,
    })

    idx = 0
    cmd, err = parse_command("h20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.One_Dimension,
        direction=.UpLeft,
        param_1=20,
    })
}

@(test)
parse_movement_commands_test :: proc(t: ^testing.T) {
    using testing

    idx := 0
    cmd, err := parse_command("m1080,720", &idx)
    expect_value(t, err, Draw_Error.None)
    expect_value(t, idx, 9)
    expect_value(t, cmd, Draw_Command{
        type=.Two_Dimensions,
        param_1=1080,
        param_2=720,
    })
}

@(test)
parse_invalid_movement_command_test :: proc(t: ^testing.T) {
    using testing

    idx := 0
    cmd, err := parse_command("m12r34", &idx)
    expect_value(t, err, Draw_Error.Expected_Comma)
    expect_value(t, idx, 3)

    idx = 0
    cmd, err = parse_command("m12,", &idx)
    expect_value(t, err, Draw_Error.Unexpected_End_Of_Command)
    expect_value(t, idx, 4)
}
