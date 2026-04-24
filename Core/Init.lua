--[[
    Angel HUB - Init.lua
    Inicialização de todos os serviços do Roblox
    Cria referências seguras para uso em todo o hub
    
    COMPATIBILIDADE: Universal (funciona em qualquer executor com UNC básico)
]]

local Init = {}

-- ============================================
-- SERVIÇOS DO ROBLOX
-- Referências centralizadas para evitar repetição
-- ============================================

Init.Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
    HttpService = game:GetService("HttpService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
}

-- ============================================
-- INFORMAÇÕES DO JOGADOR LOCAL
-- ============================================

Init.LocalPlayer = Init.Services.Players.LocalPlayer

-- ============================================
-- DETECÇÃO DE EXECUTOR
-- Detecta qual executor está sendo usado e quais funções estão disponíveis
-- ============================================

Init.Executor = {
    Name = "Unknown",
    
    -- Funções de arquivo (para salvar configs)
    HasWriteFile = pcall(function() return writefile end),
    HasReadFile = pcall(function() return readfile end),
    HasIsFile = pcall(function() return isfile end),
    HasDelFile = pcall(function() return delfile end),
    HasMakeFolder = pcall(function() return makefolder end),
    HasIsFolderFunc = pcall(function() return isfolder end),
    
    -- Funções de ambiente
    HasGetGenv = pcall(function() return getgenv end),
    HasGetSenv = pcall(function() return getsenv end),
    
    -- Funções de clipboard
    HasSetClipboard = pcall(function() return setclipboard end),
    
    -- Funções de HTTP
    HasHttpGet = pcall(function() return game.HttpGet end),
    HasHttpRequest = pcall(function() return (request or http_request or syn and syn.request) end),
    
    -- Funções de hooking (avançado)
    HasHookFunction = pcall(function() return hookfunction end),
    HasGetNamecallMethod = pcall(function() return getnamecallmethod end),
}

-- Tentar detectar o nome do executor
local function detectExecutor()
    -- Lista de identificadores conhecidos
    local executors = {
        { check = function() return MADIUM_LOADED or identifyexecutor and identifyexecutor():lower():find("madium") end, name = "Madium" },
        { check = function() return syn and syn.request end, name = "Synapse X" },
        { check = function() return KRNL_LOADED end, name = "KRNL" },
        { check = function() return fluxus and fluxus.request end, name = "Fluxus" },
        { check = function() return getexecutorname and getexecutorname() end, name = nil }, -- Usa o retorno
        { check = function() return identifyexecutor and identifyexecutor() end, name = nil },
    }
    
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then
            if exec.name then
                return exec.name
            else
                return tostring(result)
            end
        end
    end
    
    return "Unknown"
end

Init.Executor.Name = detectExecutor()

-- ============================================
-- FUNÇÕES UTILITÁRIAS UNIVERSAIS
-- Wrappers que funcionam em qualquer executor
-- ============================================

--- Escreve um arquivo (com fallback seguro)
function Init.WriteFile(path, content)
    if Init.Executor.HasWriteFile then
        local ok, err = pcall(writefile, path, content)
        return ok, err
    end
    return false, "writefile not supported"
end

--- Lê um arquivo
function Init.ReadFile(path)
    if Init.Executor.HasReadFile then
        local ok, result = pcall(readfile, path)
        if ok then return result end
    end
    return nil
end

--- Verifica se arquivo existe
function Init.FileExists(path)
    if Init.Executor.HasIsFile then
        local ok, result = pcall(isfile, path)
        if ok then return result end
    end
    return false
end

--- Cria pasta
function Init.MakeFolder(path)
    if Init.Executor.HasMakeFolder then
        local ok, err = pcall(makefolder, path)
        return ok, err
    end
    return false, "makefolder not supported"
end

--- Verifica se pasta existe
function Init.FolderExists(path)
    if Init.Executor.HasIsFolderFunc then
        local ok, result = pcall(isfolder, path)
        if ok then return result end
    end
    return false
end

--- Copia texto para clipboard
function Init.SetClipboard(text)
    if Init.Executor.HasSetClipboard then
        local ok = pcall(setclipboard, text)
        return ok
    end
    return false
end

-- ============================================
-- SETUP DE PASTAS
-- Cria estrutura de pastas para salvar configs
-- ============================================

function Init:SetupFolders()
    local folders = {
        "AngelHUB",
        "AngelHUB/Config",
        "AngelHUB/Logs",
    }
    
    for _, folder in ipairs(folders) do
        if not self.FolderExists(folder) then
            self.MakeFolder(folder)
        end
    end
end

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

function Init:Start()
    self:SetupFolders()
    return self
end

return Init
