--[[
    Angel HUB - RemoteService.lua
    Helper para descobrir e interagir com RemoteEvents/RemoteFunctions
    
    IMPORTANTE PARA INICIANTES:
    ─────────────────────────────
    RemoteEvents são a forma como o CLIENT se comunica com o SERVER no Roblox.
    Quando você clica num NPC, seu client envia um RemoteEvent pro server.
    O server processa e responde.
    
    Para automatizar ações, precisamos descobrir quais RemoteEvents o jogo usa.
    É aí que entra o Remote Spy (SimpleSpy).
    
    USO:
        local Remote = require("Services/RemoteService")
        
        -- Encontrar um remote
        local attackRemote = Remote:Find("Attack")
        
        -- Disparar um remote
        Remote:Fire("Attack", targetMob, damage)
        
        -- Listar todos os remotes
        Remote:ListAll()
        
        -- Espionar remotes em tempo real
        Remote:Spy(true)
]]

local RemoteService = {}
RemoteService.__index = RemoteService

-- ============================================
-- REFERÊNCIAS
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService -- será injetado pelo Loader

-- ============================================
-- CACHE
-- ============================================

local remoteCache = {} -- Cache de remotes encontrados

-- ============================================
-- INJEÇÃO DE DEPENDÊNCIA
-- ============================================

function RemoteService:SetLogger(logger)
    LogService = logger
end

local function log(level, ...)
    if LogService then
        LogService[level](LogService, ...)
    else
        print("[RemoteService]", ...)
    end
end

-- ============================================
-- BUSCA DE REMOTES
-- ============================================

--- Encontra um RemoteEvent/RemoteFunction pelo nome
--- Busca em ReplicatedStorage recursivamente
--- @param name string Nome (parcial) do remote
--- @param searchIn? Instance Onde buscar (default: ReplicatedStorage)
--- @return Instance|nil O remote encontrado
function RemoteService:Find(name, searchIn)
    -- Checar cache primeiro
    if remoteCache[name] then
        if remoteCache[name].Parent then -- verify still exists
            return remoteCache[name]
        else
            remoteCache[name] = nil
        end
    end
    
    searchIn = searchIn or ReplicatedStorage
    
    local function searchRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("UnreliableRemoteEvent"))
                and child.Name:lower():find(name:lower()) then
                remoteCache[name] = child
                return child
            end
            
            -- Buscar em subpastas
            local result = searchRecursive(child)
            if result then return result end
        end
        return nil
    end
    
    -- Buscar em ReplicatedStorage
    local result = searchRecursive(searchIn)
    
    -- Se não encontrou, buscar no Workspace também
    if not result then
        result = searchRecursive(game:GetService("Workspace"))
    end
    
    if result then
        log("Debug", "Remote encontrado:", result:GetFullName())
    else
        log("Warn", "Remote não encontrado:", name)
    end
    
    return result
end

--- Encontra um remote pelo caminho exato
--- @param path string Ex: "game.ReplicatedStorage.Events.Attack"
function RemoteService:FindByPath(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = game
    for i, part in ipairs(parts) do
        if part ~= "game" then
            current = current:FindFirstChild(part)
            if not current then
                log("Warn", "Caminho não encontrado:", path, "- parou em:", part)
                return nil
            end
        end
    end
    
    if current:IsA("RemoteEvent") or current:IsA("RemoteFunction") or current:IsA("UnreliableRemoteEvent") then
        remoteCache[current.Name] = current
        return current
    end
    
    log("Warn", "Objeto encontrado mas não é um Remote:", current.ClassName)
    return nil
end

-- ============================================
-- DISPARO DE REMOTES
-- ============================================

--- Dispara um RemoteEvent
--- @param remote Instance|string O remote ou nome do remote
--- @param ... any Argumentos para o server
function RemoteService:Fire(remote, ...)
    if type(remote) == "string" then
        remote = self:Find(remote)
    end
    
    if not remote then
        log("Error", "Tentou disparar remote que não existe")
        return false
    end
    
    local ok, err
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        ok, err = pcall(function(...)
            remote:FireServer(...)
        end, ...)
    elseif remote:IsA("RemoteFunction") then
        ok, err = pcall(function(...)
            return remote:InvokeServer(...)
        end, ...)
    end
    
    if not ok then
        log("Error", "Falha ao disparar remote:", remote.Name, "-", tostring(err))
    end
    
    return ok, err
end

--- Dispara um RemoteEvent e retorna o resultado (para RemoteFunctions)
function RemoteService:Invoke(remote, ...)
    if type(remote) == "string" then
        remote = self:Find(remote)
    end
    
    if not remote or not remote:IsA("RemoteFunction") then
        log("Error", "Remote inválido ou não é RemoteFunction")
        return nil
    end
    
    local ok, result = pcall(function(...)
        return remote:InvokeServer(...)
    end, ...)
    
    if ok then
        return result
    else
        log("Error", "Falha ao invocar:", remote.Name, "-", tostring(result))
        return nil
    end
end

-- ============================================
-- LISTAGEM / EXPLORAÇÃO
-- ============================================

--- Lista todos os RemoteEvents e RemoteFunctions no jogo
--- @param searchIn? Instance Onde buscar
--- @return table Lista de {name, path, type}
function RemoteService:ListAll(searchIn)
    searchIn = searchIn or ReplicatedStorage
    local results = {}
    
    local function searchRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("UnreliableRemoteEvent") then
                table.insert(results, {
                    name = child.Name,
                    path = child:GetFullName(),
                    type = child.ClassName
                })
            end
            searchRecursive(child)
        end
    end
    
    searchRecursive(searchIn)
    
    -- Printear tudo formatado
    log("Info", "═══ REMOTES ENCONTRADOS (" .. #results .. ") ═══")
    for i, remote in ipairs(results) do
        log("Info", string.format("  %d. [%s] %s", i, remote.type, remote.path))
    end
    log("Info", "═══════════════════════════════════════")
    
    return results
end

--- Lista remotes com filtro por nome
function RemoteService:Search(query)
    local all = self:ListAll()
    local filtered = {}
    
    for _, remote in ipairs(all) do
        if remote.name:lower():find(query:lower()) or remote.path:lower():find(query:lower()) then
            table.insert(filtered, remote)
        end
    end
    
    log("Info", "═══ BUSCA: '" .. query .. "' (" .. #filtered .. " resultados) ═══")
    for i, remote in ipairs(filtered) do
        log("Info", string.format("  %d. [%s] %s", i, remote.type, remote.path))
    end
    
    return filtered
end

-- ============================================
-- ESPIONAGEM (Mini Remote Spy integrado)
-- ============================================

local spyConnections = {}
local spyEnabled = false

--- Ativa espionagem de remotes (mostra no console quando um remote é disparado)
--- NOTA: Funcionalidade limitada sem hookfunction.
--- Para espionagem completa, use SimpleSpy.
function RemoteService:Spy(enabled)
    spyEnabled = enabled
    
    if enabled then
        log("Info", "🔎 Remote Spy ATIVADO - Monitorando remotes...")
        
        -- Monitorar novos remotes adicionados
        local conn = ReplicatedStorage.DescendantAdded:Connect(function(desc)
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                log("Debug", "📡 Novo remote criado:", desc:GetFullName())
            end
        end)
        table.insert(spyConnections, conn)
    else
        log("Info", "🔎 Remote Spy DESATIVADO")
        for _, conn in ipairs(spyConnections) do
            conn:Disconnect()
        end
        spyConnections = {}
    end
end

-- ============================================
-- LIMPEZA
-- ============================================

function RemoteService:ClearCache()
    remoteCache = {}
end

function RemoteService:Destroy()
    self:Spy(false)
    self:ClearCache()
end

return RemoteService
