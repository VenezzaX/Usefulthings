if not writefile or not makefolder then
    return warn("Error: Your executor lacks 'writefile' or 'makefolder' support.")
end

local decompileFunc = decompile or disassemble or (potassium and potassium.decompile)
if not decompileFunc then
    return warn("Error: Potassium Decompiler (or a compatible decompile function) was not found.")
end

local MarketService = game:GetService("MarketplaceService")

local successInfo, gameInfo = pcall(function() 
    return MarketService:GetProductInfo(game.PlaceId) 
end)
local gameName = successInfo and gameInfo.Name or "Unknown_Game"
local universeId = game.GameId
local placeId = game.PlaceId

local totalScripts = 0
local decompiledCount = 0
local failedCount = 0

local remoteManifest = { "--- NETWORK REMOTE MANIFEST ---" }

local function sanitizeName(name)
    return name:gsub('[%\\%:%*%?%"%<%>%|%/]', "_")
end

local function dumpEnvironment(object, currentPath)
    if object:IsA("Player") or object:IsA("NetworkPeer") then return end

    local safeName = sanitizeName(object.Name)
    local objectPath = currentPath .. "/" .. safeName
    
    if object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
        table.insert(remoteManifest, "[" .. object.ClassName .. "] " .. object:GetFullName())
    end

    if object:IsA("LuaSourceContainer") then
        totalScripts = totalScripts + 1
        
        local success, sourceCode = pcall(function()
            return decompileFunc(object)
        end)
        
        local header = {
            "-- [POTASSIUM CONTEXT HEADER]",
            "-- Name: " .. object.Name,
            "-- Path: " .. object:GetFullName(),
            "--------------------------------------------------\n\n"
        }
        local finalSource = table.concat(header, "\n") .. (sourceCode or "")

        if success and sourceCode then
            local fileExtension = ".luau"
            if object:IsA("ModuleScript") then
                fileExtension = ".nocollide.luau"
            end
            
            writefile(objectPath .. fileExtension, finalSource)
            decompiledCount = decompiledCount + 1
        else
            local fallbackSource = table.concat(header, "\n") .. "-- Potassium failed to decompile this script.\n-- Error: " .. tostring(sourceCode)
            writefile(objectPath .. "_FAILED.luau", fallbackSource)
            failedCount = failedCount + 1
        end
    else
        local children = object:GetChildren()
        if #children > 0 then
            pcall(makefolder, objectPath)
            
            for _, child in ipairs(children) do
                pcall(function()
                    dumpEnvironment(child, objectPath)
                end)
            end
        end
    end
end

local cleanGameName = sanitizeName(gameName)
local rootFolderName = cleanGameName .. "_Dump_" .. placeId
makefolder(rootFolderName)

local servicesToScan = {
    game:GetService("Workspace"),
    game:GetService("ReplicatedStorage"),
    game:GetService("ReplicatedFirst"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer"),
    game:GetService("Lighting"),
    game:GetService("Teams"),
    game:GetService("SoundService")
}

for _, service in ipairs(servicesToScan) do
    local serviceFolder = rootFolderName .. "/" .. service.ClassName
    makefolder(serviceFolder)
    
    for _, child in ipairs(service:GetChildren()) do
        pcall(function()
            dumpEnvironment(child, serviceFolder)
        end)
    end
end

writefile(rootFolderName .. "/Network_Remotes_Manifest.txt", table.concat(remoteManifest, "\n"))

local report = {
    "--- POTASSIUM DUMP REPORT ---",
    "Game Name: " .. gameName,
    "Place ID: " .. placeId,
    "Universe ID: " .. universeId,
    "---------------------------------",
    "Total Scripts Found: " .. totalScripts,
    "Successfully Decompiled: " .. decompiledCount,
    "Failed/Protected Scripts: " .. failedCount,
    "Dump Location: workspace/" .. rootFolderName
}
local reportStr = table.concat(report, "\n")

writefile(rootFolderName .. "/_Dump_Report.txt", reportStr)
print("✅ Success! Check your executor's workspace folder under: " .. rootFolderName)
