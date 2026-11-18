if game.PlaceId == 3095204897 then
	return
end

local env = getgenv and getgenv() or _G

if env._AnimPackHubCleanup then
	pcall(env._AnimPackHubCleanup)
	env._AnimPackHubCleanup = nil
end

if env.LastExecuted and tick() - env.LastExecuted < 2 then return end
env.LastExecuted = tick()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local AssetService = game:GetService("AssetService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
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
	"StudioAnimPackHub",
	"StudioAnimationHub"
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


-- Popular bundle IDs for instant fallback loading (All animation data & metadata is pulled live from Roblox)
local DEFAULT_POPULAR_BUNDLE_IDS = {
	24,  -- Ninja Animation Package
	38,  -- Mage Animation Package
	84,  -- Levitation Animation Package
	41,  -- Superhero Animation Package
	52,  -- Vampire Animation Package
	48,  -- Pirate Animation Package
	49,  -- Astronaut Animation Package
	43,  -- Cartoony Animation Package
	34,  -- Knight Animation Package
	50,  -- Elder Animation Package
	47,  -- Toy Animation Package
	51,  -- Bubbly Animation Package
	39,  -- Zombie Animation Package
	40,  -- Robot Animation Package
	53,  -- Sneaky Animation Package
	85,  -- Oldschool Animation Package
	42,  -- Confident Animation Package
	54,  -- Princess Animation Package
	55,  -- Cowboy Animation Package
	56,  -- Popstar Animation Package
	57,  -- Patrol Animation Package
	58   -- Bold Animation Package
}

local AnimationPacks = {}
local FavoritedPacks = {}
local PackCache = {}
local activePackName = "Default"
local currentAppliedPackData = nil
local catalogPages = nil
local isLoadingMore = false
local FetchDebounce = false
local activeConnections = {}
local RefreshFavorites
local updateAllCardsFavVisuals
local updateAllSelectionVisuals
local currentEquippedPackId = nil

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

local function normalizeFavPacks(rawList)
	local normalized = {}
	if type(rawList) ~= "table" then return normalized end
	for _, item in ipairs(rawList) do
		if type(item) == "number" then
			table.insert(normalized, { id = item, name = "Saved Pack #" .. tostring(item) })
		elseif type(item) == "table" and item.id then
			table.insert(normalized, { id = tonumber(item.id), name = tostring(item.name or ("Pack #" .. tostring(item.id))) })
		end
	end
	return normalized
end

if isfile and isfile("FavoritedAnimPacks.txt") then
	local succ, res = pcall(function()
		return HttpService:JSONDecode(readfile("FavoritedAnimPacks.txt"))
	end)
	if succ and type(res) == "table" then
		FavoritedPacks = normalizeFavPacks(res)
	end
end

local function SaveFavorites()
	if writefile then
		pcall(writefile, "FavoritedAnimPacks.txt", HttpService:JSONEncode(FavoritedPacks))
	end
end

local function isPackFav(id)
	id = tonumber(id)
	if not id then return false end
	for _, fav in ipairs(FavoritedPacks) do
		local favId = type(fav) == "table" and tonumber(fav.id) or tonumber(fav)
		if favId == id then return true end
	end
	return false
end

local function togglePackFav(id, name)
	id = tonumber(id)
	if not id then return end
	local foundIdx = nil
	for idx, fav in ipairs(FavoritedPacks) do
		local favId = type(fav) == "table" and tonumber(fav.id) or tonumber(fav)
		if favId == id then
			foundIdx = idx
			break
		end
	end
	if foundIdx then
		table.remove(FavoritedPacks, foundIdx)
	else
		table.insert(FavoritedPacks, { id = id, name = (name and name ~= "" and not name:find("^Saved Pack #")) and name or ("Pack #" .. tostring(id)) })
	end
	SaveFavorites()
	if RefreshFavorites then RefreshFavorites() end
	if updateAllCardsFavVisuals then updateAllCardsFavVisuals() end
end

local function httpGetSafe(url)
	local result = nil
	local succ = pcall(function()
		if request then
			local res = request({Url = url, Method = "GET"})
			result = res and res.Body
		elseif http_request then
			local res = http_request({Url = url, Method = "GET"})
			result = res and res.Body
		elseif syn and syn.request then
			local res = syn.request({Url = url, Method = "GET"})
			result = res and res.Body
		elseif game and game.HttpGet then
			result = game:HttpGet(url)
		end
	end)
	return succ and result or nil
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
ScreenGui.Name = "StudioAnimPackHub"
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
Title.Text = "Toolbox - R15 Animation Pack Explorer"
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
CatalogTabBtn.Text = "Animation Packs"
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
SearchBox.Size = UDim2.new(0, 180, 0, 22)
SearchBox.Position = UDim2.new(0, 6, 0, 5)
SearchBox.BackgroundColor3 = StudioTheme.insetBg
SearchBox.TextColor3 = StudioTheme.text
SearchBox.PlaceholderText = "Search Packs or Bundle ID..."
SearchBox.PlaceholderColor3 = StudioTheme.textDim
SearchBox.Font = ThemeFont
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 1
SearchBox.BorderColor3 = StudioTheme.border
SearchBox.Parent = CatToolbar

local PasteCatBtn = makeStudioButton(CatToolbar, "Paste ID", 72, 22, StudioTheme.btnBg, StudioTheme.text)
PasteCatBtn.Position = UDim2.new(0, 192, 0, 5)

local RandomCatBtn = makeStudioButton(CatToolbar, "Equip Random", 98, 22, StudioTheme.btnBg, StudioTheme.text)
RandomCatBtn.Position = UDim2.new(0, 270, 0, 5)

local FavToolbar = Instance.new("Frame")
FavToolbar.Size = UDim2.new(1, 0, 0, 32)
FavToolbar.BackgroundColor3 = StudioTheme.panelAlt
FavToolbar.BorderSizePixel = 1
FavToolbar.BorderColor3 = StudioTheme.border
FavToolbar.Parent = FavContainer

local RandomFavBtn = makeStudioButton(FavToolbar, "Equip Random", 98, 22, StudioTheme.btnBg, StudioTheme.text)
RandomFavBtn.Position = UDim2.new(0, 6, 0, 5)

local PasteFavBtn = makeStudioButton(FavToolbar, "+ Paste ID", 78, 22, StudioTheme.btnBg, StudioTheme.text)
PasteFavBtn.Position = UDim2.new(0, 110, 0, 5)

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
StatusLabel.Text = "Shortcuts: [ , ] Toggle UI  |  Equipped: Default"
StatusLabel.TextColor3 = StudioTheme.textDim
StatusLabel.TextSize = 11
StatusLabel.Font = ThemeFont
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Footer

-- Dynamically pulls and extracts animation data from Roblox for ANY bundle ID or asset ID
local function ResolvePackAnimations(packId)
	packId = tonumber(packId)
	if not packId then return nil end

	if PackCache[packId] then
		return PackCache[packId]
	end

	local anims = {}
	local idleList = {}

	-- Step 1: Try resolving as an Animation Bundle via AssetService
	local bundleSucc, bundleDetails = pcall(function()
		return AssetService:GetBundleDetailsAsync(packId)
	end)

	-- Fallback to Roblox Catalog API if AssetService is restricted
	if (not bundleSucc or not bundleDetails or not bundleDetails.Items or #bundleDetails.Items == 0) then
		local webJson = httpGetSafe("https://catalog.roproxy.com/v1/bundles/" .. tostring(packId) .. "/details")
		if not webJson then
			webJson = httpGetSafe("https://catalog.roblox.com/v1/bundles/" .. tostring(packId) .. "/details")
		end
		if webJson then
			pcall(function()
				local decoded = HttpService:JSONDecode(webJson)
				if decoded and decoded.items then
					local items = {}
					for _, item in ipairs(decoded.items) do
						table.insert(items, {
							Id = item.id,
							Name = item.name,
							Type = item.type
						})
					end
					bundleDetails = {
						Id = decoded.id,
						Name = decoded.name,
						Items = items
					}
					bundleSucc = true
				end
			end)
		end
	end

	if bundleSucc and bundleDetails and bundleDetails.Items and #bundleDetails.Items > 0 then
		for _, item in ipairs(bundleDetails.Items) do
			local itemName = item.Name:lower()
			local assetId = item.Id
			local detectedSlot = nil

			if (itemName:find("swim") and itemName:find("idle")) or itemName:find("swimidle") then
				detectedSlot = "swimidle"
			elseif itemName:find("swim") then
				detectedSlot = "swim"
			elseif itemName:find("idle") then
				detectedSlot = "idle"
			elseif itemName:find("walk") then
				detectedSlot = "walk"
			elseif itemName:find("run") then
				detectedSlot = "run"
			elseif itemName:find("jump") then
				detectedSlot = "jump"
			elseif itemName:find("fall") then
				detectedSlot = "fall"
			elseif itemName:find("climb") then
				detectedSlot = "climb"
			elseif itemName:find("pose") then
				detectedSlot = "pose"
			end

			-- Load asset objects to extract raw AnimationId properties
			local extractedIds = {}
			local getSucc, objs = pcall(function()
				return game:GetObjects("rbxassetid://" .. tostring(assetId))
			end)

			if getSucc and objs then
				for _, obj in ipairs(objs) do
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("Animation") and desc.AnimationId and desc.AnimationId ~= "" then
							table.insert(extractedIds, desc.AnimationId)
						end
					end
					if #extractedIds == 0 and obj:IsA("Animation") and obj.AnimationId and obj.AnimationId ~= "" then
						table.insert(extractedIds, obj.AnimationId)
					end
				end
			end

			if #extractedIds == 0 then
				table.insert(extractedIds, "rbxassetid://" .. tostring(assetId))
			end

			if detectedSlot == "idle" then
				for _, animId in ipairs(extractedIds) do
					if not table.find(idleList, animId) then
						table.insert(idleList, animId)
					end
				end
			elseif detectedSlot then
				anims[detectedSlot] = extractedIds[1]
			end
		end
	end

	-- Step 2: If packId was directly an Asset ID or bundle unpack returned nothing, extract directly
	if next(anims) == nil and #idleList == 0 then
		local getSucc, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(packId))
		end)

		if getSucc and objs then
			for _, obj in ipairs(objs) do
				for _, desc in ipairs(obj:GetDescendants()) do
					if desc:IsA("Animation") and desc.AnimationId and desc.AnimationId ~= "" then
						local lower = desc.Name:lower()
						local parentLower = desc.Parent and desc.Parent.Name:lower() or ""

						if (lower:find("idle") or parentLower:find("idle")) and not (lower:find("swim") or parentLower:find("swim")) then
							if not table.find(idleList, desc.AnimationId) then
								table.insert(idleList, desc.AnimationId)
							end
						elseif lower:find("walk") or parentLower:find("walk") then
							anims.walk = desc.AnimationId
						elseif lower:find("run") or parentLower:find("run") then
							anims.run = desc.AnimationId
						elseif lower:find("jump") or parentLower:find("jump") then
							anims.jump = desc.AnimationId
						elseif lower:find("fall") or parentLower:find("fall") then
							anims.fall = desc.AnimationId
						elseif lower:find("climb") or parentLower:find("climb") then
							anims.climb = desc.AnimationId
						elseif (lower:find("swim") or parentLower:find("swim")) and (lower:find("idle") or parentLower:find("idle")) then
							anims.swimidle = desc.AnimationId
						elseif lower:find("swim") or parentLower:find("swim") then
							anims.swim = desc.AnimationId
						end
					end
				end
			end
		end
	end

	if #idleList > 0 then
		anims.idle = idleList
	end

	-- Fallbacks for complementary slots
	if anims.swim and not anims.swimidle then
		anims.swimidle = anims.swim
	end
	if anims.walk and not anims.run then
		anims.run = anims.walk
	end
	if anims.run and not anims.walk then
		anims.walk = anims.run
	end

	if next(anims) ~= nil then
		PackCache[packId] = anims
		return anims
	end

	return nil
end

local function EquipAnimationPack(packData)
	local character = LocalPlayer.Character
	if not character then
		StatusLabel.Text = "Status: Character not found."
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animate = character:FindFirstChild("Animate")
	if not humanoid or not animate or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		StatusLabel.Text = "Failed: Character must be R15 with default Animate script."
		return
	end

	StatusLabel.Text = string.format("Pulling %s from Roblox...", packData.name or "Animation")

	task.spawn(function()
		local anims = packData.anims or ResolvePackAnimations(packData.id)
		if not anims then
			StatusLabel.Text = "Failed to pull animations from Roblox for " .. (packData.name or "Pack")
			return
		end

		currentAppliedPackData = packData
		currentEquippedPackId = tonumber(packData.id)
		if updateAllSelectionVisuals then updateAllSelectionVisuals() end

		-- 1. Disable Animate script to unload active internal listeners
		animate.Disabled = true

		-- 2. Flush currently playing tracks
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function() track:Stop(0) end)
			end
		end

		-- 3. Overwrite asset IDs inside the Animate script structure
		for stateName, animValue in pairs(anims) do
			local container = animate:FindFirstChild(stateName)
			if container then
				if type(animValue) == "table" then
					for i, id in ipairs(animValue) do
						local childAnim = container:FindFirstChild("Animation" .. i) or container:FindFirstChildOfClass("Animation")
						if childAnim and childAnim:IsA("Animation") then
							childAnim.AnimationId = id
						end
					end
				else
					for _, child in ipairs(container:GetChildren()) do
						if child:IsA("Animation") then
							child.AnimationId = animValue
						elseif child:IsA("StringValue") and child.Value ~= "" then
							child.Value = animValue
						end
					end
				end
			end
		end

		-- 4. Re-enable the script and force a clean state refresh that retains jump capability
		animate.Disabled = false
		humanoid:ChangeState(Enum.HumanoidStateType.Landed)

		activePackName = packData.name or "Selected Pack"
		StatusLabel.Text = string.format("Equipped: %s  |  Live from Roblox", activePackName)
	end)
end

local function CreatePackCard(pack, parentScroll)
	local Card = Instance.new("Frame")
	local numPackId = tonumber(pack.id)
	local isSelected = (currentEquippedPackId and numPackId and numPackId == currentEquippedPackId)
	Card.BackgroundColor3 = isSelected and Color3.fromRGB(32, 42, 58) or StudioTheme.cardBg
	Card.BorderSizePixel = isSelected and 2 or 1
	Card.BorderColor3 = isSelected and StudioTheme.blue or StudioTheme.border
	Card.ClipsDescendants = true
	Card:SetAttribute("PackId", numPackId)
	Card:SetAttribute("IsSelected", isSelected and true or false)

	local ActiveBadge = Instance.new("Frame")
	ActiveBadge.Name = "ActiveBadge"
	ActiveBadge.Size = UDim2.new(0, 60, 0, 16)
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
	badgeText.Text = "EQUIPPED"
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
	Icon.Image = "rbxthumb://type=BundleThumbnail&id=" .. tostring(pack.id) .. "&w=150&h=150"
	Icon.Parent = IconContainer
	
	local cleanName = (pack.name or ("Pack #" .. tostring(pack.id))):gsub(" Animation Package", ""):gsub(" Animations", ""):gsub(" Package", "")

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "NameLabel"
	NameLabel.Size = UDim2.new(1, -6, 0, 26)
	NameLabel.Position = UDim2.new(0, 3, 0, 86)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = cleanName
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

	local isFav = isPackFav(pack.id)
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
		local sel = (currentEquippedPackId and numPackId and numPackId == currentEquippedPackId)
		if not sel then
			Card.BackgroundColor3 = StudioTheme.cardHover
			Card.BorderColor3 = StudioTheme.blue
		end
	end)
	Card.MouseLeave:Connect(function()
		local sel = (currentEquippedPackId and numPackId and numPackId == currentEquippedPackId)
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

	local function onSelectPack()
		EquipAnimationPack(pack)
	end

	Icon.MouseButton1Click:Connect(onSelectPack)
	Card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onSelectPack()
		end
	end)

	FavToggle.MouseButton1Click:Connect(function()
		togglePackFav(pack.id, pack.name)
	end)

	Card.Parent = parentScroll
	return Card
end

function updateAllCardsFavVisuals()
	local function updateScroll(scrollFrame)
		if not scrollFrame then return end
		for _, card in ipairs(scrollFrame:GetChildren()) do
			if card:IsA("Frame") then
				local pId = card:GetAttribute("PackId")
				local fBtn = card:FindFirstChild("FavToggle")
				if pId and fBtn then
					local isFav = isPackFav(pId)
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
			if card:IsA("GuiObject") and card:GetAttribute("PackId") then
				local pId = tonumber(card:GetAttribute("PackId"))
				local isSel = (currentEquippedPackId and pId and pId == currentEquippedPackId)
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
	FavTabBtn.Text = string.format("Favorites (%d)", #FavoritedPacks)
	for _, fav in ipairs(FavoritedPacks) do
		local packData = { id = fav.id, name = fav.name or ("Saved Pack #" .. tostring(fav.id)) }
		if packData.name:find("^Saved Pack #") or packData.name:find("^Pack #") or packData.name:find("^Bundle #") then
			for _, p in ipairs(AnimationPacks) do
				if p.id == fav.id and p.name and not p.name:find("^Pack #") and not p.name:find("^Bundle #") then
					packData.name = p.name
					fav.name = p.name
					SaveFavorites()
					break
				end
			end
		end

		local card = CreatePackCard(packData, FavScroll)

		if packData.name:find("^Saved Pack #") or packData.name:find("^Pack #") or packData.name:find("^Bundle #") then
			task.spawn(function()
				local meta = FetchBundleMeta(fav.id)
				if meta and meta.name and not meta.name:find("^Bundle #") and not meta.name:find("^Pack #") then
					fav.name = meta.name
					SaveFavorites()
					if card and card.Parent then
						local nameLbl = card:FindFirstChild("NameLabel")
						if nameLbl then
							local clean = meta.name:gsub(" Animation Package", ""):gsub(" Animations", ""):gsub(" Package", "")
							nameLbl.Text = clean
						end
					end
				end
			end)
		end
	end
end

local function LoadAndEquipCustomPack(rawInput, autoFav)
	local numId = extractId(rawInput)
	if not numId then
		StatusLabel.Text = "Status: Invalid bundle or animation ID."
		return
	end

	StatusLabel.Text = "Resolving animation pack #" .. tostring(numId) .. " from Roblox..."

	task.spawn(function()
		local meta = FetchBundleMeta(numId)
		local exists = false
		for _, p in ipairs(AnimationPacks) do
			if p.id == numId then exists = true; break end
		end
		if not exists then
			table.insert(AnimationPacks, 1, meta)
			CreatePackCard(meta, CatScroll)
		end

		if autoFav and not isPackFav(numId) then
			table.insert(FavoritedPacks, { id = numId, name = meta.name })
			SaveFavorites()
			RefreshFavorites()
		end

		EquipAnimationPack(meta)
	end)
end

local function ProcessCatalogPage(pageData)
	for _, item in ipairs(pageData) do
		local itemId = item.Id or item.id
		local itemName = item.Name or item.name
		if itemId and itemName then
			local exists = false
			for _, p in ipairs(AnimationPacks) do
				if p.id == itemId then exists = true; break end
			end
			if not exists then
				local pData = { name = itemName, id = itemId }
				table.insert(AnimationPacks, pData)
				CreatePackCard(pData, CatScroll)
			end
		end
	end
end

local function FetchCatalog(keyword)
	if FetchDebounce then return end
	FetchDebounce = true

	for _, child in ipairs(CatScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	AnimationPacks = {}
	catalogPages = nil

	StatusLabel.Text = "Searching Roblox Catalog for animation packages..."

	task.spawn(function()
		-- Check if keyword is a direct numeric bundle or asset ID
		local numId = tonumber(keyword and keyword:match("^%s*(%d+)%s*$"))
		if numId then
			local meta = FetchBundleMeta(numId)
			table.insert(AnimationPacks, meta)
			CreatePackCard(meta, CatScroll)
			StatusLabel.Text = "Loaded custom ID from Roblox: " .. meta.name
			FetchDebounce = false
			return
		end

		local success, pages = pcall(function()
			local params = CatalogSearchParams.new()
			params.BundleTypes = { Enum.BundleType.Animations }
			params.IncludeOffSale = true
			if keyword and keyword ~= "" then
				params.SearchKeyword = keyword
				params.SortType = Enum.CatalogSortType.Relevance
			else
				params.SortType = Enum.CatalogSortType.RecentlyUpdated
			end
			params.Limit = 60
			return AvatarEditorService:SearchCatalog(params)
		end)

		local hasResults = false
		if success and pages then
			catalogPages = pages
			local curPage = pages:GetCurrentPage()
			if curPage and #curPage > 0 then
				ProcessCatalogPage(curPage)
				hasResults = true
			end
		end

		-- If catalog search returned no results, populate from popular Roblox bundle IDs dynamically
		if not hasResults and (not keyword or keyword == "") then
			for _, bundleId in ipairs(DEFAULT_POPULAR_BUNDLE_IDS) do
				local meta = FetchBundleMeta(bundleId)
				table.insert(AnimationPacks, meta)
				CreatePackCard(meta, CatScroll)
			end
		elseif not hasResults and keyword and keyword ~= "" then
			for _, bundleId in ipairs(DEFAULT_POPULAR_BUNDLE_IDS) do
				local meta = FetchBundleMeta(bundleId)
				if meta.name:lower():find(keyword:lower(), 1, true) then
					table.insert(AnimationPacks, meta)
					CreatePackCard(meta, CatScroll)
				end
			end
		end

		RefreshFavorites()
		StatusLabel.Text = string.format("Found %d animation packs from Roblox", #AnimationPacks)

		task.wait(1.0)
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
		LoadAndEquipCustomPack(clip, false)
	else
		SearchBox.Text = ""
		SearchBox.PlaceholderText = "Paste Bundle or Asset ID..."
		SearchBox:CaptureFocus()
		StatusLabel.Text = "Paste ID into search box and press Enter."
	end
end)

local pendingFavFromSearch = false

PasteFavBtn.MouseButton1Click:Connect(function()
	local clip = safeGetClipboard()
	if clip and extractId(clip) then
		LoadAndEquipCustomPack(clip, true)
	else
		pendingFavFromSearch = true
		selectTab(true)
		SearchBox.Text = ""
		SearchBox.PlaceholderText = "Paste ID to favorite..."
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
			LoadAndEquipCustomPack(text, autoFav)
		else
			pendingFavFromSearch = false
			FetchCatalog(text)
		end
	end
end)

local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Comma then
		MainFrame.Visible = not MainFrame.Visible
	end
end)
table.insert(activeConnections, keyConn)

RandomCatBtn.MouseButton1Click:Connect(function()
	if #AnimationPacks > 0 then
		local rand = AnimationPacks[math.random(1, #AnimationPacks)]
		EquipAnimationPack(rand)
	end
end)

RandomFavBtn.MouseButton1Click:Connect(function()
	if #FavoritedPacks > 0 then
		local rand = FavoritedPacks[math.random(1, #FavoritedPacks)]
		local id = type(rand) == "table" and rand.id or rand
		local name = type(rand) == "table" and rand.name or ("Pack #" .. tostring(id))
		local packData = { id = id, name = name }
		for _, p in ipairs(AnimationPacks) do
			if p.id == id then packData = p; break end
		end
		EquipAnimationPack(packData)
	end
end)

local charConn = LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	if currentAppliedPackData then
		EquipAnimationPack(currentAppliedPackData)
	end
end)
table.insert(activeConnections, charConn)

FetchCatalog()

env._AnimPackHubCleanup = function()
	for _, conn in ipairs(activeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(activeConnections)
	cleanAllPreviousInstances({
		"StudioAnimPackHub",
		"StudioAnimationHub"
	})
end
