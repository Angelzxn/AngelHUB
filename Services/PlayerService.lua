--[[
    Angel HUB - PlayerService.lua
    Utilitários para informações do jogador local
    
    USO:
        local Player = require("Services/PlayerService")
        
        print(Player:GetPosition())      -- Vector3
        print(Player:IsAlive())           -- true/false
        print(Player:GetHealth())         -- 100
        Player:Teleport(Vector3.new(0, 10, 0))
]]

local PlayerService = {}
PlayerService.__index = PlayerService

-- ============================================
-- REFERÊNCIAS
-- ============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- GETTERS BÁSICOS
-- ============================================

--- Retorna o jogador local
function PlayerService:GetPlayer()
    return LocalPlayer
end

--- Retorna o Character atual (ou nil se não existir)
function PlayerService:GetCharacter()
    return LocalPlayer and LocalPlayer.Character
end

--- Retorna o Humanoid (ou nil)
function PlayerService:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

--- Retorna o HumanoidRootPart (ou nil)
function PlayerService:GetRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

--- Retorna a posição atual como Vector3 (ou Vector3.zero)
function PlayerService:GetPosition()
    local root = self:GetRootPart()
    return root and root.Position or Vector3.new(0, 0, 0)
end

--- Retorna o CFrame do root part
function PlayerService:GetCFrame()
    local root = self:GetRootPart()
    return root and root.CFrame or CFrame.new()
end

-- ============================================
-- STATUS
-- ============================================

--- Verifica se o jogador está vivo
function PlayerService:IsAlive()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.Health > 0
end

--- Retorna a vida atual
function PlayerService:GetHealth()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.Health or 0
end

--- Retorna a vida máxima
function PlayerService:GetMaxHealth()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.MaxHealth or 0
end

--- Retorna a porcentagem de vida (0-1)
function PlayerService:GetHealthPercent()
    local maxHP = self:GetMaxHealth()
    if maxHP <= 0 then return 0 end
    return self:GetHealth() / maxHP
end

--- Retorna o WalkSpeed atual
function PlayerService:GetWalkSpeed()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.WalkSpeed or 16
end

--- Define o WalkSpeed
function PlayerService:SetWalkSpeed(speed)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

--- Retorna o JumpPower atual
function PlayerService:GetJumpPower()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.JumpPower or 50
end

--- Define o JumpPower
function PlayerService:SetJumpPower(power)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.JumpPower = power
    end
end

-- ============================================
-- TELEPORTE
-- ============================================

--- Teleporta o jogador para uma posição
--- @param position Vector3|CFrame Destino
function PlayerService:Teleport(position)
    local root = self:GetRootPart()
    if not root then return false end
    
    if typeof(position) == "CFrame" then
        root.CFrame = position
    elseif typeof(position) == "Vector3" then
        root.CFrame = CFrame.new(position)
    end
    
    return true
end

--- Teleporta para outro jogador pelo nome
--- @param playerName string Nome (parcial) do jogador
function PlayerService:TeleportToPlayer(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(playerName:lower()) then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                return self:Teleport(root.CFrame * CFrame.new(0, 0, 3))
            end
        end
    end
    return false
end

--- Teleporta para uma Part/Model pelo caminho no Explorer
--- @param path string Ex: "game.Workspace.SpawnPoint"
function PlayerService:TeleportToPath(path)
    local target = nil
    local ok, err = pcall(function()
        -- Resolve o caminho como string
        local parts = {}
        for part in path:gmatch("[^%.]+") do
            table.insert(parts, part)
        end
        
        target = game
        for i, part in ipairs(parts) do
            if part ~= "game" then
                target = target:FindFirstChild(part)
                if not target then break end
            end
        end
    end)
    
    if target then
        local pos
        if target:IsA("BasePart") then
            pos = target.CFrame
        elseif target:IsA("Model") and target:FindFirstChild("HumanoidRootPart") then
            pos = target.HumanoidRootPart.CFrame
        elseif target:IsA("Model") and target.PrimaryPart then
            pos = target.PrimaryPart.CFrame
        end
        
        if pos then
            return self:Teleport(pos * CFrame.new(0, 5, 0))
        end
    end
    
    return false
end

-- ============================================
-- EVENTOS
-- ============================================

--- Executa callback quando o Character spawna/respawna
--- @param callback function Função a chamar (recebe o Character)
--- @return RBXScriptConnection Conexão (para desconectar depois)
function PlayerService:OnCharacterAdded(callback)
    -- Se já tem character, chama imediatamente
    if LocalPlayer.Character then
        task.spawn(callback, LocalPlayer.Character)
    end
    
    return LocalPlayer.CharacterAdded:Connect(callback)
end

--- Executa callback quando o jogador morre
--- @param callback function
--- @return RBXScriptConnection
function PlayerService:OnDeath(callback)
    return self:OnCharacterAdded(function(char)
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(callback)
        end
    end)
end

-- ============================================
-- DISTÂNCIA
-- ============================================

--- Calcula distância até um ponto
--- @param position Vector3
--- @return number Distância (ou math.huge se inválido)
function PlayerService:DistanceTo(position)
    local myPos = self:GetPosition()
    if myPos.Magnitude == 0 then return math.huge end
    return (myPos - position).Magnitude
end

--- Calcula distância até uma Part
function PlayerService:DistanceToPart(part)
    if part and part:IsA("BasePart") then
        return self:DistanceTo(part.Position)
    end
    return math.huge
end

--- Encontra o NPC/Mob mais próximo dentro de uma pasta
--- @param folder Instance Pasta contendo os mobs
--- @param maxRange number Distância máxima (opcional, default infinito)
--- @return Instance|nil, number O mob mais próximo e sua distância
function PlayerService:FindNearest(folder, maxRange)
    maxRange = maxRange or math.huge
    local nearest = nil
    local nearestDist = maxRange
    
    for _, child in ipairs(folder:GetChildren()) do
        local part = nil
        if child:IsA("BasePart") then
            part = child
        elseif child:IsA("Model") then
            part = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
        end
        
        if part then
            local dist = self:DistanceTo(part.Position)
            if dist < nearestDist then
                nearestDist = dist
                nearest = child
            end
        end
    end
    
    return nearest, nearestDist
end

return PlayerService
