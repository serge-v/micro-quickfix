local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local strings = import("strings")
local os = import("os")

function init()
    config.MakeCommand("make", execMake, config.NoComplete)
    config.MakeCommand("execline", execLine, config.NoComplete)
    config.MakeCommand("jump", jumpToFile, config.NoComplete)
    micro.Log("exec plugin started")
end

function execErr(err)
	buffer.Log(err)
	micro.InfoBar():Error(err)
end

local execPane = nil

function execExit(output, args)
	local b = buffer.NewBuffer(output, "exec")
	b.Type.Scratch = true
	b.Type.Readonly = true
	micro.CurPane():HSplitIndex(b, true)
	execPane = b
	micro.InfoBar():Message("")
end

function execMake(bp, args)
	shell.JobSpawn("make", args, nil, execErr, execExit, bp)
end

function execLine(bp, args)
	local c = bp.Cursor
	local cmd = bp.Buf:Line(c.Y)
	local cmdargs = {}
	local cols = {}

	if #args > 0 then
		cols = args
	elseif #cmd > 0 then
		cols = strings.Split(cmd, " ")
	else
		micro.InfoBar():Error("neither arguments specified nor commands in current line")
		return
	end

	cmd = cols[1]
	for i = 2, #cols do
		buffer.Log("arg: "..cols[i])
		table.insert(cmdargs, cols[i])
	end
	shell.JobSpawn(cmd, cmdargs, nil, execErr, execExit, bp)
end

function jumpToFile(bp, args)
	local c = bp.Cursor
	local line = bp.Buf:Line(c.Y)
	line = string.sub(line, c.X+1)
	micro.Log("jump to "..line)
	local cols = strings.Split(line, ":")
	local fname = cols[1]

	if #fname == 0 then
		micro.InfoBar():Error("no filename at current pos")
		return
	end

	local fi, err = os.Stat(fname)
	if err ~= nil then
		micro.InfoBar():Error("cannot open "..fname)
		return
	end

	if #cols > 1 then
		fname = fname .. ":" .. cols[2]
	end

	micro.InfoBar():Message(fname)
	bp:HandleCommand("tab "..fname)
end
