-- =====================
-- MODULE: ItemESP
-- =====================
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

local ItemESP = {}

ItemESP.Enabled     = false
ItemESP.Accessories = true
ItemESP.MaxDistance = 500

local ESP_COLOR  = Color3.fromRGB(255, 0, 0)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local ACCESSORY_PREFIXES = { "Accessory", "Belt", "Hat" }

-- ── Registry (built synchronously at top level) ────────────
local ItemRegistry = {}
local itemsFolder  = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")
for _, item in ipairs(itemsFolder:GetChildren()) do
    ItemRegistry[item.Name:lower()] = true
end
itemsFolder.ChildAdded:Connect(function(item)
    ItemRegistry[item.Name:lower()] = true
end)
print("ItemESP: Registry built with " .. tostring(#itemsFolder:GetChildren()) .. " items")

-- ── Helpers ────────────────────────────────────────────────
local function isAccessory(name)
    for _, prefix in ipairs(ACCESSORY_PREFIXES) do
        if string.sub(name, 1, #prefix) == prefix then return true end
    end
    return false
end

local function isOwnedByPlayer(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and model:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local function shouldESP(model)
    if not ItemESP.Enabled then return false end

    -- Accessories show on anyone including players
    if isAccessory(model.Name) then
        return ItemESP.Accessories
    end

    -- Registered items only show if on the ground (not in a player's character)
    if ItemRegistry[model.Name:lower()] then
        if isOwnedByPlayer(model) then return false end
        return true
    end

    return false
end

-- ── Apply / remove ─────────────────────────────────────────
local function applyESP(model)
    if model:FindFirstChild("_ItemESP") then return end

    local anchorPart = model.PrimaryPart
        or model:FindFirstChild("Base")
        or model:FindFirstChildWhichIsA("MeshPart")
        or model:FindFirstChildWhichIsA("BasePart")
    if not anchorPart then return end

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
    bb.Adornee       = anchorPart
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
        while model and model.Parent and anchorPart and anchorPart.Parent do
            if not ItemESP.Enabled then
                hl.Enabled = false
                bb.Enabled = false
                task.wait(0.5)
            else
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist    = math.floor((myRoot.Position - anchorPart.Position).Magnitude)
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

local function evaluate(instance)
    if not instance:IsA("Model") then return end
    if shouldESP(instance) then
        applyESP(instance)
    else
        removeESP(instance)
    end
end

local function scanAll()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        evaluate(desc)
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
    scanAll()

    Workspace.DescendantAdded:Connect(function(desc)
        if not ItemESP.Enabled then return end
        task.wait(0.1)
        evaluate(desc)
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
