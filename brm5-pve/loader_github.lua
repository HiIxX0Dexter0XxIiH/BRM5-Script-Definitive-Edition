-- BRM5 PVE Loader (GitHub Version)
-- Carga el script desde GitHub

local GITHUB_USER = "HiIxX0Dexter0XxIiH"
local GITHUB_REPO = "BRM5-Script-Definitive-Edition"
local BRANCH = "main"

-- URL del script principal
local MAIN_SCRIPT_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/brm5-pve/main.lua",
    GITHUB_USER,
    GITHUB_REPO,
    BRANCH
)

-- Cargar y ejecutar el script principal
print("🚀 Loading BRM5 PVE from GitHub...")
print("📍 Repository: " .. GITHUB_USER .. "/" .. GITHUB_REPO)

local success, result = pcall(function()
    return loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
end)

if not success then
    warn("❌ Failed to load BRM5 PVE script")
    warn("Error: " .. tostring(result))
    warn("Please verify:")
    warn("1. GitHub username and repository name are correct")
    warn("2. Repository is public")
    warn("3. Files are uploaded to GitHub")
    warn("4. Your internet connection is working")
else
    print("✅ BRM5 PVE loaded successfully!")
end
