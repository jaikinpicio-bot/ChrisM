
-- Main script connecting all modules
local Aimbot     = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Aimbot.lua"))()
local ESP        = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/ESP.lua"))()
local Fullbright = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Fullbright.lua"))()
local Teleport   = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Teleport.lua"))()
local UI         = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/UI.lua"))()

print("Main loaded. Modules are ready for use!")

-- Securely pass the modules over to the UI if it handles them globally
if type(UI) == "table" then
    UI.ActiveModules = {
        Aimbot = Aimbot,
        ESP = ESP,
        Fullbright = Fullbright,
        Teleport = Teleport
    }
    
    -- Actively fire your custom mount function to display the ScreenGui
    if UI.mount then
        UI.mount()
        print("UI successfully mounted to screen!")
    else
        print("Error: UI table loaded, but UI.mount function was missing.")
    end
else
    print("Error: UI module failed to return a table structure.")
end
