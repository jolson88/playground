package recurse

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

main :: proc() {
  when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("\n=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("\n=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

  // ebnf_tui()
  ebnf_gui()
}

LOREM_IPSUM :: `
	Lorem ipsum dolor sit amet,
	consectetur adipiscing elit.
	Donec efficitur ac urna eu vulputate.
	Nullam et bibendum mauris.
	Nulla condimentum ultrices nunc,
	et hendrerit urna eleifend in.
`
WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 760
PADDING 	  :: 24

text_align :: proc() {
	text_align := rl.GuiTextAlignment.TEXT_ALIGN_LEFT
	vertical_text_align := rl.GuiTextAlignmentVertical.TEXT_ALIGN_MIDDLE

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Text Alignment")
	for !rl.WindowShouldClose() {
	  rl.BeginDrawing()
	  rl.ClearBackground(rl.WHITE)
  
	  rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_ALIGNMENT), i32(rl.GuiTextAlignment.TEXT_ALIGN_CENTER))
	  rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_ALIGNMENT_VERTICAL), i32(rl.GuiTextAlignmentVertical.TEXT_ALIGN_MIDDLE))
	  if (rl.GuiButton(rl.Rectangle{ PADDING, PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_TOP, ""))) {
		vertical_text_align = rl.GuiTextAlignmentVertical.TEXT_ALIGN_TOP
	  }
	  if (rl.GuiButton(rl.Rectangle{ PADDING + (PADDING + 10), PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_CENTER, ""))) {
		vertical_text_align = rl.GuiTextAlignmentVertical.TEXT_ALIGN_MIDDLE
	  }
	  if (rl.GuiButton(rl.Rectangle{ PADDING + ((PADDING + 10) * 2), PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_BOTTOM, ""))) {
		vertical_text_align = rl.GuiTextAlignmentVertical.TEXT_ALIGN_BOTTOM
	  }
	  if (rl.GuiButton(rl.Rectangle{ PADDING + ((PADDING + 10) * 4), PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_LEFT, ""))) {
		text_align = rl.GuiTextAlignment.TEXT_ALIGN_LEFT
	  }
	  if (rl.GuiButton(rl.Rectangle{ PADDING + ((PADDING + 10) * 5), PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_CENTER, ""))) {
		text_align = rl.GuiTextAlignment.TEXT_ALIGN_CENTER
	  }
	  if (rl.GuiButton(rl.Rectangle{ PADDING + ((PADDING + 10) * 6), PADDING / 2, 24, 24 }, rl.GuiIconText(rl.GuiIconName.ICON_BOX_RIGHT, ""))) {
		text_align = rl.GuiTextAlignment.TEXT_ALIGN_RIGHT
	  }

	  rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_ALIGNMENT), i32(text_align))
	  rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_ALIGNMENT_VERTICAL), i32(vertical_text_align))
	  rl.GuiTextBox(rl.Rectangle{ PADDING, PADDING * 2, WINDOW_WIDTH - PADDING * 2, WINDOW_HEIGHT - PADDING * 4 }, LOREM_IPSUM, 32, false)
  
	  rl.EndDrawing()
	}
}