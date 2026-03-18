if typeof(clear) == "function" then
    clear()
end

local MODULE_BASES = {
    "Roblox-Dexter-Scripts-main/brm5-pvp/modules/",
    "brm5-pvp/modules/",
    "modules/",
    "./brm5-pvp/modules/",
    "./modules/"
}

local function readFirstAvailableModule(moduleName)
    local attemptedPaths = {}

    for _, basePath in ipairs(MODULE_BASES) do
        local path = basePath .. moduleName .. ".lua"
        table.insert(attemptedPaths, path)

        local okRead, result = pcall(readfile, path)
        if okRead and type(result) == "string" and result ~= "" then
            return result, path, attemptedPaths
        end
    end

    return nil, nil, attemptedPaths
end

local function loadLocalModule(moduleName)
    if type(readfile) ~= "function" then
        error("This local loader requires readfile support.")
    end

    local source, loadedPath, attemptedPaths = readFirstAvailableModule(moduleName)
    if type(source) ~= "string" or source == "" then
        error("Failed to read local module '" .. moduleName .. "'. Tried: " .. table.concat(attemptedPaths, ", "))
    end

    local chunk, compileError = loadstring(source)
    if not chunk then
        error("Failed to compile local module " .. moduleName .. " from " .. tostring(loadedPath) .. ": " .. tostring(compileError))
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        error("Failed to execute local module " .. moduleName .. " from " .. tostring(loadedPath) .. ": " .. tostring(result))
    end

    return result
end

local Services = loadLocalModule("services")
local Config = loadLocalModule("config")
local Aim = loadLocalModule("aim")
local Walls = loadLocalModule("walls")
local Lighting = loadLocalModule("fullbright")
local NoRecoil = loadLocalModule("norecoil")
local AllyScan = loadLocalModule("ally_scan")
local GUI = loadLocalModule("gui")

Config:load()
Lighting:storeOriginalSettings(Services.Lighting)

local runtimeConnections = {}

local function saveConfig()
    Config:save()
end

local function syncMouseState()
    if Config.guiVisible then
        Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Services.UserInputService.MouseIconEnabled = true
    end
end

local function forceMouseLock()
    Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Services.UserInputService.MouseIconEnabled = false
end

local function disconnectRuntimeConnections()
    for _, connection in ipairs(runtimeConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    runtimeConnections = {}
end

local callbacks = {
    onAimToggle = function(enabled)
        Config.aimEnabled = enabled
        Walls:refreshTrackedTargets(Services.Workspace, Config)
        saveConfig()
    end,

    onFOVToggle = function(enabled)
        Config.fovEnabled = enabled
        saveConfig()
    end,

    onWallToggle = function(enabled)
        Walls:setWallEnabled(enabled, Config)
        Walls:refreshTrackedTargets(Services.Workspace, Config)
        saveConfig()
    end,

    onFullBrightToggle = function(enabled)
        Config.fullBrightEnabled = enabled
        if not enabled then
            Lighting:restoreOriginal(Services.Lighting)
        end
        saveConfig()
    end,

    onNoRecoilToggle = function(enabled)
        Config.patchOptions.recoil = enabled
        NoRecoil.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
        saveConfig()
    end,

    onFiremodeToggle = function(enabled)
        Config.patchOptions.firemodes = enabled
        NoRecoil.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
        saveConfig()
    end,

    onFOVRadiusChange = function(value)
        Config:updateFOVRadius(value)
        saveConfig()
    end,

    onSmoothingChange = function(value)
        Config:updateSmoothing(value)
        saveConfig()
    end,

    onVisibleRChange = function(value)
        Config:updateVisibleColor(value, nil, nil)
        saveConfig()
    end,

    onVisibleGChange = function(value)
        Config:updateVisibleColor(nil, value, nil)
        saveConfig()
    end,

    onVisibleBChange = function(value)
        Config:updateVisibleColor(nil, nil, value)
        saveConfig()
    end,

    onHiddenRChange = function(value)
        Config:updateHiddenColor(value, nil, nil)
        saveConfig()
    end,

    onHiddenGChange = function(value)
        Config:updateHiddenColor(nil, value, nil)
        saveConfig()
    end,

    onHiddenBChange = function(value)
        Config:updateHiddenColor(nil, nil, value)
        saveConfig()
    end,

    onScanAllies = function()
        AllyScan:start(Config.ALLY_SCAN_DURATION, Services, Walls, Config)
    end,

    onUnload = function()
        if Config.isUnloaded then
            return
        end

        Config.isUnloaded = true
        disconnectRuntimeConnections()
        AllyScan:stop()
        AllyScan:stopRoundMonitor()
        Walls:cleanup()
        Aim:cleanup()
        Lighting:restoreOriginal(Services.Lighting)
        Config.guiVisible = false
        saveConfig()
        forceMouseLock()
        GUI:destroy()
    end
}

GUI:init(Services, Config, callbacks)
syncMouseState()
AllyScan:startRoundMonitor(Services, Walls, Config)

Walls:refreshTrackedTargets(Services.Workspace, Config)
Walls:setupListener(Services.Workspace, Config)
Walls:setWallEnabled(Config.wallEnabled, Config)
if Config.patchOptions.recoil or Config.patchOptions.firemodes then
    NoRecoil.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
end

local targetAccumulator = 0
local colorAccumulator = 0

table.insert(runtimeConnections, Services.RunService.Heartbeat:Connect(function(dt)
    if Config.isUnloaded then
        return
    end

    if Config.guiVisible then
        syncMouseState()
    end

    Lighting:update(Services.Lighting, Config)

    targetAccumulator = targetAccumulator + dt
    if targetAccumulator >= Config.TARGET_REFRESH_INTERVAL then
        Walls:refreshTrackedTargets(Services.Workspace, Config)
        targetAccumulator = 0
    end

    colorAccumulator = colorAccumulator + dt
    if colorAccumulator >= Config.COLOR_UPDATE_INTERVAL then
        Walls:updateColors(Services.Workspace.CurrentCamera or Services.camera, Services.Workspace, Services.localPlayer, Config)
        colorAccumulator = 0
    end

    Aim:updateFOVCircle(Services.Workspace.CurrentCamera or Services.camera, Config)
    if Config.aimEnabled and Aim.holdingRightClick then
        local target = Aim:getClosestValidHead(Walls, Services.Workspace.CurrentCamera or Services.camera, Config)
        if target then
            Aim:aimAtTarget(target, Services.Workspace.CurrentCamera or Services.camera, Config)
        end
    end
end))

table.insert(runtimeConnections, Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if Config.isUnloaded then
        return
    end

    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        local wasVisible = Config.guiVisible
        Config.guiVisible = GUI:toggleVisibility()
        if Config.guiVisible then
            syncMouseState()
        elseif wasVisible then
            forceMouseLock()
        end
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aim:setHoldingRightClick(true)
        return
    end

    if not gameProcessed and input.KeyCode == Enum.KeyCode.U then
        AllyScan:start(Config.ALLY_SCAN_DURATION, Services, Walls, Config)
    end
end))

table.insert(runtimeConnections, Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aim:setHoldingRightClick(false)
    end
end))
