package main

import luigi ".."

// The smallest useful Luigi program, from the walkthrough in the README. From
// the repository root:
//     odin run luigi_rmgui/examples/minimal.odin -file

color_picker: ^luigi.Color_Picker
gauge: ^luigi.Gauge
slider: ^luigi.Slider
label: ^luigi.Label
textbox: ^luigi.Textbox

main :: proc() {
	luigi.ui_initialize()
	defer luigi.ui_shutdown()
	window := luigi.window_create("My First Application", 640, 480)

	panel := luigi.panel_create(&window.element, {.Gray, .Medium_Spacing})
	button := luigi.button_create(&panel.element, "Push")
	color_picker = luigi.color_picker_create(&panel.element)
	gauge = luigi.gauge_create(&panel.element)
	slider = luigi.slider_create(&panel.element)
	luigi.spacer_create(&panel.element, 0, 20)
	label = luigi.label_create(&panel.element, "Label")
	textbox = luigi.textbox_create(&panel.element)

	button.message_user = button_message
	slider.message_user = slider_message
	textbox.message_user = textbox_message

	luigi.element_refresh(&window.element)
	luigi.ui_message_loop()
}

button_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Clicked {
		color_picker.saturation = 0
		color_picker.value = 1
		luigi.element_refresh(&color_picker.element)
	}
	return 0
}

slider_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Value_Changed {
		gauge.position = slider.position
		luigi.element_refresh(&gauge.element)
	}
	return 0
}

textbox_message :: proc(element: ^luigi.Element, message: luigi.Message, data: int, payload: rawptr) -> int {
	if message == .Value_Changed {
		luigi.label_set_content(label, string(textbox.text[:]))
		// The label's width may have changed, so lay out its panel again.
		luigi.element_refresh(label.parent)
	}
	return 0
}
