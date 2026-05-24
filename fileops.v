module main

import os
import crypto.md5

fn exec_copy(src string, dst_dir string, method string) ! {
	expanded := expand_path(dst_dir)
	os.mkdir_all(expanded) or { return err }

	dst := os.join_path(expanded, os.base(src))

	match method {
		'link' {
			// Try hardlink first, fall back to copy if cross-filesystem
			os.link(src, dst) or {
				// cross-filesystem or other failure -> regular copy
				os.cp(src, dst) or { return err }
			}
		}
		'mv' {
			os.mv(src, dst) or { return err }
		}
		else {
			return error('unknown method: ${method}')
		}
	}
}

fn delete_from_folder(src string, dst_dir string) {
	expanded := expand_path(dst_dir)
	dst := os.join_path(expanded, os.base(src))

	if !os.exists(dst) {
		flash_main_window('red')
		expanded_disp := expand_path(dst_dir)
		title := '   NO-FILE ' + expanded_disp + '/' + os.base(src)
		C.gtk_window_set_title(app.window, &char(title.str))
		C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
		return
	}

	// Compare by md5sum (read both files entirely)
	src_data := os.read_file(src) or {
		flash_main_window('red')
		title := '   NO-FILE ' + os.base(src)
		C.gtk_window_set_title(app.window, &char(title.str))
		C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
		return
	}
	dst_data := os.read_file(dst) or {
		flash_main_window('red')
		title := '   NO-FILE ' + os.base(dst)
		C.gtk_window_set_title(app.window, &char(title.str))
		C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
		return
	}

	src_hash := md5.hexhash(src_data)
	dst_hash := md5.hexhash(dst_data)

	if src_hash != dst_hash {
		flash_main_window('red')
		show_error_msg(app.window, 'MD5 mismatch - file differs: ' + os.base(src))
		return
	}

	os.rm(dst) or {
		flash_main_window('red')
		show_error_msg(app.window, 'Cannot delete: ' + err.str())
		return
	}

	// Success
	flash_main_window('red')
	expanded_disp := expand_path(dst_dir)
	title := '   DELETED ' + expanded_disp + '/' + os.base(src)
	C.gtk_window_set_title(app.window, &char(title.str))
	C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
}
