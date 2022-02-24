local CommonUI = {}
CommonUI.__index = CommonUI

local function UUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function Split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

local function IsPosInCmp(x, y, cmp)
    return (x >= cmp.PosX) and (x < cmp.PosX + cmp.SizeX)
            and (y >= cmp.PosY) and (y < cmp.PosY + cmp.SizeY)
end

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function CommonUI.New(useTerm)
    useTerm = useTerm or term

    local newT = {
        InternalObjectList = {},
        Buffer = {},
        Term = useTerm,
        Theme = {
            BG = colours.black,
            FG = colours.white
        },
        FocusedComponentId = nil
    }

    setmetatable(newT, CommonUI)

    return newT
end

function CommonUI.MakePixel(bgColour, fgColour, content)
    return {
        BG = (bgColour or colours.black),
        FG = (fgColour or colours.black),
        CHAR = (content and tostring(content):sub(1, 1) or " ")
    }
end

function CommonUI.EmptyControl()
    return {
        -- Position
        PosX = 1,
        PosY = 1,

        -- Size
        SizeX = 1,
        SizeY = 1,

        -- Drawing
        DrawPriority = 1,
        Enabled = true,

        -- Modified by CommonUI
        IsFocused = false,

        -- This function returns a table of pixels to be written to the screen
        Fetch = function() return {} end,

        -- This function lets your control receive events
        OnEvent = function(event, ...) end
    }
end

function CommonUI:AddComponent(cmp)
    local id = UUID()
    cmp.__ID__ = id
    self.InternalObjectList[#self.InternalObjectList+1] = cmp
    return id
end

function CommonUI:RemoveComponent(id)
    for i, cmp in pairs(self.InternalObjectList) do
        if cmp.__ID__ == id then
            table.remove(self.InternalObjectList, i)
            return
        end
    end
end

function CommonUI:DrawComponent(id)
    for _, v in pairs(self.InternalObjectList) do
        if v and v.__ID__ == id then
            self:DrawAnonymousComponent(v)
            return
        end
    end
end

function CommonUI:GetComponent(id)
    for _, cmp in pairs(self.InternalObjectList) do
        if cmp.__ID__ == id then
            return cmp
        end
    end
end

function CommonUI:DrawAnonymousComponent(component)
    local pixels = component:Fetch()
    for pos, pixel in pairs(pixels) do
        --self.Buffer[pos] = colour
        local split = Split(pos, ";")
        local x = tonumber(split[1])
        local y = tonumber(split[2])
        self.Term.setCursorPos(x, y)
        self.Term.setBackgroundColour(pixel.BG)
        self.Term.setTextColour(pixel.FG)
        self.Term.write(pixel.CHAR)
    end
end

function CommonUI:ClearScreen()
    self.Term.setBackgroundColour(self.Theme.BG)
    self.Term.setTextColour(self.Theme.FG)
    self.Term.clear()
    self.Buffer = {}
end

function CommonUI:DrawScreen()
    self.Buffer = {}

    for _, c in spairs(self.InternalObjectList, function(_, a, b) return a<b end) do
        if c.Enabled then
            self:DrawAnonymousComponent(c)
        end
    end

    for pos, pixel in pairs(self.Buffer) do
        local split = Split(pos, ";")
        local x = tonumber(split[1])
        local y = tonumber(split[2])
        self.Term.setCursorPos(x, y)
        self.Term.setBackgroundColour(pixel.BG)
        self.Term.setTextColour(pixel.FG)
        self.Term.write(pixel.CHAR)
    end
end

function CommonUI:ClearComponents()
    self.InternalObjectList = {}
    self.FocusedComponentId = ""
end

function CommonUI:FocusComponent(newId)
    for _, cmp in pairs(self.InternalObjectList) do
        if cmp.__ID__ == newId then
            if self.FocusedComponentId then
                for _, oldCmp in pairs(self.InternalObjectList) do
                    if oldCmp.__ID__ == self.FocusedComponentId then
                        oldCmp.IsFocused = false
                        oldCmp.OnEvent("lose_focus")
                        break
                    end
                end
            end

            cmp.Enabled = true

            self.FocusedComponentId = newId
            cmp.IsFocused = true
            cmp.OnEvent("gain_focus")

            break
        end
    end
end

function CommonUI:BeginEventLoop()
    self:DrawScreen()
    self.EventLoopRunning = true
    while self.EventLoopRunning do
        local fn = function(event, ...)
            if event == "mouse_click" then
                -- Change focused component
                if arg[1] == 1 then
                    local topmostCmp
                    for _, cmp in pairs(self.InternalObjectList) do
                        if IsPosInCmp(arg[2], arg[3], cmp) then
                            if topmostCmp then
                                if cmp.DrawPriority >= topmostCmp.DrawPriority then
                                    topmostCmp = cmp
                                end
                            else
                                topmostCmp = cmp
                            end
                        end
                    end
                    if topmostCmp then
                        self:FocusComponent(topmostCmp.__ID__)
                    end
                end
            end


            local id = self.FocusedComponentId

            if id then
                for _, cmp in pairs(self.InternalObjectList) do
                    if cmp.__ID__ == id and cmp.Enabled then
                        cmp.OnEvent(event, unpack(arg))
                        break
                    end
                end
            end
        end
        fn(os.pullEvent())
    end
end

function CommonUI:EndEventLoop()
    self.EventLoopRunning = false
end

return CommonUI