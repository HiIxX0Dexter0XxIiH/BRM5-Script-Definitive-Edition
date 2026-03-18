if typeof(clear) == "function" then
    clear()
end

local MAIN_VERSION = "cache-bust-2026-03-18-03"
local url = "https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/BRM5-Script-Definitive-Edition/main/brm5-pvp/main.lua?v="
    .. MAIN_VERSION .. "-" .. tostring(os.time())

local response = game:HttpGet(url)
local chunk, compileError = loadstring(response)
if not chunk then
    error("Failed to compile BRM5 PVP main loader: " .. tostring(compileError))
end

return chunk()
