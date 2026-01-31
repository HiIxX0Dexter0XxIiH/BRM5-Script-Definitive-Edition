-- BRM5 PVE Loader (GitHub Version)
-- Este es un ejemplo de cómo cargar el script desde GitHub
-- Reemplaza YOUR_USERNAME y YOUR_REPO con tus datos reales

local GITHUB_USER = "YOUR_USERNAME"  -- Tu usuario de GitHub
local GITHUB_REPO = "YOUR_REPO"      -- Nombre de tu repositorio
local BRANCH = "main"                -- Rama (normalmente "main" o "master")

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
