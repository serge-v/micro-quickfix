# exec plugin for micro editor

## Commands

### make

Executes make. Opens scratch buffer with a list of errors.

### execline

Executes current line. Opens scratch buffer with a list of errors.

### jump

Jumps to the file under cursor.


## Example bindings.json

	{
	    "F3": "command:jump",
	    "F5": "command:execline",
	    "F8": "command:make"
	}
