-- GUI Module
-- Creates and manages the user interface

local GUI = {}

GUI.screenGui = nil
GUI.mainFrame = nil
GUI.tabButtons = {}
GUI.tabs = {}

-- Creates a new tab page
local function createTab(container)
    local f = Instance.new("ScrollingFrame", container)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.ScrollBarThickness = 2
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 12)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.SortOrder = Enum.SortOrder.LayoutOrder

    return f
end

-- Creates a toggle button
local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = "Gotham"
    btn.TextSize = 13
    Instance.new("UICorner", btn)
    
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(85, 170, 255) or Color3.fromRGB(35, 35, 35)
        btn.TextColor3 = active and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        callback(active)
    end)
end

-- Creates a label
local function createLabel(parent, text, color, layoutIndex)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -10, 0, 30)
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = "GothamBold"
    lbl.BackgroundTransparency = 1
    if layoutIndex then
        lbl.LayoutOrder = layoutIndex
    end
    return lbl
end

-- Creates a slider
local function createSlider(parent, label, initialValue, callback, layoutIndex, services)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 50)
    f.BackgroundTransparency = 1
    if layoutIndex then
        f.LayoutOrder = layoutIndex
    end

    local l = Instance.new("TextLabel", f)
    l.Text = label .. ": " .. initialValue
    l.Size = UDim2.new(1, 0, 0, 20)
    l.TextColor3 = Color3.new(1, 1, 1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = "Left"

    local bar = Instance.new("Frame", f)
    bar.Position = UDim2.new(0, 0, 0, 25)
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(initialValue / 255, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(85, 170, 255)

    local dragging = false
    local function update()
        local mousePos = services.UserInputService:GetMouseLocation().X
        local p = math.clamp((mousePos - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(p * 255)
        fill.Size = UDim2.new(p, 0, 1, 0)
        l.Text = label .. ": " .. val
        callback(val)
    end

    bar.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true 
            update() 
        end 
    end)
    
    services.UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false 
        end 
    end)
    
    services.RunService.RenderStepped:Connect(function() 
        if dragging then 
            update() 
        end 
    end)
end

-- Initialize the GUI
function GUI:init(services, config, callbacks)
    local localPlayer = services.localPlayer
    
    -- Create ScreenGui
    self.screenGui = Instance.new("ScreenGui", localPlayer.PlayerGui)
    self.screenGui.Name = "BRM5_V6_Final"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.DisplayOrder = 9999

    -- Main Window Frame
    local main = Instance.new("Frame", self.screenGui)
    main.Size = UDim2.new(0, 500, 0, 350)
    main.Position = UDim2.new(0.5, -250, 0.5, -175)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main.BorderSizePixel = 0
    main.Active = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    self.mainFrame = main

    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local topBar = Instance.new("Frame", main)
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    topBar.BorderSizePixel = 0
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end
            end)
        end
    end)

    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then 
            dragInput = input 
        end
    end)

    services.RunService.RenderStepped:Connect(function()
        if dragging and dragInput then 
            updateDrag(dragInput) 
        end
    end)

    -- Title
    local title = Instance.new("TextLabel", topBar)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Text = "BRM5 v6.5 🎇"
    title.Font = "GothamBold"
    title.TextColor3 = Color3.fromRGB(85, 170, 255)
    title.TextSize = 16
    title.TextXAlignment = "Left"
    title.BackgroundTransparency = 1

    -- Sidebar
    local sidebar = Instance.new("Frame", main)
    sidebar.Position = UDim2.new(0, 0, 0, 40)
    sidebar.Size = UDim2.new(0, 130, 1, -40)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    sidebar.BorderSizePixel = 0

    local sideLayout = Instance.new("UIListLayout", sidebar)
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideLayout.Padding = UDim.new(0, 8)

    -- Content Container
    local container = Instance.new("Frame", main)
    container.Position = UDim2.new(0, 140, 0, 50)
    container.Size = UDim2.new(1, -150, 1, -60)
    container.BackgroundTransparency = 1

    -- Create Tabs
    local tabCombat = createTab(container)
    local tabVisuals = createTab(container)
    local tabWeapons = createTab(container)
    local tabColors = createTab(container)
    local tabCredits = createTab(container)
    tabCombat.Visible = true

    self.tabs = {
        combat = tabCombat,
        visuals = tabVisuals,
        weapons = tabWeapons,
        colors = tabColors,
        credits = tabCredits
    }

    -- Add Tab Buttons
    local function addTabBtn(name, targetTab)
        local b = Instance.new("TextButton", sidebar)
        b.Size = UDim2.new(1, -20, 0, 35)
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        b.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        b.Font = "GothamMedium"
        b.TextSize = 13
        Instance.new("UICorner", b)

        self.tabButtons[name] = b
        if name == "Combat" then
            b.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
            b.TextColor3 = Color3.new(0, 0, 0)
        end

        b.Text = name
        b.MouseButton1Click:Connect(function()
            for _, btn in pairs(self.tabButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            end
            b.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
            b.TextColor3 = Color3.new(0, 0, 0)

            for _, tab in pairs(self.tabs) do
                tab.Visible = false
            end
            targetTab.Visible = true
        end)
    end

    addTabBtn("Combat", tabCombat)
    addTabBtn("Visuals", tabVisuals)
    addTabBtn("Weapons", tabWeapons)
    addTabBtn("Colors", tabColors)
    addTabBtn("Credits", tabCredits)

    -- COMBAT TAB
    createButton(tabCombat, "Silent Hitbox", callbacks.onSilentToggle)
    createButton(tabCombat, "Show Hitbox", callbacks.onShowHitboxToggle)

    -- VISUALS TAB
    createButton(tabVisuals, "Wall ESP", callbacks.onWallESPToggle)
    createButton(tabVisuals, "FullBright", callbacks.onFullBrightToggle)

    -- WEAPONS TAB
    local weaponNote = createLabel(tabWeapons, "Reset character to apply changes", 
                                   Color3.fromRGB(255, 100, 100))
    createButton(tabWeapons, "Anti-Recoil", callbacks.onAntiRecoilToggle)
    createButton(tabWeapons, "Unlock Firemodes", callbacks.onFiremodesToggle)

    -- COLORS TAB
    local layoutIndex = 1
    createLabel(tabColors, "-- VISIBLE COLOR --", Color3.new(0.5, 1, 0.5), layoutIndex)
    layoutIndex = layoutIndex + 1
    
    createSlider(tabColors, "R", config.visibleR, callbacks.onVisibleRChange, layoutIndex, services)
    layoutIndex = layoutIndex + 1
    createSlider(tabColors, "G", config.visibleG, callbacks.onVisibleGChange, layoutIndex, services)
    layoutIndex = layoutIndex + 1
    createSlider(tabColors, "B", config.visibleB, callbacks.onVisibleBChange, layoutIndex, services)
    layoutIndex = layoutIndex + 1

    createLabel(tabColors, "-- HIDDEN COLOR --", Color3.new(1, 0.5, 0.5), layoutIndex)
    layoutIndex = layoutIndex + 1
    
    createSlider(tabColors, "R", config.hiddenR, callbacks.onHiddenRChange, layoutIndex, services)
    layoutIndex = layoutIndex + 1
    createSlider(tabColors, "G", config.hiddenG, callbacks.onHiddenGChange, layoutIndex, services)
    layoutIndex = layoutIndex + 1
    createSlider(tabColors, "B", config.hiddenB, callbacks.onHiddenBChange, layoutIndex, services)

    -- CREDITS TAB
    local function addCredit(text, font)
        local c = Instance.new("TextLabel", tabCredits)
        c.Size = UDim2.new(1, -10, 0, 50)
        c.Text = text
        c.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        c.Font = font or "Gotham"
        c.TextSize = 12
        c.TextWrapped = true
        c.BackgroundTransparency = 1
    end

    addCredit("Made by: HiIxX0Dexter0XxIiH", "GothamBold")
    addCredit("https://github.com/HiIxX0Dexter0XxIiH/Roblox-Dexter-Scripts", "Gotham")

    -- UNLOAD BUTTON
    local unl = Instance.new("TextButton", sidebar)
    unl.Size = UDim2.new(0, 110, 0, 35)
    unl.AnchorPoint = Vector2.new(0.5, 0)
    unl.Position = UDim2.new(0.5, 0, 0, 0)
    unl.Text = "Unload Script"
    unl.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    unl.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", unl)
    unl.MouseButton1Click:Connect(callbacks.onUnload)
end

-- Toggle GUI visibility
function GUI:toggleVisibility()
    if self.mainFrame then
        self.mainFrame.Visible = not self.mainFrame.Visible
        return self.mainFrame.Visible
    end
    return false
end

-- Destroy GUI
function GUI:destroy()
    if self.screenGui then
        self.screenGui:Destroy()
    end
end

return GUI
