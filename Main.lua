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
-- Layout:
--   World (Fullbright) at top — quick toggle, always useful
--   Player ESP — main combat overlay
--   Item ESP   — gear on players
--   Event ESP  — map events
-- ══════════════════════════════════════════
local VisualsPage = UI.makePage("Visuals")
UI.makePageTitle(VisualsPage, "Visuals")

-- ── World ─────────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— World")
UI.makeToggleRow(VisualsPage, 0, "Fullbright", false, function(s)
    Fullbright:SetEnabled(s)
    UI.toast("Fullbright", s)
end)

-- ── Player ESP ────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Player ESP")

local subChams, subHealth, subBoxes, subNames, subWeapon, subSkeleton, subZombies

UI.makeToggleRow(VisualsPage, 0, "Player ESP", false, function(s)
    ESP:SetEnabled(s)
    subChams.Visible    = s
    subHealth.Visible   = s
    subBoxes.Visible    = s
    subNames.Visible    = s
    subWeapon.Visible   = s
    subSkeleton.Visible = s
    subZombies.Visible  = s
    UI.toast("Player ESP", s)
end)

-- Most-used first, secondary options after
subNames    = UI.makeSubToggleRow(VisualsPage, 0, "Names",        true,  function(s) ESP.Names = s      UI.toast("Names", s)        end)
subBoxes    = UI.makeSubToggleRow(VisualsPage, 0, "Boxes",        true,  function(s) ESP.Boxes = s      UI.toast("Boxes", s)        end)
subChams    = UI.makeSubToggleRow(VisualsPage, 0, "Chams",        false, function(s) ESP:SetChams(s)    UI.toast("Chams", s)        end)
subHealth   = UI.makeSubToggleRow(VisualsPage, 0, "Health Bars",  false, function(s) ESP.HealthBars = s UI.toast("Health Bars", s)  end)
subWeapon   = UI.makeSubToggleRow(VisualsPage, 0, "Weapon Label", true,  function(s) ESP.WeaponText = s UI.toast("Weapon Label", s) end)
subSkeleton = UI.makeSubToggleRow(VisualsPage, 0, "Skeleton",     false, function(s) ESP:SetSkeleton(s) UI.toast("Skeleton", s)     end)
subZombies  = UI.makeSubToggleRow(VisualsPage, 0, "Zombies",      false, function(s) ESP:SetZombies(s)  UI.toast("Zombies", s)      end)

UI.makeSliderRow(VisualsPage, 0, "Distance (m)", 10, 5000, 500, function(val)
    ESP.MaxDistance = val
end)

-- ── Item ESP ──────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Item ESP")

local subAccessories

UI.makeToggleRow(VisualsPage, 0, "Item ESP", false, function(s)
    ItemESP:SetEnabled(s)
    subAccessories.Visible = s
    UI.toast("Item ESP", s)
end)

subAccessories = UI.makeSubToggleRow(VisualsPage, 0, "Accessories", true, function(s)
    ItemESP:SetAccessories(s)
    UI.toast("Accessories", s)
end)

UI.makeSliderRow(VisualsPage, 0, "Distance (m)", 50, 5000, 500, function(val)
    ItemESP.MaxDistance = val
end)

-- ── Event ESP ─────────────────────────────
UI.makeSectionLabel(VisualsPage, 0, "— Event ESP")

UI.makeToggleRow(VisualsPage, 0, "Event ESP", false, function(s)
    EventESP:SetEnabled(s)
    UI.toast("Event ESP", s)
end)

UI.makeSliderRow(VisualsPage, 0, "Distance (m)", 50, 5000, 1000, function(val)
    EventESP.MaxDistance = val
end)

-- ══════════════════════════════════════════
-- COMBAT PAGE
-- Layout:
--   Aimbot toggle
--   Wall Check
--   ── Targeting ──
--   Target Bone dropdown
--   FOV slider
--   ── Behaviour ──
--   Smoothness slider
--   Bullet Velocity slider
-- ══════════════════════════════════════════
local CombatPage = UI.makePage("Combat")
UI.makePageTitle(CombatPage, "Combat")

UI.makeToggleRow(CombatPage, 0, "Aimbot", false, function(s)
    Aimbot:SetEnabled(s)
    UI.toast("Aimbot", s)
end)
UI.makeToggleRow(CombatPage, 0, "Wall Check", true, function(s)
    Aimbot.WallCheck = s
    UI.toast("Wall Check", s)
end)

UI.makeSectionLabel(CombatPage, 0, "— Targeting")
UI.makeDropdownRow(CombatPage, 0, "Target Bone", {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso", "RightUpperArm", "LeftUpperArm"
}, 1, function(val)
    Aimbot.TargetBone = val
end)
UI.makeSliderRow(CombatPage, 0, "FOV Radius (px)", 50, 400, 150, function(val)
    Aimbot.FOV = val
    local c = Aimbot:GetOverlayCircle(); if c then c.Radius = val end
end)

UI.makeSectionLabel(CombatPage, 0, "— Behaviour")
UI.makeSliderRow(CombatPage, 0, "Smoothness", 1, 20, 3, function(val)
    Aimbot.Smooth = val
end)
UI.makeSliderRow(CombatPage, 0, "Bullet Velocity (studs/s)", 1, 4625, 800, function(val)
    Aimbot.BulletVelocity = val
end)

-- ══════════════════════════════════════════
-- PLAYER PAGE (Teleport)
-- Layout:
--   Target input
--   Behind Offset slider
--   Status label
--   ── Actions ──
--   One-Time TP
--   Loop Tracking
--   Stop
-- ══════════════════════════════════════════
local PlayerPage = UI.makePage("Player")
UI.makePageTitle(PlayerPage, "Player")

UI.makeSectionLabel(PlayerPage, 0, "— Teleport")
local usernameInput = UI.makeInputRow(PlayerPage, 0, "Target", "Enter username...")
UI.makeSliderRow(PlayerPage, 0, "Behind Offset (studs)", 1, 30, 15, function(val)
    Teleport.BehindOffset = val
end)

local statusLbl = UI.makeStatusLabel(PlayerPage)
Teleport:OnStatusChange(function(msg, color)
    statusLbl.Text       = "Status: " .. msg
    statusLbl.TextColor3 = color
end)

UI.makeSectionLabel(PlayerPage, 0, "— Actions")
local instantTPBtn = UI.makeActionBtn(PlayerPage, 0, "⚡ One-Time Teleport")
local startTPBtn   = UI.makeActionBtn(PlayerPage, 0, "🔄 Start Loop Tracking")
startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
local stopTPBtn    = UI.makeActionBtn(PlayerPage, 0, "⏹ Stop Tracking")
stopTPBtn.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
stopTPBtn.TextColor3       = Color3.new(0.5, 0.5, 0.5)

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
    stopTPBtn.TextColor3        = Color3.new(0.5, 0.5, 0.5)
end)

-- ══════════════════════════════════════════
-- SIDEBAR + TAB SWITCHER
-- ══════════════════════════════════════════
local btnVisuals = UI.makeSideBtn("Visuals", 0.126, "Visuals",  "6523858394")
local btnCombat  = UI.makeSideBtn("Combat",  0.233, "Combat",   "13050670424")
local btnPlayer  = UI.makeSideBtn("Player",  0.34,  "Player",   "16181398272")

local switchTo = UI.setupTabSwitcher(
    { btnVisuals, btnCombat, btnPlayer },
    { Visuals = VisualsPage, Combat = CombatPage, Player = PlayerPage }
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
