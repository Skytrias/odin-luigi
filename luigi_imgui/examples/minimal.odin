package main

import luigi ".."

// The smallest useful Luigi program, from the walkthrough in the README,
// declared every frame. From the repository root:
//     odin run luigi_imgui/examples/minimal.odin -file

main :: proc() {
	luigi.ui_initialize()
	defer luigi.ui_shutdown()

	color := luigi.Color_HSV {
		value   = 1,
		opacity = 1,
	}
	position: f32
	text: [dynamic]u8
	defer delete(text)

	for luigi.ui_frame_begin() {
		window := luigi.window_create("My First Application", 640, 480)
		panel := luigi.panel_create(&window.element, {.Gray, .Medium_Spacing})
		if luigi.button(&panel.element, "Push") {
			color.saturation = 0
			color.value = 1
		}
		luigi.color_picker_create(&panel.element, &color)
		luigi.gauge_create(&panel.element, position)
		luigi.slider(&panel.element, &position)
		luigi.spacer_create(&panel.element, 0, 20)
		luigi.label_create(&panel.element, string(text[:]) if len(text) > 0 else "Label")
		luigi.textbox(&panel.element, &text)
		luigi.ui_frame_end()
	}
}
