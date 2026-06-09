-- =====================
-- SERVICES
-- =====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- =====================
-- AIMBOT STATE
-- =====================
local AimbotEnabled    = false
local WallCheckEnabled = true
local AimbotFOV        = 150
local AimbotSmooth     = 3
local TargetComponent  = "Head"
local TriggerInput     = Enum.UserInputType.MouseButton2
local ActiveTarget     = nil
local BulletVelocity   = 800

local OverlayCircle = Drawing.new("Circle")
OverlayCircle.Color = Color3.fromRGB(0, 255, 255)
OverlayCircle.Thickness = 1
OverlayCircle.NumSides = 64
OverlayCircle.Filled = false
OverlayCircle.Visible = false

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera
end)

local function evaluateLineOfSight(componentPart, characterModel)
    if not WallCheckEnabled then return true end
    local sourceOrigin = Camera.CFrame.Position
    local destinationPoint = componentPart.Position
    local projectionVector = destinationPoint - sourceOrigin
    local castParameters = RaycastParams.new()
    castParameters.FilterType = Enum.RaycastFilterType.Exclude
    castParameters.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    castParameters.IgnoreWater = true
    local castResult = Workspace:Raycast(sourceOrigin, projectionVector, castParameters)
    if not castResult or castResult.Instance:IsDescendantOf(characterModel) then return true end
    return false
end

local function verifyTargetValidity(playerInstance)
    if not playerInstance or not playerInstance.Character then return false end
    local character = playerInstance.Character
    local componentPart = character:FindFirstChild(TargetComponent)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if componentPart and humanoid and humanoid.Health > 0 then
        local _, withinViewport = Camera:WorldToViewportPoint(componentPart.Position)
        if withinViewport then return evaluateLineOfSight(componentPart, character) end
    end
    return false
end

local function locateProximityTarget()
    local selectedTarget = nil
    local minimumPixelDelta = AimbotFOV
    local referenceCursorLocation = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local componentPart = character and character:FindFirstChild(TargetComponent)
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if componentPart and humanoid and humanoid.Health > 0 then
                local projectedCoordinates, withinViewport = Camera:WorldToViewportPoint(componentPart.Position)
                if withinViewport then
                    local calculatedDistance = (Vector2.new(projectedCoordinates.X, projectedCoordinates.Y) - referenceCursorLocation).Magnitude
                    if calculatedDistance < minimumPixelDelta then
                        if evaluateLineOfSight(componentPart, character) then
                            minimumPixelDelta = calculatedDistance
                            selectedTarget = player
                        end
                    end
                end
            end
        end
    end
    return selectedTarget
end

RunService.RenderStepped:Connect(function()
    local frameCursorLocation = UserInputService:GetMouseLocation()
    if AimbotEnabled then
        OverlayCircle.Position = frameCursorLocation
        OverlayCircle.Radius = AimbotFOV
        OverlayCircle.Visible = true
    else
        OverlayCircle.Visible = false
    end
    if AimbotEnabled and UserInputService:IsMouseButtonPressed(TriggerInput) then
        if not verifyTargetValidity(ActiveTarget) then
            ActiveTarget = locateProximityTarget()
        end
        if ActiveTarget and ActiveTarget.Character then
            local targetComponentPart = ActiveTarget.Character:FindFirstChild(TargetComponent)
            local targetRoot = ActiveTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetComponentPart and targetRoot then
                local camPos = Camera.CFrame.Position
                local distance = (camPos - targetComponentPart.Position).Magnitude
                local travelTime = distance / BulletVelocity
                local velocity = targetRoot.AssemblyLinearVelocity
                local leadPosition = targetComponentPart.Position + (velocity * travelTime)
                local gravity = Workspace.Gravity
                local drop = 0.5 * gravity * (travelTime ^ 2)
                local compensatedPosition = leadPosition + Vector3.new(0, drop, 0)
                local projectedCoordinates, withinViewport = Camera:WorldToViewportPoint(compensatedPosition)
                if withinViewport then
                    local movementDeltaX = (projectedCoordinates.X - frameCursorLocation.X) / AimbotSmooth
                    local movementDeltaY = (projectedCoordinates.Y - frameCursorLocation.Y) / AimbotSmooth
                    if typeof(mousemoverel) == "function" then
                        mousemoverel(movementDeltaX, movementDeltaY)
                    end
                end
            end
        end
    else
        ActiveTarget = nil
    end
end)

-- =====================
-- FULLBRIGHT
-- =====================
local FullbrightEnabled = false
local OriginalLighting = {
    Brightness        = Lighting.Brightness,
    ClockTime         = Lighting.ClockTime,
    FogEnd            = Lighting.FogEnd,
    FogStart          = Lighting.FogStart,
    GlobalShadows     = Lighting.GlobalShadows,
    Ambient           = Lighting.Ambient,
    OutdoorAmbient    = Lighting.OutdoorAmbient,
}
local removedEffects = {}

local function applyFullbright()
    -- Remove post effects, sky, and atmosphere (main fog source)
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Sky") or effect:IsA("Atmosphere") then
            removedEffects[effect] = effect.Parent
            effect.Parent = nil
        end
    end
    Lighting.Brightness     = 2
    Lighting.ClockTime      = 14        -- midday sun
    Lighting.FogEnd         = 100000    -- push fog to essentially infinity
    Lighting.FogStart       = 100000
    Lighting.GlobalShadows  = false
    Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
end

local function removeFullbright()
    for effect, parent in pairs(removedEffects) do
        pcall(function() effect.Parent = parent end)
    end
    removedEffects = {}
    Lighting.Brightness     = OriginalLighting.Brightness
    Lighting.ClockTime      = OriginalLighting.ClockTime
    Lighting.FogEnd         = OriginalLighting.FogEnd
    Lighting.FogStart       = OriginalLighting.FogStart
    Lighting.GlobalShadows  = OriginalLighting.GlobalShadows
    Lighting.Ambient        = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
end

-- =====================
-- NO TEXTURES
-- =====================
local NoTextureEnabled = false
local removedTextures  = {}

local function applyNoTextures()
    removedTextures = {}
    -- Strip all Decals, Textures, SpecialMeshes from every BasePart in workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            table.insert(removedTextures, {obj = obj, parent = obj.Parent})
            obj.Parent = nil
        end
    end
    -- Also flatten materials on every BasePart to SmoothPlastic
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
            -- store original material alongside so we can restore it
            table.insert(removedTextures, {obj = obj, origMat = obj.Material})
            obj.Material = Enum.Material.SmoothPlastic
        end
    end
end

local function removeNoTextures()
    for _, entry in ipairs(removedTextures) do
        pcall(function()
            if entry.origMat then
                -- restore material
                entry.obj.Material = entry.origMat
            else
                -- restore parented decal/texture
                entry.obj.Parent = entry.parent
            end
        end)
    end
    removedTextures = {}
end

-- =====================
-- ESP STATE
-- =====================
local ESPEnabled       = false
local ChamsEnabled     = false
local HealthBarEnabled = false
local SkeletonEnabled  = false

local ESP_COLOR         = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR     = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.5
local MAX_CHAMS         = 30
local ENGINE_CHAM_LIMIT = 1000
local TEXT_PIXEL_OFFSET = 25

local ActiveESP = {}

local SKELETON_BONES = {
    {"Head","UpperTorso"}, {"Head","Torso"},
    {"UpperTorso","LowerTorso"}, {"LowerTorso","HumanoidRootPart"}, {"Torso","HumanoidRootPart"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"Torso","Right Arm"}, {"Torso","Left Arm"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"HumanoidRootPart","Right Leg"}, {"HumanoidRootPart","Left Leg"},
}

local function removeESP(player)
    if not ActiveESP[player] then return end
    local d = ActiveESP[player]
    d.Text.Visible = false; d.Text:Remove()
    d.Box.Visible = false;  d.Box:Remove()
    d.HealthBg.Visible = false;   d.HealthBg:Remove()
    d.HealthFill.Visible = false; d.HealthFill:Remove()
    d.WeaponText.Visible = false; d.WeaponText:Remove()
    if d.Cham then d.Cham:Destroy() end
    for _, line in ipairs(d.Bones) do line.Visible = false; line:Remove() end
    ActiveESP[player] = nil
end

local function createESP(player)
    if ActiveESP[player] or player == LocalPlayer then return end
    local text = Drawing.new("Text")
    text.Color = Color3.fromRGB(255,255,255); text.Size = 14
    text.Center = true; text.Outline = true; text.Visible = false

    local box = Drawing.new("Square")
    box.Color = ESP_COLOR; box.Thickness = 1.5
    box.Filled = false; box.Visible = false

    local healthBg = Drawing.new("Square")
    healthBg.Color = Color3.fromRGB(0,0,0); healthBg.Thickness = 1
    healthBg.Filled = true; healthBg.Visible = false

    local healthFill = Drawing.new("Square")
    healthFill.Color = Color3.fromRGB(0,255,80); healthFill.Thickness = 1
    healthFill.Filled = true; healthFill.Visible = false

    local weaponText = Drawing.new("Text")
    weaponText.Color = Color3.fromRGB(255,200,0)
    weaponText.Size = 12; weaponText.Center = true
    weaponText.Outline = true; weaponText.Visible = false

    ActiveESP[player] = { Text=text, Box=box, HealthBg=healthBg, HealthFill=healthFill, Cham=nil, Bones={}, WeaponText=weaponText }
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function ensureBones(data, count)
    while #data.Bones < count do
        local line = Drawing.new("Line")
        line.Color = Color3.fromRGB(0,255,255)
        line.Thickness = 1; line.Visible = false
        table.insert(data.Bones, line)
    end
end

RunService:BindToRenderStep("ESPRenderPipeline", Enum.RenderPriority.Camera.Value + 1, function()
    local currentCamera = Workspace.CurrentCamera
    if not currentCamera then return end
    local sortedPlayers = {}

    for player, data in pairs(ActiveESP) do
        local character = player.Character
        local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
        local head      = character and character:FindFirstChild("Head")
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

        if ESPEnabled and rootPart and head and humanoid and humanoid.Health > 0 then
            local cameraPos = currentCamera.CFrame.Position
            local distance  = (cameraPos - rootPart.Position).Magnitude
            local _, onScreen = currentCamera:WorldToViewportPoint(rootPart.Position)

            if onScreen and distance > 0.1 then
                table.insert(sortedPlayers, {Player=player, Data=data, Distance=distance, Character=character, Humanoid=humanoid})

                -- Name + distance tag
                local headScreenPos, headOnScreen = currentCamera:WorldToViewportPoint(head.Position)
                if headOnScreen then
                    data.Text.Position = Vector2.new(headScreenPos.X, headScreenPos.Y - TEXT_PIXEL_OFFSET)
                    data.Text.Text = string.format("%s [%d]", player.Name, math.floor(distance))
                    data.Text.Visible = true
                else
                    data.Text.Visible = false
                end

                -- Weapon ESP
                local equippedTool = character:FindFirstChildOfClass("Tool")
                if equippedTool and headOnScreen then
                    data.WeaponText.Position = Vector2.new(headScreenPos.X, headScreenPos.Y - TEXT_PIXEL_OFFSET + 16)
                    data.WeaponText.Text = "[W] " .. equippedTool.Name
                    data.WeaponText.Visible = true
                else
                    data.WeaponText.Visible = false
                end

                -- Box: project true top (head top) and bottom (feet) from world space
                local topWorld    = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
                local bottomWorld = rootPart.Position - Vector3.new(0, 3, 0)
                local leftFoot    = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
                local rightFoot   = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
                if leftFoot and rightFoot then
                    bottomWorld = Vector3.new(
                        rootPart.Position.X,
                        math.min(leftFoot.Position.Y, rightFoot.Position.Y) - 1,
                        rootPart.Position.Z
                    )
                end

                local topScreen,    topOnScreen    = currentCamera:WorldToViewportPoint(topWorld)
                local bottomScreen, bottomOnScreen = currentCamera:WorldToViewportPoint(bottomWorld)

                if topOnScreen and bottomOnScreen then
                    local heightPx = math.abs(bottomScreen.Y - topScreen.Y)
                    local widthPx  = heightPx * 0.45
                    data.Box.Size     = Vector2.new(widthPx, heightPx)
                    data.Box.Position = Vector2.new(topScreen.X - widthPx / 2, topScreen.Y)
                    data.Box.Visible  = true
                else
                    data.Box.Visible = false
                end

                -- Health bar (anchored to box)
                if HealthBarEnabled and humanoid.MaxHealth > 0 and data.Box.Visible then
                    local hpRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local bx = data.Box.Position.X
                    local by = data.Box.Position.Y
                    local bh = data.Box.Size.Y
                    local barX = bx - 6
                    data.HealthBg.Position = Vector2.new(barX - 1, by - 1)
                    data.HealthBg.Size = Vector2.new(5, bh + 2)
                    data.HealthBg.Visible = true
                    local fillH = bh * hpRatio
                    data.HealthFill.Position = Vector2.new(barX, by + (bh - fillH))
                    data.HealthFill.Size = Vector2.new(3, fillH)
                    data.HealthFill.Color = Color3.fromRGB(math.floor(255*(1-hpRatio)), math.floor(255*hpRatio), 0)
                    data.HealthFill.Visible = true
                else
                    data.HealthBg.Visible = false; data.HealthFill.Visible = false
                end

                -- Skeleton
                if SkeletonEnabled then
                    local validBones = {}
                    for _, pair in ipairs(SKELETON_BONES) do
                        local partA = character:FindFirstChild(pair[1])
                        local partB = character:FindFirstChild(pair[2])
                        if partA and partB then
                            local screenA, onA = currentCamera:WorldToViewportPoint(partA.Position)
                            local screenB, onB = currentCamera:WorldToViewportPoint(partB.Position)
                            if onA and onB then
                                table.insert(validBones, {Vector2.new(screenA.X, screenA.Y), Vector2.new(screenB.X, screenB.Y)})
                            end
                        end
                    end
                    ensureBones(data, #validBones)
                    for i, pts in ipairs(validBones) do
                        data.Bones[i].From = pts[1]; data.Bones[i].To = pts[2]; data.Bones[i].Visible = true
                    end
                    for i = #validBones + 1, #data.Bones do data.Bones[i].Visible = false end
                else
                    for _, line in ipairs(data.Bones) do line.Visible = false end
                end

            else
                data.Text.Visible = false; data.Box.Visible = false
                data.HealthBg.Visible = false; data.HealthFill.Visible = false
                data.WeaponText.Visible = false
                for _, line in ipairs(data.Bones) do line.Visible = false end
                if data.Cham then data.Cham:Destroy(); data.Cham = nil end
            end
        else
            data.Text.Visible = false; data.Box.Visible = false
            data.HealthBg.Visible = false; data.HealthFill.Visible = false
            data.WeaponText.Visible = false
            for _, line in ipairs(data.Bones) do line.Visible = false end
            if data.Cham then data.Cham:Destroy(); data.Cham = nil end
        end
    end

    table.sort(sortedPlayers, function(a, b) return a.Distance < b.Distance end)

    for index, item in ipairs(sortedPlayers) do
        if ChamsEnabled and ESPEnabled and index <= MAX_CHAMS and item.Distance <= ENGINE_CHAM_LIMIT then
            if not item.Data.Cham or item.Data.Cham.Parent ~= item.Character then
                if item.Data.Cham then item.Data.Cham:Destroy() end
                local highlight = Instance.new("Highlight")
                highlight.FillColor = ESP_COLOR; highlight.OutlineColor = OUTLINE_COLOR
                highlight.FillTransparency = FILL_TRANSPARENCY; highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = item.Character; highlight.Parent = item.Character
                item.Data.Cham = highlight
            end
        else
            if item.Data.Cham then item.Data.Cham:Destroy(); item.Data.Cham = nil end
        end
    end
end)

-- =====================
-- SCREEN GUI
-- =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScreenGui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.225, 0, 0.23, 0)
MainFrame.Size = UDim2.new(0, 675, 0, 486)
MainFrame.Parent = ScreenGui
Instance.new("UICorner").Parent = MainFrame

local TextLabel = Instance.new("TextLabel")
TextLabel.BackgroundTransparency = 1; TextLabel.BorderSizePixel = 0
TextLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
TextLabel.Size = UDim2.new(0, 200, 0, 50)
TextLabel.Text = "ChrisM Hub: Universal"; TextLabel.TextColor3 = Color3.new(1,1,1)
TextLabel.TextSize = 18; TextLabel.Parent = MainFrame

local TextLabel_1 = Instance.new("TextLabel")
TextLabel_1.BackgroundTransparency = 1; TextLabel_1.BorderSizePixel = 0
TextLabel_1.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
TextLabel_1.Position = UDim2.new(0.219, 0, -0.006, 0)
TextLabel_1.Size = UDim2.new(0, 193, 0, 56)
TextLabel_1.Text = "by LLOCD_1234 and BinkBink"
TextLabel_1.TextColor3 = Color3.new(0.58, 0.58, 0.58)
TextLabel_1.TextSize = 14; TextLabel_1.Parent = MainFrame

local Indicator = Instance.new("Frame")
Indicator.Name = "Indicator"
Indicator.BackgroundColor3 = Color3.new(0, 0.835, 1)
Indicator.BorderSizePixel = 0
Indicator.Position = UDim2.new(-0.412, 0, -0.426, 0)
Indicator.Size = UDim2.new(0, 4, 0, 20)
Indicator.Parent = MainFrame

local MinBtn = Instance.new("ImageButton")
MinBtn.Name = "MinBtn"; MinBtn.BackgroundTransparency = 1; MinBtn.BorderSizePixel = 0
MinBtn.Image = "rbxassetid://82235228007110"
MinBtn.Position = UDim2.new(0.92, 0, 0.002, 0)
MinBtn.Size = UDim2.new(0, 22, 0, 22); MinBtn.Parent = MainFrame

local CloseBtn = Instance.new("ImageButton")
CloseBtn.Name = "CloseBtn"; CloseBtn.BackgroundTransparency = 1; CloseBtn.BorderSizePixel = 0
CloseBtn.Image = "rbxassetid://109757326745560"
CloseBtn.Position = UDim2.new(0.966, 0, 0.014, 0)
CloseBtn.Size = UDim2.new(0, 11, 0, 11); CloseBtn.Parent = MainFrame

local Folder = Instance.new("Folder")
Folder.Parent = MainFrame

-- =========================================================
-- HELPER: pill toggle
-- =========================================================
local PILL_W, PILL_H = 36, 18
local KNOB_SIZE = 14
local KNOB_PAD  = 2

local function makePill(parent, defaultState)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, PILL_W, 0, PILL_H)
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -12, 0.5, 0)
    pill.BackgroundColor3 = defaultState and Color3.fromRGB(0,200,80) or Color3.fromRGB(76,76,76)
    pill.BorderSizePixel = 0
    pill.ClipsDescendants = true
    pill.Parent = parent
    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = defaultState
        and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
        or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0; knob.ZIndex = 2; knob.Parent = pill
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    return pill, knob
end

local function animatePill(pill, knob, state)
    TweenService:Create(pill, TweenInfo.new(0.15), {
        BackgroundColor3 = state and Color3.fromRGB(0,200,80) or Color3.fromRGB(76,76,76)
    }):Play()
    TweenService:Create(knob, TweenInfo.new(0.15), {
        Position = state
            and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
            or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    }):Play()
end

-- =========================================================
-- HELPER: section label
-- =========================================================
local function makeSectionLabel(parent, yOffset, labelText)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0.06, 0, 0, yOffset)
    lbl.Size = UDim2.new(0, 420, 0, 20)
    lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(0, 213, 255)
    lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    lbl.Parent = parent
end

-- =========================================================
-- HELPER: toggle row
-- =========================================================
local function makeToggleRow(parent, yOffset, labelText, defaultState, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 0, 0, yOffset)
    row.Size = UDim2.new(0, 420, 0, 36)
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0.02, 0, 0, 0)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local pill, knob = makePill(row, defaultState)
    local state = defaultState

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            animatePill(pill, knob, state)
            if onToggle then onToggle(state) end
        end
    end)
end

-- =========================================================
-- HELPER: sub-toggle row
-- =========================================================
local function makeSubToggleRow(parent, yOffset, labelText, defaultState, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.13, 0.13, 0.13)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 22, 0, yOffset)
    row.Size = UDim2.new(0, 398, 0, 32)
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.new(0, 0.835, 1)
    bar.BorderSizePixel = 0
    bar.Position = UDim2.new(0, 0, 0.15, 0)
    bar.Size = UDim2.new(0, 2, 0.7, 0)
    bar.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local pill, knob = makePill(row, defaultState)
    local state = defaultState

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            animatePill(pill, knob, state)
            if onToggle then onToggle(state) end
        end
    end)

    return row
end

-- =========================================================
-- HELPER: sub-slider row (indented, slightly smaller height)
-- =========================================================
local function makeSubSliderRow(parent, yOffset, labelText, minVal, maxVal, defaultVal, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.13, 0.13, 0.13)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 22, 0, yOffset)
    row.Size = UDim2.new(0, 398, 0, 46)
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.new(0, 0.835, 1)
    bar.BorderSizePixel = 0
    bar.Position = UDim2.new(0, 0, 0.15, 0)
    bar.Size = UDim2.new(0, 2, 0.7, 0)
    bar.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.55, 0, 0.48, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1; valLbl.BorderSizePixel = 0
    valLbl.Position = UDim2.new(0.68, 0, 0, 0); valLbl.Size = UDim2.new(0.3, 0, 0.48, 0)
    valLbl.Text = tostring(defaultVal); valLbl.TextColor3 = Color3.new(0,0.835,1)
    valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    valLbl.Parent = row

    local trackBg = Instance.new("Frame")
    trackBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2); trackBg.BorderSizePixel = 0
    trackBg.Position = UDim2.new(0, 10, 0.68, 0); trackBg.Size = UDim2.new(1, -20, 0, 4)
    trackBg.Parent = row; Instance.new("UICorner").Parent = trackBg

    local trackFill = Instance.new("Frame")
    trackFill.BackgroundColor3 = Color3.new(0,0.835,1); trackFill.BorderSizePixel = 0
    trackFill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 1, 0)
    trackFill.Parent = trackBg; Instance.new("UICorner").Parent = trackFill

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 0.5, 0)
    knob.ZIndex = 2; knob.Parent = trackBg; Instance.new("UICorner").Parent = knob

    local currentValue = defaultVal
    local dragging = false

    local function updateSlider(inputX)
        local pct = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(minVal + pct*(maxVal-minVal))
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(currentValue)
        if onChange then onChange(currentValue) end
    end

    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateSlider(input.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return { Row = row, getValue = function() return currentValue end }
end

-- =========================================================
-- HELPER: sub-dropdown row (indented)
-- =========================================================
local function makeSubDropdownRow(parent, yOffset, labelText, options, defaultIndex, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.13, 0.13, 0.13)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 22, 0, yOffset)
    row.Size = UDim2.new(0, 398, 0, 32)
    row.ClipsDescendants = false
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.new(0, 0.835, 1)
    bar.BorderSizePixel = 0
    bar.Position = UDim2.new(0, 0, 0.15, 0)
    bar.Size = UDim2.new(0, 2, 0.7, 0)
    bar.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local selected = defaultIndex or 1
    local open = false

    local selBtn = Instance.new("TextButton")
    selBtn.AnchorPoint = Vector2.new(1, 0.5)
    selBtn.Position = UDim2.new(1, -8, 0.5, 0)
    selBtn.Size = UDim2.new(0, 130, 0, 22)
    selBtn.BackgroundColor3 = Color3.new(0.22, 0.22, 0.22)
    selBtn.BorderSizePixel = 0
    selBtn.Text = options[selected] .. "  ▾"
    selBtn.TextColor3 = Color3.new(0, 0.835, 1)
    selBtn.TextSize = 11
    selBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    selBtn.ZIndex = 5; selBtn.Parent = row
    Instance.new("UICorner").Parent = selBtn

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    listFrame.BorderSizePixel = 0
    listFrame.Position = UDim2.new(1, -138, 1, 4)
    listFrame.Size = UDim2.new(0, 130, 0, #options * 26)
    listFrame.Visible = false; listFrame.ZIndex = 10
    listFrame.Parent = row
    Instance.new("UICorner").Parent = listFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.BackgroundTransparency = 1; optBtn.BorderSizePixel = 0
        optBtn.Position = UDim2.new(0, 0, 0, (i-1)*26)
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.Text = opt; optBtn.TextColor3 = Color3.new(0.85, 0.85, 0.85)
        optBtn.TextSize = 11; optBtn.ZIndex = 11
        optBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        optBtn.Parent = listFrame
        optBtn.MouseButton1Click:Connect(function()
            selected = i; selBtn.Text = options[i] .. "  ▾"
            listFrame.Visible = false; open = false
            if onChange then onChange(options[i]) end
        end)
        optBtn.MouseEnter:Connect(function() optBtn.TextColor3 = Color3.new(0,0.835,1) end)
        optBtn.MouseLeave:Connect(function() optBtn.TextColor3 = Color3.new(0.85,0.85,0.85) end)
    end

    selBtn.MouseButton1Click:Connect(function() open = not open; listFrame.Visible = open end)

    return row
end

-- =========================================================
-- HELPER: dropdown (full width, kept for any future use)
-- =========================================================
local function makeDropdownRow(parent, yOffset, labelText, options, defaultIndex, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 0, 0, yOffset)
    row.Size = UDim2.new(0, 420, 0, 36)
    row.ClipsDescendants = false
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0.02, 0, 0, 0)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local selected = defaultIndex or 1
    local open = false

    local selBtn = Instance.new("TextButton")
    selBtn.AnchorPoint = Vector2.new(1, 0.5)
    selBtn.Position = UDim2.new(1, -8, 0.5, 0)
    selBtn.Size = UDim2.new(0, 140, 0, 24)
    selBtn.BackgroundColor3 = Color3.new(0.22, 0.22, 0.22)
    selBtn.BorderSizePixel = 0
    selBtn.Text = options[selected] .. "  ▾"
    selBtn.TextColor3 = Color3.new(0, 0.835, 1)
    selBtn.TextSize = 12
    selBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    selBtn.ZIndex = 5; selBtn.Parent = row
    Instance.new("UICorner").Parent = selBtn

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    listFrame.BorderSizePixel = 0
    listFrame.Position = UDim2.new(1, -148, 1, 4)
    listFrame.Size = UDim2.new(0, 140, 0, #options * 26)
    listFrame.Visible = false; listFrame.ZIndex = 10
    listFrame.Parent = row
    Instance.new("UICorner").Parent = listFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.BackgroundTransparency = 1; optBtn.BorderSizePixel = 0
        optBtn.Position = UDim2.new(0, 0, 0, (i-1)*26)
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.Text = opt; optBtn.TextColor3 = Color3.new(0.85, 0.85, 0.85)
        optBtn.TextSize = 12; optBtn.ZIndex = 11
        optBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        optBtn.Parent = listFrame
        optBtn.MouseButton1Click:Connect(function()
            selected = i; selBtn.Text = options[i] .. "  ▾"
            listFrame.Visible = false; open = false
            if onChange then onChange(options[i]) end
        end)
        optBtn.MouseEnter:Connect(function() optBtn.TextColor3 = Color3.new(0,0.835,1) end)
        optBtn.MouseLeave:Connect(function() optBtn.TextColor3 = Color3.new(0.85,0.85,0.85) end)
    end

    selBtn.MouseButton1Click:Connect(function() open = not open; listFrame.Visible = open end)
end

-- =========================================================
-- HELPER: input row
-- =========================================================
local function makeInputRow(parent, yOffset, labelText, placeholderText)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 0, 0, yOffset)
    row.Size = UDim2.new(0, 420, 0, 40)
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0.02, 0, 0, 0)
    lbl.Size = UDim2.new(0.38, 0, 1, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = Color3.new(0.22, 0.22, 0.22); box.BorderSizePixel = 0
    box.Position = UDim2.new(0.4, 0, 0.15, 0)
    box.Size = UDim2.new(0.58, 0, 0.7, 0)
    box.Text = ""; box.PlaceholderText = placeholderText
    box.PlaceholderColor3 = Color3.new(0.45, 0.45, 0.45)
    box.TextColor3 = Color3.new(0, 0.835, 1); box.TextSize = 12
    box.ClearTextOnFocus = false
    box.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    box.Parent = row
    Instance.new("UICorner").Parent = box

    return { Row = row, getValue = function() return box.Text end }
end

-- =========================================================
-- HELPER: slider row
-- =========================================================
local function makeSliderRow(parent, yOffset, labelText, minVal, maxVal, defaultVal, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0.06, 0, 0, yOffset)
    row.Size = UDim2.new(0, 420, 0, 50)
    row.Parent = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.new(0.02, 0, 0, 0); lbl.Size = UDim2.new(0.6, 0, 0.5, 0)
    lbl.Text = labelText; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1; valLbl.BorderSizePixel = 0
    valLbl.Position = UDim2.new(0.7, 0, 0, 0); valLbl.Size = UDim2.new(0.28, 0, 0.5, 0)
    valLbl.Text = tostring(defaultVal); valLbl.TextColor3 = Color3.new(0,0.835,1)
    valLbl.TextSize = 13; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    valLbl.Parent = row

    local trackBg = Instance.new("Frame")
    trackBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2); trackBg.BorderSizePixel = 0
    trackBg.Position = UDim2.new(0.02, 0, 0.62, 0); trackBg.Size = UDim2.new(0.96, 0, 0, 4)
    trackBg.Parent = row; Instance.new("UICorner").Parent = trackBg

    local trackFill = Instance.new("Frame")
    trackFill.BackgroundColor3 = Color3.new(0,0.835,1); trackFill.BorderSizePixel = 0
    trackFill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 1, 0)
    trackFill.Parent = trackBg; Instance.new("UICorner").Parent = trackFill

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 0.5, 0)
    knob.ZIndex = 2; knob.Parent = trackBg; Instance.new("UICorner").Parent = knob

    local currentValue = defaultVal
    local dragging = false

    local function updateSlider(inputX)
        local pct = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(minVal + pct*(maxVal-minVal))
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(currentValue)
        if onChange then onChange(currentValue) end
    end

    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateSlider(input.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return { Row = row, getValue = function() return currentValue end }
end

-- =========================================================
-- HELPER: action button
-- =========================================================
local function makeActionBtn(parent, yOffset, labelText)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.new(0,0.835,1); btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.06, 0, 0, yOffset)
    btn.Size = UDim2.new(0, 420, 0, 36)
    btn.Text = labelText; btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    btn.Parent = parent; Instance.new("UICorner").Parent = btn
    return btn
end

-- =====================================================
-- VISUALS PAGE
-- Layout:
--   10   title
--   38   section label "— ESP"
--   60   ESP toggle (master)
--   104  ↳ Chams
--   144  ↳ Health Bars
--   184  ↳ Skeleton ESP
--   228  section label "— Misc"
--   250  Fullbright toggle
-- =====================================================
local VisualsPage = Instance.new("Frame")
VisualsPage.Name = "VisualsPage"
VisualsPage.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
VisualsPage.BorderSizePixel = 0
VisualsPage.Position = UDim2.new(0.31, 0, 0.126, 0)
VisualsPage.Size = UDim2.new(0, 466, 0, 425)
VisualsPage.Parent = Folder
Instance.new("UICorner").Parent = VisualsPage

local VTitle = Instance.new("TextLabel")
VTitle.BackgroundTransparency = 1; VTitle.BorderSizePixel = 0
VTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
VTitle.Position = UDim2.new(0, 25, 0, 10)
VTitle.Size = UDim2.new(0.88, 0, 0, 22)
VTitle.Text = "Visuals"; VTitle.TextColor3 = Color3.new(1,1,1)
VTitle.TextSize = 20; VTitle.TextXAlignment = Enum.TextXAlignment.Left
VTitle.Parent = VisualsPage

-- ESP section
makeSectionLabel(VisualsPage, 38, "— ESP")
makeToggleRow(VisualsPage, 60, "ESP  (Names + Boxes)", false, function(state)
    ESPEnabled = state
    for _, child in ipairs(VisualsPage:GetChildren()) do
        if child:GetAttribute("ESPSub") then child.Visible = state end
    end
    if not state then
        ChamsEnabled = false; HealthBarEnabled = false; SkeletonEnabled = false
        for _, data in pairs(ActiveESP) do
            if data.Cham then data.Cham:Destroy(); data.Cham = nil end
            for _, line in ipairs(data.Bones) do line.Visible = false end
        end
    end
end)

local subChams    = makeSubToggleRow(VisualsPage, 104, "Chams",        false, function(state)
    ChamsEnabled = state
    if not state then for _, d in pairs(ActiveESP) do if d.Cham then d.Cham:Destroy(); d.Cham = nil end end end
end)
local subHealth   = makeSubToggleRow(VisualsPage, 144, "Health Bars",  false, function(state) HealthBarEnabled = state end)
local subSkeleton = makeSubToggleRow(VisualsPage, 184, "Skeleton ESP", false, function(state)
    SkeletonEnabled = state
    if not state then for _, d in pairs(ActiveESP) do for _, l in ipairs(d.Bones) do l.Visible = false end end end
end)

subChams:SetAttribute("ESPSub", true);    subChams.Visible    = false
subHealth:SetAttribute("ESPSub", true);   subHealth.Visible   = false
subSkeleton:SetAttribute("ESPSub", true); subSkeleton.Visible = false

-- Misc section
makeSectionLabel(VisualsPage, 228, "— Misc")
makeToggleRow(VisualsPage, 250, "Fullbright", false, function(state)
    FullbrightEnabled = state
    if state then applyFullbright() else removeFullbright() end
end)
makeToggleRow(VisualsPage, 296, "No Textures", false, function(state)
    NoTextureEnabled = state
    if state then applyNoTextures() else removeNoTextures() end
end)

-- =====================================================
-- COMBAT PAGE
-- Layout:
--   10   title
--   38   section label "— Aimbot"
--   60   Aimbot toggle (master)
--   100  ↳ Check Walls
--   140  ↳ FOV Radius slider
--   194  ↳ Smoothness slider
--   248  ↳ Target Bone dropdown
--   288  ↳ Bullet Velocity slider
-- =====================================================
local CombatPage = Instance.new("Frame")
CombatPage.Name = "CombatPage"
CombatPage.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
CombatPage.BorderSizePixel = 0
CombatPage.Position = UDim2.new(0.31, 0, 0.126, 0)
CombatPage.Size = UDim2.new(0, 466, 0, 425)
CombatPage.Visible = false
CombatPage.Parent = Folder
Instance.new("UICorner").Parent = CombatPage

local CTitle = Instance.new("TextLabel")
CTitle.BackgroundTransparency = 1; CTitle.BorderSizePixel = 0
CTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
CTitle.Position = UDim2.new(0, 25, 0, 10)
CTitle.Size = UDim2.new(0.88, 0, 0, 22)
CTitle.Text = "Combat"; CTitle.TextColor3 = Color3.new(1,1,1)
CTitle.TextSize = 20; CTitle.TextXAlignment = Enum.TextXAlignment.Left
CTitle.Parent = CombatPage

makeSectionLabel(CombatPage, 38, "— Aimbot")

-- Aimbot master toggle
makeToggleRow(CombatPage, 60, "Aimbot", false, function(state)
    AimbotEnabled = state
    -- show/hide sub-rows
    for _, child in ipairs(CombatPage:GetChildren()) do
        if child:GetAttribute("AimbotSub") then child.Visible = state end
    end
    if not state then ActiveTarget = nil; OverlayCircle.Visible = false end
end)

-- Aimbot sub-rows (hidden until aimbot is toggled on)
local subWalls = makeSubToggleRow(CombatPage, 104, "Check Walls", true, function(state) WallCheckEnabled = state end)

local subFOV = makeSubSliderRow(CombatPage, 144, "FOV Radius (px)", 50, 400, 150, function(val)
    AimbotFOV = val; OverlayCircle.Radius = val
end)

local subSmooth = makeSubSliderRow(CombatPage, 198, "Smoothness", 1, 20, 3, function(val)
    AimbotSmooth = val
end)

local subBone = makeSubDropdownRow(CombatPage, 252, "Target Bone", {
    "Head","HumanoidRootPart","UpperTorso","Torso","RightUpperArm","LeftUpperArm"
}, 1, function(val) TargetComponent = val; ActiveTarget = nil end)

local subVelocity = makeSubSliderRow(CombatPage, 292, "Bullet Velocity (studs/s)", 1, 4625, 800, function(val)
    BulletVelocity = val
end)

-- Tag all sub-rows so the master toggle can show/hide them
subWalls:SetAttribute("AimbotSub", true);    subWalls.Visible    = false
subFOV.Row:SetAttribute("AimbotSub", true);  subFOV.Row.Visible  = false
subSmooth.Row:SetAttribute("AimbotSub", true); subSmooth.Row.Visible = false
subBone:SetAttribute("AimbotSub", true);     subBone.Visible     = false
subVelocity.Row:SetAttribute("AimbotSub", true); subVelocity.Row.Visible = false

-- =====================================================
-- MOVEMENT PAGE
-- =====================================================
local MovementPage = Instance.new("Frame")
MovementPage.Name = "MovementPage"
MovementPage.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
MovementPage.BorderSizePixel = 0
MovementPage.Position = UDim2.new(0.31, 0, 0.126, 0)
MovementPage.Size = UDim2.new(0, 466, 0, 425)
MovementPage.Visible = false
MovementPage.Parent = Folder
Instance.new("UICorner").Parent = MovementPage

local MTitle = Instance.new("TextLabel")
MTitle.BackgroundTransparency = 1; MTitle.BorderSizePixel = 0
MTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
MTitle.Position = UDim2.new(0, 25, 0, 10)
MTitle.Size = UDim2.new(0.88, 0, 0, 32)
MTitle.Text = "Teleport"; MTitle.TextColor3 = Color3.new(1,1,1)
MTitle.TextSize = 20; MTitle.TextXAlignment = Enum.TextXAlignment.Left
MTitle.Parent = MovementPage

local usernameInput = makeInputRow(MovementPage, 50,  "Target Username", "Enter username...")
local offsetSlider  = makeSliderRow(MovementPage, 100, "Behind Offset (studs)", 1, 30, 15, nil)

local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1; statusLbl.BorderSizePixel = 0
statusLbl.Position = UDim2.new(0.06, 0, 0, 162)
statusLbl.Size = UDim2.new(0.88, 0, 0, 22)
statusLbl.Text = "Status: Idle"; statusLbl.TextColor3 = Color3.new(0.5,0.5,0.5)
statusLbl.TextSize = 12; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
statusLbl.Parent = MovementPage

local instantTPBtn = makeActionBtn(MovementPage, 192, "⚡ One-Time Teleport")
local startTPBtn   = makeActionBtn(MovementPage, 238, "🔄 Start Loop Tracking")
startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
local stopTPBtn    = makeActionBtn(MovementPage, 284, "Stop")
stopTPBtn.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
stopTPBtn.TextColor3 = Color3.new(0.6, 0.6, 0.6)

-- =====================================================
-- SIDEBAR BUTTONS
-- =====================================================
local function makeSideBtn(name, yScale, text, iconId)
    local btn = Instance.new("TextButton")
    btn.Name = name; btn.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    btn.BorderSizePixel = 0
    btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    btn.Position = UDim2.new(0.022, 0, yScale, 0)
    btn.Size = UDim2.new(0, 194, 0, 40)
    btn.Text = text; btn.TextColor3 = Color3.new(0.62, 0.62, 0.62)
    btn.TextSize = 15; btn.Parent = MainFrame
    Instance.new("UICorner").Parent = btn
    if iconId then
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1; icon.BorderSizePixel = 0
        icon.Image = "rbxassetid://" .. iconId
        icon.ImageColor3 = Color3.new(0.58, 0.58, 0.58)
        icon.Position = UDim2.new(0.07, 0, 0.115, 0)
        icon.Size = UDim2.new(0, 28, 0, 28)
        icon.Parent = btn
    end
    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0.2, 0); pad.Parent = btn
    return btn
end

local Visuals  = makeSideBtn("Visuals",  0.126, "Visuals",  "6523858394")
local Combat   = makeSideBtn("Combat",   0.233, "Combat",   "13050670424")
local Movement = makeSideBtn("Movement", 0.34,  "Movement", "16181398272")

-- =====================================================
-- DISPLAY
-- =====================================================
ScreenGui.Parent = PlayerGui

-- =====================================================
-- DRAGGABLE
-- =====================================================
do
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =====================================================
-- WINDOW CONTROLS
-- =====================================================
do
    CloseBtn.MouseButton1Click:Connect(function()
        AimbotEnabled = false; ESPEnabled = false
        if FullbrightEnabled then removeFullbright() end
        if NoTextureEnabled then removeNoTextures() end
        OverlayCircle.Visible = false; OverlayCircle:Remove()
        for player, _ in pairs(ActiveESP) do removeESP(player) end
        RunService:UnbindFromRenderStep("ESPRenderPipeline")
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.15), {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1})
        t:Play(); t.Completed:Connect(function() ScreenGui:Destroy() end)
    end)
    MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.K then MainFrame.Visible = not MainFrame.Visible end
    end)
end

-- =====================================================
-- TAB SWITCHER
-- =====================================================
do
    local TWEEN = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local buttons = {Visuals, Combat, Movement}
    local pages = {["Visuals"]=VisualsPage, ["Combat"]=CombatPage, ["Movement"]=MovementPage}

    local function switchTo(selectedBtn)
        TweenService:Create(Indicator, TWEEN, {
            Position = UDim2.new(selectedBtn.Position.X.Scale, selectedBtn.Position.X.Offset - 6,
                selectedBtn.Position.Y.Scale, selectedBtn.Position.Y.Offset + selectedBtn.Size.Y.Offset/4),
            Size = UDim2.new(0, 4, 0, selectedBtn.Size.Y.Offset/2)
        }):Play()
        for _, btn in ipairs(buttons) do
            local sel = (btn == selectedBtn)
            TweenService:Create(btn, TWEEN, {BackgroundTransparency=sel and 0.88 or 1, TextTransparency=sel and 0 or 0.4}):Play()
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then TweenService:Create(icon, TWEEN, {ImageTransparency=sel and 0 or 0.4}):Play() end
        end
        for name, page in pairs(pages) do page.Visible = (name == selectedBtn.Name) end
    end

    for _, btn in ipairs(buttons) do btn.MouseButton1Click:Connect(function() switchTo(btn) end) end
    switchTo(Visuals)
end

-- =====================================================
-- TELEPORT LOGIC
-- =====================================================
do
    local isTracking = false
    local trackingConnection = nil

    local function setStatus(msg, color)
        statusLbl.Text = "Status: " .. msg
        statusLbl.TextColor3 = color or Color3.new(0.5, 0.5, 0.5)
    end

    local function getTargetPlayer()
        local targetName = string.lower(usernameInput.getValue())
        if targetName == "" then return nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if string.sub(string.lower(p.Name), 1, #targetName) == targetName
                or string.sub(string.lower(p.DisplayName), 1, #targetName) == targetName then
                    return p
                end
            end
        end
        return nil
    end

    local function calculateSafeCFrame(targetRoot, targetChar, myChar)
        local targetCFrame = targetRoot.CFrame
        local offset = math.max(5, math.abs(offsetSlider.getValue()))
        local idealPosition = (targetCFrame * CFrame.new(0, 0, offset)).Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {myChar, targetChar, Workspace.CurrentCamera, Players}
        params.IgnoreWater = true
        local wallHit = Workspace:Raycast(targetCFrame.Position, idealPosition - targetCFrame.Position, params)
        local finalPosition = wallHit and (wallHit.Position + (wallHit.Normal * 2.5)) or idealPosition
        local floorHit = Workspace:Raycast(finalPosition + Vector3.new(0,4,0), Vector3.new(0,-12,0), params)
        if floorHit then finalPosition = Vector3.new(finalPosition.X, floorHit.Position.Y + 3.0, finalPosition.Z) end
        return CFrame.new(finalPosition, finalPosition + targetCFrame.LookVector)
    end

    local function processTeleport()
        local targetPlayer = getTargetPlayer()
        if not targetPlayer or not LocalPlayer.Character or not targetPlayer.Character then return end
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if myRoot and targetRoot then
            if myHumanoid and myHumanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                myHumanoid.PlatformStand = true
                myHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
            myRoot.CFrame = calculateSafeCFrame(targetRoot, targetPlayer.Character, LocalPlayer.Character)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local function stopTracking()
        isTracking = false
        startTPBtn.Text = "🔄 Start Loop Tracking"
        startTPBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
        stopTPBtn.BackgroundColor3 = Color3.new(0.18,0.18,0.18)
        stopTPBtn.TextColor3 = Color3.new(0.6,0.6,0.6)
        if trackingConnection then trackingConnection:Disconnect(); trackingConnection = nil end
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local myRoot = myChar.HumanoidRootPart
            local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
            myRoot.Anchored = true
            if myHumanoid then myHumanoid.PlatformStand = false; myHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
            myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
            myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
            if myHumanoid then myHumanoid:ChangeState(Enum.HumanoidStateType.Running) end
            myRoot.Anchored = false
        end
        setStatus("Idle")
    end

    instantTPBtn.MouseButton1Click:Connect(function()
        if isTracking then stopTracking() end
        local targetPlayer = getTargetPlayer()
        if not targetPlayer or not LocalPlayer.Character or not targetPlayer.Character then
            instantTPBtn.Text = "❌ Not Found"
            setStatus("Player not found.", Color3.fromRGB(255,80,80))
            task.wait(1.5); instantTPBtn.Text = "⚡ One-Time Teleport"; setStatus("Idle"); return
        end
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and targetRoot and myHumanoid then
            myRoot.Anchored = true; myHumanoid.PlatformStand = true
            myHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
            if LocalPlayer.RequestStreamAroundAsync then
                pcall(function() LocalPlayer:RequestStreamAroundAsync(targetRoot.Position) end)
            end
            myRoot.CFrame = calculateSafeCFrame(targetRoot, targetPlayer.Character, LocalPlayer.Character)
            myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
            myHumanoid.PlatformStand = false; myHumanoid:ChangeState(Enum.HumanoidStateType.Running)
            myRoot.Anchored = false
            setStatus("Teleported to " .. targetPlayer.Name .. ".", Color3.fromRGB(0,200,80))
        end
    end)

    startTPBtn.MouseButton1Click:Connect(function()
        if isTracking then return end
        local targetPlayer = getTargetPlayer()
        if not targetPlayer then
            startTPBtn.Text = "❌ Not Found"; setStatus("Player not found.", Color3.fromRGB(255,80,80))
            task.wait(1.5); startTPBtn.Text = "🔄 Start Loop Tracking"; setStatus("Idle"); return
        end
        isTracking = true
        startTPBtn.Text = "🟢 Tracking..."; startTPBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
        stopTPBtn.BackgroundColor3 = Color3.new(0,0.835,1); stopTPBtn.TextColor3 = Color3.new(1,1,1)
        setStatus("Tracking " .. targetPlayer.Name .. "...", Color3.fromRGB(0,213,255))
        trackingConnection = RunService.Heartbeat:Connect(function()
            local ok, err = pcall(processTeleport)
            if not ok then warn("Tracking error: " .. tostring(err)) end
        end)
    end)

    stopTPBtn.MouseButton1Click:Connect(function() if isTracking then stopTracking() end end)

    Players.PlayerRemoving:Connect(function(p)
        if isTracking and getTargetPlayer() == p then
            setStatus("Target left.", Color3.fromRGB(255,80,80)); stopTracking()
        end
    end)
end
