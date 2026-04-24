--[[
    Angel HUB - ModuleManager.lua
    Sistema de registro, ativação e desativação dinâmica de módulos
    
    COMO FUNCIONA:
    ──────────────
    1. Cada módulo é uma tabela Lua com interface padrão:
       - Name (string): Nome do módulo
       - Category (string): Categoria (Main, Gamemodes, Gacha, etc.)
       - Enabled (boolean): Se está ativo
       - Init(hub): Inicializar (registrar UI, etc.)
       - Enable(): Ativar funcionalidade
       - Disable(): Desativar funcionalidade
       - Destroy(): Limpeza final
    
    2. O ModuleManager mantém registro de todos os módulos
    3. Módulos podem ser ativados/desativados pela UI
    4. O estado é sincronizado com o SaveSystem
    
    USO:
        local MM = require("Core/ModuleManager")
        
        -- Registrar módulo
        MM:Register(meuModulo)
        
        -- Ativar/Desativar
        MM:Enable("Meu Modulo")
        MM:Disable("Meu Modulo")
        MM:Toggle("Meu Modulo")
        
        -- Pegar módulo
        local mod = MM:Get("Meu Modulo")
        
        -- Listar por categoria
        local mainModules = MM:GetByCategory("Main")
]]

local ModuleManager = {}
ModuleManager.__index = ModuleManager

-- ============================================
-- ESTADO INTERNO
-- ============================================

local modules = {}           -- {[name] = moduleTable}
local categories = {}        -- {[category] = {name1, name2, ...}}
local initOrder = {}         -- Ordem de inicialização
local LogService = nil       -- Injetado
local onChangeCallbacks = {} -- Callbacks quando módulo muda de estado

-- ============================================
-- INJEÇÃO
-- ============================================

function ModuleManager:SetLogger(logger)
    LogService = logger
end

local function log(level, ...)
    if LogService then
        LogService[level](LogService, ...)
    else
        print("[ModuleManager]", ...)
    end
end

-- ============================================
-- REGISTRO
-- ============================================

--- Registra um novo módulo no sistema
--- @param moduleTable table Tabela do módulo (deve ter Name e Category)
function ModuleManager:Register(moduleTable)
    -- Validação
    if not moduleTable then
        log("Error", "Tentou registrar módulo nil")
        return false
    end
    
    if not moduleTable.Name then
        log("Error", "Módulo sem Name:", tostring(moduleTable))
        return false
    end
    
    if modules[moduleTable.Name] then
        log("Warn", "Módulo já registrado:", moduleTable.Name)
        return false
    end
    
    -- Defaults
    moduleTable.Category = moduleTable.Category or "Misc"
    moduleTable.Enabled = moduleTable.Enabled or false
    moduleTable.Description = moduleTable.Description or ""
    moduleTable.Icon = moduleTable.Icon or "⚙️"
    
    -- Registrar
    modules[moduleTable.Name] = moduleTable
    table.insert(initOrder, moduleTable.Name)
    
    -- Registrar na categoria
    if not categories[moduleTable.Category] then
        categories[moduleTable.Category] = {}
    end
    table.insert(categories[moduleTable.Category], moduleTable.Name)
    
    log("Debug", "Módulo registrado:", moduleTable.Name, "[" .. moduleTable.Category .. "]")
    return true
end

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

--- Inicializa todos os módulos registrados
--- @param hub table Referência ao hub principal (para os módulos acessarem services)
function ModuleManager:InitAll(hub)
    log("Info", "Inicializando " .. #initOrder .. " módulos...")
    
    for _, name in ipairs(initOrder) do
        local mod = modules[name]
        if mod and mod.Init then
            local ok, err = pcall(mod.Init, mod, hub)
            if ok then
                log("Debug", "  ✓ " .. name)
            else
                log("Error", "  ✗ " .. name .. " - " .. tostring(err))
            end
        end
    end
    
    log("Info", "Módulos inicializados!")
end

-- ============================================
-- ATIVAÇÃO / DESATIVAÇÃO
-- ============================================

--- Ativa um módulo
--- @param name string Nome do módulo
--- @return boolean success
function ModuleManager:Enable(name)
    local mod = modules[name]
    if not mod then
        log("Warn", "Módulo não encontrado:", name)
        return false
    end
    
    if mod.Enabled then
        log("Debug", "Módulo já está ativo:", name)
        return true
    end
    
    if mod.Enable then
        local ok, err = pcall(mod.Enable, mod)
        if ok then
            mod.Enabled = true
            log("Info", "✅ " .. name .. " ATIVADO")
            self:_notifyChange(name, true)
            return true
        else
            log("Error", "Falha ao ativar", name, ":", tostring(err))
            return false
        end
    end
    
    mod.Enabled = true
    self:_notifyChange(name, true)
    return true
end

--- Desativa um módulo
function ModuleManager:Disable(name)
    local mod = modules[name]
    if not mod then
        log("Warn", "Módulo não encontrado:", name)
        return false
    end
    
    if not mod.Enabled then
        log("Debug", "Módulo já está desativado:", name)
        return true
    end
    
    if mod.Disable then
        local ok, err = pcall(mod.Disable, mod)
        if ok then
            mod.Enabled = false
            log("Info", "⛔ " .. name .. " DESATIVADO")
            self:_notifyChange(name, false)
            return true
        else
            log("Error", "Falha ao desativar", name, ":", tostring(err))
            return false
        end
    end
    
    mod.Enabled = false
    self:_notifyChange(name, false)
    return true
end

--- Toggle (inverte estado)
function ModuleManager:Toggle(name)
    local mod = modules[name]
    if not mod then return false end
    
    if mod.Enabled then
        return self:Disable(name)
    else
        return self:Enable(name)
    end
end

--- Verifica se um módulo está ativo
function ModuleManager:IsEnabled(name)
    local mod = modules[name]
    return mod and mod.Enabled or false
end

-- ============================================
-- GETTERS
-- ============================================

--- Retorna um módulo pelo nome
function ModuleManager:Get(name)
    return modules[name]
end

--- Retorna todos os módulos de uma categoria
function ModuleManager:GetByCategory(category)
    local result = {}
    local names = categories[category]
    if not names then return result end
    
    for _, name in ipairs(names) do
        table.insert(result, modules[name])
    end
    
    return result
end

--- Retorna lista de todas as categorias
function ModuleManager:GetCategories()
    local cats = {}
    for cat, _ in pairs(categories) do
        table.insert(cats, cat)
    end
    table.sort(cats) -- Ordem alfabética
    return cats
end

--- Retorna todos os módulos
function ModuleManager:GetAll()
    return modules
end

--- Retorna o número total de módulos
function ModuleManager:GetCount()
    return #initOrder
end

-- ============================================
-- CALLBACKS
-- ============================================

--- Registra callback para quando um módulo muda de estado
--- @param callback function(name: string, enabled: boolean)
function ModuleManager:OnChange(callback)
    table.insert(onChangeCallbacks, callback)
end

function ModuleManager:_notifyChange(name, enabled)
    for _, callback in ipairs(onChangeCallbacks) do
        task.spawn(callback, name, enabled)
    end
end

-- ============================================
-- EXPORTAR/IMPORTAR ESTADOS (para SaveSystem)
-- ============================================

--- Exporta estados de todos os módulos
--- @return table {[name] = enabled}
function ModuleManager:ExportStates()
    local states = {}
    for name, mod in pairs(modules) do
        states[name] = mod.Enabled
    end
    return states
end

--- Importa estados salvos
--- @param states table {[name] = enabled}
function ModuleManager:ImportStates(states)
    if not states then return end
    
    for name, enabled in pairs(states) do
        if modules[name] then
            if enabled then
                self:Enable(name)
            else
                self:Disable(name)
            end
        end
    end
end

-- ============================================
-- DESTRUIÇÃO
-- ============================================

--- Desativa e destroi todos os módulos
function ModuleManager:DestroyAll()
    log("Info", "Destruindo todos os módulos...")
    
    -- Desativar em ordem reversa
    for i = #initOrder, 1, -1 do
        local name = initOrder[i]
        local mod = modules[name]
        
        if mod then
            if mod.Enabled then
                pcall(mod.Disable, mod)
            end
            if mod.Destroy then
                pcall(mod.Destroy, mod)
            end
        end
    end
    
    modules = {}
    categories = {}
    initOrder = {}
    onChangeCallbacks = {}
    
    log("Info", "Todos os módulos destruídos")
end

return ModuleManager
