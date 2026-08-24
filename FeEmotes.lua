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

local StudioTheme = {
	windowBg       = Color3.fromRGB(37, 37, 38),
	headerBg       = Color3.fromRGB(45, 45, 48),
	panelBg        = Color3.fromRGB(42, 42, 45),
	panelAlt       = Color3.fromRGB(32, 32, 34),
	insetBg        = Color3.fromRGB(26, 26, 28),
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
	btnBg          = Color3.fromRGB(50, 50, 54),
	btnHover       = Color3.fromRGB(65, 65, 70),
	tabActive      = Color3.fromRGB(40, 40, 42),
	tabInactive    = Color3.fromRGB(30, 30, 32),
}

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

if isfile and isfile("FavoritedEmotes.txt") then
	local succ, res = pcall(function()
		return HttpService:JSONDecode(readfile("FavoritedEmotes.txt"))
	end)
	if succ and type(res) == "table" then
		FavoritedEmotes = res
	end
end

local function SaveFavorites()
	if writefile then
		pcall(writefile, "FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
end

local function StopEmote()
	forceEmote = false
	activeEmoteName = "None"
	if currentEmoteTrack then
		currentEmoteTrack:Stop()
		currentEmoteTrack = nil
	end
end

local function makeStudioButton(parent, text, w, h, bg, fg)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, h or 22)
	b.BackgroundColor3 = bg or StudioTheme.btnBg
	b.Text = text
	b.TextColor3 = fg or StudioTheme.text
	b.TextSize = 12
	b.Font = Enum.Font.SourceSansSemibold
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
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = StudioTheme.border
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
Title.Font = Enum.Font.SourceSansSemibold
Title.TextSize = 13
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 1, 0)
CloseBtn.Position = UDim2.new(1, -26, 0, 0)
CloseBtn.BackgroundColor3 = StudioTheme.headerBg
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = StudioTheme.textMuted
CloseBtn.Font = Enum.Font.SourceSansBold
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
CatalogTabBtn.Font = Enum.Font.SourceSansSemibold
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
FavTabBtn.Font = Enum.Font.SourceSansSemibold
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
SearchBox.Size = UDim2.new(0, 210, 0, 22)
SearchBox.Position = UDim2.new(0, 6, 0, 5)
SearchBox.BackgroundColor3 = StudioTheme.insetBg
SearchBox.TextColor3 = StudioTheme.text
SearchBox.PlaceholderText = "Search Catalog (Press Enter)..."
SearchBox.PlaceholderColor3 = StudioTheme.textDim
SearchBox.Font = Enum.Font.SourceSans
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 1
SearchBox.BorderColor3 = StudioTheme.border
SearchBox.Parent = CatToolbar

local LoopCatBtn = makeStudioButton(CatToolbar, "Loop: ON", 84, 22, StudioTheme.green, Color3.fromRGB(255, 255, 255))
LoopCatBtn.Position = UDim2.new(0, 222, 0, 5)

local RandomCatBtn = makeStudioButton(CatToolbar, "Random", 76, 22, StudioTheme.btnBg, StudioTheme.text)
RandomCatBtn.Position = UDim2.new(0, 312, 0, 5)

local StopCatBtn = makeStudioButton(CatToolbar, "Stop", 60, 22, StudioTheme.red, Color3.fromRGB(255, 255, 255))
StopCatBtn.Position = UDim2.new(0, 394, 0, 5)
StopCatBtn.MouseButton1Click:Connect(StopEmote)

local FavToolbar = Instance.new("Frame")
FavToolbar.Size = UDim2.new(1, 0, 0, 32)
FavToolbar.BackgroundColor3 = StudioTheme.panelAlt
FavToolbar.BorderSizePixel = 1
FavToolbar.BorderColor3 = StudioTheme.border
FavToolbar.Parent = FavContainer

local LoopFavBtn = makeStudioButton(FavToolbar, "Loop: ON", 90, 22, StudioTheme.green, Color3.fromRGB(255, 255, 255))
LoopFavBtn.Position = UDim2.new(0, 6, 0, 5)

local RandomFavBtn = makeStudioButton(FavToolbar, "Play Random", 90, 22, StudioTheme.btnBg, StudioTheme.text)
RandomFavBtn.Position = UDim2.new(0, 102, 0, 5)

local StopFavBtn = makeStudioButton(FavToolbar, "Stop", 70, 22, StudioTheme.red, Color3.fromRGB(255, 255, 255))
StopFavBtn.Position = UDim2.new(0, 198, 0, 5)
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
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Footer

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

	return nil
end

local function PlayEmote(id, name)
	local Character = LocalPlayer.Character
	if not Character then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
	
	if not Animator or Humanoid.RigType == Enum.HumanoidRigType.R6 then return end

	StopEmote()

	local rawId = GetRawEmoteId(id, name)
	
	if rawId then
		local customAnim = Instance.new("Animation")
		customAnim.AnimationId = rawId
		local customTrack = Animator:LoadAnimation(customAnim)
		customTrack.Priority = Enum.AnimationPriority.Action4
		customTrack:SetAttribute("IsCustomEmote", true)
		customTrack.Looped = LoopEmotes
		customTrack:Play()
		currentEmoteTrack = customTrack
		forceEmote = true
		activeEmoteName = name or "Emote"
		StatusLabel.Text = string.format("Playing: %s  |  Loop: %s  |  [ X ] to Stop", activeEmoteName, LoopEmotes and "ON" or "OFF")
	end
end

local function CreateEmoteCard(emote, parentScroll)
	local Card = Instance.new("Frame")
	Card.BackgroundColor3 = StudioTheme.cardBg
	Card.BorderSizePixel = 1
	Card.BorderColor3 = StudioTheme.border
	Card.ClipsDescendants = true

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
	NameLabel.Size = UDim2.new(1, -6, 0, 26)
	NameLabel.Position = UDim2.new(0, 3, 0, 86)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = emote.name
	NameLabel.TextColor3 = StudioTheme.text
	NameLabel.Font = Enum.Font.SourceSansSemibold
	NameLabel.TextSize = 11
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextYAlignment = Enum.TextYAlignment.Top
	NameLabel.Parent = Card

	local FavToggle = Instance.new("TextButton")
	FavToggle.Size = UDim2.new(0, 20, 0, 20)
	FavToggle.Position = UDim2.new(1, -22, 0, 2)
	FavToggle.BackgroundTransparency = 1
	FavToggle.TextSize = 11
	FavToggle.Font = Enum.Font.SourceSansBold
	FavToggle.Parent = Card

	local isFav = table.find(FavoritedEmotes, emote.id)
	FavToggle.Text = isFav and "[X]" or "[+]"
	FavToggle.TextColor3 = isFav and StudioTheme.yellow or StudioTheme.textDim

	Card.MouseEnter:Connect(function()
		Card.BackgroundColor3 = StudioTheme.cardHover
		Card.BorderColor3 = StudioTheme.blue
	end)
	Card.MouseLeave:Connect(function()
		Card.BackgroundColor3 = StudioTheme.cardBg
		Card.BorderColor3 = StudioTheme.border
	end)

	Icon.MouseButton1Click:Connect(function()
		PlayEmote(emote.id, emote.name)
	end)

	FavToggle.MouseButton1Click:Connect(function()
		local idx = table.find(FavoritedEmotes, emote.id)
		if idx then
			table.remove(FavoritedEmotes, idx)
			FavToggle.Text = "[+]"
			FavToggle.TextColor3 = StudioTheme.textDim
		else
			table.insert(FavoritedEmotes, emote.id)
			FavToggle.Text = "[X]"
			FavToggle.TextColor3 = StudioTheme.yellow
		end
		SaveFavorites()
		RefreshFavorites()
	end)

	Card.Parent = parentScroll
end

function RefreshFavorites()
	for _, child in ipairs(FavScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	FavTabBtn.Text = string.format("Favorites (%d)", #FavoritedEmotes)
	for _, id in ipairs(FavoritedEmotes) do
		local emoteData = {id = id, name = "Saved Emote"}
		for _, e in ipairs(Emotes) do
			if e.id == id then emoteData.name = e.name; break end
		end
		CreateEmoteCard(emoteData, FavScroll)
	end
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

SearchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		FetchCatalog(SearchBox.Text)
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
		local randId = FavoritedEmotes[math.random(1, #FavoritedEmotes)]
		PlayEmote(randId, "Saved Emote")
	end
end)

local heartConn = RunService.Heartbeat:Connect(function()
	if forceEmote and currentEmoteTrack and currentEmoteTrack.Parent then
		if not currentEmoteTrack.IsPlaying then
			if not LoopEmotes and currentEmoteTrack.TimePosition >= currentEmoteTrack.Length - 0.05 then
				forceEmote = false
				activeEmoteName = "None"
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
