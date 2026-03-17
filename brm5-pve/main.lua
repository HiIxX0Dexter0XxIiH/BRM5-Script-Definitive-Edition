-- Main Script (BRM5 PVE)
-- Coordinates all modules

print("Starting BRM5 PVE Script...")
if typeof(clear) == "function" then
    clear()
end

local GITHUB_BASE = "https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/BRM5-Script-Definitive-Edition/main/brm5-pve/modules/"
local CACHE_BUSTER = tostring(os.time())

local function loadModule(moduleName)
    local url = GITHUB_BASE .. moduleName .. ".lua?v=" .. CACHE_BUSTER
    print("Loading module: " .. moduleName)

    local okResponse, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not okResponse then
        warn("Failed to download module: " .. moduleName)
        warn("URL: " .. url)
        warn("HttpGet error: " .. tostring(response))
        return nil
    end

    if type(response) ~= "string" or response == "" then
        warn("Module download returned empty content: " .. moduleName)
        warn("URL: " .. url)
        return nil
    end

    local chunk, compileError = loadstring(response)
    if not chunk then
        warn("Failed to compile module: " .. moduleName)
        warn("URL: " .. url)
        warn("Compile error: " .. tostring(compileError))
        return nil
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        warn("Failed to execute module: " .. moduleName)
        warn("URL: " .. url)
        warn("Runtime error: " .. tostring(result))
        return nil
    end

    return result
end

local Services = loadModule("services")
local Config = loadModule("config")
local NPCManager = loadModule("npc_manager")
local TargetSizing = loadModule("target_sizing")
local Markers = loadModule("markers")
local Lighting = loadModule("lighting")
local Weapons = loadModule("weapons")
local GUI = loadModule("gui")

if not (Services and Config and NPCManager and TargetSizing and Markers and Lighting and Weapons and GUI) then
    error("Failed to load one or more modules. Please verify the remote module files.")
end

Lighting:storeOriginalSettings(Services.Lighting)

local runtimeConnections = {}

local function disconnectRuntimeConnections()
    for _, connection in ipairs(runtimeConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    runtimeConnections = {}
end

local callbacks = {
    onSizingToggle = function(enabled)
        Config.sizingEnabled = enabled
        if not enabled then
            TargetSizing:cleanup(NPCManager)
        end
    end,

    onShowTargetBoxToggle = function(enabled)
        Config.showTargetBox = enabled
    end,

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

    onStabilityToggle = function(enabled)
        Config.patchOptions.recoil = enabled
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
    end,

    onFiremodeOptionsToggle = function(enabled)
        Config.patchOptions.firemodes = enabled
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
    end,

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

    onUnload = function()
        if Config.isUnloaded then
            return
        end

        print("Unloading BRM5 PVE Script...")
        Config.isUnloaded = true
        disconnectRuntimeConnections()
        Markers.disable()
        TargetSizing:cleanup(NPCManager)
        NPCManager:cleanup()
        Lighting:restoreOriginal(Services.Lighting)
        GUI:destroy()
        print("Script unloaded successfully!")
    end
}

GUI:init(Services, Config, callbacks)

NPCManager:scanWorkspace(Services.Workspace, Markers, Config)
NPCManager:setupListener(Services.Workspace, Markers, Config)

local markerAccumulator = 0
local targetAccumulator = 0

table.insert(runtimeConnections, Services.RunService.Heartbeat:Connect(function(dt)
    if Config.isUnloaded then
        return
    end

    Lighting:update(Services.Lighting, Config)

    markerAccumulator = markerAccumulator + dt
    if markerAccumulator >= Config.RAYCAST_COOLDOWN then
        Markers.updateColors(NPCManager, Services.Workspace.CurrentCamera or Services.camera, Services.Workspace, Services.localPlayer, Config)
        markerAccumulator = 0
    end

    targetAccumulator = targetAccumulator + dt
    if targetAccumulator >= Config.TARGET_SYNC_INTERVAL then
        TargetSizing:updateAllTargets(NPCManager, Config)
        targetAccumulator = 0
    end
end))

table.insert(runtimeConnections, Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if Config.isUnloaded then
        return
    end

    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        Config.guiVisible = GUI:toggleVisibility()
    end
end))

print("BRM5 PVE Script loaded successfully!")
print("Press INSERT to toggle menu")
