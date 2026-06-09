-- =====================
-- MODULE: ItemESP
-- =====================
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

local ItemESP = {}

ItemESP.Enabled     = false
ItemESP.Accessories = true
ItemESP.MaxDistance = 500

local ESP_COLOR  = Color3.fromRGB(255, 0, 100)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local ACCESSORY_PREFIXES = { "Accessory", "Belt", "Hat", "Hair", "Vest" }

-- Characters folder (player gear is parented here)
local CharactersFolder = Workspace:WaitForChild("Characters", 5)

-- ── Helpers ────────────────────────────────────────────────
local function isAccessory(name)
    for _, prefix in ipairs(ACCESSORY_PREFIXES) do
        if string.sub(name, 1, #prefix) == prefix then return true end
    end
    return false
end

-- Check if a model is worn/held by a player (using the working logic)
local function isWornByPlayer(instance)
    -- Check A: inside the Characters folder but not the root player model
    if CharactersFolder and instance:IsDescendantOf(CharactersFolder) then
        if instance ~= LocalPlayer.Character and instance.Parent ~= CharactersFolder then
            return true
        end
    end

    -- Check B: traverse up looking for Equipment folder or Humanoid
    local currentParent = instance.Parent
    local loops = 0
    while currentParent and currentParent ~= Workspace and loops < 5 do
        if not currentParent or not currentParent.Parent then break end
        if currentParent.Name == "Equipment" or currentParent:FindFirstChildOfClass("Humanoid") then
            if currentParent ~= LocalPlayer.Character then
                return true
            end
        end
        currentParent = currentParent.Parent
        loops = loops + 1
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
    hl.FillTransparency    = 0.5
    hl.OutlineColor        = ESP_COLOR
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee             = model
    hl.Parent              = model

    local bb = Instance.new("BillboardGui")
    bb.Name          = "_ItemESPBB"
    bb.Size          = UDim2.new(0, 200, 0, 50)
    bb.AlwaysOnTop   = true
    bb.ExtentsOffset = Vector3.new(0, 1, 0)
    bb.Adornee       = anchorPart
    bb.Parent        = model

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = TEXT_COLOR
    lbl.TextSize               = 13
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
                task.wait(0.3)
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

-- ── Evaluate a model ───────────────────────────────────────
local function evaluate(instance)
    if not instance or not instance.Parent then return end
    if not instance:IsA("Model") then return end
    if not ItemESP.Enabled then return end

    local shouldShow = false

    -- Only show items worn/held by players
    if isWornByPlayer(instance) then
        if ItemESP.Accessories and isAccessory(instance.Name) then
            shouldShow = true
        end
    end

    if shouldShow then
        applyESP(instance)
    else
        removeESP(instance)
    end
end

local function scanAll()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        pcall(function() evaluate(desc) end)
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
        pcall(function() evaluate(desc) end)
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
