package playground

import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

text_fonts :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Scrolling")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.MaximizeWindow()
    rl.SetTargetFPS(60)
    rl.SetTextLineSpacing(32)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.LINE_COLOR), rl.ColorToInt(rl.WHITE))

    font_size: i32 = 32
    src_dir := filepath.dir(#file, context.temp_allocator)

    poppins_font_path := filepath.join([]string{src_dir, "resources", "poppins.otf"}, context.temp_allocator)
    poppins_font := rl.LoadFontEx(strings.clone_to_cstring(poppins_font_path, context.temp_allocator), font_size, nil, 0)
    defer rl.UnloadFont(poppins_font)

    source_sans_font_path := filepath.join([]string{src_dir, "resources", "source_sans_pro.otf"}, context.temp_allocator)
    source_sans_font := rl.LoadFontEx(strings.clone_to_cstring(source_sans_font_path, context.temp_allocator), font_size, nil, 0)
    defer rl.UnloadFont(source_sans_font)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.GuiGrid(rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}, nil, 50, 5, nil)
        rl.DrawTextEx(
            poppins_font, "Poppins\nThe quick brown fox jumps over the lazy do\n",
            rl.Vector2{20, 20}, f32(font_size), 2,
            rl.RAYWHITE
        )
        rl.DrawTextEx(
            source_sans_font, "Source Sans Pro\nThe quick brown fox jumps over the lazy do\n",
            rl.Vector2{20, 200}, f32(font_size), 2,
            rl.RAYWHITE
        )

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}
