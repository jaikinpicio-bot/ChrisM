-- Debugger Main Script
local RepoURL = "https://githubusercontent.com"

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
        -- This will print out exactly WHICH file is causing the "bytecode corrupted" crash
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

-- Test each module individually
print("--- STARTING SYSTEM DIAGNOSTICS ---")
local Aimbot     = safeLoad("Aimbot.lua")
local ESP        = safeLoad("ESP.lua")
local Fullbright = safeLoad("Fullbright.lua")
local Teleport   = safeLoad("Teleport.lua")
local UI         = safeLoad("UI.lua")
print("--- DIAGNOSTICS COMPLETE ---")

-- Run the UI if it'll work
if type(UI) == "table" then
    UI.ActiveModules = { Aimbot = Aimbot, ESP = ESP, Fullbright = Fullbright, Teleport = Teleport }
    if UI.mount then UI.mount() end
end
