module main

import os

pub struct AppConfig {
pub mut:
	destination_dirs []string
	copy_method      string
	move_method      string
}

fn config_dir() string {
	return os.join_path(os.home_dir(), '.config', 'simple-pic-viewer')
}

fn config_path() string {
	return os.join_path(config_dir(), '.env')
}

fn load_config() AppConfig {
	path := config_path()

	// First run — create .env with defaults
	if !os.exists(path) {
		conf := AppConfig{
			destination_dirs: ['~/Pictures', '~/Desktop']
			copy_method: 'cp'
			move_method: 'mv'
		}
		save_config(conf)
		return conf
	}

	mut conf := AppConfig{
		copy_method: 'cp'
		move_method: 'mv'
	}

	data := os.read_file(path) or { return conf }

	for raw_line in data.split('\n') {
		l := raw_line.trim_space()
		if l == '' || l.starts_with('#') {
			continue
		}

		parts := l.split('=')
		if parts.len < 2 {
			continue
		}

		key := parts[0].trim_space()
		val := parts[1..].join('=').trim_space()

		if key.starts_with('TGT_FLDR_') {
			num_str := key['TGT_FLDR_'.len..]
			num := num_str.int()
			if num < 1 || num > 9 {
				config_errors << '${path}: invalid TGT_FLDR_${num_str} = ${val} — must be 1-9'
				continue
			}
			idx := num - 1
			for conf.destination_dirs.len <= idx {
				conf.destination_dirs << ''
			}
			conf.destination_dirs[idx] = val
		} else if key == 'COPY_METHOD' {
			conf.copy_method = val
		} else if key == 'MOVE_METHOD' {
			conf.move_method = val
		}
	}

	// If user wiped all TGT_FLDR lines — keep the list empty
	return conf
}

fn save_config(conf AppConfig) {
	os.mkdir_all(config_dir()) or { return }

	mut lines := []string{}
	lines << '# Simple Pic Viewer configuration'
	lines << '#'
	lines << '# Destination folders (add as many as needed):'
	for i, dir in conf.destination_dirs {
		lines << 'TGT_FLDR_${i + 1}=${dir}'
	}
	lines << ''
	lines << '# Copy method: cp | link'
	lines << 'COPY_METHOD=${conf.copy_method}'
	lines << ''
	lines << '# Move method: mv'
	lines << 'MOVE_METHOD=${conf.move_method}'
	lines << ''

	os.write_file(config_path(), lines.join('\n')) or { return }
}

const target_filename = '.target.folders'

// Load folder list from .target.folders in a specific directory.
fn load_target_folders_at(dir string) ![]string {
	data := os.read_file(os.join_path(dir, target_filename)) or {
		return err
	}

	mut folders := []string{}
	for line in data.split('\n') {
		l := line.trim_space()
		if l == '' || l.starts_with('#') {
			continue
		}
		if l.starts_with('/') || l.starts_with('~') {
			folders << l
		} else {
			folders << os.join_path(dir, l)
		}
	}

	if folders.len == 0 {
		return error('.target.folders is empty')
	}
	return folders
}

// Load folder list from .target.folders in the current directory.
// Overrides the TGT_FLDR_* from .env if the file exists.
fn load_target_folders() ![]string {
	return load_target_folders_at(os.getwd())
}

// Create .target.folders from the current config's destination_dirs.
fn init_target_file(conf AppConfig) ! {
	path := os.join_path(os.getwd(), target_filename)

	if os.exists(path) {
		return
	}

	mut lines := []string{}
	lines << '# target folders — one path per line, empty lines and # comments ignored'
	for _, dir in conf.destination_dirs {
		lines << dir
	}
	lines << ''

	os.write_file(path, lines.join('\n')) or {
		return error('cannot write ${path}')
	}
}


// Merge override dirs into dest element-by-element.
// overrides[0] replaces dest[0], overrides[1] replaces dest[1], etc.
// Extra entries in overrides are appended.
fn merge_dirs(mut dest []string, overrides []string) {
	for i, dir in overrides {
		if i < dest.len {
			dest[i] = dir
		} else {
			dest << dir
		}
	}
}

fn expand_path(path string) string {
	if path == '~' {
		return os.home_dir()
	}
	if path.starts_with('~/') {
		return os.home_dir() + path[1..]
	}
	return path
}
