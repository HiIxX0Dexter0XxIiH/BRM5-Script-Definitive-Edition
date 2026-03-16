-- BRM5 PVE Loader (GitHub Version)
-- Loads the main script from GitHub

local GITHUB_USER = "HiIxX0Dexter0XxIiH"
local GITHUB_REPO = "BRM5-Script-Definitive-Edition"
local BRANCH = "main"

local MAIN_SCRIPT_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/brm5-pve/main.lua",
    GITHUB_USER,
    GITHUB_REPO,
    BRANCH
)

print("Loading BRM5 PVE from GitHub...")
print("Repository: " .. GITHUB_USER .. "/" .. GITHUB_REPO)

local okResponse, response = pcall(function()
    return game:HttpGet(MAIN_SCRIPT_URL)
end)

if not okResponse then
    warn("Failed to load BRM5 PVE script")
    warn("URL: " .. MAIN_SCRIPT_URL)
    warn("HttpGet error: " .. tostring(response))
    warn("Please verify:")
    warn("1. GitHub username and repository name are correct")
    warn("2. Repository is public")
    warn("3. Files are uploaded to GitHub")
    warn("4. Your internet connection is working")
    return
end

if type(response) ~= "string" or response == "" then
    warn("Failed to load BRM5 PVE script")
    warn("URL: " .. MAIN_SCRIPT_URL)
    warn("Received empty content from GitHub")
    return
end

local chunk, compileError = loadstring(response)
if not chunk then
    warn("Failed to compile BRM5 PVE script")
    warn("URL: " .. MAIN_SCRIPT_URL)
    warn("Compile error: " .. tostring(compileError))
    warn("First line: " .. tostring((response:match("([^\r\n]+)") or ""):sub(1, 120)))
    return
end

local success, result = pcall(chunk)
if not success then
    warn("Failed to execute BRM5 PVE script")
    warn("URL: " .. MAIN_SCRIPT_URL)
    warn("Runtime error: " .. tostring(result))
    return
end

print("BRM5 PVE loaded successfully!")
