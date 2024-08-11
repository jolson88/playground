package recurse

import rl "vendor:raylib"

main :: proc() {
  run_ebnf()

  // gui()
}

gui :: proc() {
  rl.InitWindow(1280, 760, "Recursive Descent")

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.MAGENTA)
    rl.EndDrawing()
  }
}