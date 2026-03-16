-- NPC Manager Module
-- Handles detection and tracking of enemy NPCs

local NPCManager = {}

NPCManager.activeNPCs = {}      -- List of enemies currently in the game
NPCManager.wallConnections = {} -- List of connections to clean up later
NPCManager.modelConnections = {} -- Per-model connections for delayed NPC detection

local function debugLog(config, message)
    if config and config.debugNPCDetection then
        print("[NPCManager] " .. message)
    end
end

-- Finds the main part of a character (Root)
function NPCManager.getRootPart(model)
    return model:FindFirstChild("Root") or 
           model:FindFirstChild("HumanoidRootPart") or 
           model:FindFirstChild("UpperTorso")
end

-- Gets the inner NPC model from Workspace.Model.Male.
function NPCManager.getNPCModel(container)
    if not container or not container:IsA("Model") or container.Name ~= "Model" then
        return nil
    end

    local npc = container:FindFirstChild("NPCS")
    if npc and npc:IsA("Model") then
        return npc
    end

    local male = container:FindFirstChild("Male")
    if male and male:IsA("Model") and not male:FindFirstChildOfClass("BillboardGui") then
        male.Name = "NPCS"
        return male
    end

    return nil
end

-- Checks if the container matches the new NPC structure
function NPCManager.isNPCModel(container)
    return NPCManager.getNPCModel(container) ~= nil
end

-- Adds an enemy to our tracking list
function NPCManager:addNPC(container, markerModule, config)
    local npc = self.getNPCModel(container)
    if not npc or self.activeNPCs[npc] then 
        if not npc then
            debugLog(config, "addNPC skipped: no valid NPC model under " .. container:GetFullName())
        end
        return 
    end

    local head = npc:FindFirstChild("Head")
    local root = self.getRootPart(npc)
    
    if not head or not root then 
        debugLog(config, "addNPC skipped for " .. npc:GetFullName() .. " because head/root was missing")
        return 
    end
    
    self.activeNPCs[npc] = { head = head, root = root, character = npc, container = container }
    debugLog(config, "NPC registered: " .. npc:GetFullName())
    
    -- Create marker box if visibility markers are enabled
    if markerModule and markerModule.isEnabled() then
        markerModule.createBoxForPart(head, config)
    end
end

-- Tracks a model and waits for Male if it appears later
function NPCManager:trackPotentialNPC(container, markerModule, config)
    debugLog(config, "Inspecting container: " .. container:GetFullName())
    local npc = self.getNPCModel(container)
    if npc and self.activeNPCs[npc] then
        debugLog(config, "Already tracked: " .. npc:GetFullName())
        return
    end
    if self.isNPCModel(container) then
        local male = container:FindFirstChild("Male")
        local directBillboard = male and male:FindFirstChildOfClass("BillboardGui")
        debugLog(config, "Valid NPC container found. Male=" .. tostring(male) .. ", direct BillboardGui=" .. tostring(directBillboard))
        self:addNPC(container, markerModule, config)
        return
    end
    local male = container:FindFirstChild("Male")
    local maleClass = male and male.ClassName or "nil"
    local directBillboard = male and male:FindFirstChildOfClass("BillboardGui")
    debugLog(
        config,
        "Rejected container "
            .. container:GetFullName()
            .. "; Male="
            .. tostring(male)
            .. "; MaleClass="
            .. tostring(maleClass)
            .. "; DirectBillboard="
            .. tostring(directBillboard)
    )
    if not container:IsA("Model") or container.Name ~= "Model" then
        return
    end
    if self.modelConnections[container] then
        return
    end

    local connection
    connection = container.ChildAdded:Connect(function(child)
        if child:IsA("Model") and (child.Name == "Male" or child.Name == "NPCS") then
            self:addNPC(container, markerModule, config)
            if connection then
                connection:Disconnect()
            end
            self.modelConnections[container] = nil
        end
    end)
    self.modelConnections[container] = connection
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
function NPCManager:scanWorkspace(workspace, markerModule, config)
    debugLog(config, "Scanning workspace for NPC containers")
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m.Name == "Model" then 
            self:trackPotentialNPC(m, markerModule, config)
        end
    end
end

-- Sets up listener for new NPCs
function NPCManager:setupListener(workspace, markerModule, config)
    local connection = workspace.ChildAdded:Connect(function(m)
        if m:IsA("Model") and m.Name == "Model" then 
            debugLog(config, "New Model detected: " .. m:GetFullName())
            task.delay(0.2, function() 
                self:trackPotentialNPC(m, markerModule, config)
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
