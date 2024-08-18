package examples

import "core:strings"
import rl "vendor:raylib"

scroll_panel_example :: proc() {
    screen_width:  i32 = 800
    screen_height: i32 = 450

    rl.InitWindow(screen_width, screen_height, "Raygui - Scroll Panel Example")
    rl.SetTargetFPS(60)

    panel_view: rl.Rectangle
    panel_rec := rl.Rectangle{ 20, 40, 200, 150 }
    panel_content_rec := rl.Rectangle{ 0, 0, 340, 340 }
    panel_scroll := rl.Vector2{ 99, -20 }
    show_content_area := true
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)

            rl.DrawText(rl.TextFormat("[%f, %f]", panel_scroll.x, panel_scroll.y), 4, 4, 20, rl.RED)
            rl.GuiScrollPanel(panel_rec, nil, panel_content_rec, &panel_scroll, &panel_view)
            rl.BeginScissorMode(i32(panel_view.x), i32(panel_view.y), i32(panel_view.width), i32(panel_view.height))
                rl.GuiGrid(rl.Rectangle{panel_rec.x + panel_scroll.x, panel_rec.y + panel_scroll.y, panel_content_rec.width, panel_content_rec.height}, nil, 16, 3, nil)
            rl.EndScissorMode()

            if show_content_area {
                rl.DrawRectangle(
                    i32(panel_rec.x + panel_scroll.x), i32(panel_rec.y + panel_scroll.y),
                    i32(panel_content_rec.width), i32(panel_content_rec.height),
                    rl.Fade(rl.RED, 0.1))
            }

            draw_style_edit_controls();

            rl.GuiCheckBox(rl.Rectangle{ 565, 80, 20, 20 }, "SHOW CONTENT AREA", &show_content_area)
            rl.GuiSliderBar(rl.Rectangle{ 590, 385, 145, 15}, "WIDTH", rl.TextFormat("%i", i32(panel_content_rec.width)), &panel_content_rec.width, 1, 600)
            rl.GuiSliderBar(rl.Rectangle{ 590, 410, 145, 15 }, "HEIGHT", rl.TextFormat("%i", i32(panel_content_rec.height)), &panel_content_rec.height, 1, 400)
        rl.EndDrawing()
    }
}

draw_style_edit_controls :: proc() {
    // ScrollPanel style controls
    {
        rl.GuiGroupBox(rl.Rectangle{ 550, 170, 220, 205 }, "SCROLLBAR STYLE")

        style := rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiControlProperty.BORDER_WIDTH))
        rl.GuiLabel(rl.Rectangle{ 555, 195, 110, 10 }, "BORDER_WIDTH")
        rl.GuiSpinner(rl.Rectangle{ 670, 190, 90, 20 }, nil, &style, 0, 6, false)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiControlProperty.BORDER_WIDTH), style)

        style = rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiScrollBarProperty.ARROWS_SIZE))
        rl.GuiLabel(rl.Rectangle{ 555, 220, 110, 10 }, "ARROWS_SIZE")
        rl.GuiSpinner(rl.Rectangle{ 670, 215, 90, 20 }, nil, &style, 4, 14, false)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiScrollBarProperty.ARROWS_SIZE), style)

        style = rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_PADDING))
        rl.GuiLabel(rl.Rectangle{ 555, 245, 110, 10 }, "SLIDER_PADDING")
        rl.GuiSpinner(rl.Rectangle{ 670, 240, 90, 20 }, nil, &style, 0, 14, false)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_PADDING), style)

        scrollBarArrows := bool(rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiScrollBarProperty.ARROWS_VISIBLE)))
        rl.GuiCheckBox(rl.Rectangle{ 565, 280, 20, 20 }, "ARROWS_VISIBLE", &scrollBarArrows)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiScrollBarProperty.ARROWS_VISIBLE), i32(scrollBarArrows))

        style = rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_PADDING))
        rl.GuiLabel(rl.Rectangle{ 555, 325, 110, 10 }, "SLIDER_PADDING")
        rl.GuiSpinner(rl.Rectangle{ 670, 320, 90, 20 }, nil, &style, 0, 14, false)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_PADDING), style)

        style = rl.GuiGetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_WIDTH))
        rl.GuiLabel(rl.Rectangle{ 555, 350, 110, 10 }, "SLIDER_WIDTH")
        rl.GuiSpinner(rl.Rectangle{ 670, 345, 90, 20 }, nil, &style, 2, 100, false)
        rl.GuiSetStyle(.SCROLLBAR, i32(rl.GuiSliderProperty.SLIDER_WIDTH), style)

        text := "SCROLLBAR: LEFT" if rl.GuiGetStyle(.LISTVIEW, i32(rl.GuiListViewProperty.SCROLLBAR_SIDE)) == rl.SCROLLBAR_LEFT_SIDE else "SCROLLBAR: RIGHT"
        toggleScrollBarSide := bool(rl.GuiGetStyle(.LISTVIEW, i32(rl.GuiListViewProperty.SCROLLBAR_SIDE)))
        rl.GuiToggle(rl.Rectangle{ 560, 110, 200, 35 }, strings.clone_to_cstring(text), &toggleScrollBarSide)
        rl.GuiSetStyle(.LISTVIEW, i32(rl.GuiListViewProperty.SCROLLBAR_SIDE), i32(toggleScrollBarSide))
    }

    // ScrollBar style controls
    {
        rl.GuiGroupBox(rl.Rectangle{ 550, 20, 220, 135 }, "SCROLLPANEL STYLE")

        style := rl.GuiGetStyle(.LISTVIEW, i32(rl.GuiListViewProperty.SCROLLBAR_WIDTH))
        rl.GuiLabel(rl.Rectangle{ 555, 35, 110, 10 }, "SCROLLBAR_WIDTH")
        rl.GuiSpinner(rl.Rectangle{ 670, 30, 90, 20 }, nil, &style, 6, 30, false)
        rl.GuiSetStyle(.LISTVIEW, i32(rl.GuiListViewProperty.SCROLLBAR_WIDTH), style)

        style = rl.GuiGetStyle(.DEFAULT, i32(rl.GuiControlProperty.BORDER_WIDTH))
        rl.GuiLabel(rl.Rectangle{ 555, 60, 110, 10 }, "BORDER_WIDTH")
        rl.GuiSpinner(rl.Rectangle{ 670, 55, 90, 20 }, nil, &style, 0, 20, false)
        rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.BORDER_WIDTH), style)
    }
}