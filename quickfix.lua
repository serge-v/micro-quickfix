VERSION = "2.0.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local strings = import("strings")
local regexp = import("regexp")
local os = import("os")

function init()
	config.MakeCommand("fmake", execMake, config.NoComplete)
	config.MakeCommand("fexec", execLine, config.NoComplete)
	config.MakeCommand("fjump", jumpToFile, config.NoComplete)
	config.AddRuntimeFile("quickfix", config.RTHelp, "help/quickfix.md")
end

local qfixPane = nil
local tab = nil
local active = 0

function execExit(output, args)
	if qfixPane ~= nil then
		qfixPane:Quit()
	end

	local b = buffer.NewBuffer(output, "qfix")
	b.Type.Scratch = true
	b.Type.Readonly = true
	micro.CurPane():HSplitIndex(b, true)
	qfixPane = micro.CurPane()
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
	if name == "qfix" then
		qfixPane:Quit()
		qfixPane = nil
		return
	end

	shell.JobSpawn("make", args, nil, nil, execExit, bp)
end

function execCurrentLine(bp)
	local c = bp.Cursor
	local cmd = bp.Buf:Line(c.Y)
	micro.Log("fexec: "..cmd)
	if #cmd == 0 then
		micro.InfoBar():Error("current line is empty")
		return
	end
	shell.JobStart(cmd, nil, nil, execExit, bp)
end

function execArgs(bp, args)
	local cmd = ""
	cmd = strings.Join(args, " ")

	if strings.Contains(cmd, "{w}") then
		local c = bp.Cursor
		local sel = ""
		if not c:HasSelection() then
			c:SelectWord()
		end
		sel = c:GetSelecion()
		cmd = strings.Replace(cmd, "{w}", sel, 1)
	end

	micro.Log("fexec: "..cmd)
	shell.JobStart(cmd, nil, nil, execExit, bp)
end

function execLine(bp, args)
	local name = ""
	local p = micro.CurPane()
	if p ~= nil then
		name = p:Name()
	end
	if name == "qfix" then
		qfixPane:Quit()
		qfixPane = nil
		return
	end

	if #args > 0 then
		execArgs(bp, args)
	else
		execCurrentLine(bp)
	end
end

function jumpToFile(bp, args)
	local name = ""
	local p = micro.CurPane()
	if p ~= nil then
		name = p:Name()
	end
	if name ~= "qfix" then
		if qfixPane ~= nil then
			qfixPane:SetActive(false)
			tab:SetActive(1)
			local tabs = micro.Tabs()
			tabs:SetActive(active)
		else
			micro.InfoBar():Error("use fexec command to execute current line")
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
	if p == qfixPane then
		qfixPane = nil
	end
end

