package main

import luigi ".."
import "core:fmt"
import "core:strings"
import SDL "vendor:SDL3"

// A to-do list, after Luigi's todo_list_example.cpp, declared every frame.
// From the repository root:
//     odin run luigi_imgui/examples/todo.odin -file

Item :: struct {
	text:      string,
	completed: bool,
}

Tab :: enum {
	All,
	Active,
	Completed,
}

TAB_NAMES :: [Tab]string {
	.All       = "All",
	.Active    = "Active",
	.Completed = "Completed",
}

CHECK_MARK :: "\x0f"

main :: proc() {
	luigi.ui_initialize()
	defer luigi.ui_shutdown()

	items: [dynamic]Item
	input: [dynamic]u8
	tab: Tab
	defer {
		for item in items { delete(item.text) }
		delete(items)
		delete(input)
	}

	for luigi.ui_frame_begin() {
		window := luigi.window_create("To-do List", 420, 480)
		root := luigi.panel_create(&window.element, {.Medium_Spacing, .Gray})

		// The task insertion row. Enter is not used by the textbox, so it
		// reaches the window's shortcuts.
		insert := luigi.panel_create(&root.element, {.Horizontal, .Medium_Spacing, .Gray})
		insert.flags += {.H_Fill}
		luigi.label_create(&insert.element, "Task:")
		luigi.textbox(&insert.element, &input)
		added := false
		if luigi.window_shortcut(window, SDL.K_RETURN) && len(input) > 0 {
			append(&items, Item{text = strings.clone(string(input[:]))})
			clear(&input)
			if tab == .Completed { tab = .All }
			added = true
		}

		// The tab buttons.
		tabs := luigi.panel_create(&root.element, {.Horizontal, .Medium_Spacing, .Gray})
		tabs.flags += {.H_Fill}
		for name, target in TAB_NAMES {
			flags := luigi.Button_Flags{.Checked} if target == tab else {}
			if luigi.button(&tabs.element, name, flags) { tab = target }
		}

		// One row per visible item. Changes are applied after the loop.
		list := luigi.panel_create(&root.element, {.White, .Medium_Spacing, .Scroll})
		list.flags += {.H_Fill, .V_Fill}
		if added { list.scroll_bar.position = 1e10 }
		toggled, edited := -1, -1
		for item, index in items {
			if tab == .Completed && !item.completed { continue }
			if tab == .Active && item.completed { continue }
			row := luigi.panel_create(&list.element, {.Horizontal, .Medium_Spacing})
			row.flags += {.H_Fill}
			mark := CHECK_MARK if item.completed else " "
			if luigi.button(&row.element, fmt.tprintf("%s##check%d", mark, index), {.Small}) { toggled = index }
			if luigi.button(&row.element, fmt.tprintf("edit##%d", index), {.Small}) { edited = index }
			luigi.label_create(&row.element, item.text, {.H_Fill})
		}
		if toggled >= 0 { items[toggled].completed = !items[toggled].completed }
		if edited >= 0 {
			// Move the item's text back into the textbox and remove the item.
			clear(&input)
			append(&input, items[edited].text)
			delete(items[edited].text)
			ordered_remove(&items, edited)
		}

		luigi.ui_frame_end()
		free_all(context.temp_allocator)
	}
}
