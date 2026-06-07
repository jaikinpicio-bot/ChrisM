-- Debugger Main Script (FIXED REPO LINKS)
local RepoURL = "https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/"

local function safeLoad(fileName)
    local success, content = pcall(function()
        return game:HttpGet(RepoURL .. fileName)
    end)
    
    if not success or not content then
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

-- Load Modules
safeLoad("Aimbot.lua")
safeLoad("ESP.lua")
safeLoad("Fullbright.lua")
safeLoad("Teleport.lua")
local UI = safeLoad("UI.lua")

-- Mount UI
if type(UI) == "table" and UI.mount then 
    UI.mount() 
end
