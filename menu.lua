-- ===================================
-- SERVICIOS
-- ===================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===================================
-- CONFIGURACIÓN (FUNCIONALIDAD)
-- ===================================
local CONFIG = {
    Range = 30,
    AttackInterval = 0,
    MaxTargets = 3,
    NotificationDuration = 2,
    RemoteEvent = game:GetService("ReplicatedStorage").Events.ToolEvents.Mine,
    AttackMode = "Players",
    
    BASE_SPEED = 40,
    BOOST_SPEED = 80,
    VERTICAL_SPEED = 25,
    ACCELERATION = 50,
    MAX_SPEED = 120,
    BODY_MOVER_FORCE = 3000,
    
    WalkSpeed = 50,
    JumpPower = 50
}

-- ============================================================
-- 🔰 CONFIGURACIÓN INICIAL: RUTAS Y NOMBRES (ORES / SECRETS)
-- ============================================================
-- 🔸 RUTAS PRINCIPALES (mantienen su funcionamiento original)
local principalOres = "Ores"
local principalSecrets = "Secrets"

-- 🔸 RUTAS ADICIONALES (solo se usarán si hay nombres agregados)
local ORE_PATHS = {
    "Mechanisms.Volcano",
    "ShootingStar.Ores",
	"Mechanisms.HiddenCity",
	"SpaceshipCrash.Ores",
	"Mechanisms.FloraTemple"
}

local SECRET_PATHS = {
    "NewArea.SecretsZone",
	"Christmas Gift"
}

-- 🔸 NOMBRES ADICIONALES (solo se buscarán estos nombres)
local oresAddNames = { "Star Rock", "Fire Opal Rock", "Olivine Rock", "Secret Tanzanite Chest", "Tanzanite Rock" }
local secretAddNames = { "Ancient Relic", "Mystic Orb", "Christmas Gift" }
-- ============================================================

local BOOST_KEY = Enum.KeyCode.LeftControl
local NOCLIP_KEY = Enum.KeyCode.N

-- ===================================
-- NUEVA CONFIGURACIÓN DE INTERFAZ (VISUAL MODERNA)
-- ===================================
local UI_CONFIG = {
    -- Colores principales (tema oscuro premium)
    PRIMARY = Color3.fromRGB(12, 12, 18),
    SECONDARY = Color3.fromRGB(18, 18, 28),
    TERTIARY = Color3.fromRGB(28, 28, 42),
    QUATERNARY = Color3.fromRGB(38, 38, 55),
    
    -- Colores de acento (gradiente cyan-purple)
    ACCENT = Color3.fromRGB(0, 200, 255),
    ACCENT2 = Color3.fromRGB(138, 43, 226),
    ACCENT3 = Color3.fromRGB(255, 0, 128),
    
    -- Colores de estado
    SUCCESS = Color3.fromRGB(0, 255, 136),
    WARNING = Color3.fromRGB(255, 200, 0),
    DANGER = Color3.fromRGB(255, 60, 80),
    INFO = Color3.fromRGB(100, 180, 255),
    
    -- Texto
    TEXT = Color3.fromRGB(255, 255, 255),
    TEXT_MUTED = Color3.fromRGB(150, 150, 180),
    TEXT_DARK = Color3.fromRGB(100, 100, 130),
    
    -- Fuentes
    FONT = Enum.Font.GothamMedium,
    FONT_BOLD = Enum.Font.GothamBold,
    FONT_LIGHT = Enum.Font.Gotham,
    FONT_MONO = Enum.Font.Code,
    TITLE_SIZE = 18,
    HEADER_SIZE = 14,
    LABEL_SIZE = 12,
    BUTTON_SIZE = 13,
    
    -- Bordes y efectos
    CORNER_RADIUS = UDim.new(0, 10),
    STROKE_THICKNESS = 1.5,
    
    -- Efectos especiales
    GLOW_COLOR = Color3.fromRGB(0, 150, 255),
    GLOW_COLOR2 = Color3.fromRGB(138, 43, 226),
    SHADOW_INTENSITY = 0.4,
    
    -- Animaciones
    TWEEN_SPEED = 0.25,
    TWEEN_STYLE = Enum.EasingStyle.Quint
}

-- ===================================
-- LÓGICA PRINCIPAL
-- ===================================
local KillAuraMine = {}
KillAuraMine.__index = KillAuraMine

-- ============================================================
-- 🔰 FUNCIÓN AUXILIAR: OBTENER CARPETA DESDE RUTA
-- ============================================================
local function getFolderFromPath(startFolder, pathString)
    local current = startFolder
    local pathParts = string.split(pathString, ".")
    
    for _, part in ipairs(pathParts) do
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end
    return current
end

function KillAuraMine.new()
    local self = setmetatable({}, KillAuraMine)
    self.player = Players.LocalPlayer
    self.minimized = false
    self.isAuraActive = false
    self.isFlying = false
    self.isSpeedActive = false
    
    self.isBoosting = false
    self.noClipEnabled = false
    self.noClipConnection = nil
    self.noClipButton = nil
    self.currentSpeed = 0
    self.targetSpeed = CONFIG.BASE_SPEED
    self.bodyVelocity = nil
    self.bodyGyro = nil
    self.flyStatusFrame = nil
    
    self.isFarmingSecrets = false
    self.farmSecretsButton = nil
    self.farmSecretsCoroutine = nil
    
    self.isFarmingOres = false
    self.selectedOreType = nil
    self.oreSelectionFrame = nil
    self.oreListFrame = nil
    self.oreButtons = {}
    self.startFarmOresButton = nil
    self.stopFarmOresButton = nil
    
    self.isAutoCollecting = false
    self.autoCollectButton = nil
    self.autoCollectConnection = nil

    -- ===================================
    -- NUEVAS VARIABLES PARA AUTO KILL PLAYER
    -- ===================================
    self.isAutoKillPlayer = false
    self.selectedPlayer = nil
    self.playerListFrame = nil
    self.playerButtons = {}
    self.startAutoKillButton = nil
    self.stopAutoKillButton = nil
    self.autoKillConnection = nil
    self.selectedPlayerLabel = nil

    -- ===================================
    -- NUEVAS VARIABLES PARA TELEPORT
    -- ===================================
    self.teleportAreas = {}
    self.teleportButtons = {}
    self.teleportListFrame = nil
    
    -- ===================================
    -- VARIABLES PARA UTILIDADES
    -- ===================================
    self.isFpsUnlocked = false
    self.serverInfoFrame = nil
    self.serverInfoConnection = nil

    self.lastNoSecretsNotification = 0
    self.lastNoOresNotification = 0
    self.notificationCooldown = 15
    
    self.screenGui = nil
    self.mainFrame = nil
    self.dockIcon = nil
    self.auraButton = nil
    self.rangeSlider = nil
    self.rangeLabel = nil
    self.modeButton = nil
    self.modeLabel = nil
    self.flyButton = nil
    self.speedButton = nil
    self.connections = {}
    self.auraConnection = nil
    self.flyConnection = nil
    self.currentTab = "Modules"
    self:createUI()
    self:startAuraLoop()
    
    -- Conectar eventos para actualizar listas
    self:setupListUpdates()
    return self
end

function KillAuraMine:setupListUpdates()
    -- Actualizar lista de jugadores cuando alguien se una o salga
    table.insert(self.connections, Players.PlayerAdded:Connect(function()
        if self.playerListFrame then
            task.wait(1) -- Esperar a que el jugador se cargue completamente
            self:loadPlayerList()
        end
    end))
    
    table.insert(self.connections, Players.PlayerRemoving:Connect(function()
        if self.playerListFrame then
            self:loadPlayerList()
        end
    end))
    
    -- Actualizar lista de minerales periódicamente
    self.oreUpdateConnection = RunService.Heartbeat:Connect(function()
        if self.oreListFrame and self.oreListFrame.Visible then
            self:updateOreList()
        end
    end)
end

function KillAuraMine:createElement(className, properties)
    local element = Instance.new(className)
    for prop, value in pairs(properties) do element[prop] = value end

    -- Estilo global para que el UI se vea más profesional sin tocar cada botón a mano
    if className == "TextButton" then
        self:enhanceTextButton(element)
    elseif className == "ImageButton" then
        self:enhanceImageButton(element)
    end
    return element
end

local function safeFindFirstChildOfClass(instance, className)
    for _, child in ipairs(instance:GetChildren()) do
        if child.ClassName == className then
            return child
        end
    end
    return nil
end

function KillAuraMine:enhanceTextButton(button)
    -- No tocar tabs transparentes (se ven bien como están)
    if button.BackgroundTransparency and button.BackgroundTransparency >= 1 then
        button.AutoButtonColor = false
        return
    end

    button.AutoButtonColor = false

    -- Corner consistente si no existe
    if not safeFindFirstChildOfClass(button, "UICorner") then
        self:createElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
    end

    -- Stroke suave si no existe
    if not safeFindFirstChildOfClass(button, "UIStroke") then
        self:createElement("UIStroke", {
            Color = UI_CONFIG.TERTIARY,
            Thickness = 1,
            Transparency = 0.55,
            Parent = button
        })
    end

    -- Overlay para hover/click (no modifica BackgroundColor3 -> no rompe toggles)
    if not button:FindFirstChild("HoverOverlay") then
        local overlay = self:createElement("Frame", {
            Name = "HoverOverlay",
            BackgroundColor3 = UI_CONFIG.TEXT,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            Selectable = false,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = (button.ZIndex or 1) + 1,
            Parent = button
        })

        -- Corner del overlay para que coincida con el botón
        self:createElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = overlay })

        local function tweenOverlay(targetTransparency, duration)
            if not overlay or not overlay.Parent then return end
            TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = targetTransparency
            }):Play()
        end

        button.MouseEnter:Connect(function()
            tweenOverlay(0.92, 0.12)
        end)
        button.MouseLeave:Connect(function()
            tweenOverlay(1, 0.14)
        end)
        button.MouseButton1Down:Connect(function()
            tweenOverlay(0.85, 0.05)
        end)
        button.MouseButton1Up:Connect(function()
            -- si sigue hovered, vuelve a 0.92; si no, se irá a 1 en MouseLeave
            tweenOverlay(0.92, 0.08)
        end)
    end
end

function KillAuraMine:enhanceImageButton(button)
    button.AutoButtonColor = false

    if not safeFindFirstChildOfClass(button, "UICorner") and (button.BackgroundTransparency or 0) < 1 then
        self:createElement("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
    end

    if (button.BackgroundTransparency or 0) >= 1 then
        return
    end

    if not button:FindFirstChild("HoverOverlay") then
        local overlay = self:createElement("Frame", {
            Name = "HoverOverlay",
            BackgroundColor3 = UI_CONFIG.TEXT,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            Selectable = false,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = (button.ZIndex or 1) + 1,
            Parent = button
        })
        self:createElement("UICorner", { CornerRadius = UDim.new(0, 8), Parent = overlay })

        local function tweenOverlay(targetTransparency, duration)
            if not overlay or not overlay.Parent then return end
            TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = targetTransparency
            }):Play()
        end

        button.MouseEnter:Connect(function()
            tweenOverlay(0.92, 0.12)
        end)
        button.MouseLeave:Connect(function()
            tweenOverlay(1, 0.14)
        end)
        button.MouseButton1Down:Connect(function()
            tweenOverlay(0.85, 0.05)
        end)
        button.MouseButton1Up:Connect(function()
            tweenOverlay(0.92, 0.08)
        end)
    end
end

function KillAuraMine:createGlowEffect(parent)
    local glow = self:createElement("ImageLabel", {
        Name = "GlowEffect",
        Image = "rbxassetid://8992230673",
        ImageColor3 = UI_CONFIG.GLOW_COLOR,
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100, 100, 400, 400),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.new(0, -25, 0, -25),
        ZIndex = 0
    })
    glow.Parent = parent
    
    -- Animación de pulso sutil
    task.spawn(function()
        while glow and glow.Parent do
            local tween1 = TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.7,
                ImageColor3 = UI_CONFIG.GLOW_COLOR2
            })
            tween1:Play()
            tween1.Completed:Wait()
            
            local tween2 = TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.85,
                ImageColor3 = UI_CONFIG.GLOW_COLOR
            })
            tween2:Play()
            tween2.Completed:Wait()
        end
    end)
    
    return glow
end

function KillAuraMine:applySoftGradient(target, topColor, bottomColor)
    if not target or not target.Parent then return end
    if target:FindFirstChildOfClass("UIGradient") then return end

    self:createElement("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, topColor),
            ColorSequenceKeypoint.new(1, bottomColor)
        }),
        Parent = target
    })
end

function KillAuraMine:createShadow(parent)
    local shadow = self:createElement("ImageLabel", {
        Image = "rbxassetid://8992230673",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = UI_CONFIG.SHADOW_INTENSITY,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100, 100, 400, 400),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        ZIndex = 0
    })
    shadow.Parent = parent
    return shadow
end

function KillAuraMine:showNotification(message, notifType)
    print("[DragonHub] " .. message)
    notifType = notifType or "info"
    
    local notifColors = {
        info = UI_CONFIG.ACCENT,
        success = UI_CONFIG.SUCCESS,
        warning = UI_CONFIG.WARNING,
        error = UI_CONFIG.DANGER
    }
    local notifIcons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌"
    }
    
    local notifGui = self:createElement("ScreenGui", { Name = "DragonHubNotif", Parent = self.player:WaitForChild("PlayerGui") })
    local notifFrame = self:createElement("Frame", { 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 320, 0, 70), 
        Position = UDim2.new(0, -330, 1, -80), 
        Parent = notifGui 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = notifFrame})
    self:createElement("UIStroke", {Color = notifColors[notifType], Thickness = 1.5, Parent = notifFrame})
    self:createShadow(notifFrame)
    
    -- Barra de progreso
    local progressBar = self:createElement("Frame", {
        BackgroundColor3 = notifColors[notifType],
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BorderSizePixel = 0,
        Parent = notifFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressBar})
    
    -- Icono
    local icon = self:createElement("TextLabel", {
        Text = notifIcons[notifType],
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 24,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0.5, -20),
        Parent = notifFrame
    })
    
    -- Título
    local title = self:createElement("TextLabel", { 
        Text = "DRAK HUB", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = 13, 
        TextColor3 = notifColors[notifType], 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -65, 0, 20), 
        Position = UDim2.new(0, 55, 0, 10), 
        Parent = notifFrame 
    })
    
    -- Mensaje
    local label = self:createElement("TextLabel", { 
        Text = message, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -65, 0, 30), 
        Position = UDim2.new(0, 55, 0, 28), 
        Parent = notifFrame 
    })
    
    -- Animación de entrada (desde la izquierda)
    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 1, -80)
    })
    tweenIn:Play()
    
    -- Animación de la barra de progreso
    local progressTween = TweenService:Create(progressBar, TweenInfo.new(CONFIG.NotificationDuration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    })
    progressTween:Play()
    
    task.wait(CONFIG.NotificationDuration)
    
    -- Animación de salida (hacia la izquierda)
    local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0, -330, 1, -80)
    })
    tweenOut:Play()
    tweenOut.Completed:Connect(function() notifGui:Destroy() end)
end

function KillAuraMine:createUI()
    self.screenGui = self:createElement("ScreenGui", { 
        Name = "KillAuraMineGUI", 
        ResetOnSpawn = false, 
        Parent = self.player:WaitForChild("PlayerGui") 
    })
    
    self.mainFrame = self:createElement("Frame", { 
        Name = "MainFrame", 
        BackgroundColor3 = UI_CONFIG.PRIMARY,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 500, 0, 600), 
        Position = UDim2.new(0.5, -250, 0.5, -300), 
        Parent = self.screenGui 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.mainFrame})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT, 
        Thickness = UI_CONFIG.STROKE_THICKNESS,
        Transparency = 0.7,
        Parent = self.mainFrame
    })
    self:createShadow(self.mainFrame)
    self:applySoftGradient(self.mainFrame, UI_CONFIG.PRIMARY, UI_CONFIG.SECONDARY)
    self:createGlowEffect(self.mainFrame)
    self:makeDraggable(self.mainFrame)
    
    local header = self:createElement("Frame", { 
        Name = "Header", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 50), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = self.mainFrame 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = header})
    
    -- Gradiente animado en el header
    local headerGradient = self:createElement("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UI_CONFIG.SECONDARY),
            ColorSequenceKeypoint.new(1, UI_CONFIG.PRIMARY)
        }),
        Parent = header
    })
    
    -- Línea de acento inferior
    local accentLine = self:createElement("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = UI_CONFIG.ACCENT,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
        Parent = header
    })
    
    -- Gradiente en la línea de acento
    local lineGradient = self:createElement("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UI_CONFIG.ACCENT),
            ColorSequenceKeypoint.new(0.5, UI_CONFIG.ACCENT2),
            ColorSequenceKeypoint.new(1, UI_CONFIG.ACCENT3)
        }),
        Parent = accentLine
    })
    
    -- Animación del gradiente de la línea
    task.spawn(function()
        local offset = 0
        while accentLine and accentLine.Parent do
            offset = (offset + 0.005) % 1
            lineGradient.Offset = Vector2.new(offset, 0)
            task.wait(0.03)
        end
    end)
    
    local titleContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Parent = header
    })
    
    -- Icono/Logo
    local logoIcon = self:createElement("TextLabel", {
        Text = "🐲",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 24,
        TextColor3 = UI_CONFIG.ACCENT,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = titleContainer
    })
    
    local mainTitle = self:createElement("TextLabel", { 
        Text = "DRAK HUB", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.TITLE_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -35, 0.55, 0), 
        Position = UDim2.new(0, 35, 0, 5), 
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleContainer 
    })
    
    local subTitle = self:createElement("TextLabel", { 
        Text = "THE LOST LAND • PREMIUM EDITION", 
        Font = UI_CONFIG.FONT_LIGHT, 
        TextSize = UI_CONFIG.LABEL_SIZE - 1, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -35, 0.4, 0), 
        Position = UDim2.new(0, 35, 0.55, 0), 
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleContainer 
    })
    
    -- Efecto de brillo en el título
    local titleStroke = self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT,
        Thickness = 0,
        Transparency = 0.5,
        Parent = mainTitle
    })
    
    local controlContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -85, 0, 0),
        Parent = header
    })
    
    local minimizeButton = self:createElement("TextButton", { 
        Text = "━", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = 14, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(0, 30, 0, 30), 
        Position = UDim2.new(0, 5, 0.5, -15), 
        Parent = controlContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = minimizeButton})
    self:createElement("UIStroke", {Color = UI_CONFIG.QUATERNARY, Thickness = 1, Parent = minimizeButton})
    
    -- Hover effect para minimize
    minimizeButton.MouseEnter:Connect(function()
        TweenService:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = UI_CONFIG.QUATERNARY}):Play()
    end)
    minimizeButton.MouseLeave:Connect(function()
        TweenService:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = UI_CONFIG.TERTIARY}):Play()
    end)
    table.insert(self.connections, minimizeButton.MouseButton1Click:Connect(function() self:toggleMinimize() end))
    
    local closeButton = self:createElement("TextButton", { 
        Text = "✕", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = 14, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.DANGER, 
        Size = UDim2.new(0, 30, 0, 30), 
        Position = UDim2.new(0, 40, 0.5, -15), 
        Parent = controlContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = closeButton})
    
    -- Hover effect para close
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = UI_CONFIG.DANGER}):Play()
    end)
    table.insert(self.connections, closeButton.MouseButton1Click:Connect(function() self:destroy() end))
    
    local tabsContainer = self:createElement("Frame", { 
        Name = "TabsContainer", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 55), 
        Parent = self.mainFrame 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabsContainer})
    self:createElement("UIStroke", {Color = UI_CONFIG.TERTIARY, Thickness = 1, Transparency = 0.5, Parent = tabsContainer})
    
    -- Indicador de tab activo con gradiente
    local tabHighlight = self:createElement("Frame", {
        Name = "TabHighlight",
        BackgroundColor3 = UI_CONFIG.ACCENT,
        Size = UDim2.new(0.33, -6, 0, 3),
        Position = UDim2.new(0, 3, 1, -4),
        Parent = tabsContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 2), Parent = tabHighlight})
    local highlightGradient = self:createElement("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UI_CONFIG.ACCENT),
            ColorSequenceKeypoint.new(1, UI_CONFIG.ACCENT2)
        }),
        Parent = tabHighlight
    })
    
    local modulesTab = self:createElement("TextButton", { 
        Name = "ModulesTab", 
        Text = "⚡ MÓDULOS", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(0.33, -2, 1, -5), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = tabsContainer 
    })
    table.insert(self.connections, modulesTab.MouseButton1Click:Connect(function() 
        self:switchTab("Modules") 
        TweenService:Create(tabHighlight, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 3, 1, -4)
        }):Play()
        self:refreshAllLists()
    end))
    
    local playerTab = self:createElement("TextButton", { 
        Name = "PlayerTab", 
        Text = "👤 JUGADOR", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(0.33, -2, 1, -5), 
        Position = UDim2.new(0.33, 2, 0, 0), 
        Parent = tabsContainer 
    })
    table.insert(self.connections, playerTab.MouseButton1Click:Connect(function() 
        self:switchTab("Player") 
        TweenService:Create(tabHighlight, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.33, 3, 1, -4)
        }):Play()
    end))
    
    local teleportTab = self:createElement("TextButton", { 
        Name = "TeleportTab", 
        Text = "📍 TELEPORT", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(0.33, -2, 1, -5), 
        Position = UDim2.new(0.66, 2, 0, 0), 
        Parent = tabsContainer 
    })
    table.insert(self.connections, teleportTab.MouseButton1Click:Connect(function() 
        self:switchTab("Teleport") 
        TweenService:Create(tabHighlight, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.66, 3, 1, -4)
        }):Play()
    end))
    
    local contentContainer = self:createElement("Frame", { 
        Name = "ContentContainer", 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -100), 
        Position = UDim2.new(0, 0, 0, 100), 
        Parent = self.mainFrame 
    })
    
    local modulesContent = self:createElement("ScrollingFrame", { 
        Name = "ModulesContent", 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Visible = true,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI_CONFIG.ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 800),
        Parent = contentContainer 
    })

    -- Padding sutil para que no quede “pegado” a los bordes
    self:createElement("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = modulesContent
    })
    
    local auraPanel = self:createElement("Frame", { 
        Name = "AuraPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0.48, -5, 0, 220), 
        Position = UDim2.new(0, 10, 0, 10), 
        Parent = modulesContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = auraPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT,
        Thickness = 1,
        Transparency = 0.5,
        Parent = auraPanel
    })
    self:applySoftGradient(auraPanel, UI_CONFIG.SECONDARY, UI_CONFIG.TERTIARY)
    
    local auraTitle = self:createElement("TextLabel", { 
        Text = "⚔️ KILL AURA", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = UI_CONFIG.ACCENT, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = auraPanel 
    })
    
    self.modeButton = self:createElement("TextButton", { 
        Text = "🎯 MODO: JUGADORES", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 32), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = auraPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.modeButton})
    table.insert(self.connections, self.modeButton.MouseButton1Click:Connect(function() self:toggleMode() end))
    
    self.rangeLabel = self:createElement("TextLabel", { 
        Text = "📏 Rango: " .. CONFIG.Range, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 20), 
        Position = UDim2.new(0, 10, 0, 75), 
        Parent = auraPanel 
    })
    
    local sliderContainer = self:createElement("Frame", {
        Name = "RangeSliderContainer",
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 100),
        Parent = auraPanel
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderContainer})
    
    local sliderFill = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.ACCENT,
        Size = UDim2.new((CONFIG.Range - 10) / 1490, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = sliderContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderFill})
    
    local sliderButton = self:createElement("TextButton", {
        Name = "RangeSliderButton",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((CONFIG.Range - 10) / 1490, -8, 0.5, -8),
        BackgroundColor3 = UI_CONFIG.TEXT,
        Text = "",
        Parent = sliderContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = sliderButton})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT,
        Thickness = 2,
        Parent = sliderButton
    })
    
    self.auraButton = self:createElement("TextButton", { 
        Text = "🔴 ACTIVAR AURA", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 36), 
        Position = UDim2.new(0, 10, 0, 125), 
        Parent = auraPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.auraButton})
    table.insert(self.connections, self.auraButton.MouseButton1Click:Connect(function() self:toggleAura() end))
    
    -- ===================================
    -- PANEL DE SECRETS CORREGIDO (MÁS ALTO Y CON AUTO RECOLECTAR)
    -- ===================================

    local secretsPanel = self:createElement("Frame", {
        Name = "SecretsPanel",
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0.48, -10, 0, 220),
        Position = UDim2.new(0.52, 0, 0, 10),
        Parent = modulesContent
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = secretsPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT2,
        Thickness = 1,
        Transparency = 0.5,
        Parent = secretsPanel
    })
    self:applySoftGradient(secretsPanel, UI_CONFIG.SECONDARY, UI_CONFIG.TERTIARY)
    self:createShadow(secretsPanel)
    self:createGlowEffect(secretsPanel)

    local secretsTitle = self:createElement("TextLabel", {
        Text = "💎 FARM SECRETS",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = UI_CONFIG.HEADER_SIZE,
        TextColor3 = UI_CONFIG.ACCENT2,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 8),
        Parent = secretsPanel
    })

    self.farmSecretsButton = self:createElement("TextButton", {
        Text = "🔴 INICIAR FARM SECRETS",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = UI_CONFIG.BUTTON_SIZE,
        TextColor3 = UI_CONFIG.TEXT,
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, -20, 0, 36),
        Position = UDim2.new(0, 10, 0, 35),
        Parent = secretsPanel
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.farmSecretsButton})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT2,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.farmSecretsButton
    })
    self:createGlowEffect(self.farmSecretsButton)
    table.insert(self.connections, self.farmSecretsButton.MouseButton1Click:Connect(function() self:toggleFarmSecrets() end))

    -- ===================================
    -- BOTÓN AUTO RECOLECTAR DENTRO DEL PANEL SECRETS
    -- ===================================
    self.autoCollectButton = self:createElement("TextButton", {
        Text = "🔴 AUTO RECOLECTAR",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = UI_CONFIG.BUTTON_SIZE,
        TextColor3 = UI_CONFIG.TEXT,
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, -20, 0, 36),
        Position = UDim2.new(0, 10, 0, 85),
        Parent = secretsPanel
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.autoCollectButton})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT2,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.autoCollectButton
    })
    self:createGlowEffect(self.autoCollectButton)
    table.insert(self.connections, self.autoCollectButton.MouseButton1Click:Connect(function() self:toggleAutoCollect() end))
    
    -- ===================================
    -- DESCRIPCIÓN MEJORADA PARA SECRETS
    -- ===================================
    local secretsDescription = self:createElement("TextLabel", { 
        Text = "Farm automático de secretos y recolección de ítems", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE - 1, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 135), 
        TextWrapped = true,
        Parent = secretsPanel 
    })
    
    local secretsInfo = self:createElement("TextLabel", { 
        Text = "💡 El farm de secrets teletransporta automáticamente a los secretos y los mina", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE - 1, 
        TextColor3 = UI_CONFIG.ACCENT2, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 50), 
        Position = UDim2.new(0, 10, 0, 175), 
        TextWrapped = true,
        Parent = secretsPanel 
    })
    
    local autoCollectInfo = self:createElement("TextLabel", { 
        Text = "📦 Auto Recolectar recoge todos los ítems cercanos automáticamente", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE - 1, 
        TextColor3 = UI_CONFIG.ACCENT, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 230), 
        TextWrapped = true,
        Parent = secretsPanel 
    })
    
    local oresPanel = self:createElement("Frame", { 
        Name = "OresPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 180), 
        Position = UDim2.new(0, 10, 0, 300),  -- Ajustada posición por el panel de secrets más grande
        Parent = modulesContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = oresPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.WARNING,
        Thickness = 1,
        Transparency = 0.5,
        Parent = oresPanel
    })
    
    local oresTitle = self:createElement("TextLabel", { 
        Text = "⛏️ FARM MINERALES", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = UI_CONFIG.WARNING, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = oresPanel 
    })
    
    self.selectedOreLabel = self:createElement("TextLabel", { 
        Text = "📦 Mineral seleccionado: Ninguno", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 20), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = oresPanel 
    })
    
    self.oreListFrame = self:createElement("ScrollingFrame", { 
        Name = "OreListFrame", 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 60), 
        Position = UDim2.new(0, 10, 0, 60), 
        Visible = true,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI_CONFIG.WARNING,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = oresPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.oreListFrame})
    
    -- Añadir UIListLayout para organizar los botones automáticamente
    local oreListLayout = self:createElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = self.oreListFrame
    })
    
    local orePadding = self:createElement("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = self.oreListFrame
    })
    
    oreListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.oreListFrame.CanvasSize = UDim2.new(0, 0, 0, oreListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local buttonsContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 130),
        Parent = oresPanel
    })
    
    self.startFarmOresButton = self:createElement("TextButton", { 
        Text = "🟢 INICIAR FARMEO", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.SUCCESS, 
        Size = UDim2.new(0.48, -5, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = buttonsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.startFarmOresButton})
    table.insert(self.connections, self.startFarmOresButton.MouseButton1Click:Connect(function() 
        if self.selectedOreType then
            self:toggleFarmOres()
        else
            self:showNotification("❌ Por favor, selecciona un mineral primero")
        end
    end))
    
    self.stopFarmOresButton = self:createElement("TextButton", { 
        Text = "🔴 DETENER FARMEO", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.DANGER, 
        Size = UDim2.new(0.48, -5, 1, 0), 
        Position = UDim2.new(0.52, 5, 0, 0), 
        Visible = false, 
        Parent = buttonsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.stopFarmOresButton})
    table.insert(self.connections, self.stopFarmOresButton.MouseButton1Click:Connect(function() 
        self:toggleFarmOres()
    end))
    
    -- ===================================
    -- PANEL DE AUTO KILL PLAYER
    -- ===================================
    local autoKillPanel = self:createElement("Frame", { 
        Name = "AutoKillPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 180), 
        Position = UDim2.new(0, 10, 0, 490),  -- Ajustada posición
        Parent = modulesContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = autoKillPanel})
    self:createElement("UIStroke", {
        Color = Color3.fromRGB(180, 80, 220),
        Thickness = 1,
        Transparency = 0.5,
        Parent = autoKillPanel
    })
    
    local autoKillTitle = self:createElement("TextLabel", { 
        Text = "🔫 AUTO KILL PLAYER", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = Color3.fromRGB(180, 80, 220), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = autoKillPanel 
    })
    
    self.selectedPlayerLabel = self:createElement("TextLabel", { 
        Text = "🎯 Jugador seleccionado: Ninguno", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 20), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = autoKillPanel 
    })
    
    self.playerListFrame = self:createElement("ScrollingFrame", { 
        Name = "PlayerListFrame", 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 60), 
        Position = UDim2.new(0, 10, 0, 60), 
        Visible = true,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(180, 80, 220),
        Parent = autoKillPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.playerListFrame})
    
    local autoKillButtonsContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 130),
        Parent = autoKillPanel
    })
    
    self.startAutoKillButton = self:createElement("TextButton", { 
        Text = "🟢 INICIAR AUTO KILL", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.SUCCESS, 
        Size = UDim2.new(0.48, -5, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = autoKillButtonsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.startAutoKillButton})
    table.insert(self.connections, self.startAutoKillButton.MouseButton1Click:Connect(function() 
        if self.selectedPlayer then
            self:toggleAutoKillPlayer()
        else
            self:showNotification("❌ Por favor, selecciona un jugador primero")
        end
    end))
    
    self.stopAutoKillButton = self:createElement("TextButton", { 
        Text = "🔴 DETENER AUTO KILL", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.DANGER, 
        Size = UDim2.new(0.48, -5, 1, 0), 
        Position = UDim2.new(0.52, 5, 0, 0), 
        Visible = false, 
        Parent = autoKillButtonsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.stopAutoKillButton})
    table.insert(self.connections, self.stopAutoKillButton.MouseButton1Click:Connect(function() 
        self:toggleAutoKillPlayer()
    end))
    
    -- ===================================
    -- CONTENIDO DE JUGADOR
    -- ===================================
    local playerContent = self:createElement("ScrollingFrame", { 
        Name = "PlayerContent", 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Visible = false,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI_CONFIG.ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 620),
        Parent = contentContainer 
    })
    
    local flyPanel = self:createElement("Frame", { 
        Name = "FlyPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 280), 
        Position = UDim2.new(0, 10, 0, 10), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = flyPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT,
        Thickness = 1,
        Transparency = 0.5,
        Parent = flyPanel
    })
    
    local flyTitle = self:createElement("TextLabel", { 
        Text = "🚀 CONFIGURACIÓN DE VUELO", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = UI_CONFIG.ACCENT, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = flyPanel 
    })
    
    self.flyButton = self:createElement("TextButton", { 
        Text = "🔴 ACTIVAR FLY", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 36), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = flyPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.flyButton})
    table.insert(self.connections, self.flyButton.MouseButton1Click:Connect(function() self:toggleFly() end))
    
    -- Slider de Velocidad Base del Fly
    local flyBaseSpeedContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 45),
        Position = UDim2.new(0, 10, 0, 80),
        Parent = flyPanel
    })
    
    self.flyBaseSpeedLabel = self:createElement("TextLabel", { 
        Text = "🚀 Velocidad Base: " .. CONFIG.BASE_SPEED, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 18), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = flyBaseSpeedContainer 
    })
    
    local flyBaseSliderBg = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 22),
        Parent = flyBaseSpeedContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyBaseSliderBg})
    
    local flyBaseSliderFill = self:createElement("Frame", {
        Name = "Fill",
        BackgroundColor3 = UI_CONFIG.ACCENT,
        Size = UDim2.new((CONFIG.BASE_SPEED - 10) / 190, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = flyBaseSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyBaseSliderFill})
    
    local flyBaseSliderKnob = self:createElement("Frame", {
        Name = "Knob",
        BackgroundColor3 = UI_CONFIG.TEXT,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((CONFIG.BASE_SPEED - 10) / 190, -7, 0.5, -7),
        Parent = flyBaseSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flyBaseSliderKnob})
    
    self:makeSliderDraggable(flyBaseSliderBg, flyBaseSliderFill, flyBaseSliderKnob, 10, 200, CONFIG.BASE_SPEED, function(value)
        CONFIG.BASE_SPEED = value
        self.flyBaseSpeedLabel.Text = "🚀 Velocidad Base: " .. value
        if not self.isBoosting then
            self.targetSpeed = value
        end
    end)
    
    -- Slider de Velocidad Boost del Fly
    local flyBoostSpeedContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 45),
        Position = UDim2.new(0, 10, 0, 130),
        Parent = flyPanel
    })
    
    self.flyBoostSpeedLabel = self:createElement("TextLabel", { 
        Text = "⚡ Velocidad Boost (Ctrl): " .. CONFIG.BOOST_SPEED, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 18), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = flyBoostSpeedContainer 
    })
    
    local flyBoostSliderBg = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 22),
        Parent = flyBoostSpeedContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyBoostSliderBg})
    
    local flyBoostSliderFill = self:createElement("Frame", {
        Name = "Fill",
        BackgroundColor3 = UI_CONFIG.WARNING,
        Size = UDim2.new((CONFIG.BOOST_SPEED - 20) / 280, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = flyBoostSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyBoostSliderFill})
    
    local flyBoostSliderKnob = self:createElement("Frame", {
        Name = "Knob",
        BackgroundColor3 = UI_CONFIG.TEXT,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((CONFIG.BOOST_SPEED - 20) / 280, -7, 0.5, -7),
        Parent = flyBoostSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flyBoostSliderKnob})
    
    self:makeSliderDraggable(flyBoostSliderBg, flyBoostSliderFill, flyBoostSliderKnob, 20, 300, CONFIG.BOOST_SPEED, function(value)
        CONFIG.BOOST_SPEED = value
        self.flyBoostSpeedLabel.Text = "⚡ Velocidad Boost (Ctrl): " .. value
        if self.isBoosting then
            self.targetSpeed = value
        end
    end)
    
    -- Slider de Velocidad Vertical del Fly
    local flyVerticalSpeedContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 45),
        Position = UDim2.new(0, 10, 0, 180),
        Parent = flyPanel
    })
    
    self.flyVerticalSpeedLabel = self:createElement("TextLabel", { 
        Text = "↕️ Velocidad Vertical: " .. CONFIG.VERTICAL_SPEED, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 18), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = flyVerticalSpeedContainer 
    })
    
    local flyVerticalSliderBg = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 22),
        Parent = flyVerticalSpeedContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyVerticalSliderBg})
    
    local flyVerticalSliderFill = self:createElement("Frame", {
        Name = "Fill",
        BackgroundColor3 = UI_CONFIG.ACCENT2,
        Size = UDim2.new((CONFIG.VERTICAL_SPEED - 5) / 95, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = flyVerticalSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = flyVerticalSliderFill})
    
    local flyVerticalSliderKnob = self:createElement("Frame", {
        Name = "Knob",
        BackgroundColor3 = UI_CONFIG.TEXT,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((CONFIG.VERTICAL_SPEED - 5) / 95, -7, 0.5, -7),
        Parent = flyVerticalSliderBg
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flyVerticalSliderKnob})
    
    self:makeSliderDraggable(flyVerticalSliderBg, flyVerticalSliderFill, flyVerticalSliderKnob, 5, 100, CONFIG.VERTICAL_SPEED, function(value)
        CONFIG.VERTICAL_SPEED = value
        self.flyVerticalSpeedLabel.Text = "↕️ Velocidad Vertical: " .. value
    end)
    
    -- Info de controles
    local flyControlsInfo = self:createElement("TextLabel", { 
        Text = "💡 Controles: WASD=Mover | Space=Subir | Shift=Bajar | Ctrl=Boost | N=NoClip", 
        Font = UI_CONFIG.FONT, 
        TextSize = 10, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 25), 
        Position = UDim2.new(0, 10, 0, 230), 
        TextWrapped = true,
        Parent = flyPanel 
    })
    
    local speedConfigPanel = self:createElement("Frame", { 
        Name = "SpeedConfigPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 200), 
        Position = UDim2.new(0, 10, 0, 300), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = speedConfigPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT2,
        Thickness = 1,
        Transparency = 0.5,
        Parent = speedConfigPanel
    })
    
    local speedTitle = self:createElement("TextLabel", { 
        Text = "⚡ CONFIGURACIÓN DE VELOCIDAD", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = UI_CONFIG.ACCENT2, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = speedConfigPanel 
    })
    
    self.speedButton = self:createElement("TextButton", { 
        Text = "🔴 ACTIVAR SPEED", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(0.48, -5, 0, 36), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = speedConfigPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.speedButton})
    table.insert(self.connections, self.speedButton.MouseButton1Click:Connect(function() self:toggleSpeed() end))
    
    self.noClipButton = self:createElement("TextButton", { 
        Text = "🔴 NOCLIP", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(0.48, -5, 0, 36), 
        Position = UDim2.new(0.52, 0, 0, 35), 
        Parent = speedConfigPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.noClipButton})
    table.insert(self.connections, self.noClipButton.MouseButton1Click:Connect(function() self:toggleNoClip() end))
    
    local walkSpeedContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 80),
        Parent = speedConfigPanel
    })
    
    self.walkSpeedLabel = self:createElement("TextLabel", { 
        Text = "👟 Velocidad: " .. CONFIG.WalkSpeed, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 20), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = walkSpeedContainer 
    })
    
    local walkSlider = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 25),
        Parent = walkSpeedContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = walkSlider})
    
    local walkSliderFill = self:createElement("Frame", {
        Name = "Fill",
        BackgroundColor3 = UI_CONFIG.WARNING,
        Size = UDim2.new((CONFIG.WalkSpeed - 16) / 184, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = walkSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = walkSliderFill})
    
    local walkSliderKnob = self:createElement("Frame", {
        Name = "Knob",
        BackgroundColor3 = UI_CONFIG.TEXT,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((CONFIG.WalkSpeed - 16) / 184, -7, 0.5, -7),
        Parent = walkSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = walkSliderKnob})
    
    self:makeSliderDraggable(walkSlider, walkSliderFill, walkSliderKnob, 16, 200, CONFIG.WalkSpeed, function(value)
        CONFIG.WalkSpeed = value
        self.walkSpeedLabel.Text = "👟 Velocidad: " .. value
        if self.isSpeedActive then
            local character = self.player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = value
            end
        end
    end)
    
    local jumpPowerContainer = self:createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 140),
        Parent = speedConfigPanel
    })
    
    self.jumpPowerLabel = self:createElement("TextLabel", { 
        Text = "🦘 Salto: " .. CONFIG.JumpPower, 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 20), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = jumpPowerContainer 
    })
    
    local jumpSlider = self:createElement("Frame", {
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 25),
        Parent = jumpPowerContainer
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = jumpSlider})
    
    local jumpSliderFill = self:createElement("Frame", {
        Name = "Fill",
        BackgroundColor3 = UI_CONFIG.SUCCESS,
        Size = UDim2.new((CONFIG.JumpPower - 50) / 200, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = jumpSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = jumpSliderFill})
    
    local jumpSliderKnob = self:createElement("Frame", {
        Name = "Knob",
        BackgroundColor3 = UI_CONFIG.TEXT,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((CONFIG.JumpPower - 50) / 200, -7, 0.5, -7),
        Parent = jumpSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = jumpSliderKnob})
    
    self:makeSliderDraggable(jumpSlider, jumpSliderFill, jumpSliderKnob, 50, 250, CONFIG.JumpPower, function(value)
        CONFIG.JumpPower = value
        self.jumpPowerLabel.Text = "🦘 Salto: " .. value
        if self.isSpeedActive then
            local character = self.player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.JumpPower = value
            end
        end
    end)
    
    -- ===================================
    -- PANEL DE UTILIDADES (FPS, SERVER INFO, DUPE CHECK)
    -- ===================================
    local utilitiesPanel = self:createElement("Frame", { 
        Name = "UtilitiesPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 280), 
        Position = UDim2.new(0, 10, 0, 510), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = utilitiesPanel})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.INFO,
        Thickness = 1,
        Transparency = 0.5,
        Parent = utilitiesPanel
    })
    
    local utilitiesTitle = self:createElement("TextLabel", { 
        Text = "🔧 UTILIDADES", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = UI_CONFIG.INFO, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = utilitiesPanel 
    })
    
    -- FPS Unlocker Button
    self.fpsUnlockerButton = self:createElement("TextButton", { 
        Text = "🔓 FPS UNLOCKER (OFF)", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 36), 
        Position = UDim2.new(0, 10, 0, 38), 
        Parent = utilitiesPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.fpsUnlockerButton})
    table.insert(self.connections, self.fpsUnlockerButton.MouseButton1Click:Connect(function() self:toggleFpsUnlocker() end))
    
    -- Server Info Button
    local serverInfoButton = self:createElement("TextButton", { 
        Text = "📊 VER SERVER INFO", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 36), 
        Position = UDim2.new(0, 10, 0, 80), 
        Parent = utilitiesPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = serverInfoButton})
    table.insert(self.connections, serverInfoButton.MouseButton1Click:Connect(function() self:showServerInfo() end))
    
    -- Dupe Check Button
    local dupeCheckButton = self:createElement("TextButton", { 
        Text = "🔍 DUPE CHECK (Analizar Items)", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.BUTTON_SIZE, 
        TextColor3 = UI_CONFIG.TEXT, 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 36), 
        Position = UDim2.new(0, 10, 0, 122), 
        Parent = utilitiesPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = dupeCheckButton})
    table.insert(self.connections, dupeCheckButton.MouseButton1Click:Connect(function() self:runDupeCheck() end))
    
    -- Info labels
    local fpsInfo = self:createElement("TextLabel", { 
        Text = "💡 Desbloquea el límite de 60 FPS del juego", 
        Font = UI_CONFIG.FONT, 
        TextSize = 10, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 18), 
        Position = UDim2.new(0, 10, 0, 165), 
        Parent = utilitiesPanel 
    })
    
    local serverInfo = self:createElement("TextLabel", { 
        Text = "💡 Muestra ping, jugadores, JobId del servidor", 
        Font = UI_CONFIG.FONT, 
        TextSize = 10, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 18), 
        Position = UDim2.new(0, 10, 0, 185), 
        Parent = utilitiesPanel 
    })
    
    local dupeInfo = self:createElement("TextLabel", { 
        Text = "💡 Analiza items del inventario para detectar posibles dupes", 
        Font = UI_CONFIG.FONT, 
        TextSize = 10, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 18), 
        Position = UDim2.new(0, 10, 0, 205), 
        Parent = utilitiesPanel 
    })
    
    -- FPS Display en tiempo real
    self.fpsLabel = self:createElement("TextLabel", { 
        Text = "FPS: --", 
        Font = UI_CONFIG.FONT_MONO, 
        TextSize = 14, 
        TextColor3 = UI_CONFIG.SUCCESS, 
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(0.5, -15, 0, 30), 
        Position = UDim2.new(0, 10, 0, 235), 
        Parent = utilitiesPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.fpsLabel})
    
    -- Ping Display en tiempo real
    self.pingLabel = self:createElement("TextLabel", { 
        Text = "PING: --ms", 
        Font = UI_CONFIG.FONT_MONO, 
        TextSize = 14, 
        TextColor3 = UI_CONFIG.WARNING, 
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(0.5, -15, 0, 30), 
        Position = UDim2.new(0.5, 5, 0, 235), 
        Parent = utilitiesPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.pingLabel})
    
    -- Iniciar actualización de FPS/Ping
    self:startStatsMonitor()
    
    -- Actualizar CanvasSize del playerContent
    playerContent.CanvasSize = UDim2.new(0, 0, 0, 920)
    
    -- ===================================
    -- CONTENIDO DE TELEPORT
    -- ===================================
    local teleportContent = self:createElement("ScrollingFrame", { 
        Name = "TeleportContent", 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Visible = false,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(255, 105, 180),
        CanvasSize = UDim2.new(0, 0, 0, 400),
        Parent = contentContainer 
    })
    
    local teleportPanel = self:createElement("Frame", { 
        Name = "TeleportPanel", 
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -20, 0, 350), 
        Position = UDim2.new(0, 10, 0, 10), 
        Parent = teleportContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = teleportPanel})
    self:createElement("UIStroke", {
        Color = Color3.fromRGB(255, 105, 180),
        Thickness = 1,
        Transparency = 0.5,
        Parent = teleportPanel
    })
    
    local teleportTitle = self:createElement("TextLabel", { 
        Text = "📍 TELEPORT A ÁREAS", 
        Font = UI_CONFIG.FONT_BOLD, 
        TextSize = UI_CONFIG.HEADER_SIZE, 
        TextColor3 = Color3.fromRGB(255, 105, 180), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 8), 
        Parent = teleportPanel 
    })
    
    local teleportDescription = self:createElement("TextLabel", { 
        Text = "Selecciona un área para teletransportarte", 
        Font = UI_CONFIG.FONT, 
        TextSize = UI_CONFIG.LABEL_SIZE, 
        TextColor3 = UI_CONFIG.TEXT_MUTED, 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 20), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = teleportPanel 
    })
    
    self.teleportListFrame = self:createElement("ScrollingFrame", { 
        Name = "TeleportListFrame", 
        BackgroundColor3 = UI_CONFIG.TERTIARY, 
        Size = UDim2.new(1, -20, 0, 250), 
        Position = UDim2.new(0, 10, 0, 60), 
        Visible = true,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(255, 105, 180),
        Parent = teleportPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.teleportListFrame})
    
    -- Dock Icon mejorado con diseño premium
    self.dockIcon = self:createElement("Frame", { 
        Name = "DockIcon", 
        Size = UDim2.new(0, 55, 0, 55), 
        Position = UDim2.new(0.5, -27, 0.5, -27), 
        BackgroundColor3 = UI_CONFIG.PRIMARY, 
        Visible = false, 
        Parent = self.screenGui 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.dockIcon})
    self:createElement("UIStroke", {
        Color = UI_CONFIG.ACCENT, 
        Thickness = 2,
        Parent = self.dockIcon
    })
    self:createGlowEffect(self.dockIcon)
    
    -- Gradiente en el borde
    local dockGradient = self:createElement("UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UI_CONFIG.ACCENT),
            ColorSequenceKeypoint.new(1, UI_CONFIG.ACCENT2)
        }),
        Parent = self.dockIcon:FindFirstChildOfClass("UIStroke")
    })
    
    -- Icono del dragón
    local dockLabel = self:createElement("TextLabel", {
        Text = "🐲",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 28,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.dockIcon
    })
    
    -- Botón invisible para clicks y drag
    local dockButton = self:createElement("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.dockIcon
    })
    
    -- Hacer el dock icon arrastratable desde el botón
    local dockDragging = false
    local dockDragStart, dockStartPos
    local dockHasMoved = false
    local DOCK_DRAG_THRESHOLD = 5
    
    dockButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dockDragging = true
            dockHasMoved = false
            dockDragStart = input.Position
            dockStartPos = self.dockIcon.Position
        end
    end)
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if dockDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dockDragStart
            if math.abs(delta.X) > DOCK_DRAG_THRESHOLD or math.abs(delta.Y) > DOCK_DRAG_THRESHOLD then
                dockHasMoved = true
            end
            if dockHasMoved then
                self.dockIcon.Position = UDim2.new(dockStartPos.X.Scale, dockStartPos.X.Offset + delta.X, dockStartPos.Y.Scale, dockStartPos.Y.Offset + delta.Y)
            end
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dockDragging and not dockHasMoved then
                -- Solo click sin mover = abrir menú
                self:toggleMinimize()
            end
            dockDragging = false
        end
    end))
    
    -- Animación de pulso en hover
    dockButton.MouseEnter:Connect(function()
        TweenService:Create(self.dockIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
    end)
    dockButton.MouseLeave:Connect(function()
        TweenService:Create(self.dockIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 55, 0, 55)}):Play()
    end)
    
    self:loadOreList()
    self:loadPlayerList()
    self:loadTeleportList()
    self:setupRangeSlider()
end

function KillAuraMine:refreshAllLists()
    self:loadPlayerList()
    self:loadOreList()
end

function KillAuraMine:setupRangeSlider()
    local sliderContainer = self.mainFrame:FindFirstChild("AuraPanel", true):FindFirstChild("RangeSliderContainer", true)
    local sliderButton = sliderContainer:FindFirstChild("RangeSliderButton", true)
    local sliderFill = sliderContainer:FindFirstChildOfClass("Frame")
    
    local dragging = false
    
    local function updateRangeSlider(input)
        if not dragging then return end
        
        local sliderSize = sliderContainer.AbsoluteSize.X
        local mousePos = input.Position.X
        local sliderPos = sliderContainer.AbsolutePosition.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        local newRange = math.floor(10 + percent * 1490)
        CONFIG.Range = newRange
        self.rangeLabel.Text = "📏 Rango: " .. CONFIG.Range
        
        sliderButton.Position = UDim2.new(percent, -8, 0.5, -8)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    end

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateRangeSlider(input)
        end
    end

    local function onInputChanged(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateRangeSlider(input)
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end

    sliderButton.InputBegan:Connect(onInputBegan)
    sliderContainer.InputBegan:Connect(onInputBegan)
    
    self.connections[#self.connections + 1] = UserInputService.InputChanged:Connect(onInputChanged)
    self.connections[#self.connections + 1] = UserInputService.InputEnded:Connect(onInputEnded)
end

function KillAuraMine:loadPlayerList()
    for _, button in pairs(self.playerButtons) do
        if button then
            button:Destroy()
        end
    end
    self.playerButtons = {}
    
    local players = Players:GetPlayers()
    local yOffset = 5
    
    if #players <= 1 then
        local noPlayersLabel = self:createElement("TextLabel", { 
            Text = "No hay otros jugadores", 
            Font = UI_CONFIG.FONT, 
            TextSize = UI_CONFIG.LABEL_SIZE, 
            TextColor3 = UI_CONFIG.TEXT_MUTED, 
            BackgroundTransparency = 1, 
            Size = UDim2.new(1, -10, 0, 25), 
            Position = UDim2.new(0, 5, 0, yOffset), 
            Parent = self.playerListFrame 
        })
        self.playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 30)
        return
    end
    
    for _, player in ipairs(players) do
        if player ~= self.player then
            local playerButton = self:createElement("TextButton", { 
                Text = player.Name, 
                Font = UI_CONFIG.FONT, 
                TextSize = UI_CONFIG.LABEL_SIZE, 
                TextColor3 = UI_CONFIG.TEXT, 
                BackgroundColor3 = UI_CONFIG.SECONDARY, 
                Size = UDim2.new(1, -10, 0, 25), 
                Position = UDim2.new(0, 5, 0, yOffset), 
                Parent = self.playerListFrame 
        })
            self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = playerButton})
            
            table.insert(self.connections, playerButton.MouseButton1Click:Connect(function()
                self:selectPlayer(player)
            end))
            
            table.insert(self.playerButtons, playerButton)
            yOffset = yOffset + 30
        end
    end
    
    self.playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function KillAuraMine:selectPlayer(player)
    self.selectedPlayer = player
    
    if self.selectedPlayerLabel then
        self.selectedPlayerLabel.Text = "🎯 Jugador seleccionado: " .. player.Name
    end
    
    for _, button in pairs(self.playerButtons) do
        if button.Text == player.Name then
            button.BackgroundColor3 = UI_CONFIG.SUCCESS
        else
            button.BackgroundColor3 = UI_CONFIG.SECONDARY
        end
    end
    
    self:showNotification("Jugador seleccionado: " .. player.Name)
end

function KillAuraMine:toggleAutoKillPlayer()
    self.isAutoKillPlayer = not self.isAutoKillPlayer
    self:updateAutoKillButtons()
    
    if self.isAutoKillPlayer then
        self:startAutoKillPlayer()
        self:showNotification("Auto Kill Player activado para: " .. (self.selectedPlayer and self.selectedPlayer.Name or "Ninguno"))
    else
        self:stopAutoKillPlayer()
        self:showNotification("Auto Kill Player desactivado")
    end
end

function KillAuraMine:updateAutoKillButtons()
    if not self.startAutoKillButton or not self.stopAutoKillButton then return end
    
    if self.isAutoKillPlayer then
        self.startAutoKillButton.Visible = false
        self.stopAutoKillButton.Visible = true
    else
        self.startAutoKillButton.Visible = true
        self.stopAutoKillButton.Visible = false
    end
end

function KillAuraMine:startAutoKillPlayer()
    self.autoKillConnection = RunService.Heartbeat:Connect(function()
        if not self.isAutoKillPlayer or not self.selectedPlayer then return end
        
        local character = self.player.Character
        local targetCharacter = self.selectedPlayer.Character
        if not character or not targetCharacter then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetHrp then return end
        
        -- MODIFICACIÓN: Aparecer MÁS ARRIBA del jugador (aumentado de 15 a 25)
        local offset = Vector3.new(3, 25, 3) -- Aumentado de 15 a 25 en Y
        hrp.CFrame = CFrame.new(targetHrp.Position + offset)
        
        -- Atacar al jugador
        CONFIG.RemoteEvent:FireServer(targetCharacter)
        
        -- Pequeña pausa para evitar spam
        task.wait(0.5)
    end)
end

function KillAuraMine:stopAutoKillPlayer()
    if self.autoKillConnection then
        self.autoKillConnection:Disconnect()
        self.autoKillConnection = nil
    end
end

function KillAuraMine:makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    local hasMoved = false
    local DRAG_THRESHOLD = 5 -- Píxeles de movimiento para considerar que es un drag
    
    table.insert(self.connections, frame.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = frame.Position
        end 
    end))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input) 
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then 
            local delta = input.Position - dragStart
            -- Solo marcar como movido si supera el umbral
            if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
                hasMoved = true
            end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end 
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false
        end 
    end))
    
    -- Guardar referencia para verificar si se movió
    frame:SetAttribute("_wasDragged", false)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            frame:SetAttribute("_wasDragged", hasMoved)
        end
    end)
end

function KillAuraMine:makeSliderDraggable(sliderBg, sliderFill, sliderKnob, minValue, maxValue, initialValue, onValueChanged)
    local dragging = false
    
    local function updateSlider(inputPos)
        local sliderAbsPos = sliderBg.AbsolutePosition.X
        local sliderAbsSize = sliderBg.AbsoluteSize.X
        
        local relativeX = math.clamp((inputPos.X - sliderAbsPos) / sliderAbsSize, 0, 1)
        local value = math.floor(minValue + (maxValue - minValue) * relativeX)
        
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderKnob.Position = UDim2.new(relativeX, -7, 0.5, -7)
        
        if onValueChanged then
            onValueChanged(value)
        end
    end
    
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position)
        end
    end
    
    table.insert(self.connections, sliderBg.InputBegan:Connect(startDrag))
    table.insert(self.connections, sliderKnob.InputBegan:Connect(startDrag))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

function KillAuraMine:startAuraLoop()
    self.auraConnection = RunService.Heartbeat:Connect(function()
        if not self.isAuraActive then return end
        
        local myChar = self.player.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        local targets = {}
        
        if CONFIG.AttackMode == "Players" then
            targets = self:getNearbyPlayers(myHrp.Position)
        elseif CONFIG.AttackMode == "Animals" then
            targets = self:getNearbyAnimals(myHrp.Position)
        elseif CONFIG.AttackMode == "Trees" then
            targets = self:getNearbyTrees(myHrp.Position)
        elseif CONFIG.AttackMode == "Minerales/Secrets" then
            targets = self:getNearbyOresAndSecrets(myHrp.Position)
        end
        
        local attackedCount = 0

        for _, targetData in ipairs(targets) do
            if attackedCount >= CONFIG.MaxTargets then break end
            
            local success = false
            
            if CONFIG.AttackMode == "Players" then
                success = self:attackPlayer(targetData.player)
            elseif CONFIG.AttackMode == "Animals" then
                success = self:attackAnimal(targetData.animal)
            elseif CONFIG.AttackMode == "Trees" then
                success = self:attackTree(targetData.tree)
            elseif CONFIG.AttackMode == "Minerales/Secrets" then
                success = self:attackOreOrSecret(targetData.target)
            end
            
            if success then
                attackedCount = attackedCount + 1
                if CONFIG.AttackInterval > 0 then
                    task.wait(CONFIG.AttackInterval)
                end
            end
        end
    end)
end

function KillAuraMine:getNearbyPlayers(myPosition)
    local nearbyTargets = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.player and player.Character then
            local character = player.Character
            local targetRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character:FindFirstChild("Torso")
            if targetRoot then
                local distance = (myPosition - targetRoot.Position).Magnitude
                if distance <= CONFIG.Range then
                    table.insert(nearbyTargets, { player = player, distance = distance })
                end
            end
        end
    end
    
    table.sort(nearbyTargets, function(a, b) return a.distance < b.distance end)
    return nearbyTargets
end

function KillAuraMine:getNearbyAnimals(myPosition)
    local nearbyTargets = {}
    local addedModels = {}
    
    -- Primero buscar en la carpeta Animals
    local animalsFolder = Workspace:FindFirstChild("Animals")
    if animalsFolder then
        for _, animal in ipairs(animalsFolder:GetChildren()) do
            local targetPart = nil
            
            if animal.PrimaryPart then
                targetPart = animal.PrimaryPart
            else
                for _, part in ipairs(animal:GetDescendants()) do
                    if part:IsA("BasePart") and part.Position then
                        targetPart = part
                        break
                    end
                end
            end
            
            if targetPart then
                local distance = (myPosition - targetPart.Position).Magnitude
                if distance <= CONFIG.Range then
                    table.insert(nearbyTargets, { animal = animal, distance = distance })
                    addedModels[animal] = true
                end
            end
        end
    end
    
    -- Buscar en SpaceshipCrash (Alien boss)
    local spaceshipCrash = Workspace:FindFirstChild("SpaceshipCrash")
    if spaceshipCrash then
        local alien = spaceshipCrash:FindFirstChild("Alien")
        if alien and alien:IsA("Model") and not addedModels[alien] then
            local targetPart = alien.PrimaryPart or alien:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local distance = (myPosition - targetPart.Position).Magnitude
                if distance <= CONFIG.Range then
                    table.insert(nearbyTargets, { animal = alien, distance = distance })
                    addedModels[alien] = true
                end
            end
        end
    end
    
    -- Buscar en Mechanisms (BossAttack de cada zona)
    local mechanisms = Workspace:FindFirstChild("Mechanisms")
    if mechanisms then
        for _, zone in ipairs(mechanisms:GetChildren()) do
            -- Buscar carpeta BossAttack en cada zona
            local bossAttack = zone:FindFirstChild("BossAttack")
            if bossAttack then
                for _, boss in ipairs(bossAttack:GetChildren()) do
                    if boss:IsA("Model") and not addedModels[boss] then
                        local targetPart = boss.PrimaryPart or boss:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            local distance = (myPosition - targetPart.Position).Magnitude
                            if distance <= CONFIG.Range then
                                table.insert(nearbyTargets, { animal = boss, distance = distance })
                                addedModels[boss] = true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Luego buscar en todo el Workspace por otros animales
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= self.player.Character and not addedModels[obj] then
            local isAnimal = false
            
            -- Verificar por nombres comunes de animales y bosses
            local animalNames = {"Yeti", "Water Creature", "Bear", "Wolf", "Deer", "Rabbit", "Fox", "Creature", "Monster", "Beast", "Animal", "Cow", "Pig", "Chicken", "Sheep", "Penguin", "Snake", "Spider", "Bat", "Bird", "Alien", "Mushroom", "Flora", "Venomous", "Boss"}
            for _, name in ipairs(animalNames) do
                if string.find(obj.Name:lower(), name:lower()) then
                    isAnimal = true
                    break
                end
            end
            
            -- Verificar si tiene Humanoid pero no es un jugador
            if not isAnimal and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                isAnimal = true
            end
            
            if isAnimal then
                local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local distance = (myPosition - targetPart.Position).Magnitude
                    if distance <= CONFIG.Range then
                        table.insert(nearbyTargets, { animal = obj, distance = distance })
                    end
                end
            end
        end
    end
    
    table.sort(nearbyTargets, function(a, b) return a.distance < b.distance end)
    return nearbyTargets
end

function KillAuraMine:getNearbyTrees(myPosition)
    local nearbyTargets = {}
    
    local treesFolder = Workspace:FindFirstChild("Trees")
    if not treesFolder then
        return nearbyTargets
    end
    
    for _, tree in ipairs(treesFolder:GetChildren()) do
        local targetPart = nil
        
        if tree.PrimaryPart then
            targetPart = tree.PrimaryPart
        else
            for _, part in ipairs(tree:GetDescendants()) do
                if part:IsA("BasePart") and part.Position then
                    targetPart = part
                    break
                end
            end
        end
        
        if targetPart then
            local distance = (myPosition - targetPart.Position).Magnitude
            if distance <= CONFIG.Range then
                table.insert(nearbyTargets, { tree = tree, distance = distance })
            end
        end
    end
    
    table.sort(nearbyTargets, function(a, b) return a.distance < b.distance end)
    return nearbyTargets
end

-- ============================================================
-- 🔰 FUNCIÓN MODIFICADA: BUSCAR MINERALES Y SECRETOS ADICIONALES
-- ============================================================
function KillAuraMine:getNearbyOresAndSecrets(myPosition)
    local nearbyTargets = {}
    
    -- 🔸 BUSCAR EN RUTAS PRINCIPALES (COMPORTAMIENTO ORIGINAL)
    local oresFolder = Workspace:FindFirstChild(principalOres)
    if oresFolder then
        for _, ore in ipairs(oresFolder:GetChildren()) do
            local targetPart = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local distance = (myPosition - targetPart.Position).Magnitude
                if distance <= CONFIG.Range then
                    table.insert(nearbyTargets, { target = ore, distance = distance, type = "ore" })
                end
            end
        end
    end
    
    local secretsFolder = Workspace:FindFirstChild(principalSecrets)
    if secretsFolder then
        for _, secret in ipairs(secretsFolder:GetChildren()) do
            local targetPart = secret.PrimaryPart or secret:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local distance = (myPosition - targetPart.Position).Magnitude
                if distance <= CONFIG.Range then
                    table.insert(nearbyTargets, { target = secret, distance = distance, type = "secret" })
                end
            end
        end
    end
    
    -- 🔸 BUSCAR MINERALES ADICIONALES (SOLO SI HAY NOMBRES DEFINIDOS)
    if #oresAddNames > 0 then
        for _, path in ipairs(ORE_PATHS) do
            local additionalFolder = getFolderFromPath(Workspace, path)
            if additionalFolder then
                for _, oreName in ipairs(oresAddNames) do
                    local ore = additionalFolder:FindFirstChild(oreName)
                    if ore then
                        local targetPart = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            local distance = (myPosition - targetPart.Position).Magnitude
                            if distance <= CONFIG.Range then
                                table.insert(nearbyTargets, { target = ore, distance = distance, type = "ore" })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 🔸 BUSCAR SECRETOS ADICIONALES (SOLO SI HAY NOMBRES DEFINIDOS)
    if #secretAddNames > 0 then
        for _, path in ipairs(SECRET_PATHS) do
            local additionalFolder = getFolderFromPath(Workspace, path)
            if additionalFolder then
                for _, secretName in ipairs(secretAddNames) do
                    local secret = additionalFolder:FindFirstChild(secretName)
                    if secret then
                        local targetPart = secret.PrimaryPart or secret:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            local distance = (myPosition - targetPart.Position).Magnitude
                            if distance <= CONFIG.Range then
                                table.insert(nearbyTargets, { target = secret, distance = distance, type = "secret" })
                            end
                        end
                    end
                end
            end
        end
    end
    
    table.sort(nearbyTargets, function(a, b) return a.distance < b.distance end)
    return nearbyTargets
end

function KillAuraMine:attackPlayer(player)
    if not player or not player.Character then return false end
    
    local success, errorMsg = pcall(function()
        local targetModel = player.Character
        CONFIG.RemoteEvent:FireServer(targetModel)
        return true
    end)
    
    return success
end

function KillAuraMine:attackAnimal(animal)
    if not animal then return false end
    
    local success, errorMsg = pcall(function()
        CONFIG.RemoteEvent:FireServer(animal)
        return true
    end)
    
    if not success then
        -- Intentar con el método alternativo si el primero falla
        success = pcall(function()
            -- Algunos animales podrían necesitar ser atacados de forma diferente
            local targetPart = animal.PrimaryPart or animal:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                CONFIG.RemoteEvent:FireServer(targetPart)
                return true
            end
        end)
    end
    
    return success
end

function KillAuraMine:attackTree(tree)
    if not tree then return false end
    
    local success, errorMsg = pcall(function()
        CONFIG.RemoteEvent:FireServer(tree)
        return true
    end)
    
    return success
end

function KillAuraMine:attackOreOrSecret(target)
    if not target then return false end
    
    local success, errorMsg = pcall(function()
        CONFIG.RemoteEvent:FireServer(target)
        return true
    end)
    
    return success
end

function KillAuraMine:toggleAura()
    self.isAuraActive = not self.isAuraActive
    self.auraButton.Text = self.isAuraActive and "🟢 DESACTIVAR AURA" or "🔴 ACTIVAR AURA"
    self.auraButton.BackgroundColor3 = self.isAuraActive and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    self:showNotification("Kill Aura " .. (self.isAuraActive and "activado" or "desactivado"))
end

function KillAuraMine:toggleMode()
    if CONFIG.AttackMode == "Players" then
        CONFIG.AttackMode = "Animals"
        self.modeButton.Text = "🎯 MODO: ANIMALES"
        self.modeButton.BackgroundColor3 = UI_CONFIG.WARNING
        self:showNotification("Modo de ataque cambiado a Animales")
    elseif CONFIG.AttackMode == "Animals" then
        CONFIG.AttackMode = "Trees"
        self.modeButton.Text = "🎯 MODO: ÁRBOLES"
        self.modeButton.BackgroundColor3 = UI_CONFIG.DANGER
        self:showNotification("Modo de ataque cambiado a Árboles")
    elseif CONFIG.AttackMode == "Trees" then
        CONFIG.AttackMode = "Minerales/Secrets"
        self.modeButton.Text = "🎯 MODO: MINERALES/SECRETS"
        self.modeButton.BackgroundColor3 = UI_CONFIG.ACCENT2
        self:showNotification("Modo de ataque cambiado a Minerales/Secrets")
    else
        CONFIG.AttackMode = "Players"
        self.modeButton.Text = "🎯 MODO: JUGADORES"
        self.modeButton.BackgroundColor3 = UI_CONFIG.SUCCESS
        self:showNotification("Modo de ataque cambiado a Jugadores")
    end
end

function KillAuraMine:toggleFly()
    self.isFlying = not self.isFlying
    self.flyButton.Text = self.isFlying and "🟢 DESACTIVAR FLY" or "🔴 ACTIVAR FLY"
    self.flyButton.BackgroundColor3 = self.isFlying and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    
    if self.isFlying then
        self:startFly()
        self:showNotification("Fly activado")
        self:createFlyStatusFrame()
    else
        self:stopFly()
        self:showNotification("Fly desactivado")
        if self.flyStatusFrame then
            self.flyStatusFrame.Visible = false
        end
    end
end

function KillAuraMine:createFlyStatusFrame()
    if self.flyStatusFrame then
        self.flyStatusFrame:Destroy()
    end
    
    self.flyStatusFrame = self:createElement("Frame", {
        Name = "FlyStatusFrame",
        Size = UDim2.new(0, 280, 0, 100),
        Position = UDim2.new(0.5, -140, 0.05, 0),
        BackgroundColor3 = UI_CONFIG.PRIMARY,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Parent = self.screenGui
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.flyStatusFrame})
    self:createElement("UIStroke", {Color = UI_CONFIG.ACCENT, Thickness = 1, Parent = self.flyStatusFrame})
    
    local statusLabel = self:createElement("TextLabel", {
        Name = "StatusLabel",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 5),
        Text = "VUELO ACTIVADO",
        TextColor3 = UI_CONFIG.SUCCESS,
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 16,
        BackgroundTransparency = 1,
        Parent = self.flyStatusFrame
    })
    
    local altitudeLabel = self:createElement("TextLabel", {
        Name = "AltitudeLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 30),
        Text = "ALTITUD: 0 u",
        TextColor3 = UI_CONFIG.TEXT,
        Font = UI_CONFIG.FONT,
        TextSize = 14,
        BackgroundTransparency = 1,
        Parent = self.flyStatusFrame
    })
    
    local speedBarFrame = self:createElement("Frame", {
        Size = UDim2.new(0.8, 0, 0, 8),
        Position = UDim2.new(0.1, 0, 0.55, 0),
        BackgroundColor3 = UI_CONFIG.TERTIARY,
        BorderSizePixel = 0,
        Parent = self.flyStatusFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = speedBarFrame})
    
    local speedFill = self:createElement("Frame", {
        Name = "SpeedFill",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UI_CONFIG.ACCENT,
        BorderSizePixel = 0,
        Parent = speedBarFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = speedFill})
    
    local noClipLabel = self:createElement("TextLabel", {
        Name = "NoClipLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0.75, 0),
        Text = "NO-CLIP: OFF",
        TextColor3 = UI_CONFIG.TEXT_MUTED,
        Font = UI_CONFIG.FONT,
        TextSize = 12,
        BackgroundTransparency = 1,
        Parent = self.flyStatusFrame
    })
end

function KillAuraMine:startFly()
    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    self.originalWalkSpeed = humanoid.WalkSpeed
    self.originalJumpPower = humanoid.JumpPower
    
    self.bodyVelocity = Instance.new("BodyVelocity")
    self.bodyVelocity.MaxForce = Vector3.new(CONFIG.BODY_MOVER_FORCE, CONFIG.BODY_MOVER_FORCE, CONFIG.BODY_MOVER_FORCE)
    self.bodyVelocity.P = 2500
    self.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    self.bodyVelocity.Parent = character.HumanoidRootPart
    
    self.bodyGyro = Instance.new("BodyGyro")
    self.bodyGyro.MaxTorque = Vector3.new(CONFIG.BODY_MOVER_FORCE, CONFIG.BODY_MOVER_FORCE, CONFIG.BODY_MOVER_FORCE)
    self.bodyGyro.P = 2500
    self.bodyGyro.CFrame = Workspace.CurrentCamera.CFrame
    self.bodyGyro.Parent = character.HumanoidRootPart
    
    self.flyConnection = RunService.Heartbeat:Connect(function(dt)
        self:updateFlight(dt)
    end)
    
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == BOOST_KEY and self.isFlying then
            self.isBoosting = true
        end
        if input.KeyCode == NOCLIP_KEY and self.isFlying then
            self:setNoClip(not self.noClipEnabled)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == BOOST_KEY then
            self.isBoosting = false
        end
    end))
end

function KillAuraMine:updateFlight(dt)
    if not self.isFlying or not self.bodyVelocity or not self.bodyGyro then return end
    
    local character = self.player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if self.isBoosting and not UserInputService:IsKeyDown(BOOST_KEY) then
        self.isBoosting = false
    end
    self.targetSpeed = self.isBoosting and CONFIG.BOOST_SPEED or CONFIG.BASE_SPEED
    
    if self.currentSpeed < self.targetSpeed then
        self.currentSpeed = math.min(self.currentSpeed + CONFIG.ACCELERATION * dt, self.targetSpeed)
    elseif self.currentSpeed > self.targetSpeed then
        self.currentSpeed = math.max(self.currentSpeed - CONFIG.ACCELERATION * dt, self.targetSpeed)
    end
    
    self.currentSpeed = math.clamp(self.currentSpeed, 0, CONFIG.MAX_SPEED)
    
    if self.flyStatusFrame and self.flyStatusFrame.Visible then
        local altitudeLabel = self.flyStatusFrame:FindFirstChild("AltitudeLabel")
        if altitudeLabel then
            altitudeLabel.Text = "ALTITUD: " .. math.floor(rootPart.Position.Y) .. " u"
        end
        local speedFill = self.flyStatusFrame:FindFirstChild("SpeedFill")
        if speedFill then
            local speedPercentage = self.currentSpeed / CONFIG.MAX_SPEED
            speedFill:TweenSize(UDim2.new(speedPercentage, 0, 1, 0), "Out", "Quad", 0.1, true)
        end
    end
    
    local cameraCF = Workspace.CurrentCamera.CFrame
    local cameraLook = cameraCF.LookVector
    local horizontalLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    local horizontalDirection = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then horizontalDirection += horizontalLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then horizontalDirection -= horizontalLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then horizontalDirection -= cameraCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then horizontalDirection += cameraCF.RightVector end
    
    local verticalDirection = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalDirection = CONFIG.VERTICAL_SPEED end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then verticalDirection = -CONFIG.VERTICAL_SPEED end
    
    local targetVelocity
    if horizontalDirection.Magnitude > 0 then
        horizontalDirection = horizontalDirection.Unit
        targetVelocity = horizontalDirection * self.currentSpeed + Vector3.new(0, verticalDirection, 0)
    else
        targetVelocity = Vector3.new(0, verticalDirection, 0)
    end
    
    self.bodyVelocity.Velocity = targetVelocity
    self.bodyGyro.CFrame = cameraCF
end

function KillAuraMine:setNoClip(enabled)
    self.noClipEnabled = enabled
    local character = self.player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
            end
        end
    end
    if self.flyStatusFrame then
        local noClipLabel = self.flyStatusFrame:FindFirstChild("NoClipLabel")
        if noClipLabel then
            noClipLabel.Text = "NO-CLIP: " .. (enabled and "ON" or "OFF")
            noClipLabel.TextColor3 = enabled and UI_CONFIG.WARNING or UI_CONFIG.TEXT_MUTED
        end
    end
    -- Actualizar botón de NoClip independiente
    if self.noClipButton then
        self.noClipButton.Text = enabled and "🟢 NOCLIP" or "🔴 NOCLIP"
        self.noClipButton.BackgroundColor3 = enabled and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    end
end

function KillAuraMine:toggleNoClip()
    self.noClipEnabled = not self.noClipEnabled
    
    if self.noClipEnabled then
        -- Activar NoClip
        self:setNoClip(true)
        self:showNotification("NoClip activado - Puedes atravesar paredes")
        
        -- Loop para mantener NoClip activo (por si el personaje respawnea)
        self.noClipConnection = RunService.Stepped:Connect(function()
            if not self.noClipEnabled then return end
            
            local character = self.player.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Desactivar NoClip
        if self.noClipConnection then
            self.noClipConnection:Disconnect()
            self.noClipConnection = nil
        end
        self:setNoClip(false)
        self:showNotification("NoClip desactivado")
    end
end

function KillAuraMine:stopFly()
    if self.bodyVelocity then
        self.bodyVelocity:Destroy()
        self.bodyVelocity = nil
    end
    
    if self.bodyGyro then
        self.bodyGyro:Destroy()
        self.bodyGyro = nil
    end
    
    if self.flyConnection then
        self.flyConnection:Disconnect()
        self.flyConnection = nil
    end
    
    local character = self.player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if self.originalWalkSpeed then
            humanoid.WalkSpeed = self.originalWalkSpeed
        end
        if self.originalJumpPower then
            humanoid.JumpPower = self.originalJumpPower
        end
    end
    
    if self.noClipEnabled then
        self:setNoClip(false)
    end
end

function KillAuraMine:toggleSpeed()
    self.isSpeedActive = not self.isSpeedActive
    self.speedButton.Text = self.isSpeedActive and "🟢 DESACTIVAR SPEED" or "🔴 ACTIVAR SPEED"
    self.speedButton.BackgroundColor3 = self.isSpeedActive and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    
    local character = self.player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if self.isSpeedActive then
            if not self.originalWalkSpeed then
                self.originalWalkSpeed = humanoid.WalkSpeed
            end
            if not self.originalJumpPower then
                self.originalJumpPower = humanoid.JumpPower
            end
            
            humanoid.WalkSpeed = CONFIG.WalkSpeed
            humanoid.JumpPower = CONFIG.JumpPower
            self:showNotification("Speed activado")
        else
            if self.originalWalkSpeed then
                humanoid.WalkSpeed = self.originalWalkSpeed
            end
            if self.originalJumpPower then
                humanoid.JumpPower = self.originalJumpPower
            end
            self:showNotification("Speed desactivado")
        end
    end
end

-- ===================================
-- FUNCIONES DE UTILIDADES
-- ===================================

function KillAuraMine:toggleFpsUnlocker()
    self.isFpsUnlocked = not self.isFpsUnlocked
    
    if self.isFpsUnlocked then
        -- Intentar desbloquear FPS usando setfpscap si está disponible (exploits)
        if setfpscap then
            setfpscap(999) -- Desbloquear a máximo
            self:showNotification("FPS Desbloqueado a 999", "success")
        elseif setfps then
            setfps(999)
            self:showNotification("FPS Desbloqueado a 999", "success")
        else
            -- Método alternativo: reducir throttling
            local success = pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                settings():GetService("RenderSettings").QualityLevel = Enum.QualityLevel.Level21
            end)
            if success then
                self:showNotification("FPS optimizado (método alternativo)", "info")
            else
                self:showNotification("⚠️ setfpscap no disponible en este executor", "warning")
            end
        end
        self.fpsUnlockerButton.Text = "🔓 FPS UNLOCKER (ON)"
        self.fpsUnlockerButton.BackgroundColor3 = UI_CONFIG.SUCCESS
    else
        -- Restaurar límite normal
        if setfpscap then
            setfpscap(60)
        elseif setfps then
            setfps(60)
        end
        self.fpsUnlockerButton.Text = "🔓 FPS UNLOCKER (OFF)"
        self.fpsUnlockerButton.BackgroundColor3 = UI_CONFIG.TERTIARY
        self:showNotification("FPS limitado a 60")
    end
end

function KillAuraMine:showServerInfo()
    local Stats = game:GetService("Stats")
    local NetworkStats = Stats.Network
    
    -- Obtener información del servidor
    local ping = math.floor(self.player:GetNetworkPing() * 1000)
    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers
    local jobId = game.JobId
    local placeId = game.PlaceId
    local placeVersion = game.PlaceVersion
    local serverTime = os.date("%H:%M:%S")
    
    -- Obtener memoria usada si es posible
    local memoryUsage = "N/A"
    pcall(function()
        memoryUsage = string.format("%.1f MB", Stats:GetTotalMemoryUsageMb())
    end)
    
    -- Crear ventana de info
    if self.serverInfoFrame then
        self.serverInfoFrame:Destroy()
    end
    
    self.serverInfoFrame = self:createElement("Frame", {
        Name = "ServerInfoFrame",
        Size = UDim2.new(0, 320, 0, 280),
        Position = UDim2.new(0.5, -160, 0.5, -140),
        BackgroundColor3 = UI_CONFIG.PRIMARY,
        Parent = self.screenGui
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.serverInfoFrame})
    self:createElement("UIStroke", {Color = UI_CONFIG.ACCENT, Thickness = 2, Parent = self.serverInfoFrame})
    self:createGlowEffect(self.serverInfoFrame)
    
    -- Título
    local infoTitle = self:createElement("TextLabel", {
        Text = "📊 SERVER INFO",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 16,
        TextColor3 = UI_CONFIG.ACCENT,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 5),
        Parent = self.serverInfoFrame
    })
    
    -- Contenido de info
    local infoText = string.format([[
🌐 Ping: %dms
👥 Jugadores: %d/%d
🆔 Job ID: %s
📍 Place ID: %d
📦 Versión: %d
💾 Memoria: %s
⏰ Hora: %s
    ]], ping, playerCount, maxPlayers, 
    string.sub(jobId, 1, 20) .. "...", 
    placeId, placeVersion, memoryUsage, serverTime)
    
    local infoContent = self:createElement("TextLabel", {
        Text = infoText,
        Font = UI_CONFIG.FONT_MONO,
        TextSize = 13,
        TextColor3 = UI_CONFIG.TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 180),
        Position = UDim2.new(0, 15, 0, 40),
        Parent = self.serverInfoFrame
    })
    
    -- Botón copiar JobId
    local copyButton = self:createElement("TextButton", {
        Text = "📋 Copiar Job ID",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 12,
        TextColor3 = UI_CONFIG.TEXT,
        BackgroundColor3 = UI_CONFIG.ACCENT2,
        Size = UDim2.new(0.45, -5, 0, 30),
        Position = UDim2.new(0, 10, 1, -40),
        Parent = self.serverInfoFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = copyButton})
    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(jobId)
            self:showNotification("Job ID copiado!", "success")
        else
            self:showNotification("Clipboard no disponible", "warning")
        end
    end)
    
    -- Botón cerrar
    local closeInfoButton = self:createElement("TextButton", {
        Text = "✕ Cerrar",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 12,
        TextColor3 = UI_CONFIG.TEXT,
        BackgroundColor3 = UI_CONFIG.DANGER,
        Size = UDim2.new(0.45, -5, 0, 30),
        Position = UDim2.new(0.55, 0, 1, -40),
        Parent = self.serverInfoFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = closeInfoButton})
    closeInfoButton.MouseButton1Click:Connect(function()
        self.serverInfoFrame:Destroy()
        self.serverInfoFrame = nil
    end)
    
    self:makeDraggable(self.serverInfoFrame)
end

function KillAuraMine:runDupeCheck()
    self:showNotification("🔍 Analizando items...", "info")
    
    local results = {}
    local potentialDupes = {}
    local analyzedCount = 0
    
    -- Buscar en el backpack del jugador
    local backpack = self.player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            analyzedCount = analyzedCount + 1
            local itemName = item.Name
            
            if not results[itemName] then
                results[itemName] = {count = 0, items = {}}
            end
            results[itemName].count = results[itemName].count + 1
            table.insert(results[itemName].items, item)
        end
    end
    
    -- Buscar en el character (herramientas equipadas)
    local character = self.player.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                analyzedCount = analyzedCount + 1
                local itemName = item.Name
                
                if not results[itemName] then
                    results[itemName] = {count = 0, items = {}}
                end
                results[itemName].count = results[itemName].count + 1
                table.insert(results[itemName].items, item)
            end
        end
    end
    
    -- Buscar en PlayerGui por inventarios custom
    local playerGui = self.player:FindFirstChild("PlayerGui")
    if playerGui then
        -- Buscar frames que parezcan inventarios
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Name:lower():find("count") then
                local countText = gui.Text
                local count = tonumber(countText:match("%d+"))
                if count and count > 1 then
                    local parentName = gui.Parent and gui.Parent.Name or "Unknown"
                    if not potentialDupes[parentName] then
                        potentialDupes[parentName] = count
                    end
                end
            end
        end
    end
    
    -- Buscar ReplicatedStorage por datos de inventario
    local inventoryData = ReplicatedStorage:FindFirstChild("Inventory") or ReplicatedStorage:FindFirstChild("PlayerData")
    if inventoryData then
        for _, data in ipairs(inventoryData:GetDescendants()) do
            if data:IsA("NumberValue") or data:IsA("IntValue") then
                if data.Value > 10 then
                    potentialDupes[data.Name] = data.Value
                end
            end
        end
    end
    
    -- Crear ventana de resultados
    if self.dupeCheckFrame then
        self.dupeCheckFrame:Destroy()
    end
    
    self.dupeCheckFrame = self:createElement("Frame", {
        Name = "DupeCheckFrame",
        Size = UDim2.new(0, 350, 0, 320),
        Position = UDim2.new(0.5, -175, 0.5, -160),
        BackgroundColor3 = UI_CONFIG.PRIMARY,
        Parent = self.screenGui
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.dupeCheckFrame})
    self:createElement("UIStroke", {Color = UI_CONFIG.WARNING, Thickness = 2, Parent = self.dupeCheckFrame})
    self:createGlowEffect(self.dupeCheckFrame)
    
    -- Título
    local dupeTitle = self:createElement("TextLabel", {
        Text = "🔍 DUPE CHECK RESULTS",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 16,
        TextColor3 = UI_CONFIG.WARNING,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 5),
        Parent = self.dupeCheckFrame
    })
    
    -- Scroll frame para resultados
    local resultsScroll = self:createElement("ScrollingFrame", {
        BackgroundColor3 = UI_CONFIG.SECONDARY,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -20, 0, 220),
        Position = UDim2.new(0, 10, 0, 40),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI_CONFIG.ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.dupeCheckFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = resultsScroll})
    self:createElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = resultsScroll
    })
    
    local yOffset = 0
    local hasDupes = false
    
    -- Mostrar items duplicados
    for itemName, data in pairs(results) do
        if data.count > 1 then
            hasDupes = true
            local label = self:createElement("TextLabel", {
                Text = string.format("⚠️ %s x%d", itemName, data.count),
                Font = UI_CONFIG.FONT,
                TextSize = 12,
                TextColor3 = UI_CONFIG.WARNING,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = UI_CONFIG.TERTIARY,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, -10, 0, 25),
                Parent = resultsScroll
            })
            self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = label})
            yOffset = yOffset + 28
        end
    end
    
    -- Mostrar potenciales dupes de inventario
    for itemName, count in pairs(potentialDupes) do
        hasDupes = true
        local label = self:createElement("TextLabel", {
            Text = string.format("📦 %s: %d unidades", itemName, count),
            Font = UI_CONFIG.FONT,
            TextSize = 12,
            TextColor3 = UI_CONFIG.INFO,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = UI_CONFIG.TERTIARY,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, -10, 0, 25),
            Parent = resultsScroll
        })
        self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = label})
        yOffset = yOffset + 28
    end
    
    if not hasDupes then
        local noLabel = self:createElement("TextLabel", {
            Text = "✅ No se encontraron items duplicados",
            Font = UI_CONFIG.FONT,
            TextSize = 12,
            TextColor3 = UI_CONFIG.SUCCESS,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25),
            Parent = resultsScroll
        })
        yOffset = 25
    end
    
    resultsScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
    
    -- Stats label
    local statsLabel = self:createElement("TextLabel", {
        Text = string.format("Analizados: %d items | Métodos: Backpack, Character, GUI", analyzedCount),
        Font = UI_CONFIG.FONT,
        TextSize = 10,
        TextColor3 = UI_CONFIG.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 1, -55),
        Parent = self.dupeCheckFrame
    })
    
    -- Botón cerrar
    local closeDupeButton = self:createElement("TextButton", {
        Text = "✕ Cerrar",
        Font = UI_CONFIG.FONT_BOLD,
        TextSize = 12,
        TextColor3 = UI_CONFIG.TEXT,
        BackgroundColor3 = UI_CONFIG.DANGER,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 1, -35),
        Parent = self.dupeCheckFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = closeDupeButton})
    closeDupeButton.MouseButton1Click:Connect(function()
        self.dupeCheckFrame:Destroy()
        self.dupeCheckFrame = nil
    end)
    
    self:makeDraggable(self.dupeCheckFrame)
    self:showNotification("Análisis completado - " .. analyzedCount .. " items", "success")
end

function KillAuraMine:startStatsMonitor()
    -- Monitor de FPS y Ping en tiempo real
    local lastTime = tick()
    local frameCount = 0
    
    self.statsConnection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 0.5 then -- Actualizar cada 0.5 segundos
            local fps = math.floor(frameCount / (currentTime - lastTime))
            frameCount = 0
            lastTime = currentTime
            
            -- Actualizar FPS label si existe
            if self.fpsLabel then
                self.fpsLabel.Text = "FPS: " .. fps
                if fps >= 50 then
                    self.fpsLabel.TextColor3 = UI_CONFIG.SUCCESS
                elseif fps >= 30 then
                    self.fpsLabel.TextColor3 = UI_CONFIG.WARNING
                else
                    self.fpsLabel.TextColor3 = UI_CONFIG.DANGER
                end
            end
            
            -- Actualizar Ping label si existe
            if self.pingLabel then
                local ping = math.floor(self.player:GetNetworkPing() * 1000)
                self.pingLabel.Text = "PING: " .. ping .. "ms"
                if ping <= 80 then
                    self.pingLabel.TextColor3 = UI_CONFIG.SUCCESS
                elseif ping <= 150 then
                    self.pingLabel.TextColor3 = UI_CONFIG.WARNING
                else
                    self.pingLabel.TextColor3 = UI_CONFIG.DANGER
                end
            end
        end
    end)
    
    table.insert(self.connections, self.statsConnection)
end

function KillAuraMine:toggleAutoCollect()
    self.isAutoCollecting = not self.isAutoCollecting
    self.autoCollectButton.Text = self.isAutoCollecting and "🟢 DETENER AUTO RECOLECTAR" or "🔴 AUTO RECOLECTAR"
    self.autoCollectButton.BackgroundColor3 = self.isAutoCollecting and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    
    if self.isAutoCollecting then
        self:startAutoCollect()
        self:showNotification("Auto Recolectar activado")
    else
        self:stopAutoCollect()
        self:showNotification("Auto Recolectar desactivado")
    end
end

function KillAuraMine:startAutoCollect()
    self.autoCollectConnection = RunService.Heartbeat:Connect(function()
        if not self.isAutoCollecting then return end
        
        local character = self.player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local itemsFolder = Workspace:FindFirstChild("Items")
        if not itemsFolder then return end

        local itemsToCollect = itemsFolder:GetChildren()
        if #itemsToCollect == 0 then return end

        table.sort(itemsToCollect, function(a, b)
            local partA = a:IsA("BasePart") and a or a:FindFirstChildWhichIsA("BasePart")
            local partB = b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart")
            if not partA or not partB then return false end
            return (hrp.Position - partA.Position).Magnitude < (hrp.Position - partB.Position).Magnitude
        end)

        for _, item in ipairs(itemsToCollect) do
            if not self.isAutoCollecting then break end

            local targetPart = nil
            if item:IsA("BasePart") then
                targetPart = item
            elseif item:IsA("Model") then
                targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            end

            if targetPart and targetPart.Parent then
                local distance = (hrp.Position - targetPart.Position).Magnitude
                if distance <= 25 then
                    game:GetService("ReplicatedStorage").Events.GrabItem:FireServer(item)
                    task.wait(0.1)
                end
            end
        end
    end)
end

function KillAuraMine:stopAutoCollect()
    if self.autoCollectConnection then
        self.autoCollectConnection:Disconnect()
        self.autoCollectConnection = nil
    end
end

function KillAuraMine:collectSecretSpecificItems()
    if not self.isAutoCollecting then return end
    
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then return end

    local specialItems = {"Tiny Gift", "SeasonCurrency"}
    for _, itemName in ipairs(specialItems) do
        local item = itemsFolder:FindFirstChild(itemName)
        if item and item:IsA("BasePart") then
            self:showNotification("Recolectando ítem especial: " .. itemName)
            game:GetService("ReplicatedStorage").Events.GrabItem:FireServer(item)
            task.wait(0.1)
        end
    end
end

-- ============================================================
-- 🔰 FUNCIÓN MODIFICADA: FARMING DE SECRETOS (INCLUYE ADICIONALES)
-- ============================================================
function KillAuraMine:farmNextSecret()
    if not self.isFarmingSecrets then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:showNotification("Personaje no encontrado. Reintentando en 5 segundos...")
        task.wait(5)
        self:farmNextSecret()
        return
    end
    
    -- 🔸 BUSCAR EN TODAS LAS FUENTES: PRINCIPAL + ADICIONALES
    local allSecrets = {}
    
    -- Buscar en carpeta principal
    local secretsFolder = Workspace:FindFirstChild(principalSecrets)
    if secretsFolder then
        for _, secret in ipairs(secretsFolder:GetChildren()) do
            table.insert(allSecrets, secret)
        end
    end
    
    -- Buscar en rutas adicionales
    if #secretAddNames > 0 then
        for _, path in ipairs(SECRET_PATHS) do
            local additionalFolder = getFolderFromPath(Workspace, path)
            if additionalFolder then
                for _, secretName in ipairs(secretAddNames) do
                    local secret = additionalFolder:FindFirstChild(secretName)
                    if secret then
                        table.insert(allSecrets, secret)
                    end
                end
            end
        end
    end
    
    if #allSecrets == 0 then
        self:showNotification("No se encontraron secretos. Reintentando en 10 segundos...")
        task.wait(10)
        self:farmNextSecret()
        return
    end

    local myPosition = character.HumanoidRootPart.Position
    local closestSecret = nil
    local closestDistance = math.huge
    
    for _, secret in ipairs(allSecrets) do
        local targetPart = secret.PrimaryPart or secret:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            local distance = (myPosition - targetPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestSecret = secret
            end
        end
    end

    if not closestSecret then
        self:showNotification("No se pudo encontrar un secreto válido. Reintentando...")
        task.wait(5)
        self:farmNextSecret()
        return
    end

    local targetPart = closestSecret.PrimaryPart or closestSecret:FindFirstChildWhichIsA("BasePart")
    if targetPart then
        character.HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 15, 0))
        self:showNotification("Teletransportado a un secreto. Esperando 2 segundos...")
        task.wait(2)
        
        self:showNotification("Iniciando minado del secreto...")
        local mineTimeout = 20
        local startTime = tick()
        
        while closestSecret.Parent and tick() - startTime < mineTimeout and self.isFarmingSecrets do
            if closestSecret and closestSecret.PrimaryPart then
                CONFIG.RemoteEvent:FireServer(closestSecret)
            end
            task.wait(0.1)
        end
        
        if not closestSecret.Parent then
            self:showNotification("Secreto destruido. Esperando 4 segundos...")
            task.wait(4)
            
            self:collectSecretSpecificItems()
        else
            self:showNotification("El secreto tardó demasiado en romper. Pasando al siguiente...")
        end
    end
    
    task.wait(2)
    self:farmNextSecret()
end

function KillAuraMine:startFarmSecrets()
    self:farmNextSecret()
end

function KillAuraMine:stopFarmSecrets()
    self.isFarmingSecrets = false
end

-- ============================================================
-- 🔰 FUNCIÓN MODIFICADA: FARMING DE MINERALES (INCLUYE ADICIONALES)
-- ============================================================
function KillAuraMine:farmNextOre()
    if not self.isFarmingOres then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:showNotification("Personaje no encontrado. Reintentando en 5 segundos...")
        task.wait(5)
        self:farmNextOre()
        return
    end
    
    -- 🔸 BUSCAR EN TODAS LAS FUENTES: PRINCIPAL + ADICIONALES + WORKSPACE
    local targetOres = {}
    
    -- Buscar en carpeta principal
    local oresFolder = Workspace:FindFirstChild(principalOres)
    if oresFolder then
        for _, ore in ipairs(oresFolder:GetChildren()) do
            if ore.Name == self.selectedOreType then
                table.insert(targetOres, ore)
            end
        end
    end
    
    -- Buscar en rutas adicionales (si el mineral seleccionado está en la lista de adicionales)
    if #oresAddNames > 0 and table.find(oresAddNames, self.selectedOreType) then
        for _, path in ipairs(ORE_PATHS) do
            local additionalFolder = getFolderFromPath(Workspace, path)
            if additionalFolder then
                local ore = additionalFolder:FindFirstChild(self.selectedOreType)
                if ore then
                    table.insert(targetOres, ore)
                end
            end
        end
    end
    
    -- Buscar Secret Chests directamente en Workspace
    local selectedLower = self.selectedOreType:lower()
    if string.find(selectedLower, "secret") and string.find(selectedLower, "chest") then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name == self.selectedOreType then
                table.insert(targetOres, obj)
            end
        end
    end
    
    if #targetOres == 0 then
        self:showNotification("No se encontraron minerales del tipo " .. self.selectedOreType .. ". Reintentando en 10 segundos...")
        task.wait(10)
        self:farmNextOre()
        return
    end

    local myPosition = character.HumanoidRootPart.Position
    local closestOre = nil
    local closestDistance = math.huge
    
    for _, ore in ipairs(targetOres) do
        local targetPart = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            local distance = (myPosition - targetPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestOre = ore
            end
        end
    end

    if not closestOre then
        self:showNotification("No se pudo encontrar un mineral válido. Reintentando...")
        task.wait(5)
        self:farmNextOre()
        return
    end

    local targetPart = closestOre.PrimaryPart or closestOre:FindFirstChildWhichIsA("BasePart")
    if targetPart then
        character.HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 15, 0))
        self:showNotification("Teletransportado a " .. self.selectedOreType .. ". Esperando 2 segundos...")
        task.wait(2)
        
        self:showNotification("Iniciando minado de " .. self.selectedOreType .. "...")
        local mineTimeout = 20
        local startTime = tick()
        
        while closestOre.Parent and tick() - startTime < mineTimeout and self.isFarmingOres do
            if closestOre and closestOre.PrimaryPart then
                CONFIG.RemoteEvent:FireServer(closestOre)
            end
            task.wait(0.1)
        end
        
        if not closestOre.Parent then
            self:showNotification("Mineral destruido. Esperando 3 segundos...")
            task.wait(3)
        else
            self:showNotification("El mineral tardó demasiado en romper. Pasando al siguiente...")
        end
    end
    
    task.wait(2)
    self:farmNextOre()
end

function KillAuraMine:startFarmOres()
    if not self.selectedOreType then
        self:showNotification("Error: No hay mineral seleccionado")
        self.isFarmingOres = false
        self:updateOreSelectionButtons()
        return
    end
    self:farmNextOre()
end

function KillAuraMine:stopFarmOres()
    self.isFarmingOres = false
end

function KillAuraMine:toggleFarmSecrets()
    self.isFarmingSecrets = not self.isFarmingSecrets
    self.farmSecretsButton.Text = self.isFarmingSecrets and "🟢 DETENER FARM SECRETS" or "🔴 INICIAR FARM SECRETS"
    self.farmSecretsButton.BackgroundColor3 = self.isFarmingSecrets and UI_CONFIG.SUCCESS or UI_CONFIG.TERTIARY
    
    if self.isFarmingSecrets then
        self:startFarmSecrets()
        self:showNotification("Farm Secrets activado")
    else
        self:stopFarmSecrets()
        self:showNotification("Farm Secrets desactivado")
    end
end

function KillAuraMine:toggleFarmOres()
    self.isFarmingOres = not self.isFarmingOres
    self:updateOreSelectionButtons()
    
    if self.isFarmingOres then
        self:startFarmOres()
        self:showNotification("Farm Ores activado para: " .. (self.selectedOreType or "Ninguno"))
    else
        self:stopFarmOres()
        self:showNotification("Farm Ores desactivado")
    end
end

function KillAuraMine:updateOreSelectionButtons()
    if not self.startFarmOresButton or not self.stopFarmOresButton then return end
    
    if self.isFarmingOres then
        self.startFarmOresButton.Visible = false
        self.stopFarmOresButton.Visible = true
    else
        self.startFarmOresButton.Visible = true
        self.stopFarmOresButton.Visible = false
    end
end

-- ============================================================
-- 🔰 FUNCIÓN MODIFICADA: LISTA DE MINERALES (INCLUYE ADICIONALES)
-- ============================================================
function KillAuraMine:loadOreList()
    for _, button in pairs(self.oreButtons) do
        if button then
            button:Destroy()
        end
    end
    self.oreButtons = {}
    
    local oreTypes = {}
    
    -- 🔸 BUSCAR EN CARPETA PRINCIPAL
    local oresFolder = Workspace:FindFirstChild(principalOres)
    if oresFolder then
        for _, ore in ipairs(oresFolder:GetChildren()) do
            local oreName = ore.Name
            if oreName and not oreTypes[oreName] then
                oreTypes[oreName] = true
            end
        end
    end
    
    -- 🔸 BUSCAR EN RUTAS ADICIONALES
    if #oresAddNames > 0 then
        for _, oreName in ipairs(oresAddNames) do
            oreTypes[oreName] = true
        end
    end
    
    -- 🔸 BUSCAR SECRET CHESTS EN WORKSPACE (Secret Ruby Chest, etc.)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if string.find(name, "secret") and string.find(name, "chest") then
                if not oreTypes[obj.Name] then
                    oreTypes[obj.Name] = true
                end
            end
        end
    end
    
    local layoutOrder = 0
    for oreName, _ in pairs(oreTypes) do
        local oreButton = self:createElement("TextButton", { 
            Text = oreName, 
            Font = UI_CONFIG.FONT, 
            TextSize = UI_CONFIG.LABEL_SIZE, 
            TextColor3 = UI_CONFIG.TEXT, 
            BackgroundColor3 = (self.selectedOreType == oreName) and UI_CONFIG.SUCCESS or UI_CONFIG.SECONDARY, 
            Size = UDim2.new(1, 0, 0, 25), 
            LayoutOrder = layoutOrder,
            Parent = self.oreListFrame 
        })
        self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = oreButton})
        
        oreButton.MouseButton1Click:Connect(function()
            self:selectOreType(oreName)
        end)
        
        table.insert(self.oreButtons, oreButton)
        layoutOrder = layoutOrder + 1
    end
    
    if layoutOrder == 0 then
        local noOresLabel = self:createElement("TextLabel", { 
            Text = "No hay minerales disponibles", 
            Font = UI_CONFIG.FONT, 
            TextSize = UI_CONFIG.LABEL_SIZE, 
            TextColor3 = UI_CONFIG.TEXT_MUTED, 
            BackgroundTransparency = 1, 
            Size = UDim2.new(1, 0, 0, 25), 
            LayoutOrder = layoutOrder,
            Parent = self.oreListFrame 
        })
        layoutOrder = layoutOrder + 1
    end
end

function KillAuraMine:updateOreList()
    -- Actualización en tiempo real de la lista de minerales
    -- Nota: si hay minerales "adicionales" (oresAddNames), no deben provocar recargas infinitas.
    -- Throttle para no ejecutar en cada Heartbeat.
    self._lastOreListUpdate = self._lastOreListUpdate or 0
    if tick() - self._lastOreListUpdate < 0.75 then
        return
    end
    self._lastOreListUpdate = tick()

    local oresFolder = Workspace:FindFirstChild(principalOres)
    
    local currentOres = {}
    for _, button in pairs(self.oreButtons) do
        if button then
            currentOres[button.Text] = true
        end
    end

    -- Conjunto esperado = Ores del folder principal + nombres adicionales
    local expectedOres = {}
    if oresFolder then
        for _, ore in ipairs(oresFolder:GetChildren()) do
            expectedOres[ore.Name] = true
        end
    end
    if #oresAddNames > 0 then
        for _, oreName in ipairs(oresAddNames) do
            expectedOres[oreName] = true
        end
    end
    
    local hasChanges = false
    
    -- Verificar si hay minerales nuevos
    for oreName, _ in pairs(expectedOres) do
        if not currentOres[oreName] then
            hasChanges = true
            break
        end
    end

    -- Verificar si hay minerales eliminados
    if not hasChanges then
        for oreName, _ in pairs(currentOres) do
            if not expectedOres[oreName] then
                hasChanges = true
                break
            end
        end
    end
    
    if hasChanges then
        self:loadOreList()
    end
end

function KillAuraMine:selectOreType(oreName)
    self.selectedOreType = oreName
    
    if self.selectedOreLabel then
        self.selectedOreLabel.Text = "📦 Mineral seleccionado: " .. oreName
    end
    
    for _, button in pairs(self.oreButtons) do
        if button.Text == oreName then
            button.BackgroundColor3 = UI_CONFIG.SUCCESS
        else
            button.BackgroundColor3 = UI_CONFIG.SECONDARY
        end
    end
    
    self:showNotification("Mineral seleccionado: " .. oreName)
end

-- ===================================
-- FUNCIONES DE TELEPORT
-- ===================================

function KillAuraMine:loadTeleportList()
    for _, button in pairs(self.teleportButtons) do
        if button then
            button:Destroy()
        end
    end
    self.teleportButtons = {}
    self.teleportAreas = {}
    
    -- Buscar las áreas de niveles en ReplicatedStorage
    local levelAreasFolder = ReplicatedStorage:FindFirstChild("Items")
    if levelAreasFolder then
        levelAreasFolder = levelAreasFolder:FindFirstChild("CaveRelated")
        if levelAreasFolder then
            levelAreasFolder = levelAreasFolder:FindFirstChild("LevelAreas")
        end
    end
    
    local yOffset = 5
    
    if not levelAreasFolder then
        local noAreasLabel = self:createElement("TextLabel", { 
            Text = "No se encontraron áreas de niveles", 
            Font = UI_CONFIG.FONT, 
            TextSize = UI_CONFIG.LABEL_SIZE, 
            TextColor3 = UI_CONFIG.TEXT_MUTED, 
            BackgroundTransparency = 1, 
            Size = UDim2.new(1, -10, 0, 25), 
            Position = UDim2.new(0, 5, 0, yOffset), 
            Parent = self.teleportListFrame 
        })
        self.teleportListFrame.CanvasSize = UDim2.new(0, 0, 0, 30)
        return
    end
    
    -- Recopilar todas las áreas
    for _, area in ipairs(levelAreasFolder:GetChildren()) do
        if area:IsA("Model") or area:IsA("Part") then
            table.insert(self.teleportAreas, area)
            
            local areaButton = self:createElement("TextButton", { 
                Text = "📍 " .. area.Name, 
                Font = UI_CONFIG.FONT, 
                TextSize = UI_CONFIG.BUTTON_SIZE, 
                TextColor3 = UI_CONFIG.TEXT, 
                BackgroundColor3 = UI_CONFIG.SECONDARY, 
                Size = UDim2.new(1, -10, 0, 35), 
                Position = UDim2.new(0, 5, 0, yOffset), 
                Parent = self.teleportListFrame 
            })
            self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = areaButton})
            
            table.insert(self.connections, areaButton.MouseButton1Click:Connect(function()
                self:teleportToArea(area)
            end))
            
            table.insert(self.teleportButtons, areaButton)
            yOffset = yOffset + 40
        end
    end
    
    if #self.teleportAreas == 0 then
        local noAreasLabel = self:createElement("TextLabel", { 
            Text = "No hay áreas disponibles", 
            Font = UI_CONFIG.FONT, 
            TextSize = UI_CONFIG.LABEL_SIZE, 
            TextColor3 = UI_CONFIG.TEXT_MUTED, 
            BackgroundTransparency = 1, 
            Size = UDim2.new(1, -10, 0, 25), 
            Position = UDim2.new(0, 5, 0, yOffset), 
            Parent = self.teleportListFrame 
        })
        yOffset = yOffset + 30
    end
    
    self.teleportListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function KillAuraMine:teleportToArea(area)
    local character = self.player.Character
    if not character then
        self:showNotification("❌ Error: Personaje no encontrado")
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        self:showNotification("❌ Error: HumanoidRootPart no encontrado")
        return
    end
    
    -- Obtener la posición del área
    local targetPosition
    if area:IsA("Part") then
        targetPosition = area.Position
    elseif area:IsA("Model") then
        local primaryPart = area.PrimaryPart
        if primaryPart then
            targetPosition = primaryPart.Position
        else
            -- Buscar cualquier parte del modelo
            local firstPart = area:FindFirstChildWhichIsA("BasePart")
            if firstPart then
                targetPosition = firstPart.Position
            else
                self:showNotification("❌ Error: No se pudo encontrar posición del área")
                return
            end
        end
    end
    
    -- Teletransportar al jugador (con un offset más alto para no quedar atrapado)
    local offset = Vector3.new(0, 15, 0)
    humanoidRootPart.CFrame = CFrame.new(targetPosition + offset)
    
    self:showNotification("✅ Teletransportado a: " .. area.Name)
end

-- ===================================
-- FUNCIÓN SWITCH TAB ACTUALIZADA
-- ===================================

function KillAuraMine:switchTab(tabName)
    if self.currentTab == tabName then return end
    
    self.currentTab = tabName
    
    local modulesTab = self.mainFrame.TabsContainer.ModulesTab
    local playerTab = self.mainFrame.TabsContainer.PlayerTab
    local teleportTab = self.mainFrame.TabsContainer.TeleportTab
    local modulesContent = self.mainFrame.ContentContainer.ModulesContent
    local playerContent = self.mainFrame.ContentContainer.PlayerContent
    local teleportContent = self.mainFrame.ContentContainer.TeleportContent
    
    -- Resetear todos los colores de pestañas
    modulesTab.TextColor3 = UI_CONFIG.TEXT_MUTED
    playerTab.TextColor3 = UI_CONFIG.TEXT_MUTED
    teleportTab.TextColor3 = UI_CONFIG.TEXT_MUTED
    
    -- Ocultar todo el contenido
    modulesContent.Visible = false
    playerContent.Visible = false
    teleportContent.Visible = false
    
    -- Mostrar la pestaña seleccionada
    if tabName == "Modules" then
        modulesTab.TextColor3 = UI_CONFIG.TEXT
        modulesContent.Visible = true
    elseif tabName == "Player" then
        playerTab.TextColor3 = UI_CONFIG.TEXT
        playerContent.Visible = true
    elseif tabName == "Teleport" then
        teleportTab.TextColor3 = UI_CONFIG.TEXT
        teleportContent.Visible = true
    end
end

function KillAuraMine:toggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then 
        self.lastPosition = self.mainFrame.Position; 
        self.mainFrame.Visible = false; 
        self.dockIcon.Visible = true; 
        self:showNotification("Hub minimizado")
    else 
        self.dockIcon.Visible = false; 
        self.mainFrame.Position = self.lastPosition or UDim2.new(0.5, -250, 0.5, -250); 
        self.mainFrame.Visible = true; 
        self:showNotification("Hub restaurado") 
    end
end

function KillAuraMine:destroy()
    self.isAuraActive = false
    self.isFlying = false
    self.isSpeedActive = false
    self.isFarmingSecrets = false
    self.isFarmingOres = false
    self.isAutoCollecting = false
    self.isAutoKillPlayer = false
    
    if self.isFlying then
        self:stopFly()
    end

    if self.isFarmingSecrets then
        self:stopFarmSecrets()
    end
    
    if self.isFarmingOres then
        self:stopFarmOres()
    end

    if self.isAutoCollecting then
        self:stopAutoCollect()
    end
    
    if self.isAutoKillPlayer then
        self:stopAutoKillPlayer()
    end
    
    if self.isSpeedActive then
        local character = self.player.Character
        if character and character:FindFirstChildOfClass("Humanoid") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if self.originalWalkSpeed then
                humanoid.WalkSpeed = self.originalWalkSpeed
            end
            if self.originalJumpPower then
                humanoid.JumpPower = self.originalJumpPower
            end
        end
    end
    
    for _, connection in pairs(self.connections) do if connection then connection:Disconnect() end end
    if self.auraConnection then self.auraConnection:Disconnect() end
    if self.flyConnection then self.flyConnection:Disconnect() end
    if self.autoKillConnection then self.autoKillConnection:Disconnect() end
    if self.oreUpdateConnection then self.oreUpdateConnection:Disconnect() end
    if self.screenGui then self.screenGui:Destroy() end
    self = nil
end

-- ===================================
-- EJECUCIÓN PRINCIPAL
-- ===================================
local killAuraMineMenu = KillAuraMine.new()
