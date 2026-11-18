local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if env._PassBypassCleanup then
    pcall(env._PassBypassCleanup)
    env._PassBypassCleanup = nil
end

local function getExecutorName()
    local name = "Executor"
    local success, result = pcall(function()
        if typeof(identifyexecutor) == "function" then
            return identifyexecutor()
        elseif typeof(getexecutorname) == "function" then
            return getexecutorname()
        end
    end)
    if success and typeof(result) == "string" and result ~= "" then
        name = result
    end
    return name
end

local currentExecutor = getExecutorName()
local passName = currentExecutor .. " Pass"
local uiName = currentExecutor .. "PassUI"

local function getGuiParent()
    local success, core = pcall(function()
        return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or game:GetService("CoreGui")
    end)
    if success and core then
        return core
    end
    return player:WaitForChild("PlayerGui")
end

local targetGuiParent = getGuiParent()

local function cleanAllPreviousInstances(names)
    local containers = {}
    pcall(function() if gethui then table.insert(containers, gethui()) end end)
    pcall(function() if get_hidden_gui then table.insert(containers, get_hidden_gui()) end end)
    pcall(function() table.insert(containers, game:GetService("CoreGui")) end)
    pcall(function() if player and player:FindFirstChild("PlayerGui") then table.insert(containers, player.PlayerGui) end end)

    for _, container in ipairs(containers) do
        pcall(function()
            for _, name in ipairs(names) do
                local found = container:FindFirstChild(name)
                while found do
                    found:Destroy()
                    found = container:FindFirstChild(name)
                end
            end
        end)
    end
end

cleanAllPreviousInstances({
    uiName,
    "PassUI",
    "StudioPassMonitor",
    "PassReopenBtn",
    "StudioSettingsModal"
})

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
screenGui.ScreenInsets = Enum.ScreenInsets.None
screenGui.Parent = targetGuiParent

local isMobile = UserInputService.TouchEnabled
local autoSpeed = 100
local uiVisible = true
local autoClipEnabled = false 
local blacklist = {}          
local webhookUrl = ""
local antiPrompt = false

local reopenButton = nil
local settingsWindow = nil
local suppressCounter = 0
local eventCount = 0
local entries = {}
local activeAuto = {}
local activeSpam = {}
local activeConnections = {}

local VH = _G.VoidHub
local isClassic = false
local isWasorModern = false

if VH and VH.UI then
    if (VH.UI.themeColors and VH.UI.themeColors["Studio Classic"]) or (_G.WASOR_ScreenGui and _G.WASOR_ScreenGui:FindFirstChild("StudioTopRibbon")) then
        isClassic = true
    else
        isWasorModern = true
    end
end

local StudioTheme
if isWasorModern then
    local curAccent = (VH.State and VH.State.currentThemeColor) or (VH.UI and VH.UI.themeColors and VH.UI.themeColors["Red"]) or Color3.fromRGB(218, 38, 38)
    StudioTheme = {
        isModern       = true,
        font           = Enum.Font.Gotham,
        fontBold       = Enum.Font.GothamBold,
        fontSemibold   = Enum.Font.GothamMedium,
        cornerRadius   = 6,
        borderSize     = 0,
        
        windowBg       = Color3.fromRGB(18, 18, 22),
        headerBg       = Color3.fromRGB(24, 24, 28),
        panelBg        = Color3.fromRGB(22, 22, 26),
        panelAlt       = Color3.fromRGB(16, 16, 18),
        insetBg        = Color3.fromRGB(14, 14, 16),
        categoryBg     = Color3.fromRGB(30, 30, 35),
        cardBg         = Color3.fromRGB(26, 26, 30),
        cardHover      = Color3.fromRGB(36, 36, 42),
        border         = Color3.fromRGB(38, 38, 44),
        borderSubtle   = Color3.fromRGB(48, 48, 54),
        text           = Color3.fromRGB(240, 240, 245),
        textMuted      = Color3.fromRGB(160, 160, 170),
        textDim        = Color3.fromRGB(115, 115, 125),
        
        blue           = curAccent,
        blueHover      = Color3.fromRGB(math.clamp(math.floor(curAccent.R * 255 + 25), 0, 255), math.clamp(math.floor(curAccent.G * 255 + 25), 0, 255), math.clamp(math.floor(curAccent.B * 255 + 25), 0, 255)),
        green          = Color3.fromRGB(46, 204, 113),
        greenHover     = Color3.fromRGB(56, 218, 125),
        red            = Color3.fromRGB(218, 38, 38),
        redHover       = Color3.fromRGB(238, 58, 58),
        yellow         = Color3.fromRGB(241, 196, 15),
        purple         = Color3.fromRGB(141, 47, 196),
        btnBg          = Color3.fromRGB(32, 32, 36),
        btnHover       = Color3.fromRGB(44, 44, 50),
        btnPressed     = curAccent,
        tabActive      = Color3.fromRGB(26, 26, 30),
        tabInactive    = Color3.fromRGB(18, 18, 20),
        Product        = curAccent,
        Gamepass       = Color3.fromRGB(141, 47, 196),
        Bulk           = Color3.fromRGB(241, 196, 15),
    }
else
    StudioTheme = {
        isModern       = false,
        font           = ThemeFont,
        fontBold       = ThemeFontBold,
        fontSemibold   = ThemeFontSemibold,
        cornerRadius   = 0,
        borderSize     = 1,
        
        windowBg       = Color3.fromRGB(37, 37, 38),
        headerBg       = Color3.fromRGB(45, 45, 48),
        panelBg        = Color3.fromRGB(42, 42, 45),
        panelAlt       = Color3.fromRGB(32, 32, 34),
        insetBg        = Color3.fromRGB(26, 26, 28),
        categoryBg     = Color3.fromRGB(50, 50, 54),
        cardBg         = Color3.fromRGB(44, 44, 48),
        cardHover      = Color3.fromRGB(56, 56, 62),
        border         = Color3.fromRGB(20, 20, 22),
        borderSubtle   = Color3.fromRGB(55, 55, 58),
        text           = Color3.fromRGB(225, 225, 228),
        textMuted      = Color3.fromRGB(160, 160, 165),
        textDim        = Color3.fromRGB(115, 115, 120),
        blue           = Color3.fromRGB(0, 122, 204),
        blueHover      = Color3.fromRGB(28, 140, 224), 
        green          = Color3.fromRGB(76, 175, 80),
        greenHover     = Color3.fromRGB(92, 195, 96),  
        red            = Color3.fromRGB(215, 60, 60),
        redHover       = Color3.fromRGB(235, 75, 75),   
        yellow         = Color3.fromRGB(230, 180, 50),
        purple         = Color3.fromRGB(160, 120, 220),
        btnBg          = Color3.fromRGB(50, 50, 54),
        btnHover       = Color3.fromRGB(65, 65, 70),
        btnPressed     = Color3.fromRGB(0, 122, 204),
        tabActive      = Color3.fromRGB(40, 40, 42),
        tabInactive    = Color3.fromRGB(30, 30, 32),
        Product        = Color3.fromRGB(0, 122, 204),
        Gamepass       = Color3.fromRGB(160, 120, 220),
        Bulk           = Color3.fromRGB(230, 180, 50),
    }
end
local ThemeFont = StudioTheme.font
local ThemeFontSemibold = StudioTheme.fontSemibold
local ThemeFontBold = StudioTheme.fontBold


local SIGNAL_COLORS = {
    Product = StudioTheme.blue,
    Gamepass = StudioTheme.purple,
    Bulk = StudioTheme.yellow,
    Purchase = StudioTheme.green,
}

local TITLE_H = 26
local FILTER_H = 28 
local FOOTER_H = 24
local ROW_H = 28
local BTN_H = 20

local function saveConfig()
    if writefile then
        local data = {
            autoSpeed = autoSpeed,
            autoClipEnabled = autoClipEnabled,
            blacklist = blacklist,
            webhookUrl = webhookUrl,
            antiPrompt = antiPrompt
        }
        pcall(writefile, "PassSpammerConfig.json", HttpService:JSONEncode(data))
    end
end

local function loadConfig()
    if readfile and isfile and isfile("PassSpammerConfig.json") then
        local success, result = pcall(readfile, "PassSpammerConfig.json")
        if success then
            local success2, data = pcall(HttpService.JSONDecode, HttpService, result)
            if success2 and typeof(data) == "table" then
                autoSpeed = data.autoSpeed or autoSpeed
                autoClipEnabled = data.autoClipEnabled or false
                blacklist = data.blacklist or {}
                webhookUrl = data.webhookUrl or ""
                antiPrompt = data.antiPrompt or false
            end
        end
    end
end
loadConfig()

local function sendWebhook(label, id)
    if webhookUrl == "" then return end
    local req = syn and syn.request or http and http.request or request
    if req then
        task.spawn(function()
            pcall(req, {
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = "Marketplace Prompt Intercepted",
                        color = 10181046,
                        fields = {
                            {name = "Asset Type", value = label, inline = true},
                            {name = "Asset ID", value = tostring(id), inline = true},
                            {name = "Game/Place ID", value = tostring(game.PlaceId), inline = true}
                        },
                        footer = {text = "Logged via " .. currentExecutor}
                    }}
                })
            })
        end)
    end
end

local function setButtonState(btn, bg, fg)
    if btn and btn.Parent then
        btn.BackgroundColor3 = bg
        if fg then btn.TextColor3 = fg end
    end
end

local function addDesktopHover(btn, normalBg, hoverBg, normalFg, hoverFg)
    if isMobile then return end
    btn.MouseEnter:Connect(function()
        setButtonState(btn, hoverBg, hoverFg or StudioTheme.text)
    end)
    btn.MouseLeave:Connect(function()
        setButtonState(btn, normalBg, normalFg or StudioTheme.text)
    end)
end

local function makeStudioButton(parent, text, w, h, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, h or BTN_H)
    b.BackgroundColor3 = bg or StudioTheme.btnBg
    b.Text = text
    b.TextColor3 = fg or StudioTheme.text
    b.TextSize = 12
    b.Font = ThemeFontSemibold
    b.AutoButtonColor = false
    b.BorderSizePixel = 1
    b.BorderColor3 = StudioTheme.border
    b.ClipsDescendants = true
    b.Parent = parent

    local defaultBg = bg or StudioTheme.btnBg
    local hoverBg = (bg == StudioTheme.blue and StudioTheme.blueHover)
        or (bg == StudioTheme.red and StudioTheme.redHover)
        or (bg == StudioTheme.green and StudioTheme.greenHover)
        or StudioTheme.btnHover
    addDesktopHover(b, defaultBg, hoverBg, fg or StudioTheme.text, fg or StudioTheme.text)

    return b
end

local function makeStudioTextBox(parent, text, width, height, placeholder, fontCode)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, width or 60, 0, height or BTN_H)
    box.BackgroundColor3 = StudioTheme.insetBg
    box.Text = text or ""
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = StudioTheme.textDim
    box.TextColor3 = StudioTheme.text
    box.TextSize = 12
    box.Font = fontCode and Enum.Font.Code or ThemeFont
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 1
    box.BorderColor3 = StudioTheme.border
    box.Parent = parent
    return box
end

local panel = Instance.new("Frame")
panel.Name = "StudioPassMonitor"
panel.Size = isMobile and UDim2.new(0, 360, 0, 260) or UDim2.new(0, 520, 0, 310)
panel.Position = UDim2.new(0.5, isMobile and -180 or -260, 0.5, isMobile and -130 or -155)
panel.BackgroundColor3 = StudioTheme.windowBg
if StudioTheme.isModern then
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", panel)
    s.Color = StudioTheme.border
    s.Thickness = 1
else
    panel.BorderSizePixel = 1
    panel.BorderColor3 = StudioTheme.border
end
panel.ClipsDescendants = true
panel.Active = true
panel.Selectable = true
panel.Parent = screenGui

local panelMin = Instance.new("UISizeConstraint")
panelMin.MinSize = isMobile and Vector2.new(320, 230) or Vector2.new(460, 250)
panelMin.MaxSize = Vector2.new(800, 600)
panelMin.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Name = "StudioTitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = StudioTheme.headerBg
titleBar.BorderSizePixel = 1
titleBar.BorderColor3 = StudioTheme.border
titleBar.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.Text = "Main - Marketplace Interceptor (" .. passName .. ")"
title.TextColor3 = StudioTheme.text
title.TextSize = 13
title.Font = ThemeFontSemibold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local clearBtn = makeStudioButton(titleBar, "Clear", 40, 18, StudioTheme.btnBg, StudioTheme.text)
clearBtn.Position = UDim2.new(1, -72, 0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 1, 0)
closeBtn.Position = UDim2.new(1, -26, 0, 0)
closeBtn.BackgroundColor3 = StudioTheme.headerBg
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = StudioTheme.textMuted
closeBtn.Font = ThemeFontBold
closeBtn.TextSize = 12
closeBtn.Parent = titleBar

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = StudioTheme.red
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = StudioTheme.headerBg
    closeBtn.TextColor3 = StudioTheme.textMuted
end)

local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local filterBar = Instance.new("Frame")
filterBar.Name = "StudioFilterBar"
filterBar.Size = UDim2.new(1, 0, 0, FILTER_H)
filterBar.Position = UDim2.new(0, 0, 0, TITLE_H)
filterBar.BackgroundColor3 = StudioTheme.panelAlt
filterBar.BorderSizePixel = 1
filterBar.BorderColor3 = StudioTheme.border
filterBar.Parent = panel

local filterBox = makeStudioTextBox(filterBar, "", 0, 20, "Filter events by Type or Asset ID (e.g. Gamepass, 12345)...", false)
filterBox.Size = UDim2.new(1, -12, 0, 20)
filterBox.Position = UDim2.new(0, 6, 0, 4)

local listWrap = Instance.new("Frame")
listWrap.Name = "StudioLogViewport"
listWrap.Size = UDim2.new(1, -8, 1, -(TITLE_H + FILTER_H + FOOTER_H + 8))
listWrap.Position = UDim2.new(0, 4, 0, TITLE_H + FILTER_H + 4)
listWrap.BackgroundColor3 = StudioTheme.insetBg
listWrap.BorderSizePixel = 1
listWrap.BorderColor3 = StudioTheme.border
listWrap.ClipsDescendants = true
listWrap.Parent = panel

local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, -2, 1, -2)
logArea.Position = UDim2.new(0, 1, 0, 1)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = 5
logArea.ScrollBarImageColor3 = StudioTheme.borderSubtle
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.ClipsDescendants = true
logArea.Parent = listWrap

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = logArea

local logPad = Instance.new("UIPadding")
logPad.PaddingTop = UDim.new(0, 4)
logPad.PaddingBottom = UDim.new(0, 4)
logPad.PaddingLeft = UDim.new(0, 4)
logPad.PaddingRight = UDim.new(0, 4)
logPad.Parent = logArea

local footer = Instance.new("Frame")
footer.Name = "StudioFooter"
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = StudioTheme.headerBg
footer.BorderSizePixel = 1
footer.BorderColor3 = StudioTheme.border
footer.Parent = panel

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(0, 90, 1, 0)
countLabel.Position = UDim2.new(0, 8, 0, 0)
countLabel.Text = "0 events logged"
countLabel.TextColor3 = StudioTheme.textMuted
countLabel.TextSize = 11
countLabel.Font = ThemeFont
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = footer

local speedLabel = Instance.new("TextLabel")
speedLabel.BackgroundTransparency = 1
speedLabel.Size = UDim2.new(0, 80, 1, 0)
speedLabel.Position = UDim2.new(0, 104, 0, 0)
speedLabel.Text = "Rate: " .. tostring(autoSpeed) .. "/s"
speedLabel.TextColor3 = StudioTheme.textMuted
speedLabel.TextSize = 11
speedLabel.Font = ThemeFont
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = footer

local stopBtn = makeStudioButton(footer, "Stop All", 60, 18, StudioTheme.btnBg, StudioTheme.red)
stopBtn.Position = UDim2.new(1, -126, 0, 3)

local setBtn = makeStudioButton(footer, "Settings", 58, 18, StudioTheme.btnBg, StudioTheme.text)
setBtn.Position = UDim2.new(1, -62, 0, 3)

local function setEmpty(show)
    local old = logArea:FindFirstChild("EmptyState")
    if show and not old then
        local lbl = Instance.new("TextLabel")
        lbl.Name = "EmptyState"
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -4, 0, 80)
        lbl.Text = "-- Ready for marketplace purchase prompts --"
        lbl.TextColor3 = StudioTheme.textDim
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Code
        lbl.Parent = logArea
    elseif not show and old then
        old:Destroy()
    end
end

local function fireFakeSignal(signalType, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if signalType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif signalType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    suppressCounter = suppressCounter - 1
end

local function stopAllLoops()
    for btn, data in pairs(activeAuto) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"
            setButtonState(btn, StudioTheme.btnBg, StudioTheme.text)
        end
    end
    table.clear(activeAuto)

    for btn, data in pairs(activeSpam) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Run"
            setButtonState(btn, StudioTheme.btnBg, StudioTheme.text)
        end
    end
    table.clear(activeSpam)
end

local function updateFilter()
    local q = string.lower(filterBox.Text)
    for _, item in ipairs(entries) do
        if item and item.Parent then
            local labelVal = string.lower(item:FindFirstChild("TypeLabel").Text)
            local idVal = string.lower(item:FindFirstChild("IdLabel").Text)
            if q == "" or string.find(labelVal, q) or string.find(idVal, q) then
                item.Visible = true
            else
                item.Visible = false
            end
        end
    end
end
filterBox:GetPropertyChangedSignal("Text"):Connect(updateFilter)

local function addLog(label, id, signalType)
    if suppressCounter > 0 then return end
    if table.find(blacklist, tonumber(id)) then return end 
    
    setEmpty(false)

    if autoClipEnabled then
        pcall(setclipboard, tostring(id))
    end

    sendWebhook(label, id)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, ROW_H)
    row.BackgroundColor3 = (eventCount % 2 == 0) and StudioTheme.panelBg or StudioTheme.windowBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.LayoutOrder = -(eventCount + 1)
    row.ClipsDescendants = true
    row.Parent = logArea

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 4, 1, 0)
    stripe.BackgroundColor3 = SIGNAL_COLORS[signalType] or StudioTheme.blue
    stripe.BorderSizePixel = 0
    stripe.Parent = row

    local badge = Instance.new("TextLabel")
    badge.Name = "TypeLabel"
    badge.BackgroundTransparency = 1
    badge.Size = UDim2.new(0, 68, 1, 0)
    badge.Position = UDim2.new(0, 8, 0, 0)
    badge.Text = "[" .. string.upper(label) .. "]"
    badge.TextColor3 = SIGNAL_COLORS[signalType] or StudioTheme.blue
    badge.TextSize = 11
    badge.Font = ThemeFontBold
    badge.TextXAlignment = Enum.TextXAlignment.Left
    badge.Parent = row

    local actionWidth = 118
    local idLabel = Instance.new("TextLabel")
    idLabel.Name = "IdLabel"
    idLabel.BackgroundTransparency = 1
    idLabel.Size = UDim2.new(1, -(80 + actionWidth), 1, 0)
    idLabel.Position = UDim2.new(0, 78, 0, 0)
    idLabel.Text = tostring(id)
    idLabel.TextColor3 = StudioTheme.text
    idLabel.TextSize = 12
    idLabel.Font = Enum.Font.Code
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.TextTruncate = Enum.TextTruncate.AtEnd
    idLabel.Parent = row

    local actions = Instance.new("Frame")
    actions.Size = UDim2.new(0, actionWidth, 1, 0)
    actions.Position = UDim2.new(1, -actionWidth, 0, 0)
    actions.BackgroundTransparency = 1
    actions.ClipsDescendants = true
    actions.Parent = row

    local copyBtn = makeStudioButton(actions, "Copy", 36, 20, StudioTheme.btnBg, StudioTheme.text)
    copyBtn.Position = UDim2.new(0, 0, 0, 4)

    local autoBtn = makeStudioButton(actions, "Auto", 36, 20, StudioTheme.btnBg, StudioTheme.text)
    autoBtn.Position = UDim2.new(0, 40, 0, 4)

    local runBtn = makeStudioButton(actions, "Run", 36, 20, StudioTheme.btnBg, StudioTheme.text)
    runBtn.Position = UDim2.new(0, 80, 0, 4)

    copyBtn.Activated:Connect(function()
        pcall(setclipboard, tostring(id))
        copyBtn.Text = "OK"
        setButtonState(copyBtn, StudioTheme.green, Color3.fromRGB(255, 255, 255))
        task.wait(0.6)
        if copyBtn and copyBtn.Parent then
            copyBtn.Text = "Copy"
            setButtonState(copyBtn, StudioTheme.btnBg, StudioTheme.text)
        end
    end)

    local autoOn = false
    local autoLoop = nil

    local function startAuto()
        if autoOn then return end
        autoOn = true
        autoBtn.Text = "ON"
        setButtonState(autoBtn, StudioTheme.red, Color3.fromRGB(255, 255, 255))
        autoLoop = task.spawn(function()
            local delay = autoSpeed > 0 and (1 / autoSpeed) or 0.01
            while autoOn and autoBtn.Parent do
                fireFakeSignal(signalType, id)
                task.wait(delay)
            end
        end)
        activeAuto[autoBtn] = {active = true, loop = autoLoop}
    end

    local function stopAuto()
        autoOn = false
        if autoLoop then task.cancel(autoLoop) end
        activeAuto[autoBtn] = nil
        if autoBtn and autoBtn.Parent then
            autoBtn.Text = "Auto"
            setButtonState(autoBtn, StudioTheme.btnBg, StudioTheme.text)
        end
    end

    autoBtn.Activated:Connect(function()
        if autoOn then stopAuto() else startAuto() end
    end)

    local spamOn = false
    local spamLoop = nil
    local holdStart = nil
    local holdThread = nil

    local function startSpam()
        if spamOn then return end
        spamOn = true
        runBtn.Text = "SPM"
        setButtonState(runBtn, StudioTheme.yellow, Color3.fromRGB(255, 255, 255))
        spamLoop = task.spawn(function()
            while spamOn and runBtn.Parent do
                fireFakeSignal(signalType, id)
                task.wait(0.1)
            end
        end)
        activeSpam[runBtn] = {active = true, loop = spamLoop}
    end

    local function stopSpam()
        spamOn = false
        if spamLoop then task.cancel(spamLoop) end
        activeSpam[runBtn] = nil
        if runBtn and runBtn.Parent then
            runBtn.Text = "Run"
            setButtonState(runBtn, StudioTheme.btnBg, StudioTheme.text)
        end
    end

    local function onPress()
        holdStart = tick()
        holdThread = task.spawn(function()
            while holdStart and (tick() - holdStart) < 2 do
                task.wait(0.05)
            end
            if holdStart and not spamOn then
                startSpam()
            end
        end)
    end

    local function onRelease()
        local held = holdStart and (tick() - holdStart) or 0
        holdStart = nil
        if holdThread then task.cancel(holdThread) end

        if spamOn then
            stopSpam()
        elseif held < 2 then
            fireFakeSignal(signalType, id)
            runBtn.Text = "OK"
            setButtonState(runBtn, StudioTheme.green, Color3.fromRGB(255, 255, 255))
            task.wait(0.5)
            if runBtn and runBtn.Parent then
                runBtn.Text = "Run"
                setButtonState(runBtn, StudioTheme.btnBg, StudioTheme.text)
            end
        end
    end

    runBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onPress()
        end
    end)

    runBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onRelease()
        end
    end)

    row.AncestryChanged:Connect(function()
        if not row.Parent then
            if autoOn then stopAuto() end
            if spamOn then stopSpam() end
            for i, entry in ipairs(entries) do
                if entry == row then
                    table.remove(entries, i)
                    break
                end
            end
        end
    end)

    eventCount = eventCount + 1
    countLabel.Text = tostring(eventCount) .. " events"
    table.insert(entries, row)
    updateFilter() 
end

clearBtn.Activated:Connect(function()
    stopAllLoops()
    for _, entry in ipairs(entries) do
        if entry and entry.Parent then
            entry:Destroy()
        end
    end
    entries = {}
    eventCount = 0
    countLabel.Text = "0 events logged"
    setEmpty(true)
end)

stopBtn.Activated:Connect(stopAllLoops)

local function toggleSettings()
    if settingsWindow then
        settingsWindow:Destroy()
        settingsWindow = nil
        return
    end

    settingsWindow = Instance.new("Frame")
    settingsWindow.Name = "StudioSettingsModal"
    settingsWindow.Size = UDim2.new(0, 290, 0, 270)
    settingsWindow.Position = UDim2.new(0.5, -145, 0.5, -135)
    settingsWindow.BackgroundColor3 = StudioTheme.windowBg
    settingsWindow.BorderSizePixel = 1
    settingsWindow.BorderColor3 = StudioTheme.border
    settingsWindow.ZIndex = 200
    settingsWindow.ClipsDescendants = true
    settingsWindow.Parent = screenGui

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 24)
    top.BackgroundColor3 = StudioTheme.headerBg
    top.BorderSizePixel = 1
    top.BorderColor3 = StudioTheme.border
    top.ZIndex = 201
    top.Parent = settingsWindow

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Size = UDim2.new(1, -28, 1, 0)
    ttl.Position = UDim2.new(0, 6, 0, 0)
    ttl.Text = "Settings & Interceptor Preferences"
    ttl.TextColor3 = StudioTheme.text
    ttl.TextSize = 12
    ttl.Font = ThemeFontSemibold
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 202
    ttl.Parent = top

    local x = Instance.new("TextButton")
    x.Size = UDim2.new(0, 24, 1, 0)
    x.Position = UDim2.new(1, -24, 0, 0)
    x.BackgroundColor3 = StudioTheme.headerBg
    x.BorderSizePixel = 0
    x.Text = "X"
    x.TextColor3 = StudioTheme.textMuted
    x.Font = ThemeFontBold
    x.TextSize = 11
    x.ZIndex = 202
    x.Parent = top

    x.MouseEnter:Connect(function() x.BackgroundColor3 = StudioTheme.red; x.TextColor3 = Color3.fromRGB(255, 255, 255) end)
    x.MouseLeave:Connect(function() x.BackgroundColor3 = StudioTheme.headerBg; x.TextColor3 = StudioTheme.textMuted end)
    x.Activated:Connect(function()
        if settingsWindow then settingsWindow:Destroy(); settingsWindow = nil end
    end)

    local speedLbl = Instance.new("TextLabel")
    speedLbl.BackgroundTransparency = 1
    speedLbl.Size = UDim2.new(0, 68, 0, 20)
    speedLbl.Position = UDim2.new(0, 8, 0, 32)
    speedLbl.Text = "Spam Rate:"
    speedLbl.TextColor3 = StudioTheme.textMuted
    speedLbl.TextSize = 11
    speedLbl.Font = ThemeFontSemibold
    speedLbl.TextXAlignment = Enum.TextXAlignment.Left
    speedLbl.ZIndex = 201
    speedLbl.Parent = settingsWindow

    local box = makeStudioTextBox(settingsWindow, tostring(autoSpeed), 48, 20, "100", true)
    box.Position = UDim2.new(0, 78, 0, 32)
    box.ZIndex = 201

    local save = makeStudioButton(settingsWindow, "Save", 36, 20, StudioTheme.btnBg, StudioTheme.text)
    save.Position = UDim2.new(0, 130, 0, 32)
    save.ZIndex = 201

    local autoClipBtn = makeStudioButton(settingsWindow, autoClipEnabled and "Clip: ON" or "Clip: OFF", 54, 20, autoClipEnabled and StudioTheme.green or StudioTheme.btnBg, StudioTheme.text)
    autoClipBtn.Position = UDim2.new(0, 170, 0, 32)
    autoClipBtn.ZIndex = 201

    local antiBtn = makeStudioButton(settingsWindow, antiPrompt and "Block: ON" or "Block: OFF", 56, 20, antiPrompt and StudioTheme.red or StudioTheme.btnBg, StudioTheme.text)
    antiBtn.Position = UDim2.new(0, 228, 0, 32)
    antiBtn.ZIndex = 201

    save.Activated:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.floor(n)
            if n >= 1 and n <= 10000 then
                autoSpeed = n
                speedLabel.Text = "Rate: " .. tostring(autoSpeed) .. "/s"
                box.BackgroundColor3 = StudioTheme.green
                saveConfig()
                task.wait(0.3)
                if box and box.Parent then box.BackgroundColor3 = StudioTheme.insetBg end
            else
                box.BackgroundColor3 = StudioTheme.red
                task.wait(0.3)
                if box and box.Parent then box.BackgroundColor3 = StudioTheme.insetBg end
            end
        end
    end)

    autoClipBtn.Activated:Connect(function()
        autoClipEnabled = not autoClipEnabled
        autoClipBtn.Text = autoClipEnabled and "Clip: ON" or "Clip: OFF"
        setButtonState(autoClipBtn, autoClipEnabled and StudioTheme.green or StudioTheme.btnBg, StudioTheme.text)
        saveConfig()
    end)

    antiBtn.Activated:Connect(function()
        antiPrompt = not antiPrompt
        antiBtn.Text = antiPrompt and "Block: ON" or "Block: OFF"
        setButtonState(antiBtn, antiPrompt and StudioTheme.red or StudioTheme.btnBg, StudioTheme.text)
        saveConfig()
    end)

    local webLbl = Instance.new("TextLabel")
    webLbl.BackgroundTransparency = 1
    webLbl.Size = UDim2.new(0, 76, 0, 20)
    webLbl.Position = UDim2.new(0, 8, 0, 58)
    webLbl.Text = "Webhook URL:"
    webLbl.TextColor3 = StudioTheme.textMuted
    webLbl.TextSize = 11
    webLbl.Font = ThemeFontSemibold
    webLbl.TextXAlignment = Enum.TextXAlignment.Left
    webLbl.ZIndex = 201
    webLbl.Parent = settingsWindow

    local webBox = makeStudioTextBox(settingsWindow, webhookUrl, 0, 20, "Discord webhook URL...", false)
    webBox.Size = UDim2.new(1, -134, 0, 20)
    webBox.Position = UDim2.new(0, 84, 0, 58)
    webBox.ZIndex = 201

    local saveWebBtn = makeStudioButton(settingsWindow, "Apply", 40, 20, StudioTheme.btnBg, StudioTheme.text)
    saveWebBtn.Position = UDim2.new(1, -46, 0, 58)
    saveWebBtn.ZIndex = 201

    saveWebBtn.Activated:Connect(function()
        webhookUrl = webBox.Text
        saveConfig()
        saveWebBtn.Text = "OK"
        setButtonState(saveWebBtn, StudioTheme.green, Color3.fromRGB(255, 255, 255))
        task.wait(0.5)
        if saveWebBtn and saveWebBtn.Parent then
            saveWebBtn.Text = "Apply"
            setButtonState(saveWebBtn, StudioTheme.btnBg, StudioTheme.text)
        end
    end)

    local sectionBar = Instance.new("Frame")
    sectionBar.Size = UDim2.new(1, -16, 0, 18)
    sectionBar.Position = UDim2.new(0, 8, 0, 86)
    sectionBar.BackgroundColor3 = StudioTheme.categoryBg
    sectionBar.BorderSizePixel = 1
    sectionBar.BorderColor3 = StudioTheme.border
    sectionBar.ZIndex = 201
    sectionBar.Parent = settingsWindow

    local manualTitle = Instance.new("TextLabel")
    manualTitle.BackgroundTransparency = 1
    manualTitle.Size = UDim2.new(1, -8, 1, 0)
    manualTitle.Position = UDim2.new(0, 4, 0, 0)
    manualTitle.Text = "v Manual Entry & Blacklist"
    manualTitle.TextColor3 = StudioTheme.text
    manualTitle.TextSize = 11
    manualTitle.Font = ThemeFontBold
    manualTitle.TextXAlignment = Enum.TextXAlignment.Left
    manualTitle.ZIndex = 202
    manualTitle.Parent = sectionBar

    local targetIdBox = makeStudioTextBox(settingsWindow, "", 130, 20, "Target ID (e.g. 12345)", true)
    targetIdBox.Position = UDim2.new(0, 8, 0, 110)
    targetIdBox.ZIndex = 201

    local typeToggle = "Product"
    local typeToggleBtn = makeStudioButton(settingsWindow, "Type: Product", 136, 20, StudioTheme.btnBg, StudioTheme.text)
    typeToggleBtn.Position = UDim2.new(0, 144, 0, 110)
    typeToggleBtn.ZIndex = 201
    
    typeToggleBtn.Activated:Connect(function()
        if typeToggle == "Product" then
            typeToggle = "Gamepass"
        elseif typeToggle == "Gamepass" then
            typeToggle = "Bulk"
        elseif typeToggle == "Bulk" then
            typeToggle = "Purchase"
        else
            typeToggle = "Product"
        end
        typeToggleBtn.Text = "Type: " .. typeToggle
        typeToggleBtn.TextColor3 = SIGNAL_COLORS[typeToggle] or StudioTheme.text
    end)

    local createBtn = makeStudioButton(settingsWindow, "+ Add to Log", 130, 22, StudioTheme.green, Color3.fromRGB(255, 255, 255))
    createBtn.Position = UDim2.new(0, 8, 0, 136)
    createBtn.ZIndex = 201

    local blacklistBtn = makeStudioButton(settingsWindow, "Block / Unblock", 136, 22, StudioTheme.btnBg, StudioTheme.red)
    blacklistBtn.Position = UDim2.new(0, 144, 0, 136)
    blacklistBtn.ZIndex = 201

    createBtn.Activated:Connect(function()
        local idVal = tonumber(targetIdBox.Text)
        if idVal then
            addLog(typeToggle, idVal, typeToggle)
            createBtn.Text = "Added!"
            task.wait(0.5)
            if createBtn and createBtn.Parent then createBtn.Text = "+ Add to Log" end
        else
            targetIdBox.BackgroundColor3 = StudioTheme.red
            task.wait(0.3)
            if targetIdBox and targetIdBox.Parent then targetIdBox.BackgroundColor3 = StudioTheme.insetBg end
        end
    end)

    blacklistBtn.Activated:Connect(function()
        local idVal = tonumber(targetIdBox.Text)
        if idVal then
            local index = table.find(blacklist, idVal)
            if index then
                table.remove(blacklist, index)
                blacklistBtn.Text = "Unblocked!"
            else
                table.insert(blacklist, idVal)
                blacklistBtn.Text = "Blocked!"
                for _, item in ipairs(entries) do
                    if item and item.Parent and tonumber(item:FindFirstChild("IdLabel").Text) == idVal then
                        item:Destroy()
                    end
                end
            end
            saveConfig()
            task.wait(0.5)
            if blacklistBtn and blacklistBtn.Parent then blacklistBtn.Text = "Block / Unblock" end
        else
            targetIdBox.BackgroundColor3 = StudioTheme.red
            task.wait(0.3)
            if targetIdBox and targetIdBox.Parent then targetIdBox.BackgroundColor3 = StudioTheme.insetBg end
        end
    end)

    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Size = UDim2.new(1, -16, 0, 80)
    infoLbl.Position = UDim2.new(0, 8, 0, 168)
    infoLbl.Text = "- Block: ON intercepts outgoing prompts to suppress screen overlays.\n- Auto-clip copies detected IDs directly to clipboard.\n- Webhooks post intercepted marketplace events to Discord."
    infoLbl.TextColor3 = StudioTheme.textDim
    infoLbl.TextSize = 10
    infoLbl.Font = ThemeFont
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextWrapped = true
    infoLbl.ZIndex = 201
    infoLbl.Parent = settingsWindow
end

setBtn.Activated:Connect(toggleSettings)

local function showGui()
    screenGui.Enabled = true
    uiVisible = true
    if reopenButton then reopenButton.Visible = false end
end

local function hideGui()
    screenGui.Enabled = false
    uiVisible = false

    if isMobile then
        if not reopenButton or not reopenButton.Parent then
            reopenButton = makeStudioButton(targetGuiParent, "P", 28, 28, StudioTheme.headerBg, StudioTheme.text)
            reopenButton.Name = "PassReopenBtn"
            reopenButton.Size = UDim2.new(0, 28, 0, 28)
            reopenButton.Position = UDim2.new(1, -34, 1, -34)
            reopenButton.AnchorPoint = Vector2.new(1, 1)
            reopenButton.ZIndex = 400

            local startPos, startInput, moved
            reopenButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    startPos = reopenButton.Position
                    startInput = input.Position
                    moved = false

                    local moveConn
                    local endConn
                    moveConn = UserInputService.InputChanged:Connect(function(changed)
                        if changed.UserInputType == input.UserInputType then
                            local delta = changed.Position - startInput
                            if delta.Magnitude > 6 then moved = true end
                            reopenButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                        end
                    end)
                    endConn = UserInputService.InputEnded:Connect(function(ended)
                        if ended.UserInputType == input.UserInputType then
                            moveConn:Disconnect()
                            endConn:Disconnect()
                            if not moved then showGui() end
                        end
                    end)
                end
            end)
        else
            reopenButton.Visible = true
        end
    end
end

closeBtn.Activated:Connect(hideGui)

if not isMobile then
    local keyConn = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if uiVisible then hideGui() else showGui() end
        end
    end)
    table.insert(activeConnections, keyConn)
end

local hookSuccess, hookErr = pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if self == MarketplaceService then
                if method == "PromptPurchase" and typeof(args[2]) == "number" then
                    task.spawn(addLog, "Purchase", args[2], "Purchase")
                    if antiPrompt then return end
                elseif method == "PromptGamePassPurchase" and typeof(args[2]) == "number" then
                    task.spawn(addLog, "Gamepass", args[2], "Gamepass")
                    if antiPrompt then return end
                elseif method == "PromptProductPurchase" and typeof(args[2]) == "number" then
                    task.spawn(addLog, "Product", args[2], "Product")
                    if antiPrompt then return end
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

local c1 = MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Product", id, "Product") end
end)
local c2 = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
local c3 = MarketplaceService.PromptBulkPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
end)
local c4 = MarketplaceService.PromptPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)
table.insert(activeConnections, c1)
table.insert(activeConnections, c2)
table.insert(activeConnections, c3)
table.insert(activeConnections, c4)

setEmpty(true)

env._PassBypassCleanup = function()
    stopAllLoops()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(activeConnections)
    cleanAllPreviousInstances({
        uiName,
        "PassUI",
        "StudioPassMonitor",
        "PassReopenBtn",
        "StudioSettingsModal"
    })
end
