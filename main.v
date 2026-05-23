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

fn C.gtk_combo_box_text_new() voidptr
fn C.gtk_combo_box_text_append(voidptr, &char, &char)
fn C.gtk_combo_box_get_active(voidptr) int
fn C.gtk_combo_box_set_active(voidptr, int)

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
const gtk_align_start = 1
const gtk_selection_single = 1
const css_provider_priority = 800

// ============================================================
// Application state
// ============================================================

struct AppState {
mut:
	files           []string
	cur_index       int = -1
	window          voidptr
	image           voidptr
	config          AppConfig
	dialog_rows     []voidptr
	dialog_provider voidptr
	dialog_window   voidptr
	current_dir     string
	dir_stack       []string
}

__global(
	app AppState
)

// ============================================================
// Callbacks
// ============================================================

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

	if keyval == 67 || keyval == 99 {
		show_copy_dialog('link')
		return 1
	}

	if keyval == 77 || keyval == 109 {
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

	return 0
}

@[export: 'on_dialog_key']
fn on_dialog_key(dlg voidptr, event voidptr, list_box voidptr) int {
	keyval := get_keyval(event)
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
	for i, dir in app.config.destination_dirs {
		row := C.gtk_list_box_row_new()
		hbox := C.gtk_box_new(0, 8)

		path_label := C.gtk_label_new(&char(dir.str))
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
	}
	app.dialog_rows = rows

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

		if dir_idx >= 0 && dir_idx < app.config.destination_dirs.len {
			dst_dir := app.config.destination_dirs[dir_idx]
			src := app.files[app.cur_index]
			exec_copy(src, dst_dir, method) or {
				show_error_msg(dialog, 'Failed: ${err.str()}')
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

	C.gtk_widget_destroy(dialog)
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

	// .target.folders overrides TGT_FLDR_* from .env
	target_folders := load_target_folders() or { []string{} }
	if target_folders.len > 0 {
		app.config.destination_dirs = target_folders
	}

	start_dir := if os.args.len > 1 { os.args[1] } else { '.' }
	load_dir(start_dir)

	C.gtk_init(voidptr(0), voidptr(0))

	window := C.gtk_window_new(gtk_window_toplevel)
	C.gtk_window_set_title(window, c"Simple Pic Viewer")
	C.gtk_window_set_default_size(window, 900, 700)

	image := C.gtk_image_new()
	C.gtk_container_add(window, image)

	app.window = window
	app.image = image

	C.g_signal_connect_data(window, c"destroy", voidptr(on_destroy), voidptr(0), voidptr(0), 0)
	C.g_signal_connect_data(window, c"key-press-event", voidptr(on_key_press), voidptr(0), voidptr(0), 0)

	show_current_image()
	C.gtk_widget_show_all(window)
	C.gtk_main()
}

fn usage() string {
	return 'Usage: simple-pic-viewer [OPTIONS] [DIR...]

Minimal GTK3 image viewer with keyboard navigation.
Supports PNG, JPEG, TIFF images.

Options:
  -h, --help       Show this help and exit
  -I, --init       Create .target.folders from config and exit
  -V, --version    Show version and exit

Keys:
  ← →             Previous / next image
  C               Copy (link) current image to selected folder
  M               Move current image to selected folder
  Esc             Quit
  Enter           Enter a directory (when directory navigation is enabled)
  Backspace       Go up to parent directory

Configuration:
  ~/.config/simple-pic-viewer/.env — TGT_FLDR_*, COPY_METHOD, MOVE_METHOD
  ./.target.folders — per-project folder list (overrides .env)

Examples:
  simple-pic-viewer
  simple-pic-viewer /path/to/images
  simple-pic-viewer --init
'
}
