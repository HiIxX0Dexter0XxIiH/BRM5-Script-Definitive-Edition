-- Hitbox Module
-- Handles modification of NPC hitboxes for silent aim

local Hitbox = {}

Hitbox.originalSizes = {} -- Storage for original sizes to restore them later

-- Makes the NPC hitboxes larger (Silent Aim effect)
function Hitbox:applySilentHitbox(model, root, config)
    if not self.originalSizes[model] then 
        self.originalSizes[model] = root.Size 
    end
    
    root.Size = config.TARGET_HITBOX_SIZE
    root.Transparency = config.showHitbox and 0.85 or 1 -- If showHitbox is true, you'll see a faint box
    root.CanCollide = true
end

-- Restores hitboxes to their normal size
function Hitbox:restoreOriginalSize(model, npcManager)
    local root = npcManager.getRootPart(model)
    if root and self.originalSizes[model] then
        root.Size = self.originalSizes[model]
        root.Transparency = 1
        root.CanCollide = false
    end
    self.originalSizes[model] = nil
end

-- Updates hitboxes for all NPCs based on config
function Hitbox:updateAllHitboxes(npcManager, config)
    if config.silentEnabled then
        for model, data in pairs(npcManager:getActiveNPCs()) do
            self:applySilentHitbox(model, data.root, config)
        end
    end
end

-- Cleanup all modified hitboxes
function Hitbox:cleanup(npcManager)
    for model, _ in pairs(self.originalSizes) do
        self:restoreOriginalSize(model, npcManager)
    end
end

return Hitbox
