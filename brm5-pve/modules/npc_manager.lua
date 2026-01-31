-- NPC Manager Module
-- Handles detection and tracking of enemy NPCs

local NPCManager = {}

NPCManager.activeNPCs = {}      -- List of enemies currently in the game
NPCManager.wallConnections = {} -- List of connections to clean up later

-- Finds the main part of a character (Root)
function NPCManager.getRootPart(model)
    return model:FindFirstChild("Root") or 
           model:FindFirstChild("HumanoidRootPart") or 
           model:FindFirstChild("UpperTorso")
end

-- Checks if the model is an AI/NPC enemy
function NPCManager.hasAIChild(model)
    for _, c in ipairs(model:GetChildren()) do
        if type(c.Name) == "string" and c.Name:sub(1, 3) == "AI_" then 
            return true 
        end
    end
    return false
end

-- Adds an enemy to our tracking list
function NPCManager:addNPC(model, espModule)
    if self.activeNPCs[model] or model.Name ~= "Male" or not self.hasAIChild(model) then 
        return 
    end
    
    local head = model:FindFirstChild("Head")
    local root = self.getRootPart(model)
    
    if not head or not root then 
        return 
    end
    
    self.activeNPCs[model] = { head = head, root = root }
    
    -- Create ESP box if wall ESP is enabled
    if espModule and espModule.isEnabled() then
        espModule.createBoxForPart(head)
    end
end

-- Removes an NPC from tracking
function NPCManager:removeNPC(model)
    self.activeNPCs[model] = nil
end

-- Gets all active NPCs
function NPCManager:getActiveNPCs()
    return self.activeNPCs
end

-- Scans workspace for existing NPCs
function NPCManager:scanWorkspace(workspace, espModule)
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m.Name == "Male" then 
            if self.hasAIChild(m) then 
                self:addNPC(m, espModule) 
            end
        end
    end
end

-- Sets up listener for new NPCs
function NPCManager:setupListener(workspace, espModule)
    local connection = workspace.ChildAdded:Connect(function(m)
        if m:IsA("Model") and m.Name == "Male" then 
            task.delay(0.2, function() 
                if self.hasAIChild(m) then 
                    self:addNPC(m, espModule) 
                end 
            end) 
        end
    end)
    
    table.insert(self.wallConnections, connection)
end

-- Cleanup all connections
function NPCManager:cleanup()
    for _, c in ipairs(self.wallConnections) do 
        pcall(function() c:Disconnect() end) 
    end
    self.wallConnections = {}
    self.activeNPCs = {}
end

return NPCManager
