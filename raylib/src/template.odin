package playground

import rl "vendor:raylib"

exploration_name :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Exploration")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.MaximizeWindow()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{120, 143, 153, 255})

        // do cool stuff

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}