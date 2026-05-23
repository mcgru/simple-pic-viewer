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
