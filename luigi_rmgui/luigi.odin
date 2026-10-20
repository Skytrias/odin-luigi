package luigi

import "core:math"
import "core:strings"
import SDL "vendor:SDL3"

// Luigi's software framebuffer and retained element/message model in Odin.
// Run the examples from the repository root:
//     odin run luigi_rmgui/examples/minimal.odin -file
//     odin run luigi_rmgui/examples/basics.odin -file

Message :: enum {
	Paint,
	Layout,
	Destroy,
	Update,
	Animate,
	Scrolled,
	Get_Width,
	Get_Height,
	Find_By_Point,
	Client_Parent,
	Input_Events_Start,
	Left_Down,
	Left_Up,
	Middle_Down,
	Middle_Up,
	Right_Down,
	Right_Up,
	Key_Typed,
	Mouse_Move,
	Mouse_Drag,
	Mouse_Wheel,
	Clicked,
	Get_Cursor,
	Pressed_Descendent,
	Input_Events_End,
	Value_Changed,
	Table_Get_Item,
	Code_Get_Margin_Color,
	Code_Decorate_Line,
	Window_Close,
	Tab_Selected,
	Window_Drop_Files,
	Window_Activate,
	User,
}
Cursor_Style :: enum int {
	Arrow,
	Text,
	Split_V,
	Split_H,
	Flipped_Arrow,
	Cross_Hair,
	Hand,
	Resize_Up,
	Resize_Left,
	Resize_Up_Right,
	Resize_Up_Left,
	Resize_Down,
	Resize_Right,
	Resize_Down_Right,
	Resize_Down_Left,
}

Element_Flags :: bit_set[Element_Flag;u32]
Element_Flag :: enum u32 {
	V_Fill = 16,
	H_Fill,
	Window,
	Parent_Push,
	Tab_Stop,
	Non_Client,
	Disabled,
	Hide = 29,
	Destroy,
	Destroy_Descendent,
}

Panel_Flags :: bit_set[Panel_Flag;u32]
Panel_Flag :: enum u32 {
	Horizontal = 0,
	Gray = 2,
	White,
	Expand,
	Medium_Spacing,
	Small_Spacing,
	Scroll,
	Border,
}

Button_Flags :: bit_set[Button_Flag;u32]
Button_Flag :: enum u32 {
	Small,
	Menu_Item,
	Can_Focus,
	Drop_Down,
	Checked = 15,
}

Rect :: struct {
	l, r, t, b: int,
}
rect :: proc(l, r, t, b: int) -> Rect { return {l, r, t, b} }
rect_size :: proc(width, height: int) -> Rect { return {0, width, 0, height} }
rect_inset :: proc(r: Rect, amount: int) -> Rect { return {r.l + amount, r.r - amount, r.t + amount, r.b - amount} }
rect_width :: proc(r: Rect) -> int { return r.r - r.l }
rect_height :: proc(r: Rect) -> int { return r.b - r.t }
rect_valid :: proc(r: Rect) -> bool { return r.r > r.l && r.b > r.t }
rect_contains :: proc(r: Rect, x, y: int) -> bool { return x >= r.l && x < r.r && y >= r.t && y < r.b }
rect_intersection :: proc(a, b: Rect) -> Rect {
	return {max(a.l, b.l), min(a.r, b.r), max(a.t, b.t), min(a.b, b.b)}
}
rect_bounding :: proc(a, b: Rect) -> Rect {
	return {min(a.l, b.l), max(a.r, b.r), min(a.t, b.t), max(a.b, b.b)}
}
rect_add :: proc(a, b: Rect) -> Rect { return {a.l + b.l, a.r + b.r, a.t + b.t, a.b + b.b} }
rect_translate :: proc(a, delta: Rect) -> Rect {
	return {a.l + delta.l, a.r + delta.l, a.t + delta.t, a.b + delta.t}
}
rect_equals :: proc(a, b: Rect) -> bool { return a == b }
measure_string_width :: proc(value: string) -> int { return len(value) * ui.active_font.glyph_width }
measure_string_height :: proc() -> int { return ui.active_font.glyph_height }

Theme :: struct {
	panel1, panel2, selected, border:                                       u32,
	text, text_disabled, text_selected:                                     u32,
	button_normal, button_hovered, button_pressed, button_disabled:         u32,
	textbox_normal, textbox_focused:                                        u32,
	code_focused, code_background, code_default, code_comment, code_string: u32,
	code_number, code_operator, code_preprocessor:                          u32,
}
Font :: struct {
	glyph_width, glyph_height: int,
}

classic_theme :: Theme {
	panel1            = 0xFFF0F0F0,
	panel2            = 0xFFFFFFFF,
	selected          = 0xFF94BEFE,
	border            = 0xFF404040,
	text              = 0xFF000000,
	text_disabled     = 0xFF404040,
	text_selected     = 0xFF000000,
	button_normal     = 0xFFE0E0E0,
	button_hovered    = 0xFFF0F0F0,
	button_pressed    = 0xFFA0A0A0,
	button_disabled   = 0xFFF0F0F0,
	textbox_normal    = 0xFFF8F8F8,
	textbox_focused   = 0xFFFFFFFF,
	code_focused      = 0xFFE0E0E0,
	code_background   = 0xFFFFFFFF,
	code_default      = 0xFF000000,
	code_comment      = 0xFFA11F20,
	code_string       = 0xFF037E01,
	code_number       = 0xFF213EF1,
	code_operator     = 0xFF7F0480,
	code_preprocessor = 0xFF545D70,
}

Painter :: struct {
	clip:          Rect,
	bits:          []u32,
	width, height: int,
}
String_Selection :: struct {
	carets:                       [2]int,
	color_text, color_background: u32,
}

Element :: struct {
	flags:                       Element_Flags,
	id:                          u32,
	parent, next, children:      ^Element,
	window:                      ^Window,
	bounds, clip:                Rect,
	user_data:                   rawptr,
	message_class, message_user: Message_Handler,
	class_name:                  string,
}
Message_Handler :: proc(element: ^Element, message: Message, data: int, payload: rawptr) -> int
Find_By_Point :: struct {
	x, y:   int,
	result: ^Element,
}
Key_Typed :: struct {
	text:             string,
	code:             SDL.Keycode,
	ctrl, shift, alt: bool,
}
Drop_Files :: struct {
	paths: []string,
}
Shortcut :: struct {
	code:             SDL.Keycode,
	ctrl, shift, alt: bool,
	invoke:           proc(user_data: rawptr),
	user_data:        rawptr,
}

Window :: struct {
	using element:             Element,
	owner:                     ^Window,
	bits:                      []u32,
	width, height:             int,
	texture:                   ^SDL.Texture,
	renderer:                  ^SDL.Renderer,
	sdl_window:                ^SDL.Window,
	sdl_id:                    SDL.WindowID,
	hovered, pressed, focused: ^Element,
	pressed_button:            u8,
	cursor_x, cursor_y:        int,
	cursor_style:              Cursor_Style,
	ctrl, shift, alt:          bool,
	update_region:             Rect,
	next_window:               ^Window,
	shortcuts:                 [dynamic]Shortcut,
	is_menu:                   bool,
	is_dialog:                 bool,
	drop_paths:                [dynamic]string,
}
Panel :: struct {
	using element: Element,
	border:        Rect,
	gap:           int,
	panel_flags:   Panel_Flags,
	scroll_bar:    ^Scroll_Bar,
}
Button :: struct {
	using element: Element,
	label:         string,
	button_flags:  Button_Flags,
	invoke:        proc(user_data: rawptr),
}
Label :: struct {
	using element: Element,
	text:          string,
}
Checkbox :: struct {
	using element: Element,
	label:         string,
	checked:       bool,
	invoke:        proc(user_data: rawptr),
}
Gauge :: struct {
	using element: Element,
	position:      f32,
}
Slider :: struct {
	using element: Element,
	position:      f32,
	steps:         int,
}
Split_Pane :: struct {
	using element: Element,
	vertical:      bool,
	weight:        f32,
}
Tab_Pane :: struct {
	using element: Element,
	tabs:          [dynamic]string,
	tabs_storage:  string,
	active:        int,
}
Spacer :: struct {
	using element: Element,
	width, height: int,
	line:          bool,
}
Scroll_Bar :: struct {
	using element:        Element,
	maximum, page:        int,
	position:             f64,
	horizontal, dragging: bool,
	drag_offset:          int,
	repeat_direction:     int,
	repeat_last_ms:       u64,
}
Textbox :: struct {
	using element: Element,
	text:          [dynamic]u8,
	carets:        [2]int,
	scroll:        int,
}
Table_Get_Item :: struct {
	index, column: int,
	text:          string,
	selected:      bool,
}
Table :: struct {
	using element:    Element,
	item_count:       int,
	columns:          [dynamic]string,
	columns_storage:  string,
	column_widths:    [dynamic]int,
	column_highlight: int,
	v_scroll:         ^Scroll_Bar,
}
Code_Line :: struct {
	offset, bytes: int,
}
Code_Decorate_Line :: struct {
	bounds:      Rect,
	index, x, y: int,
	painter:     ^Painter,
}
Code :: struct {
	using element: Element,
	content:       [dynamic]u8,
	lines:         [dynamic]Code_Line,
	v_scroll:      ^Scroll_Bar,
	focused:       int,
	tab_size:      int,
	no_margin:     bool,
}
Color_Picker :: struct {
	using element:                   Element,
	hue, saturation, value, opacity: f32,
	has_opacity:                     bool,
}
Image_Display :: struct {
	using element:          Element,
	bits:                   []u32,
	width, height:          int,
	pan_x, pan_y, zoom:     f32,
	interactive, fit:       bool,
	previous_x, previous_y: int,
}
Wrap_Panel :: struct {
	using element: Element,
}
Expand_Pane :: struct {
	using element: Element,
	button:        ^Button,
	panel:         ^Panel,
	expanded:      bool,
}
MDI_Client :: struct {
	using element: Element,
	active:        ^MDI_Child,
	transparent:   bool,
	cascade:       int,
}
MDI_Child :: struct {
	using element:               Element,
	frame:                       Rect,
	title:                       string,
	close_button:                bool,
	dragging, resizing, closing: bool,
	resize_edges:                u8,
	drag_x, drag_y:              int,
	start_frame:                 Rect,
}
Menu :: struct {
	using panel:      Panel,
	owner:            ^Window,
	point_x, point_y: int,
	place_above:      bool,
}

State :: struct {
	windows:            ^Window,
	theme:              Theme,
	default_font:       ^Font,
	active_font:        ^Font,
	quit:               bool,
	next_id:            u32,
	parent_stack:       [16]^Element,
	parent_stack_count: int,
	animating:          [dynamic]^Element,
	cursors:            [15]^SDL.Cursor,
}
ui: State

ui_initialize :: proc() -> bool {
	ui = {
		theme = classic_theme,
	}
	if !SDL.Init(SDL.INIT_VIDEO) { return false }
	ui.default_font = font_create()
	ui.active_font = ui.default_font
	systems := [15]SDL.SystemCursor {
		.DEFAULT,
		.TEXT,
		.NS_RESIZE,
		.EW_RESIZE,
		.DEFAULT,
		.CROSSHAIR,
		.POINTER,
		.N_RESIZE,
		.W_RESIZE,
		.NE_RESIZE,
		.NW_RESIZE,
		.S_RESIZE,
		.E_RESIZE,
		.SE_RESIZE,
		.SW_RESIZE,
	}
	for cursor, index in systems { ui.cursors[index] = SDL.CreateSystemCursor(cursor) }
	return true
}

ui_shutdown :: proc() {
	for ui.windows != nil { window_destroy(ui.windows) }
	delete(ui.animating)
	if ui.default_font != nil { free(ui.default_font) }
	for cursor in ui.cursors {
		if cursor != nil {
			SDL.DestroyCursor(cursor)
		}
	}
	SDL.Quit()
	ui = {}
}

// Matches Luigi's default-font behavior without the optional UI_FREETYPE path.
font_create :: proc(path: string = "", size: u32 = 0) -> ^Font {
	font := new(Font)
	font.glyph_width, font.glyph_height = 9, 16
	return font
}
font_activate :: proc(font: ^Font) -> ^Font {
	previous := ui.active_font
	ui.active_font = font
	return previous
}

// Widgets own their allocated nodes until the containing window is destroyed.
element_create :: proc(
	$T: typeid,
	parent: ^Element,
	flags: Element_Flags,
	handler: Message_Handler,
	name: string,
) -> ^T {
	target_parent := parent
	node := new(T)
	e := (^Element)(node)
	ui.next_id += 1
	e.id = ui.next_id
	e.flags = flags
	e.message_class = handler
	e.class_name = name
	if target_parent == nil && .Window not_in flags && ui.parent_stack_count > 0 {
		target_parent = ui.parent_stack[ui.parent_stack_count - 1]
	}
	if target_parent != nil && .Non_Client not_in flags {
		client_parent := target_parent
		if element_message(target_parent, .Client_Parent, 0, &client_parent) != 0 { target_parent = client_parent }
	}
	if target_parent != nil {
		e.parent = target_parent
		e.window = target_parent.window
		if target_parent.children == nil {
			target_parent.children = e
		} else {
			last := target_parent.children
			for last.next != nil { last = last.next }
			last.next = e
		}
	}
	if .Parent_Push in flags { element_parent_push(e) }
	return node
}

element_parent_push :: proc(e: ^Element) {
	assert(ui.parent_stack_count < len(ui.parent_stack))
	ui.parent_stack[ui.parent_stack_count] = e
	ui.parent_stack_count += 1
}
element_parent_pop :: proc() -> ^Element {
	assert(ui.parent_stack_count > 0)
	ui.parent_stack_count -= 1
	return ui.parent_stack[ui.parent_stack_count]
}

element_change_parent :: proc(e, new_parent, insert_before: ^Element) {
	if e == nil || new_parent == nil || e.parent == nil { return }
	old_parent := e.parent
	link := &old_parent.children
	for link^ != nil && link^ != e { link = &link^.next }
	if link^ == e { link^ = e.next }
	link = &new_parent.children
	for link^ != nil && link^ != insert_before { link = &link^.next }
	e.next = link^
	link^ = e
	e.parent = new_parent
	element_set_window(e, new_parent.window)
	element_refresh(old_parent)
	element_refresh(new_parent)
}

element_set_window :: proc(e: ^Element, window: ^Window) {
	e.window = window
	for child := e.children; child != nil; child = child.next { element_set_window(child, window) }
}

element_destroy :: proc(e: ^Element) {
	if e == nil || .Destroy in e.flags { return }
	e.flags += {.Destroy}
	if e.parent != nil { element_repaint(e.parent) }
}

element_animate :: proc(e: ^Element, stop := false) -> bool {
	for item, index in ui.animating {
		if item == e {
			if stop { ordered_remove(&ui.animating, index) }
			return !stop
		}
	}
	if !stop {
		append(&ui.animating, e)
		return true
	}
	return false
}

animate_clock :: proc() -> u64 { return u64(SDL.GetTicks()) }

element_destroy_descendents :: proc(e: ^Element) {
	if e == nil { return }
	for child := e.children; child != nil; child = child.next {
		if .Non_Client not_in child.flags { element_destroy(child) }
	}
}

element_clear_window_references :: proc(e: ^Element) {
	w := e.window
	if w.hovered == e { w.hovered = &w.element }
	if w.pressed == e { w.pressed = nil }
	if w.focused == e { w.focused = nil }
	element_animate(e, true)
	for child := e.children; child != nil; child = child.next { element_clear_window_references(child) }
}

element_sweep_destroyed :: proc(parent: ^Element) {
	link := &parent.children
	for link^ != nil {
		child := link^
		if .Destroy in child.flags {
			link^ = child.next
			element_clear_window_references(child)
			element_free_tree(child)
		} else {
			element_sweep_destroyed(child)
			link = &child.next
		}
	}
}

element_message :: proc(e: ^Element, kind: Message, data: int = 0, payload: rawptr = nil) -> int {
	if e == nil || (kind != .Destroy && .Destroy in e.flags) { return 0 }
	if kind > .Input_Events_Start && kind < .Input_Events_End && .Disabled in e.flags { return 0 }
	if e.message_user != nil {
		result := e.message_user(e, kind, data, payload)
		if result != 0 { return result }
	}
	if e.message_class != nil { return e.message_class(e, kind, data, payload) }
	return 0
}

element_move :: proc(e: ^Element, bounds: Rect, always_layout := false) {
	old_bounds, old_clip := e.bounds, e.clip
	e.bounds = bounds
	e.clip = rect_intersection(e.parent.clip, bounds)
	if old_bounds != bounds || old_clip != e.clip || always_layout { element_message(e, .Layout) }
}

element_refresh :: proc(e: ^Element) {
	if e == nil { return }
	element_message(e, .Layout)
	element_repaint(e)
}
element_repaint :: proc(e: ^Element, region: ^Rect = nil) {
	if e == nil || e.window == nil { return }
	w := e.window
	area := e.clip
	if region != nil { area = rect_intersection(area, region^) }
	if !rect_valid(area) { return }
	if !rect_valid(w.update_region) {
		w.update_region = area
	} else {
		w.update_region = rect_bounding(w.update_region, area)
	}
}

element_focus :: proc(e: ^Element) {
	w := e.window
	if w.focused == e { return }
	previous := w.focused
	w.focused = e
	if previous != nil && previous.class_name == "Textbox" { _ = SDL.StopTextInput(w.sdl_window) }
	if e != nil && e.class_name == "Textbox" { _ = SDL.StartTextInput(w.sdl_window) }
	element_message(previous, .Update)
	element_message(e, .Update)
}

element_find_by_point :: proc(e: ^Element, x, y: int) -> ^Element {
	if e == nil || .Hide in e.flags || !rect_contains(e.clip, x, y) { return nil }
	probe := Find_By_Point {
		x = x,
		y = y,
	}
	if element_message(e, .Find_By_Point, 0, &probe) != 0 { return probe.result }
	result := e
	for child := e.children; child != nil; child = child.next {
		if found := element_find_by_point(child, x, y); found != nil { result = found }
	}
	return result
}

element_paint_tree :: proc(e: ^Element, painter: ^Painter) {
	if .Hide in e.flags { return }
	previous := painter.clip
	painter.clip = rect_intersection(previous, e.clip)
	if rect_valid(painter.clip) {
		element_message(e, .Paint, 0, painter)
		for child := e.children; child != nil; child = child.next { element_paint_tree(child, painter) }
	}
	painter.clip = previous
}

draw_block :: proc(painter: ^Painter, bounds: Rect, color: u32) {
	r := rect_intersection(bounds, painter.clip)
	if !rect_valid(r) { return }
	for y := r.t; y < r.b; y += 1 {
		for x := r.l; x < r.r; x += 1 { painter.bits[y * painter.width + x] = color }
	}
}
draw_rectangle :: proc(painter: ^Painter, bounds: Rect, fill, border: u32, thickness := 1) {
	draw_block(painter, bounds, border)
	draw_block(painter, rect_inset(bounds, thickness), fill)
}

draw_border :: proc(p: ^Painter, bounds: Rect, color: u32, size := 1) {
	draw_block(p, rect(bounds.l, bounds.r, bounds.t, bounds.t + size), color)
	draw_block(p, rect(bounds.l, bounds.r, bounds.b - size, bounds.b), color)
	draw_block(p, rect(bounds.l, bounds.l + size, bounds.t, bounds.b), color)
	draw_block(p, rect(bounds.r - size, bounds.r, bounds.t, bounds.b), color)
}

draw_invert :: proc(p: ^Painter, bounds: Rect) {
	r := rect_intersection(p.clip, bounds)
	for y := r.t; y < r.b; y += 1 {
		for x := r.l; x < r.r; x += 1 {
			index := y * p.width + x
			p.bits[index] = p.bits[index] ~ 0x00FFFFFF
		}
	}
}

draw_line :: proc(p: ^Painter, x0, y0, x1, y1: int, color: u32) -> bool {
	x, y := x0, y0
	dx, dy := abs(x1 - x0), -abs(y1 - y0)
	sx, sy := -1, -1
	if x0 < x1 { sx = 1 }
	if y0 < y1 { sy = 1 }
	error_value := dx + dy
	visible := false
	for {
		if rect_contains(p.clip, x, y) {
			p.bits[y * p.width + x] = color
			visible = true
		}
		if x == x1 && y == y1 { break }
		twice := 2 * error_value
		if twice >= dy {
			error_value += dy
			x += sx
		}
		if twice <= dx {
			error_value += dx
			y += sy
		}
	}
	return visible
}

draw_triangle_outline :: proc(p: ^Painter, x0, y0, x1, y1, x2, y2: int, color: u32) {
	_ = draw_line(p, x0, y0, x1, y1, color)
	_ = draw_line(p, x1, y1, x2, y2, color)
	_ = draw_line(p, x2, y2, x0, y0, color)
}

draw_triangle :: proc(p: ^Painter, x0, y0, x1, y1, x2, y2: int, color: u32) {
	r := rect_intersection(
		p.clip,
		rect(min(x0, min(x1, x2)), max(x0, max(x1, x2)) + 1, min(y0, min(y1, y2)), max(y0, max(y1, y2)) + 1),
	)
	if !rect_valid(r) { return }
	winding := (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
	if winding == 0 {
		draw_triangle_outline(p, x0, y0, x1, y1, x2, y2, color)
		return
	}
	for y := r.t; y < r.b; y += 1 {
		for x := r.l; x < r.r; x += 1 {
			a := (x1 - x0) * (y - y0) - (y1 - y0) * (x - x0)
			b := (x2 - x1) * (y - y1) - (y2 - y1) * (x - x1)
			c := (x0 - x2) * (y - y2) - (y0 - y2) * (x - x2)
			if (a >= 0 && b >= 0 && c >= 0) || (a <= 0 && b <= 0 && c <= 0) {
				p.bits[y * p.width + x] = color
			}
		}
	}
}

// Luigi's bundled 8x16 Code Page 437 bitmap font, copied from Luigi's luigi.h.
// odinfmt: disable
font_bitmap: [256]u64 = {
	0x0000000000000000, 0x0000000000000000, 0xBD8181A5817E0000, 0x000000007E818199, 0xC3FFFFDBFF7E0000, 0x000000007EFFFFE7, 0x7F7F7F3600000000, 0x00000000081C3E7F,
	0x7F3E1C0800000000, 0x0000000000081C3E, 0xE7E73C3C18000000, 0x000000003C1818E7, 0xFFFF7E3C18000000, 0x000000003C18187E, 0x3C18000000000000, 0x000000000000183C,
	0xC3E7FFFFFFFFFFFF, 0xFFFFFFFFFFFFE7C3, 0x42663C0000000000, 0x00000000003C6642, 0xBD99C3FFFFFFFFFF, 0xFFFFFFFFFFC399BD, 0x331E4C5870780000, 0x000000001E333333,
	0x3C666666663C0000, 0x0000000018187E18, 0x0C0C0CFCCCFC0000, 0x00000000070F0E0C, 0xC6C6C6FEC6FE0000, 0x0000000367E7E6C6, 0xE73CDB1818000000, 0x000000001818DB3C,
	0x1F7F1F0F07030100, 0x000000000103070F, 0x7C7F7C7870604000, 0x0000000040607078, 0x1818187E3C180000, 0x0000000000183C7E, 0x6666666666660000, 0x0000000066660066,
	0xD8DEDBDBDBFE0000, 0x00000000D8D8D8D8, 0x6363361C06633E00, 0x0000003E63301C36, 0x0000000000000000, 0x000000007F7F7F7F, 0x1818187E3C180000, 0x000000007E183C7E,
	0x1818187E3C180000, 0x0000000018181818, 0x1818181818180000, 0x00000000183C7E18, 0x7F30180000000000, 0x0000000000001830, 0x7F060C0000000000, 0x0000000000000C06,
	0x0303000000000000, 0x0000000000007F03, 0xFF66240000000000, 0x0000000000002466, 0x3E1C1C0800000000, 0x00000000007F7F3E, 0x3E3E7F7F00000000, 0x0000000000081C1C,
	0x0000000000000000, 0x0000000000000000, 0x18183C3C3C180000, 0x0000000018180018, 0x0000002466666600, 0x0000000000000000, 0x36367F3636000000, 0x0000000036367F36,
	0x603E0343633E1818, 0x000018183E636160, 0x1830634300000000, 0x000000006163060C, 0x3B6E1C36361C0000, 0x000000006E333333, 0x000000060C0C0C00, 0x0000000000000000,
	0x0C0C0C0C18300000, 0x0000000030180C0C, 0x30303030180C0000, 0x000000000C183030, 0xFF3C660000000000, 0x000000000000663C, 0x7E18180000000000, 0x0000000000001818,
	0x0000000000000000, 0x0000000C18181800, 0x7F00000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000018180000, 0x1830604000000000, 0x000000000103060C,
	0xDBDBC3C3663C0000, 0x000000003C66C3C3, 0x1818181E1C180000, 0x000000007E181818, 0x0C183060633E0000, 0x000000007F630306, 0x603C6060633E0000, 0x000000003E636060,
	0x7F33363C38300000, 0x0000000078303030, 0x603F0303037F0000, 0x000000003E636060, 0x633F0303061C0000, 0x000000003E636363, 0x18306060637F0000, 0x000000000C0C0C0C,
	0x633E6363633E0000, 0x000000003E636363, 0x607E6363633E0000, 0x000000001E306060, 0x0000181800000000, 0x0000000000181800, 0x0000181800000000, 0x000000000C181800,
	0x060C183060000000, 0x000000006030180C, 0x00007E0000000000, 0x000000000000007E, 0x6030180C06000000, 0x00000000060C1830, 0x18183063633E0000, 0x0000000018180018,
	0x7B7B63633E000000, 0x000000003E033B7B, 0x7F6363361C080000, 0x0000000063636363, 0x663E6666663F0000, 0x000000003F666666, 0x03030343663C0000, 0x000000003C664303,
	0x66666666361F0000, 0x000000001F366666, 0x161E1646667F0000, 0x000000007F664606, 0x161E1646667F0000, 0x000000000F060606, 0x7B030343663C0000, 0x000000005C666363,
	0x637F636363630000, 0x0000000063636363, 0x18181818183C0000, 0x000000003C181818, 0x3030303030780000, 0x000000001E333333, 0x1E1E366666670000, 0x0000000067666636,
	0x06060606060F0000, 0x000000007F664606, 0xC3DBFFFFE7C30000, 0x00000000C3C3C3C3, 0x737B7F6F67630000, 0x0000000063636363, 0x63636363633E0000, 0x000000003E636363,
	0x063E6666663F0000, 0x000000000F060606, 0x63636363633E0000, 0x000070303E7B6B63, 0x363E6666663F0000, 0x0000000067666666, 0x301C0663633E0000, 0x000000003E636360,
	0x18181899DBFF0000, 0x000000003C181818, 0x6363636363630000, 0x000000003E636363, 0xC3C3C3C3C3C30000, 0x00000000183C66C3, 0xDBC3C3C3C3C30000, 0x000000006666FFDB,
	0x18183C66C3C30000, 0x00000000C3C3663C, 0x183C66C3C3C30000, 0x000000003C181818, 0x0C183061C3FF0000, 0x00000000FFC38306, 0x0C0C0C0C0C3C0000, 0x000000003C0C0C0C,
	0x1C0E070301000000, 0x0000000040607038, 0x30303030303C0000, 0x000000003C303030, 0x0000000063361C08, 0x0000000000000000, 0x0000000000000000, 0x0000FF0000000000,
	0x0000000000180C0C, 0x0000000000000000, 0x3E301E0000000000, 0x000000006E333333, 0x66361E0606070000, 0x000000003E666666, 0x03633E0000000000, 0x000000003E630303,
	0x33363C3030380000, 0x000000006E333333, 0x7F633E0000000000, 0x000000003E630303, 0x060F0626361C0000, 0x000000000F060606, 0x33336E0000000000, 0x001E33303E333333,
	0x666E360606070000, 0x0000000067666666, 0x18181C0018180000, 0x000000003C181818, 0x6060700060600000, 0x003C666660606060, 0x1E36660606070000, 0x000000006766361E,
	0x18181818181C0000, 0x000000003C181818, 0xDBFF670000000000, 0x00000000DBDBDBDB, 0x66663B0000000000, 0x0000000066666666, 0x63633E0000000000, 0x000000003E636363,
	0x66663B0000000000, 0x000F06063E666666, 0x33336E0000000000, 0x007830303E333333, 0x666E3B0000000000, 0x000000000F060606, 0x06633E0000000000, 0x000000003E63301C,
	0x0C0C3F0C0C080000, 0x00000000386C0C0C, 0x3333330000000000, 0x000000006E333333, 0xC3C3C30000000000, 0x00000000183C66C3, 0xC3C3C30000000000, 0x0000000066FFDBDB,
	0x3C66C30000000000, 0x00000000C3663C18, 0x6363630000000000, 0x001F30607E636363, 0x18337F0000000000, 0x000000007F63060C, 0x180E181818700000, 0x0000000070181818,
	0x1800181818180000, 0x0000000018181818, 0x18701818180E0000, 0x000000000E181818, 0x000000003B6E0000, 0x0000000000000000, 0x63361C0800000000, 0x00000000007F6363,
}
// odinfmt: enable
draw_glyph :: proc(p: ^Painter, x0, y0: int, character: u8, color: u32) {
	c := int(character)
	if c > 127 { c = int('?') }
	r := rect_intersection(p.clip, rect(x0, x0 + 8, y0, y0 + 16))
	if !rect_valid(r) { return }
	for y := r.t; y < r.b; y += 1 {
		row := y - y0
		bits := u8(font_bitmap[c * 2 + row / 8] >> u64((row % 8) * 8))
		for x := r.l; x < r.r; x += 1 {
			if bits & (u8(1) << u8(x - x0)) != 0 { p.bits[y * p.width + x] = color }
		}
	}
}

Text_Align :: enum {
	Left,
	Right,
	Center,
}
draw_string :: proc(
	p: ^Painter,
	bounds: Rect,
	value: string,
	color: u32,
	align := Text_Align.Left,
	selection: ^String_Selection = nil,
) {
	old_clip := p.clip
	p.clip = rect_intersection(p.clip, bounds)
	if rect_valid(p.clip) {
		width := measure_string_width(value)
		glyph_width := ui.active_font.glyph_width
		x := bounds.l
		#partial switch align {
		case .Right:
			x = bounds.r - width
		case .Center:
			x = (bounds.l + bounds.r - width) / 2
		case:
		}
		y := (bounds.t + bounds.b - measure_string_height()) / 2
		for c, index in value {
			glyph_color := color
			if selection != nil &&
			   index >= min(selection.carets[0], selection.carets[1]) &&
			   index < max(selection.carets[0], selection.carets[1]) {
				draw_block(p, rect(x, x + glyph_width, bounds.t, bounds.b), selection.color_background)
				glyph_color = selection.color_text
			}
			draw_glyph(p, x, y, u8(c), glyph_color)
			x += glyph_width
		}
	}
	p.clip = old_clip
}

panel_measure :: proc(panel: ^Panel, horizontal: bool) -> int {
	result := 0
	for child := panel.children; child != nil; child = child.next {
		if .Hide in child.flags || .Non_Client in child.flags { continue }
		if horizontal {
			result = max(result, element_message(child, .Get_Height))
		} else {
			result = max(result, element_message(child, .Get_Width))
		}
	}
	if horizontal { return result + panel.border.t + panel.border.b }
	return result + panel.border.l + panel.border.r
}

panel_layout :: proc(panel: ^Panel, bounds: Rect, measure_only: bool) -> int {
	horizontal := .Horizontal in panel.panel_flags
	position := panel.border.t
	if !measure_only && panel.scroll_bar != nil && !horizontal { position -= int(panel.scroll_bar.position) }
	cross := rect_width(bounds) - panel.border.l - panel.border.r
	available := rect_height(bounds) - panel.border.t - panel.border.b
	if horizontal {
		position = panel.border.l
		cross = rect_height(bounds) - panel.border.t - panel.border.b
		available = rect_width(bounds) - panel.border.l - panel.border.r
	}
	fill, count := 0, 0
	for child := panel.children; child != nil; child = child.next {
		if .Hide in child.flags || .Non_Client in child.flags { continue }
		count += 1
		if horizontal {
			if .H_Fill in child.flags {
				fill += 1
			} else {
				available -= element_message(child, .Get_Width, cross)
			}
		} else {
			if .V_Fill in child.flags {
				fill += 1
			} else {
				available -= element_message(child, .Get_Height, cross)
			}
		}
	}
	available -= max(0, count - 1) * panel.gap
	per_fill := 0
	if fill > 0 { per_fill = max(0, available / fill) }
	for child := panel.children; child != nil; child = child.next {
		if .Hide in child.flags || .Non_Client in child.flags { continue }
		if horizontal {
			height := element_message(child, .Get_Height)
			if .V_Fill in child.flags || .Expand in panel.panel_flags { height = cross }
			width := element_message(child, .Get_Width, height)
			if .H_Fill in child.flags { width = per_fill }
			if !measure_only {
				top := bounds.t + panel.border.t + (cross - height) / 2
				element_move(child, rect(bounds.l + position, bounds.l + position + width, top, top + height))
			}
			position += width + panel.gap
		} else {
			width := element_message(child, .Get_Width)
			if .H_Fill in child.flags || .Expand in panel.panel_flags { width = cross }
			height := element_message(child, .Get_Height, width)
			if .V_Fill in child.flags { height = per_fill }
			if !measure_only {
				left := bounds.l + panel.border.l + (cross - width) / 2
				element_move(child, rect(left, left + width, bounds.t + position, bounds.t + position + height))
			}
			position += height + panel.gap
		}
	}
	if count > 0 { position -= panel.gap }
	if horizontal { return position + panel.border.r }
	return position + panel.border.b
}

panel_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	panel := (^Panel)(e)
	#partial switch kind {
	case .Layout:
		bounds := e.bounds
		if panel.scroll_bar != nil {
			bounds.r -= 16
			bar := panel.scroll_bar
			bar.maximum = panel_layout(panel, bounds, true)
			bar.page = rect_height(bounds)
			element_move(&bar.element, rect(bounds.r, e.bounds.r, bounds.t, bounds.b), true)
		}
		panel_layout(panel, bounds, false)
	case .Get_Width:
		if .Horizontal in panel.panel_flags { return panel_layout(panel, rect(0, 0, 0, data), true) }
		return panel_measure(panel, false)
	case .Get_Height:
		if .Horizontal in panel.panel_flags { return panel_measure(panel, true) }
		return panel_layout(panel, rect(0, data, 0, 0), true)
	case .Paint:
		p := (^Painter)(payload)
		if .Gray in panel.panel_flags { draw_block(p, e.bounds, ui.theme.panel1) }
		if .White in panel.panel_flags { draw_block(p, e.bounds, ui.theme.panel2) }
		if .Border in panel.panel_flags { draw_rectangle(p, e.bounds, ui.theme.panel1, ui.theme.border) }
	case .Mouse_Wheel:
		if panel.scroll_bar != nil { return element_message(&panel.scroll_bar.element, .Mouse_Wheel, data) }
	case .Scrolled:
		element_refresh(e)
	}
	return 0
}

panel_create :: proc(parent: ^Element, flags := Panel_Flags{}) -> ^Panel {
	panel := element_create(Panel, parent, {}, panel_message, "Panel")
	panel.panel_flags = flags
	if .Medium_Spacing in flags {
		panel.border = {5, 5, 5, 5}
		panel.gap = 5
	}
	if .Small_Spacing in flags {
		panel.border = {3, 3, 3, 3}
		panel.gap = 3
	}
	if .Scroll in flags { panel.scroll_bar = scroll_bar_create(&panel.element, false) }
	return panel
}

button_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	button := (^Button)(e)
	#partial switch kind {
	case .Get_Width:
		if .Menu_Item in button.button_flags { return max(160, len(button.label) * 9 + 18) }
		if .Small in button.button_flags { return len(button.label) * 9 + 16 }
		return max(100, len(button.label) * 9 + 16)
	case .Get_Height:
		if .Menu_Item in button.button_flags {
			return 24
		}
		return 27
	case .Paint:
		color := ui.theme.button_normal
		text_color := ui.theme.text
		if .Disabled in e.flags {
			color = ui.theme.button_disabled
			text_color = ui.theme.text_disabled
		} else if e == e.window.pressed && e == e.window.hovered {
			color = ui.theme.button_pressed
		} else if e == e.window.hovered || e == e.window.pressed {
			color = ui.theme.button_hovered
		}
		if .Menu_Item in button.button_flags {
			draw_block((^Painter)(payload), e.bounds, color)
			draw_string(
				(^Painter)(payload),
				rect(e.bounds.l + 9, e.bounds.r - 9, e.bounds.t, e.bounds.b),
				button.label,
				text_color,
			)
		} else {
			draw_rectangle((^Painter)(payload), e.bounds, color, ui.theme.border)
			if .Checked in button.button_flags {
				draw_block((^Painter)(payload), rect_inset(e.bounds, 4), ui.theme.button_pressed)
			}
			draw_string((^Painter)(payload), e.bounds, button.label, text_color, .Center)
		}
	case .Update:
		element_repaint(e)
	case .Clicked:
		if button.invoke != nil { button.invoke(e.user_data) }
	case .Left_Down:
		if .Can_Focus in button.button_flags { element_focus(e) }
	case .Key_Typed:
		key := (^Key_Typed)(payload)
		if key.code == SDL.K_SPACE || key.code == SDL.K_RETURN {
			element_message(e, .Clicked)
			return 1
		}
	case .Destroy:
		delete(button.label)
	}
	return 0
}

button_create :: proc(parent: ^Element, label: string, flags := Button_Flags{}) -> ^Button {
	button := element_create(Button, parent, {.Tab_Stop}, button_message, "Button")
	button.label = strings.clone(label)
	button.button_flags = flags
	return button
}

label_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	label := (^Label)(e)
	#partial switch kind {
	case .Get_Width:
		return len(label.text) * 9
	case .Get_Height:
		return 16
	case .Paint:
		draw_string((^Painter)(payload), e.bounds, label.text, ui.theme.text)
	case .Destroy:
		delete(label.text)
	}
	return 0
}
label_create :: proc(parent: ^Element, text: string, flags := Element_Flags{}) -> ^Label {
	label := element_create(Label, parent, flags, label_message, "Label")
	label.text = strings.clone(text)
	return label
}
label_set_content :: proc(label: ^Label, text: string) {
	delete(label.text)
	label.text = strings.clone(text)
	element_refresh(&label.element)
}

checkbox_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	box := (^Checkbox)(e)
	#partial switch kind {
	case .Get_Width:
		return len(box.label) * 9 + 22
	case .Get_Height:
		return 27
	case .Paint:
		p := (^Painter)(payload)
		mid := (e.bounds.t + e.bounds.b) / 2
		r := rect(e.bounds.l, e.bounds.l + 14, mid - 7, mid + 7)
		draw_rectangle(p, r, ui.theme.button_normal, ui.theme.border)
		if box.checked { draw_string(p, r, "*", ui.theme.text, .Center) }
		draw_string(p, rect(e.bounds.l + 22, e.bounds.r, e.bounds.t, e.bounds.b), box.label, ui.theme.text)
	case .Clicked:
		box.checked = !box.checked
		element_repaint(e)
		if box.invoke != nil { box.invoke(e.user_data) }
	case .Update:
		element_repaint(e)
	case .Key_Typed:
		key := (^Key_Typed)(payload)
		if key.code == SDL.K_SPACE {
			element_message(e, .Clicked)
			return 1
		}
	case .Destroy:
		delete(box.label)
	}
	return 0
}
checkbox_create :: proc(parent: ^Element, label: string) -> ^Checkbox {
	box := element_create(Checkbox, parent, {.Tab_Stop}, checkbox_message, "Checkbox")
	box.label = strings.clone(label)
	return box
}

gauge_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	gauge := (^Gauge)(e)
	#partial switch kind {
	case .Get_Width:
		return 200
	case .Get_Height:
		return 22
	case .Paint:
		p := (^Painter)(payload)
		draw_rectangle(p, e.bounds, ui.theme.button_normal, ui.theme.border)
		inner := rect_inset(e.bounds, 1)
		inner.r = inner.l + int(f32(rect_width(inner)) * math.clamp(gauge.position, 0, 1))
		draw_block(p, inner, ui.theme.selected)
	}
	return 0
}
gauge_create :: proc(parent: ^Element) -> ^Gauge { return element_create(Gauge, parent, {}, gauge_message, "Gauge") }

slider_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	slider := (^Slider)(e)
	#partial switch kind {
	case .Get_Width:
		return 200
	case .Get_Height:
		return 25
	case .Paint:
		p := (^Painter)(payload)
		middle := (e.bounds.t + e.bounds.b) / 2
		draw_rectangle(
			p,
			rect(e.bounds.l, e.bounds.r, middle - 2, middle + 3),
			ui.theme.button_normal,
			ui.theme.border,
		)
		left := e.bounds.l + int(f32(rect_width(e.bounds) - 15) * slider.position)
		color := ui.theme.button_normal
		if e == e.window.pressed {
			color = ui.theme.button_pressed
		} else if e == e.window.hovered {
			color = ui.theme.button_hovered
		}
		draw_rectangle(p, rect(left, left + 15, middle - 7, middle + 8), color, ui.theme.border)
	case .Left_Down, .Mouse_Drag:
		if kind == .Mouse_Drag && e.window.pressed_button != SDL.BUTTON_LEFT { break }
		span := max(1, rect_width(e.bounds) - 15)
		slider.position = math.clamp(f32(e.window.cursor_x - e.bounds.l - 7) / f32(span), 0, 1)
		if slider.steps > 1 {
			slider.position = f32(int(slider.position * f32(slider.steps - 1) + 0.5)) / f32(slider.steps - 1)
		}
		element_message(e, .Value_Changed)
		element_repaint(e)
	case .Update:
		element_repaint(e)
	}
	return 0
}
slider_create :: proc(parent: ^Element) -> ^Slider {
	return element_create(Slider, parent, {}, slider_message, "Slider")
}
window_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	#partial switch kind {
	case .Layout:
		for child := e.children; child != nil; child = child.next {
			if .Hide not_in child.flags { element_move(child, e.bounds) }
		}
	case .Paint:
		draw_block((^Painter)(payload), e.bounds, ui.theme.panel1)
	}
	return 0
}

window_resize :: proc(w: ^Window, width, height: int) {
	if width < 1 || height < 1 { return }
	w.width, w.height = width, height
	if w.texture != nil { SDL.DestroyTexture(w.texture) }
	if len(w.bits) > 0 { delete(w.bits) }
	w.bits = make([]u32, width * height)
	w.texture = SDL.CreateTexture(w.renderer, .ARGB8888, .STREAMING, i32(width), i32(height))
	if w.texture != nil { SDL.SetTextureScaleMode(w.texture, .NEAREST) }
	w.element.bounds = rect_size(width, height)
	w.element.clip = w.element.bounds
	element_message(&w.element, .Layout)
	w.update_region = w.element.bounds
}

window_create_with_flags :: proc(title: cstring, width, height: int, flags: SDL.WindowFlags) -> ^Window {
	w := element_create(Window, nil, {.Window}, window_message, "Window")
	w.element.window = w
	w.sdl_window = SDL.CreateWindow(title, i32(width), i32(height), flags)
	if w.sdl_window == nil {
		free(w)
		return nil
	}
	w.renderer = SDL.CreateRenderer(w.sdl_window, nil)
	if w.renderer == nil {
		SDL.DestroyWindow(w.sdl_window)
		free(w)
		return nil
	}
	w.sdl_id = SDL.GetWindowID(w.sdl_window)
	w.next_window = ui.windows
	ui.windows = w
	window_resize(w, width, height)
	return w
}

window_create :: proc(title: cstring, width := 800, height := 600) -> ^Window {
	return window_create_with_flags(title, width, height, SDL.WindowFlags{.RESIZABLE})
}

element_free_tree :: proc(e: ^Element) {
	child := e.children
	for child != nil {
		next := child.next
		element_free_tree(child)
		child = next
	}
	element_message(e, .Destroy)
	free(e)
}

window_destroy :: proc(w: ^Window) {
	element_clear_window_references(&w.element)
	link := &ui.windows
	for link^ != nil && link^ != w { link = &link^.next_window }
	if link^ == w { link^ = w.next_window }
	if w.texture != nil { SDL.DestroyTexture(w.texture) }
	if w.renderer != nil { SDL.DestroyRenderer(w.renderer) }
	if w.sdl_window != nil { SDL.DestroyWindow(w.sdl_window) }
	if len(w.bits) > 0 { delete(w.bits) }
	delete(w.shortcuts)
	for path in w.drop_paths { delete(path) }
	delete(w.drop_paths)
	element_free_tree(&w.element)
}

window_register_shortcut :: proc(w: ^Window, shortcut: Shortcut) { append(&w.shortcuts, shortcut) }

window_post_message :: proc(w: ^Window, kind: Message, payload: rawptr = nil) -> bool {
	event: SDL.Event
	event.user.type = .USER
	event.user.windowID = w.sdl_id
	event.user.code = i32(kind)
	event.user.data1 = payload
	return SDL.PushEvent(&event)
}

window_pack :: proc(w: ^Window, width: int) {
	child := w.element.children
	if child == nil { return }
	packed_width := width
	if packed_width <= 0 { packed_width = element_message(child, .Get_Width) }
	if packed_width <= 0 { return }
	height := element_message(child, .Get_Height, packed_width)
	if height > 0 { _ = SDL.SetWindowSize(w.sdl_window, i32(packed_width), i32(height)) }
}

element_screen_bounds :: proc(e: ^Element) -> Rect {
	x, y: i32
	_ = SDL.GetWindowPosition(e.window.sdl_window, &x, &y)
	return {e.bounds.l + int(x), e.bounds.r + int(x), e.bounds.t + int(y), e.bounds.b + int(y)}
}

window_present :: proc(w: ^Window) {
	if !rect_valid(w.update_region) || w.texture == nil { return }
	painter := Painter {
		clip   = w.element.bounds,
		bits   = w.bits,
		width  = w.width,
		height = w.height,
	}
	element_paint_tree(&w.element, &painter)
	SDL.UpdateTexture(w.texture, nil, raw_data(w.bits), i32(w.width * 4))
	SDL.RenderTexture(w.renderer, w.texture, nil, nil)
	SDL.RenderPresent(w.renderer)
	w.update_region = {}
}

window_from_id :: proc(id: SDL.WindowID) -> ^Window {
	for w := ui.windows; w != nil; w = w.next_window {
		if w.sdl_id == id {
			return w
		}
	}
	return nil
}

window_mouse_position :: proc(w: ^Window, x, y: f32) {
	w.cursor_x, w.cursor_y = int(x), int(y)
	hovered := element_find_by_point(&w.element, w.cursor_x, w.cursor_y)
	if hovered == nil { hovered = &w.element }
	if hovered != w.hovered {
		element_message(w.hovered, .Update)
		w.hovered = hovered
		element_message(w.hovered, .Update)
	}
	style := element_message(w.hovered, .Get_Cursor)
	if style >= 0 && style < len(ui.cursors) && style != int(w.cursor_style) {
		w.cursor_style = Cursor_Style(style)
		if ui.cursors[style] != nil { _ = SDL.SetCursor(ui.cursors[style]) }
	}
}

element_collect_tab_stops :: proc(e: ^Element, result: ^[dynamic]^Element) {
	if .Hide in e.flags || .Disabled in e.flags { return }
	if .Tab_Stop in e.flags { append(result, e) }
	for child := e.children; child != nil; child = child.next { element_collect_tab_stops(child, result) }
}

window_focus_next :: proc(w: ^Window, backwards: bool) {
	stops: [dynamic]^Element
	defer delete(stops)
	element_collect_tab_stops(&w.element, &stops)
	if len(stops) == 0 { return }
	index := -1
	for item, i in stops {
		if item == w.focused {
			index = i
			break
		}
	}
	if backwards {
		if index < 0 { index = 0 }
		index = (index - 1 + len(stops)) % len(stops)
	} else {
		index = (index + 1) % len(stops)
	}
	element_focus(stops[index])
}

window_key_typed :: proc(w: ^Window, typed: ^Key_Typed) {
	for e := w.focused; e != nil; e = e.parent {
		if element_message(e, .Key_Typed, 0, typed) != 0 { return }
	}
	if typed.code == SDL.K_TAB && !typed.ctrl && !typed.alt { window_focus_next(w, typed.shift) }
	for i := len(w.shortcuts) - 1; i >= 0; i -= 1 {
		shortcut := w.shortcuts[i]
		if shortcut.code == typed.code &&
		   shortcut.ctrl == typed.ctrl &&
		   shortcut.shift == typed.shift &&
		   shortcut.alt == typed.alt {
			if shortcut.invoke != nil { shortcut.invoke(shortcut.user_data) }
			return
		}
	}
}

ui_handle_event :: proc(event: ^SDL.Event) {
	#partial switch event.type {
	case .QUIT:
		ui.quit = true
	case .WINDOW_CLOSE_REQUESTED:
		w := window_from_id(event.window.windowID)
		if w != nil {
			if element_message(&w.element, .Window_Close) == 0 {
				if w.is_menu || w.is_dialog {
					element_destroy(&w.element)
				} else {
					ui.quit = true
				}
			}
		}
	case .WINDOW_RESIZED:
		w := window_from_id(event.window.windowID)
		if w != nil { window_resize(w, int(event.window.data1), int(event.window.data2)) }
	case .WINDOW_EXPOSED:
		w := window_from_id(event.window.windowID)
		if w != nil { element_repaint(&w.element) }
	case .WINDOW_FOCUS_GAINED:
		w := window_from_id(event.window.windowID)
		if w != nil { element_message(&w.element, .Window_Activate) }
	case .MOUSE_MOTION:
		w := window_from_id(event.motion.windowID)
		if w == nil { return }
		window_mouse_position(w, event.motion.x, event.motion.y)
		if w.pressed != nil {
			element_message(w.pressed, .Mouse_Drag)
		} else {
			element_message(w.hovered, .Mouse_Move)
		}
	case .MOUSE_BUTTON_DOWN:
		w := window_from_id(event.button.windowID)
		if w == nil { return }
		if !w.is_menu {
			for other := ui.windows; other != nil; other = other.next_window {
				if other.is_menu { element_destroy(&other.element) }
			}
		}
		window_mouse_position(w, event.button.x, event.button.y)
		w.pressed = w.hovered
		w.pressed_button = event.button.button
		element_message(w.pressed, .Update)
		for ancestor := w.pressed.parent; ancestor != nil; ancestor = ancestor.parent {
			element_message(ancestor, .Pressed_Descendent, 0, w.pressed)
		}
		switch event.button.button {
		case SDL.BUTTON_LEFT:
			element_message(w.pressed, .Left_Down)
		case SDL.BUTTON_MIDDLE:
			element_message(w.pressed, .Middle_Down)
		case SDL.BUTTON_RIGHT:
			element_message(w.pressed, .Right_Down)
		}
	case .MOUSE_BUTTON_UP:
		w := window_from_id(event.button.windowID)
		if w == nil { return }
		window_mouse_position(w, event.button.x, event.button.y)
		pressed := w.pressed
		if pressed == nil || w.pressed_button != event.button.button { return }
		if pressed == w.hovered && event.button.button == SDL.BUTTON_LEFT { element_message(pressed, .Clicked) }
		switch event.button.button {
		case SDL.BUTTON_LEFT:
			element_message(pressed, .Left_Up)
		case SDL.BUTTON_MIDDLE:
			element_message(pressed, .Middle_Up)
		case SDL.BUTTON_RIGHT:
			element_message(pressed, .Right_Up)
		}
		w.pressed = nil
		w.pressed_button = 0
		element_message(pressed, .Update)
	case .MOUSE_WHEEL:
		w := window_from_id(event.wheel.windowID)
		if w == nil { return }
		for e := w.hovered; e != nil; e = e.parent {
			if element_message(e, .Mouse_Wheel, int(event.wheel.y * 72)) != 0 { break }
		}
	case .DROP_FILE:
		w := window_from_id(event.drop.windowID)
		if w != nil && event.drop.data != nil {
			append(&w.drop_paths, strings.clone(string(event.drop.data)))
		}
		if event.drop.data != nil { SDL.free(rawptr(event.drop.data)) }
	case .DROP_COMPLETE:
		w := window_from_id(event.drop.windowID)
		if w != nil && len(w.drop_paths) > 0 {
			files := Drop_Files {
				paths = w.drop_paths[:],
			}
			element_message(&w.element, .Window_Drop_Files, len(files.paths), &files)
			for path in w.drop_paths { delete(path) }
			clear(&w.drop_paths)
		}
	case .KEY_DOWN:
		w := window_from_id(event.key.windowID)
		if w == nil { return }
		modifiers := event.key.mod
		w.ctrl = modifiers & (SDL.KMOD_CTRL | SDL.KMOD_GUI) != SDL.Keymod{}
		w.shift = modifiers & SDL.KMOD_SHIFT != SDL.Keymod{}
		w.alt = modifiers & SDL.KMOD_ALT != SDL.Keymod{}
		typed := Key_Typed {
			code  = event.key.key,
			ctrl  = w.ctrl,
			shift = w.shift,
			alt   = w.alt,
		}
		window_key_typed(w, &typed)
	case .KEY_UP:
		w := window_from_id(event.key.windowID)
		if w == nil { return }
		modifiers := event.key.mod
		w.ctrl = modifiers & (SDL.KMOD_CTRL | SDL.KMOD_GUI) != SDL.Keymod{}
		w.shift = modifiers & SDL.KMOD_SHIFT != SDL.Keymod{}
		w.alt = modifiers & SDL.KMOD_ALT != SDL.Keymod{}
	case .TEXT_INPUT:
		w := window_from_id(event.text.windowID)
		if w == nil { return }
		typed := Key_Typed {
			text = string(event.text.text),
		}
		window_key_typed(w, &typed)
	case .USER:
		w := window_from_id(event.user.windowID)
		if w != nil { element_message(&w.element, Message(event.user.code), 0, event.user.data1) }
	}
}

ui_pump_once :: proc() {
	event: SDL.Event
	if SDL.WaitEventTimeout(&event, 16) {
		ui_handle_event(&event)
		for SDL.PollEvent(&event) { ui_handle_event(&event) }
	}
	for i := 0; i < len(ui.animating); {
		e := ui.animating[i]
		element_message(e, .Animate)
		if i < len(ui.animating) && ui.animating[i] == e { i += 1 }
	}
	for w := ui.windows; w != nil; {
		next := w.next_window
		if .Destroy in w.element.flags {
			window_destroy(w)
		} else {
			element_sweep_destroyed(&w.element)
		}
		w = next
	}
	for w := ui.windows; w != nil; w = w.next_window { window_present(w) }
}

ui_message_loop :: proc() {
	for !ui.quit && ui.windows != nil { ui_pump_once() }
}

// Split panes reserve their first child for the splitter. Callers append two content children.
splitter_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	pane := (^Split_Pane)(e.parent)
	#partial switch kind {
	case .Paint:
		p := (^Painter)(payload)
		draw_rectangle(p, e.bounds, ui.theme.button_normal, ui.theme.border)
	case .Mouse_Drag:
		space := rect_width(pane.bounds) - 8
		cursor := e.window.cursor_x - pane.bounds.l - 4
		if pane.vertical {
			space = rect_height(pane.bounds) - 8
			cursor = e.window.cursor_y - pane.bounds.t - 4
		}
		if space > 0 { pane.weight = math.clamp(f32(cursor) / f32(space), 0.05, 0.95) }
		element_refresh(&pane.element)
	case .Get_Cursor:
		if pane.vertical {
			return int(Cursor_Style.Split_V)
		}
		return int(Cursor_Style.Split_H)
	case .Update:
		element_repaint(e)
	}
	return 0
}

split_pane_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	if kind != .Layout { return 0 }
	pane := (^Split_Pane)(e)
	splitter := e.children
	if splitter == nil || splitter.next == nil || splitter.next.next == nil { return 0 }
	first, second := splitter.next, splitter.next.next
	space := rect_width(e.bounds) - 8
	if pane.vertical { space = rect_height(e.bounds) - 8 }
	first_size := int(f32(max(0, space)) * pane.weight)
	if pane.vertical {
		element_move(first, rect(e.bounds.l, e.bounds.r, e.bounds.t, e.bounds.t + first_size))
		element_move(splitter, rect(e.bounds.l, e.bounds.r, e.bounds.t + first_size, e.bounds.t + first_size + 8))
		element_move(second, rect(e.bounds.l, e.bounds.r, e.bounds.t + first_size + 8, e.bounds.b))
	} else {
		element_move(first, rect(e.bounds.l, e.bounds.l + first_size, e.bounds.t, e.bounds.b))
		element_move(splitter, rect(e.bounds.l + first_size, e.bounds.l + first_size + 8, e.bounds.t, e.bounds.b))
		element_move(second, rect(e.bounds.l + first_size + 8, e.bounds.r, e.bounds.t, e.bounds.b))
	}
	return 0
}

split_pane_create :: proc(parent: ^Element, vertical: bool, weight: f32) -> ^Split_Pane {
	pane := element_create(Split_Pane, parent, {}, split_pane_message, "Split Pane")
	pane.vertical = vertical
	pane.weight = math.clamp(weight, 0.05, 0.95)
	element_create(Element, &pane.element, {.Non_Client}, splitter_message, "Splitter")
	return pane
}

tab_pane_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	pane := (^Tab_Pane)(e)
	#partial switch kind {
	case .Layout:
		index := 0
		content := e.bounds
		content.t += 27
		for child := e.children; child != nil; child = child.next {
			if index == pane.active {
				child.flags -= {.Hide}
				element_move(child, content)
				element_message(child, .Tab_Selected)
			} else {
				child.flags += {.Hide}
			}
			index += 1
		}
	case .Get_Height:
		index := 0
		for child := e.children; child != nil; child = child.next {
			if index == pane.active { return 27 + element_message(child, .Get_Height, data) }
			index += 1
		}
		return 27
	case .Get_Width:
		index := 0
		for child := e.children; child != nil; child = child.next {
			if index == pane.active { return element_message(child, .Get_Width, data) }
			index += 1
		}
	case .Paint:
		p := (^Painter)(payload)
		strip := rect(e.bounds.l, e.bounds.r, e.bounds.t, e.bounds.t + 27)
		draw_rectangle(p, strip, ui.theme.panel1, ui.theme.border)
		x := e.bounds.l + 4
		for title, index in pane.tabs {
			width := len(title) * 9 + 16
			color := ui.theme.button_normal
			if index == pane.active { color = ui.theme.button_pressed }
			button := rect(x, x + width, strip.t + 2, strip.b)
			draw_rectangle(p, button, color, ui.theme.border)
			draw_string(p, button, title, ui.theme.text, .Center)
			x += width - 1
		}
	case .Left_Down:
		x := e.bounds.l + 4
		for title, index in pane.tabs {
			width := len(title) * 9 + 16
			if rect_contains(rect(x, x + width, e.bounds.t, e.bounds.t + 27), e.window.cursor_x, e.window.cursor_y) {
				if pane.active != index {
					pane.active = index
					element_refresh(e)
				}
				break
			}
			x += width - 1
		}
	case .Destroy:
		delete(pane.tabs)
		delete(pane.tabs_storage)
	}
	return 0
}

tab_pane_create :: proc(parent: ^Element, titles: string) -> ^Tab_Pane {
	pane := element_create(Tab_Pane, parent, {}, tab_pane_message, "Tab Pane")
	pane.tabs_storage = strings.clone(titles)
	owned_titles := pane.tabs_storage
	start := 0
	for c, index in owned_titles {
		if c == '\t' {
			append(&pane.tabs, owned_titles[start:index])
			start = index + 1
		}
	}
	append(&pane.tabs, owned_titles[start:])
	return pane
}

spacer_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	spacer := (^Spacer)(e)
	#partial switch kind {
	case .Get_Width:
		return spacer.width
	case .Get_Height:
		return spacer.height
	case .Paint:
		if spacer.line { draw_block((^Painter)(payload), e.bounds, ui.theme.border) }
	}
	return 0
}
spacer_create :: proc(parent: ^Element, width, height: int, line := false) -> ^Spacer {
	spacer := element_create(Spacer, parent, {}, spacer_message, "Spacer")
	spacer.width, spacer.height, spacer.line = width, height, line
	return spacer
}

scroll_bar_track :: proc(bar: ^Scroll_Bar) -> Rect {
	r := bar.bounds
	length := rect_height(r)
	if bar.horizontal { length = rect_width(r) }
	if length < 48 { return r }
	if bar.horizontal {
		r.l += 16
		r.r -= 16
	} else {
		r.t += 16
		r.b -= 16
	}
	return r
}

scroll_bar_thumb :: proc(bar: ^Scroll_Bar) -> Rect {
	r := scroll_bar_track(bar)
	length := rect_height(r)
	if bar.horizontal { length = rect_width(r) }
	if bar.maximum <= bar.page || bar.page <= 0 { return r }
	thumb_length := max(20, length * bar.page / bar.maximum)
	thumb_length = min(thumb_length, length)
	position := int(bar.position / f64(bar.maximum - bar.page) * f64(length - thumb_length))
	if bar.horizontal { return rect(r.l + position, r.l + position + thumb_length, r.t, r.b) }
	return rect(r.l, r.r, r.t + position, r.t + position + thumb_length)
}

scroll_bar_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	bar := (^Scroll_Bar)(e)
	#partial switch kind {
	case .Get_Width, .Get_Height:
		return 16
	case .Layout:
		bar.position = math.clamp(bar.position, 0, f64(max(0, bar.maximum - bar.page)))
	case .Paint:
		p := (^Painter)(payload)
		draw_block(p, e.bounds, ui.theme.panel1)
		if bar.maximum > bar.page {
			track := scroll_bar_track(bar)
			color := ui.theme.button_normal
			if e == e.window.pressed {
				color = ui.theme.button_pressed
			} else if e == e.window.hovered {
				color = ui.theme.button_hovered
			}
			draw_rectangle(p, scroll_bar_thumb(bar), color, ui.theme.border, 2)
			if track != e.bounds {
				first, last: Rect
				if bar.horizontal {
					first = rect(e.bounds.l, track.l, e.bounds.t, e.bounds.b)
					last = rect(track.r, e.bounds.r, e.bounds.t, e.bounds.b)
				} else {
					first = rect(e.bounds.l, e.bounds.r, e.bounds.t, track.t)
					last = rect(e.bounds.l, e.bounds.r, track.b, e.bounds.b)
				}
				draw_rectangle(p, first, ui.theme.panel2, ui.theme.border)
				draw_rectangle(p, last, ui.theme.panel2, ui.theme.border)
				if bar.horizontal {
					draw_glyph(p, first.l + 4, first.t, 27, ui.theme.text)
					draw_glyph(p, last.l + 4, last.t, 26, ui.theme.text)
				} else {
					draw_glyph(p, first.l + 4, first.t, 24, ui.theme.text)
					draw_glyph(p, last.l + 4, last.t, 25, ui.theme.text)
				}
			}
		}
	case .Left_Down:
		track := scroll_bar_track(bar)
		bar.repeat_direction = 0
		if track != e.bounds {
			cursor := e.window.cursor_y
			start, end := track.t, track.b
			if bar.horizontal {
				cursor = e.window.cursor_x
				start, end = track.l, track.r
			}
			if cursor < start { bar.repeat_direction = -1 }
			if cursor >= end { bar.repeat_direction = 1 }
			if bar.repeat_direction != 0 {
				bar.repeat_last_ms = animate_clock()
				element_animate(e)
				element_repaint(e)
				return 1
			}
		}
		thumb := scroll_bar_thumb(bar)
		cursor := e.window.cursor_y
		start := thumb.t
		if bar.horizontal {
			cursor = e.window.cursor_x
			start = thumb.l
		}
		if rect_contains(thumb, e.window.cursor_x, e.window.cursor_y) {
			bar.dragging = true
			bar.drag_offset = cursor - start
		} else {
			if cursor < start {
				bar.position -= f64(bar.page)
			} else {
				bar.position += f64(bar.page)
			}
			bar.position = math.clamp(bar.position, 0, f64(max(0, bar.maximum - bar.page)))
			element_message(e.parent, .Scrolled)
			element_repaint(e)
		}
	case .Mouse_Drag:
		if bar.dragging && bar.maximum > bar.page {
			thumb := scroll_bar_thumb(bar)
			track := scroll_bar_track(bar)
			length := rect_height(track) - rect_height(thumb)
			cursor := e.window.cursor_y - track.t
			if bar.horizontal {
				length = rect_width(track) - rect_width(thumb)
				cursor = e.window.cursor_x - track.l
			}
			if length > 0 {
				bar.position = math.clamp(
					f64(cursor - bar.drag_offset) / f64(length) * f64(bar.maximum - bar.page),
					0,
					f64(bar.maximum - bar.page),
				)
				element_message(e.parent, .Scrolled)
				element_repaint(e)
			}
		}
	case .Left_Up:
		bar.dragging = false
		bar.repeat_direction = 0
		element_animate(e, true)
	case .Animate:
		if bar.repeat_direction != 0 {
			now := animate_clock()
			delta := min(now - bar.repeat_last_ms, u64(100))
			bar.repeat_last_ms = now
			bar.position = math.clamp(
				bar.position + f64(bar.repeat_direction) * f64(bar.page) * 3 * f64(delta) / 1000,
				0,
				f64(max(0, bar.maximum - bar.page)),
			)
			element_message(e.parent, .Scrolled)
			element_repaint(e)
		}
	case .Mouse_Wheel:
		bar.position = math.clamp(bar.position - f64(data), 0, f64(max(0, bar.maximum - bar.page)))
		element_message(e.parent, .Scrolled)
		element_repaint(e)
		return 1
	case .Update:
		element_repaint(e)
	}
	return 0
}
scroll_bar_create :: proc(parent: ^Element, horizontal := false) -> ^Scroll_Bar {
	bar := element_create(Scroll_Bar, parent, {.Non_Client}, scroll_bar_message, "Scroll Bar")
	bar.horizontal = horizontal
	return bar
}

textbox_replace :: proc(box: ^Textbox, insertion: string, notify := true) {
	from := min(box.carets[0], box.carets[1])
	to := max(box.carets[0], box.carets[1])
	updated: [dynamic]u8
	for c in box.text[:from] { append(&updated, c) }
	append(&updated, insertion)
	for c in box.text[to:] { append(&updated, c) }
	delete(box.text)
	box.text = updated
	box.carets = {from + len(insertion), from + len(insertion)}
	if notify { element_message(&box.element, .Value_Changed) }
	element_repaint(&box.element)
}
textbox_clear :: proc(box: ^Textbox, notify := true) {
	box.carets = {0, len(box.text)}
	textbox_replace(box, "", notify)
}
textbox_move_caret :: proc(box: ^Textbox, backward, by_word: bool) {
	position := box.carets[0]
	if backward {
		if position > 0 { position -= 1 }
		if by_word {
			for position > 0 && box.text[position - 1] == ' ' { position -= 1 }
			for position > 0 && box.text[position - 1] != ' ' { position -= 1 }
		}
	} else {
		if position < len(box.text) { position += 1 }
		if by_word {
			for position < len(box.text) && box.text[position] != ' ' { position += 1 }
			for position < len(box.text) && box.text[position] == ' ' { position += 1 }
		}
	}
	box.carets[0] = position
}

textbox_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	box := (^Textbox)(e)
	#partial switch kind {
	case .Get_Width:
		return 200
	case .Get_Height:
		return 27
	case .Get_Cursor:
		return int(Cursor_Style.Text)
	case .Paint:
		p := (^Painter)(payload)
		focused := e.window.focused == e
		background := ui.theme.textbox_normal
		if focused { background = ui.theme.textbox_focused }
		if .Disabled in e.flags { background = ui.theme.button_disabled }
		draw_rectangle(p, e.bounds, background, ui.theme.border)
		inner := rect_inset(e.bounds, 3)
		caret_x := box.carets[0] * 9 - box.scroll
		if caret_x < 0 { box.scroll = box.carets[0] * 9 }
		if caret_x >= rect_width(inner) { box.scroll = box.carets[0] * 9 - rect_width(inner) + 1 }
		box.scroll = max(0, box.scroll)
		old_clip := p.clip
		p.clip = rect_intersection(p.clip, inner)
		select_from, select_to := min(box.carets[0], box.carets[1]), max(box.carets[0], box.carets[1])
		y := (inner.t + inner.b - 16) / 2
		for c, index in box.text {
			x := inner.l + index * 9 - box.scroll
			color := ui.theme.text
			if focused && index >= select_from && index < select_to {
				draw_block(p, rect(x, x + 9, inner.t, inner.b), ui.theme.selected)
				color = ui.theme.text_selected
			}
			draw_glyph(p, x, y, c, color)
		}
		if focused && select_from == select_to {
			x := inner.l + box.carets[0] * 9 - box.scroll
			draw_block(p, rect(x, x + 1, inner.t + 2, inner.b - 2), ui.theme.text)
		}
		p.clip = old_clip
	case .Left_Down:
		element_focus(e)
		inner := rect_inset(e.bounds, 3)
		position := (e.window.cursor_x - inner.l + box.scroll + 4) / 9
		box.carets = {min(max(position, 0), len(box.text)), min(max(position, 0), len(box.text))}
		element_repaint(e)
	case .Mouse_Drag:
		inner := rect_inset(e.bounds, 3)
		position := (e.window.cursor_x - inner.l + box.scroll + 4) / 9
		box.carets[0] = min(max(position, 0), len(box.text))
		element_repaint(e)
	case .Update:
		element_repaint(e)
	case .Destroy:
		delete(box.text)
	case .Key_Typed:
		key := (^Key_Typed)(payload)
		if key == nil { return 0 }
		switch key.code {
		case SDL.K_BACKSPACE, SDL.K_DELETE:
			if box.carets[0] == box.carets[1] {
				textbox_move_caret(box, key.code == SDL.K_BACKSPACE, key.ctrl)
			}
			textbox_replace(box, "")
			return 1
		case SDL.K_LEFT, SDL.K_RIGHT:
			textbox_move_caret(box, key.code == SDL.K_LEFT, key.ctrl)
			if !key.shift { box.carets[1] = box.carets[0] }
			element_repaint(e)
			return 1
		case SDL.K_HOME, SDL.K_END:
			if key.code == SDL.K_HOME {
				box.carets[0] = 0
			} else {
				box.carets[0] = len(box.text)
			}
			if !key.shift { box.carets[1] = box.carets[0] }
			element_repaint(e)
			return 1
		case SDL.K_A:
			if key.ctrl {
				box.carets = {len(box.text), 0}
				element_repaint(e)
				return 1
			}
		case SDL.K_C, SDL.K_X:
			if key.ctrl {
				from, to := min(box.carets[0], box.carets[1]), max(box.carets[0], box.carets[1])
				if from < to {
					copy := strings.clone_to_cstring(string(box.text[from:to]))
					SDL.SetClipboardText(copy)
					free(rawptr(copy))
					if key.code == SDL.K_X { textbox_replace(box, "") }
				}
				return 1
			}
		case SDL.K_V:
			if key.ctrl {
				copy := SDL.GetClipboardText()
				if copy != nil {
					textbox_replace(box, string(cstring(copy)))
					SDL.free(rawptr(copy))
				}
				return 1
			}
		}
		if len(key.text) > 0 && !key.ctrl && !key.alt && key.text[0] >= ' ' {
			textbox_replace(box, key.text)
			return 1
		}
	}
	return 0
}
textbox_create :: proc(parent: ^Element) -> ^Textbox {
	return element_create(Textbox, parent, {.Tab_Stop}, textbox_message, "Textbox")
}

table_hit_test :: proc(table: ^Table, x, y: int) -> int {
	e := &table.element
	if x < e.bounds.l || x >= e.bounds.r - 16 { return -1 }
	row_y := y - e.bounds.t - 26 + int(table.v_scroll.position)
	if row_y < 0 || row_y >= table.item_count * 20 { return -1 }
	return row_y / 20
}

table_header_hit_test :: proc(table: ^Table, x, y: int) -> int {
	if y < table.bounds.t || y >= table.bounds.t + 26 { return -1 }
	left := table.bounds.l + 20
	for width, index in table.column_widths {
		if x >= left && x < left + width { return index }
		left += width + 20
	}
	return -1
}

table_ensure_visible :: proc(table: ^Table, index: int) -> bool {
	if index < 0 || index >= table.item_count { return false }
	top := index * 20
	bottom := top + 20
	visible_top := int(table.v_scroll.position)
	visible_bottom := visible_top + table.v_scroll.page
	if top < visible_top {
		table.v_scroll.position = f64(top)
	} else if bottom > visible_bottom {
		table.v_scroll.position = f64(bottom - table.v_scroll.page)
	} else {
		return false
	}
	element_refresh(&table.element)
	return true
}

table_resize_columns :: proc(table: ^Table) {
	clear(&table.column_widths)
	for title, column in table.columns {
		longest := len(title) * 9
		// Sampling keeps large virtual tables cheap while preserving Luigi's measured columns.
		for row := 0; row < min(table.item_count, 256); row += 1 {
			item := Table_Get_Item {
				index  = row,
				column = column,
			}
			element_message(&table.element, .Table_Get_Item, 0, &item)
			longest = max(longest, len(item.text) * 9)
		}
		append(&table.column_widths, longest)
	}
	element_repaint(&table.element)
}

table_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	table := (^Table)(e)
	#partial switch kind {
	case .Layout:
		bar := table.v_scroll
		bar.maximum = table.item_count * 20
		bar.page = max(0, rect_height(e.bounds) - 26)
		element_move(&bar.element, rect(e.bounds.r - 16, e.bounds.r, e.bounds.t, e.bounds.b), true)
	case .Paint:
		p := (^Painter)(payload)
		content := rect(e.bounds.l, e.bounds.r - 16, e.bounds.t + 26, e.bounds.b)
		draw_block(p, content, ui.theme.panel2)
		old_clip := p.clip
		p.clip = rect_intersection(p.clip, content)
		first_row := int(table.v_scroll.position) / 20
		row_top := content.t - int(table.v_scroll.position) % 20
		hovered := table_hit_test(table, e.window.cursor_x, e.window.cursor_y)
		for row := first_row; row < table.item_count && row_top < content.b; row += 1 {
			bounds := rect(content.l, content.r, row_top, row_top + 20)
			selection := Table_Get_Item {
				index  = row,
				column = 0,
			}
			element_message(e, .Table_Get_Item, 0, &selection)
			text_color := ui.theme.text
			if selection.selected {
				draw_block(p, bounds, ui.theme.selected)
				text_color = ui.theme.text_selected
			} else if hovered == row {
				draw_block(p, bounds, ui.theme.button_hovered)
			}
			left := bounds.l + 20
			for width, column in table.column_widths {
				item := Table_Get_Item {
					index  = row,
					column = column,
				}
				if column == 0 {
					item = selection
				} else {
					element_message(e, .Table_Get_Item, 0, &item)
				}
				cell := rect(left, left + width, bounds.t, bounds.b)
				draw_string(p, cell, item.text, text_color)
				left += width + 20
			}
			row_top += 20
		}
		p.clip = old_clip
		header := rect(e.bounds.l, e.bounds.r - 16, e.bounds.t, e.bounds.t + 26)
		draw_rectangle(p, header, ui.theme.panel1, ui.theme.border)
		left := header.l + 20
		for title, column in table.columns {
			width := table.column_widths[column]
			cell := rect(left, left + width, header.t, header.b)
			draw_string(p, cell, title, ui.theme.text)
			if table.column_highlight == column { draw_invert(p, cell) }
			left += width + 20
		}
	case .Mouse_Move, .Update:
		element_repaint(e)
	case .Scrolled:
		element_repaint(e)
	case .Mouse_Wheel:
		return element_message(&table.v_scroll.element, .Mouse_Wheel, data)
	case .Destroy:
		delete(table.columns)
		delete(table.columns_storage)
		delete(table.column_widths)
	}
	return 0
}

table_create :: proc(parent: ^Element, columns: string) -> ^Table {
	table := element_create(Table, parent, {}, table_message, "Table")
	table.columns_storage = strings.clone(columns)
	owned_columns := table.columns_storage
	table.column_highlight = -1
	table.v_scroll = scroll_bar_create(&table.element, false)
	start := 0
	for c, index in owned_columns {
		if c == '\t' {
			append(&table.columns, owned_columns[start:index])
			start = index + 1
		}
	}
	append(&table.columns, owned_columns[start:])
	table_resize_columns(table)
	return table
}

code_hit_test :: proc(code: ^Code, x, y: int) -> int {
	if x < code.bounds.l || x >= code.bounds.r - 16 { return 0 }
	line_y := y - code.bounds.t + int(code.v_scroll.position)
	if line_y < 0 || line_y >= len(code.lines) * 16 { return 0 }
	line := line_y / 16 + 1
	if !code.no_margin && x < code.bounds.l + 45 + 4 { return -line }
	return line
}

code_focus_line :: proc(code: ^Code, index: int) {
	code.focused = index - 1
	if index > 0 {
		center := (index - 1) * 16 - rect_height(code.bounds) / 2 + 8
		code.v_scroll.position = f64(max(0, center))
	}
	element_refresh(&code.element)
}

code_insert_content :: proc(code: ^Code, content: string, replace := false) {
	if replace { clear(&code.content) }
	append(&code.content, content)
	clear(&code.lines)
	start := 0
	for c, index in code.content {
		if c == '\n' {
			append(&code.lines, Code_Line{start, index - start})
			start = index + 1
		}
	}
	if start < len(code.content) { append(&code.lines, Code_Line{start, len(code.content) - start}) }
	if !replace { code.v_scroll.position = f64(len(code.lines) * 16) }
	element_refresh(&code.element)
}

draw_string_highlighted :: proc(p: ^Painter, bounds: Rect, content: string, tab_size := 4) -> int {
	x := bounds.l
	y := (bounds.t + bounds.b - 16) / 2
	tabs := max(1, tab_size)
	in_string, in_char, in_comment := false, false, false
	preprocessor := false
	if len(content) > 0 && content[0] == '#' { preprocessor = true }
	column := 0
	for c, i in content {
		if i > 10000 { break }
		if c == '\t' {
			column += tabs - column % tabs
			x = bounds.l + column * 9
			continue
		}
		was_in_string, was_in_char := in_string, in_char
		color := ui.theme.code_default
		if preprocessor {
			color = ui.theme.code_preprocessor
		} else if in_comment {
			color = ui.theme.code_comment
		} else if in_string || in_char {
			color = ui.theme.code_string
		} else if c >= '0' && c <= '9' {
			color = ui.theme.code_number
		} else if c == '/' && i + 1 < len(content) && content[i + 1] == '/' {
			color = ui.theme.code_comment
			in_comment = true
		} else if c == '"' {
			color = ui.theme.code_string
			in_string = true
		} else if c == '\'' {
			color = ui.theme.code_string
			in_char = true
		} else if strings.contains_rune("+-*=<>&|!", c) {
			color = ui.theme.code_operator
		}
		draw_glyph(p, x, y, u8(c), color)
		if c == '"' && was_in_string && i > 0 && content[i - 1] != '\\' { in_string = false }
		if c == '\'' && was_in_char && i > 0 && content[i - 1] != '\\' { in_char = false }
		column += 1
		x += 9
	}
	return x
}

code_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	code := (^Code)(e)
	#partial switch kind {
	case .Layout:
		code.v_scroll.maximum = len(code.lines) * 16
		code.v_scroll.page = rect_height(e.bounds)
		element_move(&code.v_scroll.element, rect(e.bounds.r - 16, e.bounds.r, e.bounds.t, e.bounds.b), true)
	case .Paint:
		p := (^Painter)(payload)
		draw_block(p, e.bounds, ui.theme.code_background)
		content_bounds := rect(e.bounds.l, e.bounds.r - 16, e.bounds.t, e.bounds.b)
		old_clip := p.clip
		p.clip = rect_intersection(p.clip, content_bounds)
		start_line := int(code.v_scroll.position) / 16
		top := e.bounds.t - int(code.v_scroll.position) % 16
		for line := start_line; line < len(code.lines) && top < e.bounds.b; line += 1 {
			line_bounds := rect(e.bounds.l, e.bounds.r - 16, top, top + 16)
			text_bounds := line_bounds
			if !code.no_margin {
				margin := rect(e.bounds.l, e.bounds.l + 45, top, top + 16)
				margin_color := element_message(e, .Code_Get_Margin_Color, line + 1)
				if margin_color != 0 { draw_block(p, margin, u32(margin_color)) }
				// The fixed font keeps line numbers compact and aligned with the source.
				buffer: [16]u8
				number := line + 1
				length := 0
				for number > 0 {
					buffer[length] = u8(number % 10) + '0'
					number /= 10
					length += 1
				}
				for j := 0;
				    j < length / 2;
				    j += 1 { buffer[j], buffer[length - 1 - j] = buffer[length - 1 - j], buffer[j] }
				draw_string(p, margin, string(buffer[:length]), ui.theme.code_default, .Right)
				text_bounds.l += 45 + 9
			}
			if code.focused == line { draw_block(p, text_bounds, ui.theme.code_focused) }
			item := code.lines[line]
			x := draw_string_highlighted(
				p,
				text_bounds,
				string(code.content[item.offset:item.offset + item.bytes]),
				code.tab_size,
			)
			decoration := Code_Decorate_Line {
				bounds  = text_bounds,
				index   = line + 1,
				x       = x,
				y       = top,
				painter = p,
			}
			element_message(e, .Code_Decorate_Line, 0, &decoration)
			top += 16
		}
		p.clip = old_clip
	case .Mouse_Wheel:
		return element_message(&code.v_scroll.element, .Mouse_Wheel, data)
	case .Scrolled:
		element_repaint(e)
	case .Destroy:
		delete(code.content)
		delete(code.lines)
	}
	return 0
}

code_create :: proc(parent: ^Element, no_margin := false) -> ^Code {
	code := element_create(Code, parent, {}, code_message, "Code")
	code.no_margin = no_margin
	code.focused = -1
	code.tab_size = 4
	code.v_scroll = scroll_bar_create(&code.element, false)
	return code
}

color_to_hsv :: proc(rgb: u32) -> (hue, saturation, value: f32, chromatic: bool) {
	r := f32((rgb >> 16) & 0xff) / 255
	g := f32((rgb >> 8) & 0xff) / 255
	b := f32(rgb & 0xff) / 255
	maximum := max(r, max(g, b))
	minimum := min(r, min(g, b))
	difference := maximum - minimum
	value = maximum
	if difference == 0 { return 0, 0, value, false }
	saturation = difference / maximum
	if maximum == r {
		hue = (g - b) / difference
	} else if maximum == g {
		hue = (b - r) / difference + 2
	} else {
		hue = (r - g) / difference + 4
	}
	if hue < 0 { hue += 6 }
	return hue, saturation, value, true
}

color_to_rgb :: proc(hue, saturation, value: f32) -> u32 {
	h := hue
	for h < 0 { h += 6 }
	for h >= 6 { h -= 6 }
	c := value * saturation
	x := c * (1 - abs((h - f32(int(h / 2)) * 2) - 1))
	m := value - c
	r, g, b: f32
	if h < 1 {
		r, g, b = c, x, 0
	} else if h < 2 {
		r, g, b = x, c, 0
	} else if h < 3 {
		r, g, b = 0, c, x
	} else if h < 4 {
		r, g, b = 0, x, c
	} else if h < 5 {
		r, g, b = x, 0, c
	} else {
		r, g, b = c, 0, x
	}
	return 0xFF000000 | u32((r + m) * 255) << 16 | u32((g + m) * 255) << 8 | u32((b + m) * 255)
}

color_picker_circle_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	picker := (^Color_Picker)(e.parent)
	#partial switch kind {
	case .Get_Cursor:
		return int(Cursor_Style.Cross_Hair)
	case .Paint:
		p := (^Painter)(payload)
		bounds := rect_intersection(e.bounds, p.clip)
		center_x := f32(e.bounds.l + e.bounds.r) / 2
		center_y := f32(e.bounds.t + e.bounds.b) / 2
		radius := f32(min(rect_width(e.bounds), rect_height(e.bounds))) / 2
		if radius <= 0 { return 0 }
		for y := bounds.t; y < bounds.b; y += 1 {
			for x := bounds.l; x < bounds.r; x += 1 {
				dx, dy := (f32(x) - center_x) / radius, (f32(y) - center_y) / radius
				distance := math.sqrt(dx * dx + dy * dy)
				if distance > 1 { continue }
				hue := f32((math.atan2(dy, dx) + math.PI) * 3 / math.PI)
				p.bits[y * p.width + x] = color_to_rgb(hue, distance, picker.value)
			}
		}
		angle := f64(picker.hue) * math.PI / 3 - math.PI
		cx := int(center_x + f32(math.cos(angle)) * picker.saturation * radius)
		cy := int(center_y + f32(math.sin(angle)) * picker.saturation * radius)
		draw_invert(p, rect(cx - 1, cx + 2, e.bounds.t, e.bounds.b))
		draw_invert(p, rect(e.bounds.l, e.bounds.r, cy - 1, cy + 2))
	case .Left_Down, .Mouse_Drag:
		center_x := f32(e.bounds.l + e.bounds.r) / 2
		center_y := f32(e.bounds.t + e.bounds.b) / 2
		radius := f32(min(rect_width(e.bounds), rect_height(e.bounds))) / 2
		if radius <= 0 { return 0 }
		dx := (f32(e.window.cursor_x) - center_x) / radius
		dy := (f32(e.window.cursor_y) - center_y) / radius
		picker.hue = f32((math.atan2(dy, dx) + math.PI) * 3 / math.PI)
		picker.saturation = math.clamp(math.sqrt(dx * dx + dy * dy), 0, 1)
		element_message(&picker.element, .Value_Changed)
		element_repaint(&picker.element)
	}
	return 0
}

color_picker_slider_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	picker := (^Color_Picker)(e.parent)
	opacity := e.class_name == "Opacity Slider"
	#partial switch kind {
	case .Get_Cursor:
		return int(Cursor_Style.Cross_Hair)
	case .Paint:
		p := (^Painter)(payload)
		for y := max(e.bounds.t, p.clip.t); y < min(e.bounds.b, p.clip.b); y += 1 {
			value := 1 - f32(y - e.bounds.t) / f32(max(1, rect_height(e.bounds)))
			color := color_to_rgb(picker.hue, picker.saturation, value)
			if opacity {
				full := color_to_rgb(picker.hue, picker.saturation, picker.value)
				r := f32((full >> 16) & 0xff) * value + 128 * (1 - value)
				g := f32((full >> 8) & 0xff) * value + 128 * (1 - value)
				b := f32(full & 0xff) * value + 128 * (1 - value)
				color = 0xFF000000 | u32(r) << 16 | u32(g) << 8 | u32(b)
			}
			draw_block(p, rect(e.bounds.l, e.bounds.r, y, y + 1), color)
		}
		value := picker.value
		if opacity { value = picker.opacity }
		indicator := e.bounds.t + int((1 - value) * f32(rect_height(e.bounds)))
		draw_invert(p, rect(e.bounds.l, e.bounds.r, indicator - 1, indicator + 2))
	case .Left_Down, .Mouse_Drag:
		value := math.clamp(1 - f32(e.window.cursor_y - e.bounds.t) / f32(max(1, rect_height(e.bounds))), 0, 1)
		if opacity {
			picker.opacity = value
		} else {
			picker.value = value
		}
		element_message(&picker.element, .Value_Changed)
		element_repaint(&picker.element)
	}
	return 0
}

color_picker_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	picker := (^Color_Picker)(e)
	#partial switch kind {
	case .Get_Width:
		if picker.has_opacity {
			return 280
		}
		return 240
	case .Get_Height:
		return 200
	case .Layout:
		circle := e.children
		if circle == nil { return 0 }
		slider := circle.next
		if slider == nil { return 0 }
		gap, width := 5, 35
		right := e.bounds.r - width - gap
		if picker.has_opacity { right -= width + gap }
		element_move(circle, rect(e.bounds.l, right, e.bounds.t, e.bounds.b))
		element_move(slider, rect(right + gap, right + gap + width, e.bounds.t, e.bounds.b))
		if picker.has_opacity && slider.next != nil {
			element_move(slider.next, rect(e.bounds.r - width, e.bounds.r, e.bounds.t, e.bounds.b))
		}
	}
	return 0
}

color_picker_create :: proc(parent: ^Element, has_opacity := false) -> ^Color_Picker {
	picker := element_create(Color_Picker, parent, {}, color_picker_message, "Color Picker")
	picker.value, picker.opacity = 1, 1
	picker.has_opacity = has_opacity
	element_create(Element, &picker.element, {}, color_picker_circle_message, "Color Circle")
	element_create(Element, &picker.element, {}, color_picker_slider_message, "Value Slider")
	if has_opacity { element_create(Element, &picker.element, {}, color_picker_slider_message, "Opacity Slider") }
	return picker
}

image_display_update_viewport :: proc(display: ^Image_Display) {
	view_width, view_height := rect_width(display.bounds), rect_height(display.bounds)
	if display.width <= 0 || display.height <= 0 || view_width <= 0 || view_height <= 0 { return }
	minimum := min(1.0, min(f32(view_width) / f32(display.width), f32(view_height) / f32(display.height)))
	if display.fit || display.zoom < minimum {
		display.zoom = minimum
		display.fit = true
	}
	visible_width := f32(view_width) / display.zoom
	visible_height := f32(view_height) / display.zoom
	if visible_width >= f32(display.width) {
		display.pan_x = (f32(display.width) - visible_width) / 2
	} else {
		display.pan_x = math.clamp(display.pan_x, 0, f32(display.width) - visible_width)
	}
	if visible_height >= f32(display.height) {
		display.pan_y = (f32(display.height) - visible_height) / 2
	} else {
		display.pan_y = math.clamp(display.pan_y, 0, f32(display.height) - visible_height)
	}
}

image_display_set_content :: proc(display: ^Image_Display, bits: []u32, width, height: int, stride := 0) {
	if len(display.bits) > 0 { delete(display.bits) }
	display.bits = nil
	display.width, display.height = max(0, width), max(0, height)
	row_stride := stride
	if row_stride <= 0 { row_stride = width }
	if width > 0 && height > 0 && len(bits) >= (height - 1) * row_stride + width {
		display.bits = make([]u32, width * height)
		for y := 0;
		    y < height;
		    y += 1 { copy(display.bits[y * width:(y + 1) * width], bits[y * row_stride:y * row_stride + width]) }
	}
	display.fit = true
	image_display_update_viewport(display)
	element_repaint(&display.element)
}

image_display_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	display := (^Image_Display)(e)
	#partial switch kind {
	case .Get_Cursor:
		if display.interactive { return int(Cursor_Style.Hand) }
	case .Get_Width:
		return display.width
	case .Get_Height:
		return display.height
	case .Layout:
		image_display_update_viewport(display)
	case .Paint:
		p := (^Painter)(payload)
		draw_block(p, e.bounds, ui.theme.panel2)
		if len(display.bits) == 0 || display.zoom <= 0 { return 0 }
		r := rect_intersection(e.bounds, p.clip)
		for y := r.t; y < r.b; y += 1 {
			sy := int(display.pan_y + f32(y - e.bounds.t) / display.zoom)
			if sy < 0 || sy >= display.height { continue }
			for x := r.l; x < r.r; x += 1 {
				sx := int(display.pan_x + f32(x - e.bounds.l) / display.zoom)
				if sx >= 0 && sx < display.width { p.bits[y * p.width + x] = display.bits[sy * display.width + sx] }
			}
		}
	case .Mouse_Wheel:
		if !display.interactive { return 0 }
		old_world_x := display.pan_x + f32(e.window.cursor_x - e.bounds.l) / display.zoom
		old_world_y := display.pan_y + f32(e.window.cursor_y - e.bounds.t) / display.zoom
		factor := f32(1.2)
		if data < 0 { factor = 1 / factor }
		display.zoom = math.clamp(display.zoom * factor, 0.01, 64)
		display.fit = false
		display.pan_x = old_world_x - f32(e.window.cursor_x - e.bounds.l) / display.zoom
		display.pan_y = old_world_y - f32(e.window.cursor_y - e.bounds.t) / display.zoom
		image_display_update_viewport(display)
		element_repaint(e)
		return 1
	case .Left_Down:
		display.previous_x, display.previous_y = e.window.cursor_x, e.window.cursor_y
	case .Mouse_Drag:
		if display.interactive && e.window.pressed_button == SDL.BUTTON_LEFT {
			display.fit = false
			display.pan_x -= f32(e.window.cursor_x - display.previous_x) / display.zoom
			display.pan_y -= f32(e.window.cursor_y - display.previous_y) / display.zoom
			display.previous_x, display.previous_y = e.window.cursor_x, e.window.cursor_y
			image_display_update_viewport(display)
			element_repaint(e)
		}
	case .Destroy:
		if len(display.bits) > 0 { delete(display.bits) }
	}
	return 0
}
image_display_create :: proc(
	parent: ^Element,
	bits: []u32,
	width, height: int,
	interactive := false,
	stride := 0,
) -> ^Image_Display {
	display := element_create(Image_Display, parent, {}, image_display_message, "Image Display")
	display.interactive = interactive
	display.zoom = 1
	image_display_set_content(display, bits, width, height, stride)
	return display
}

wrap_panel_layout :: proc(panel: ^Wrap_Panel, available_width: int, measure_only: bool) -> int {
	limit := available_width
	if limit <= 0 { limit = 1 << 20 }
	x, y, row_height := 0, 0, 0
	for child := panel.children; child != nil; child = child.next {
		if .Hide in child.flags || .Non_Client in child.flags { continue }
		width := element_message(child, .Get_Width)
		height := element_message(child, .Get_Height, width)
		if x > 0 && x + width > limit {
			x = 0
			y += row_height
			row_height = 0
		}
		if !measure_only {
			left, top := panel.bounds.l + x, panel.bounds.t + y
			element_move(child, rect(left, left + width, top, top + height))
		}
		x += width
		row_height = max(row_height, height)
	}
	return y + row_height
}
wrap_panel_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	panel := (^Wrap_Panel)(e)
	#partial switch kind {
	case .Layout:
		wrap_panel_layout(panel, rect_width(e.bounds), false)
	case .Get_Height:
		return wrap_panel_layout(panel, data, true)
	case .Get_Width:
		width := 0
		for child := e.children; child != nil; child = child.next { width += element_message(child, .Get_Width) }
		return width
	}
	return 0
}
wrap_panel_create :: proc(parent: ^Element) -> ^Wrap_Panel {
	return element_create(Wrap_Panel, parent, {}, wrap_panel_message, "Wrap Panel")
}

expand_pane_toggle :: proc(user_data: rawptr) {
	pane := (^Expand_Pane)(user_data)
	pane.expanded = !pane.expanded
	for ancestor := &pane.element; ancestor != nil; ancestor = ancestor.parent {
		element_refresh(ancestor)
		if .V_Fill in ancestor.flags { break }
	}
}
expand_pane_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	pane := (^Expand_Pane)(e)
	#partial switch kind {
	case .Get_Width:
		return max(element_message(&pane.button.element, .Get_Width), element_message(&pane.panel.element, .Get_Width))
	case .Get_Height:
		height := element_message(&pane.button.element, .Get_Height)
		if pane.expanded { height += element_message(&pane.panel.element, .Get_Height, data) }
		return height
	case .Layout:
		button_height := element_message(&pane.button.element, .Get_Height)
		element_move(&pane.button.element, rect(e.bounds.l, e.bounds.r, e.bounds.t, e.bounds.t + button_height))
		if pane.expanded {
			pane.panel.flags -= {.Hide}
			element_move(&pane.panel.element, rect(e.bounds.l, e.bounds.r, e.bounds.t + button_height, e.bounds.b))
		} else {
			pane.panel.flags += {.Hide}
		}
	case .Client_Parent:
		client := (^^Element)(payload)
		client^ = &pane.panel.element
		return 1
	}
	return 0
}
expand_pane_create :: proc(parent: ^Element, label: string, panel_flags := Panel_Flags{}) -> ^Expand_Pane {
	pane := element_create(Expand_Pane, parent, {}, expand_pane_message, "Expand Pane")
	pane.button = element_create(Button, &pane.element, {.Non_Client, .Tab_Stop}, button_message, "Button")
	pane.button.label = strings.clone(label)
	pane.button.invoke = expand_pane_toggle
	pane.button.user_data = pane
	pane.panel = element_create(Panel, &pane.element, {.Non_Client}, panel_message, "Panel")
	pane.panel.panel_flags = panel_flags
	if .Medium_Spacing in panel_flags {
		pane.panel.border = {5, 5, 5, 5}
		pane.panel.gap = 5
	}
	if .Small_Spacing in panel_flags {
		pane.panel.border = {3, 3, 3, 3}
		pane.panel.gap = 3
	}
	if .Scroll in panel_flags { pane.panel.scroll_bar = scroll_bar_create(&pane.panel.element, false) }
	return pane
}

mdi_client_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	client := (^MDI_Client)(e)
	#partial switch kind {
	case .Paint:
		if !client.transparent { draw_block((^Painter)(payload), e.bounds, ui.theme.panel1) }
	case .Layout:
		for child := e.children; child != nil; child = child.next {
			mdi := (^MDI_Child)(child)
			frame := mdi.frame
			element_move(
				child,
				rect(e.bounds.l + frame.l, e.bounds.l + frame.r, e.bounds.t + frame.t, e.bounds.t + frame.b),
			)
		}
	}
	return 0
}
mdi_client_create :: proc(parent: ^Element, transparent := false) -> ^MDI_Client {
	client := element_create(MDI_Client, parent, {}, mdi_client_message, "MDI Client")
	client.transparent = transparent
	return client
}

mdi_child_hit_test :: proc(mdi: ^MDI_Child, x, y: int) -> u8 {
	r := mdi.bounds
	if !rect_contains(r, x, y) { return 0 }
	left := x < r.l + 12
	right := x >= r.r - 12
	top := y < r.t + 12
	bottom := y >= r.b - 12
	if left && top { return 10 }
	if right && top { return 6 }
	if left && bottom { return 9 }
	if right && bottom { return 5 }
	if x < r.l + 6 { return 8 }
	if x >= r.r - 6 { return 4 }
	if y < r.t + 6 { return 2 }
	if y >= r.b - 6 { return 1 }
	if y < r.t + 30 { return 15 }
	return 0
}

mdi_child_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	mdi := (^MDI_Child)(e)
	client := (^MDI_Client)(e.parent)
	#partial switch kind {
	case .Get_Cursor:
		switch mdi_child_hit_test(mdi, e.window.cursor_x, e.window.cursor_y) {
		case 8:
			return int(Cursor_Style.Resize_Left)
		case 2:
			return int(Cursor_Style.Resize_Up)
		case 6:
			return int(Cursor_Style.Resize_Up_Right)
		case 10:
			return int(Cursor_Style.Resize_Up_Left)
		case 4:
			return int(Cursor_Style.Resize_Right)
		case 1:
			return int(Cursor_Style.Resize_Down)
		case 9:
			return int(Cursor_Style.Resize_Down_Left)
		case 5:
			return int(Cursor_Style.Resize_Down_Right)
		}
	case .Layout:
		content := rect(e.bounds.l + 6, e.bounds.r - 6, e.bounds.t + 30, e.bounds.b - 6)
		for child := e.children; child != nil; child = child.next { element_move(child, content) }
	case .Paint:
		p := (^Painter)(payload)
		active := client.active == mdi
		border := ui.theme.border
		if active { border = ui.theme.selected }
		draw_rectangle(p, e.bounds, ui.theme.panel1, border, 6)
		title := rect(e.bounds.l + 6, e.bounds.r - 6, e.bounds.t + 6, e.bounds.t + 30)
		color := ui.theme.button_normal
		if active { color = ui.theme.button_hovered }
		draw_block(p, title, color)
		draw_string(p, rect(title.l + 6, title.r - 30, title.t, title.b), mdi.title, ui.theme.text)
		if mdi.close_button {
			close := rect(title.r - 24, title.r - 4, title.t + 2, title.b - 2)
			draw_rectangle(p, close, ui.theme.button_normal, ui.theme.border)
			draw_string(p, close, "x", ui.theme.text, .Center)
		}
	case .Left_Down, .Pressed_Descendent:
		if kind == .Pressed_Descendent {
			client.active = mdi
			if e.next != nil { element_change_parent(e, &client.element, nil) }
			element_repaint(&client.element)
			return 0
		}
		client.active = mdi
		if e.next != nil { element_change_parent(e, &client.element, nil) }
		mdi.drag_x, mdi.drag_y = e.window.cursor_x, e.window.cursor_y
		mdi.start_frame = mdi.frame
		mdi.closing = false
		mdi.dragging = false
		mdi.resizing = false
		mdi.resize_edges = 0
		close_bounds := rect(e.bounds.r - 30, e.bounds.r - 10, e.bounds.t + 8, e.bounds.t + 28)
		if mdi.close_button && rect_contains(close_bounds, mdi.drag_x, mdi.drag_y) {
			mdi.closing = true
		} else {
			hit := mdi_child_hit_test(mdi, mdi.drag_x, mdi.drag_y)
			if hit == 15 {
				mdi.dragging = true
			} else if hit != 0 {
				mdi.resizing = true
				mdi.resize_edges = hit
			}
		}
		element_repaint(&client.element)
	case .Mouse_Drag:
		dx := e.window.cursor_x - mdi.drag_x
		dy := e.window.cursor_y - mdi.drag_y
		if mdi.dragging {
			mdi.frame = {
				mdi.start_frame.l + dx,
				mdi.start_frame.r + dx,
				mdi.start_frame.t + dy,
				mdi.start_frame.b + dy,
			}
			element_refresh(&client.element)
		} else if mdi.resizing {
			if mdi.resize_edges & 8 != 0 { mdi.frame.l = min(mdi.start_frame.r - 100, mdi.start_frame.l + dx) }
			if mdi.resize_edges & 4 != 0 { mdi.frame.r = max(mdi.start_frame.l + 100, mdi.start_frame.r + dx) }
			if mdi.resize_edges & 2 != 0 { mdi.frame.t = min(mdi.start_frame.b - 50, mdi.start_frame.t + dy) }
			if mdi.resize_edges & 1 != 0 { mdi.frame.b = max(mdi.start_frame.t + 50, mdi.start_frame.b + dy) }
			element_refresh(&client.element)
		}
	case .Left_Up:
		if mdi.closing &&
		   rect_contains(
			   rect(e.bounds.r - 30, e.bounds.r - 10, e.bounds.t + 8, e.bounds.t + 28),
			   e.window.cursor_x,
			   e.window.cursor_y,
		   ) {
			if element_message(e, .Window_Close) == 0 { element_destroy(e) }
		}
		mdi.dragging, mdi.resizing, mdi.closing = false, false, false
		if mdi.frame.l < 0 {
			mdi.frame.r -= mdi.frame.l
			mdi.frame.l = 0
		}
		if mdi.frame.t < 0 {
			mdi.frame.b -= mdi.frame.t
			mdi.frame.t = 0
		}
		element_refresh(&client.element)
	case .Update:
		element_repaint(e)
	case .Destroy:
		if client.active == mdi { client.active = nil }
		delete(mdi.title)
	}
	return 0
}
mdi_child_create :: proc(client: ^MDI_Client, frame: Rect, title: string, close_button := true) -> ^MDI_Child {
	mdi := element_create(MDI_Child, &client.element, {}, mdi_child_message, "MDI Child")
	mdi.frame = frame
	mdi.title = strings.clone(title)
	mdi.close_button = close_button
	client.active = mdi
	return mdi
}

menu_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	if kind == .Key_Typed {
		key := (^Key_Typed)(payload)
		if key != nil && key.code == SDL.K_ESCAPE {
			element_destroy(&e.window.element)
			return 1
		}
	}
	return panel_message(e, kind, data, payload)
}
menu_item_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	if kind == .Clicked {
		button := (^Button)(e)
		if button.invoke != nil { button.invoke(e.user_data) }
		element_destroy(&e.window.element)
		return 1
	}
	return 0
}
menu_create :: proc(parent: ^Element, place_above := false) -> ^Menu {
	if parent == nil || parent.window == nil { return nil }
	owner := parent.window
	w := window_create_with_flags("", 1, 1, SDL.WindowFlags{.HIDDEN, .BORDERLESS, .ALWAYS_ON_TOP})
	if w == nil { return nil }
	w.is_menu = true
	w.owner = owner
	menu := element_create(Menu, &w.element, {}, menu_message, "Menu")
	menu.panel.panel_flags = {.White}
	menu.panel.border = {2, 2, 2, 2}
	menu.owner = owner
	menu.place_above = place_above
	bounds := element_screen_bounds(parent)
	menu.point_x = bounds.l
	menu.point_y = bounds.b - 1
	if parent.parent == nil {
		menu.point_x = bounds.l + owner.cursor_x
		menu.point_y = bounds.t + owner.cursor_y
	}
	if place_above { menu.point_y = bounds.t }
	return menu
}
menu_add_item :: proc(
	menu: ^Menu,
	label: string,
	invoke: proc(user_data: rawptr),
	user_data: rawptr = nil,
) -> ^Button {
	button := button_create(&menu.element, label, {.Menu_Item})
	button.invoke = invoke
	button.user_data = user_data
	button.message_user = menu_item_message
	return button
}
menu_show :: proc(menu: ^Menu) {
	if menu == nil { return }
	width := max(164, panel_measure(&menu.panel, false))
	height := panel_layout(&menu.panel, rect(0, width, 0, 0), true)
	height = max(4, height)
	w := menu.window
	display := SDL.GetDisplayForWindow(menu.owner.sdl_window)
	usable: SDL.Rect
	if SDL.GetDisplayUsableBounds(display, &usable) {
		limit := max(80, int(usable.h) - 32)
		if height > limit {
			height = limit
			menu.panel.scroll_bar = scroll_bar_create(&menu.element, false)
			width += 16
		}
	}
	_ = SDL.SetWindowSize(w.sdl_window, i32(width), i32(height))
	window_resize(w, width, height)
	y := menu.point_y
	if menu.place_above { y -= height }
	if usable.w > 0 {
		y = math.clamp(y, int(usable.y), int(usable.y + usable.h) - height)
		menu.point_x = math.clamp(menu.point_x, int(usable.x), int(usable.x + usable.w) - width)
	}
	_ = SDL.SetWindowPosition(w.sdl_window, i32(menu.point_x), i32(y))
	_ = SDL.ShowWindow(w.sdl_window)
	element_focus(&menu.element)
	element_repaint(&w.element)
}

Dialog :: struct {
	window:  ^Window,
	choices: []string,
	result:  string,
	done:    bool,
}
dialog_button_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	if kind != .Clicked { return 0 }
	dialog := (^Dialog)(e.user_data)
	dialog.result = (^Button)(e).label
	for choice in dialog.choices {
		if choice == dialog.result {
			dialog.result = choice
			break
		}
	}
	if len(dialog.choices) == 0 { dialog.result = "OK" }
	dialog.done = true
	element_destroy(&dialog.window.element)
	return 1
}

// A common message-and-choices dialog.
dialog_show :: proc(owner: ^Window, message_text: string, choices: []string) -> string {
	width := max(320, len(message_text) * 9 + 40)
	buttons := max(1, len(choices))
	width = max(width, buttons * 105 + 20)
	w := window_create_with_flags("Luigi", width, 112, SDL.WindowFlags{.BORDERLESS, .ALWAYS_ON_TOP})
	if w == nil { return "" }
	w.is_dialog = true
	w.owner = owner
	if owner != nil {
		x, y: i32
		_ = SDL.GetWindowPosition(owner.sdl_window, &x, &y)
		_ = SDL.SetWindowPosition(
			w.sdl_window,
			i32(int(x) + (owner.width - width) / 2),
			i32(int(y) + (owner.height - 112) / 2),
		)
	}
	dialog := Dialog {
		window  = w,
		choices = choices,
	}
	panel := panel_create(&w.element, {.Gray, .Medium_Spacing, .Expand})
	panel.border = {10, 10, 10, 10}
	label_create(&panel.element, message_text, {.H_Fill})
	row := panel_create(&panel.element, {.Horizontal, .Small_Spacing})
	if len(choices) == 0 {
		button := button_create(&row.element, "OK")
		button.user_data = &dialog
		button.message_user = dialog_button_message
	} else {
		for choice in choices {
			button := button_create(&row.element, choice)
			button.user_data = &dialog
			button.message_user = dialog_button_message
		}
	}
	element_refresh(&w.element)
	id := w.sdl_id
	for !dialog.done && !ui.quit && window_from_id(id) != nil { ui_pump_once() }
	return dialog.result
}

// Arguments are consumed by %b (button), %s (label), %t (textbox), and %u
// (custom row content). %f and %l insert a fill spacer and a line. Newlines
// start new rows. This typed slice takes the place of C's variadic arguments.
Dialog_Argument :: struct {
	text:     string,
	buffer:   ^[dynamic]u8,
	callback: proc(row: ^Element),
}

dialog_textbox_message :: proc(e: ^Element, kind: Message, data: int, payload: rawptr) -> int {
	if kind == .Value_Changed && e.user_data != nil {
		buffer := (^[dynamic]u8)(e.user_data)
		clear(buffer)
		append(buffer, string((^Textbox)(e).text[:]))
	}
	return 0
}

dialog_show_format :: proc(owner: ^Window, format: string, arguments: []Dialog_Argument) -> string {
	w := window_create_with_flags("Luigi", 1, 1, SDL.WindowFlags{.HIDDEN, .BORDERLESS, .ALWAYS_ON_TOP})
	if w == nil { return "" }
	w.is_dialog = true
	w.owner = owner
	choices: [dynamic]string
	defer delete(choices)
	dialog := Dialog {
		window = w,
	}
	panel := panel_create(&w.element, {.Gray, .Medium_Spacing, .Expand})
	panel.border = {10, 10, 10, 10}
	row := panel_create(&panel.element, {.Horizontal, .Small_Spacing})
	argument_index := 0
	first_focus: ^Element
	for i := 0; i < len(format); {
		if format[i] == '\n' {
			row = panel_create(&panel.element, {.Horizontal, .Small_Spacing})
			i += 1
			continue
		}
		if format[i] != '%' {
			start := i
			for i < len(format) && format[i] != '%' && format[i] != '\n' { i += 1 }
			label_create(&row.element, format[start:i])
			continue
		}
		i += 1
		if i >= len(format) { break }
		specifier := format[i]
		i += 1
		if specifier == '%' {
			label_create(&row.element, "%")
			continue
		}
		if specifier == 'f' {
			spacer := spacer_create(&row.element, 0, 0)
			spacer.flags += {.H_Fill}
			continue
		}
		if specifier == 'l' {
			spacer := spacer_create(&row.element, 0, 1, true)
			spacer.flags += {.H_Fill}
			continue
		}
		if argument_index >= len(arguments) { continue }
		argument := arguments[argument_index]
		argument_index += 1
		switch specifier {
		case 'b':
			button := button_create(&row.element, argument.text)
			button.user_data = &dialog
			button.message_user = dialog_button_message
			append(&choices, argument.text)
			if first_focus == nil { first_focus = &button.element }
		case 's':
			label_create(&row.element, argument.text)
		case 't':
			box := textbox_create(&row.element)
			box.flags += {.H_Fill}
			box.user_data = argument.buffer
			box.message_user = dialog_textbox_message
			if argument.buffer != nil { textbox_replace(box, string(argument.buffer^[:]), false) }
			if first_focus == nil { first_focus = &box.element }
		case 'u':
			if argument.callback != nil { argument.callback(&row.element) }
		}
	}
	if len(choices) == 0 {
		row = panel_create(&panel.element, {.Horizontal})
		button := button_create(&row.element, "OK")
		button.user_data = &dialog
		button.message_user = dialog_button_message
		if first_focus == nil { first_focus = &button.element }
	}
	dialog.choices = choices[:]
	width := max(320, element_message(&panel.element, .Get_Width))
	height := max(80, element_message(&panel.element, .Get_Height, width))
	_ = SDL.SetWindowSize(w.sdl_window, i32(width), i32(height))
	window_resize(w, width, height)
	if owner != nil {
		x, y: i32
		_ = SDL.GetWindowPosition(owner.sdl_window, &x, &y)
		_ = SDL.SetWindowPosition(
			w.sdl_window,
			i32(int(x) + (owner.width - width) / 2),
			i32(int(y) + (owner.height - height) / 2),
		)
	}
	_ = SDL.ShowWindow(w.sdl_window)
	if first_focus != nil { element_focus(first_focus) }
	element_refresh(&w.element)
	id := w.sdl_id
	for !dialog.done && !ui.quit && window_from_id(id) != nil { ui_pump_once() }
	return dialog.result
}
