-- =====================
-- MAIN: ChrisM Hub
-- =====================
local BASE = "https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/main/"

local function load(path)
    print("⏳ Loading: " .. path)
    local src = game:HttpGet(BASE .. path)
    print("📦 Got " .. #src .. " bytes for: " .. path)
    local fn, err = loadstring(src)
    if not fn then
        error("❌ COMPILE ERROR in " .. path .. ": " .. tostring(err), 2)
    end
    print("✅ OK: " .. path)
    return fn()
end

local Aimbot     = load("Aimbot.lua")
local ESP        = load("ESP.lua")
local Fullbright = load("Fullbright.lua")
local Teleport   = load("Teleport.lua")
local ItemESP    = load("ItemESP.lua")
local EventESP   = load("EventESP.lua")
local UI         = load("UI.lua")

Aimbot:Init()
ESP:Init()
Teleport:Init()
ItemESP:Init()
EventESP:Init()

-- ══════════════════════════════════════════
-- VISUALS PAGE
-- ══════════════════════════════════════════
local VisualsPage = UI.makePage("Visuals")
UI.makePageTitle(VisualsPage, "Visuals")

-- ── Player ESP ────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Player ESP")

local subChams, subHealth, subSkeleton, subBoxes, subNames, subWeapon, subZombies

UI.makeToggleRow(VisualsPage, 0, "ESP", false, function(state)
    ESP:SetEnabled(state)
    subChams.Visible    = state
    subHealth.Visible   = state
    subSkeleton.Visible = state
    subBoxes.Visible    = state
    subNames.Visible    = state
    subWeapon.Visible   = state
    subZombies.Visible  = state
end)

subChams    = UI.makeSubToggleRow(VisualsPage, 0, "Chams",        false, function(s) ESP:SetChams(s)    end)
subHealth   = UI.makeSubToggleRow(VisualsPage, 0, "Health Bars",  false, function(s) ESP.HealthBars = s end)
subSkeleton = UI.makeSubToggleRow(VisualsPage, 0, "Skeleton",     false, function(s) ESP:SetSkeleton(s) end)
subBoxes    = UI.makeSubToggleRow(VisualsPage, 0, "Boxes",        true,  function(s) ESP.Boxes = s      end)
subNames    = UI.makeSubToggleRow(VisualsPage, 0, "Names",        true,  function(s) ESP.Names = s      end)
subWeapon   = UI.makeSubToggleRow(VisualsPage, 0, "Weapon Label", true,  function(s) ESP.WeaponText = s end)
subZombies  = UI.makeSubToggleRow(VisualsPage, 0, "Zombies",      false, function(s) ESP:SetZombies(s)  end)

-- ── Item ESP ──────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Item ESP")

local subAccessories

UI.makeToggleRow(VisualsPage, 0, "Item ESP", false, function(state)
    ItemESP:SetEnabled(state)
    subAccessories.Visible = state
end)

subAccessories = UI.makeSubToggleRow(VisualsPage, 0, "Accessories", true, function(s) ItemESP:SetAccessories(s) end)

UI.makeSliderRow(VisualsPage, 0, "Item ESP Distance (m)", 50, 2000, 500, function(val)
    ItemESP.MaxDistance = val
end)

-- ── Event ESP ─────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Event ESP")

UI.makeToggleRow(VisualsPage, 0, "Event ESP", false, function(state)
    EventESP:SetEnabled(state)
end)

UI.makeSliderRow(VisualsPage, 0, "Event ESP Distance (m)", 50, 5000, 1000, function(val)
    EventESP.MaxDistance = val
end)

-- ── World ─────────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— World")
UI.makeToggleRow(VisualsPage, 0, "Fullbright", false, function(state)
    Fullbright:SetEnabled(state)
end)

-- ══════════════════════════════════════════
-- COMBAT PAGE
-- ══════════════════════════════════════════
local CombatPage = UI.makePage("Combat")
UI.makePageTitle(CombatPage, "Combat")

UI.makeToggleRow(CombatPage, 0, "Aimbot", false, function(state)
    Aimbot:SetEnabled(state)
end)
UI.makeToggleRow(CombatPage, 0, "Check Walls", true, function(state)
    Aimbot.WallCheck = state
end)
UI.makeSliderRow(CombatPage, 0, "FOV Radius (px)", 50, 400, 150, function(val)
    Aimbot.FOV = val
    local c = Aimbot:GetOverlayCircle(); if c then c.Radius = val end
end)
UI.makeSliderRow(CombatPage, 0, "Smoothness", 1, 20, 3, function(val)
    Aimbot.Smooth = val
end)
UI.makeDropdownRow(CombatPage, 0, "Target Bone", {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso", "RightUpperArm", "LeftUpperArm"
}, 1, function(val)
    Aimbot.TargetBone = val
end)
UI.makeSliderRow(CombatPage, 0, "Bullet Velocity (studs/s)", 1, 4625, 800, function(val)
    Aimbot.BulletVelocity = val
end)

-- ══════════════════════════════════════════
-- MOVEMENT PAGE
-- ══════════════════════════════════════════
local MovementPage = UI.makePage("Movement")
UI.makePageTitle(MovementPage, "Teleport")

local usernameInput = UI.makeInputRow(MovementPage, 0, "Target Username", "Enter username...")
UI.makeSliderRow(MovementPage, 0, "Behind Offset (studs)", 1, 30, 15, function(val)
    Teleport.BehindOffset = val
end)

local statusLbl = UI.makeStatusLabel(MovementPage)
Teleport:OnStatusChange(function(msg, color)
    statusLbl.Text       = "Status: " .. msg
    statusLbl.TextColor3 = color
end)

local instantTPBtn = UI.makeActionBtn(MovementPage, 0, "⚡ One-Time Teleport")
local startTPBtn   = UI.makeActionBtn(MovementPage, 0, "🔄 Start Loop Tracking")
startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
local stopTPBtn    = UI.makeActionBtn(MovementPage, 0, "Stop")
stopTPBtn.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
stopTPBtn.TextColor3       = Color3.new(0.6, 0.6, 0.6)

instantTPBtn.MouseButton1Click:Connect(function()
    instantTPBtn.Text = "⏳ Teleporting..."
    Teleport:Once(usernameInput.getValue(), function(success)
        if not success then instantTPBtn.Text = "❌ Not Found" end
        task.delay(1.5, function() instantTPBtn.Text = "⚡ One-Time Teleport" end)
    end)
end)

startTPBtn.MouseButton1Click:Connect(function()
    if Teleport.IsTracking then return end
    Teleport:StartTracking(
        usernameInput.getValue(),
        function(_target)
            startTPBtn.Text             = "🟢 Tracking..."
            startTPBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
            stopTPBtn.BackgroundColor3  = Color3.new(0, 0.835, 1)
            stopTPBtn.TextColor3        = Color3.new(1, 1, 1)
        end,
        function()
            startTPBtn.Text = "❌ Not Found"
            task.delay(1.5, function()
                startTPBtn.Text             = "🔄 Start Loop Tracking"
                startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            end)
        end
    )
end)

stopTPBtn.MouseButton1Click:Connect(function()
    if not Teleport.IsTracking then return end
    Teleport:StopTracking()
    startTPBtn.Text             = "🔄 Start Loop Tracking"
    startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    stopTPBtn.BackgroundColor3  = Color3.new(0.18, 0.18, 0.18)
    stopTPBtn.TextColor3        = Color3.new(0.6, 0.6, 0.6)
end)

-- ══════════════════════════════════════════
-- SIDEBAR + TAB SWITCHER
-- ══════════════════════════════════════════
local btnVisuals  = UI.makeSideBtn("Visuals",  0.126, "Visuals",  "6523858394")
local btnCombat   = UI.makeSideBtn("Combat",   0.233, "Combat",   "13050670424")
local btnMovement = UI.makeSideBtn("Movement", 0.34,  "Movement", "16181398272")

local switchTo = UI.setupTabSwitcher(
    { btnVisuals, btnCombat, btnMovement },
    { Visuals = VisualsPage, Combat = CombatPage, Movement = MovementPage }
)
switchTo(btnVisuals)

UI.setupDrag()
UI.setupWindowControls(function()
    Aimbot:Destroy()
    ESP:Destroy()
    ItemESP:Destroy()
    EventESP:Destroy()
    if Fullbright.Enabled then Fullbright:Remove() end
    if Teleport.IsTracking then Teleport:StopTracking() end
end)

UI.mount()
