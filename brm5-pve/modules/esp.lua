-- ESP Module (Wallhack)
-- Creates visual boxes around enemies that can be seen through walls

local ESP = {}

ESP.trackedParts = {} -- List of body parts we are watching
ESP.enabled = false

-- Creates the visual box for Wallhack (ESP)
function ESP.createBoxForPart(part, config)
    if not part or part:FindFirstChild("Wall_Box") then 
        return 
    end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Wall_Box"
    box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    box.Adornee = part
    box.AlwaysOnTop = true -- This allows seeing it through walls
    box.ZIndex = 10
    box.Color3 = config.visibleColor
    box.Transparency = 0.3
    box.Parent = part
    
    ESP.trackedParts[part] = true
end

-- Removes all ESP boxes
function ESP.destroyAllBoxes()
    for part, _ in pairs(ESP.trackedParts) do
        if part and part:FindFirstChild("Wall_Box") then 
            pcall(function() part.Wall_Box:Destroy() end) 
        end
    end
    ESP.trackedParts = {}
end

-- Updates ESP colors based on line of sight
function ESP.updateColors(npcManager, camera, workspace, localPlayer, config)
    if not ESP.enabled then 
        return 
    end
    
    for model, data in pairs(npcManager:getActiveNPCs()) do
        if data.head and data.head:FindFirstChild("Wall_Box") then
            local origin = camera.CFrame.Position
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Blacklist
            rp.FilterDescendantsInstances = {localPlayer.Character, data.head}
            
            -- Raycast to check if there is a wall between you and the NPC
            local r = workspace:Raycast(origin, data.head.Position - origin, rp)
            data.head.Wall_Box.Color3 = (not r or r.Instance:IsDescendantOf(model)) 
                and config.visibleColor 
                or config.hiddenColor
        end
    end
end

-- Enables ESP
function ESP.enable(npcManager, config)
    ESP.enabled = true
    for _, data in pairs(npcManager:getActiveNPCs()) do 
        ESP.createBoxForPart(data.head, config) 
    end
end

-- Disables ESP
function ESP.disable()
    ESP.enabled = false
    ESP.destroyAllBoxes()
end

-- Check if ESP is enabled
function ESP.isEnabled()
    return ESP.enabled
end

return ESP
