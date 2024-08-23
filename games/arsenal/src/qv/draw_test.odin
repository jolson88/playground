package qv

import "core:testing"


/*
    title := "s8 r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
    qv.draw("bm90,250 c15")
    qv.draw(title)
*/

/*
Testing scenarios needing to be covered:
- command "modifiers" ('n': return to original location, 'b': move without drawing)
- failure if a number is found when command was expected
- failure if a letter is found when a number was expected
- scaling command
- color command
- integers that would overflow (erroring for a number > 999999 for simplicity)
- movement with comma
- movement failure if only one number (both just comma, and no comma)
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
        type=.Draw,
        direction=.Right,
        param_1=20
    })
}

@(test)
parse_directional_commands_test :: proc(t: ^testing.T) {
    using testing

    idx: int
    cmd, err := parse_command("r20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.Right,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("l20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.Left,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("u20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.Up,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("d20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.Down,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("e20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.UpRight,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("f20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.DownRight,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("g20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.DownLeft,
        param_1=20
    })

    idx = 0
    cmd, err = parse_command("h20", &idx)
    expect_value(t, idx, 3)
    expect_value(t, cmd, Draw_Command{
        type=.Draw,
        direction=.UpLeft,
        param_1=20
    })
}
