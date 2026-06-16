if not writefile then
    return warn("🛑 [ERRO]: Seu executor não suporta a função 'writefile'.")
end

local decompileFunc = decompile or disassemble or (potassium and potassium.decompile)
if not decompileFunc then
    return warn("🛑 [ERRO]: Descompilador não encontrado.")
end

-- Obtém e higieniza o nome do jogo de forma segura
local MarketplaceService = game:GetService("MarketplaceService")
local gameName = "Jogo_Desconhecido"
local successName, info = pcall(function() 
    return MarketplaceService:GetProductInfo(game.PlaceId) 
end)

if successName and info and info.Name then
    gameName = info.Name:gsub('[%\\%:%*%?%"%<%>%|%/]', "_"):gsub("%s+", "_")
else
    gameName = "Place_" .. tostring(game.PlaceId)
end

local fileName = gameName .. "_dump.json"
print("🔍 [DUMP OTIMIZADO]: Iniciando mapeamento para o arquivo: " .. fileName)

local totalScripts = 0
local decompiledCount = 0
local failedCount = 0
local remoteManifest = { "--- NETWORK REMOTE MANIFEST ---" }
local fileStructure = {}

local function sanitizeName(name)
    return name:gsub('[%\\%:%*%?%"%<%>%|%/]', "_")
end

-- Watchdog de 1.2 segundos para evitar travamentos
local function safeDecompile(object)
    local done = false
    local success, result
    
    task.spawn(function()
        success, result = pcall(function()
            return decompileFunc(object)
        end)
        done = true
    end)
    
    local startTime = os.clock()
    while not done do
        if os.clock() - startTime > 1.2 then
            return false, "TIMEOUT"
        end
        task.wait()
    end
    return success, result
end

-- Varredura iterativa em fila (BFS)
local function scanHierarchy(rootObject, initialPath)
    local queue = { {rootObject, initialPath} }
    local head = 1
    local tail = 2

    while head < tail do
        local data = queue[head]
        head = head + 1
        
        local object = data[1]
        local currentPath = data[2]

        if object and not (object:IsA("Player") or object:IsA("NetworkPeer")) then
            local safeName = sanitizeName(object.Name)
            local objectPath = currentPath .. "/" .. safeName

            -- Captura apenas Remotes essenciais do jogo
            if object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
                table.insert(remoteManifest, "[" .. object.ClassName .. "] " .. object:GetFullName())
            end

            -- Captura e Descompila apenas Scripts criados no jogo (ignora lixo nativo)
            if object:IsA("LuaSourceContainer") then
                local fullName = object:GetFullName()
                
                if not fullName:find("RobloxReplicatedStorage") and not fullName:find("ChatServiceRunner") then
                    totalScripts = totalScripts + 1
                    
                    print("📝 Decompilando -> " .. safeName)
                    local success, sourceCode = safeDecompile(object)
                    
                    if success and sourceCode and #sourceCode > 0 then
                        local header = "-- Path: " .. fullName .. "\n-------------------------\n\n"
                        local fileExtension = object:IsA("ModuleScript") and ".nocollide.luau" or ".luau"
                        fileStructure[objectPath .. fileExtension] = header .. sourceCode
                        decompiledCount = decompiledCount + 1
                    else
                        failedCount = failedCount + 1
                    end
                end
            end

            -- Continua descendo na hierarquia do jogo de forma segura
            local successChildren, children = pcall(function() return object:GetChildren() end)
            if successChildren and children and #children > 0 then
                for i = 1, #children do
                    queue[tail] = {children[i], objectPath}
                    tail = tail + 1
                end
            end
        end
    end
end

-- Apenas os locais onde o código do jogo realmente fica
local gameServices = {
    {name = "Workspace", service = game:GetService("Workspace")},
    {name = "ReplicatedStorage", service = game:GetService("ReplicatedStorage")},
    {name = "ReplicatedFirst", service = game:GetService("ReplicatedFirst")},
    {name = "StarterGui", service = game:GetService("StarterGui")},
    {name = "StarterPack", service = game:GetService("StarterPack")},
    {name = "StarterPlayer", service = game:GetService("StarterPlayer")},
    {name = "Teams", service = game:GetService("Teams")},
    {name = "SoundService", service = game:GetService("SoundService")}
}

for _, data in ipairs(gameServices) do
    if data.service then
        print("🌐 Escaneando: " .. data.name)
        pcall(function()
            scanHierarchy(data.service, data.name)
        end)
        task.wait(0.05)
    end
end

-- Junta os manifestos se houver conteúdo relevante
if #remoteManifest > 1 then
    fileStructure["Network_Remotes_Manifest.txt"] = table.concat(remoteManifest, "\n")
end
fileStructure["_Dump_Report.txt"] = "Scripts do Jogo Encontrados: " .. totalScripts .. "\nSucesso: " .. decompiledCount .. "\nFalhas/Vazios: " .. failedCount

local HttpService = game:GetService("HttpService")
local successEncode, jsonResult = pcall(function()
    return HttpService:JSONEncode(fileStructure)
end)

if successEncode then
    writefile(fileName, jsonResult)
    print("✅ [CONCLUÍDO]: Arquivo '" .. fileName .. "' gerado na pasta workspace!")
else
    print("🛑 [ERRO]: Falha ao gerar o JSON.")
end
