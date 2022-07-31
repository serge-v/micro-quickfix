VERSION = "2.0.4"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local strings = import("strings")
local regexp = import("regexp")
local os = import("os")

function init()
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
end

function execCurrentLine(bp)
	local c = bp.Cursor
	local cmd = bp.Buf:Line(c.Y)
	micro.Log("fexec: "..cmd)
	if #cmd == 0 then
		micro.InfoBar():Error("current line is empty")
		return
	end
	local s, err = shell.RunCommand(cmd)
	execExit(s, nil)
	if err ~= nil then
		micro.InfoBar():Error(err:Error())
	else
		micro.InfoBar():Message("")
	end
end

function execArgs(bp, args)
	local c = bp.Cursor
	local cmd = ""
	cmd = strings.Join(args, " ")

	if strings.Contains(cmd, "{s}") then
		if c:HasSelection() then
			sel = c:GetSelection()
			cmd = strings.Replace(cmd, "{s}", sel, 1)
		end
	end

	if strings.Contains(cmd, "{w}") then
		local sel = ""
		if not c:HasSelection() then
			c:SelectWord()
		end
		sel = c:GetSelection()
		cmd = strings.Replace(cmd, "{w}", sel, 1)
	end
	
	cmd = strings.Replace(cmd, "{f}", c:Buf().AbsPath, 1)

	local loc = buffer.Loc(c.X, c.Y)
	local offs = buffer.ByteOffset(loc, c:Buf())
	cmd = strings.Replace(cmd, "{o}", tostring(offs), 1)
	cmd = strings.Replace(cmd, "{l}", tostring(c.Y+1), 1)
	cmd = strings.Replace(cmd, "{c}", tostring(c.X+1), 1)

	micro.Log("fexec: "..cmd)
	micro.InfoBar():Message("running: "..cmd)
	local s, err = shell.RunCommand(cmd)
	execExit(s, nil)
	if err ~= nil then
		micro.InfoBar():Error(err:Error())
	else
		micro.InfoBar():Message("")
	end
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
			return
		end
	end

	local c = bp.Cursor
	local line = bp.Buf:Line(c.Y)
	line = string.sub(line, c.X+1)
	micro.Log("jump to "..line)

	local arr = strings.Split(line, ":")
	if #arr == 0 then
		micro.InfoBar():Error("no filename at current pos")
		return
	end

	local fi, err = os.Stat(arr[1])
	if err ~= nil then
		micro.InfoBar():Error("no filename at current pos")
		return
	end

	rex = regexp.MustCompile("[^:]+:[0-9]+:[0-9]+:")
	local fname = rex:FindString(line)
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

	plainfname = strings.Split(fname, ":")[1]
	micro.Log("plainfname", plainfname)

	micro.InfoBar():Message(fname)

    local tabs = micro.Tabs()
    for i = 1,#tabs.List do
        for j = 1,#tabs.List[i].Panes do
            local name = tabs.List[i].Panes[j]:Name()
            micro.Log("tab", i, "pane", i, "name", name)
            if plainfname == name then
                micro.Log("set active:", name)
                tabs:SetActive(i-1)
                tabs.List[i]:SetActive(j-1)
                tabs.List[i].Panes[j]:SetActive(true)
                tabs.List[i].Panes[j]:HandleCommand("open "..fname)
                return
            end
        end
    end

	micro.Log("fname: "..fname)
	bp:HandleCommand("tab "..fname)
	bp:Center()
end

function onQuit(p)
	if p == qfixPane then
		qfixPane = nil
	end
end

