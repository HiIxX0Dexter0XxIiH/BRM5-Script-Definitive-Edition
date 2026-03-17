
local Markers = {}

Markers.trackedParts = {} -- List of body parts we are watching
Markers.enabled = false
Markers.boxTransparency = 0.3
Markers.lastDebugAt = 0

local function debugLog(config, message)
    if config and config.debugMarkers then
        print("[Markers] " .. message)
    end
end

local function ensureBox(part, color)
    local box = part:FindFirstChild("Marker_Box")
    if box then
        box.Color3 = color
        return box
    end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Marker_Box"
    box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = color
    box.Transparency = Markers.boxTransparency
    box.Parent = part

    return box
end

function Markers.createBoxForPart(part, config)
    if not part then
        return
    end

    ensureBox(part, (config and config.visibleColor) or Color3.fromRGB(0, 255, 0))
    Markers.trackedParts[part] = true
end

-- Removes all marker boxes
function Markers.destroyAllBoxes()
    for part, _ in pairs(Markers.trackedParts) do
        if part then
            local box = part:FindFirstChild("Marker_Box")
            if box then
                pcall(function() box:Destroy() end)
            end
        end
    end
    Markers.trackedParts = {}
end

-- Updates marker colors based on line of sight
function Markers.updateColors(npcManager, camera, workspace, localPlayer, config)
    if not Markers.enabled then 
        if config and config.debugMarkers and (os.clock() - Markers.lastDebugAt) >= 1 then
            Markers.lastDebugAt = os.clock()
            debugLog(config, "updateColors skipped: markers disabled")
        end
        return 
    end
    camera = camera or (workspace and workspace.CurrentCamera)
    if not camera or not localPlayer then
        if config and config.debugMarkers and (os.clock() - Markers.lastDebugAt) >= 1 then
            Markers.lastDebugAt = os.clock()
            debugLog(config, "updateColors skipped: missing camera or localPlayer")
        end
        return
    end
    local character = localPlayer.Character
    if not character then
        if config and config.debugMarkers and (os.clock() - Markers.lastDebugAt) >= 1 then
            Markers.lastDebugAt = os.clock()
            debugLog(config, "updateColors skipped: local character missing")
        end
        return
    end

    local processed = 0
    local maxPerStep = config.MARKER_MAX_PER_STEP or 12
    local origin = camera.CFrame.Position

    for model, data in pairs(npcManager:getActiveNPCs()) do
        if processed >= maxPerStep then
            break
        end
        if data.head and data.head:FindFirstChild("Marker_Box") then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Blacklist
            rp.FilterDescendantsInstances = {character, data.head}

            local result = workspace:Raycast(origin, data.head.Position - origin, rp)
            local isVisible = (not result or result.Instance:IsDescendantOf(model))
            data.head.Marker_Box.Color3 = isVisible
                and config.visibleColor
                or config.hiddenColor
            data.head.Marker_Box.Transparency = Markers.boxTransparency

            if config and config.debugMarkers and (os.clock() - Markers.lastDebugAt) >= 1 then
                Markers.lastDebugAt = os.clock()
                local hitName = result and result.Instance and result.Instance:GetFullName() or "nil"
                debugLog(config, "Target=" .. model:GetFullName() .. "; Hit=" .. hitName .. "; Visible=" .. tostring(isVisible))
            end
            processed = processed + 1
        end
    end

    if processed == 0 and config and config.debugMarkers and (os.clock() - Markers.lastDebugAt) >= 1 then
        Markers.lastDebugAt = os.clock()
        debugLog(config, "updateColors ran but processed 0 NPCs")
    end
end

-- Enables visibility markers
function Markers.enable(npcManager, config)
    Markers.enabled = true
    for _, data in pairs(npcManager:getActiveNPCs()) do 
        Markers.createBoxForPart(data.head, config) 
    end
end

-- Disables visibility markers
function Markers.disable()
    Markers.enabled = false
    Markers.destroyAllBoxes()
end

-- Check if markers are enabled
function Markers.isEnabled()
    return Markers.enabled
end

return Markers
