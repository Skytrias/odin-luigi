package main

import luigi ".."
import "core:fmt"
import "core:os"

// Luigi's example program: widgets, a code view, a table, a theme editor, and
// MDI windows. Run it from the repository root so the code view finds its file:
//     odin run luigi_rmgui/examples/basics.odin -file

main :: proc() {
	if !luigi.ui_initialize() {
		fmt.println("SDL3 initialization failed")
		return
	}
	defer luigi.ui_shutdown()

	window := luigi.window_create("Odin Luigi", 840, 540)
	if window == nil {
		fmt.println("SDL3 window creation failed")
		return
	}

	split := luigi.split_pane_create(&window.element, false, 0.42)
	panel := luigi.panel_create(&split.element, {.Gray, .Medium_Spacing, .Scroll})
	panel.element.flags += {.H_Fill, .V_Fill}
	status := luigi.label_create(&panel.element, "Hello, I am a label!")
	button := luigi.button_create(&panel.element, "Hello")
	button.element.message_user = button_message
	button.element.user_data = status
	menu_button := luigi.button_create(&panel.element, "Menu")
	menu_button.element.message_user = menu_button_message
	menu_button.element.user_data = status
	dialog_button := luigi.button_create(&panel.element, "Dialog")
	dialog_button.element.message_user = dialog_button_message
	luigi.checkbox_create(&panel.element, "A checkbox")
	gauge := luigi.gauge_create(&panel.element)
	gauge.position = 0.3
	slider := luigi.slider_create(&panel.element)
	slider.position = 0.3
	slider.element.message_user = slider_message
	slider.element.user_data = gauge
	input := luigi.textbox_create(&panel.element)
	luigi.textbox_replace(input, "Edit me", false)

	right := luigi.split_pane_create(&split.element, true, 0.62)
	code := luigi.code_create(&right.element)
	code.element.flags += {.H_Fill, .V_Fill}
	if contents, err := os.read_entire_file("luigi_rmgui/luigi.odin", context.allocator); err == nil {
		luigi.code_insert_content(code, string(contents), true)
		delete(contents)
	}

	tabs := luigi.tab_pane_create(&right.element, "Table\tNotes")
	table := luigi.table_create(&tabs.element, "Item\tValue")
	table.item_count = 100000
	table.element.message_user = table_message
	luigi.table_resize_columns(table)
	second := luigi.panel_create(&tabs.element, {.Gray, .Medium_Spacing})
	luigi.label_create(&second.element, "Luigi in Odin")
	luigi.label_create(&second.element, "Drag the dividers or change tabs.")
	luigi.element_refresh(&window.element)

	mdi_window := luigi.window_create("MDI Example", 500, 420)
	if mdi_window != nil {
		client := luigi.mdi_client_create(&mdi_window.element)
		child_a := luigi.mdi_child_create(client, luigi.rect(20, 310, 20, 250), "My Window")
		inside_a := luigi.panel_create(&child_a.element, {.Gray, .Medium_Spacing})
		luigi.label_create(&inside_a.element, "It's a christmas miracle")
		child_b := luigi.mdi_child_create(client, luigi.rect(70, 390, 85, 325), "Second Window")
		inside_b := luigi.panel_create(&child_b.element, {.White, .Medium_Spacing})
		luigi.button_create(&inside_b.element, "A button")
		luigi.element_refresh(&mdi_window.element)
	}
	theme_window := luigi.window_create("Theme Editor", 590, 320)
	if theme_window != nil {
		pane := luigi.split_pane_create(&theme_window.element, false, 0.46)
		left := luigi.panel_create(&pane.element, {.Gray, .Medium_Spacing})
		theme_picker = luigi.color_picker_create(&left.element)
		theme_picker.element.message_user = theme_picker_message
		theme_table = luigi.table_create(&pane.element, "Item\tColor")
		theme_table.item_count = len(theme_items)
		theme_table.element.message_user = theme_table_message
		luigi.table_resize_columns(theme_table)
		luigi.element_refresh(&theme_window.element)
	}
	luigi.ui_message_loop()
}

button_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Clicked {
		fmt.println("clicked!")
		luigi.label_set_content((^luigi.Label)(element.user_data), "Hello clicked!")
	}
	return 0
}

slider_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Value_Changed {
		gauge := (^luigi.Gauge)(element.user_data)
		gauge.position = (^luigi.Slider)(element).position
		luigi.element_repaint(&gauge.element)
	}
	return 0
}

selected_row: int = -1

table_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Table_Get_Item {
		item := (^luigi.Table_Get_Item)(payload)
		item.selected = item.index == selected_row
		if item.column == 0 {
			item.text = fmt.tprintf("Item %d", item.index)
		} else {
			item.text = fmt.tprintf("Value %d", item.index)
		}
	} else if kind == .Left_Down {
		selected_row = luigi.table_hit_test((^luigi.Table)(element), element.window.cursor_x, element.window.cursor_y)
		luigi.element_repaint(element)
	}
	return 0
}

menu_button_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Clicked {
		menu := luigi.menu_create(element)
		if menu != nil {
			luigi.menu_add_item(menu, "Item 1", menu_choice, element.user_data)
			luigi.menu_add_item(menu, "Item 2", menu_choice, element.user_data)
			luigi.menu_show(menu)
		}
		return 1
	}
	return 0
}
menu_choice :: proc(user_data: rawptr) {
	luigi.label_set_content((^luigi.Label)(user_data), "A menu item was clicked!")
}
dialog_button_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Clicked {
		answer: [dynamic]u8
		defer delete(answer)
		arguments := []luigi.Dialog_Argument {
			{text = "Luigi in Odin"},
			{buffer = &answer},
			{text = "OK"},
			{text = "Cancel"},
		}
		result := luigi.dialog_show_format(element.window, "%s\n%t\n%f%b%b", arguments)
		fmt.println("Dialog result:", result, " text:", string(answer[:]))
		return 1
	}
	return 0
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
theme_picker: ^luigi.Color_Picker
theme_table: ^luigi.Table
theme_selected: int = -1

theme_color :: proc(index: int) -> ^u32 {
	colors := (^[21]u32)(&luigi.ui.theme)
	return &colors[index]
}
theme_table_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Table_Get_Item {
		item := (^luigi.Table_Get_Item)(payload)
		item.selected = item.index == theme_selected
		if item.column == 0 {
			item.text = theme_items[item.index]
		} else {
			item.text = fmt.tprintf("#%06x", theme_color(item.index)^ & 0xFFFFFF)
		}
	} else if kind == .Left_Down {
		theme_selected = luigi.table_hit_test(
			(^luigi.Table)(element),
			element.window.cursor_x,
			element.window.cursor_y,
		)
		if theme_selected >= 0 {
			theme_picker.hue, theme_picker.saturation, theme_picker.value, _ = luigi.color_to_hsv(
				theme_color(theme_selected)^,
			)
			luigi.element_repaint(&theme_picker.element)
		}
		luigi.element_repaint(element)
	}
	return 0
}
theme_picker_message :: proc(element: ^luigi.Element, kind: luigi.Message, data: int, payload: rawptr) -> int {
	if kind == .Value_Changed && theme_selected >= 0 {
		theme_color(theme_selected)^ = luigi.color_to_rgb(
			theme_picker.hue,
			theme_picker.saturation,
			theme_picker.value,
		)
		for window := luigi.ui.windows; window != nil; window = window.next_window {
			luigi.element_repaint(&window.element)
		}
	}
	return 0
}
