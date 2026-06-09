local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currentPlaceId = tostring(game.PlaceId)
local SAVE_FILE = "CoordinateUI.json"

if playerGui:FindFirstChild("AttackUI") then
	playerGui.AttackUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AttackUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local isMobile = UserInputService.TouchEnabled
local uiVisible = true
local reopenButton = nil

local C = {
	bg = Color3.fromRGB(54, 58, 69),
	panel = Color3.fromRGB(69, 74, 88),
	panel2 = Color3.fromRGB(80, 86, 101),
	top = Color3.fromRGB(74, 79, 94),
	borderDark = Color3.fromRGB(28, 30, 37),
	borderLight = Color3.fromRGB(103, 109, 127),
	text = Color3.fromRGB(240, 242, 246),
	textMuted = Color3.fromRGB(205, 210, 220),
	textDim = Color3.fromRGB(170, 176, 188),
	blue = Color3.fromRGB(96, 149, 227),
	green = Color3.fromRGB(103, 208, 120),
	red = Color3.fromRGB(221, 103, 103),
	yellow = Color3.fromRGB(222, 186, 90),
	purple = Color3.fromRGB(156, 129, 220),
	orange = Color3.fromRGB(217, 155, 84),
}

local TITLE_H = 28
local FOOTER_H = 20
local BTN_H = 20
local ROW_H = 54

local MIN_W, MIN_H = 620, 240
local MAX_W, MAX_H = 900, 520

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

	local name = tostring(entry.name or ("Coordinate " .. tostring(fallbackIndex)))
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
		{ name = "Coordinate 1", pos = {0, 0, 0} },
		{ name = "Coordinate 2", pos = {1000, 0, 1000} },
	}
	saveDatabase()
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
	b.Parent = parent
	bevel(b)
	return b
end

local function makeTextBox(parent, text, width, placeholder)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, width or 60, 0, BTN_H)
	box.BackgroundColor3 = C.panel
	box.Text = text or ""
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = C.textDim
	box.TextColor3 = C.text
	box.TextSize = 12
	box.Font = Enum.Font.ArialBold
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = parent
	bevel(box)
	return box
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 680, 0, 270)
panel.Position = UDim2.new(0.5, -340, 0.5, -135)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Active = true
panel.ClipsDescendants = true
panel.Parent = screenGui
bevel(panel)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(MIN_W, MIN_H)
sizeConstraint.MaxSize = Vector2.new(MAX_W, MAX_H)
sizeConstraint.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.top
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
bevel(titleBar)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -28, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.Text = "Coordinate UI"
title.TextColor3 = C.text
title.TextSize = 14
title.Font = Enum.Font.ArialBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = makeButton(titleBar, "X", 20, C.red, C.text)
closeBtn.Position = UDim2.new(1, -22, 0, 4)
addDesktopHover(closeBtn, C.red, C.green, C.text, C.text)

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
content.Size = UDim2.new(1, -10, 1, -(TITLE_H + FOOTER_H + 8))
content.Position = UDim2.new(0, 5, 0, TITLE_H + 4)
content.BackgroundTransparency = 1
content.Parent = panel

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundTransparency = 1
topBar.Parent = content

local filterLabel = Instance.new("TextLabel")
filterLabel.BackgroundTransparency = 1
filterLabel.Size = UDim2.new(0, 70, 0, 18)
filterLabel.Position = UDim2.new(0, 2, 0, 2)
filterLabel.Text = "Game ID:"
filterLabel.TextColor3 = C.text
filterLabel.TextSize = 12
filterLabel.Font = Enum.Font.ArialBold
filterLabel.TextXAlignment = Enum.TextXAlignment.Left
filterLabel.Parent = topBar

local filterBox = makeTextBox(topBar, currentFilterId, 110, "PlaceId")
filterBox.Position = UDim2.new(0, 74, 0, 0)

local currentGameBtn = makeButton(topBar, "Current", 60, C.green, C.text)
currentGameBtn.Position = UDim2.new(0, 190, 0, 0)
addDesktopHover(currentGameBtn, C.green, C.blue, C.text, C.text)

local addCoordBtn = makeButton(topBar, "+ Coord", 70, C.purple, C.text)
addCoordBtn.Position = UDim2.new(0, 254, 0, 0)
addDesktopHover(addCoordBtn, C.purple, C.blue, C.text, C.text)

local alternateBtn = makeButton(topBar, "Alternate", 76, C.orange, C.text)
alternateBtn.Position = UDim2.new(0, 330, 0, 0)
addDesktopHover(alternateBtn, C.orange, C.green, C.text, C.text)

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -4, 0, 16)
infoLabel.Position = UDim2.new(0, 2, 0, 22)
infoLabel.Text = ""
infoLabel.TextColor3 = C.yellow
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.ArialBold
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = topBar

local listViewport = Instance.new("Frame")
listViewport.Size = UDim2.new(1, 0, 1, -42)
listViewport.Position = UDim2.new(0, 0, 0, 42)
listViewport.BackgroundColor3 = C.bg
listViewport.BorderSizePixel = 0
listViewport.ClipsDescendants = true
listViewport.Parent = content
bevel(listViewport)

local rowsHolder = Instance.new("Frame")
rowsHolder.Size = UDim2.new(1, 0, 1, 0)
rowsHolder.BackgroundTransparency = 1
rowsHolder.Parent = listViewport

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = rowsHolder

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)
padding.Parent = rowsHolder

local scrollUpBtn = makeButton(listViewport, "˄", 22, C.panel2, C.text)
scrollUpBtn.Position = UDim2.new(1, -24, 0, 4)

local scrollDownBtn = makeButton(listViewport, "˅", 22, C.panel2, C.text)
scrollDownBtn.Position = UDim2.new(1, -24, 0, 28)

local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = C.top
footer.BorderSizePixel = 0
footer.Parent = panel
bevel(footer)

local saveStatus = Instance.new("TextLabel")
saveStatus.BackgroundTransparency = 1
saveStatus.Size = UDim2.new(1, -28, 1, 0)
saveStatus.Position = UDim2.new(0, 8, 0, 0)
saveStatus.Text = canFileIO() and ("Saved to " .. SAVE_FILE) or "File save unavailable in this executor"
saveStatus.TextColor3 = C.textDim
saveStatus.TextSize = 11
saveStatus.Font = Enum.Font.ArialBold
saveStatus.TextXAlignment = Enum.TextXAlignment.Left
saveStatus.Parent = footer

local resizeGrip = makeButton(panel, "◢", 18, C.panel2, C.textDim)
resizeGrip.Size = UDim2.new(0, 18, 0, 18)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.Position = UDim2.new(1, -2, 1, -2)

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
	local usableHeight = math.max(0, listViewport.AbsoluteSize.Y - 12)
	return math.max(1, math.floor(usableHeight / (ROW_H + 6)))
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
	infoLabel.Text = "Filter: " .. currentFilterId .. " | Coords: " .. #list
	scrollUpBtn.Visible = #list > capacity
	scrollDownBtn.Visible = #list > capacity
end

local function saveRow(row)
	row.entry.name = row.nameBox.Text ~= "" and row.nameBox.Text or "Coordinate"
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

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, ROW_H)
		row.BackgroundColor3 = C.panel
		row.BorderSizePixel = 0
		row.Parent = rowsHolder
		bevel(row)

		local nameBox = makeTextBox(row, entry.name, 112, "Name")
		nameBox.Position = UDim2.new(0, 8, 0, 6)

		local renameBtn = makeButton(row, "Name", 48, C.purple, C.text)
		renameBtn.Position = UDim2.new(0, 126, 0, 6)
		addDesktopHover(renameBtn, C.purple, C.blue, C.text, C.text)

		local xBox = makeTextBox(row, tostring(entry.pos[1]), 56, "X")
		xBox.Position = UDim2.new(0, 8, 0, 30)

		local yBox = makeTextBox(row, tostring(entry.pos[2]), 56, "Y")
		yBox.Position = UDim2.new(0, 70, 0, 30)

		local zBox = makeTextBox(row, tostring(entry.pos[3]), 56, "Z")
		zBox.Position = UDim2.new(0, 132, 0, 30)

		local currentBtn = makeButton(row, "Here", 52, C.green, C.text)
		currentBtn.Position = UDim2.new(0, 194, 0, 30)
		addDesktopHover(currentBtn, C.green, C.blue, C.text, C.text)

		local tpBtn = makeButton(row, "TP", 42, C.blue, C.text)
		tpBtn.Position = UDim2.new(0, 252, 0, 30)
		addDesktopHover(tpBtn, C.blue, C.green, C.text, C.text)

		local delBtn = makeButton(row, "Del", 42, C.red, C.text)
		delBtn.Position = UDim2.new(0, 300, 0, 30)
		addDesktopHover(delBtn, C.red, C.purple, C.text, C.text)

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
			entry.name = nameBox.Text ~= "" and nameBox.Text or ("Coordinate " .. i)
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
		name = "Coordinate " .. tostring(#list + 1),
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
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			if uiVisible then
				hideGui()
			else
				showGui()
			end
		end
	end)
end
