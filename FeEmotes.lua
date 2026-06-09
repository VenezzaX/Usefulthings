if game.PlaceId == 3095204897 then
	return
end

local env = getgenv()
if env.LastExecuted and tick() - env.LastExecuted < 5 then return end
env.LastExecuted = tick()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("BevelEmoteHub") then
	CoreGui.BevelEmoteHub:Destroy()
end

-- Potassium Color Palette
local C = {
    bg = Color3.fromRGB(36, 39, 47),
    panel = Color3.fromRGB(58, 62, 74),
    panel2 = Color3.fromRGB(70, 75, 89),
    top = Color3.fromRGB(82, 88, 104),
    borderDark = Color3.fromRGB(24, 26, 31),
    borderLight = Color3.fromRGB(112, 119, 138),
    text = Color3.fromRGB(241, 243, 247),
    textMuted = Color3.fromRGB(210, 214, 223),
    textDim = Color3.fromRGB(165, 171, 184), -- Missing color added here
    green = Color3.fromRGB(103, 208, 120),
    red = Color3.fromRGB(221, 103, 103),
    blue = Color3.fromRGB(97, 150, 228),
    yellow = Color3.fromRGB(222, 186, 90),
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
		writefile("FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
end

local function StopEmote()
	forceEmote = false
	if currentEmoteTrack then
		currentEmoteTrack:Stop()
		currentEmoteTrack = nil
	end
end

-- UI Utility Functions
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

local function makeButton(parent, text, w, h, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, h)
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

-- Core UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BevelEmoteHub"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (get_hidden_gui and get_hidden_gui()) or CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 420)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -210)
MainFrame.BackgroundColor3 = C.bg
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = ScreenGui
bevel(MainFrame)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.BackgroundColor3 = C.top
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
bevel(TopBar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = "Potassium Emote hub"
Title.TextColor3 = C.text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.ArialBold
Title.TextSize = 13
Title.Parent = TopBar

local CloseBtn = makeButton(TopBar, "X", 20, 20, C.red, C.text)
CloseBtn.Position = UDim2.new(1, -24, 0, 4)
CloseBtn.Activated:Connect(function() MainFrame.Visible = false end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
TopBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Tabs
local CatalogTabBtn = makeButton(MainFrame, "Catalog", 240, 26, C.panel, C.text)
CatalogTabBtn.Position = UDim2.new(0, 0, 0, 28)

local FavTabBtn = makeButton(MainFrame, "Favorites", 240, 26, C.bg, C.textMuted)
FavTabBtn.Position = UDim2.new(0.5, 0, 0, 28)

-- Containers
local CatalogContainer = Instance.new("Frame")
CatalogContainer.Size = UDim2.new(1, 0, 1, -54)
CatalogContainer.Position = UDim2.new(0, 0, 0, 54)
CatalogContainer.BackgroundTransparency = 1
CatalogContainer.Parent = MainFrame

local FavContainer = Instance.new("Frame")
FavContainer.Size = UDim2.new(1, 0, 1, -54)
FavContainer.Position = UDim2.new(0, 0, 0, 54)
FavContainer.BackgroundTransparency = 1
FavContainer.Visible = false
FavContainer.Parent = MainFrame

CatalogTabBtn.MouseButton1Click:Connect(function()
	CatalogContainer.Visible = true
	FavContainer.Visible = false
	CatalogTabBtn.BackgroundColor3 = C.panel
	CatalogTabBtn.TextColor3 = C.text
	FavTabBtn.BackgroundColor3 = C.bg
	FavTabBtn.TextColor3 = C.textMuted
end)

FavTabBtn.MouseButton1Click:Connect(function()
	CatalogContainer.Visible = false
	FavContainer.Visible = true
	FavTabBtn.BackgroundColor3 = C.panel
	FavTabBtn.TextColor3 = C.text
	CatalogTabBtn.BackgroundColor3 = C.bg
	CatalogTabBtn.TextColor3 = C.textMuted
end)

-- Controls (Catalog)
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0, 180, 0, 24)
SearchBox.Position = UDim2.new(0, 8, 0, 8)
SearchBox.BackgroundColor3 = C.panel2
SearchBox.TextColor3 = C.text
SearchBox.PlaceholderText = " Search Catalog..."
SearchBox.PlaceholderColor3 = C.textDim
SearchBox.Font = Enum.Font.ArialBold
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
SearchBox.Parent = CatalogContainer
bevel(SearchBox)

local LoopCatBtn = makeButton(CatalogContainer, "🔁 Loop: ON", 90, 24, C.green, C.text)
LoopCatBtn.Position = UDim2.new(0, 196, 0, 8)

local RandomCatBtn = makeButton(CatalogContainer, "🎲 Random", 90, 24, C.panel2, C.text)
RandomCatBtn.Position = UDim2.new(0, 294, 0, 8)

local StopCatBtn = makeButton(CatalogContainer, "⏹ Stop", 80, 24, C.red, C.text)
StopCatBtn.Position = UDim2.new(0, 392, 0, 8)
StopCatBtn.MouseButton1Click:Connect(StopEmote)

-- Controls (Favorites)
local LoopFavBtn = makeButton(FavContainer, "🔁 Loop: ON", 120, 24, C.green, C.text)
LoopFavBtn.Position = UDim2.new(0, 8, 0, 8)

local RandomFavBtn = makeButton(FavContainer, "🎲 Random", 120, 24, C.panel2, C.text)
RandomFavBtn.Position = UDim2.new(0, 136, 0, 8)

local StopFavBtn = makeButton(FavContainer, "⏹ Stop Emote", 120, 24, C.red, C.text)
StopFavBtn.Position = UDim2.new(0, 264, 0, 8)
StopFavBtn.MouseButton1Click:Connect(StopEmote)

local function UpdateLoopState()
	local txt = LoopEmotes and "🔁 Loop: ON" or "🔁 Loop: OFF"
	local bg = LoopEmotes and C.green or C.panel2
	LoopCatBtn.Text = txt
	LoopCatBtn.BackgroundColor3 = bg
	LoopFavBtn.Text = txt
	LoopFavBtn.BackgroundColor3 = bg
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

-- Scrolling Grids
local function CreateScrollFrame(parent)
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(1, -16, 1, -48)
    Wrapper.Position = UDim2.new(0, 8, 0, 40)
    Wrapper.BackgroundColor3 = C.panel
    Wrapper.BorderSizePixel = 0
    Wrapper.Parent = parent
    bevel(Wrapper)

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -4, 1, -4)
	Scroll.Position = UDim2.new(0, 2, 0, 2)
	Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = C.borderLight
	Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.Parent = Wrapper

	local Grid = Instance.new("UIGridLayout")
	Grid.CellSize = UDim2.new(0, 86, 0, 110)
	Grid.CellPadding = UDim2.new(0, 6, 0, 6)
	Grid.SortOrder = Enum.SortOrder.LayoutOrder
	Grid.Parent = Scroll
    
    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 4)
    Pad.PaddingLeft = UDim.new(0, 4)
    Pad.Parent = Scroll

	return Scroll
end

local CatScroll = CreateScrollFrame(CatalogContainer)
local FavScroll = CreateScrollFrame(FavContainer)

-- Emote Logic
local function GetRawEmoteId(catalogId, name)
	if EmoteCache[catalogId] then return EmoteCache[catalogId] end

	local s1, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(catalogId)) end)
	if s1 and objs and objs[1] then
		local anim = objs[1]:FindFirstChildOfClass("Animation", true) or (objs[1]:IsA("Animation") and objs[1])
		if anim and anim.AnimationId and anim.AnimationId ~= "" then
			EmoteCache[catalogId] = anim.AnimationId
			warn("[Velq Emotes] Success: Method 1 (game:GetObjects) utilized for " .. tostring(catalogId))
			return anim.AnimationId
		end
	end

	local s2, asset = pcall(function() return game:GetService("InsertService"):LoadAsset(catalogId) end)
	if s2 and asset then
		local anim = asset:FindFirstChildOfClass("Animation", true) or (asset:IsA("Animation") and asset)
		if anim and anim.AnimationId and anim.AnimationId ~= "" then
			EmoteCache[catalogId] = anim.AnimationId
			warn("[Velq Emotes] Success: Method 2 (InsertService:LoadAsset) utilized for " .. tostring(catalogId))
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
				warn("[Velq Emotes] Success: Method 3 (Native HumanoidDescription) utilized for " .. tostring(catalogId))
				return rawId
			end
		end
	end

	warn("[Velq Emotes] CRITICAL: All 3 extraction methods failed for ID " .. tostring(catalogId))
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
	end
end

local function CreateEmoteCard(emote, parentScroll)
	local Card = Instance.new("Frame")
	Card.BackgroundColor3 = C.panel2
	Card.BorderSizePixel = 0
    bevel(Card)

	local Icon = Instance.new("ImageButton")
	Icon.Size = UDim2.new(1, 0, 0, 80)
	Icon.BackgroundTransparency = 1
	Icon.Image = "rbxthumb://type=Asset&id=" .. emote.id .. "&w=150&h=150"
	Icon.Parent = Card
	
	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(1, -2, 0, 26)
	NameLabel.Position = UDim2.new(0, 2, 0, 82)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = emote.name
	NameLabel.TextColor3 = C.text
	NameLabel.Font = Enum.Font.ArialBold
	NameLabel.TextSize = 11
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.Parent = Card

	local FavToggle = Instance.new("TextButton")
	FavToggle.Size = UDim2.new(0, 20, 0, 20)
	FavToggle.Position = UDim2.new(1, -22, 0, 4)
	FavToggle.BackgroundTransparency = 1
	FavToggle.TextSize = 14
	FavToggle.Font = Enum.Font.ArialBold
	FavToggle.Parent = Card

	local isFav = table.find(FavoritedEmotes, emote.id)
	FavToggle.Text = isFav and "⭐" or "☆"
	FavToggle.TextColor3 = isFav and C.yellow or C.textMuted

	Icon.MouseButton1Click:Connect(function()
		PlayEmote(emote.id, emote.name)
	end)

	FavToggle.MouseButton1Click:Connect(function()
		local idx = table.find(FavoritedEmotes, emote.id)
		if idx then
			table.remove(FavoritedEmotes, idx)
			FavToggle.Text = "☆"
			FavToggle.TextColor3 = C.textMuted
		else
			table.insert(FavoritedEmotes, emote.id)
			FavToggle.Text = "⭐"
			FavToggle.TextColor3 = C.yellow
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
			params.SortType = keyword and Enum.CatalogSortType.Relevance or Enum.CatalogSortType.RecentlyUpdated
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

CatScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
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

SearchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		FetchCatalog(SearchBox.Text)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed then
		if input.KeyCode == Enum.KeyCode.Comma then
			MainFrame.Visible = not MainFrame.Visible
		elseif input.KeyCode == Enum.KeyCode.X then
			StopEmote()
		end
	end
end)

RandomCatBtn.MouseButton1Click:Connect(function()
	if #Emotes > 0 then
		local rand = Emotes[math.random(1, #Emotes)]
		PlayEmote(rand.id, rand.name)
	end
end)

RandomFavBtn.MouseButton1Click:Connect(function()
	if #FavoritedEmotes > 0 then
		local randId = FavoritedEmotes[math.random(1, #FavoritedEmotes)]
		PlayEmote(randId, "Emote")
	end
end)

RunService.Heartbeat:Connect(function()
	if forceEmote and currentEmoteTrack and currentEmoteTrack.Parent then
		if not currentEmoteTrack.IsPlaying then
			if not LoopEmotes and currentEmoteTrack.TimePosition >= currentEmoteTrack.Length - 0.05 then
				forceEmote = false
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

FetchCatalog()
