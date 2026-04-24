--[[
    Angel HUB - LogService.lua
    Sistema de logs com níveis, cores e formatação
    
    USO:
        local Log = require("Services/LogService")
        Log:Info("Módulo carregado!")
        Log:Warn("Cuidado com isso")
        Log:Error("Algo deu errado", errorMsg)
        Log:Debug("Valor de x:", tostring(x))
]]

local LogService = {}
LogService.__index = LogService

-- ============================================
-- CONFIGURAÇÃO
-- ============================================

LogService.Levels = {
    DEBUG = { priority = 0, prefix = "[DEBUG]", color = "\27[36m" },  -- Cyan
    INFO  = { priority = 1, prefix = "[INFO]",  color = "\27[32m" },  -- Green
    WARN  = { priority = 2, prefix = "[WARN]",  color = "\27[33m" },  -- Yellow
    ERROR = { priority = 3, prefix = "[ERROR]", color = "\27[31m" },  -- Red
}

LogService.MinLevel = "DEBUG"  -- Nível mínimo para exibir (pode ser alterado)
LogService.Enabled = true
LogService.Prefix = "[Angel HUB]"
LogService.History = {}         -- Guarda histórico de logs
LogService.MaxHistory = 200     -- Máximo de logs no histórico

-- ============================================
-- FUNÇÕES INTERNAS
-- ============================================

local function getTimestamp()
    local ok, time = pcall(function()
        return os.date("%H:%M:%S")
    end)
    return ok and time or "??:??:??"
end

local function shouldLog(level)
    local minPriority = LogService.Levels[LogService.MinLevel].priority
    local msgPriority = LogService.Levels[level].priority
    return msgPriority >= minPriority
end

local function formatMessage(level, ...)
    local parts = {...}
    local message = ""
    for i, part in ipairs(parts) do
        message = message .. tostring(part)
        if i < #parts then
            message = message .. " "
        end
    end
    
    local levelInfo = LogService.Levels[level]
    local timestamp = getTimestamp()
    
    return string.format("%s %s %s %s", LogService.Prefix, levelInfo.prefix, timestamp, message)
end

-- ============================================
-- MÉTODOS PÚBLICOS
-- ============================================

--- Log de nível DEBUG — informações detalhadas para desenvolvimento
function LogService:Debug(...)
    if not self.Enabled then return end
    if shouldLog("DEBUG") then
        local msg = formatMessage("DEBUG", ...)
        print(msg)
        self:_addHistory("DEBUG", msg)
    end
end

--- Log de nível INFO — eventos normais do sistema
function LogService:Info(...)
    if not self.Enabled then return end
    if shouldLog("INFO") then
        local msg = formatMessage("INFO", ...)
        print(msg)
        self:_addHistory("INFO", msg)
    end
end

--- Log de nível WARN — algo inesperado mas não fatal
function LogService:Warn(...)
    if not self.Enabled then return end
    if shouldLog("WARN") then
        local msg = formatMessage("WARN", ...)
        warn(msg)
        self:_addHistory("WARN", msg)
    end
end

--- Log de nível ERROR — erro que precisa atenção
function LogService:Error(...)
    if not self.Enabled then return end
    if shouldLog("ERROR") then
        local msg = formatMessage("ERROR", ...)
        warn(msg) -- warn em vermelho no console
        self:_addHistory("ERROR", msg)
    end
end

--- Adiciona ao histórico (para debug posterior)
function LogService:_addHistory(level, msg)
    table.insert(self.History, {
        level = level,
        message = msg,
        timestamp = tick()
    })
    
    -- Limita tamanho do histórico
    if #self.History > self.MaxHistory then
        table.remove(self.History, 1)
    end
end

--- Altera o nível mínimo de log
--- @param level string "DEBUG" | "INFO" | "WARN" | "ERROR"
function LogService:SetLevel(level)
    if self.Levels[level] then
        self.MinLevel = level
        self:Info("Log level alterado para:", level)
    else
        self:Warn("Nível de log inválido:", tostring(level))
    end
end

--- Retorna histórico de logs
function LogService:GetHistory()
    return self.History
end

--- Limpa histórico
function LogService:ClearHistory()
    self.History = {}
end

--- Retorna string formatada do histórico (para export)
function LogService:ExportHistory()
    local lines = {}
    for _, entry in ipairs(self.History) do
        table.insert(lines, entry.message)
    end
    return table.concat(lines, "\n")
end

return LogService
