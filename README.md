# exec plugin for micro editor

Provides run make and jump to the error functionality.

## Commands

### make

Executes make. Captures the output.

### execline

Executes current line. Captures the output.

### jump

Jumps to the file under cursor. On the next execution jumps back to the output pane.

## Example bindings.json

	{
	    "F3": "command:jump",
	    "F5": "command:execline",
	    "F8": "command:make"
	}
