--[[
    Angel HUB - DebounceService.lua
    Prevents duplicate function and loop execution
    
    PROBLEM IT SOLVES:
    If you have a button that activates a loop, and the user clicks 5 times,
    sem debounce terá 5 loops rodando ao mesmo tempo = lag/crash.
    
    USO:
        local Debounce = require("Services/DebounceService")
        
        -- Exemplo 1: Cooldown simples
        if Debounce:Check("auto_farm") then
            Debounce:Lock("auto_farm")
            -- faz algo...
            Debounce:Unlock("auto_farm")
        end
        
        -- Exemplo 2: Com cooldown automático (2 segundos)
        if Debounce:CheckCooldown("attack", 2) then
            -- ataque executado, próximo só em 2s
        end
]]

local DebounceService = {}
DebounceService.__index = DebounceService

-- ============================================
-- ESTADO INTERNO
-- ============================================

local locks = {}      -- Locks booleanos simples
local cooldowns = {}  -- Cooldowns com timestamp
local activeLoops = {} -- Loops ativos para controle de cancel

-- ============================================
-- LOCKS SIMPLES (on/off)
-- ============================================

--- Verifica se uma key NÃO está travada
--- @param key string Identificador único
--- @return boolean true se pode executar
function DebounceService:Check(key)
    return not locks[key]
end

--- Trava uma key (impede execução)
function DebounceService:Lock(key)
    locks[key] = true
end

--- Destrava uma key (permite execução novamente)
function DebounceService:Unlock(key)
    locks[key] = false
end

--- Verifica e trava atomicamente (check + lock em um passo)
--- @return boolean true se conseguiu travar (estava livre)
function DebounceService:TryLock(key)
    if not locks[key] then
        locks[key] = true
        return true
    end
    return false
end

-- ============================================
-- COOLDOWNS (com tempo)
-- ============================================

--- Verifica se o cooldown já passou e renova automaticamente
--- @param key string Identificador único
--- @param cooldownTime number Tempo em segundos
--- @return boolean true se pode executar
function DebounceService:CheckCooldown(key, cooldownTime)
    local now = tick()
    if not cooldowns[key] or (now - cooldowns[key]) >= cooldownTime then
        cooldowns[key] = now
        return true
    end
    return false
end

--- Retorna quanto tempo falta para o cooldown acabar
--- @param key string
--- @param cooldownTime number
--- @return number Tempo restante em segundos (0 se já expirou)
function DebounceService:GetRemainingCooldown(key, cooldownTime)
    if not cooldowns[key] then return 0 end
    local elapsed = tick() - cooldowns[key]
    local remaining = cooldownTime - elapsed
    return remaining > 0 and remaining or 0
end

--- Reseta um cooldown específico
function DebounceService:ResetCooldown(key)
    cooldowns[key] = nil
end

-- ============================================
-- CONTROLE DE LOOPS
-- Para loops tipo "while autoFarm do ... end"
-- ============================================

--- Registra um loop como ativo
--- @param key string Nome do loop
--- @return string ID único do loop (para verificar se É este loop que deve rodar)
function DebounceService:StartLoop(key)
    local id = key .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
    activeLoops[key] = id
    return id
end

--- Verifica se um loop específico ainda é o loop ativo
--- (Se outro loop foi iniciado com a mesma key, este deve parar)
--- @param key string Nome do loop
--- @param loopId string ID retornado por StartLoop
--- @return boolean true se este loop ainda é o ativo
function DebounceService:IsLoopActive(key, loopId)
    return activeLoops[key] == loopId
end

--- Para um loop (qualquer loop novo com essa key vai substituir)
function DebounceService:StopLoop(key)
    activeLoops[key] = nil
end

--- Verifica se existe algum loop ativo para uma key
function DebounceService:HasActiveLoop(key)
    return activeLoops[key] ~= nil
end

-- ============================================
-- RESET GERAL
-- ============================================

--- Limpa tudo (útil ao destruir o hub)
function DebounceService:ResetAll()
    locks = {}
    cooldowns = {}
    activeLoops = {}
end

return DebounceService
