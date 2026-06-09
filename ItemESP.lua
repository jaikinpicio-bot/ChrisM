-- =====================
-- MODULE: ItemESP
-- =====================
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local ItemESP = {}

-- ── Config ─────────────────────────────────────────────────
ItemESP.Enabled     = false
ItemESP.Accessories = true
ItemESP.MaxDistance = 500

local ESP_COLOR  = Color3.fromRGB(255, 0, 0)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local ACCESSORY_PREFIXES = { "Accessory", "Belt", "Hat" }

local function isAccessory(name)
    for _, prefix in ipairs(ACCESSORY_PREFIXES) do
        if string.sub(name, 1, #prefix) == prefix then return true end
    end
    return false
end

-- ── Zombie detection ───────────────────────────────────────
local function isZombie(model)
    local zombieFolder = Workspace:FindFirstChild("Zombies")
    if not zombieFolder then return false end
    return model.Parent == zombieFolder
end

-- ── Item registry ──────────────────────────────────────────
local TargetItems = {}

local function buildRegistry()
    local ok, itemsFolder = pcall(function()
        return ReplicatedStorage:WaitForChild("Assets", 5):WaitForChild("Items", 5)
    end)
    if not ok or not itemsFolder then
        warn("ItemESP: Could not find ReplicatedStorage.Assets.Items")
        return
    end
    for _, item in ipairs(itemsFolder:GetChildren()) do
        TargetItems[item.Name:lower()] = true
    end
end

-- ── Player char registry ───────────────────────────────────
local playerChars = {}

local function refreshPlayerChars()
    playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
end

local function isOwnedByPlayer(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and model:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

-- ── Should this model have ESP? ────────────────────────────
local function shouldESP(model)
    if not ItemESP.Enabled then return false end

    -- Accessories: show even on players (hats, belts etc worn by players)
    if isAccessory(model.Name) then
        return ItemESP.Accessories
    end

    -- Registered items: only show if NOT owned by a player
    if TargetItems[model.Name:lower()] then
        if isOwnedByPlayer(model) then return false end
        return true
    end

    return false
end

-- ── Apply / remove ESP ─────────────────────────────────────
local function applyESP(model)
    if model:FindFirstChild("_ItemESP") then return end

    local anchor = model:FindFirstChild("Base")
        or model:FindFirstChildWhichIsA("MeshPart")
        or model:FindFirstChildWhichIsA("BasePart")
    if not anchor then return end

    local hl = Instance.new("Highlight")
    hl.Name                = "_ItemESP"
    hl.FillColor           = ESP_COLOR
    hl.FillTransparency    = 0.6
    hl.OutlineColor        = ESP_COLOR
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee             = model
    hl.Parent              = model

    local bb = Instance.new("BillboardGui")
    bb.Name          = "_ItemESPBB"
    bb.Size          = UDim2.new(0, 200, 0, 50)
    bb.AlwaysOnTop   = true
    bb.ExtentsOffset = Vector3.new(0, 1.5, 0)
    bb.Adornee       = anchor
    bb.Parent        = model

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = TEXT_COLOR
    lbl.TextSize               = 14
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextStrokeTransparency = 0
    lbl.Parent                 = bb

    task.spawn(function()
        while model and model.Parent and anchor and anchor.Parent do
            if not ItemESP.Enabled then
                hl.Enabled = false
                bb.Enabled = false
                task.wait(0.5)
            else
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist    = math.floor((myRoot.Position - anchor.Position).Magnitude)
                    local inRange = dist <= ItemESP.MaxDistance
                    hl.Enabled    = inRange
                    bb.Enabled    = inRange
                    if inRange then
                        lbl.Text = model.Name .. " [" .. dist .. "m]"
                    end
                end
                task.wait(0.2)
            end
        end
    end)
end

local function removeESP(model)
    local hl = model:FindFirstChild("_ItemESP")
    local bb = model:FindFirstChild("_ItemESPBB")
    if hl then hl:Destroy() end
    if bb then bb:Destroy() end
end

-- ── Scan all ───────────────────────────────────────────────
local function scanAll()
    refreshPlayerChars()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") then
            if shouldESP(desc) then
                applyESP(desc)
            else
                removeESP(desc)
            end
        end
    end
end

-- ── Public API ─────────────────────────────────────────────
function ItemESP:SetEnabled(state)
    self.Enabled = state
    scanAll()
end

function ItemESP:SetAccessories(state)
    self.Accessories = state
    scanAll()
end

function ItemESP:Init()
    buildRegistry()

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c)
            playerChars[c] = true
        end)
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p.Character then playerChars[p.Character] = nil end
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        p.CharacterAdded:Connect(function(c) playerChars[c] = true end)
        if p.Character then playerChars[p.Character] = true end
    end

    scanAll()

    Workspace.DescendantAdded:Connect(function(desc)
        if not ItemESP.Enabled then return end
        if not desc:IsA("Model") then return end
        task.wait(0.1)
        refreshPlayerChars()
        if shouldESP(desc) then applyESP(desc) end
    end)

    Workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") then removeESP(desc) end
    end)
end

function ItemESP:Destroy()
    self.Enabled = false
    scanAll()
end

return ItemESP
