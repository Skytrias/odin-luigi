package main

import luigi ".."
import "core:strings"
import SDL "vendor:SDL3"

// A to-do list, after Luigi's todo_list_example.cpp. From the repository root:
//     odin run luigi_rmgui/examples/todo.odin -file

Item :: struct {
	text:      string,
	completed: bool,
}

Tab :: enum {
	All,
	Active,
	Completed,
}

items: [dynamic]Item
tab: Tab
switch_tab_buttons: [Tab]^luigi.Button
input_textbox: ^luigi.Textbox
items_panel: ^luigi.Panel

CHECK_MARK :: "\x0f"
TAB_NAMES :: [Tab]string {
	.All       = "All",
	.Active    = "Active",
	.Completed = "Completed",
}

item_index :: proc(element: ^luigi.Element) -> int { return int(uintptr(element.user_data)) }

edit_item_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Clicked {
		// Move the item's text back into the textbox and remove the item.
		index := item_index(element)
		luigi.textbox_clear(input_textbox, false)
		luigi.textbox_replace(input_textbox, items[index].text, false)
		delete(items[index].text)
		ordered_remove(&items, index)
		// The rows after it hold stale indices, so rebuild the list.
		switch_tab(tab)
		luigi.element_refresh(&input_textbox.element)
	}
	return 0
}

check_item_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Clicked {
		// Toggle the item, and remove its row if the tab no longer shows it.
		item := &items[item_index(element)]
		item.completed = !item.completed
		button := (^luigi.Button)(element)
		delete(button.label)
		button.label = strings.clone(CHECK_MARK if item.completed else " ")
		luigi.element_refresh(element)
		if (item.completed && tab == .Active) || (!item.completed && tab == .Completed) {
			luigi.element_destroy(element.parent)
			luigi.element_refresh(&items_panel.element)
		}
	}
	return 0
}

add_item :: proc(index: int) {
	// A row with a check button, an edit button, and the item's text.
	row := luigi.panel_create(&items_panel.element, {.Horizontal, .Medium_Spacing})
	row.flags += {.H_Fill}
	luigi.element_parent_push(&row.element)
	check := luigi.button_create(nil, CHECK_MARK if items[index].completed else " ", {.Small})
	check.user_data = rawptr(uintptr(index))
	check.message_user = check_item_message
	edit := luigi.button_create(nil, "edit", {.Small})
	edit.user_data = rawptr(uintptr(index))
	edit.message_user = edit_item_message
	luigi.label_create(nil, items[index].text, {.H_Fill})
	luigi.element_parent_pop()
	luigi.element_refresh(&items_panel.element)
}

switch_tab :: proc(target: Tab) {
	// Replace the rows with the target tab's items and check its button.
	tab = target
	luigi.element_destroy_descendents(&items_panel.element)
	for item, index in items {
		if tab == .Completed && !item.completed { continue }
		if tab == .Active && item.completed { continue }
		add_item(index)
	}
	luigi.element_refresh(&items_panel.element)
	for button, button_tab in switch_tab_buttons {
		if button_tab == tab {
			button.button_flags += {.Checked}
		} else {
			button.button_flags -= {.Checked}
		}
		luigi.element_refresh(&button.element)
	}
}

switch_tab_invoke :: proc(user_data: rawptr) { switch_tab(Tab(uintptr(user_data))) }

input_textbox_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Key_Typed && (^luigi.Key_Typed)(payload).code == SDL.K_RETURN && len(input_textbox.text) > 0 {
		append(&items, Item{text = strings.clone(string(input_textbox.text[:]))})
		luigi.textbox_clear(input_textbox, false)
		luigi.element_refresh(&input_textbox.element)
		// Show the new item, scrolled to the bottom.
		if tab == .Completed { switch_tab(.All) }
		items_panel.scroll_bar.position = 1e10
		add_item(len(items) - 1)
		return 1
	}
	return 0
}

main :: proc() {
	luigi.ui_initialize()
	defer luigi.ui_shutdown()
	defer {
		for item in items { delete(item.text) }
		delete(items)
	}
	window := luigi.window_create("To-do List", 420, 480)
	luigi.element_parent_push(&window.element)
	root := luigi.panel_create(nil, {.Medium_Spacing, .Gray})
	luigi.element_parent_push(&root.element)

	// The task insertion row.
	insert := luigi.panel_create(nil, {.Horizontal, .Medium_Spacing, .Gray})
	insert.flags += {.H_Fill}
	luigi.element_parent_push(&insert.element)
	luigi.label_create(nil, "Task:")
	input_textbox = luigi.textbox_create(nil)
	input_textbox.message_user = input_textbox_message
	luigi.element_parent_pop()

	// The tab buttons.
	tabs := luigi.panel_create(nil, {.Horizontal, .Medium_Spacing, .Gray})
	tabs.flags += {.H_Fill}
	luigi.element_parent_push(&tabs.element)
	for name, target in TAB_NAMES {
		button := luigi.button_create(nil, name)
		button.invoke = switch_tab_invoke
		button.user_data = rawptr(uintptr(target))
		switch_tab_buttons[target] = button
	}
	luigi.element_parent_pop()

	// The items, refilled by switch_tab.
	items_panel = luigi.panel_create(nil, {.White, .Medium_Spacing, .Scroll})
	items_panel.flags += {.H_Fill, .V_Fill}

	switch_tab(.All)
	luigi.element_refresh(&window.element)
	luigi.ui_message_loop()
}
