package playground

import "core:strings"
import rl "vendor:raylib"

src := #load(#file, string)
window_title_height: i32 = 24

text_scroll :: proc() {
    rl.InitWindow(1280, 768, "Scrolling")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.MaximizeWindow()
    rl.SetTargetFPS(60)

    screen_width, screen_height: i32
    code_window_minimized := false
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{120, 143, 153, 255})

        border_size: i32 = 5
        content_loc: rl.Rectangle
        screen_width  = rl.GetScreenWidth()
        screen_height = rl.GetScreenHeight()

        window_loc := rl.Rectangle{20, 20, f32(screen_width - 40), f32((screen_height - 40) / 2)}
        if (ui_window(window_loc, #file, border_size, &content_loc, &code_window_minimized)) {
            margin: i32 = 5
            rl.SetTextLineSpacing(24)
            rl.BeginScissorMode(i32(content_loc.x), i32(content_loc.y), i32(content_loc.width), i32(content_loc.height))
            rl.DrawText(strings.clone_to_cstring(src), i32(content_loc.x) + margin, i32(content_loc.y) + margin, 16, rl.WHITE)
            rl.EndScissorMode()
        }
        
        rl.EndDrawing()
    }
}

ui_window :: proc(window_loc: rl.Rectangle, title: string, border_size: i32, content_loc: ^rl.Rectangle, minimized: ^bool) -> bool {
    // window frame
    window_width := i32(window_loc.width)
    window_height := i32(window_loc.height)
    window_x := i32(window_loc.x)
    window_y := i32(window_loc.y)
    render_x := window_x
    render_y := window_y
    rl.DrawRectangle(
        render_x, render_y,
        window_width, window_height if !minimized^ else window_title_height,
        rl.Color{63, 95, 111, 255}
    )

    // title bar
    render_x = window_x + border_size
    render_y = window_y
    title_bounds    := rl.Rectangle{f32(render_x), f32(render_y), f32(window_loc.width), f32(window_title_height)}
    title_font_size := window_title_height - border_size * 2
    title_text      := rl.GuiIconText(.ICON_ARROW_DOWN if !minimized^ else .ICON_ARROW_RIGHT, #file)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), title_font_size)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL), i32(rl.ColorToInt(rl.WHITE)))
    if (rl.GuiLabelButton(title_bounds, title_text)) {
        minimized^ = !minimized^
    }

    // content background
    if (!minimized^) {
        content_loc^ = rl.Rectangle{
            f32(window_x + border_size), f32(window_y + window_title_height),
            f32(window_width - border_size * 2), f32(window_height - window_title_height - border_size)
        }
        rl.DrawRectangle(i32(content_loc.x), i32(content_loc.y), i32(content_loc.width), i32(content_loc.height), rl.Color{59, 69, 73, 255})
    }

    return !minimized^
}
