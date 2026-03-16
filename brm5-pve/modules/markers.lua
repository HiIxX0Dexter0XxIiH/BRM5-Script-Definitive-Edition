
local Markers = {}

Markers.trackedParts = {} -- List of body parts we are watching
Markers.enabled = false
Markers.raycastParams = RaycastParams.new()
Markers.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
Markers.activeTransparency = 0.3
Markers.inactiveTransparency = 1

local function ensureBox(part, name, color)
    local box = part:FindFirstChild(name)
    if box then
        box.Color3 = color
        return box
    end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = name
    box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = color
    box.Transparency = Markers.inactiveTransparency
    box.Parent = part

    return box
end

function Markers.createBoxForPart(part, config)
    if not part then
        return
    end

    local visibleBox = ensureBox(part, "Visible_Marker_Box", (config and config.visibleColor) or Color3.fromRGB(0, 255, 0))
    local hiddenBox = ensureBox(part, "Hidden_Marker_Box", (config and config.hiddenColor) or Color3.fromRGB(255, 0, 0))
    visibleBox.Transparency = Markers.activeTransparency
    hiddenBox.Transparency = Markers.inactiveTransparency
    Markers.trackedParts[part] = true
end

-- Removes all marker boxes
function Markers.destroyAllBoxes()
    for part, _ in pairs(Markers.trackedParts) do
        if part then
            local visibleBox = part:FindFirstChild("Visible_Marker_Box")
            local hiddenBox = part:FindFirstChild("Hidden_Marker_Box")
            if visibleBox then
                pcall(function() visibleBox:Destroy() end)
            end
            if hiddenBox then
                pcall(function() hiddenBox:Destroy() end)
            end
        end
    end
    Markers.trackedParts = {}
end

-- Updates marker colors based on line of sight
function Markers.updateColors(npcManager, camera, workspace, localPlayer, config)
    if not Markers.enabled then 
        return 
    end
    if not camera or not localPlayer then
        return
    end
    local character = localPlayer.Character
    if not character then
        return
    end

    local processed = 0
    local maxPerStep = config.MARKER_MAX_PER_STEP or 12
    local origin = camera.CFrame.Position
    local rp = Markers.raycastParams

    for model, data in pairs(npcManager:getActiveNPCs()) do
        if processed >= maxPerStep then
            break
        end
        if data.head then
            local visibleBox = ensureBox(data.head, "Visible_Marker_Box", config.visibleColor)
            local hiddenBox = ensureBox(data.head, "Hidden_Marker_Box", config.hiddenColor)
            rp.FilterDescendantsInstances = {character, data.head}
            
            -- Raycast to check if there is an obstacle between you and the NPC
            local r = workspace:Raycast(origin, data.head.Position - origin, rp)
            local isVisible = not r or r.Instance:IsDescendantOf(model)
            visibleBox.Color3 = config.visibleColor
            hiddenBox.Color3 = config.hiddenColor
            visibleBox.Transparency = isVisible and Markers.activeTransparency or Markers.inactiveTransparency
            hiddenBox.Transparency = isVisible and Markers.inactiveTransparency or Markers.activeTransparency
            processed = processed + 1
        end
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
