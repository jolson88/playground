package playground

import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

src := #load(#file, string)
window_title_height: i32 = 32
src_font: rl.Font
ui_font:  rl.Font
src_font_size: i32 = 24
ui_font_size:  i32 = 16

text_scroll :: proc() {
    rl.InitWindow(1280, 768, "Scrolling")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.MaximizeWindow()
    rl.SetTargetFPS(60)

    ui_font_path := filepath.join([]string{filepath.dir(#file), "resources", "poppins.otf"})
    ui_font = rl.LoadFontEx(strings.clone_to_cstring(ui_font_path), 24, nil, 0)
    rl.GuiSetFont(ui_font)
    src_font_path := filepath.join([]string{filepath.dir(#file), "resources", "source_sans_pro.otf"})
    src_font = rl.LoadFontEx(strings.clone_to_cstring(src_font_path), src_font_size, nil, 0)
    defer rl.UnloadFont(ui_font)
    defer rl.UnloadFont(src_font)

    screen_width, screen_height: i32
    code_window_minimized := false
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{120, 143, 153, 255})

        border_size: i32 = 5
        content_loc: rl.Rectangle
        screen_width  = rl.GetScreenWidth()
        screen_height = rl.GetScreenHeight()

        window_loc := rl.Rectangle{20, 20, f32(screen_width - 440), f32(screen_height - 340)}
        if (ui_window(window_loc, filepath.base(#file), border_size, &content_loc, &code_window_minimized)) {
            margin: i32 = 5
            rl.SetTextLineSpacing(24)
            rl.BeginScissorMode(i32(content_loc.x), i32(content_loc.y), i32(content_loc.width), i32(content_loc.height))
            rl.DrawTextEx(
                src_font, strings.clone_to_cstring(src),
                rl.Vector2{ content_loc.x + f32(margin), content_loc.y + f32(margin) },
                f32(src_font_size), 2,
                rl.RAYWHITE)
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
    title_font_size := window_title_height - border_size * 2
    render_x = window_x + border_size
    render_y = window_y
    title_bounds    := rl.Rectangle{f32(render_x), f32(render_y), f32(window_loc.width), f32(window_title_height)}
    title_text      := rl.GuiIconText(.ICON_ARROW_DOWN if !minimized^ else .ICON_ARROW_RIGHT, strings.clone_to_cstring(strings.to_upper(title)))
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
