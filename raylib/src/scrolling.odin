package playground

import "core:strings"
import rl "vendor:raylib"

Dimensions :: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
}

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
        screen_width  = rl.GetScreenWidth()
        screen_height = rl.GetScreenHeight()
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{120, 143, 153, 255})

        padding: i32 = 20
        border_size:  i32 = 5
        window_loc := Dimensions{padding, padding, screen_width - padding * 2, (screen_height - padding * 2) / 2}
        ui_text_window(window_loc, #file, border_size, &code_window_minimized)
        
        rl.EndDrawing()
    }
}

ui_text_window :: proc(window_loc: Dimensions, title: string, border_size: i32, minimized: ^bool) {
    render_x := window_loc.x
    render_y := window_loc.y

    // window body
    rl.DrawRectangle(
        render_x, render_y,
        window_loc.width, window_loc.height if !minimized^ else window_title_height,
        rl.Color{63, 95, 111, 255}
    )

    // title bar
    render_x = window_loc.x + border_size
    render_y = window_loc.y
    title_text := rl.GuiIconText(.ICON_ARROW_DOWN if !minimized^ else .ICON_ARROW_RIGHT, #file)
    title_font_size := window_title_height - border_size * 2
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), title_font_size)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL), i32(rl.ColorToInt(rl.WHITE)))
    if (rl.GuiLabelButton(rl.Rectangle{f32(render_x), f32(render_y), f32(window_loc.width), f32(window_title_height)}, title_text)) {
        minimized^ = !minimized^
    }

    if (minimized^) {
        return
    }

    // window contents
    render_x = window_loc.x + border_size
    render_y = render_y + window_title_height
    content_loc := Dimensions{render_x, render_y, window_loc.width - border_size * 2, window_loc.height - window_title_height - border_size}
    rl.DrawRectangle(
        content_loc.x, content_loc.y,
        content_loc.width, content_loc.height,
        rl.Color{59, 69, 73, 255},
    )
    
    render_x = render_x + border_size
    render_y = render_y + border_size
    rl.SetTextLineSpacing(24)
    rl.BeginScissorMode(content_loc.x, content_loc.y, content_loc.width, content_loc.height)
    rl.DrawText(strings.clone_to_cstring(src), render_x, render_y, 16, rl.WHITE)
    rl.EndScissorMode()
}
