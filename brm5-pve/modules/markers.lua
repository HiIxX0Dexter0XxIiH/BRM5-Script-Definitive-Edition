
local Markers = {}

Markers.trackedParts = {} -- List of body parts we are watching
Markers.enabled = false
Markers.raycastParams = RaycastParams.new()
Markers.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

function Markers.createBoxForPart(part, config)
    if not part or part:FindFirstChild("Marker_Box") then 
        return 
    end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Marker_Box"
    box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 10
    local visibleColor = (config and config.visibleColor) or Color3.fromRGB(0, 255, 0)
    box.Color3 = visibleColor
    box.Transparency = 0.3
    box.Parent = part
    
    Markers.trackedParts[part] = true
end

-- Removes all marker boxes
function Markers.destroyAllBoxes()
    for part, _ in pairs(Markers.trackedParts) do
        if part and part:FindFirstChild("Marker_Box") then 
            pcall(function() part.Marker_Box:Destroy() end) 
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
        if data.head and data.head:FindFirstChild("Marker_Box") then
            rp.FilterDescendantsInstances = {character, data.head}
            
            -- Raycast to check if there is an obstacle between you and the NPC
            local r = workspace:Raycast(origin, data.head.Position - origin, rp)
            data.head.Marker_Box.Color3 = (not r or r.Instance:IsDescendantOf(model)) 
                and config.visibleColor 
                or config.hiddenColor
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
