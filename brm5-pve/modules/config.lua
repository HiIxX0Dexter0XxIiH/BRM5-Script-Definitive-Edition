-- Configuration Module
-- Contains all settings, constants, and state variables

local Config = {}

-- CONSTANTS
Config.RAYCAST_COOLDOWN = 0.15
Config.TARGET_HITBOX_SIZE = Vector3.new(15, 15, 15) -- Size of the modified hitboxes

-- TOGGLES (State)
Config.wallEnabled = false       -- ESP (Wallhack)
Config.silentEnabled = false     -- Makes targets bigger
Config.showHitbox = false        -- Shows the big hitbox box
Config.fullBrightEnabled = false -- Removes shadows/darkness
Config.guiVisible = true         -- Menu visibility
Config.isUnloaded = false        -- To stop the script

-- WEAPON PATCHES
Config.patchOptions = { 
    recoil = false, 
    firemodes = false 
}

-- COLORS (RGB: 0 to 255)
Config.visibleR, Config.visibleG, Config.visibleB = 0, 255, 0    -- Green for visible enemies
Config.hiddenR, Config.hiddenG, Config.hiddenB = 255, 0, 0       -- Red for enemies behind walls
Config.visibleColor = Color3.fromRGB(Config.visibleR, Config.visibleG, Config.visibleB)
Config.hiddenColor = Color3.fromRGB(Config.hiddenR, Config.hiddenG, Config.hiddenB)

-- Update color function
function Config:updateVisibleColor(r, g, b)
    if r then self.visibleR = r end
    if g then self.visibleG = g end
    if b then self.visibleB = b end
    self.visibleColor = Color3.fromRGB(self.visibleR, self.visibleG, self.visibleB)
end

function Config:updateHiddenColor(r, g, b)
    if r then self.hiddenR = r end
    if g then self.hiddenG = g end
    if b then self.hiddenB = b end
    self.hiddenColor = Color3.fromRGB(self.hiddenR, self.hiddenG, self.hiddenB)
end

return Config
