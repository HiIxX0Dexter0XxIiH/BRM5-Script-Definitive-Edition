-- NPC Manager Module
-- Handles detection and tracking of enemy NPCs

local NPCManager = {}
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

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

function NPCManager:isCandidateNPCModel(model)
    return model
        and model:IsA("Model")
        and (model.Name == "Male" or model.Name == "NPCS")
        and not model:FindFirstChildWhichIsA("BillboardGui", true)
end

function NPCManager:getDetectionOrigin(workspace)
    local character = localPlayer and localPlayer.Character
    local root = character and self.getRootPart(character)
    if root then
        return root.Position
    end

    local camera = workspace and workspace.CurrentCamera
    return camera and camera.CFrame.Position or nil
end

function NPCManager:isWithinDetectionRadius(model, workspace, config)
    if not config then
        return true
    end

    local origin = self:getDetectionOrigin(workspace)
    if not origin then
        return true
    end

    local root = self.getRootPart(model) or model:FindFirstChild("Head")
    local targetPosition = root and root.Position or model:GetPivot().Position
    local distance = (targetPosition - origin).Magnitude
    local inRange = distance <= (config.npcDetectionRadius or math.huge)

    if config and config.debugNPCDetection and (model.Name == "Male" or model.Name == "NPCS") then
        debugLog(
            config,
            "Range check for " .. model:GetFullName()
                .. " | distance=" .. string.format("%.1f", distance)
                .. " | max=" .. tostring(config.npcDetectionRadius)
                .. " | inRange=" .. tostring(inRange)
        )
    end

    return inRange
end

-- Gets the NPC model either from Workspace.Model.Male/NPCS or direct Workspace.Male/NPCS.
function NPCManager:getNPCModel(container, workspace, config)
    if not (config and config.isNPCDetectionEnabled and config:isNPCDetectionEnabled()) then
        return nil
    end

    if not container or not container:IsA("Model") then
        return nil
    end

    if config and config.debugNPCDetection then
        debugLog(config, "Inspecting container: " .. container:GetFullName() .. " | name=" .. container.Name)
    end

    if self:isCandidateNPCModel(container) then
        debugLog(config, "Direct candidate found: " .. container:GetFullName())
    end
    if self:isCandidateNPCModel(container) and self:isWithinDetectionRadius(container, workspace, config) then
        if container.Name == "Male" then
            debugLog(config, "Renaming direct Male -> NPCS: " .. container:GetFullName())
            container.Name = "NPCS"
        end
        debugLog(config, "Accepted direct NPC: " .. container:GetFullName())
        return container
    end

    if container.Name ~= "Model" then
        return nil
    end

    local npc = container:FindFirstChild("NPCS")
    if npc and npc:IsA("Model") then
        debugLog(config, "Found nested NPCS: " .. npc:GetFullName())
    end
    if npc and npc:IsA("Model") and self:isWithinDetectionRadius(npc, workspace, config) then
        debugLog(config, "Accepted nested NPCS: " .. npc:GetFullName())
        return npc
    end

    local male = container:FindFirstChild("Male")
    if male and male:IsA("Model") then
        local hasBillboard = male:FindFirstChildWhichIsA("BillboardGui", true) ~= nil
        debugLog(
            config,
            "Found nested Male: " .. male:GetFullName()
                .. " | hasBillboard=" .. tostring(hasBillboard)
        )
    end
    if male
        and male:IsA("Model")
        and not male:FindFirstChildWhichIsA("BillboardGui", true)
        and self:isWithinDetectionRadius(male, workspace, config) then
        debugLog(config, "Renaming nested Male -> NPCS: " .. male:GetFullName())
        male.Name = "NPCS"
        debugLog(config, "Accepted nested Male as NPCS: " .. male:GetFullName())
        return male
    end

    if male and male:IsA("Model") then
        debugLog(config, "Rejected nested Male: " .. male:GetFullName())
    end

    return nil
end

-- Checks if the container matches the new NPC structure
function NPCManager:isNPCModel(container, workspace, config)
    return self:getNPCModel(container, workspace, config) ~= nil
end

-- Adds a specific NPC model to our tracking list
function NPCManager:addNPCModel(npc, container, markerModule, config)
    if not npc or self.activeNPCs[npc] then
        if npc and self.activeNPCs[npc] then
            debugLog(config, "Skipping already tracked NPC: " .. npc:GetFullName())
        end
        return
    end
    local head = npc:FindFirstChild("Head")
    local root = self.getRootPart(npc)
    
    if not head or not root then 
        debugLog(config, "Rejecting NPC without head/root: " .. npc:GetFullName())
        return 
    end
    
    self.activeNPCs[npc] = { head = head, root = root, character = npc, container = container }
    debugLog(config, "Registered NPC: " .. npc:GetFullName())
    
    -- Create marker box if visibility markers are enabled
    if markerModule and markerModule.isEnabled() then
        markerModule.createBoxForPart(head, config)
    end
end

-- Adds all valid NPCs under a container
function NPCManager:addNPC(container, workspace, markerModule, config)
    local npc = self:getNPCModel(container, workspace, config)
    if not npc then
        debugLog(config, "No NPC resolved for container: " .. container:GetFullName())
        return
    end

    self:addNPCModel(npc, container, markerModule, config)
end

-- Tracks a model and waits for Male if it appears later
function NPCManager:trackPotentialNPC(container, workspace, markerModule, config)
    if not (config and config.isNPCDetectionEnabled and config:isNPCDetectionEnabled()) then
        debugLog(config, "Skipping detection because features are disabled")
        return
    end

    local npc = self:getNPCModel(container, workspace, config)
    if npc and self.activeNPCs[npc] then
        debugLog(config, "Container already tracked: " .. npc:GetFullName())
        return
    end
    if npc then
        debugLog(config, "Resolved NPC from container: " .. container:GetFullName())
        self:addNPC(container, workspace, markerModule, config)
        return
    end
    if not container:IsA("Model") then
        return
    end
    if container.Name ~= "Model" or self.modelConnections[container] then
        return
    end

    local connection
    connection = container.ChildAdded:Connect(function(child)
        if child:IsA("Model") and (child.Name == "Male" or child.Name == "NPCS") then
            debugLog(config, "ChildAdded candidate: " .. child:GetFullName())
            self:addNPC(container, workspace, markerModule, config)
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

function NPCManager:removeNPCModel(model, markerModule, targetSizing)
    local data = self.activeNPCs[model]
    if not data then
        return
    end

    if targetSizing then
        targetSizing:restoreOriginalSize(model, self)
    end
    if markerModule and data.head then
        markerModule.destroyBoxForPart(data.head)
    end

    self.activeNPCs[model] = nil
end

function NPCManager:refreshTrackedNPCs(workspace, markerModule, targetSizing, config)
    if not (config and config.isNPCDetectionEnabled and config:isNPCDetectionEnabled()) then
        local trackedModels = {}
        for model, _ in pairs(self.activeNPCs) do
            table.insert(trackedModels, model)
        end
        for _, model in ipairs(trackedModels) do
            self:removeNPCModel(model, markerModule, targetSizing)
        end
        return
    end

    local modelsToRemove = {}
    for model, _ in pairs(self.activeNPCs) do
        if not model.Parent or not self:isWithinDetectionRadius(model, workspace, config) then
            table.insert(modelsToRemove, model)
        end
    end
    for _, model in ipairs(modelsToRemove) do
        self:removeNPCModel(model, markerModule, targetSizing)
    end

    for _, container in ipairs(workspace:GetChildren()) do
        if container:IsA("Model") then
            self:trackPotentialNPC(container, workspace, markerModule, config)
        end
    end
end

-- Scans workspace for existing NPCs
function NPCManager:scanWorkspace(workspace, markerModule, config)
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") then 
            self:trackPotentialNPC(m, workspace, markerModule, config)
        end
    end
end

-- Sets up listener for new NPCs
function NPCManager:setupListener(workspace, markerModule, config)
    local connection = workspace.ChildAdded:Connect(function(m)
        if m:IsA("Model") then 
            task.delay(0.2, function() 
                self:trackPotentialNPC(m, workspace, markerModule, config)
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
