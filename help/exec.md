# Exec plugin

Provides make and jump to the error functionality.

Commands:

make [target]

    Executes make command. Captures the output.

execline

    Executes current line as a shell script. Captures the output.

jump

    Jumps between captured build errors and actual file locations.


## Example bindings

	{
		"F3": "command:jump",
		"F8": "command:make",
		"F9": "command:execline"
	}
