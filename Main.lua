-- Main script connecting all modules
local Aimbot     = loadstring(game:HttpGet("https://githubusercontent.com"))()
local ESP        = loadstring(game:HttpGet("https://githubusercontent.com"))()
local Fullbright = loadstring(game:HttpGet("https://githubusercontent.com"))()
local Teleport   = loadstring(game:HttpGet("https://githubusercontent.com"))()
local UI         = loadstring(game:HttpGet("https://githubusercontent.com"))()

-- Initialize your UI and pass the modules into it so your buttons work
-- (Adjust this function call to match whatever init function is in your UI.lua)
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
