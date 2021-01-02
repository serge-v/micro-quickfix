# Quickfix plugin for micro editor

Quickfix is a plugin to speedup edit-make-edit development cycle.
It is similar to quickfix window in VIM editor.

You can execute an external command, examine the output in qfix pane
and toggle between list of positions and file locations.

## Commands

### fexec [args]

If args list is empty fexec executes the current line.
Otherwise fexec replaces argument placeholders and executes the arguments.

Placeholders:

	{w} -- current word
	{s} -- current selection
	{o} -- byte offset
	{f} -- current file

Binding examples:

Run make:

	"F8": "command:fexec make"

Grep for word under cursor:

	"F7": "command:fexec grep -n {w} *.go"

Show go doc for selected pkgname.Entity:

	"F8": "command:fexec go doc {s}"

List all declarations in go file:

	"Alt-t": "command:fexec motion -file {f} -mode decls -include func -format text",

### fjump

Jumps to the file under cursor and back.
