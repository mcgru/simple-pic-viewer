module main

import os

fn exec_copy(src string, dst_dir string, method string) ! {
	expanded := expand_path(dst_dir)
	os.mkdir_all(expanded) or { return err }

	dst := os.join_path(expanded, os.base(src))

	match method {
		'link' {
			// Try hardlink first, fall back to copy if cross-filesystem
			res := os.execute('cp -l "${src}" "${dst}"')
			if res.exit_code == 0 {
				return
			}
			// cross-filesystem or other failure -> try cp -a
			res2 := os.execute('cp -a "${src}" "${dst}"')
			if res2.exit_code != 0 {
				return error(res2.output)
			}
		}
		'mv' {
			res := os.execute('mv "${src}" "${dst}"')
			if res.exit_code != 0 {
				return error(res.output)
			}
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
		show_error_msg(app.window, 'Not found in ' + dst_dir + ': ' + os.base(src))
		return
	}

	// Compare by md5sum
	src_hash := os.execute('md5sum "' + src + '"').output.split(' ')[0]
	dst_hash := os.execute('md5sum "' + dst + '"').output.split(' ')[0]

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
	base := os.base(src)
	title := '   DELETED ' + base
	C.gtk_window_set_title(app.window, &char(title.str))
	C.g_timeout_add(2000, voidptr(restore_title_fn), voidptr(0))
}
