local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local currentPlaceId = tostring(game.PlaceId)
local SAVE_FILE = "CoordinateUI.json"
local env = getgenv and getgenv() or _G

if env._CoordinateGuiCleanup then
	pcall(env._CoordinateGuiCleanup)
	env._CoordinateGuiCleanup = nil
end

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
	"AttackUI",
	"CoordinateUI",
	"StudioCoordinatePanel",
	"CoordinateReopenBtn"
})

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AttackUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.Parent = targetGuiParent

local isMobile = UserInputService.TouchEnabled
local uiVisible = true
local reopenButton = nil
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


local TITLE_H = 26
local RIBBON_H = 34
local FOOTER_H = 22
local BTN_H = 20
local ROW_H = 50

local MIN_W, MIN_H = 620, 260
local MAX_W, MAX_H = 920, 540

local filters = {}
local currentFilterId = currentPlaceId
local nextAlternateIndex = 1
local rowRefs = {}
local scrollIndex = 1

local function clamp(v, minV, maxV)
	return math.max(minV, math.min(maxV, v))
end

local function roundPos(n)
	return math.floor(n + 0.5)
end

local function canFileIO()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
end

local function normalizeEntry(entry, fallbackIndex)
	if type(entry) ~= "table" then
		entry = {}
	end

	local name = tostring(entry.name or ("Waypoint " .. tostring(fallbackIndex)))
	local pos = entry.pos

	if type(pos) ~= "table" then
		pos = {0, 0, 0}
	end

	return {
		name = name,
		pos = {
			tonumber(pos[1]) or 0,
			tonumber(pos[2]) or 0,
			tonumber(pos[3]) or 0,
		}
	}
end

local function normalizeDatabase(decoded)
	local result = {}
	if type(decoded) ~= "table" then
		return result
	end

	for placeId, list in pairs(decoded) do
		if type(list) == "table" then
			result[tostring(placeId)] = {}
			for i, entry in ipairs(list) do
				table.insert(result[tostring(placeId)], normalizeEntry(entry, i))
			end
		end
	end

	return result
end

local function saveDatabase()
	if not canFileIO() then
		return
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(filters)
	end)

	if ok and encoded then
		pcall(function()
			writefile(SAVE_FILE, encoded)
		end)
	end
end

local function loadDatabase()
	if not canFileIO() then
		return {}
	end

	local ok, data = pcall(function()
		if isfile(SAVE_FILE) then
			return readfile(SAVE_FILE)
		end
		return nil
	end)

	if not ok or not data or data == "" then
		return {}
	end

	local decodedOk, decoded = pcall(function()
		return HttpService:JSONDecode(data)
	end)

	if not decodedOk then
		return {}
	end

	return normalizeDatabase(decoded)
end

filters = loadDatabase()

local function ensureFilterExists(filterId)
	filterId = tostring(filterId or ""):gsub("%s+", "")
	if filterId == "" then
		filterId = currentPlaceId
	end
	if not filters[filterId] then
		filters[filterId] = {}
	end
	return filters[filterId]
end

if not filters[currentPlaceId] or #filters[currentPlaceId] == 0 then
	filters[currentPlaceId] = {
		{ name = "Spawn Area", pos = {0, 5, 0} },
		{ name = "Waypoint 2", pos = {500, 10, 500} },
	}
	saveDatabase()
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
	b.BorderSizePixel = StudioTheme.borderSize or (StudioTheme.isModern and 0 or 1)
	b.BorderColor3 = StudioTheme.border
	if StudioTheme.isModern then
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	end
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
panel.Name = "StudioCoordinatePanel"
panel.Size = UDim2.new(0, 660, 0, 290)
panel.Position = UDim2.new(0.5, -330, 0.5, -145)
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
panel.Active = true
panel.ClipsDescendants = true
panel.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(MIN_W, MIN_H)
sizeConstraint.MaxSize = Vector2.new(MAX_W, MAX_H)
sizeConstraint.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Name = "StudioTitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = StudioTheme.headerBg
titleBar.BorderSizePixel = 1
titleBar.BorderColor3 = StudioTheme.border
titleBar.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.Text = "Properties - Waypoints & Coordinates"
title.TextColor3 = StudioTheme.text
title.TextSize = 13
title.Font = ThemeFontSemibold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

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

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -8, 1, -(TITLE_H + FOOTER_H + 8))
content.Position = UDim2.new(0, 4, 0, TITLE_H + 4)
content.BackgroundTransparency = 1
content.Parent = panel

local ribbon = Instance.new("Frame")
ribbon.Name = "StudioRibbon"
ribbon.Size = UDim2.new(1, 0, 0, RIBBON_H)
ribbon.BackgroundColor3 = StudioTheme.panelAlt
ribbon.BorderSizePixel = 1
ribbon.BorderColor3 = StudioTheme.border
ribbon.Parent = content

local filterLabel = Instance.new("TextLabel")
filterLabel.BackgroundTransparency = 1
filterLabel.Size = UDim2.new(0, 52, 0, 22)
filterLabel.Position = UDim2.new(0, 6, 0, 6)
filterLabel.Text = "Place ID:"
filterLabel.TextColor3 = StudioTheme.textMuted
filterLabel.TextSize = 12
filterLabel.Font = ThemeFontSemibold
filterLabel.TextXAlignment = Enum.TextXAlignment.Left
filterLabel.Parent = ribbon

local filterBox = makeStudioTextBox(ribbon, currentFilterId, 120, 22, "Target PlaceId", true)
filterBox.Position = UDim2.new(0, 60, 0, 6)

local currentGameBtn = makeStudioButton(ribbon, "Current", 64, 22, StudioTheme.btnBg, StudioTheme.text)
currentGameBtn.Position = UDim2.new(0, 186, 0, 6)

local divider1 = Instance.new("Frame")
divider1.Size = UDim2.new(0, 1, 0, 20)
divider1.Position = UDim2.new(0, 256, 0, 7)
divider1.BackgroundColor3 = StudioTheme.borderSubtle
divider1.BorderSizePixel = 0
divider1.Parent = ribbon

local addCoordBtn = makeStudioButton(ribbon, "+ Waypoint", 88, 22, StudioTheme.blue, Color3.fromRGB(255, 255, 255))
addCoordBtn.Position = UDim2.new(0, 264, 0, 6)

local alternateBtn = makeStudioButton(ribbon, "Cycle Next", 76, 22, StudioTheme.btnBg, StudioTheme.yellow)
alternateBtn.Position = UDim2.new(0, 358, 0, 6)

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -450, 0, 22)
infoLabel.Position = UDim2.new(0, 444, 0, 6)
infoLabel.Text = ""
infoLabel.TextColor3 = StudioTheme.textMuted
infoLabel.TextSize = 12
infoLabel.Font = ThemeFont
infoLabel.TextXAlignment = Enum.TextXAlignment.Right
infoLabel.Parent = ribbon

local categoryBar = Instance.new("Frame")
categoryBar.Size = UDim2.new(1, 0, 0, 20)
categoryBar.Position = UDim2.new(0, 0, 0, RIBBON_H + 3)
categoryBar.BackgroundColor3 = StudioTheme.panelBg
categoryBar.BorderSizePixel = 1
categoryBar.BorderColor3 = StudioTheme.border
categoryBar.Parent = content

local catArrow = Instance.new("TextLabel")
catArrow.BackgroundTransparency = 1
catArrow.Size = UDim2.new(0, 16, 1, 0)
catArrow.Position = UDim2.new(0, 4, 0, 0)
catArrow.Text = "v"
catArrow.TextColor3 = StudioTheme.textMuted
catArrow.TextSize = 10
catArrow.Font = ThemeFontBold
catArrow.Parent = categoryBar

local catTitle = Instance.new("TextLabel")
catTitle.BackgroundTransparency = 1
catTitle.Size = UDim2.new(1, -24, 1, 0)
catTitle.Position = UDim2.new(0, 18, 0, 0)
catTitle.Text = "Active Waypoints Table"
catTitle.TextColor3 = StudioTheme.text
catTitle.TextSize = 11
catTitle.Font = ThemeFontBold
catTitle.TextXAlignment = Enum.TextXAlignment.Left
catTitle.Parent = categoryBar

local listViewport = Instance.new("Frame")
listViewport.Name = "StudioListViewport"
listViewport.Size = UDim2.new(1, 0, 1, -(RIBBON_H + 26))
listViewport.Position = UDim2.new(0, 0, 0, RIBBON_H + 25)
listViewport.BackgroundColor3 = StudioTheme.insetBg
listViewport.BorderSizePixel = 1
listViewport.BorderColor3 = StudioTheme.border
listViewport.ClipsDescendants = true
listViewport.Parent = content

local rowsHolder = Instance.new("Frame")
rowsHolder.Size = UDim2.new(1, 0, 1, 0)
rowsHolder.BackgroundTransparency = 1
rowsHolder.Parent = listViewport

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = rowsHolder

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)
padding.Parent = rowsHolder

local scrollUpBtn = makeStudioButton(listViewport, "^", 20, 18, StudioTheme.headerBg, StudioTheme.text)
scrollUpBtn.Position = UDim2.new(1, -23, 0, 3)

local scrollDownBtn = makeStudioButton(listViewport, "v", 20, 18, StudioTheme.headerBg, StudioTheme.text)
scrollDownBtn.Position = UDim2.new(1, -23, 0, 23)

local footer = Instance.new("Frame")
footer.Name = "StudioFooter"
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = StudioTheme.headerBg
footer.BorderSizePixel = 1
footer.BorderColor3 = StudioTheme.border
footer.Parent = panel

local saveStatus = Instance.new("TextLabel")
saveStatus.BackgroundTransparency = 1
saveStatus.Size = UDim2.new(1, -40, 1, 0)
saveStatus.Position = UDim2.new(0, 8, 0, 0)
saveStatus.Text = canFileIO() and ("Database: " .. SAVE_FILE .. " (Active)") or "File save unavailable in this executor"
saveStatus.TextColor3 = StudioTheme.textDim
saveStatus.TextSize = 11
saveStatus.Font = ThemeFont
saveStatus.TextXAlignment = Enum.TextXAlignment.Left
saveStatus.Parent = footer

local resizeGrip = Instance.new("TextButton")
resizeGrip.Size = UDim2.new(0, 18, 0, 18)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.Position = UDim2.new(1, -1, 1, -1)
resizeGrip.BackgroundColor3 = StudioTheme.headerBg
resizeGrip.BorderSizePixel = 0
resizeGrip.Text = "//"
resizeGrip.TextColor3 = StudioTheme.textDim
resizeGrip.TextSize = 11
resizeGrip.Font = ThemeFontBold
resizeGrip.Parent = panel

local resizing = false
local resizeStartMouse
local resizeStartSize

resizeGrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStartMouse = input.Position
		resizeStartSize = panel.AbsoluteSize
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - resizeStartMouse
		local newW = clamp(resizeStartSize.X + delta.X, MIN_W, MAX_W)
		local newH = clamp(resizeStartSize.Y + delta.Y, MIN_H, MAX_H)
		panel.Size = UDim2.new(0, newW, 0, newH)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end)

local function getActiveList()
	return ensureFilterExists(currentFilterId)
end

local function getVisibleCapacity()
	local usableHeight = math.max(0, listViewport.AbsoluteSize.Y - 8)
	return math.max(1, math.floor(usableHeight / (ROW_H + 4)))
end

local function getCurrentHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:FindFirstChild("HumanoidRootPart")
end

local function teleportToEntry(entry)
	local hrp = getCurrentHRP()
	if not hrp then return end
	hrp.CFrame = CFrame.new(entry.pos[1], entry.pos[2], entry.pos[3])
end

local function updateInfo()
	local list = getActiveList()
	local capacity = getVisibleCapacity()
	local maxStart = math.max(1, #list - capacity + 1)

	scrollIndex = clamp(scrollIndex, 1, maxStart)
	infoLabel.Text = string.format("Filter: %s  |  Entries: %d", currentFilterId, #list)
	scrollUpBtn.Visible = #list > capacity
	scrollDownBtn.Visible = #list > capacity
end

local function saveRow(row)
	row.entry.name = row.nameBox.Text ~= "" and row.nameBox.Text or "Waypoint"
	row.entry.pos = {
		tonumber(row.xBox.Text) or 0,
		tonumber(row.yBox.Text) or 0,
		tonumber(row.zBox.Text) or 0,
	}
end

local function saveAllRows()
	for _, row in ipairs(rowRefs) do
		saveRow(row)
	end
	saveDatabase()
end

local function rebuildRows()
	for _, row in ipairs(rowRefs) do
		if row.frame and row.frame.Parent then
			row.frame:Destroy()
		end
	end
	table.clear(rowRefs)

	local list = getActiveList()
	local capacity = getVisibleCapacity()
	local maxStart = math.max(1, #list - capacity + 1)
	scrollIndex = clamp(scrollIndex, 1, maxStart)

	local lastIndex = math.min(#list, scrollIndex + capacity - 1)

	for i = scrollIndex, lastIndex do
		local entry = list[i]
		local isAlt = (i % 2 == 0)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, ROW_H)
		row.BackgroundColor3 = isAlt and StudioTheme.panelBg or StudioTheme.windowBg
		row.BorderSizePixel = 1
		row.BorderColor3 = StudioTheme.border
		row.Parent = rowsHolder

		local ind = Instance.new("Frame")
		ind.Size = UDim2.new(0, 3, 1, 0)
		ind.BackgroundColor3 = StudioTheme.blue
		ind.BorderSizePixel = 0
		ind.Parent = row

		local nameTag = Instance.new("TextLabel")
		nameTag.BackgroundTransparency = 1
		nameTag.Size = UDim2.new(0, 38, 0, 20)
		nameTag.Position = UDim2.new(0, 8, 0, 3)
		nameTag.Text = "Name:"
		nameTag.TextColor3 = StudioTheme.textMuted
		nameTag.TextSize = 11
		nameTag.Font = ThemeFontSemibold
		nameTag.TextXAlignment = Enum.TextXAlignment.Left
		nameTag.Parent = row

		local nameBox = makeStudioTextBox(row, entry.name, 140, 20, "Waypoint Name", false)
		nameBox.Position = UDim2.new(0, 48, 0, 3)

		local renameBtn = makeStudioButton(row, "Rename", 54, 20, StudioTheme.btnBg, StudioTheme.text)
		renameBtn.Position = UDim2.new(0, 194, 0, 3)

		local xLbl = Instance.new("TextLabel")
		xLbl.BackgroundTransparency = 1
		xLbl.Size = UDim2.new(0, 14, 0, 20)
		xLbl.Position = UDim2.new(0, 8, 0, 26)
		xLbl.Text = "X:"
		xLbl.TextColor3 = StudioTheme.textDim
		xLbl.TextSize = 11
		xLbl.Font = ThemeFontBold
		xLbl.Parent = row

		local xBox = makeStudioTextBox(row, tostring(entry.pos[1]), 50, 20, "0", true)
		xBox.Position = UDim2.new(0, 24, 0, 26)

		local yLbl = Instance.new("TextLabel")
		yLbl.BackgroundTransparency = 1
		yLbl.Size = UDim2.new(0, 14, 0, 20)
		yLbl.Position = UDim2.new(0, 80, 0, 26)
		yLbl.Text = "Y:"
		yLbl.TextColor3 = StudioTheme.textDim
		yLbl.TextSize = 11
		yLbl.Font = ThemeFontBold
		yLbl.Parent = row

		local yBox = makeStudioTextBox(row, tostring(entry.pos[2]), 50, 20, "0", true)
		yBox.Position = UDim2.new(0, 96, 0, 26)

		local zLbl = Instance.new("TextLabel")
		zLbl.BackgroundTransparency = 1
		zLbl.Size = UDim2.new(0, 14, 0, 20)
		zLbl.Position = UDim2.new(0, 152, 0, 26)
		zLbl.Text = "Z:"
		zLbl.TextColor3 = StudioTheme.textDim
		zLbl.TextSize = 11
		zLbl.Font = ThemeFontBold
		zLbl.Parent = row

		local zBox = makeStudioTextBox(row, tostring(entry.pos[3]), 50, 20, "0", true)
		zBox.Position = UDim2.new(0, 168, 0, 26)

		local currentBtn = makeStudioButton(row, "Get Pos", 58, 20, StudioTheme.btnBg, StudioTheme.text)
		currentBtn.Position = UDim2.new(0, 224, 0, 26)

		local tpBtn = makeStudioButton(row, "Teleport", 62, 20, StudioTheme.blue, Color3.fromRGB(255, 255, 255))
		tpBtn.Position = UDim2.new(0, 288, 0, 26)

		local delBtn = makeStudioButton(row, "Delete", 52, 20, StudioTheme.btnBg, StudioTheme.red)
		delBtn.Position = UDim2.new(0, 356, 0, 26)

		local rowRef = {
			frame = row,
			entry = entry,
			nameBox = nameBox,
			xBox = xBox,
			yBox = yBox,
			zBox = zBox,
		}

		for _, box in ipairs({nameBox, xBox, yBox, zBox}) do
			box.FocusLost:Connect(function()
				saveRow(rowRef)
				saveDatabase()
				updateInfo()
			end)
		end

		renameBtn.Activated:Connect(function()
			saveRow(rowRef)
			entry.name = nameBox.Text ~= "" and nameBox.Text or ("Waypoint " .. i)
			nameBox.Text = entry.name
			saveDatabase()
			updateInfo()
		end)

		currentBtn.Activated:Connect(function()
			local hrp = getCurrentHRP()
			if not hrp then return end
			xBox.Text = tostring(roundPos(hrp.Position.X))
			yBox.Text = tostring(roundPos(hrp.Position.Y))
			zBox.Text = tostring(roundPos(hrp.Position.Z))
			saveRow(rowRef)
			saveDatabase()
			updateInfo()
		end)

		tpBtn.Activated:Connect(function()
			saveRow(rowRef)
			saveDatabase()
			teleportToEntry(entry)
		end)

		delBtn.Activated:Connect(function()
			table.remove(list, i)
			if nextAlternateIndex > #list then
				nextAlternateIndex = 1
			end
			saveDatabase()
			rebuildRows()
		end)

		table.insert(rowRefs, rowRef)
	end

	updateInfo()
end

local function loadFilter(filterId)
	saveAllRows()
	currentFilterId = tostring(filterId or ""):gsub("%s+", "")
	if currentFilterId == "" then
		currentFilterId = currentPlaceId
	end
	filterBox.Text = currentFilterId
	ensureFilterExists(currentFilterId)
	scrollIndex = 1
	if nextAlternateIndex > #getActiveList() then
		nextAlternateIndex = 1
	end
	rebuildRows()
end

currentGameBtn.Activated:Connect(function()
	loadFilter(currentPlaceId)
end)

filterBox.FocusLost:Connect(function()
	local typed = tostring(filterBox.Text or ""):gsub("%s+", "")
	if typed == "" then
		typed = currentPlaceId
	end
	loadFilter(typed)
end)

addCoordBtn.Activated:Connect(function()
	saveAllRows()
	local list = getActiveList()
	table.insert(list, {
		name = "Waypoint " .. tostring(#list + 1),
		pos = {0, 0, 0},
	})
	saveDatabase()
	rebuildRows()
end)

alternateBtn.Activated:Connect(function()
	saveAllRows()
	local list = getActiveList()
	if #list == 0 then return end

	if nextAlternateIndex > #list then
		nextAlternateIndex = 1
	end

	local entry = list[nextAlternateIndex]
	teleportToEntry(entry)

	nextAlternateIndex = nextAlternateIndex + 1
	if nextAlternateIndex > #list then
		nextAlternateIndex = 1
	end
end)

scrollUpBtn.Activated:Connect(function()
	local capacity = getVisibleCapacity()
	local list = getActiveList()
	if #list <= capacity then return end
	scrollIndex = math.max(1, scrollIndex - 1)
	rebuildRows()
end)

scrollDownBtn.Activated:Connect(function()
	local capacity = getVisibleCapacity()
	local list = getActiveList()
	if #list <= capacity then return end
	local maxStart = math.max(1, #list - capacity + 1)
	scrollIndex = math.min(maxStart, scrollIndex + 1)
	rebuildRows()
end)

listViewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	rebuildRows()
end)

loadFilter(currentPlaceId)

local function showGui()
	screenGui.Enabled = true
	uiVisible = true
	if reopenButton then
		reopenButton.Visible = false
	end
end

local function hideGui()
	screenGui.Enabled = false
	uiVisible = false

	if isMobile then
		if not reopenButton or not reopenButton.Parent then
			reopenButton = makeStudioButton(targetGuiParent, "P", 28, 28, StudioTheme.headerBg, StudioTheme.text)
			reopenButton.Name = "CoordinateReopenBtn"
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
							reopenButton.Position = UDim2.new(
								startPos.X.Scale,
								startPos.X.Offset + delta.X,
								startPos.Y.Scale,
								startPos.Y.Offset + delta.Y
							)
						end
					end)

					endConn = UserInputService.InputEnded:Connect(function(ended)
						if ended.UserInputType == input.UserInputType then
							moveConn:Disconnect()
							endConn:Disconnect()
							if not moved then
								showGui()
							end
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
	local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			if uiVisible then
				hideGui()
			else
				showGui()
			end
		end
	end)
	table.insert(activeConnections, keyConn)
end

env._CoordinateGuiCleanup = function()
	for _, conn in ipairs(activeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(activeConnections)
	cleanAllPreviousInstances({
		"AttackUI",
		"CoordinateUI",
		"StudioCoordinatePanel",
		"CoordinateReopenBtn"
	})
end
