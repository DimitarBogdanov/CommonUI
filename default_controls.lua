local DefaultControls = {}
DefaultControls.__index = DefaultControls

function DefaultControls.New(CommonUI)
    local ctrls = {
        CommonUI = CommonUI
    }
    setmetatable(ctrls, DefaultControls)
    return ctrls
end

function DefaultControls:Base()
    local control = self.CommonUI:EmptyControl()

    control.Redraw = function()
        self.CommonUI:DrawAnonymousComponent(self.CommonUI:GetComponent(control.__ID__))
    end

    return control
end

function DefaultControls:Box()
    local control = self:Base()

    -- Custom properties
    control.Colour = colours.white

    -- Overriden functions
    control.Fetch = function()
        local pixels = {}

        for y = control.PosY, control.PosY + control.SizeY - 1 do
            for x = control.PosX, control.PosX + control.SizeX - 1 do
                pixels[x .. ";" .. y] = self.CommonUI.MakePixel(
                    control.Colour, control.Colour, " "
                )
            end
        end
        

        return pixels
    end

    return control
end

function DefaultControls:TextLabel()
    local control = self:Box()

    -- Custom properties
    control.Text = "Label"
    control.TextColour = colours.black

    -- Overriden functions
    local baseFetch = control.Fetch
    control.Fetch = function()
        local pixels = baseFetch()

        local currentX = control.PosX
        local currentY = control.PosY

        for i = 1, #control.Text do
            if currentX >= control.SizeX + control.PosX then
                currentX = control.PosX
                currentY = currentY + 1
            end

            if currentY >= control.SizeY + control.PosY then
                break
            end

            local char = control.Text:sub(i, i)

            if char == "\n" then
                currentX = control.PosX
                currentY = currentY + 1
            else
                pixels[currentX .. ";" .. currentY] = self.CommonUI.MakePixel(
                    control.Colour, control.TextColour,
                    char
                )
                currentX = currentX + 1
            end
        end

        return pixels
    end

    return control
end

function DefaultControls:Header()
    local control = self:TextLabel()

    control.PosX = 2
    control.PosY = 2

    -- Overriden functions
    local baseFetch = control.Fetch
    control.Fetch = function()
        control.PosX = 2
        control.PosY = 2
        control.SizeX = term.getSize()
        control.SizeY = 1

        -- terrible performance but it's ok
        local box = self:Box()
        box.PosX = 1
        box.PosY = 1
        box.SizeX = control.SizeX
        box.SizeY = 3
        box.Colour = control.Colour

        local pixels = box:Fetch()

        for pos, pixel in pairs(baseFetch()) do
            pixels[pos] = pixel
        end

        return pixels
    end

    return control
end

function DefaultControls:Button()
    local control = self:TextLabel()

    -- Custom properties
    control.OnClick = function() end
    control.Text = "Button"

    -- Overriden functions
    control.OnEvent = function(event)
        if event == "gain_focus" then
            control.OnClick()
        end
    end

    return control
end

function DefaultControls:BigButton()
    local control = self:Button()

    -- Overriden functions
    local baseFetch = control.Fetch
    control.Fetch = function()
        -- terrible performance but it's ok
        local box = self:Box()
        box.PosX = control.PosX - 1
        box.PosY = control.PosY - 1
        box.SizeX = control.SizeX + 2
        box.SizeY = control.SizeY + 2
        box.Colour = control.Colour

        local pixels = box:Fetch()

        for pos, pixel in pairs(baseFetch()) do
            pixels[pos] = pixel
        end

        return pixels
    end

    return control
end

function DefaultControls:TextBox()
    local control = self:Box()

    local scroll = 1

    control.Text = ""
    control.PasswordChar = nil
    control.TextColour = colours.black
    control.SetScroll = function(pos)
        if pos > #control.Text then
            pos = #control.Text
        elseif pos < 1 then
            pos = 1
        end
        scroll = pos
    end

    -- Overriden functions
    local baseFetch = control.Fetch
    control.Fetch = function()
        local pixels = baseFetch()

        local currentX = control.PosX
        local currentY = control.PosY

        pixels[currentX .. ";" .. currentY] = self.CommonUI.MakePixel(
            control.TextColour, control.Colour,
            ">"
        )
        currentX = currentX + 1

        for i = scroll, #control.Text do
            if currentX >= control.SizeX + control.PosX then
                currentX = control.PosX
                currentY = currentY + 1
            end

            if currentY >= control.SizeY + control.PosY then
                break
            end

            local char = control.Text:sub(i, i)

            pixels[currentX .. ";" .. currentY] = self.CommonUI.MakePixel(
                control.Colour, control.TextColour,
                control.PasswordChar and control.PasswordChar:sub(1,1) or char
            )
            currentX = currentX + 1
        end

        return pixels
    end

    local baseRedraw = control.Redraw
    control.Redraw = function()
        baseRedraw()

        term.setCursorBlink(control.IsFocused)
        if control.IsFocused then
            term.setBackgroundColour(control.Colour)
            term.setTextColour(control.TextColour)
            term.setCursorPos(control.PosX + #control.Text - scroll + 2, control.PosY)
        end
    end

    control.OnEvent = function(event, ...)
        if event == "gain_focus" then
            control.Redraw()
        elseif event == "lose_focus" then
            control.Redraw()
        elseif event == "char" then
            local c = arg[1]
            control.Text = control.Text .. c

            if #control.Text:sub(scroll - 1) > control.SizeX then
                control.SetScroll(scroll + control.SizeX / 2)
            end

            control.Redraw()
        elseif event == "key" then
            local switch = ({
                -- Backspace
                [259] = function()
                    if #control.Text > 0 then
                        control.Text = control.Text:sub(1, #control.Text-1)
                        control.SetScroll(scroll - 1)
                    end
                    control.Redraw()
                end
            })[arg[1]]
            if switch then switch() end
        end
    end

    return control
end

return DefaultControls