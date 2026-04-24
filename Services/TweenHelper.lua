--[[
    Angel HUB - TweenHelper.lua
    Utilitários para animações com TweenService
    Facilita criação de tweens para a UI e efeitos visuais
    
    USO:
        local Tween = require("Services/TweenHelper")
        
        Tween:FadeIn(frame, 0.3)
        Tween:SlideIn(frame, "Left", 0.5)
        Tween:To(frame, 0.3, {BackgroundTransparency = 0})
]]

local TweenHelper = {}
TweenHelper.__index = TweenHelper

-- ============================================
-- REFERÊNCIAS
-- ============================================

local TweenService = game:GetService("TweenService")

-- ============================================
-- ESTILOS PREDEFINIDOS
-- ============================================

TweenHelper.Styles = {
    -- Suave e profissional (padrão)
    Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Rápido para feedback instantâneo
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Lento para transições dramáticas
    Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    
    -- Bounce para notificações
    Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    
    -- Elástico para elementos divertidos
    Elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    
    -- Linear para progresso
    Linear = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
}

-- ============================================
-- CORE
-- ============================================

--- Cria e toca um tween genérico
--- @param instance Instance Objeto a animar
--- @param duration number Duração em segundos
--- @param properties table Propriedades a animar
--- @param style? string Nome do estilo predefinido (default: "Smooth")
--- @param callback? function Função a chamar quando terminar
--- @return Tween O tween criado
function TweenHelper:To(instance, duration, properties, style, callback)
    local tweenInfo
    
    if type(style) == "string" and self.Styles[style] then
        tweenInfo = self.Styles[style]
    elseif typeof(style) == "TweenInfo" then
        tweenInfo = style
    else
        tweenInfo = TweenInfo.new(
            duration or 0.3,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
    end
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- ============================================
-- FADE (Transparência)
-- ============================================

--- Faz um elemento aparecer suavemente (fade in)
function TweenHelper:FadeIn(instance, duration, callback)
    duration = duration or 0.3
    
    -- Tornar visível antes do fade
    instance.Visible = true
    
    local props = {}
    
    if instance:IsA("GuiObject") then
        -- Salvar transparências originais se não salvas
        if instance:GetAttribute("_originalBGTransparency") == nil then
            instance:SetAttribute("_originalBGTransparency", instance.BackgroundTransparency)
        end
        
        instance.BackgroundTransparency = 1
        props.BackgroundTransparency = instance:GetAttribute("_originalBGTransparency") or 0
    end
    
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance.TextTransparency = 1
        props.TextTransparency = 0
    end
    
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        instance.ImageTransparency = 1
        props.ImageTransparency = 0
    end
    
    return self:To(instance, duration, props, "Smooth", callback)
end

--- Faz um elemento desaparecer (fade out)
function TweenHelper:FadeOut(instance, duration, callback)
    duration = duration or 0.3
    
    local props = {}
    
    if instance:IsA("GuiObject") then
        props.BackgroundTransparency = 1
    end
    
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        props.TextTransparency = 1
    end
    
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        props.ImageTransparency = 1
    end
    
    return self:To(instance, duration, props, "Smooth", function()
        instance.Visible = false
        if callback then callback() end
    end)
end

-- ============================================
-- SLIDE (Posição)
-- ============================================

--- Slide in de uma direção
--- @param instance GuiObject
--- @param direction string "Left"|"Right"|"Top"|"Bottom"
--- @param duration number
function TweenHelper:SlideIn(instance, direction, duration, callback)
    duration = duration or 0.35
    direction = direction or "Left"
    
    instance.Visible = true
    
    -- Salvar posição original
    local targetPos = instance.Position
    
    -- Posição inicial fora da tela
    local offsets = {
        Left   = UDim2.new(targetPos.X.Scale - 1, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset),
        Right  = UDim2.new(targetPos.X.Scale + 1, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset),
        Top    = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale - 1, targetPos.Y.Offset),
        Bottom = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale + 1, targetPos.Y.Offset),
    }
    
    instance.Position = offsets[direction] or offsets["Left"]
    
    return self:To(instance, duration, {Position = targetPos}, "Bounce", callback)
end

--- Slide out para uma direção
function TweenHelper:SlideOut(instance, direction, duration, callback)
    duration = duration or 0.3
    direction = direction or "Left"
    
    local currentPos = instance.Position
    
    local offsets = {
        Left   = UDim2.new(currentPos.X.Scale - 1, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset),
        Right  = UDim2.new(currentPos.X.Scale + 1, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset),
        Top    = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale - 1, currentPos.Y.Offset),
        Bottom = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale + 1, currentPos.Y.Offset),
    }
    
    return self:To(instance, duration, {Position = offsets[direction] or offsets["Left"]}, "Smooth", function()
        instance.Visible = false
        instance.Position = currentPos -- Restaurar posição original
        if callback then callback() end
    end)
end

-- ============================================
-- SCALE (Tamanho)
-- ============================================

--- Pop in (começa pequeno, cresce)
function TweenHelper:PopIn(instance, duration, callback)
    duration = duration or 0.3
    instance.Visible = true
    
    local targetSize = instance.Size
    instance.Size = UDim2.new(0, 0, 0, 0)
    
    return self:To(instance, duration, {Size = targetSize}, "Bounce", callback)
end

--- Pop out (encolhe e desaparece)
function TweenHelper:PopOut(instance, duration, callback)
    duration = duration or 0.25
    local originalSize = instance.Size
    
    return self:To(instance, duration, {Size = UDim2.new(0, 0, 0, 0)}, "Smooth", function()
        instance.Visible = false
        instance.Size = originalSize
        if callback then callback() end
    end)
end

-- ============================================
-- HOVER EFFECTS
-- ============================================

--- Adiciona efeito de hover a um botão (escurece/clareia)
function TweenHelper:AddHoverEffect(button, hoverColor, normalColor)
    button.MouseEnter:Connect(function()
        self:To(button, 0.15, {BackgroundColor3 = hoverColor}, "Fast")
    end)
    
    button.MouseLeave:Connect(function()
        self:To(button, 0.15, {BackgroundColor3 = normalColor}, "Fast")
    end)
end

--- Adiciona efeito de escala no hover
function TweenHelper:AddScaleHover(button, scaleUp)
    scaleUp = scaleUp or 1.05
    
    local uiScale = button:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = button
    end
    
    button.MouseEnter:Connect(function()
        self:To(uiScale, 0.15, {Scale = scaleUp}, "Fast")
    end)
    
    button.MouseLeave:Connect(function()
        self:To(uiScale, 0.15, {Scale = 1}, "Fast")
    end)
end

-- ============================================
-- UTILIDADES
-- ============================================

--- Cria um TweenInfo customizado
function TweenHelper:CreateInfo(duration, style, direction, repeatCount, reverses, delay)
    return TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out,
        repeatCount or 0,
        reverses or false,
        delay or 0
    )
end

return TweenHelper
