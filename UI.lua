-- =====================
-- MODULE: UI
-- =====================
-- Builds the ScreenGui and exposes widget factories.
-- Does NOT reference Aimbot/ESP/etc. directly — wiring is
-- done in Main.lua via the callbacks passed to each row.
-- =====================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}

-- ── Constants ──────────────────────────────────────────────
local PILL_W    = 36
local PILL_H    = 18
local KNOB_SIZE = 14
local KNOB_PAD  = 2

local FONT_REGULAR = Font.new(
    "rbxasset://fonts/families/SourceSansPro.json",
    Enum.FontWeight.Regular, Enum.FontStyle.Normal
)
local FONT_BOLD = Font.new(
    "rbxasset://fonts/families/SourceSansPro.json",
    Enum.FontWeight.Bold, Enum.FontStyle.Normal
)

-- ── Root GUI ───────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "ChrisMHubGui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn  = false

local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
MainFrame.BorderSizePixel  = 0
MainFrame.Position         = UDim2.new(0.225, 0, 0.23, 0)
MainFrame.Size             = UDim2.new(0, 675, 0, 486)
MainFrame.Parent           = ScreenGui
Instance.new("UICorner").Parent = MainFrame

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.BorderSizePixel        = 0
titleLbl.FontFace               = FONT_REGULAR
titleLbl.Size                   = UDim2.new(0, 200, 0, 50)
titleLbl.Text                   = "ChrisM Hub: Universal"
titleLbl.TextColor3             = Color3.new(1, 1, 1)
titleLbl.TextSize               = 18
titleLbl.Parent                 = MainFrame

local authorLbl = Instance.new("TextLabel")
authorLbl.BackgroundTransparency = 1
authorLbl.BorderSizePixel        = 0
authorLbl.FontFace               = FONT_REGULAR
authorLbl.Position               = UDim2.new(0.219, 0, -0.006, 0)
authorLbl.Size                   = UDim2.new(0, 193, 0, 56)
authorLbl.Text                   = "by LLOCD_1234 and BinkBink"
authorLbl.TextColor3             = Color3.new(0.58, 0.58, 0.58)
authorLbl.TextSize               = 14
authorLbl.Parent                 = MainFrame

local Indicator = Instance.new("Frame")
Indicator.Name             = "Indicator"
Indicator.BackgroundColor3 = Color3.new(0, 0.835, 1)
Indicator.BorderSizePixel  = 0
Indicator.Position         = UDim2.new(-0.412, 0, -0.426, 0)
Indicator.Size             = UDim2.new(0, 4, 0, 20)
Indicator.Parent           = MainFrame

local MinBtn = Instance.new("ImageButton")
MinBtn.Name                = "MinBtn"
MinBtn.BackgroundTransparency = 1
MinBtn.BorderSizePixel     = 0
MinBtn.Image               = "rbxassetid://82235228007110"
MinBtn.Position            = UDim2.new(0.92, 0, 0.002, 0)
MinBtn.Size                = UDim2.new(0, 22, 0, 22)
MinBtn.Parent              = MainFrame

local CloseBtn = Instance.new("ImageButton")
CloseBtn.Name              = "CloseBtn"
CloseBtn.BackgroundTransparency = 1
CloseBtn.BorderSizePixel   = 0
CloseBtn.Image             = "rbxassetid://109757326745560"
CloseBtn.Position          = UDim2.new(0.966, 0, 0.014, 0)
CloseBtn.Size              = UDim2.new(0, 11, 0, 11)
CloseBtn.Parent            = MainFrame

local PageFolder = Instance.new("Folder")
PageFolder.Parent = MainFrame

-- ── Widget factories ───────────────────────────────────────
function UI.makePill(parent, defaultState)
    local pill = Instance.new("Frame")
    pill.Size              = UDim2.new(0, PILL_W, 0, PILL_H)
    pill.AnchorPoint       = Vector2.new(1, 0.5)
    pill.Position          = UDim2.new(1, -12, 0.5, 0)
    pill.BackgroundColor3  = defaultState and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(76, 76, 76)
    pill.BorderSizePixel   = 0
    pill.ClipsDescendants  = true
    pill.Parent            = parent
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE)
    knob.AnchorPoint      = Vector2.new(0, 0.5)
    knob.Position         = defaultState
        and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
        or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 2
    knob.Parent           = pill
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    return pill, knob
end

function UI.animatePill(pill, knob, state)
    TweenService:Create(pill, TweenInfo.new(0.15), {
        BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(76, 76, 76)
    }):Play()
    TweenService:Create(knob, TweenInfo.new(0.15), {
        Position = state
            and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
            or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    }):Play()
end

function UI.makeSectionLabel(parent, yOffset, text)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0.06, 0, 0, yOffset)
    lbl.Size                   = UDim2.new(0, 420, 0, 20)
    lbl.Text                   = text
    lbl.TextColor3             = Color3.fromRGB(0, 213, 255)
    lbl.TextSize               = 11
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_BOLD
    lbl.Parent                 = parent
end

-- Toggle row with pill. onToggle(state: bool)
function UI.makeToggleRow(parent, yOffset, labelText, defaultState, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel  = 0
    row.Position         = UDim2.new(0.06, 0, 0, yOffset)
    row.Size             = UDim2.new(0, 420, 0, 36)
    row.Parent           = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0.02, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.7, 0, 1, 0)
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_REGULAR
    lbl.Parent                 = row

    local pill, knob = UI.makePill(row, defaultState)
    local state = defaultState

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UI.animatePill(pill, knob, state)
            if onToggle then onToggle(state) end
        end
    end)

    return row
end

-- Indented sub-toggle with accent bar
function UI.makeSubToggleRow(parent, yOffset, labelText, defaultState, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.13, 0.13, 0.13)
    row.BorderSizePixel  = 0
    row.Position         = UDim2.new(0.06, 22, 0, yOffset)
    row.Size             = UDim2.new(0, 398, 0, 32)
    row.Parent           = parent
    Instance.new("UICorner").Parent = row

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.new(0, 0.835, 1)
    bar.BorderSizePixel  = 0
    bar.Position         = UDim2.new(0, 0, 0.15, 0)
    bar.Size             = UDim2.new(0, 2, 0.7, 0)
    bar.Parent           = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.Size                   = UDim2.new(0.65, 0, 1, 0)
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.fromRGB(180, 180, 180)
    lbl.TextSize               = 12
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_REGULAR
    lbl.Parent                 = row

    local pill, knob = UI.makePill(row, defaultState)
    local state = defaultState

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UI.animatePill(pill, knob, state)
            if onToggle then onToggle(state) end
        end
    end)

    return row
end

-- Dropdown row. onChange(selectedString)
function UI.makeDropdownRow(parent, yOffset, labelText, options, defaultIndex, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3  = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel   = 0
    row.Position          = UDim2.new(0.06, 0, 0, yOffset)
    row.Size              = UDim2.new(0, 420, 0, 36)
    row.ClipsDescendants  = false
    row.Parent            = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0.02, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.5, 0, 1, 0)
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_REGULAR
    lbl.Parent                 = row

    local selected = defaultIndex or 1
    local open     = false

    local selBtn = Instance.new("TextButton")
    selBtn.AnchorPoint       = Vector2.new(1, 0.5)
    selBtn.Position          = UDim2.new(1, -8, 0.5, 0)
    selBtn.Size              = UDim2.new(0, 140, 0, 24)
    selBtn.BackgroundColor3  = Color3.new(0.22, 0.22, 0.22)
    selBtn.BorderSizePixel   = 0
    selBtn.Text              = options[selected] .. "  ▾"
    selBtn.TextColor3        = Color3.new(0, 0.835, 1)
    selBtn.TextSize          = 12
    selBtn.FontFace          = FONT_REGULAR
    selBtn.ZIndex            = 5
    selBtn.Parent            = row
    Instance.new("UICorner").Parent = selBtn

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    listFrame.BorderSizePixel  = 0
    listFrame.Position         = UDim2.new(1, -148, 1, 4)
    listFrame.Size             = UDim2.new(0, 140, 0, #options * 26)
    listFrame.Visible          = false
    listFrame.ZIndex           = 10
    listFrame.Parent           = row
    Instance.new("UICorner").Parent = listFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel        = 0
        optBtn.Position               = UDim2.new(0, 0, 0, (i - 1) * 26)
        optBtn.Size                   = UDim2.new(1, 0, 0, 26)
        optBtn.Text                   = opt
        optBtn.TextColor3             = Color3.new(0.85, 0.85, 0.85)
        optBtn.TextSize               = 12
        optBtn.ZIndex                 = 11
        optBtn.FontFace               = FONT_REGULAR
        optBtn.Parent                 = listFrame

        optBtn.MouseButton1Click:Connect(function()
            selected = i
            selBtn.Text   = options[i] .. "  ▾"
            listFrame.Visible = false
            open = false
            if onChange then onChange(options[i]) end
        end)
        optBtn.MouseEnter:Connect(function() optBtn.TextColor3 = Color3.new(0, 0.835, 1) end)
        optBtn.MouseLeave:Connect(function() optBtn.TextColor3 = Color3.new(0.85, 0.85, 0.85) end)
    end

    selBtn.MouseButton1Click:Connect(function() open = not open; listFrame.Visible = open end)
end

-- Text input row. Returns { getValue() }
function UI.makeInputRow(parent, yOffset, labelText, placeholder)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel  = 0
    row.Position         = UDim2.new(0.06, 0, 0, yOffset)
    row.Size             = UDim2.new(0, 420, 0, 40)
    row.Parent           = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0.02, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.38, 0, 1, 0)
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_REGULAR
    lbl.Parent                 = row

    local box = Instance.new("TextBox")
    box.BackgroundColor3   = Color3.new(0.22, 0.22, 0.22)
    box.BorderSizePixel    = 0
    box.Position           = UDim2.new(0.4, 0, 0.15, 0)
    box.Size               = UDim2.new(0.58, 0, 0.7, 0)
    box.Text               = ""
    box.PlaceholderText    = placeholder
    box.PlaceholderColor3  = Color3.new(0.45, 0.45, 0.45)
    box.TextColor3         = Color3.new(0, 0.835, 1)
    box.TextSize           = 12
    box.ClearTextOnFocus   = false
    box.FontFace           = FONT_REGULAR
    box.Parent             = row
    Instance.new("UICorner").Parent = box

    return { Row = row, getValue = function() return box.Text end }
end

-- Slider row. Returns { getValue() }; onChange(value: number)
function UI.makeSliderRow(parent, yOffset, labelText, minVal, maxVal, defaultVal, onChange)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    row.BorderSizePixel  = 0
    row.Position         = UDim2.new(0.06, 0, 0, yOffset)
    row.Size             = UDim2.new(0, 420, 0, 50)
    row.Parent           = parent
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Position               = UDim2.new(0.02, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.6, 0, 0.5, 0)
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.FontFace               = FONT_REGULAR
    lbl.Parent                 = row

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1
    valLbl.BorderSizePixel        = 0
    valLbl.Position               = UDim2.new(0.7, 0, 0, 0)
    valLbl.Size                   = UDim2.new(0.28, 0, 0.5, 0)
    valLbl.Text                   = tostring(defaultVal)
    valLbl.TextColor3             = Color3.new(0, 0.835, 1)
    valLbl.TextSize               = 13
    valLbl.TextXAlignment         = Enum.TextXAlignment.Right
    valLbl.FontFace               = FONT_BOLD
    valLbl.Parent                 = row

    local trackBg = Instance.new("Frame")
    trackBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    trackBg.BorderSizePixel  = 0
    trackBg.Position         = UDim2.new(0.02, 0, 0.62, 0)
    trackBg.Size             = UDim2.new(0.96, 0, 0, 4)
    trackBg.Parent           = row
    Instance.new("UICorner").Parent = trackBg

    local trackFill = Instance.new("Frame")
    trackFill.BackgroundColor3 = Color3.new(0, 0.835, 1)
    trackFill.BorderSizePixel  = 0
    trackFill.Size             = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    trackFill.Parent           = trackBg
    Instance.new("UICorner").Parent = trackFill

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.ZIndex           = 2
    knob.Parent           = trackBg
    Instance.new("UICorner").Parent = knob

    local currentValue = defaultVal
    local dragging     = false

    local function updateSlider(inputX)
        local pct = math.clamp(
            (inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X,
            0, 1
        )
        currentValue         = math.floor(minVal + pct * (maxVal - minVal))
        trackFill.Size       = UDim2.new(pct, 0, 1, 0)
        knob.Position        = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text          = tostring(currentValue)
        if onChange then onChange(currentValue) end
    end

    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return { Row = row, getValue = function() return currentValue end }
end

-- Action button
function UI.makeActionBtn(parent, yOffset, labelText)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.new(0, 0.835, 1)
    btn.BorderSizePixel  = 0
    btn.Position         = UDim2.new(0.06, 0, 0, yOffset)
    btn.Size             = UDim2.new(0, 420, 0, 36)
    btn.Text             = labelText
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.TextSize         = 13
    btn.FontFace         = FONT_BOLD
    btn.Parent           = parent
    Instance.new("UICorner").Parent = btn
    return btn
end

-- Sidebar nav button
function UI.makeSideBtn(name, yScale, text, iconId)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
    btn.BorderSizePixel  = 0
    btn.FontFace         = FONT_REGULAR
    btn.Position         = UDim2.new(0.022, 0, yScale, 0)
    btn.Size             = UDim2.new(0, 194, 0, 40)
    btn.Text             = text
    btn.TextColor3       = Color3.new(0.62, 0.62, 0.62)
    btn.TextSize         = 15
    btn.Parent           = MainFrame
    Instance.new("UICorner").Parent = btn

    if iconId then
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.BorderSizePixel        = 0
        icon.Image                  = "rbxassetid://" .. iconId
        icon.ImageColor3            = Color3.new(0.58, 0.58, 0.58)
        icon.Position               = UDim2.new(0.07, 0, 0.115, 0)
        icon.Size                   = UDim2.new(0, 28, 0, 28)
        icon.Parent                 = btn
    end

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0.2, 0)
    pad.Parent       = btn

    return btn
end

-- Page frame
function UI.makePage(name)
    local page = Instance.new("Frame")
    page.Name             = name
    page.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
    page.BorderSizePixel  = 0
    page.Position         = UDim2.new(0.31, 0, 0.126, 0)
    page.Size             = UDim2.new(0, 466, 0, 425)
    page.Visible          = false
    page.Parent           = PageFolder
    Instance.new("UICorner").Parent = page
    return page
end

-- Page title label
function UI.makePageTitle(page, text)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.FontFace               = FONT_BOLD
    lbl.Position               = UDim2.new(0, 25, 0, 10)
    lbl.Size                   = UDim2.new(0.88, 0, 0, 32)
    lbl.Text                   = text
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextSize               = 20
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = page
end

-- ── Tab switcher ───────────────────────────────────────────
function UI.setupTabSwitcher(buttons, pages)
    local TWEEN = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function switchTo(selectedBtn)
        TweenService:Create(Indicator, TWEEN, {
            Position = UDim2.new(
                selectedBtn.Position.X.Scale,
                selectedBtn.Position.X.Offset - 6,
                selectedBtn.Position.Y.Scale,
                selectedBtn.Position.Y.Offset + selectedBtn.Size.Y.Offset / 4
            ),
            Size = UDim2.new(0, 4, 0, selectedBtn.Size.Y.Offset / 2)
        }):Play()

        for _, btn in ipairs(buttons) do
            local sel = (btn == selectedBtn)
            TweenService:Create(btn, TWEEN, {
                BackgroundTransparency = sel and 0.88 or 1,
                TextTransparency       = sel and 0 or 0.4,
            }):Play()
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then
                TweenService:Create(icon, TWEEN, { ImageTransparency = sel and 0 or 0.4 }):Play()
            end
        end

        for name, page in pairs(pages) do
            page.Visible = (name == selectedBtn.Name)
        end
    end

    for _, btn in ipairs(buttons) do
        btn.MouseButton1Click:Connect(function() switchTo(btn) end)
    end

    return switchTo
end

-- ── Draggable MainFrame ────────────────────────────────────
function UI.setupDrag()
    local dragging, dragInput, dragStart, startPos

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
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
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ── Window controls ────────────────────────────────────────
-- onClose: called before the GUI is destroyed so Main can clean up modules
function UI.setupWindowControls(onClose)
    CloseBtn.MouseButton1Click:Connect(function()
        if onClose then onClose() end
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function() ScreenGui:Destroy() end)
    end)

    MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.K then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
end

-- ── Mount ─────────────────────────────────────────────────
function UI.mount()
    ScreenGui.Parent = PlayerGui
end

return UI
