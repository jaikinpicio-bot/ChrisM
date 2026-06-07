-- Direct Debugger Loader (Unbreakable URL version)
local function safeLoadDirect(url, fileName)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not content or content == "" then
        warn("❌ Failed to download: " .. fileName)
        return nil
    end
    
    local func, err = loadstring(content)
    if not func then
        warn("❌ SYNTAX ERROR IN " .. fileName .. ": " .. tostring(err))
        return nil
    end
    
    local execSuccess, result = pcall(func)
    if not execSuccess then
        warn("❌ RUNTIME ERROR IN " .. fileName .. ": " .. tostring(result))
        return nil
    end
    
    print("✅ " .. fileName .. " loaded perfectly.")
    return result
end

print("--- STARTING SYSTEM DIAGNOSTICS ---")

-- Split into pieces to bypass chat shortening completely
local firstPart  = "https://"
local secondPart = "raw.githubusercontent"
local thirdPart  = ".com/"

local base = firstPart .. secondPart .. thirdPart
local path = "jaikinpicio-bot/ChrisM/refs/heads/main/"
local fullURL = base .. path

local Aimbot     = safeLoadDirect(fullURL .. "Aimbot.lua", "Aimbot.lua")
local ESP        = safeLoadDirect(fullURL .. "ESP.lua", "ESP.lua")
local Fullbright = safeLoadDirect(fullURL .. "Fullbright.lua", "Fullbright.lua")
local Teleport   = safeLoadDirect(fullURL .. "Teleport.lua", "Teleport.lua")
local UI         = safeLoadDirect(fullURL .. "UI.lua", "UI.lua")

print("--- DIAGNOSTICS COMPLETE ---")

-- Execute Mounting
if type(UI) == "table" and UI.mount then 
    UI.mount() 
end
