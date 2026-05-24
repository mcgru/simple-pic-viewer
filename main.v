module main

import os

#include "gtk/gtk.h"

// ============================================================
// GTK3 C function declarations
// ============================================================

fn C.gtk_init(intptr, intptr)
fn C.gtk_main()
fn C.gtk_main_quit()

fn C.gtk_window_new(int) voidptr
fn C.gtk_window_set_title(voidptr, &char)
fn C.gtk_window_set_default_size(voidptr, int, int)
fn C.gtk_window_set_resizable(voidptr, int)
fn C.gtk_window_set_transient_for(voidptr, voidptr)
fn C.gtk_window_set_modal(voidptr, int)

fn C.gtk_container_add(voidptr, voidptr)
fn C.gtk_widget_show_all(voidptr)
fn C.gtk_widget_destroy(voidptr)
fn C.gtk_widget_set_size_request(voidptr, int, int)

fn C.g_signal_connect_data(voidptr, &char, voidptr, voidptr, voidptr, int) u64

fn C.gtk_image_new() voidptr
fn C.gtk_image_set_from_pixbuf(voidptr, voidptr)
fn C.gtk_image_clear(voidptr)

fn C.gdk_pixbuf_new_from_file_at_scale(&char, int, int, int, intptr) voidptr
fn C.g_object_unref(voidptr)

fn C.gtk_dialog_new() voidptr
fn C.gtk_dialog_add_button(voidptr, &char, int) voidptr
fn C.gtk_dialog_get_content_area(voidptr) voidptr
fn C.gtk_dialog_response(voidptr, int)
fn C.gtk_dialog_run(voidptr) int

fn C.gtk_box_pack_start(voidptr, voidptr, int, int, int)
fn C.gtk_box_pack_end(voidptr, voidptr, int, int, int)
fn C.gtk_box_new(int, int) voidptr
fn C.gtk_button_new_with_label(&char) voidptr

fn C.gtk_label_new(&char) voidptr
fn C.gtk_label_set_text(voidptr, &char)

fn C.gtk_combo_box_text_new() voidptr
fn C.gtk_combo_box_text_append(voidptr, &char, &char)
fn C.gtk_combo_box_get_active(voidptr) int
fn C.gtk_combo_box_set_active(voidptr, int)

// ScrolledWindow
fn C.gtk_scrolled_window_new(voidptr, voidptr) voidptr
fn C.gtk_scrolled_window_set_policy(voidptr, int, int)

// ListBox
fn C.gtk_list_box_new() voidptr
fn C.gtk_list_box_insert(voidptr, voidptr, int)
fn C.gtk_list_box_select_row(voidptr, voidptr)
fn C.gtk_list_box_get_selected_row(voidptr) voidptr
fn C.gtk_list_box_set_selection_mode(voidptr, int)

// ListBoxRow
fn C.gtk_list_box_row_new() voidptr
fn C.gtk_list_box_row_get_index(voidptr) int

// Widget margins & alignment
fn C.gtk_widget_set_name(voidptr, &char)
fn C.gtk_widget_set_halign(voidptr, int)
fn C.gtk_widget_set_margin_top(voidptr, int)
fn C.gtk_widget_set_margin_bottom(voidptr, int)
fn C.gtk_widget_set_margin_start(voidptr, int)
fn C.gtk_widget_set_margin_end(voidptr, int)
fn C.gtk_widget_grab_focus(voidptr)

// Entry
fn C.gtk_entry_new() voidptr
fn C.gtk_entry_set_text(voidptr, &char)
fn C.gtk_entry_get_text(voidptr) &char

// CSS provider (for red flash)
fn C.gtk_css_provider_new() voidptr
fn C.gtk_css_provider_load_from_data(voidptr, &char, int, intptr) int
fn C.gtk_widget_get_style_context(voidptr) voidptr
fn C.gtk_style_context_add_provider(voidptr, voidptr, int)
fn C.gtk_style_context_remove_provider(voidptr, voidptr)

// Timer
fn C.g_timeout_add(int, voidptr, voidptr) int

// ============================================================
// Constants
// ============================================================

const gtk_window_toplevel = 0
const gtk_orient_vertical = 1
const gtk_response_cancel = -6
const copy_response_id = 1
const gdk_key_left = 65361
const gdk_key_right = 65363
const gdk_key_escape = 65307
const gdk_key_return = 65293
const gdk_key_backspace = 65288
const gdk_key_f5 = 65469
const gdk_key_f6 = 65470
const gdk_key_f4 = 65471
const gdk_key_f8 = 65472
const gtk_align_start = 1
const gtk_selection_single = 1
const css_provider_priority = 800

// Cyrillic keyvals (match Unicode codepoints)
const cyrillic_capital_es = 1057
const cyrillic_small_es = 1089
const cyrillic_capital_soft = 1068
const cyrillic_small_soft = 1100
const cyrillic_capital_u = 1059
const cyrillic_small_u = 1091

// Arrow keys
const gdk_key_up = 65362
const gdk_key_down = 65364

// Cyrillic Ya/ya
const cyrillic_capital_ya = 1067
const cyrillic_small_ya = 1103

// ============================================================
// Application state
// ============================================================

struct AppState {
mut:
	files               []string
	cur_index           int = -1
	window              voidptr
	image               voidptr
	config              AppConfig
	dialog_rows         []voidptr
	dialog_path_labels  []voidptr
	dialog_dest_idx     []int
	dialog_provider     voidptr
	dialog_window       voidptr
	sidebar_scroll      voidptr
	sidebar_list        voidptr
	sidebar_rows        []voidptr
	sidebar_labels      []voidptr
	sidebar_sel         int = -1
	current_dir         string
	dir_stack           []string
	flash_provider      voidptr
}

__global(
	app AppState
	config_errors []string
)

// ============================================================
// Callbacks
// ============================================================

@[export: 'restore_title_fn']
fn restore_title_fn(data voidptr) int {
	if voidptr(app.window) != voidptr(0) {
		show_current_image()
	}
	return 0
}

@[export: 'on_destroy']
fn on_destroy(widget voidptr, data voidptr) {
	C.gtk_main_quit()
}

@[export: 'on_key_press']
fn on_key_press(widget voidptr, event voidptr, data voidptr) int {
	keyval := get_keyval(event)

	if keyval == u32(gdk_key_left) {
		show_prev_image()
		return 1
	}

	if keyval == u32(gdk_key_right) {
		show_next_image()
		return 1
	}

	// Digits 1-9: copy; Shift+digit: delete from destination folder
	idx := digit_idx(keyval)
	if idx >= 0 {
		state := get_event_state(event)

		if state & 1 != 0 {
			// Shift+digit: delete from destination folder
			if app.cur_index >= 0 && app.cur_index < app.files.len && idx < app.config.destination_dirs.len && app.config.destination_dirs[idx].path != '' {
				delete_from_folder(app.files[app.cur_index], app.config.destination_dirs[idx].path)
			} else {
				flash_main_window('red')
			}
			return 1
		}

		// Normal digit: copy (hardlink) to corresponding destination dir
		if app.cur_index >= 0 && app.cur_index < app.files.len {
			if idx < app.config.destination_dirs.len && app.config.destination_dirs[idx].path != '' {
				exec_copy(app.files[app.cur_index], app.config.destination_dirs[idx].path, 'link') or {
					flash_main_window('red')
					show_error_msg(app.window, 'Failed: ${err.str()}')
					return 1
				}
				// Success — show feedback
				flash_main_window('green')
				title := '   COPIED to ' + app.config.destination_dirs[idx].path
				C.gtk_window_set_title(app.window, &char(title.str))
				C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
				return 1
			}
		}
		// Empty / out-of-range slot — error flash
		flash_main_window('red')
		num := (idx + 1).str()
		title := '   ERROR: no folder assigned to ' + num
		C.gtk_window_set_title(app.window, &char(title.str))
		C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
		return 1
	}

	// D / В / F8: delete dialog
	if keyval == 68 || keyval == 100 || keyval == u32(gdk_key_f8) {
		show_delete_dialog()
		return 1
	}
	if keyval == 1042 || keyval == 1074 {
		show_delete_dialog()
		return 1
	}

	if keyval == 67 || keyval == 99 || keyval == cyrillic_capital_es || keyval == cyrillic_small_es {
		show_copy_dialog('link')
		return 1
	}

	if keyval == 77 || keyval == 109 || keyval == cyrillic_capital_soft || keyval == cyrillic_small_soft {
		show_copy_dialog(app.config.move_method)
		return 1
	}

	if keyval == u32(gdk_key_escape) {
		C.gtk_main_quit()
		return 1
	}

	if keyval == u32(gdk_key_return) {
		if app.cur_index >= 0 && app.cur_index < app.files.len && os.is_dir(app.files[app.cur_index]) {
			navigate_to_dir(app.files[app.cur_index])
			return 1
		}
	}

	if keyval == u32(gdk_key_backspace) {
		if app.dir_stack.len > 0 {
			navigate_up()
			return 1
		}
	}

	// Sidebar navigation
	if keyval == u32(gdk_key_up) {
		sidebar_select_prev()
		return 1
	}
	if keyval == u32(gdk_key_down) {
		sidebar_select_next()
		return 1
	}

	// z / Z / \xd1\x8f / \xd0\xaf — quick copy to sidebar-selected folder
	if keyval == 122 || keyval == 90 || keyval == cyrillic_small_ya || keyval == cyrillic_capital_ya {
		if app.cur_index >= 0 && app.cur_index < app.files.len && app.sidebar_sel >= 0 && app.sidebar_sel < app.config.destination_dirs.len {
			dir := app.config.destination_dirs[app.sidebar_sel]
			if dir.path != '' {
				exec_copy(app.files[app.cur_index], dir.path, 'link') or {
					flash_main_window('red')
					show_error_msg(app.window, 'Failed: ${err.str()}')
					return 1
				}
				flash_main_window('green')
				title := '   COPIED to ' + dir.path
				C.gtk_window_set_title(app.window, &char(title.str))
				C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
				return 1
			}
		}
		flash_main_window('red')
		return 1
	}

	return 0
}

@[export: 'on_dialog_key']
fn on_dialog_key(dlg voidptr, event voidptr, list_box voidptr) int {
	keyval := get_keyval(event)
	if keyval == u32(gdk_key_return) {
		C.gtk_dialog_response(dlg, copy_response_id)
		return 1
	}
	if keyval >= 49 && keyval <= 57 {
		idx := int(keyval - 49)
		if idx < app.dialog_rows.len {
			C.gtk_list_box_select_row(list_box, app.dialog_rows[idx])
			C.gtk_dialog_response(dlg, copy_response_id)
			return 1
		}
		flash_dialog_red()
		return 1
	}

	// e / E / у / У / F4 — edit selected destination
	if keyval == 69 || keyval == 101 || keyval == cyrillic_capital_u || keyval == cyrillic_small_u || keyval == u32(gdk_key_f4) {
		sel := C.gtk_list_box_get_selected_row(list_box)
		if voidptr(sel) != voidptr(0) {
			row_idx := C.gtk_list_box_row_get_index(sel)
			if row_idx >= 0 && row_idx < app.dialog_dest_idx.len {
				idx := app.dialog_dest_idx[row_idx]
				if idx >= 0 && idx < app.config.destination_dirs.len {
					show_edit_dialog(idx)
				}
			}
		}
		return 1
	}
	return 0
}

@[export: 'unflash_dialog']
fn unflash_dialog(data voidptr) int {
	if voidptr(app.dialog_provider) != voidptr(0) {
		ctx := C.gtk_widget_get_style_context(app.dialog_window)
		C.gtk_style_context_remove_provider(ctx, app.dialog_provider)
		C.g_object_unref(app.dialog_provider)
		app.dialog_provider = voidptr(0)
	}
	return 0
}

fn unflash_main_window(data voidptr) int {
	if voidptr(app.flash_provider) != voidptr(0) {
		ctx := C.gtk_widget_get_style_context(app.window)
		C.gtk_style_context_remove_provider(ctx, app.flash_provider)
		C.g_object_unref(app.flash_provider)
		app.flash_provider = voidptr(0)
	}
	return 0
}

fn flash_main_window(color string) {
	if voidptr(app.flash_provider) != voidptr(0) {
		ctx := C.gtk_widget_get_style_context(app.window)
		C.gtk_style_context_remove_provider(ctx, app.flash_provider)
		C.g_object_unref(app.flash_provider)
		app.flash_provider = voidptr(0)
	}
	provider := C.gtk_css_provider_new()
	css := '#main-window { background-color: ' + color + '; }'
	C.gtk_css_provider_load_from_data(provider, &char(css.str), -1, voidptr(0))
	C.gtk_widget_set_name(app.window, c"main-window")
	ctx := C.gtk_widget_get_style_context(app.window)
	C.gtk_style_context_add_provider(ctx, provider, css_provider_priority)
	app.flash_provider = provider
	C.g_timeout_add(500, voidptr(unflash_main_window), voidptr(0))
}

fn flash_dialog_red() {
	if voidptr(app.dialog_provider) != voidptr(0) {
		return
	}
	provider := C.gtk_css_provider_new()
	css := "#flash-dialog { background-color: #e04040; }"
	C.gtk_css_provider_load_from_data(provider, &char(css.str), -1, voidptr(0))

	C.gtk_widget_set_name(app.dialog_window, c"flash-dialog")
	ctx := C.gtk_widget_get_style_context(app.dialog_window)
	C.gtk_style_context_add_provider(ctx, provider, css_provider_priority)

	app.dialog_provider = provider
	C.g_timeout_add(300, voidptr(unflash_dialog), voidptr(0))
}

// ============================================================
// GDK event helpers
// ============================================================

struct GdkEventKeyFields {
	gtype       int
	pad1        int
	win         voidptr
	send_event  u8
	pad2        [3]u8
	time_val    u32
	state_val   u32
	keyval      u32
}

fn get_keyval(event voidptr) u32 {
	unsafe {
		ke := &GdkEventKeyFields(event)
		return ke.keyval
	}
}

fn get_event_state(event voidptr) u32 {
	unsafe {
		ke := &GdkEventKeyFields(event)
		return ke.state_val
	}
}

fn digit_idx(keyval u32) int {
	if keyval >= 49 && keyval <= 57 {
		return int(keyval - 49)
	}
	match keyval {
		33 { return 0 }
		64 { return 1 }
		35 { return 2 }
		36 { return 3 }
		37 { return 4 }
		94 { return 5 }
		38 { return 6 }
		42 { return 7 }
		40 { return 8 }
		else { return -1 }
	}
}

// ============================================================
// Directory scanning
// ============================================================

fn load_dir(dir string) {
	app.current_dir = dir

	exts := ['.png', '.jpg', '.jpeg', '.tif', '.tiff']

	entries := os.ls(dir) or {
		app.files = []
		app.cur_index = -1
		return
	}

	mut dirs := []string{}
	mut images := []string{}

	for f in entries {
		path := os.join_path(dir, f)
		if os.is_dir(path) {
			dirs << path
			continue
		}
		lower := f.to_lower()
		for ext in exts {
			if lower.ends_with(ext) {
				images << path
				break
			}
		}
	}

	dirs.sort()
	images.sort()

	app.files = dirs
	app.files << images
	app.cur_index = if app.files.len > 0 { 0 } else { -1 }
}

// ============================================================
// Image display
// ============================================================

fn show_current_image() {
	if app.cur_index < 0 || app.cur_index >= app.files.len {
		C.gtk_window_set_title(app.window, c"No images found")
		C.gtk_image_clear(app.image)
		return
	}

	filename := app.files[app.cur_index]
	folder := if app.current_dir != '' { app.current_dir } else { '.' }
	idx_str := '(${app.cur_index + 1}/${app.files.len})'

	if os.is_dir(filename) {
		base := os.base(filename)
		title := '   ${folder} ${idx_str} -- ${base}'
		C.gtk_window_set_title(app.window, &char(title.str))
		C.gtk_image_clear(app.image)
	} else {
		base := os.base(filename)
		title := '   ${folder} ${idx_str} -- ${base}'
		C.gtk_window_set_title(app.window, &char(title.str))
		C.gtk_image_clear(app.image)

		pixbuf := C.gdk_pixbuf_new_from_file_at_scale(
			&char(filename.str),
			860, 660, 1,
			voidptr(0),
		)

		if voidptr(pixbuf) != voidptr(0) {
			C.gtk_image_set_from_pixbuf(app.image, pixbuf)
			C.g_object_unref(pixbuf)
		}
	}
}

fn show_prev_image() {
	if app.files.len == 0 {
		return
	}
	app.cur_index = (app.cur_index - 1 + app.files.len) % app.files.len
	show_current_image()
}

fn show_next_image() {
	if app.files.len == 0 {
		return
	}
	app.cur_index = (app.cur_index + 1) % app.files.len
	show_current_image()
}

// ============================================================
// Directory navigation
// ============================================================

fn navigate_to_dir(path string) {
	app.dir_stack << app.current_dir
	load_dir(path)
	show_current_image()
}

fn navigate_up() {
	if app.dir_stack.len == 0 {
		return
	}
	parent := app.dir_stack.pop()
	load_dir(parent)
	show_current_image()
}

// ============================================================
// Copy / Move dialog
// ============================================================

fn show_error_msg(parent voidptr, msg string) {
	dialog := C.gtk_dialog_new()
	C.gtk_window_set_title(dialog, c"Error")
	C.gtk_window_set_transient_for(dialog, parent)
	C.gtk_window_set_modal(dialog, 1)
	C.gtk_window_set_default_size(dialog, 300, 100)

	content := C.gtk_dialog_get_content_area(dialog)
	label := C.gtk_label_new(&char(msg.str))
	C.gtk_box_pack_start(content, label, 1, 1, 10)
	C.gtk_dialog_add_button(dialog, c"_OK", -7)

	C.gtk_widget_show_all(dialog)
	C.gtk_dialog_run(dialog)
	C.gtk_widget_destroy(dialog)
}

fn show_copy_dialog(method string) {
	if app.cur_index < 0 || app.cur_index >= app.files.len || app.config.destination_dirs.len == 0 {
		return
	}

	method_label := if method == 'link' { 'copy' } else { 'move' }
	full_title := '${method_label} — select destination'

	dialog := C.gtk_dialog_new()
	C.gtk_window_set_title(dialog, &char(full_title.str))
	C.gtk_window_set_transient_for(dialog, app.window)
	C.gtk_window_set_modal(dialog, 1)
	C.gtk_window_set_default_size(dialog, 420, 300)

	app.dialog_window = dialog
	app.dialog_provider = voidptr(0)

	content := C.gtk_dialog_get_content_area(dialog)

	// ListBox for destinations
	list_box := C.gtk_list_box_new()
	C.gtk_list_box_set_selection_mode(list_box, gtk_selection_single)
	C.gtk_widget_set_size_request(list_box, -1, 280)

	mut rows := []voidptr{}
	mut path_labels := []voidptr{}
	mut dest_indices := []int{}
	for i, dir in app.config.destination_dirs {
		row := C.gtk_list_box_row_new()
		hbox := C.gtk_box_new(0, 8)

		path_label := C.gtk_label_new(&char(dir.path.str))
		C.gtk_widget_set_halign(path_label, gtk_align_start)

		idx_num := i + 1
		num_str := if idx_num < 10 { '  ${idx_num}' } else { '' }
		num_label := C.gtk_label_new(&char(num_str.str))

		C.gtk_box_pack_start(hbox, path_label, 1, 1, 0)
		C.gtk_box_pack_end(hbox, num_label, 0, 0, 8)

		C.gtk_widget_set_margin_top(hbox, 4)
		C.gtk_widget_set_margin_bottom(hbox, 4)
		C.gtk_widget_set_margin_start(hbox, 8)
		C.gtk_widget_set_margin_end(hbox, 8)

		C.gtk_container_add(row, hbox)
		C.gtk_list_box_insert(list_box, row, -1)
		rows << row
		path_labels << path_label
		dest_indices << i
	}
	app.dialog_rows = rows
	app.dialog_path_labels = path_labels
	app.dialog_dest_idx = dest_indices

	if rows.len > 0 {
		C.gtk_list_box_select_row(list_box, rows[0])
	}

	C.gtk_box_pack_start(content, list_box, 1, 1, 5)

	// Buttons
	C.gtk_dialog_add_button(dialog, c"_Cancel", gtk_response_cancel)
	C.gtk_dialog_add_button(dialog, c"_OK", copy_response_id)

	// Keyboard shortcuts 1-9
	C.g_signal_connect_data(dialog, c"key-press-event", voidptr(on_dialog_key), list_box, voidptr(0), 0)

	C.gtk_widget_show_all(dialog)

	// Run
	response := C.gtk_dialog_run(dialog)

	if response == copy_response_id {
		sel := C.gtk_list_box_get_selected_row(list_box)
		dir_idx := C.gtk_list_box_row_get_index(sel)

		if dir_idx >= 0 && dir_idx < app.dialog_dest_idx.len {
			idx := app.dialog_dest_idx[dir_idx]
			if idx >= 0 && idx < app.config.destination_dirs.len {
				dst_dir := app.config.destination_dirs[idx].path
				src := app.files[app.cur_index]
				exec_copy(src, dst_dir, method) or {
					show_error_msg(dialog, 'Failed: ${err.str()}')
				}
			}
		}
	}

	// Clean up
	if voidptr(app.dialog_provider) != voidptr(0) {
		ctx := C.gtk_widget_get_style_context(dialog)
		C.gtk_style_context_remove_provider(ctx, app.dialog_provider)
		C.g_object_unref(app.dialog_provider)
		app.dialog_provider = voidptr(0)
	}
	app.dialog_window = voidptr(0)
	app.dialog_rows = []
	app.dialog_path_labels = []
	app.dialog_dest_idx = []

	C.gtk_widget_destroy(dialog)
}

fn show_delete_dialog() {
	if app.cur_index < 0 || app.cur_index >= app.files.len || app.config.destination_dirs.len == 0 {
		return
	}

	title := 'delete -- select destination'
	dialog := C.gtk_dialog_new()
	C.gtk_window_set_title(dialog, &char(title.str))
	C.gtk_window_set_transient_for(dialog, app.window)
	C.gtk_window_set_modal(dialog, 1)
	C.gtk_window_set_default_size(dialog, 420, 300)

	app.dialog_window = dialog
	app.dialog_provider = voidptr(0)

	content := C.gtk_dialog_get_content_area(dialog)

	// ListBox for destinations
	list_box := C.gtk_list_box_new()
	C.gtk_list_box_set_selection_mode(list_box, gtk_selection_single)
	C.gtk_widget_set_size_request(list_box, -1, 280)

	mut rows := []voidptr{}
	mut path_labels := []voidptr{}
	mut dest_indices := []int{}
	for i, dir in app.config.destination_dirs {
		if dir.path == '' {
			path_labels << voidptr(0)
			continue
		}
		row := C.gtk_list_box_row_new()
		hbox := C.gtk_box_new(0, 8)

		path_label := C.gtk_label_new(&char(dir.path.str))
		C.gtk_widget_set_halign(path_label, gtk_align_start)

		idx_num := i + 1
		num_str := if idx_num < 10 { '  ' + idx_num.str() } else { '' }
		num_label := C.gtk_label_new(&char(num_str.str))

		C.gtk_box_pack_start(hbox, path_label, 1, 1, 0)
		C.gtk_box_pack_end(hbox, num_label, 0, 0, 8)

		C.gtk_widget_set_margin_top(hbox, 4)
		C.gtk_widget_set_margin_bottom(hbox, 4)
		C.gtk_widget_set_margin_start(hbox, 8)
		C.gtk_widget_set_margin_end(hbox, 8)

		C.gtk_container_add(row, hbox)
		C.gtk_list_box_insert(list_box, row, -1)
		rows << row
		path_labels << path_label
		dest_indices << i
	}
	app.dialog_rows = rows
	app.dialog_path_labels = path_labels
	app.dialog_dest_idx = dest_indices

	if rows.len > 0 {
		C.gtk_list_box_select_row(list_box, rows[0])
	} else {
		C.gtk_widget_destroy(dialog)
		return
	}

	C.gtk_box_pack_start(content, list_box, 1, 1, 5)

	// Buttons
	C.gtk_dialog_add_button(dialog, c"_Cancel", gtk_response_cancel)
	C.gtk_dialog_add_button(dialog, c"_OK", copy_response_id)

	C.g_signal_connect_data(dialog, c"key-press-event", voidptr(on_dialog_key), list_box, voidptr(0), 0)

	C.gtk_widget_show_all(dialog)

	response := C.gtk_dialog_run(dialog)

	if response == copy_response_id {
		sel := C.gtk_list_box_get_selected_row(list_box)
		dir_idx := C.gtk_list_box_row_get_index(sel)

		if dir_idx >= 0 && dir_idx < app.dialog_dest_idx.len {
			idx := app.dialog_dest_idx[dir_idx]
			if idx >= 0 && idx < app.config.destination_dirs.len {
				dst_dir := app.config.destination_dirs[idx].path
				src := app.files[app.cur_index]
				delete_from_folder(src, dst_dir)
			}
		}
	}

	if voidptr(app.dialog_provider) != voidptr(0) {
		ctx := C.gtk_widget_get_style_context(dialog)
		C.gtk_style_context_remove_provider(ctx, app.dialog_provider)
		C.g_object_unref(app.dialog_provider)
		app.dialog_provider = voidptr(0)
	}
	app.dialog_window = voidptr(0)
	app.dialog_rows = []
	app.dialog_path_labels = []
	app.dialog_dest_idx = []

	C.gtk_widget_destroy(dialog)
}

// ============================================================
// Sidebar
// ============================================================

fn rebuild_sidebar() {
	if voidptr(app.sidebar_list) == voidptr(0) {
		return
	}

	// Destroy old rows
	for row in app.sidebar_rows {
		C.gtk_widget_destroy(row)
	}

	mut rows := []voidptr{}
	mut labels := []voidptr{}

	if voidptr(app.sidebar_list) != voidptr(0) {
		for i, dir in app.config.destination_dirs {
			row := C.gtk_list_box_row_new()
			hbox := C.gtk_box_new(0, 4)

			label_text := if dir.path != '' {
				'${i + 1}: ${dir.path}'
			} else {
				'${i + 1}: (empty)'
			}
			label := C.gtk_label_new(&char(label_text.str))
			C.gtk_widget_set_halign(label, gtk_align_start)
			C.gtk_widget_set_margin_start(label, 6)
			C.gtk_widget_set_margin_end(label, 6)

			C.gtk_box_pack_start(hbox, label, 1, 1, 0)
			C.gtk_container_add(row, hbox)
			C.gtk_list_box_insert(app.sidebar_list, row, -1)

			rows << row
			labels << label
		}
	}

	app.sidebar_rows = rows
	app.sidebar_labels = labels

	// Select first non-empty entry
	if app.sidebar_sel < 0 || app.sidebar_sel >= rows.len {
		app.sidebar_sel = 0
		for i, dir in app.config.destination_dirs {
			if dir.path != '' {
				app.sidebar_sel = i
				break
			}
		}
	}
	if app.sidebar_sel >= 0 && app.sidebar_sel < rows.len {
		C.gtk_list_box_select_row(app.sidebar_list, app.sidebar_rows[app.sidebar_sel])
	} else {
		app.sidebar_sel = -1
	}
}

fn sidebar_select_next() int {
	if app.sidebar_rows.len == 0 {
		return -1
	}
	mut sel := app.sidebar_sel
	for _ in 0 .. app.sidebar_rows.len {
		sel = (sel + 1) % app.sidebar_rows.len
		if sel < app.config.destination_dirs.len && app.config.destination_dirs[sel].path != '' {
			app.sidebar_sel = sel
			C.gtk_list_box_select_row(app.sidebar_list, app.sidebar_rows[sel])
			return sel
		}
	}
	return -1
}

fn sidebar_select_prev() int {
	if app.sidebar_rows.len == 0 {
		return -1
	}
	mut sel := app.sidebar_sel
	for _ in 0 .. app.sidebar_rows.len {
		sel = (sel - 1 + app.sidebar_rows.len) % app.sidebar_rows.len
		if sel < app.config.destination_dirs.len && app.config.destination_dirs[sel].path != '' {
			app.sidebar_sel = sel
			C.gtk_list_box_select_row(app.sidebar_list, app.sidebar_rows[sel])
			return sel
		}
	}
	return -1
}

// ============================================================
// Edit destination dialog
// ============================================================

fn show_edit_dialog(idx int) {
	old_path := app.config.destination_dirs[idx].path

	dlg := C.gtk_dialog_new()
	C.gtk_window_set_title(dlg, c"Edit destination folder")
	C.gtk_window_set_transient_for(dlg, app.dialog_window)
	C.gtk_window_set_modal(dlg, 1)
	C.gtk_window_set_default_size(dlg, 400, 120)

	content := C.gtk_dialog_get_content_area(dlg)

	entry := C.gtk_entry_new()
	C.gtk_entry_set_text(entry, &char(old_path.str))
	C.gtk_widget_grab_focus(entry)
	C.gtk_box_pack_start(content, entry, 1, 1, 10)

	C.gtk_dialog_add_button(dlg, c"_Cancel", gtk_response_cancel)
	C.gtk_dialog_add_button(dlg, c"_OK", copy_response_id)

	C.gtk_widget_show_all(dlg)

	response := C.gtk_dialog_run(dlg)

	if response == copy_response_id {
		c_text := C.gtk_entry_get_text(entry)
		new_path := unsafe { cstring_to_vstring(c_text) }

		if new_path != old_path {
			app.config.destination_dirs[idx].path = new_path
			save_dest_dir_to_source(idx, new_path)

			if idx < app.dialog_path_labels.len {
				lbl := app.dialog_path_labels[idx]
				if voidptr(lbl) != voidptr(0) {
					C.gtk_label_set_text(lbl, &char(new_path.str))
				}
			}
		}
	}

	C.gtk_widget_destroy(dlg)
}

// ============================================================
// Entry point
// ============================================================

fn main() {
	// --help / -h : usage
	if os.args.contains('-h') || os.args.contains('--help') {
		println(usage())
		return
	}

	if os.args.contains('-V') || os.args.contains('--version') {
		println('simple-pic-viewer ${app_version}')
		return
	}

	// --init / -I : create .target.folders and exit
	if os.args.contains('-I') || os.args.contains('--init') {
		conf := load_config()
		init_target_file(conf) or {
			eprintln('Error: ${err}')
			exit(1)
		}
		println('Created ${os.getwd()}/.target.folders')
		return
	}

	app.config = load_config()

	start_dir := if os.args.len > 1 { os.args[1] } else { '.' }

	// Priority chain: lowest → highest. Each step overwrites by index.

	// 1. ~/.config/simple-pic-viewer/.target.folders
	home_target := load_target_folders_at(config_dir()) or { []DestDir{} }
	if home_target.len > 0 {
		merge_dirs(mut app.config.destination_dirs, home_target)
	}

	// 2. CWD/.target.folders
	cwd_target := load_target_folders() or { []DestDir{} }
	if cwd_target.len > 0 {
		merge_dirs(mut app.config.destination_dirs, cwd_target)
	}

	// 3. Walk intermediate dirs from CWD to start_dir
	abs_cwd := os.real_path(os.getwd())
	abs_start := os.real_path(start_dir)
	if abs_start != abs_cwd && abs_start.len > abs_cwd.len && abs_start[..abs_cwd.len] == abs_cwd {
		mut rest := abs_start[abs_cwd.len..]
		rest = rest.trim_left('/')
		mut prev := ''
		for seg in rest.split('/') {
			prev = os.join_path(prev, seg)
			walk_path := os.join_path(abs_cwd, prev)
			if walk_path == abs_start {
				break
			}
			step_target := load_target_folders_at(walk_path) or { []DestDir{} }
			if step_target.len > 0 {
				merge_dirs(mut app.config.destination_dirs, step_target)
			}
		}
	}

	// 4. start_dir/.target.folders (highest)
	if abs_start != abs_cwd {
		dir_target := load_target_folders_at(start_dir) or { []DestDir{} }
		if dir_target.len > 0 {
			merge_dirs(mut app.config.destination_dirs, dir_target)
		}
	}

	load_dir(start_dir)

	C.gtk_init(voidptr(0), voidptr(0))

	window := C.gtk_window_new(gtk_window_toplevel)
	C.gtk_window_set_title(window, c"Simple Pic Viewer")
	C.gtk_window_set_default_size(window, 1100, 700)

	// Horizontal layout: sidebar | image
	hbox := C.gtk_box_new(0, 0)

	// Sidebar (scrolled list of destination dirs)
	scroll := C.gtk_scrolled_window_new(voidptr(0), voidptr(0))
	C.gtk_scrolled_window_set_policy(scroll, 1, 1) // GTK_POLICY_AUTOMATIC
	C.gtk_widget_set_size_request(scroll, 220, -1)

	list_box := C.gtk_list_box_new()
	C.gtk_list_box_set_selection_mode(list_box, gtk_selection_single)
	C.gtk_container_add(scroll, list_box)

	image := C.gtk_image_new()

	C.gtk_box_pack_start(hbox, scroll, 0, 0, 0)
	C.gtk_box_pack_start(hbox, image, 1, 1, 0)

	C.gtk_container_add(window, hbox)

	app.window = window
	app.image = image
	app.sidebar_scroll = scroll
	app.sidebar_list = list_box

	// Build sidebar after config is fully loaded
	rebuild_sidebar()

	C.g_signal_connect_data(window, c"destroy", voidptr(on_destroy), voidptr(0), voidptr(0), 0)
	C.g_signal_connect_data(window, c"key-press-event", voidptr(on_key_press), voidptr(0), voidptr(0), 0)

	if config_errors.len > 0 {
		msg := config_errors.join('\n')
		show_error_msg(window, msg)
		config_errors = []
	}

	show_current_image()
	C.gtk_widget_show_all(window)
	C.gtk_main()
}

fn usage() string {
	return 'Version: simple-pic-viewer ${app_version}
Usage: simple-pic-viewer [OPTIONS] [DIR...]

Minimal GTK3 image viewer with keyboard navigation.
Supports PNG, JPEG, TIFF images.

Options:
  -h, --help       Show this help and exit
  -I, --init       Create .target.folders from config and exit
  -V, --version    Show version and exit

Keys:
  ← →             Previous / next image
  1-9             Quick copy (hardlink) to folder 1-9 by index
  Shift+1..9       Delete from folder 1-9 (verified by MD5)
  C / С / F5       Copy (link) current image to selected folder
  M / Ь / F6       Move current image to selected folder
  D / В / F8       Delete from folder (MD5-verified, with dialog)
  Esc             Quit
  Enter           Enter a directory (when directory navigation is enabled)
  Backspace       Go up to parent directory

Dialog keys:
  e / E / Ñ / Ð£ / F4  Edit selected destination folder

Configuration:
  ~/.config/simple-pic-viewer/.env — TGT_FLDR_*, COPY_METHOD, MOVE_METHOD
  ./.target.folders — per-project folder list (overrides .env)

Libs (build):
  sudo apt install build-essential pkg-config git libgtk-3-dev
Libs (runtime):
  sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0 gdk-pixbuf-tiff
V compiler:  https://github.com/vlang/v

Examples:
  simple-pic-viewer
  simple-pic-viewer /path/to/images
  simple-pic-viewer --init
'
}
