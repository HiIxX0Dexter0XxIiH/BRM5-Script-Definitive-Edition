-- Main Script (BRM5 PVE v6.5)
-- Coordinates all modules

print("Starting BRM5 PVE Script...")
if typeof(clear) == "function" then clear() end

-- GitHub Raw URL Base
local GITHUB_BASE = "https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/BRM5-Script-Definitive-Edition/main/brm5-pve/modules/"

-- Function to load module from GitHub
local function loadModule(moduleName)
    print("Loading module: " .. moduleName)
    local url = GITHUB_BASE .. moduleName .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleName)
        warn("Error: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Load all modules from GitHub
local Services = loadModule("services")
local Config = loadModule("config")
local NPCManager = loadModule("npc_manager")
local TargetSizing = loadModule("target_sizing")
local Markers = loadModule("markers")
local Lighting = loadModule("lighting")
local Weapons = loadModule("weapons")
local GUI = loadModule("gui")

-- Verify all modules loaded successfully
if not (Services and Config and NPCManager and TargetSizing and Markers and Lighting and Weapons and GUI) then
    error("Failed to load one or more modules. Please check your internet connection and GitHub URLs.")
    return
end

print("All modules loaded successfully!")

-- Initialize Lighting
Lighting:storeOriginalSettings(Services.Lighting)

-- GUI Callbacks
local callbacks = {
    -- Combat callbacks
    onSizingToggle = function(enabled)
        Config.sizingEnabled = enabled
    end,
    
    onShowTargetBoxToggle = function(enabled)
        Config.showTargetBox = enabled
    end,
    
    -- Visual callbacks
    onHighlightsToggle = function(enabled)
        Config.highlightEnabled = enabled
        if enabled then 
            Markers.enable(NPCManager, Config)
        else 
            Markers.disable()
        end
    end,
    
    onFullBrightToggle = function(enabled)
        Config.fullBrightEnabled = enabled
        if not enabled then 
            Lighting:restoreOriginal(Services.Lighting)
        end
    end,
    
    -- Weapon callbacks
    onStabilityToggle = function(enabled)
        Config.patchOptions.recoil = enabled
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
    end,
    
    onFiremodeOptionsToggle = function(enabled)
        Config.patchOptions.firemodes = enabled
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
    end,
    
    -- Color callbacks
    onVisibleRChange = function(value)
        Config:updateVisibleColor(value, nil, nil)
    end,
    
    onVisibleGChange = function(value)
        Config:updateVisibleColor(nil, value, nil)
    end,
    
    onVisibleBChange = function(value)
        Config:updateVisibleColor(nil, nil, value)
    end,
    
    onHiddenRChange = function(value)
        Config:updateHiddenColor(value, nil, nil)
    end,
    
    onHiddenGChange = function(value)
        Config:updateHiddenColor(nil, value, nil)
    end,
    
    onHiddenBChange = function(value)
        Config:updateHiddenColor(nil, nil, value)
    end,
    
    -- Unload callback
    onUnload = function()
        print("Unloading BRM5 PVE Script...")
        Config.isUnloaded = true
        Markers.destroyAllBoxes()
        TargetSizing:cleanup(NPCManager)
        NPCManager:cleanup()
        Lighting:restoreOriginal(Services.Lighting)
        GUI:destroy()
        print("Script unloaded successfully!")
    end
}

-- Initialize GUI
GUI:init(Services, Config, callbacks)

-- Scan for existing NPCs
NPCManager:scanWorkspace(Services.Workspace, Markers)

-- Setup listener for new NPCs
NPCManager:setupListener(Services.Workspace, Markers)

-- Main game loop
local markerAccumulator = 0
local targetAccumulator = 0

Services.RunService.Heartbeat:Connect(function(dt)
    if Config.isUnloaded then 
        return 
    end

    -- Update lighting
    Lighting:update(Services.Lighting, Config)

    -- Update marker colors (throttled)
    markerAccumulator = markerAccumulator + dt
    if markerAccumulator >= Config.RAYCAST_COOLDOWN then
        Markers.updateColors(NPCManager, Services.camera, Services.Workspace, 
                         Services.localPlayer, Config)
        markerAccumulator = 0
    end
    
    -- Update target bounds (throttled)
    targetAccumulator = targetAccumulator + dt
    if targetAccumulator >= Config.TARGET_SYNC_INTERVAL then
        TargetSizing:updateAllTargets(NPCManager, Config)
        targetAccumulator = 0
    end
end)

-- Toggle menu with INSERT key
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        Config.guiVisible = GUI:toggleVisibility()
    end
end)

print("BRM5 PVE Script loaded successfully!")
print("Press INSERT to toggle menu")
