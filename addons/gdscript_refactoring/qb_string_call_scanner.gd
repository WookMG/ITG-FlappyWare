@tool
extends RefCounted

## Finds string-literal method references that this plugin's LSP-based
## rename cannot see. GDScript's dynamic-dispatch call forms pass the
## method name as a plain string/StringName ARGUMENT instead of a real
## identifier token (call_deferred("foo"), call("foo"), rpc("foo"),
## rpc_id(id, "foo"), has_method("foo"), Callable(target, "foo")) --
## Godot's language server resolves identifiers, not string contents, so
## textDocument/rename silently never touches these call sites, leaving
## them pointing at the OLD name after a rename.
##
## Best-effort by construction: there is no static receiver type to check
## here (the whole point of these calls is dynamic/duck-typed dispatch --
## see qb_ObjUtil-style code elsewhere in this project for why), so this
## is a project-wide textual scan gated only on the string's content
## matching old_name exactly. That is the same name-only blind spot the
## LSP's own symbol matching already has for shadowed variables (see
## qb_scope_filter.gd's own doc comment) -- an unrelated method elsewhere
## that happens to share the name would also match. Mitigated by the
## rename dialog always showing every edit in its Before/After preview
## before anything is written, so a spurious match is caught by eye
## rather than silently applied.
##
## Line-based (one call expression per line), like qb_symbol_replacer.gd
## and the parameter-rename fallback in qb_rename_dialog.gd -- a call
## whose arguments are split across multiple lines is not matched.

const LspClient = preload("res://addons/gdscript_refactoring/qb_lsp_client.gd")

## Name-first call forms: the method name is the call's FIRST argument.
const FIRST_ARG_KEYWORDS := ["call_deferred", "callv", "call", "has_method", "rpc"]
## Name-second call forms: the method name is the call's SECOND argument
## (the first is something else -- a peer id for rpc_id, the target
## object for Callable).
const SECOND_ARG_KEYWORDS := ["rpc_id"]

## Signal-name string forms. These take a SIGNAL name (not a method name) as
## their first string argument, so they are gated on `signal <name>` being
## declared, not `func <name>` -- kept separate so a method rename never
## touches a same-named signal and vice versa.
const SIGNAL_FIRST_ARG_KEYWORDS := ["connect", "disconnect", "emit_signal", "is_connected", "has_signal"]

## Callable-by-identifier forms: the method name appears as a real identifier
## token followed by a Callable method, e.g. `obj.my_method.call_deferred(a)` or
## `my_method.bind(x)`. The LSP resolves these only when the receiver's type is
## statically known -- calls on a dynamically-typed object (a loaded scene, an
## untyped var) are missed, so we scan for them textually.
const CALLABLE_METHODS := ["call_deferred", "callv", "call", "bindv", "bind", "rpc_id", "rpc", "unbind"]


## Returns { uri: [ {range:{start,end}, newText}, ... ] } for every string-
## literal method reference to [old_name] found across [gd_files] (absolute
## paths, as returned by qb_file_scanner.gd's collect_gd_files()).
func find_string_call_edits(gd_files: PackedStringArray, old_name: String, new_name: String) -> Dictionary:
	var out: Dictionary = {}
	var regexes := _build_regexes(old_name)
	for abs_path in gd_files:
		var f := FileAccess.open(abs_path, FileAccess.READ)
		if f == null:
			continue
		var lines := f.get_as_text().split("\n")
		f.close()
		var edits: Array = []
		for i in lines.size():
			_collect_line_edits(lines[i], i, regexes, new_name, edits)
		if not edits.is_empty():
			out[LspClient.path_to_uri(abs_path)] = edits
	return out


## True if [old_name] is declared as a function anywhere in [gd_files] --
## used by the caller to gate this (relatively expensive, whole-project)
## scan to actual method renames, skipping it for plain variable renames
## where it would only add noise.
func is_declared_as_function(gd_files: PackedStringArray, old_name: String) -> bool:
	var rx := RegEx.new()
	rx.compile("^\\s*(?:static\\s+)?func\\s+%s\\s*\\(" % _regex_escape(old_name))
	for abs_path in gd_files:
		var f := FileAccess.open(abs_path, FileAccess.READ)
		if f == null:
			continue
		var text := f.get_as_text()
		f.close()
		for line in text.split("\n"):
			if rx.search(line):
				return true
	return false


## Like find_string_call_edits but for SIGNAL-name string literals
## (connect("sig", ...), disconnect(...), emit_signal("sig", ...),
## is_connected(...), has_signal(...)). Kept separate from the method scan
## so renaming a signal never rewrites a same-named method and vice versa.
func find_signal_string_edits(gd_files: PackedStringArray, old_name: String, new_name: String) -> Dictionary:
	var out: Dictionary = {}
	var regexes := _build_signal_regexes(old_name)
	for abs_path in gd_files:
		var f := FileAccess.open(abs_path, FileAccess.READ)
		if f == null:
			continue
		var lines := f.get_as_text().split("\n")
		f.close()
		var edits: Array = []
		for i in lines.size():
			_collect_line_edits(lines[i], i, regexes, new_name, edits)
		if not edits.is_empty():
			out[LspClient.path_to_uri(abs_path)] = edits
	return out


## True if [old_name] is declared as a signal anywhere in [gd_files] --
## gates the signal scan to actual signal renames.
func is_declared_as_signal(gd_files: PackedStringArray, old_name: String) -> bool:
	var rx := RegEx.new()
	rx.compile("^\\s*signal\\s+%s\\b" % _regex_escape(old_name))
	for abs_path in gd_files:
		var f := FileAccess.open(abs_path, FileAccess.READ)
		if f == null:
			continue
		var text := f.get_as_text()
		f.close()
		for line in text.split("\n"):
			if rx.search(line):
				return true
	return false


func _build_regexes(old_name: String) -> Array[RegEx]:
	var escaped := _regex_escape(old_name)
	var list: Array[RegEx] = []
	for kw in FIRST_ARG_KEYWORDS:
		var rx := RegEx.new()
		# \b (not a required leading ".") before the keyword: GDScript's most
		# common form is a bare implicit-self call ("call_deferred(...)", no
		# "self." or object prefix -- confirmed against this project's actual
		# call sites), so the keyword can be preceded by ".", whitespace, "(",
		# or line-start. \b on both sides of the keyword still keeps ".call("
		# from matching inside ".call_deferred(" -- "_" is a word character, so
		# there is no boundary between "call" and "_deferred".
		# (?![\w]) after the closing quote's backreference guards against
		# matching "foo" inside a longer "foobar" string.
		rx.compile("\\b%s\\b\\s*\\(\\s*&?([\"'])(%s)\\1(?![\\w])" % [kw, escaped])
		list.append(rx)
	for kw in SECOND_ARG_KEYWORDS:
		var rx := RegEx.new()
		# Same bare-call reasoning as above: rpc_id(peer_id, "name") is commonly
		# called without an explicit receiver.
		rx.compile("\\b%s\\b\\s*\\(\\s*[^,()]+,\\s*&?([\"'])(%s)\\1(?![\\w])" % [kw, escaped])
		list.append(rx)
	var callable_rx := RegEx.new()
	callable_rx.compile("\\bCallable\\s*\\(\\s*[^,()]+,\\s*&?([\"'])(%s)\\1(?![\\w])" % escaped)
	list.append(callable_rx)
	# Callable-by-identifier: <name>.<callable_method>( -- the method name is a
	# real token (not a string) directly before a Callable method. Group 1 is the
	# char before the name; it excludes word chars (so we don't match inside a
	# longer identifier) but ALLOWS a leading "." so object.method.call_deferred()
	# is caught. Group 2 is the name, matching _collect_line_edits' group-2 read.
	var callable_methods_alt := "|".join(CALLABLE_METHODS)
	for cm_rx in [RegEx.new()]:
		cm_rx.compile("(^|[^\\w])(%s)\\.(?:%s)\\b\\s*\\(" % [escaped, callable_methods_alt])
		list.append(cm_rx)
	return list


## Builds the SIGNAL-name regexes: each keyword takes the signal name as its
## first string argument. Same \b-both-sides and bare-call reasoning as
## _build_regexes; both "name" and &"name" (StringName) forms are matched.
func _build_signal_regexes(old_name: String) -> Array[RegEx]:
	var escaped := _regex_escape(old_name)
	var list: Array[RegEx] = []
	for kw in SIGNAL_FIRST_ARG_KEYWORDS:
		var rx := RegEx.new()
		rx.compile("\\b%s\\b\\s*\\(\\s*&?([\"'])(%s)\\1(?![\\w])" % [kw, escaped])
		list.append(rx)
	return list


func _collect_line_edits(line: String, line_idx: int, regexes: Array[RegEx],
		new_name: String, out_edits: Array) -> void:
	# Whole-line comment: cheap, common case to skip. A trailing inline
	# "# ..." comment after real code on the same line is NOT filtered here
	# -- same trade-off qb_symbol_replacer.gd's own line-based scan accepts.
	if line.strip_edges().begins_with("#"):
		return
	for rx in regexes:
		for m in rx.search_all(line):
			out_edits.append({
				"range": {
					"start": {"line": line_idx, "character": m.get_start(2)},
					"end":   {"line": line_idx, "character": m.get_end(2)},
				},
				"newText": new_name,
			})


func _regex_escape(s: String) -> String:
	var special := ["\\", ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"]
	var out := s
	for ch in special:
		out = out.replace(ch, "\\" + ch)
	return out
