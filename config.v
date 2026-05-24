module main

import os

struct DestDir {
mut:
	path    string
	source  string // config file this entry came from (for saving back)
	src_idx int    // 0-based index within that file's significant lines (-1 for .env)
}

pub struct AppConfig {
pub mut:
	destination_dirs []DestDir
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
			destination_dirs: [DestDir{'~/Pictures', path, -1}, DestDir{'~/Desktop', path, -1}]
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
				conf.destination_dirs << DestDir{}
			}
			conf.destination_dirs[idx] = DestDir{val, path, -1}
		} else if key == 'COPY_METHOD' {
			conf.copy_method = val
		} else if key == 'MOVE_METHOD' {
			conf.move_method = val
		}
	}

	return conf
}

fn save_config(conf AppConfig) {
	os.mkdir_all(config_dir()) or { return }

	mut lines := []string{}
	lines << '# Simple Pic Viewer configuration'
	lines << '#'
	lines << '# Destination folders (add as many as needed):'
	for i, dir in conf.destination_dirs {
		lines << 'TGT_FLDR_${i + 1}=${dir.path}'
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
fn load_target_folders_at(dir string) ![]DestDir {
	source := os.join_path(dir, target_filename)
	data := os.read_file(source) or {
		return err
	}

	mut folders := []DestDir{}
	for line in data.split('\n') {
		l := line.trim_space()
		if l == '' || l.starts_with('#') {
			continue
		}
		path := if l.starts_with('/') || l.starts_with('~') {
			l
		} else {
			os.join_path(dir, l)
		}
		folders << DestDir{path, source, folders.len}
	}

	if folders.len == 0 {
		return error('.target.folders is empty')
	}
	return folders
}

// Load folder list from .target.folders in the current directory.
fn load_target_folders() ![]DestDir {
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
		lines << dir.path
	}
	lines << ''

	os.write_file(path, lines.join('\n')) or {
		return error('cannot write ${path}')
	}
}

// Merge override dirs into dest element-by-element.
// overrides[0] replaces dest[0], overrides[1] replaces dest[1], etc.
// Extra entries in overrides are appended.
fn merge_dirs(mut dest []DestDir, overrides []DestDir) {
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

// Save a single edited destination dir back to its source file.
fn save_dest_dir_to_source(idx int, new_path string) {
	if idx < 0 || idx >= app.config.destination_dirs.len {
		return
	}
	source := app.config.destination_dirs[idx].source
	if source == '' {
		return
	}

	data := os.read_file(source) or { return }
	mut lines := data.split('\n')

	if source == config_path() {
		// .env file: find and replace TGT_FLDR_{idx+1}= line
		key_prefix := 'TGT_FLDR_${idx + 1}='
		mut found := false
		for i, line in lines {
			trimmed := line.trim_space()
			if trimmed.starts_with(key_prefix) {
				lines[i] = key_prefix + new_path
				found = true
				break
			}
		}
		if !found {
			// Insert after the last TGT_FLDR_ line, or at end
			mut insert_pos := lines.len
			for i := lines.len - 1; i >= 0; i-- {
				if lines[i].trim_space().starts_with('TGT_FLDR_') {
					insert_pos = i + 1
					break
				}
			}
			lines.insert(insert_pos, key_prefix + new_path)
		}
		os.write_file(source, lines.join('\n')) or { return }
		return
	}

	// .target.folders file: find the src_idx-th significant line
	src_idx := app.config.destination_dirs[idx].src_idx
	if src_idx < 0 {
		return
	}
	mut count := -1
	for i, line in lines {
		trimmed := line.trim_space()
		if trimmed == '' || trimmed.starts_with('#') {
			continue
		}
		count++
		if count == src_idx {
			lines[i] = new_path
			os.write_file(source, lines.join('\n')) or { return }
			return
		}
	}

	// src_idx not found (file was truncated externally) — append
	lines << new_path
	os.write_file(source, lines.join('\n')) or { return }
}
