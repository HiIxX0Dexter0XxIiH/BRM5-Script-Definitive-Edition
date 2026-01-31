-- NPC Manager Module
-- Handles detection and tracking of enemy NPCs

local NPCManager = {}

NPCManager.activeNPCs = {}      -- List of enemies currently in the game
NPCManager.wallConnections = {} -- List of connections to clean up later
NPCManager.modelConnections = {} -- Per-model connections for delayed AI detection

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
function NPCManager:addNPC(model, markerModule)
    if self.activeNPCs[model] or not self.hasAIChild(model) then 
        return 
    end
    
    local head = model:FindFirstChild("Head")
    local root = self.getRootPart(model)
    
    if not head or not root then 
        return 
    end
    
    self.activeNPCs[model] = { head = head, root = root }
    
    -- Create marker box if visibility markers are enabled
    if markerModule and markerModule.isEnabled() then
        markerModule.createBoxForPart(head)
    end
end

-- Tracks a model and waits for AI_ child if it appears later
function NPCManager:trackPotentialNPC(model, markerModule)
    if self.activeNPCs[model] then
        return
    end
    if self.hasAIChild(model) then
        self:addNPC(model, markerModule)
        return
    end
    if self.modelConnections[model] then
        return
    end

    local connection
    connection = model.ChildAdded:Connect(function(child)
        if type(child.Name) == "string" and child.Name:sub(1, 3) == "AI_" then
            self:addNPC(model, markerModule)
            if connection then
                connection:Disconnect()
            end
            self.modelConnections[model] = nil
        end
    end)
    self.modelConnections[model] = connection
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
function NPCManager:scanWorkspace(workspace, markerModule)
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") then 
            self:trackPotentialNPC(m, markerModule)
        end
    end
end

-- Sets up listener for new NPCs
function NPCManager:setupListener(workspace, markerModule)
    local connection = workspace.ChildAdded:Connect(function(m)
        if m:IsA("Model") then 
            task.delay(0.2, function() 
                self:trackPotentialNPC(m, markerModule)
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
    for _, c in pairs(self.modelConnections) do
        pcall(function() c:Disconnect() end)
    end
    self.modelConnections = {}
    self.activeNPCs = {}
end

return NPCManager
