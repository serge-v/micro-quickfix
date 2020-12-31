VERSION = "2.0.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local strings = import("strings")
local regexp = import("regexp")
local os = import("os")

function init()
	config.MakeCommand("make", execMake, config.NoComplete)
	config.MakeCommand("execline", execLine, config.NoComplete)
	config.MakeCommand("jump", jumpToFile, config.NoComplete)
	config.AddRuntimeFile("exec", config.RTHelp, "help/exec.md")
end

--function execErr(err)
--	micro.Log("execline err: "..err)
--	micro.InfoBar():Error("execline error: "..err)
--end

local execPane = nil
local tab = nil
local active = 0

function execExit(output, args)
	if execPane ~= nil then
		execPane:Quit()
	end

	local b = buffer.NewBuffer(output, "exec")
	b.Type.Scratch = true
	b.Type.Readonly = true
	micro.CurPane():HSplitIndex(b, true)
	execPane = micro.CurPane()
	tab = micro.CurTab()
	local tabs = micro.Tabs()
	active = tabs:Active()

	micro.InfoBar():Message("")
end

function execMake(bp, args)
	local name = ""
	local p = micro.CurPane()
	if p ~= nil then
		name = p:Name()
	end
	if name == "exec" then
		execPane:Quit()
		execPane = nil
		return
	end

	shell.JobSpawn("make", args, nil, nil, execExit, bp)
end

function execLine(bp, args)
	local name = ""
	local p = micro.CurPane()
	if p ~= nil then
		name = p:Name()
	end
	if name == "exec" then
		micro.InfoBar():Error("use jump command to go to the file")
		return
	end

	local c = bp.Cursor
	local cmd = bp.Buf:Line(c.Y)
	micro.Log("execline: "..cmd)
	if #cmd == 0 then
		micro.InfoBar():Error("current line is empty")
		return
	end
	shell.JobStart(cmd, nil, nil, execExit, bp)
end

function jumpToFile(bp, args)
	local name = ""
	local p = micro.CurPane()
	if p ~= nil then
		name = p:Name()
	end
	if name ~= "exec" then
		if execPane ~= nil then
			execPane:SetActive(false)
			tab:SetActive(1)
			local tabs = micro.Tabs()
			tabs:SetActive(active)
		else
			micro.InfoBar():Error("use execline command to execute current line")
		end
		return
	end

	local c = bp.Cursor
	local line = bp.Buf:Line(c.Y)
	line = string.sub(line, c.X+1)
	micro.Log("jump to "..line)

	rex = regexp.MustCompile("[^:]+:[0-9]+:[0-9]:")
	fname = rex:FindString(line)
	if fname == "" then
		rex = regexp.MustCompile("[^:]+:[0-9]+:")
		fname = rex:FindString(line)
	end
	if fname == "" then
		rex = regexp.MustCompile("[^:]+:")
		fname = rex:FindString(line)
	end
	if fname == "" then
		rex = regexp.MustCompile("[^ \t].*")
		fname = rex:FindString(line)
	end
	fname = strings.TrimSuffix(fname, ":")

	if #fname == 0 then
		micro.InfoBar():Error("no filename at current pos")
		return
	end

	micro.InfoBar():Message(fname)
	micro.Log("fname: "..fname)
	bp:HandleCommand("tab "..fname)
	bp:Center()
end

function onQuit(p)
	if p == execPane then
		execPane = nil
	end
end

