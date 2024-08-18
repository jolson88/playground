package playground

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 760

// TODO: Remove Dimensions and use raylib.Rectangle instead
Dimensions :: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
}

main :: proc() {
    text_scroll()
}