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
    local ok, result = pcall(fn)
    if not ok then
        error("❌ RUNTIME ERROR in " .. path .. ": " .. tostring(result), 2)
    end
    print("✅ OK: " .. path)
    return result
end

local Aimbot     = load("Aimbot.lua")
local ESP        = load("ESP.lua")
local Fullbright = load("Fullbright.lua")
local Teleport   = load("Teleport.lua")
local ItemESP    = load("ItemESP.lua")
local EventESP   = load("EventESP.lua")
local UI         = load("UI.lua")

-- Sanity check all critical UI functions exist before proceeding
local required = {
    "makePage","getCol","makeSectionLabel","makeToggleRow","makeSubToggleRow",
    "makeSliderRow","makeDropdownRow","makeInputRow","makeActionBtn",
    "makeStatusLabel","makeSpacer","setupNavigation","switchTo",
    "setupDrag","setupWindowControls","toast","mount"
}
for _, fn in ipairs(required) do
    if type(UI[fn]) ~= "function" then
        error("❌ UI missing function: " .. fn)
    end
end
print("✅ UI API verified")

Aimbot:Init()
ESP:Init()
Teleport:Init()
ItemESP:Init()
EventESP:Init()

-- ══════════════════════════════════════════
-- COMBAT PAGE  (nav key: "combat")
-- ══════════════════════════════════════════
UI.makePage("combat")
local cL = UI.getCol("combat", "left")
local cR = UI.getCol("combat", "right")

-- Left column
UI.makeSectionLabel(cL, "Aimbot")
UI.makeToggleRow(cL, "Aimbot", false, function(s)
    Aimbot:SetEnabled(s)
    UI.toast("Aimbot", s)
end)
UI.makeToggleRow(cL, "Wall Check", true, function(s)
    Aimbot.WallCheck = s
    UI.toast("Wall Check", s)
end)

UI.makeSectionLabel(cL, "Targeting")
UI.makeDropdownRow(cL, "Target Bone", {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso", "RightUpperArm", "LeftUpperArm"
}, 1, function(val)
    Aimbot.TargetBone = val
end)
UI.makeSliderRow(cL, "FOV Radius (px)", 50, 400, 150, function(val)
    Aimbot.FOV = val
    local c = Aimbot:GetOverlayCircle()
    if c then c.Radius = val end
end)

-- Right column
UI.makeSectionLabel(cR, "Behaviour")
UI.makeSliderRow(cR, "Smoothness", 1, 20, 3, function(val)
    Aimbot.Smooth = val
end)
UI.makeSliderRow(cR, "Bullet Velocity (studs/s)", 1, 4625, 800, function(val)
    Aimbot.BulletVelocity = val
end)

-- ══════════════════════════════════════════
-- LEGIT PAGE  (nav key: "legit")
-- ══════════════════════════════════════════
UI.makePage("legit")

-- ══════════════════════════════════════════
-- VISUALS PAGE  (nav key: "visuals")
-- ══════════════════════════════════════════
UI.makePage("visuals")
local vL = UI.getCol("visuals", "left")
local vR = UI.getCol("visuals", "right")

UI.makeSectionLabel(vL, "Player ESP")

local subChams, subHealth, subBoxes, subNames, subWeapon, subSkeleton, subZombies

UI.makeToggleRow(vL, "Player ESP", false, function(s)
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

subNames    = UI.makeSubToggleRow(vL, "Names",        true,  function(s) ESP.Names = s       UI.toast("Names", s)        end)
subBoxes    = UI.makeSubToggleRow(vL, "Boxes",        true,  function(s) ESP.Boxes = s       UI.toast("Boxes", s)        end)
subChams    = UI.makeSubToggleRow(vL, "Chams",        false, function(s) ESP:SetChams(s)     UI.toast("Chams", s)        end)
subHealth   = UI.makeSubToggleRow(vL, "Health Bars",  false, function(s) ESP.HealthBars = s  UI.toast("Health Bars", s)  end)
subWeapon   = UI.makeSubToggleRow(vL, "Weapon Label", true,  function(s) ESP.WeaponText = s  UI.toast("Weapon Label", s) end)
subSkeleton = UI.makeSubToggleRow(vL, "Skeleton",     false, function(s) ESP:SetSkeleton(s)  UI.toast("Skeleton", s)     end)
subZombies  = UI.makeSubToggleRow(vL, "Zombies",      false, function(s) ESP:SetZombies(s)   UI.toast("Zombies", s)      end)

UI.makeSliderRow(vL, "ESP Distance (m)", 10, 5000, 500, function(val)
    ESP.MaxDistance = val
end)

UI.makeSectionLabel(vR, "Item ESP")

local subAccessories

UI.makeToggleRow(vR, "Item ESP", false, function(s)
    ItemESP:SetEnabled(s)
    subAccessories.Visible = s
    UI.toast("Item ESP", s)
end)

subAccessories = UI.makeSubToggleRow(vR, "Accessories", true, function(s)
    ItemESP:SetAccessories(s)
    UI.toast("Accessories", s)
end)

UI.makeSliderRow(vR, "Item Distance (m)", 50, 5000, 500, function(val)
    ItemESP.MaxDistance = val
end)

UI.makeSpacer(vR, 6)
UI.makeSectionLabel(vR, "Event ESP")

UI.makeToggleRow(vR, "Event ESP", false, function(s)
    EventESP:SetEnabled(s)
    UI.toast("Event ESP", s)
end)

UI.makeSliderRow(vR, "Event Distance (m)", 50, 5000, 1000, function(val)
    EventESP.MaxDistance = val
end)

-- ══════════════════════════════════════════
-- WORLD PAGE  (nav key: "world")
-- ══════════════════════════════════════════
UI.makePage("world")
local wL = UI.getCol("world", "left")

UI.makeSectionLabel(wL, "Lighting")
UI.makeToggleRow(wL, "Fullbright", false, function(s)
    Fullbright:SetEnabled(s)
    UI.toast("Fullbright", s)
end)

-- ══════════════════════════════════════════
-- MOVEMENT PAGE  (nav key: "movement")
-- ══════════════════════════════════════════
UI.makePage("movement")
local mL = UI.getCol("movement", "left")

UI.makeSectionLabel(mL, "Teleport")

local inputRow, getUsername = UI.makeInputRow(mL, "Target Username", "Enter username...")

UI.makeSliderRow(mL, "Behind Offset (studs)", 1, 30, 15, function(val)
    Teleport.BehindOffset = val
end)

local statusLbl = UI.makeStatusLabel(mL)
Teleport:OnStatusChange(function(msg, color)
    statusLbl.Text       = "Status: " .. msg
    statusLbl.TextColor3 = color
end)

UI.makeSpacer(mL, 4)
UI.makeSectionLabel(mL, "Actions")

local instantTPBtn = UI.makeActionBtn(mL, "⚡ One-Time Teleport")
local startTPBtn   = UI.makeActionBtn(mL, "🔄 Start Loop Tracking", Color3.fromRGB(180, 40, 40))
local stopTPBtn    = UI.makeActionBtn(mL, "⏹ Stop Tracking",       Color3.fromRGB(46, 46, 46))
stopTPBtn.TextColor3 = Color3.fromRGB(128, 128, 128)

instantTPBtn.MouseButton1Click:Connect(function()
    instantTPBtn.Text = "⏳ Teleporting..."
    Teleport:Once(getUsername(), function(success)
        if not success then instantTPBtn.Text = "❌ Not Found" end
        task.delay(1.5, function() instantTPBtn.Text = "⚡ One-Time Teleport" end)
    end)
end)

startTPBtn.MouseButton1Click:Connect(function()
    if Teleport.IsTracking then return end
    Teleport:StartTracking(
        getUsername(),
        function(_target)
            startTPBtn.Text             = "🟢 Tracking..."
            startTPBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
            stopTPBtn.BackgroundColor3  = Color3.fromRGB(0, 213, 255)
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
    stopTPBtn.BackgroundColor3  = Color3.fromRGB(46, 46, 46)
    stopTPBtn.TextColor3        = Color3.fromRGB(128, 128, 128)
end)

-- ══════════════════════════════════════════
-- MISC PAGE  (nav key: "misc")
-- ══════════════════════════════════════════
UI.makePage("misc")

-- ══════════════════════════════════════════
-- NAVIGATION + DRAG + WINDOW CONTROLS
-- ══════════════════════════════════════════
UI.setupNavigation()
UI.switchTo("combat")

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
