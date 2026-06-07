-- Main script connecting all modules
local Aimbot     = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Aimbot.lua"))()
local ESP        = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/ESP.lua"))()
local Fullbright = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Fullbright.lua"))()
local Teleport   = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/Teleport.lua"))()
local UI         = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/refs/heads/main/UI.lua"))()

-- Initialize your UI and pass the modules into it so your buttons work
if UI and UI.Init then
    UI.Init({
        Aimbot = Aimbot,
        ESP = ESP,
        Fullbright = Fullbright,
        Teleport = Teleport
    })
else
    print("Main loaded. Modules are ready for use!")
end
