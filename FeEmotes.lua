if game.PlaceId == 3095204897 then
	return
end

local env = getgenv and getgenv() or _G

if env._EmoteHubCleanup then
	pcall(env._EmoteHubCleanup)
	env._EmoteHubCleanup = nil
end

if env.LastExecuted and tick() - env.LastExecuted < 5 then return end
env.LastExecuted = tick()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
	local success, core = pcall(function()
		return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or game:GetService("CoreGui")
	end)
	if success and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local targetGuiParent = getGuiParent()

local function cleanAllPreviousInstances(names)
	local containers = {}
	pcall(function() if gethui then table.insert(containers, gethui()) end end)
	pcall(function() if get_hidden_gui then table.insert(containers, get_hidden_gui()) end end)
	pcall(function() table.insert(containers, game:GetService("CoreGui")) end)
	pcall(function() if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then table.insert(containers, LocalPlayer.PlayerGui) end end)

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
	"StudioEmoteHub",
	"BevelEmoteHub",
	"PotassiumEmoteHub"
})

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


local Emotes = {}
local FavoritedEmotes = {}
local catalogPages = nil
local isLoadingMore = false
local FetchDebounce = false

local EmoteCache = {} 
local LoopEmotes = true
local currentEmoteTrack = nil
local forceEmote = false
local activeEmoteName = "None"
local activeConnections = {}
local RefreshFavorites
local updateAllCardsFavVisuals
local updateAllSelectionVisuals
local currentPlayingEmoteId = nil

local function safeGetClipboard()
	local clip = nil
	pcall(function()
		if getclipboard then
			clip = getclipboard()
		elseif get_clipboard then
			clip = get_clipboard()
		elseif syn and syn.get_clipboard then
			clip = syn.get_clipboard()
		end
	end)
	return (type(clip) == "string" and clip ~= "") and clip or nil
end

local function extractId(input)
	if not input then return nil end
	local str = tostring(input)
	local idStr = str:match("(%d+)")
	return tonumber(idStr)
end

local function normalizeFavEmotes(rawList)
	local normalized = {}
	if type(rawList) ~= "table" then return normalized end
	for _, item in ipairs(rawList) do
		if type(item) == "number" then
			table.insert(normalized, { id = item, name = "Saved Emote" })
		elseif type(item) == "table" and item.id then
			table.insert(normalized, { id = tonumber(item.id), name = tostring(item.name or "Saved Emote") })
		end
	end
	return normalized
end

if isfile and isfile("FavoritedEmotes.txt") then
	local succ, res = pcall(function()
		return HttpService:JSONDecode(readfile("FavoritedEmotes.txt"))
	end)
	if succ and type(res) == "table" then
		FavoritedEmotes = normalizeFavEmotes(res)
	end
end

local function SaveFavorites()
	if writefile then
		pcall(writefile, "FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
end

local function isEmoteFav(id)
	id = tonumber(id)
	if not id then return false end
	for _, fav in ipairs(FavoritedEmotes) do
		local favId = type(fav) == "table" and tonumber(fav.id) or tonumber(fav)
		if favId == id then return true end
	end
	return false
end

local function toggleFav(id, name)
	id = tonumber(id)
	if not id then return end
	local foundIdx = nil
	for idx, fav in ipairs(FavoritedEmotes) do
		local favId = type(fav) == "table" and tonumber(fav.id) or tonumber(fav)
		if favId == id then
			foundIdx = idx
			break
		end
	end
	if foundIdx then
		table.remove(FavoritedEmotes, foundIdx)
	else
		table.insert(FavoritedEmotes, { id = id, name = (name and name ~= "" and name ~= "Saved Emote") and name or "Saved Emote" })
	end
	SaveFavorites()
	if RefreshFavorites then RefreshFavorites() end
	if updateAllCardsFavVisuals then updateAllCardsFavVisuals() end
end

local function StopEmote()
	forceEmote = false
	activeEmoteName = "None"
	if currentEmoteTrack then
		currentEmoteTrack:Stop()
		currentEmoteTrack = nil
	end
	currentPlayingEmoteId = nil
	if updateAllSelectionVisuals then updateAllSelectionVisuals() end
end

local function makeStudioButton(parent, text, w, h, bg, fg)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, h or 22)
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
	b.ClipsDescendants = true
	b.Parent = parent

	local defaultBg = bg or StudioTheme.btnBg
	local hoverBg = (bg == StudioTheme.blue and StudioTheme.blueHover)
		or (bg == StudioTheme.red and StudioTheme.redHover)
		or (bg == StudioTheme.green and StudioTheme.greenHover)
		or StudioTheme.btnHover

	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = hoverBg
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = defaultBg
	end)

	return b
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioEmoteHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = targetGuiParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 510, 0, 440)
MainFrame.Position = UDim2.new(0.5, -255, 0.5, -220)
MainFrame.BackgroundColor3 = StudioTheme.windowBg
if StudioTheme.isModern then
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", MainFrame)
    s.Color = StudioTheme.border
    s.Thickness = 1
else
    MainFrame.BorderSizePixel = 1
    MainFrame.BorderColor3 = StudioTheme.border
end
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 26)
TopBar.BackgroundColor3 = StudioTheme.headerBg
TopBar.BorderSizePixel = 1
TopBar.BorderColor3 = StudioTheme.border
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Toolbox - Animation & Emote Explorer"
Title.TextColor3 = StudioTheme.text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = ThemeFontSemibold
Title.TextSize = 13
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 1, 0)
CloseBtn.Position = UDim2.new(1, -26, 0, 0)
CloseBtn.BackgroundColor3 = StudioTheme.headerBg
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = StudioTheme.textMuted
CloseBtn.Font = ThemeFontBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar

CloseBtn.MouseEnter:Connect(function()
	CloseBtn.BackgroundColor3 = StudioTheme.red
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
CloseBtn.MouseLeave:Connect(function()
	CloseBtn.BackgroundColor3 = StudioTheme.headerBg
	CloseBtn.TextColor3 = StudioTheme.textMuted
end)
CloseBtn.Activated:Connect(function()
	MainFrame.Visible = false
end)

local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
TopBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local TabStrip = Instance.new("Frame")
TabStrip.Name = "TabStrip"
TabStrip.Size = UDim2.new(1, 0, 0, 26)
TabStrip.Position = UDim2.new(0, 0, 0, 26)
TabStrip.BackgroundColor3 = StudioTheme.tabInactive
TabStrip.BorderSizePixel = 1
TabStrip.BorderColor3 = StudioTheme.border
TabStrip.Parent = MainFrame

local CatalogTabBtn = Instance.new("TextButton")
CatalogTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
CatalogTabBtn.Position = UDim2.new(0, 0, 0, 0)
CatalogTabBtn.BackgroundColor3 = StudioTheme.tabActive
CatalogTabBtn.BorderSizePixel = 1
CatalogTabBtn.BorderColor3 = StudioTheme.border
CatalogTabBtn.Text = "Catalog Animations"
CatalogTabBtn.TextColor3 = StudioTheme.text
CatalogTabBtn.Font = ThemeFontSemibold
CatalogTabBtn.TextSize = 12
CatalogTabBtn.Parent = TabStrip

local CatalogTabAccent = Instance.new("Frame")
CatalogTabAccent.Size = UDim2.new(1, 0, 0, 2)
CatalogTabAccent.Position = UDim2.new(0, 0, 0, 0)
CatalogTabAccent.BackgroundColor3 = StudioTheme.blue
CatalogTabAccent.BorderSizePixel = 0
CatalogTabAccent.Parent = CatalogTabBtn

local FavTabBtn = Instance.new("TextButton")
FavTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
FavTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
FavTabBtn.BackgroundColor3 = StudioTheme.tabInactive
FavTabBtn.BorderSizePixel = 1
FavTabBtn.BorderColor3 = StudioTheme.border
FavTabBtn.Text = "Favorites"
FavTabBtn.TextColor3 = StudioTheme.textMuted
FavTabBtn.Font = ThemeFontSemibold
FavTabBtn.TextSize = 12
FavTabBtn.Parent = TabStrip

local FavTabAccent = Instance.new("Frame")
FavTabAccent.Size = UDim2.new(1, 0, 0, 2)
FavTabAccent.Position = UDim2.new(0, 0, 0, 0)
FavTabAccent.BackgroundColor3 = StudioTheme.blue
FavTabAccent.BorderSizePixel = 0
FavTabAccent.Visible = false
FavTabAccent.Parent = FavTabBtn

local FOOTER_H = 22
local CatalogContainer = Instance.new("Frame")
CatalogContainer.Size = UDim2.new(1, -8, 1, -(52 + FOOTER_H + 8))
CatalogContainer.Position = UDim2.new(0, 4, 0, 56)
CatalogContainer.BackgroundTransparency = 1
CatalogContainer.Parent = MainFrame

local FavContainer = Instance.new("Frame")
FavContainer.Size = UDim2.new(1, -8, 1, -(52 + FOOTER_H + 8))
FavContainer.Position = UDim2.new(0, 4, 0, 56)
FavContainer.BackgroundTransparency = 1
FavContainer.Visible = false
FavContainer.Parent = MainFrame

local function selectTab(isCatalog)
	CatalogContainer.Visible = isCatalog
	FavContainer.Visible = not isCatalog
	CatalogTabBtn.BackgroundColor3 = isCatalog and StudioTheme.tabActive or StudioTheme.tabInactive
	CatalogTabBtn.TextColor3 = isCatalog and StudioTheme.text or StudioTheme.textMuted
	CatalogTabAccent.Visible = isCatalog

	FavTabBtn.BackgroundColor3 = (not isCatalog) and StudioTheme.tabActive or StudioTheme.tabInactive
	FavTabBtn.TextColor3 = (not isCatalog) and StudioTheme.text or StudioTheme.textMuted
	FavTabAccent.Visible = not isCatalog

	if not isCatalog then
		if RefreshFavorites then RefreshFavorites() end
	else
		if updateAllCardsFavVisuals then updateAllCardsFavVisuals() end
	end
end

CatalogTabBtn.MouseButton1Click:Connect(function() selectTab(true) end)
FavTabBtn.MouseButton1Click:Connect(function() selectTab(false) end)

local CatToolbar = Instance.new("Frame")
CatToolbar.Size = UDim2.new(1, 0, 0, 32)
CatToolbar.BackgroundColor3 = StudioTheme.panelAlt
CatToolbar.BorderSizePixel = 1
CatToolbar.BorderColor3 = StudioTheme.border
CatToolbar.Parent = CatalogContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0, 160, 0, 22)
SearchBox.Position = UDim2.new(0, 6, 0, 5)
SearchBox.BackgroundColor3 = StudioTheme.insetBg
SearchBox.TextColor3 = StudioTheme.text
SearchBox.PlaceholderText = "Search or Paste ID..."
SearchBox.PlaceholderColor3 = StudioTheme.textDim
SearchBox.Font = ThemeFont
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 1
SearchBox.BorderColor3 = StudioTheme.border
SearchBox.Parent = CatToolbar

local PasteCatBtn = makeStudioButton(CatToolbar, "Paste ID", 68, 22, StudioTheme.btnBg, StudioTheme.text)
PasteCatBtn.Position = UDim2.new(0, 172, 0, 5)

local LoopCatBtn = makeStudioButton(CatToolbar, "Loop: ON", 80, 22, StudioTheme.green, Color3.fromRGB(255, 255, 255))
LoopCatBtn.Position = UDim2.new(0, 246, 0, 5)

local RandomCatBtn = makeStudioButton(CatToolbar, "Random", 70, 22, StudioTheme.btnBg, StudioTheme.text)
RandomCatBtn.Position = UDim2.new(0, 332, 0, 5)

local StopCatBtn = makeStudioButton(CatToolbar, "Stop", 55, 22, StudioTheme.red, Color3.fromRGB(255, 255, 255))
StopCatBtn.Position = UDim2.new(0, 408, 0, 5)
StopCatBtn.MouseButton1Click:Connect(StopEmote)

local FavToolbar = Instance.new("Frame")
FavToolbar.Size = UDim2.new(1, 0, 0, 32)
FavToolbar.BackgroundColor3 = StudioTheme.panelAlt
FavToolbar.BorderSizePixel = 1
FavToolbar.BorderColor3 = StudioTheme.border
FavToolbar.Parent = FavContainer

local LoopFavBtn = makeStudioButton(FavToolbar, "Loop: ON", 80, 22, StudioTheme.green, Color3.fromRGB(255, 255, 255))
LoopFavBtn.Position = UDim2.new(0, 6, 0, 5)

local RandomFavBtn = makeStudioButton(FavToolbar, "Play Random", 88, 22, StudioTheme.btnBg, StudioTheme.text)
RandomFavBtn.Position = UDim2.new(0, 92, 0, 5)

local PasteFavBtn = makeStudioButton(FavToolbar, "+ Paste ID", 78, 22, StudioTheme.btnBg, StudioTheme.text)
PasteFavBtn.Position = UDim2.new(0, 186, 0, 5)

local StopFavBtn = makeStudioButton(FavToolbar, "Stop", 55, 22, StudioTheme.red, Color3.fromRGB(255, 255, 255))
StopFavBtn.Position = UDim2.new(0, 270, 0, 5)
StopFavBtn.MouseButton1Click:Connect(StopEmote)

local function UpdateLoopState()
	local txt = LoopEmotes and "Loop: ON" or "Loop: OFF"
	local bg = LoopEmotes and StudioTheme.green or StudioTheme.btnBg
	local fg = LoopEmotes and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted
	LoopCatBtn.Text = txt
	LoopCatBtn.BackgroundColor3 = bg
	LoopCatBtn.TextColor3 = fg
	LoopFavBtn.Text = txt
	LoopFavBtn.BackgroundColor3 = bg
	LoopFavBtn.TextColor3 = fg
	if currentEmoteTrack then
		currentEmoteTrack.Looped = LoopEmotes
	end
end

LoopCatBtn.MouseButton1Click:Connect(function()
	LoopEmotes = not LoopEmotes
	UpdateLoopState()
end)

LoopFavBtn.MouseButton1Click:Connect(function()
	LoopEmotes = not LoopEmotes
	UpdateLoopState()
end)

local function CreateScrollFrame(parent)
	local Wrapper = Instance.new("Frame")
	Wrapper.Size = UDim2.new(1, 0, 1, -38)
	Wrapper.Position = UDim2.new(0, 0, 0, 36)
	Wrapper.BackgroundColor3 = StudioTheme.insetBg
	Wrapper.BorderSizePixel = 1
	Wrapper.BorderColor3 = StudioTheme.border
	Wrapper.ClipsDescendants = true
	Wrapper.Parent = parent

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -2, 1, -2)
	Scroll.Position = UDim2.new(0, 1, 0, 1)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 5
	Scroll.ScrollBarImageColor3 = StudioTheme.borderSubtle
	Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.ClipsDescendants = true
	Scroll.Parent = Wrapper

	local Grid = Instance.new("UIGridLayout")
	Grid.CellSize = UDim2.new(0, 92, 0, 116)
	Grid.CellPadding = UDim2.new(0, 6, 0, 6)
	Grid.SortOrder = Enum.SortOrder.LayoutOrder
	Grid.Parent = Scroll

	local Pad = Instance.new("UIPadding")
	Pad.PaddingTop = UDim.new(0, 6)
	Pad.PaddingBottom = UDim.new(0, 6)
	Pad.PaddingLeft = UDim.new(0, 6)
	Pad.PaddingRight = UDim.new(0, 6)
	Pad.Parent = Scroll

	return Scroll
end

local CatScroll = CreateScrollFrame(CatalogContainer)
local FavScroll = CreateScrollFrame(FavContainer)

local Footer = Instance.new("Frame")
Footer.Name = "StudioFooter"
Footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
Footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
Footer.BackgroundColor3 = StudioTheme.headerBg
Footer.BorderSizePixel = 1
Footer.BorderColor3 = StudioTheme.border
Footer.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, -12, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.Text = "Shortcuts: [ , ] Toggle UI  |  [ X ] Stop Emote  |  Status: Ready"
StatusLabel.TextColor3 = StudioTheme.textDim
StatusLabel.TextSize = 11
StatusLabel.Font = ThemeFont
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Footer

local function ResolveEmoteName(id)
	id = tonumber(id)
	if not id then return "Custom Emote" end

	for _, e in ipairs(Emotes) do
		if e.id == id and e.name and e.name ~= "" and e.name ~= "Saved Emote" and e.name ~= "Custom Emote" then
			return e.name
		end
	end

	local succ, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(id, Enum.InfoType.Asset)
	end)
	if succ and info and info.Name and info.Name ~= "" then
		return info.Name
	end

	return "Emote #" .. tostring(id)
end

local function GetRawEmoteId(catalogId, name)
	if EmoteCache[catalogId] then return EmoteCache[catalogId] end

	local s1, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(catalogId)) end)
	if s1 and objs and objs[1] then
		local anim = objs[1]:FindFirstChildOfClass("Animation", true) or (objs[1]:IsA("Animation") and objs[1])
		if anim and anim.AnimationId and anim.AnimationId ~= "" then
			EmoteCache[catalogId] = anim.AnimationId
			return anim.AnimationId
		end
	end

	local s2, asset = pcall(function() return game:GetService("InsertService"):LoadAsset(catalogId) end)
	if s2 and asset then
		local anim = asset:FindFirstChildOfClass("Animation", true) or (asset:IsA("Animation") and asset)
		if anim and anim.AnimationId and anim.AnimationId ~= "" then
			EmoteCache[catalogId] = anim.AnimationId
			return anim.AnimationId
		end
	end

	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local desc = hum and hum:FindFirstChildOfClass("HumanoidDescription")
		if hum and desc then
			local s3, r1, r2 = pcall(function()
				desc:AddEmote(name or "Emote", catalogId)
				return hum:PlayEmoteAndGetAnimTrackById(catalogId)
			end)
			local track = (typeof(r1) == "Instance" and r1:IsA("AnimationTrack") and r1) or (typeof(r2) == "Instance" and r2:IsA("AnimationTrack") and r2)
			if track then
				local rawId = track.Animation.AnimationId
				track:Stop()
				EmoteCache[catalogId] = rawId
				return rawId
			end
		end
	end

	-- Fallback for direct custom dance/animation IDs
	local directId = "rbxassetid://" .. tostring(catalogId)
	EmoteCache[catalogId] = directId
	return directId
end

local function PlayEmote(id, name)
	local Character = LocalPlayer.Character
	if not Character then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
	
	if not Animator or Humanoid.RigType == Enum.HumanoidRigType.R6 then 
		StatusLabel.Text = "Failed: Character must be R15."
		return 
	end

	StopEmote()
	currentPlayingEmoteId = tonumber(id) or id
	if updateAllSelectionVisuals then updateAllSelectionVisuals() end

	StatusLabel.Text = string.format("Loading: %s...", name or tostring(id))

	task.spawn(function()
		local rawId = GetRawEmoteId(id, name)
		
		if rawId then
			local customAnim = Instance.new("Animation")
			customAnim.AnimationId = rawId
			local succ, customTrack = pcall(function()
				return Animator:LoadAnimation(customAnim)
			end)
			if succ and customTrack then
				customTrack.Priority = Enum.AnimationPriority.Action4
				customTrack:SetAttribute("IsCustomEmote", true)
				customTrack.Looped = LoopEmotes
				customTrack:Play()
				currentEmoteTrack = customTrack
				forceEmote = true
				activeEmoteName = name or "Emote"
				StatusLabel.Text = string.format("Playing: %s  |  Loop: %s  |  [ X ] to Stop", activeEmoteName, LoopEmotes and "ON" or "OFF")
			else
				StatusLabel.Text = "Failed to load animation track for " .. tostring(name or id)
				currentPlayingEmoteId = nil
				if updateAllSelectionVisuals then updateAllSelectionVisuals() end
			end
		else
			StatusLabel.Text = "Failed to resolve animation for " .. tostring(name or id)
			currentPlayingEmoteId = nil
			if updateAllSelectionVisuals then updateAllSelectionVisuals() end
		end
	end)
end

local function CreateEmoteCard(emote, parentScroll)
	local Card = Instance.new("Frame")
	local numEmoteId = tonumber(emote.id)
	local isSelected = (currentPlayingEmoteId and numEmoteId and numEmoteId == tonumber(currentPlayingEmoteId))
	Card.BackgroundColor3 = isSelected and Color3.fromRGB(32, 42, 58) or StudioTheme.cardBg
	Card.BorderSizePixel = isSelected and 2 or 1
	Card.BorderColor3 = isSelected and StudioTheme.blue or StudioTheme.border
	Card.ClipsDescendants = true
	Card:SetAttribute("EmoteId", numEmoteId or emote.id)
	Card:SetAttribute("IsSelected", isSelected and true or false)

	local ActiveBadge = Instance.new("Frame")
	ActiveBadge.Name = "ActiveBadge"
	ActiveBadge.Size = UDim2.new(0, 54, 0, 16)
	ActiveBadge.Position = UDim2.new(0, 3, 0, 3)
	ActiveBadge.BackgroundColor3 = StudioTheme.blue
	ActiveBadge.BorderSizePixel = 0
	ActiveBadge.ZIndex = 20
	ActiveBadge.Visible = isSelected and true or false
	ActiveBadge.Parent = Card

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 3)
	badgeCorner.Parent = ActiveBadge

	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "BadgeText"
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = "PLAYING"
	badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeText.Font = ThemeFontBold
	badgeText.TextSize = 9
	badgeText.ZIndex = 21
	badgeText.Parent = ActiveBadge

	local IconContainer = Instance.new("Frame")
	IconContainer.Size = UDim2.new(1, -6, 0, 80)
	IconContainer.Position = UDim2.new(0, 3, 0, 3)
	IconContainer.BackgroundColor3 = StudioTheme.insetBg
	IconContainer.BorderSizePixel = 1
	IconContainer.BorderColor3 = StudioTheme.border
	IconContainer.Parent = Card

	local Icon = Instance.new("ImageButton")
	Icon.Size = UDim2.new(1, 0, 1, 0)
	Icon.BackgroundTransparency = 1
	Icon.Image = "rbxthumb://type=Asset&id=" .. emote.id .. "&w=150&h=150"
	Icon.Parent = IconContainer
	
	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "NameLabel"
	NameLabel.Size = UDim2.new(1, -6, 0, 26)
	NameLabel.Position = UDim2.new(0, 3, 0, 86)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = emote.name or ("Emote #" .. tostring(emote.id))
	NameLabel.TextColor3 = StudioTheme.text
	NameLabel.Font = ThemeFontSemibold
	NameLabel.TextSize = 11
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextYAlignment = Enum.TextYAlignment.Top
	NameLabel.Parent = Card

	local FavToggle = Instance.new("TextButton")
	FavToggle.Name = "FavToggle"
	FavToggle.Size = UDim2.new(0, 24, 0, 20)
	FavToggle.Position = UDim2.new(1, -26, 0, 3)
	FavToggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	FavToggle.BackgroundTransparency = 0.25
	FavToggle.BorderSizePixel = 1
	FavToggle.BorderColor3 = StudioTheme.border
	FavToggle.TextSize = 11
	FavToggle.Font = ThemeFontBold
	FavToggle.Active = true
	FavToggle.AutoButtonColor = true
	FavToggle.ZIndex = 25
	FavToggle.Parent = Card

	local favCorner = Instance.new("UICorner")
	favCorner.CornerRadius = UDim.new(0, 4)
	favCorner.Parent = FavToggle

	local isFav = isEmoteFav(emote.id)
	FavToggle.Text = isFav and "[X]" or "[+]"
	FavToggle.TextColor3 = isFav and StudioTheme.yellow or StudioTheme.textDim

	FavToggle.MouseEnter:Connect(function()
		FavToggle.BackgroundTransparency = 0
		FavToggle.BorderColor3 = StudioTheme.blue
	end)
	FavToggle.MouseLeave:Connect(function()
		FavToggle.BackgroundTransparency = 0.25
		FavToggle.BorderColor3 = StudioTheme.border
	end)

	Card.MouseEnter:Connect(function()
		local sel = (currentPlayingEmoteId and numEmoteId and numEmoteId == tonumber(currentPlayingEmoteId))
		if not sel then
			Card.BackgroundColor3 = StudioTheme.cardHover
			Card.BorderColor3 = StudioTheme.blue
		end
	end)
	Card.MouseLeave:Connect(function()
		local sel = (currentPlayingEmoteId and numEmoteId and numEmoteId == tonumber(currentPlayingEmoteId))
		if sel then
			Card.BackgroundColor3 = Color3.fromRGB(32, 42, 58)
			Card.BorderSizePixel = 2
			Card.BorderColor3 = StudioTheme.blue
		else
			Card.BackgroundColor3 = StudioTheme.cardBg
			Card.BorderSizePixel = 1
			Card.BorderColor3 = StudioTheme.border
		end
	end)

	local function onSelectEmote()
		PlayEmote(emote.id, emote.name)
	end

	Icon.MouseButton1Click:Connect(onSelectEmote)
	Card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onSelectEmote()
		end
	end)

	FavToggle.MouseButton1Click:Connect(function()
		toggleFav(emote.id, emote.name)
	end)

	Card.Parent = parentScroll
	return Card
end

function updateAllCardsFavVisuals()
	local function updateScroll(scrollFrame)
		if not scrollFrame then return end
		for _, card in ipairs(scrollFrame:GetChildren()) do
			if card:IsA("Frame") then
				local eId = card:GetAttribute("EmoteId")
				local fBtn = card:FindFirstChild("FavToggle")
				if eId and fBtn then
					local isFav = isEmoteFav(eId)
					fBtn.Text = isFav and "[X]" or "[+]"
					fBtn.TextColor3 = isFav and StudioTheme.yellow or StudioTheme.textDim
				end
			end
		end
	end
	updateScroll(CatScroll)
	updateScroll(FavScroll)
end

function updateAllSelectionVisuals()
	local function updateScroll(scrollFrame)
		if not scrollFrame then return end
		for _, card in ipairs(scrollFrame:GetChildren()) do
			if card:IsA("GuiObject") and card:GetAttribute("EmoteId") then
				local eId = tonumber(card:GetAttribute("EmoteId"))
				local isSel = (currentPlayingEmoteId and eId and eId == tonumber(currentPlayingEmoteId))
				card:SetAttribute("IsSelected", isSel and true or false)
				local badge = card:FindFirstChild("ActiveBadge")
				if badge then
					badge.Visible = isSel and true or false
				end
				if isSel then
					card.BackgroundColor3 = Color3.fromRGB(32, 42, 58)
					card.BorderSizePixel = 2
					card.BorderColor3 = StudioTheme.blue
				else
					card.BackgroundColor3 = StudioTheme.cardBg
					card.BorderSizePixel = 1
					card.BorderColor3 = StudioTheme.border
				end
			end
		end
	end
	updateScroll(CatScroll)
	updateScroll(FavScroll)
end

function RefreshFavorites()
	for _, child in ipairs(FavScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	FavTabBtn.Text = string.format("Favorites (%d)", #FavoritedEmotes)
	for _, fav in ipairs(FavoritedEmotes) do
		local emoteData = { id = fav.id, name = fav.name or "Saved Emote" }
		if emoteData.name == "Saved Emote" or emoteData.name == "Custom Emote" then
			for _, e in ipairs(Emotes) do
				if e.id == fav.id and e.name and e.name ~= "" and e.name ~= "Saved Emote" then
					emoteData.name = e.name
					fav.name = e.name
					SaveFavorites()
					break
				end
			end
		end

		local card = CreateEmoteCard(emoteData, FavScroll)

		if emoteData.name == "Saved Emote" or emoteData.name == "Custom Emote" then
			task.spawn(function()
				local realName = ResolveEmoteName(fav.id)
				if realName and realName ~= "Saved Emote" and realName ~= "Custom Emote" then
					fav.name = realName
					SaveFavorites()
					if card and card.Parent then
						local nameLbl = card:FindFirstChild("NameLabel")
						if nameLbl then
							nameLbl.Text = realName
						end
					end
				end
			end)
		end
	end
end

local function LoadAndPlayCustomEmote(rawInput, autoFav)
	local numId = extractId(rawInput)
	if not numId then
		StatusLabel.Text = "Status: Invalid animation ID or URL."
		return
	end

	StatusLabel.Text = "Resolving emote #" .. tostring(numId) .. " from Roblox..."

	task.spawn(function()
		local emoteName = ResolveEmoteName(numId)
		local emoteData = { id = numId, name = emoteName }

		local exists = false
		for _, e in ipairs(Emotes) do
			if e.id == numId then exists = true; break end
		end
		if not exists then
			table.insert(Emotes, 1, emoteData)
			CreateEmoteCard(emoteData, CatScroll)
		end

		if autoFav and not isEmoteFav(numId) then
			table.insert(FavoritedEmotes, { id = numId, name = emoteName })
			SaveFavorites()
			RefreshFavorites()
		end

		PlayEmote(numId, emoteName)
	end)
end

local function ProcessCatalogPage(pageData)
	for _, item in ipairs(pageData) do
		local exists = false
		for _, e in ipairs(Emotes) do
			if e.id == item.Id then exists = true; break end
		end
		if not exists then
			local eData = {name = item.Name, id = item.Id}
			table.insert(Emotes, eData)
			CreateEmoteCard(eData, CatScroll)
		end
	end
end

local function FetchCatalog(keyword)
	if FetchDebounce then return end
	FetchDebounce = true

	for _, child in ipairs(CatScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	Emotes = {}
	
	task.spawn(function()
		local success, pages = pcall(function()
			local params = CatalogSearchParams.new()
			params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
			params.SortType = (keyword and keyword ~= "") and Enum.CatalogSortType.Relevance or Enum.CatalogSortType.RecentlyUpdated
			if keyword and keyword ~= "" then params.SearchKeyword = keyword end
			params.Limit = 120
			return AvatarEditorService:SearchCatalog(params)
		end)

		if success and pages then
			catalogPages = pages
			ProcessCatalogPage(pages:GetCurrentPage())
			RefreshFavorites()
		end
		
		task.wait(1.5) 
		FetchDebounce = false
	end)
end

local canvasConn = CatScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local maxScroll = CatScroll.AbsoluteCanvasSize.Y - CatScroll.AbsoluteWindowSize.Y
	if CatScroll.CanvasPosition.Y >= maxScroll - 50 and not isLoadingMore then
		if catalogPages and not catalogPages.IsFinished then
			isLoadingMore = true
			local success = pcall(function() catalogPages:AdvanceToNextPageAsync() end)
			if success then
				ProcessCatalogPage(catalogPages:GetCurrentPage())
			end
			task.wait(1.2) 
			isLoadingMore = false
		end
	end
end)
table.insert(activeConnections, canvasConn)

PasteCatBtn.MouseButton1Click:Connect(function()
	local clip = safeGetClipboard()
	if clip and extractId(clip) then
		LoadAndPlayCustomEmote(clip, false)
	else
		SearchBox.Text = ""
		SearchBox.PlaceholderText = "Paste ID or URL here..."
		SearchBox:CaptureFocus()
		StatusLabel.Text = "Paste ID or URL into search box and press Enter."
	end
end)

local pendingFavFromSearch = false

PasteFavBtn.MouseButton1Click:Connect(function()
	local clip = safeGetClipboard()
	if clip and extractId(clip) then
		LoadAndPlayCustomEmote(clip, true)
	else
		pendingFavFromSearch = true
		selectTab(true)
		SearchBox.Text = ""
		SearchBox.PlaceholderText = "Paste ID or URL to favorite..."
		SearchBox:CaptureFocus()
		StatusLabel.Text = "Paste ID into search box and press Enter (will be favorited)."
	end
end)

SearchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local text = SearchBox.Text
		local numId = extractId(text)
		if numId and (text:match("^%s*%d+%s*$") or text:match("roblox%.com") or text:match("rbxassetid://")) then
			local autoFav = pendingFavFromSearch
			pendingFavFromSearch = false
			LoadAndPlayCustomEmote(text, autoFav)
		else
			pendingFavFromSearch = false
			FetchCatalog(text)
		end
	end
end)

local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed then
		if input.KeyCode == Enum.KeyCode.Comma then
			MainFrame.Visible = not MainFrame.Visible
		elseif input.KeyCode == Enum.KeyCode.X then
			StopEmote()
		end
	end
end)
table.insert(activeConnections, keyConn)

RandomCatBtn.MouseButton1Click:Connect(function()
	if #Emotes > 0 then
		local rand = Emotes[math.random(1, #Emotes)]
		PlayEmote(rand.id, rand.name)
	end
end)

RandomFavBtn.MouseButton1Click:Connect(function()
	if #FavoritedEmotes > 0 then
		local rand = FavoritedEmotes[math.random(1, #FavoritedEmotes)]
		local id = type(rand) == "table" and rand.id or rand
		local name = type(rand) == "table" and rand.name or "Saved Emote"
		PlayEmote(id, name)
	end
end)

local heartConn = RunService.Heartbeat:Connect(function()
	if forceEmote and currentEmoteTrack and currentEmoteTrack.Parent then
		if not currentEmoteTrack.IsPlaying then
			if not LoopEmotes and currentEmoteTrack.TimePosition >= currentEmoteTrack.Length - 0.05 then
				forceEmote = false
				activeEmoteName = "None"
				currentPlayingEmoteId = nil
				if updateAllSelectionVisuals then updateAllSelectionVisuals() end
				return
			end
			currentEmoteTrack:Play()
		end
		
		for _, track in ipairs(currentEmoteTrack.Parent:GetPlayingAnimationTracks()) do
			if track ~= currentEmoteTrack and not track:GetAttribute("IsCustomEmote") then
				if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 or track.Priority == Enum.AnimationPriority.Action4 then
					track:Stop()
				end
			end
		end
	end
end)
table.insert(activeConnections, heartConn)

RefreshFavorites()
FetchCatalog()

env._EmoteHubCleanup = function()
	StopEmote()
	for _, conn in ipairs(activeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(activeConnections)
	cleanAllPreviousInstances({
		"StudioEmoteHub",
		"BevelEmoteHub",
		"PotassiumEmoteHub"
	})
end
