# ComputerCraft CommonUI

---

This is a little OOP framework for UI in ComputerCraft.

Examples:
Header:

```lua
local header = DefaultControls:Header()
header.Text = "Welcome!"
header.TextColour = colors.black
header.DrawPriority = 1
CommonUI:AddComponent(header)
```

Button:
```lua
local button = DefaultControls:BigButton()
button.PosX = 2
button.PosY = 13
button.SizeX = 6
button.SizeY = 1
button.Text = "End!"
button.Colour = colors.blue
button.TextColour = colors.white
button.DrawPriority = 2
button.OnClick = function()
    CommonUI:EndEventLoop()
    CommonUI:ClearScreen()
end

CommonUI:AddComponent(button)
CommonUI:BeginEventLoop() -- starts listening for events e.g. mouse click
```