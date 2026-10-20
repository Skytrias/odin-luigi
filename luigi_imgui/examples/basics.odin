package main

import luigi ".."
import "core:fmt"
import "core:os"

// Luigi's example program, declared every frame: widgets, a code view, a table,
// a theme editor, and MDI windows. Run it from the repository root so the code
// view finds its file:
//     odin run luigi_imgui/examples/basics.odin -file

App :: struct {
	status:         string,
	checked:        bool,
	slider:         f32,
	input:          [dynamic]u8,
	source:         string,
	selected_row:   int,
	show_theme:     bool,
	show_mdi:       bool,
	show_first:     bool,
	show_second:    bool,
	mdi_clicks:     int,
	theme_selected: int,
	theme_color:    luigi.Color_HSV,
}

main :: proc() {
	if !luigi.ui_initialize() {
		fmt.println("SDL3 initialization failed")
		return
	}
	defer luigi.ui_shutdown()

	app := App {
		status = "Hello, I am a label!",
		slider = 0.3,
		selected_row = -1,
		show_theme = true,
		show_mdi = true,
		show_first = true,
		show_second = true,
		theme_selected = -1,
		theme_color = {value = 1, opacity = 1},
	}
	defer delete(app.input)
	append(&app.input, "Edit me")
	if contents, err := os.read_entire_file("luigi_imgui/luigi.odin", context.allocator); err == nil {
		app.source = string(contents)
	}
	defer delete(app.source)

	for luigi.ui_frame_begin() {
		running := build_main_window(&app)
		if app.show_theme { build_theme_window(&app) }
		if app.show_mdi { build_mdi_window(&app) }
		luigi.ui_frame_end()
		free_all(context.temp_allocator)
		if !running { break }
	}
}

build_main_window :: proc(app: ^App) -> bool {
	window := luigi.window_create("Odin Luigi", 840, 540)
	if window == nil {
		fmt.println("SDL3 window creation failed")
		return false
	}
	if luigi.window_close_requested(window) { return false }

	split := luigi.split_pane_create(&window.element, false, 0.42)
	panel := luigi.panel_create(&split.element, {.Gray, .Medium_Spacing, .Scroll})
	panel.flags += {.H_Fill, .V_Fill}
	luigi.label_create(&panel.element, app.status)
	if luigi.button(&panel.element, "Hello") {
		fmt.println("clicked!")
		app.status = "Hello clicked!"
	}
	menu_button := luigi.button_create(&panel.element, "Menu")
	if luigi.element_clicked(&menu_button.element) { luigi.menu_open(&menu_button.element) }
	if menu := luigi.menu_create(&menu_button.element); menu != nil {
		if luigi.menu_item(menu, "Item 1") { app.status = "Item 1 was clicked!" }
		if luigi.menu_item(menu, "Item 2") { app.status = "Item 2 was clicked!" }
	}
	luigi.checkbox(&panel.element, "A checkbox", &app.checked)
	// The gauge is declared before the slider that moves it; the frame after a
	// drag shows the new value.
	luigi.gauge_create(&panel.element, app.slider)
	luigi.slider(&panel.element, &app.slider)
	luigi.textbox(&panel.element, &app.input)
	luigi.label_create(&panel.element, fmt.tprintf("Typed %d characters", len(app.input)))
	luigi.checkbox(&panel.element, "Theme editor window", &app.show_theme)
	luigi.checkbox(&panel.element, "MDI window", &app.show_mdi)

	right := luigi.split_pane_create(&split.element, true, 0.62)
	code := luigi.code_create(&right.element, app.source)
	code.flags += {.H_Fill, .V_Fill}

	tabs := luigi.tab_pane_create(&right.element, "Table\tNotes")
	table := luigi.table_create(&tabs.element, "Item\tValue", 100000)
	table.message_user = table_message
	table.user_data = app
	if row, clicked := luigi.table_clicked(table); clicked { app.selected_row = row }
	notes := luigi.panel_create(&tabs.element, {.Gray, .Medium_Spacing})
	luigi.label_create(&notes.element, "Luigi in Odin, immediate mode")
	luigi.label_create(&notes.element, "Drag the dividers or change tabs.")
	luigi.label_create(&notes.element, "The whole element tree is declared every frame.")
	return true
}

table_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Table_Get_Item {
		app := (^App)(element.user_data)
		item := (^luigi.Table_Get_Item)(payload)
		item.selected = item.index == app.selected_row
		if item.column == 0 {
			item.text = fmt.tprintf("Item %d", item.index)
		} else {
			item.text = fmt.tprintf("Value %d", item.index)
		}
	}
	return 0
}

build_mdi_window :: proc(app: ^App) {
	window := luigi.window_create("MDI Example", 500, 420)
	if window == nil { return }
	if luigi.window_close_requested(window) { app.show_mdi = false }
	client := luigi.mdi_client_create(&window.element)
	if app.show_first {
		child := luigi.mdi_child_create(client, luigi.rect(20, 310, 20, 250), "My Window")
		if luigi.mdi_child_close_requested(child) { app.show_first = false }
		inside := luigi.panel_create(&child.element, {.Gray, .Medium_Spacing})
		luigi.label_create(&inside.element, "It's a christmas miracle")
	}
	if app.show_second {
		child := luigi.mdi_child_create(client, luigi.rect(70, 390, 85, 325), "Second Window")
		if luigi.mdi_child_close_requested(child) { app.show_second = false }
		inside := luigi.panel_create(&child.element, {.White, .Medium_Spacing})
		if luigi.button(&inside.element, "A button") { app.mdi_clicks += 1 }
		luigi.label_create(&inside.element, fmt.tprintf("Clicked %d times", app.mdi_clicks))
		if !app.show_first && luigi.button(&inside.element, "Reopen the first window") { app.show_first = true }
	}
}

theme_items := [21]string {
	"panel1",
	"panel2",
	"selected",
	"border",
	"text",
	"textDisabled",
	"textSelected",
	"buttonNormal",
	"buttonHovered",
	"buttonPressed",
	"buttonDisabled",
	"textboxNormal",
	"textboxFocused",
	"codeFocused",
	"codeBackground",
	"codeDefault",
	"codeComment",
	"codeString",
	"codeNumber",
	"codeOperator",
	"codePreprocessor",
}

theme_color :: proc(index: int) -> ^u32 {
	colors := (^[21]u32)(&luigi.ui.theme)
	return &colors[index]
}

build_theme_window :: proc(app: ^App) {
	window := luigi.window_create("Theme Editor", 590, 320)
	if window == nil { return }
	if luigi.window_close_requested(window) { app.show_theme = false }
	pane := luigi.split_pane_create(&window.element, false, 0.46)
	left := luigi.panel_create(&pane.element, {.Gray, .Medium_Spacing})
	before := app.theme_color
	luigi.color_picker_create(&left.element, &app.theme_color)
	if app.theme_color != before && app.theme_selected >= 0 {
		theme_color(app.theme_selected)^ = luigi.color_to_rgb(
			app.theme_color.hue,
			app.theme_color.saturation,
			app.theme_color.value,
		)
	}
	table := luigi.table_create(&pane.element, "Item\tColor", len(theme_items))
	table.message_user = theme_table_message
	table.user_data = app
	if row, clicked := luigi.table_clicked(table); clicked && row >= 0 {
		app.theme_selected = row
		app.theme_color.hue, app.theme_color.saturation, app.theme_color.value, _ = luigi.color_to_hsv(
			theme_color(row)^,
		)
	}
}

theme_table_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Table_Get_Item {
		app := (^App)(element.user_data)
		item := (^luigi.Table_Get_Item)(payload)
		item.selected = item.index == app.theme_selected
		if item.column == 0 {
			item.text = theme_items[item.index]
		} else {
			item.text = fmt.tprintf("#%06x", theme_color(item.index)^ & 0xFFFFFF)
		}
	}
	return 0
}
