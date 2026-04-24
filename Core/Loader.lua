--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                    ANGEL HUB v1.0                       ║
    ║              Developer Hub Premium                      ║
    ║                                                         ║
    ║  Criado para uso em jogos com permissão do usuário      ║
    ║  Compatível com: Madium, Synapse, KRNL, Fluxus, etc.   ║
    ╚══════════════════════════════════════════════════════════╝
    
    COMO USAR:
    ──────────
    Este é o Loader principal. Ele carrega todos os serviços,
    inicializa a UI e registra todos os módulos.
    
    Para desenvolvimento LOCAL (copiar e colar):
        1. Cole todo o código no executor
        2. Execute
    
    Para desenvolvimento REMOTO (GitHub):
        loadstring(game:HttpGet("SUA_URL"))()
]]

-- ============================================
-- PROTEÇÃO CONTRA EXECUÇÃO DUPLA
-- ============================================

if getgenv and getgenv().AngelHUB_Loaded then
    warn("[Angel HUB] Já está carregado! Destruindo instância anterior...")
    if getgenv().AngelHUB and getgenv().AngelHUB.Destroy then
        getgenv().AngelHUB:Destroy()
    end
end

-- ============================================
-- HUB PRINCIPAL
-- ============================================

local AngelHUB = {
    Version = "1.0.0",
    Name = "Angel HUB",
    StartTime = tick(),
    
    -- Referências (preenchidas durante Init)
    Init = nil,
    Log = nil,
    Debounce = nil,
    Player = nil,
    Tween = nil,
    Remote = nil,
    ModuleManager = nil,
    UI = nil,
    Config = nil,
    
    -- Estado
    Ready = false,
    Connections = {},  -- Todas as conexões para cleanup
}

-- ============================================
-- SISTEMA DE CARREGAMENTO
-- Simula um sistema de require para scripts de executor
-- (Executores não têm require como Roblox Studio)
-- ============================================

--[[
    EXPLICAÇÃO PARA INICIANTE:
    ─────────────────────────
    No Roblox Studio, você usa "require()" para importar módulos.
    Em executors, não funciona assim. Cada arquivo é um script separado.
    
    Para o hub funcionar como UM ARQUIVO SÓ (mais fácil de usar),
    vamos incluir todos os módulos inline abaixo.
    
    Quando hospedarmos no GitHub, cada módulo será carregado via HTTP.
    
    Por agora, os módulos já foram criados como arquivos separados
    para organização, mas o Loader os carrega inline.
]]

-- ============================================
-- PASSO 1: Carregar Services Base
-- ============================================

local function loadServices()
    print("\n")
    print("╔══════════════════════════════════════╗")
    print("║         🔥 ANGEL HUB v1.0 🔥        ║")
    print("║      Loading Premium Experience      ║")
    print("╚══════════════════════════════════════╝")
    print("")
    
    -- Init (Serviços do Roblox + Detecção de Executor)
    local Init = loadModule("Core/Init")
    AngelHUB.Init = Init:Start()
    
    -- LogService
    AngelHUB.Log = loadModule("Services/LogService")
    AngelHUB.Log:Info("═══ Angel HUB v" .. AngelHUB.Version .. " ═══")
    AngelHUB.Log:Info("Executor detectado:", AngelHUB.Init.Executor.Name)
    AngelHUB.Log:Info("Jogador:", AngelHUB.Init.LocalPlayer.Name)
    
    -- DebounceService
    AngelHUB.Debounce = loadModule("Services/DebounceService")
    AngelHUB.Log:Debug("DebounceService carregado ✓")
    
    -- PlayerService
    AngelHUB.Player = loadModule("Services/PlayerService")
    AngelHUB.Log:Debug("PlayerService carregado ✓")
    
    -- TweenHelper
    AngelHUB.Tween = loadModule("Services/TweenHelper")
    AngelHUB.Log:Debug("TweenHelper carregado ✓")
    
    -- RemoteService
    AngelHUB.Remote = loadModule("Services/RemoteService")
    AngelHUB.Remote:SetLogger(AngelHUB.Log)
    AngelHUB.Log:Debug("RemoteService carregado ✓")
    
    -- ModuleManager
    AngelHUB.ModuleManager = loadModule("Core/ModuleManager")
    AngelHUB.ModuleManager:SetLogger(AngelHUB.Log)
    AngelHUB.Log:Debug("ModuleManager carregado ✓")
end

-- ============================================
-- SISTEMA DE REQUIRE PARA EXECUTORS
-- ============================================

-- Cache de módulos carregados
local loadedModules = {}

--- Carrega um módulo pelo caminho
--- Funciona inline (tudo num arquivo) ou via HTTP (GitHub)
function loadModule(path)
    -- Se já carregou, retorna do cache
    if loadedModules[path] then
        return loadedModules[path]
    end
    
    -- Modo 1: Módulos embutidos (inline)
    -- Quando todos os módulos estão neste arquivo
    if _G.AngelHUB_Modules and _G.AngelHUB_Modules[path] then
        local mod = _G.AngelHUB_Modules[path]()
        loadedModules[path] = mod
        return mod
    end
    
    -- Modo 2: Carregar via HTTP (GitHub)
    if AngelHUB.BaseURL then
        local url = AngelHUB.BaseURL .. path .. ".lua"
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok then
            loadedModules[path] = result
            return result
        else
            warn("[Angel HUB] Falha ao carregar via HTTP: " .. tostring(result))
        end
    end
    
    -- Modo 3: Carregar de arquivo local (writefile/readfile)
    if AngelHUB.Init and AngelHUB.Init.Executor.HasReadFile then
        local filePath = "AngelHUB/" .. path .. ".lua"
        if AngelHUB.Init.FileExists(filePath) then
            local ok, result = pcall(function()
                return loadstring(readfile(filePath))()
            end)
            if ok then
                loadedModules[path] = result
                return result
            end
        end
    end
    
    error("[Angel HUB] Não foi possível carregar módulo: " .. path)
end

-- ============================================
-- PASSO 2: Carregar UI (será implementada na Fase 2)
-- ============================================

local function loadUI()
    AngelHUB.Log:Info("Carregando sistema de UI...")
    
    -- TODO: Fase 2 - Sistema de UI Premium
    -- AngelHUB.UI = loadModule("UI/Framework")
    -- AngelHUB.UI:Init(AngelHUB)
    
    AngelHUB.Log:Info("UI carregada ✓ (placeholder)")
end

-- ============================================
-- PASSO 3: Registrar Módulos (será implementado na Fase 4)
-- ============================================

local function loadModules()
    AngelHUB.Log:Info("Registrando módulos...")
    
    -- TODO: Fase 4 - Módulos
    -- Cada módulo se auto-registra via ModuleManager:Register()
    
    -- Inicializar todos os módulos registrados
    AngelHUB.ModuleManager:InitAll(AngelHUB)
    
    AngelHUB.Log:Info("Módulos registrados ✓")
end

-- ============================================
-- PASSO 4: Carregar configurações salvas
-- ============================================

local function loadConfig()
    AngelHUB.Log:Info("Carregando configurações...")
    
    -- TODO: Fase 3 - SaveSystem
    -- AngelHUB.Config = loadModule("Config/SaveSystem")
    -- local saved = AngelHUB.Config:Load()
    -- AngelHUB.ModuleManager:ImportStates(saved.moduleStates)
    
    AngelHUB.Log:Info("Configurações carregadas ✓ (placeholder)")
end

-- ============================================
-- DESTRUIÇÃO (Cleanup completo)
-- ============================================

function AngelHUB:Destroy()
    self.Log:Info("Destruindo Angel HUB...")
    
    -- Desativar todos os módulos
    self.ModuleManager:DestroyAll()
    
    -- Desconectar todas as conexões
    for _, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.Connections = {}
    
    -- Limpar debounces
    self.Debounce:ResetAll()
    
    -- Limpar remotes
    self.Remote:Destroy()
    
    -- Destruir UI
    if self.UI and self.UI.Destroy then
        self.UI:Destroy()
    end
    
    -- Limpar ScreenGui
    local playerGui = self.Init.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local gui = playerGui:FindFirstChild("AngelHUB")
        if gui then gui:Destroy() end
    end
    
    -- Limpar global
    if getgenv then
        getgenv().AngelHUB_Loaded = false
        getgenv().AngelHUB = nil
    end
    
    self.Ready = false
    self.Log:Info("Angel HUB destruído! Até a próxima 👋")
end

-- ============================================
-- INICIALIZAÇÃO PRINCIPAL
-- ============================================

local function main()
    local ok, err = pcall(function()
        -- Passo 1: Services
        loadServices()
        
        -- Passo 2: UI
        loadUI()
        
        -- Passo 3: Módulos
        loadModules()
        
        -- Passo 4: Config
        loadConfig()
        
        -- Marcar como pronto
        AngelHUB.Ready = true
        
        -- Registrar globalmente
        if getgenv then
            getgenv().AngelHUB_Loaded = true
            getgenv().AngelHUB = AngelHUB
        end
        
        -- Estatísticas
        local loadTime = string.format("%.2f", tick() - AngelHUB.StartTime)
        AngelHUB.Log:Info("")
        AngelHUB.Log:Info("╔══════════════════════════════════════╗")
        AngelHUB.Log:Info("║      ✅ ANGEL HUB CARREGADO!        ║")
        AngelHUB.Log:Info("║  Tempo: " .. loadTime .. "s                        ║")
        AngelHUB.Log:Info("║  Módulos: " .. AngelHUB.ModuleManager:GetCount() .. "                           ║")
        AngelHUB.Log:Info("║  Executor: " .. AngelHUB.Init.Executor.Name .. string.rep(" ", math.max(0, 24 - #AngelHUB.Init.Executor.Name)) .. "║")
        AngelHUB.Log:Info("╚══════════════════════════════════════╝")
        AngelHUB.Log:Info("")
    end)
    
    if not ok then
        warn("[Angel HUB] ❌ ERRO FATAL durante inicialização:")
        warn(tostring(err))
    end
end

-- ============================================
-- EXECUTAR!
-- ============================================

main()

return AngelHUB
