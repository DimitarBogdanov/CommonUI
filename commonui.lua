local CommonUI = {}
CommonUI.__index = CommonUI

local ShiftHeld = false
local CtrlHeld = false

function NewUuid()
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
    end)
end

--------------------------------------------------
-- BUILT-IN COMPONENTS                          --
--------------------------------------------------

function CommonUI.NewButton(text,
                            posX,
                            posY,
                            bigButton,
                            bgColor,
                            fgColor,
                            onClick)
    return {
        PosX = posX,
        PosY = posY,
        EndX = posX + string.len(text) + (bigButton and 1 or -1),
        EndY = posY + (bigButton and 2 or 0),
		
		SetText = function(self, t)
			text = t
			EndX = posX + string.len(text)
		end,
		
        Draw = function(self)
            -- 2 from padding on both sides
            local xSize = string.len(text) + 2
            
            local currentY = posY
            
            local prevBgColor = term.getBackgroundColor()
            local prevFgColor = term.getTextColor()
            
            term.setBackgroundColor(bgColor)
            term.setTextColor(fgColor)
            
            if bigButton then
                term.setCursorPos(posX, currentY)
                term.write(string.rep(" ", xSize))
                currentY = currentY + 1
            end
            
            term.setCursorPos(posX, currentY)
			if bigButton then
				term.write(" " .. text .. " ")
			else
				term.write(text)
			end
            currentY = currentY + 1
            
            if bigButton then
                term.setCursorPos(posX, currentY)
                term.write(string.rep(" ", xSize))
            end
            
            term.setBackgroundColor(prevBgColor)
            term.setTextColor(prevFgColor)
        end,
        
        OnEvent = function(self, eventName, data)
            if eventName == "mouse_click" then
                local btn = data[1]
                
                if btn == 1 then
                    onClick()
                end
            end
        end
    }
end

function CommonUI.NewListView(posX, posY, sizeX, sizeY,
							  items, bgColor, fgColor,
							  onClick)
	
	local highlightColor = colors.black
	if fgColor == highlightColor then
		highlightColor = colors.white
	end
	
	return {
		PosX = posX,
		PosY = posY,
		EndX = posX + sizeX - 1,
		EndY = posY + sizeY - 1,
		
		Items = items,
		Scroll = 1,
		
		Draw = function(self)
			CommonUI.DrawBox(posX, posY, sizeX, sizeY, bgColor)
			local currentY = posY
			for i,item in pairs(self.Items) do
				if currentY > self.EndY then
					break
				end
			
				if i >= self.Scroll then
					term.setCursorPos(posX, currentY)
					CommonUI.SetColors(bgColor, fgColor)
					term.write(type(item) == "table" and tostring(item.Name) or tostring(item))
					currentY = currentY + 1
				end
			end
			
			-- don't draw scroll bar if we have less items
			-- than rows available
			CommonUI.SetColors(bgColor, fgColor)
			local itemCount = table.getn(self.Items)
			if itemCount > sizeY then
				term.setBackgroundColor(fgColor)
				term.setTextColor(bgColor)
				for y = posY, self.EndY do
					term.setCursorPos(self.EndX, y)
					
					term.write(string.char(127))
				end
				term.setBackgroundColor(bgColor)
				term.setTextColor(fgColor)
				
				term.setBackgroundColor(fgColor)
				for y = posY, self.EndY do
					term.setCursorPos(self.EndX - 1, y)
					term.write(" ")
				end
				term.setTextColor(fgColor)
				
				local scrollDotSize = math.floor(itemCount / sizeY)
				if scrollDotSize <= 0 then
					scrollDotSize = 0
				end
				
				local scrollDotPos = (sizeY / itemCount) * self.Scroll
				if scrollDotPos <= 0 then
					scrollDotPos = 1
				elseif scrollDotPos + scrollDotSize >= self.EndY then
					scrollDotPos = self.EndY - scrollDotSize - 1
				end
				
				term.setBackgroundColor(bgColor)
				term.setTextColor(fgColor)
				for i = 1, scrollDotSize do
					term.setCursorPos(self.EndX, scrollDotPos + i + 1)
					local _, curY = term.getCursorPos()
					
					if curY > self.EndY then
						break
					end
					
					if scrollDotSize == 1 then
						term.write(string.char(143))
					else
						term.write(" ")
					end
				end
			end
		end,
		
		OnEvent = function(self, event, data)
			if event == "mouse_click" then
				if data[1] == 1 then
					local itemCount = table.getn(self.Items)
					if (itemCount > sizeY) and (data[2] == self.EndX) then
						self.Scroll = math.floor((data[3]-posX) * (itemCount/sizeY))
						if self.Scroll <= 0 then
							self.Scroll = 1
						end
						self:Draw()
					elseif data[2] < self.EndX - 1 then
						local i = data[3] - posY + self.Scroll
						onClick(i)
					end
				end
			elseif event == "mouse_scroll" then
				local direction = data[1]
				local tableSize = table.getn(self.Items)
				
				if tableSize <= sizeY then
					if self.Scroll ~= 1 then
						self.Scroll = 1
						self:Draw()
					end
					return
				end
				
				if self.Scroll + direction <= 1 then
					self.Scroll = 1
				elseif self.Scroll + direction > tableSize then
					self.Scroll = tableSize
				else
					self.Scroll = self.Scroll + direction
				end
				
				self:Draw()
			end
		end
	}
end

function CommonUI.NewLabel(posX, posY, text,
                           bgColor, fgColor)
    return {
        PosX = posX,
        PosY = posY,
        EndX = posX + string.len(text),
        EndY = posY,
		
		SetText = function(self, t)
			text = t
			EndX = posX + string.len(text)
		end,
    
        Draw = function(self)
            local cX, cY = term.getCursorPos()
            local oldBgColor = term.getBackgroundColor()
            local oldFgColor = term.getTextColor()
            
            term.setCursorPos(posX, posY)
            CommonUI.SetColors(bgColor, fgColor)
            
            term.write(text)
            
            term.setCursorPos(cX, cY)
            CommonUI.SetColors(oldBgColor, oldFgColor)
        end,
        
        OnEvent = function() end
    }
end

function CommonUI.NewTextField(posX, posY, sizeX,
                               bgColor, fgColor,
                               maxLength, big,
							   passwordChar, text)
    -- TODO: Text scrolling
    if maxLength > (sizeX-2) then
        maxLength = sizeX - 2
    end
    
    return {
        PosX = posX,
        PosY = posY,
        EndX = posX + sizeX - 1,
        EndY = posY + (big and 2 or 0),
        Text = text,
        
        Draw = function(self, refocus)
            local currentY = posY
            
            local oldBgColor = term.getBackgroundColor()
            local oldFgColor = term.getTextColor()
            term.setBackgroundColor(bgColor)
            term.setTextColor(fgColor)
            
            if big then
                term.setCursorPos(posX, currentY)
                term.write(string.rep(" ", sizeX))
                currentY = currentY + 1
            end
            
            term.setCursorPos(posX, currentY)
            term.write(">" .. (passwordChar and string.rep(passwordChar, string.len(self.Text)) or self.Text) .. string.rep(" ", sizeX - string.len(self.Text) - 1))
            currentY = currentY + 1
            
            if big then
                term.setCursorPos(posX, currentY)
                term.write(string.rep(" ", sizeX))
            end
        end,
        
        OnEvent = function(self, eventName, data)
            if eventName == "gain_focus" then
                term.setCursorPos(posX + 1, big and posY+1 or posY)
                term.setCursorBlink(true)
                term.setBackgroundColor(bgColor)
                term.setTextColor(fgColor)
            elseif eventName == "lose_focus" then
                term.setCursorBlink(false)
            elseif eventName == "mouse_click" then
                local btn = data[1]
                local x = data[2]
                local y = data[3]
                
                if btn == 1 then
					term.setCursorPos(posX + string.len(self.Text) + 1, y)
					
					-- This lets you position the cursor anywhere
					-- within the text field. Works wonders, but
					-- scrolling needs to be implemented first.
					--[[
                    if big and (y ~= posY+1) then
                        term.setCursorPos(posX + string.len(self.Text) + 1, posY+1)
                        return
                    end
                
                    local y = big and posY+1 or posY
                    if x == posX then
                        term.setCursorPos(x + 1, y)
                    elseif x < (posX + string.len(self.Text) + 1) then
                        term.setCursorPos(x, y)
                    else
                        term.setCursorPos(posX + string.len(self.Text) + 1, y)
                    end
					]]
                end
			elseif eventName == "char" then
				local c = data[1]
				if string.len(self.Text) < maxLength then
                    self.Text = self.Text .. c
                    term.setCursorPos(string.len(self.Text) + posX, big and posY+1 or posY)
                    term.write(passwordChar and passwordChar or c)
                end
            elseif eventName == "key" then
                if data[1] == 259 then
                    local len = string.len(self.Text)
                    if len > 0 then
                        self.Text = string.sub(self.Text, 1, len - 1)
                        local cx, cy = term.getCursorPos()
                        self:Draw()
                        term.setCursorPos(posX + len, big and posY+1 or posY)
                    end
                end
            end
        end
    }
end

function CommonUI.DrawBox(x, y, width, height, color)
	local prevX, prevY = term.getCursorPos()
    local prevBgColor = term.getBackgroundColor()
	
	term.setBackgroundColor(color)
	
	local str = string.rep(" ", width)
	for i=0, height - 1 do
		term.setCursorPos(x, y+i)
		term.write(str)
	end
	
	term.setBackgroundColor(prevBgColor)
    term.setCursorPos(prevX, prevY)
end

function CommonUI.DrawHeader(text,
                             bgColor,
                             fgColor,
							 yPos)
    local prevX, prevY = term.getCursorPos()
    local prevBgColor = term.getBackgroundColor()
    local prevFgColor = term.getTextColor()
    
	yPos = yPos or 1
	
    term.setBackgroundColor(bgColor)
    term.setTextColor(fgColor)
    
    term.setCursorPos(1,yPos)
    term.clearLine()
    term.setCursorPos(2,yPos + 1)
    term.clearLine()
    term.write(text)
    term.setCursorPos(1,yPos + 2)
    term.clearLine()
    
    term.setBackgroundColor(prevBgColor)
    term.setTextColor(prevFgColor)
    term.setCursorPos(prevX, prevY)
end

function CommonUI.DrawFooter(text)
    local prevX, prevY = term.getCursorPos()
    local prevBgColor = term.getBackgroundColor()
    local prevFgColor = term.getTextColor()
    
    local _,ySize = term.getSize()
    term.setCursorPos(2, ySize)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black)
    term.clearLine()
    term.write(text)
    
    term.setCursorPos(prevX, prevY)
    term.setBackgroundColor(prevBgColor)
    term.setTextColor(prevFgColor)
end

function CommonUI.ClearScreen(color)
    term.setBackgroundColor(color)
    term.clear()
    term.setCursorPos(1,1)
end

function CommonUI.SetColors(bgColor, fgColor)
    if bgColor then
        term.setBackgroundColor(bgColor)
    end
    if fgColor then
        term.setTextColor(fgColor)
    end
end


--------------------------------------------------
-- COMMON UI LOGIC                              --
--------------------------------------------------

function CommonUI.new()
	local new = {}
	setmetatable(new, CommonUI)
	
	new.Id = NewUuid()
	new.Components = {}
	new.CurrentFocusedComponent = nil
	
	return new
end

-- component should be a table
function CommonUI:AddComponent(component)
    if type(component.Draw) ~= "function" then
        error("All components must have a Draw function")
    elseif type(component.OnEvent) ~= "function" then
        error("All components must have an OnEvent function")
    elseif not component.PosX then
        error("All components must have a PosX number")
    elseif not component.PosY then
        error("All components must have a PosY number")
    elseif not component.EndX then
        error("All components must have an EndX number")
    elseif not component.EndY then
        error("All components must have an EndY number")
    end
    
    local id = NewUuid()
    
    component._CID = id
    table.insert(self.Components, component)
    
    return id
end

-- Returns the character for displaying by key code
function CommonUI.GetKeyGlyph(id)
    -- For letters
    if id >= 65 and id <= 90 then
        return keys.getName(id)
    end
    
    -- For all other characters
    local t = {
        [32] = " ",
        [39] = "'",
        [44] = ",",
        [45] = "-",
        [46] = ".",
        [47] = "/",
        [48] = "0",
        [49] = "1",
        [50] = "2",
        [51] = "3",
        [52] = "4",
        [53] = "5",
        [54] = "6",
        [55] = "7",
        [56] = "8",
        [57] = "9",
        [59] = ";",
        [61] = "=",
        [91] = "[",
        [92] = "\\",
        [93] = "]",
        [96] = "`",
        [258] = "\t",
        [320] = "0",
        [321] = "1",
        [322] = "2",
        [323] = "3",
        [324] = "4",
        [325] = "5",
        [326] = "6",
        [327] = "7",
        [328] = "8",
        [329] = "9",
        [330] = ",",
        [331] = "/",
        [332] = "*",
        [333] = "-",
        [334] = "+"
    }
    return t[id]
end

-- Returns the component by id
function CommonUI:GetComponent(id)
    for _, cmp in pairs(self.Components) do
        if cmp._CID == id then
            return cmp
        end
    end
end

-- id: the ID of the cmp from RegisterComponent
-- noErrorIfNil: if true, the function won't
--               error if the component isn't
--               found. Optional argument
function CommonUI:DrawComponent(id, noErrorIfNil)
    local cmp = self:GetComponent(id)
    
    if cmp then
        cmp:Draw()
        return
    end
    
    if not noErrorIfNil then
        error("component " .. tostring(id) .. " doesn't exist")
    end
end

-- Begin main loop for handling events
-- such as button clicks, etc.
function CommonUI:BeginEventLoop()
	self.Run = true
    while self.Run do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
		
        -- Remove first item from eventData
        local _ned = {}
        for i,v in pairs(eventData) do
            if i ~= 1 then
                table.insert(_ned, v)
            end
        end
        eventData = _ned
        
        if event == "mouse_click" then
            local x = eventData[2]
            local y = eventData[3]
            
            local found = false
            
            for _, cmp in pairs(self.Components) do
                if x >= cmp.PosX
                     and y >= cmp.PosY
                     and x <= cmp.EndX
                     and y <= cmp.EndY then
                     
                     found = true
					 
                     self:FocusComponent(cmp._CID)
                     cmp:OnEvent(event, eventData)
					 
					 break
                end
            end
            
            if not found then
                if self.CurrentFocusedComponent then
                    local cmp = self:GetComponent(self.CurrentFocusedComponent)
                    if cmp then
                        cmp:OnEvent("lose_focus", {})
                    end
                end
            end
		elseif event == "mouse_scroll" then
            local x = eventData[2]
            local y = eventData[3]
			for _, cmp in pairs(self.Components) do
                if x >= cmp.PosX
                     and y >= cmp.PosY
                     and x <= cmp.EndX
                     and y <= cmp.EndY then
					 
                     cmp:OnEvent(event, eventData)
                end
            end
        else
            local _c = true -- c[ontinue]
        
            if event == "key" then
                local k = eventData[1]
                if k == 340 or k == 344 then
                    ShiftHeld = true
                    _c = false
                elseif k == 341 or k == 345 then
                    CtrlHeld = true
                    _c = false
                end
            elseif event == "key_up" then
                local k = eventData[1]
                if k == 340 or k == 344 then
                    ShiftHeld = false
                    _c = false
                elseif k == 341 or k == 345 then
                    CtrlHeld = false
                    _c = false
                end
            end
            
            if _c and self.CurrentFocusedComponent then
                local cmp = self:GetComponent(self.CurrentFocusedComponent)
                if cmp then
                    cmp:OnEvent(event, eventData)
                end
            end
        end
    end
end

-- Stop event loop
function CommonUI:EndEventLoop()
	self.Run = false
end

-- Add and draw a component
function CommonUI:AddAndDrawComponent(component)
    local id = self:AddComponent(component)
    self:DrawComponent(id)
    return id
end

-- Is any the shift keys held down?
function CommonUI.GetShiftHeld()
    return ShiftHeld
end

-- Is any of the CTRL keys held down?
function CommonUI.GetCtrlHeld()
    return CtrlHeld
end

-- Clear component registry
-- This can be useful when showing a different
-- screen, so you can get rid of all buttons
-- and text fields
function CommonUI:ClearComponents()
    self.Components = {}
end

function CommonUI:RemoveComponent(id)
	for i, cmp in pairs(self.Components) do
		if cmp._CID == id then
			table.remove(self.Components, i)
		end
	end
end

-- Focuses the given component
function CommonUI:FocusComponent(id)
    if self.CurrentFocusedComponent then
        cmp = self:GetComponent(self.CurrentFocusedComponent)
        if cmp then
            cmp:OnEvent("lose_focus", {})
        end
    end
    
    local cmp = self:GetComponent(id)
    if cmp then
        self.CurrentFocusedComponent = cmp._CID
        cmp:OnEvent("gain_focus", {})
    else
        error("unknown component " .. id)
    end
end

return CommonUI
