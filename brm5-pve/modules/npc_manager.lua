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

-- Gets all NPC candidate models from a Workspace.Model container.
function NPCManager.getNPCModels(container, config)
    if not container or not container:IsA("Model") or container.Name ~= "Model" then
        return {}
    end

    local npcs = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Model") then
            local directBillboard = child:FindFirstChildOfClass("BillboardGui")
            if child.Name == "Male" or child.Name == "NPCS" then
                debugLog(
                    config,
                    "Candidate under "
                        .. container:GetFullName()
                        .. ": Name="
                        .. child.Name
                        .. "; Class="
                        .. child.ClassName
                        .. "; DirectBillboard="
                        .. tostring(directBillboard)
                )
            end
            if child.Name == "NPCS" then
                table.insert(npcs, child)
            elseif child.Name == "Male" and not child:FindFirstChildOfClass("BillboardGui") then
                debugLog(config, "Renaming valid NPC: " .. child:GetFullName() .. " -> NPCS")
                child.Name = "NPCS"
                table.insert(npcs, child)
            end
        end
    end

    return npcs
end

-- Checks if the container matches the new NPC structure
function NPCManager.isNPCModel(container)
    return #NPCManager.getNPCModels(container) > 0
end

-- Adds a specific NPC model to our tracking list
function NPCManager:addNPCModel(npc, container, markerModule, config)
    if not npc or self.activeNPCs[npc] then
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

-- Adds all valid NPCs under a container
function NPCManager:addNPC(container, markerModule, config)
    local npcs = self.getNPCModels(container, config)
    if #npcs == 0 then
        debugLog(config, "addNPC skipped: no valid NPC model under " .. container:GetFullName())
        return
    end

    for _, npc in ipairs(npcs) do
        self:addNPCModel(npc, container, markerModule, config)
    end
end

-- Tracks a model and waits for Male if it appears later
function NPCManager:trackPotentialNPC(container, markerModule, config)
    debugLog(config, "Inspecting container: " .. container:GetFullName())
    local npcs = self.getNPCModels(container, config)
    local alreadyTracked = true
    for _, npc in ipairs(npcs) do
        if not self.activeNPCs[npc] then
            alreadyTracked = false
            break
        end
    end
    if #npcs > 0 and alreadyTracked then
        debugLog(config, "All NPCs already tracked in " .. container:GetFullName())
        return
    end
    if #npcs > 0 then
        debugLog(config, "Valid NPC container found. Count=" .. tostring(#npcs))
        self:addNPC(container, markerModule, config)
    end
    if not container:IsA("Model") or container.Name ~= "Model" then
        return
    end
    if self.modelConnections[container] then
        return
    end

    local connection
    connection = container.ChildAdded:Connect(function(child)
        if child:IsA("Model") and (child.Name == "Male" or child.Name == "NPCS") then
            debugLog(config, "New candidate under container: " .. child:GetFullName())
            self:addNPC(container, markerModule, config)
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
