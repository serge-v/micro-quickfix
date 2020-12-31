# Exec plugin

Exec plugin runs an external commands and displays the output in
scratch pane.

User can jump between errors in the scratch window and files.

## Commands

### make [target]

Run make command, open scratch pane, show the make output.

### jump

If the current pane is `exec` opens the file under cursor in new tab.

If the current pane is not `exec` jumps back to `exec` pane.

### execline [cmdline]

If cmdline is not empty executes the `cmdline`.

If cmdline is empty executes current line as an external command.

## Example bindings

	{
		"F3": "command:jump",
		"F8": "command:make",
		"F9": "command:execline"
	}
