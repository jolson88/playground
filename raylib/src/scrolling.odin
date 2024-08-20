package playground

import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

src_font_size: i32 = 24
ui_font_size:  i32 = 16
window_title_height: i32 = 32

text_scroll :: proc() {
    src := #load(#file, string)
    src_font: rl.Font
    ui_font:  rl.Font

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Scrolling")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.MaximizeWindow()
    rl.SetTargetFPS(60)
    rl.SetTextLineSpacing(24)

    src_dir := filepath.dir(#file, context.temp_allocator)
    src_cstring := strings.clone_to_cstring(src)
    defer delete(src_cstring)

    ui_font_path := filepath.join([]string{src_dir, "resources", "poppins.otf"}, context.temp_allocator)
    ui_font = rl.LoadFontEx(strings.clone_to_cstring(ui_font_path, context.temp_allocator), ui_font_size, nil, 0)
    rl.GuiSetFont(ui_font)
    src_font_path := filepath.join([]string{src_dir, "resources", "source_sans_pro.otf"}, context.temp_allocator)
    src_font = rl.LoadFontEx(strings.clone_to_cstring(src_font_path, context.temp_allocator), src_font_size, nil, 0)
    src_total_size := rl.MeasureTextEx(src_font, src_cstring, f32(src_font_size), 2)
    defer rl.UnloadFont(ui_font)
    defer rl.UnloadFont(src_font)

    code_window_minimized := false
    screen_width, screen_height: i32
    window_view: rl.Rectangle
    window_scroll: rl.Vector2
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{120, 143, 153, 255})
        screen_width  = rl.GetScreenWidth()
        screen_height = rl.GetScreenHeight()

        border_size: i32 = 5
        window_loc := rl.Rectangle{20, 20, f32(screen_width - 440), f32(screen_height - 340)}
        window_content_loc: rl.Rectangle
        if (ui_window(window_loc, filepath.base(#file), border_size, &window_content_loc, &code_window_minimized)) {
            rl.GuiScrollPanel(
                window_content_loc, nil, rl.Rectangle{0, 0, src_total_size.x, src_total_size.y},
                &window_scroll, &window_view
            )
            rl.BeginScissorMode(i32(window_view.x), i32(window_view.y), i32(window_view.width), i32(window_view.height))
                rl.DrawRectangle(i32(window_view.x), i32(window_view.y), i32(window_view.width), i32(window_view.height), rl.Color{59, 69, 73, 255})
                rl.DrawTextEx(
                    src_font, src_cstring,
                    rl.Vector2{window_content_loc.x + window_scroll.x + 10, window_content_loc.y + window_scroll.y + 10},
                    f32(src_font_size),
                    2,
                    rl.RAYWHITE
                )
            rl.EndScissorMode()
        }

        rl.EndDrawing()
        free_all(context.temp_allocator)
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
    title_text      := rl.GuiIconText(.ICON_ARROW_DOWN_FILL if !minimized^ else .ICON_ARROW_RIGHT_FILL, strings.clone_to_cstring(strings.to_upper(title, context.temp_allocator), context.temp_allocator))
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), ui_font_size)
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
