local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Helper function to identify the current executor dynamically
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

-- Clean up any previous instances using the dynamic name
if playerGui:FindFirstChild(uiName) then
    playerGui[uiName]:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
screenGui.ScreenInsets = Enum.ScreenInsets.None
screenGui.Parent = playerGui

local isMobile = UserInputService.TouchEnabled
local autoSpeed = 100
local uiVisible = true
local autoClipEnabled = false 
local blacklist = {}          
local webhookUrl = ""         -- FEATURE: Discord Webhook URL
local antiPrompt = false       -- FEATURE: Block purchase screen overlays

local reopenButton = nil
local settingsWindow = nil
local suppressCounter = 0
local eventCount = 0
local entries = {}
local activeAuto = {}
local activeSpam = {}

local C = {
    bg = Color3.fromRGB(36, 39, 47),
    panel = Color3.fromRGB(58, 62, 74),
    panel2 = Color3.fromRGB(70, 75, 89),
    top = Color3.fromRGB(82, 88, 104),
    borderDark = Color3.fromRGB(24, 26, 31),
    borderLight = Color3.fromRGB(112, 119, 138),
    text = Color3.fromRGB(241, 243, 247),
    textMuted = Color3.fromRGB(210, 214, 223),
    textDim = Color3.fromRGB(165, 171, 184),
    blue = Color3.fromRGB(97, 150, 228),
    green = Color3.fromRGB(103, 208, 120),
    red = Color3.fromRGB(221, 103, 103),
    yellow = Color3.fromRGB(222, 186, 90),
    purple = Color3.fromRGB(156, 129, 220),
}

local SIGNAL_COLORS = {
    Product = C.blue,
    Gamepass = C.purple,
    Bulk = C.yellow,
    Purchase = C.green,
}

local TITLE_H = 28
local FILTER_H = 24 
local FOOTER_H = 30
local ROW_H = 26
local BTN_H = 20

-- FEATURE: Save/Load Config persistence
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
loadConfig() -- Call early to load configs

-- FEATURE: Webhook poster
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
                        title = "🛒 Marketplace Prompt Intercepted",
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

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.borderDark
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 0)
    c.Parent = parent
    return c
end

local function pad(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function setButtonState(btn, bg, fg)
    if btn and btn.Parent then
        btn.BackgroundColor3 = bg
        btn.TextColor3 = fg
    end
end

local function addDesktopHover(btn, normalBg, hoverBg, normalFg, hoverFg)
    if isMobile then return end
    btn.MouseEnter:Connect(function()
        setButtonState(btn, hoverBg, hoverFg)
    end)
    btn.MouseLeave:Connect(function()
        setButtonState(btn, normalBg, normalFg)
    end)
end

local function bevel(parent)
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 1)
    topLine.BackgroundColor3 = C.borderLight
    topLine.BorderSizePixel = 0
    topLine.Parent = parent

    local leftLine = Instance.new("Frame")
    leftLine.Size = UDim2.new(0, 1, 1, 0)
    leftLine.BackgroundColor3 = C.borderLight
    leftLine.BorderSizePixel = 0
    leftLine.Parent = parent

    local bottomLine = Instance.new("Frame")
    bottomLine.AnchorPoint = Vector2.new(0, 1)
    bottomLine.Position = UDim2.new(0, 0, 1, 0)
    bottomLine.Size = UDim2.new(1, 0, 0, 1)
    bottomLine.BackgroundColor3 = C.borderDark
    bottomLine.BorderSizePixel = 0
    bottomLine.Parent = parent

    local rightLine = Instance.new("Frame")
    rightLine.AnchorPoint = Vector2.new(1, 0)
    rightLine.Position = UDim2.new(1, 0, 0, 0)
    rightLine.Size = UDim2.new(0, 1, 1, 0)
    rightLine.BackgroundColor3 = C.borderDark
    rightLine.BorderSizePixel = 0
    rightLine.Parent = parent
end

local function makeButton(parent, text, w, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, BTN_H)
    b.BackgroundColor3 = bg or C.panel
    b.Text = text
    b.TextColor3 = fg or C.text
    b.TextSize = 12
    b.Font = Enum.Font.ArialBold
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ClipsDescendants = true
    b.Parent = parent
    bevel(b)
    return b
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = isMobile and UDim2.new(0, 320, 0, 244) or UDim2.new(0, 460, 0, 274)
panel.Position = UDim2.new(0.5, isMobile and -160 or -230, 0.5, isMobile and -122 or -137)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Active = true
panel.Selectable = true
panel.Parent = screenGui
bevel(panel)

local panelMin = Instance.new("UISizeConstraint")
panelMin.MinSize = isMobile and Vector2.new(300, 220) or Vector2.new(430, 240)
panelMin.MaxSize = Vector2.new(700, 500)
panelMin.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.top
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
bevel(titleBar)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -68, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.Text = passName
title.TextColor3 = C.text
title.TextSize = 14
title.Font = Enum.Font.ArialBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local clearBtn = makeButton(titleBar, "Clear", 40, C.panel2, C.text)
clearBtn.Position = UDim2.new(1, -64, 0, 4)
addDesktopHover(clearBtn, C.panel2, C.top, C.text, C.text)

local closeBtn = makeButton(titleBar, "X", 20, C.red, C.text)
closeBtn.Position = UDim2.new(1, -22, 0, 4)

local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1, 0, 0, FILTER_H)
filterBar.Position = UDim2.new(0, 0, 0, TITLE_H)
filterBar.BackgroundColor3 = C.panel
filterBar.BorderSizePixel = 0
filterBar.Parent = panel
bevel(filterBar)

local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -16, 0, 16)
filterBox.Position = UDim2.new(0, 8, 0, 4)
filterBox.BackgroundColor3 = C.bg
filterBox.PlaceholderText = "Filter by ID or Type (e.g. Gamepass, Product)..."
filterBox.PlaceholderColor3 = C.textDim
filterBox.Text = ""
filterBox.TextColor3 = C.text
filterBox.TextSize = 11
filterBox.Font = Enum.Font.Arial
filterBox.TextXAlignment = Enum.TextXAlignment.Left
filterBox.BorderSizePixel = 0
filterBox.Parent = filterBar
bevel(filterBox)
pad(filterBox, 4, 4, 0, 0)

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

local listWrap = Instance.new("Frame")
listWrap.Size = UDim2.new(1, -8, 1, -(TITLE_H + FILTER_H + FOOTER_H + 8))
listWrap.Position = UDim2.new(0, 4, 0, TITLE_H + FILTER_H + 4)
listWrap.BackgroundColor3 = C.panel
listWrap.BorderSizePixel = 0
listWrap.ClipsDescendants = true
listWrap.Parent = panel
bevel(listWrap)

local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, -4, 1, -4)
logArea.Position = UDim2.new(0, 2, 0, 2)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = 3
logArea.ScrollBarImageColor3 = C.borderLight
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.ClipsDescendants = true
logArea.Parent = listWrap

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = logArea
pad(logArea, 2, 2, 2, 2)

local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = C.top
footer.BorderSizePixel = 0
footer.Parent = panel
bevel(footer)

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(0, 120, 1, 0)
countLabel.Position = UDim2.new(0, 6, 0, 0)
countLabel.Text = "0 events"
countLabel.TextColor3 = C.textMuted
countLabel.TextSize = 12
countLabel.Font = Enum.Font.Arial
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = footer

local speedLabel = Instance.new("TextLabel")
speedLabel.BackgroundTransparency = 1
speedLabel.Size = UDim2.new(0, 72, 1, 0)
speedLabel.Position = UDim2.new(0, 118, 0, 0)
speedLabel.Text = "Speed: " .. tostring(autoSpeed)
speedLabel.TextColor3 = C.textMuted
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.Arial
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = footer

local stopBtn = makeButton(footer, "Stop", 42, C.panel2, C.text)
stopBtn.Position = UDim2.new(1, -92, 0, 5)
addDesktopHover(stopBtn, C.panel2, C.top, C.text, C.text)

local setBtn = makeButton(footer, "Set", 32, C.panel2, C.text)
setBtn.Position = UDim2.new(1, -46, 0, 5)
addDesktopHover(setBtn, C.panel2, C.top, C.text, C.text)

local function setEmpty(show)
    local old = logArea:FindFirstChild("EmptyState")
    if show and not old then
        local lbl = Instance.new("TextLabel")
        lbl.Name = "EmptyState"
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -4, 0, 80)
        lbl.Text = "Waiting for marketplace events"
        lbl.TextColor3 = C.textDim
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Arial
        lbl.Parent = logArea
    elseif not show and old then
        old:Destroy()
    end
end

local function fireFakeSignal(signalType, id)
    suppressCounter += 1
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
    suppressCounter -= 1
end

local function stopAllLoops()
    for btn, data in pairs(activeAuto) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"
            setButtonState(btn, C.panel2, C.text)
        end
    end
    table.clear(activeAuto)

    for btn, data in pairs(activeSpam) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Run"
            setButtonState(btn, C.panel2, C.text)
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

    sendWebhook(label, id) -- Fire Discord Webhook async

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, ROW_H)
    row.BackgroundColor3 = C.panel2
    row.BorderSizePixel = 0
    row.LayoutOrder = -(eventCount + 1)
    row.ClipsDescendants = true
    row.Parent = logArea
    bevel(row)

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 4, 1, 0)
    stripe.BackgroundColor3 = SIGNAL_COLORS[signalType] or C.blue
    stripe.BorderSizePixel = 0
    stripe.Parent = row

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Name = "TypeLabel"
    typeLabel.BackgroundTransparency = 1
    typeLabel.Size = UDim2.new(0, 62, 1, 0)
    typeLabel.Position = UDim2.new(0, 8, 0, 0)
    typeLabel.Text = label
    typeLabel.TextColor3 = C.textMuted
    typeLabel.TextSize = 12
    typeLabel.Font = Enum.Font.ArialBold
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = row

    local actionWidth = 106
    local idLabel = Instance.new("TextLabel")
    idLabel.Name = "IdLabel"
    idLabel.BackgroundTransparency = 1
    idLabel.Size = UDim2.new(1, -(78 + actionWidth), 1, 0)
    idLabel.Position = UDim2.new(0, 72, 0, 0)
    idLabel.Text = tostring(id)
    idLabel.TextColor3 = C.text
    idLabel.TextSize = 12
    idLabel.Font = Enum.Font.ArialBold
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.TextTruncate = Enum.TextTruncate.AtEnd
    idLabel.Parent = row

    local actions = Instance.new("Frame")
    actions.Size = UDim2.new(0, actionWidth, 1, 0)
    actions.Position = UDim2.new(1, -actionWidth, 0, 0)
    actions.BackgroundTransparency = 1
    actions.ClipsDescendants = true
    actions.Parent = row

    local copyBtn = makeButton(actions, "Copy", 32, C.panel, C.text)
    copyBtn.Position = UDim2.new(0, 0, 0, 3)
    addDesktopHover(copyBtn, C.panel, C.top, C.text, C.text)

    local autoBtn = makeButton(actions, "Auto", 32, C.panel, C.text)
    autoBtn.Position = UDim2.new(0, 36, 0, 3)
    addDesktopHover(autoBtn, C.panel, C.top, C.text, C.text)

    local runBtn = makeButton(actions, "Run", 32, C.panel, C.text)
    runBtn.Position = UDim2.new(0, 72, 0, 3)
    addDesktopHover(runBtn, C.panel, C.top, C.text, C.text)

    copyBtn.Activated:Connect(function()
        pcall(setclipboard, tostring(id))
        copyBtn.Text = "OK"
        setButtonState(copyBtn, C.green, C.text)
        task.wait(0.6)
        if copyBtn and copyBtn.Parent then
            copyBtn.Text = "Copy"
            setButtonState(copyBtn, C.panel, C.text)
        end
    end)

    local autoOn = false
    local autoLoop = nil

    local function startAuto()
        if autoOn then return end
        autoOn = true
        autoBtn.Text = "ON"
        setButtonState(autoBtn, C.red, C.text)
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
            setButtonState(autoBtn, C.panel, C.text)
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
        setButtonState(runBtn, C.yellow, C.text)
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
            setButtonState(runBtn, C.panel, C.text)
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
            setButtonState(runBtn, C.green, C.text)
            task.wait(0.5)
            if runBtn and runBtn.Parent then
                runBtn.Text = "Run"
                setButtonState(runBtn, C.panel, C.text)
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

    eventCount += 1
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
    countLabel.Text = "0 events"
    setEmpty(true)
end)

stopBtn.Activated:Connect(stopAllLoops)

local function toggleSettings()
    if settingsWindow then
        settingsWindow:Destroy()
        settingsWindow = nil
        return
    end

    -- Enlarged settings height to handle more control features comfortably (200 -> 240)
    settingsWindow = Instance.new("Frame")
    settingsWindow.Size = UDim2.new(0, 260, 0, 240)
    settingsWindow.Position = UDim2.new(0.5, -130, 0.5, -120)
    settingsWindow.BackgroundColor3 = C.bg
    settingsWindow.BorderSizePixel = 0
    settingsWindow.ZIndex = 200
    settingsWindow.Parent = screenGui
    settingsWindow.ClipsDescendants = true
    bevel(settingsWindow)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 24)
    top.BackgroundColor3 = C.top
    top.BorderSizePixel = 0
    top.ZIndex = 201
    top.Parent = settingsWindow
    bevel(top)

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Size = UDim2.new(1, -24, 1, 0)
    ttl.Position = UDim2.new(0, 6, 0, 0)
    ttl.Text = "Settings & Hook Setup"
    ttl.TextColor3 = C.text
    ttl.TextSize = 12
    ttl.Font = Enum.Font.ArialBold
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 202
    ttl.Parent = top

    local x = makeButton(top, "X", 18, C.red, C.text)
    x.Position = UDim2.new(1, -20, 0, 3)
    x.ZIndex = 202
    x.Activated:Connect(function()
        if settingsWindow then settingsWindow:Destroy(); settingsWindow = nil end
    end)

    -- Row 1: Spam speed configuration & Clip
    local speedLbl = Instance.new("TextLabel")
    speedLbl.BackgroundTransparency = 1
    speedLbl.Size = UDim2.new(0, 60, 0, 20)
    speedLbl.Position = UDim2.new(0, 8, 0, 32)
    speedLbl.Text = "Spam Speed:"
    speedLbl.TextColor3 = C.text
    speedLbl.TextSize = 11
    speedLbl.Font = Enum.Font.Arial
    speedLbl.TextXAlignment = Enum.TextXAlignment.Left
    speedLbl.ZIndex = 201
    speedLbl.Parent = settingsWindow

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 50, 0, 20)
    box.Position = UDim2.new(0, 74, 0, 32)
    box.BackgroundColor3 = C.panel
    box.Text = tostring(autoSpeed)
    box.TextColor3 = C.text
    box.TextSize = 12
    box.Font = Enum.Font.ArialBold
    box.BorderSizePixel = 0
    box.ZIndex = 201
    box.Parent = settingsWindow
    bevel(box)

    local save = makeButton(settingsWindow, "Save", 38, C.panel2, C.text)
    save.Position = UDim2.new(0, 128, 0, 32)
    save.ZIndex = 201

    local autoClipBtn = makeButton(settingsWindow, autoClipEnabled and "Clip: ON" or "Clip: OFF", 42, autoClipEnabled and C.green or C.panel2, C.text)
    autoClipBtn.Position = UDim2.new(0, 170, 0, 32)
    autoClipBtn.ZIndex = 201

    local antiBtn = makeButton(settingsWindow, antiPrompt and "Block: ON" or "Block: OFF", 40, antiPrompt and C.red or C.panel2, C.text)
    antiBtn.Position = UDim2.new(0, 216, 0, 32)
    antiBtn.ZIndex = 201

    save.Activated:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.floor(n)
            if n >= 1 and n <= 10000 then
                autoSpeed = n
                speedLabel.Text = "Speed: " .. tostring(autoSpeed)
                box.BackgroundColor3 = C.green
                saveConfig()
                task.wait(0.3)
                if box and box.Parent then box.BackgroundColor3 = C.panel end
            else
                box.BackgroundColor3 = C.red
                task.wait(0.3)
                if box and box.Parent then box.BackgroundColor3 = C.panel end
            end
        end
    end)

    autoClipBtn.Activated:Connect(function()
        autoClipEnabled = not autoClipEnabled
        autoClipBtn.Text = autoClipEnabled and "Clip: ON" or "Clip: OFF"
        setButtonState(autoClipBtn, autoClipEnabled and C.green or C.panel2, C.text)
        saveConfig()
    end)

    antiBtn.Activated:Connect(function()
        antiPrompt = not antiPrompt
        antiBtn.Text = antiPrompt and "Block: ON" or "Block: OFF"
        setButtonState(antiBtn, antiPrompt and C.red or C.panel2, C.text)
        saveConfig()
    end)

    -- Row 2: Discord Webhook configuration
    local webLbl = Instance.new("TextLabel")
    webLbl.BackgroundTransparency = 1
    webLbl.Size = UDim2.new(0, 80, 0, 20)
    webLbl.Position = UDim2.new(0, 8, 0, 56)
    webLbl.Text = "Webhook URL:"
    webLbl.TextColor3 = C.text
    webLbl.TextSize = 11
    webLbl.Font = Enum.Font.Arial
    webLbl.TextXAlignment = Enum.TextXAlignment.Left
    webLbl.ZIndex = 201
    webLbl.Parent = settingsWindow

    local webBox = Instance.new("TextBox")
    webBox.Size = UDim2.new(1, -114, 0, 20)
    webBox.Position = UDim2.new(0, 84, 0, 56)
    webBox.BackgroundColor3 = C.panel
    webBox.PlaceholderText = "Paste Discord webhook link..."
    webBox.PlaceholderColor3 = C.textDim
    webBox.Text = webhookUrl
    webBox.TextColor3 = C.text
    webBox.TextSize = 10
    webBox.Font = Enum.Font.Arial
    webBox.BorderSizePixel = 0
    webBox.ZIndex = 201
    webBox.Parent = settingsWindow
    bevel(webBox)
    pad(webBox, 4, 4, 0, 0)

    local saveWebBtn = makeButton(settingsWindow, "Apply", 38, C.panel2, C.text)
    saveWebBtn.Position = UDim2.new(1, -44, 0, 56)
    saveWebBtn.ZIndex = 201

    saveWebBtn.Activated:Connect(function()
        webhookUrl = webBox.Text
        saveConfig()
        saveWebBtn.Text = "OK"
        setButtonState(saveWebBtn, C.green, C.text)
        task.wait(0.5)
        if saveWebBtn and saveWebBtn.Parent then
            saveWebBtn.Text = "Apply"
            setButtonState(saveWebBtn, C.panel2, C.text)
        end
    end)

    -- Row 3: Manual creation / Blacklist control
    local manualTitle = Instance.new("TextLabel")
    manualTitle.BackgroundTransparency = 1
    manualTitle.Size = UDim2.new(1, -16, 0, 16)
    manualTitle.Position = UDim2.new(0, 8, 0, 84)
    manualTitle.Text = "Manual Entry Creator & Blacklist"
    manualTitle.TextColor3 = C.textMuted
    manualTitle.TextSize = 11
    manualTitle.Font = Enum.Font.ArialBold
    manualTitle.TextXAlignment = Enum.TextXAlignment.Left
    manualTitle.ZIndex = 201
    manualTitle.Parent = settingsWindow

    local targetIdBox = Instance.new("TextBox")
    targetIdBox.Size = UDim2.new(0, 140, 0, 20)
    targetIdBox.Position = UDim2.new(0, 8, 0, 104)
    targetIdBox.BackgroundColor3 = C.panel
    targetIdBox.PlaceholderText = "ID (e.g. 1234567)"
    targetIdBox.PlaceholderColor3 = C.textDim
    targetIdBox.Text = ""
    targetIdBox.TextColor3 = C.text
    targetIdBox.TextSize = 11
    targetIdBox.Font = Enum.Font.Arial
    targetIdBox.BorderSizePixel = 0
    targetIdBox.ZIndex = 201
    targetIdBox.Parent = settingsWindow
    bevel(targetIdBox)
    pad(targetIdBox, 4, 4, 0, 0)

    local typeToggle = "Product"
    local typeToggleBtn = makeButton(settingsWindow, "Type: Product", 100, C.panel2, C.text)
    typeToggleBtn.Position = UDim2.new(0, 152, 0, 104)
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
    end)

    local createBtn = makeButton(settingsWindow, "Add to Log Area", 112, C.green, C.text)
    createBtn.Position = UDim2.new(0, 8, 0, 130)
    createBtn.ZIndex = 201

    local blacklistBtn = makeButton(settingsWindow, "Block / Unblock ID", 128, C.red, C.text)
    blacklistBtn.Position = UDim2.new(0, 124, 0, 130)
    blacklistBtn.ZIndex = 201

    createBtn.Activated:Connect(function()
        local idVal = tonumber(targetIdBox.Text)
        if idVal then
            addLog(typeToggle, idVal, typeToggle)
            createBtn.Text = "Added!"
            task.wait(0.5)
            if createBtn and createBtn.Parent then createBtn.Text = "Add to Log Area" end
        else
            targetIdBox.BackgroundColor3 = C.red
            task.wait(0.3)
            if targetIdBox and targetIdBox.Parent then targetIdBox.BackgroundColor3 = C.panel end
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
            if blacklistBtn and blacklistBtn.Parent then blacklistBtn.Text = "Block / Unblock ID" end
        else
            targetIdBox.BackgroundColor3 = C.red
            task.wait(0.3)
            if targetIdBox and targetIdBox.Parent then targetIdBox.BackgroundColor3 = C.panel end
        end
    end)

    -- Read-only information hints at bottom of settings window
    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Size = UDim2.new(1, -16, 0, 60)
    infoLbl.Position = UDim2.new(0, 8, 0, 164)
    infoLbl.Text = "- Save configurations automatically.\n- Block: ON intercepts outbound prompts so the native UI doesn't display.\n- Discord webhook tracks intercepted events remotely."
    infoLbl.TextColor3 = C.textDim
    infoLbl.TextSize = 10
    infoLbl.Font = Enum.Font.Arial
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
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
            reopenButton = makeButton(playerGui, "P", 28, C.top, C.text)
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
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if uiVisible then hideGui() else showGui() end
        end
    end)
end

-- FEATURE: Metamethod Hooking for Outgoing Prompts (Anti-Prompt / Silent Capture)
-- This blocks actual prompt screens while silently extracting the asset ID to the log area.
local hookSuccess, hookErr = pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if self == MarketplaceService then
                if method == "PromptPurchase" and typeof(args[2]) == "number" then
                    task.spawn(addLog, "Purchase", args[2], "Purchase")
                    if antiPrompt then return end -- Silently capture and block output UI
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

-- Native fallback listeners if hooking isn't supported or active
MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Product", id, "Product") end
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
MarketplaceService.PromptBulkPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
end)
MarketplaceService.PromptPurchaseFinished:Connect(function(_, id)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)

setEmpty(true)
