local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

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

local BOOST_KEY = Enum.KeyCode.LeftControl
local NOCLIP_KEY = Enum.KeyCode.N

local KillAuraMine = {}
KillAuraMine.__index = KillAuraMine

function KillAuraMine.new()
    local self = setmetatable({}, KillAuraMine)
    self.player = Players.LocalPlayer
    self.minimized = false
    self.isAuraActive = false
    self.isFlying = false
    self.isSpeedActive = false
    
    self.isBoosting = false
    self.noClipEnabled = false
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
    return self
end

function KillAuraMine:createElement(className, properties)
    local element = Instance.new(className)
    for prop, value in pairs(properties) do element[prop] = value end
    return element
end

function KillAuraMine:showNotification(message)
    print("[KillAura-Mine] " .. message)
    local notifGui = self:createElement("ScreenGui", { Name = "KillAuraNotif", Parent = self.player:WaitForChild("PlayerGui") })
    local notifFrame = self:createElement("Frame", { BackgroundColor3 = Color3.fromRGB(30, 30, 40), Size = UDim2.new(0, 250, 0, 50), Position = UDim2.new(0, 10, 1, -60), Parent = notifGui })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = notifFrame})
    self:createElement("UIStroke", {Color = Color3.fromRGB(200, 50, 50), Thickness = 1, Parent = notifFrame})
    local label = self:createElement("TextLabel", { Text = message, Font = Enum.Font.GothamSemibold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), Parent = notifFrame })
    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, 10, 1, -70)})
    tweenIn:Play()
    task.wait(CONFIG.NotificationDuration)
    local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, 10, 1, 20)})
    tweenOut:Play()
    tweenOut.Completed:Connect(function() notifGui:Destroy() end)
end

function KillAuraMine:createUI()
    self.screenGui = self:createElement("ScreenGui", { Name = "KillAuraMineGUI", ResetOnSpawn = false, Parent = self.player:WaitForChild("PlayerGui") })
    self.mainFrame = self:createElement("Frame", { Name = "MainFrame", BackgroundColor3 = Color3.fromRGB(25, 25, 35), Size = UDim2.new(0, 450, 0, 420), Position = UDim2.new(0.5, -225, 0.5, -210), Parent = self.screenGui })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.mainFrame})
    self:createElement("UIStroke", {Color = Color3.fromRGB(200, 50, 50), Thickness = 2, Parent = self.mainFrame})
    self:makeDraggable(self.mainFrame)
    
    local header = self:createElement("Frame", { Name = "Header", BackgroundColor3 = Color3.fromRGB(40, 40, 50), Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 0), Parent = self.mainFrame })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = header})
    self:createElement("TextLabel", { Text = "DrakHub The Lost Land", Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), Parent = header })
    local minimizeButton = self:createElement("TextButton", { Text = "—", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(255, 193, 7), Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -30, 0, 2.5), Parent = header })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = minimizeButton})
    table.insert(self.connections, minimizeButton.MouseButton1Click:Connect(function() self:toggleMinimize() end))
    local closeButton = self:createElement("TextButton", { Text = "✕", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(220, 20, 60), Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -55, 0, 2.5), Parent = header })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = closeButton})
    table.insert(self.connections, closeButton.MouseButton1Click:Connect(function() self:destroy() end))
    
    local tabsContainer = self:createElement("Frame", { Name = "TabsContainer", BackgroundColor3 = Color3.fromRGB(35, 35, 45), Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 30), Parent = self.mainFrame })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabsContainer})
    
    local modulesTab = self:createElement("TextButton", { 
        Name = "ModulesTab", 
        Text = "MÓDULOS OP", 
        Font = Enum.Font.GothamBold, 
        TextSize = 12, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        BackgroundColor3 = Color3.fromRGB(60, 60, 70), 
        Size = UDim2.new(0.5, -2, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = tabsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = modulesTab})
    table.insert(self.connections, modulesTab.MouseButton1Click:Connect(function() self:switchTab("Modules") end))
    
    local playerTab = self:createElement("TextButton", { 
        Name = "PlayerTab", 
        Text = "JUGADOR", 
        Font = Enum.Font.GothamBold, 
        TextSize = 12, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        BackgroundColor3 = Color3.fromRGB(45, 45, 55), 
        Size = UDim2.new(0.5, -2, 1, 0), 
        Position = UDim2.new(0.5, 2, 0, 0), 
        Parent = tabsContainer 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = playerTab})
    table.insert(self.connections, playerTab.MouseButton1Click:Connect(function() self:switchTab("Player") end))
    
    local contentContainer = self:createElement("Frame", { Name = "ContentContainer", BackgroundColor3 = Color3.fromRGB(25, 25, 35), Size = UDim2.new(1, 0, 1, -60), Position = UDim2.new(0, 0, 0, 60), Parent = self.mainFrame })
    
    local modulesContent = self:createElement("ScrollingFrame", { 
        Name = "ModulesContent", 
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), 
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Visible = true,
        ScrollBarThickness = 5,
        Parent = contentContainer 
    })
    
    local leftPanel = self:createElement("Frame", { 
        Name = "LeftPanel", 
        BackgroundColor3 = Color3.fromRGB(30, 30, 40), 
        Size = UDim2.new(0.5, -5, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Parent = modulesContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = leftPanel})
    
    local rightPanel = self:createElement("Frame", { 
        Name = "RightPanel", 
        BackgroundColor3 = Color3.fromRGB(30, 30, 40), 
        Size = UDim2.new(0.5, -5, 1, 0), 
        Position = UDim2.new(0.5, 5, 0, 0), 
        Parent = modulesContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = rightPanel})
    
    local leftTitle = self:createElement("TextLabel", { 
        Text = "KILL AURA & FARM SECRETS", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(200, 200, 200), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 5), 
        Parent = leftPanel 
    })
    
    self.modeButton = self:createElement("TextButton", { 
        Text = "   MODO: JUGADORES", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        TextXAlignment = Enum.TextXAlignment.Left, 
        BackgroundColor3 = Color3.fromRGB(50, 100, 50), 
        Size = UDim2.new(1, -20, 0, 30), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = leftPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.modeButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.modeButton})
    table.insert(self.connections, self.modeButton.MouseButton1Click:Connect(function() self:toggleMode() end))
    
    self.rangeLabel = self:createElement("TextLabel", { Text = "Rango: " .. CONFIG.Range, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 75), Parent = leftPanel })
    self.rangeSlider = self:createElement("TextBox", {
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        PlaceholderText = "Usa el slider para ajustar",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 105),
        Parent = leftPanel
    })
    
    local slider = self:createElement("Frame", {
        Name = "Slider",
        BackgroundColor3 = Color3.fromRGB(70, 70, 80),
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 140),
        Parent = leftPanel
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = slider})
    
    local sliderButton = self:createElement("TextButton", {
        Name = "SliderButton",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, (CONFIG.Range - 10) / 100 * (slider.AbsoluteSize.X - 20), 0, 0),
        BackgroundColor3 = Color3.fromRGB(50, 200, 50),
        Text = "",
        Parent = slider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = sliderButton})

    local dragging = false
    
    local function updateSlider(input)
        if not dragging then return end
        
        local sliderSize = slider.AbsoluteSize.X
        local mousePos = input.Position.X
        local sliderPos = slider.AbsolutePosition.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        local newRange = math.floor(percent * 100) + 10
        CONFIG.Range = newRange
        self.rangeLabel.Text = "Rango: " .. CONFIG.Range
        
        sliderButton.Position = UDim2.new(0, percent * (sliderSize - 20), 0, 0)
    end

    table.insert(self.connections, sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    
    table.insert(self.connections, slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end))

    self.auraButton = self:createElement("TextButton", { Text = "   ACTIVAR AURA", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Color3.fromRGB(50, 50, 60), Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 175), Parent = leftPanel })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.auraButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.auraButton})
    local statusIndicator = self:createElement("Frame", { Name = "Status", BackgroundColor3 = Color3.fromRGB(150, 40, 40), Size = UDim2.new(0, 8, 0, 25), Position = UDim2.new(1, -15, 0.5, -12.5), Parent = self.auraButton })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = statusIndicator})
    table.insert(self.connections, self.auraButton.MouseButton1Click:Connect(function() self:toggleAura() end))
    
    self.farmSecretsButton = self:createElement("TextButton", { 
        Text = "   FARM SECRETS", 
        Font = Enum.Font.GothamBold, 
        TextSize = 16, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        TextXAlignment = Enum.TextXAlignment.Left, 
        BackgroundColor3 = Color3.fromRGB(80, 60, 40), 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 225), 
        Parent = leftPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.farmSecretsButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.farmSecretsButton})
    local farmSecretsStatusIndicator = self:createElement("Frame", { Name = "FarmSecretsStatus", BackgroundColor3 = Color3.fromRGB(150, 40, 40), Size = UDim2.new(0, 8, 0, 25), Position = UDim2.new(1, -15, 0.5, -12.5), Parent = self.farmSecretsButton })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = farmSecretsStatusIndicator})
    table.insert(self.connections, self.farmSecretsButton.MouseButton1Click:Connect(function() self:toggleFarmSecrets() end))
    
    local rightTitle = self:createElement("TextLabel", { 
        Text = "FARM ORES & AUTO RECOLECTAR", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(200, 200, 200), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 5), 
        Parent = rightPanel 
    })
    
    self.selectedOreLabel = self:createElement("TextLabel", { 
        Text = "Mineral seleccionado: Ninguno", 
        Font = Enum.Font.Gotham, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(200, 200, 200), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -20, 0, 25), 
        Position = UDim2.new(0, 10, 0, 35), 
        Parent = rightPanel 
    })
    
    self.oreListFrame = self:createElement("ScrollingFrame", { 
        Name = "OreListFrame", 
        BackgroundColor3 = Color3.fromRGB(40, 40, 50), 
        Size = UDim2.new(1, -20, 0, 150), 
        Position = UDim2.new(0, 10, 0, 65), 
        Visible = true,
        ScrollBarThickness = 5,
        Parent = rightPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.oreListFrame})
    
    self.startFarmOresButton = self:createElement("TextButton", { 
        Text = "INICIAR FARMEO", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        BackgroundColor3 = Color3.fromRGB(60, 120, 60), 
        Size = UDim2.new(1, -20, 0, 30), 
        Position = UDim2.new(0, 10, 0, 225), 
        Parent = rightPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.startFarmOresButton})
    table.insert(self.connections, self.startFarmOresButton.MouseButton1Click:Connect(function() 
        if self.selectedOreType then
            self:toggleFarmOres()
        else
            self:showNotification("Por favor, selecciona un mineral primero")
        end
    end))
    
    self.stopFarmOresButton = self:createElement("TextButton", { 
        Text = "DETENER FARMEO", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        BackgroundColor3 = Color3.fromRGB(180, 60, 60), 
        Size = UDim2.new(1, -20, 0, 30), 
        Position = UDim2.new(0, 10, 0, 225), 
        Visible = false, 
        Parent = rightPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.stopFarmOresButton})
    table.insert(self.connections, self.stopFarmOresButton.MouseButton1Click:Connect(function() 
        self:toggleFarmOres()
    end))
    
    self.autoCollectButton = self:createElement("TextButton", { 
        Text = "   AUTO RECOLECTAR", 
        Font = Enum.Font.GothamBold, 
        TextSize = 16, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        TextXAlignment = Enum.TextXAlignment.Left, 
        BackgroundColor3 = Color3.fromRGB(50, 50, 150), 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 265), 
        Parent = rightPanel 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.autoCollectButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.autoCollectButton})
    local autoCollectStatusIndicator = self:createElement("Frame", { Name = "AutoCollectStatus", BackgroundColor3 = Color3.fromRGB(150, 40, 40), Size = UDim2.new(0, 8, 0, 25), Position = UDim2.new(1, -15, 0.5, -12.5), Parent = self.autoCollectButton })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = autoCollectStatusIndicator})
    table.insert(self.connections, self.autoCollectButton.MouseButton1Click:Connect(function() self:toggleAutoCollect() end))
    
    self:loadOreList()
    
    local playerContent = self:createElement("ScrollingFrame", { 
        Name = "PlayerContent", 
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), 
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0, 0, 0, 0), 
        Visible = false,
        ScrollBarThickness = 5,
        Parent = contentContainer 
    })
    
    self.flyButton = self:createElement("TextButton", { 
        Text = "   ACTIVAR FLY", 
        Font = Enum.Font.GothamBold, 
        TextSize = 16, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        TextXAlignment = Enum.TextXAlignment.Left, 
        BackgroundColor3 = Color3.fromRGB(50, 50, 100), 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 10), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.flyButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.flyButton})
    local flyStatusIndicator = self:createElement("Frame", { Name = "FlyStatus", BackgroundColor3 = Color3.fromRGB(150, 40, 40), Size = UDim2.new(0, 8, 0, 25), Position = UDim2.new(1, -15, 0.5, -12.5), Parent = self.flyButton })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flyStatusIndicator})
    table.insert(self.connections, self.flyButton.MouseButton1Click:Connect(function() self:toggleFly() end))
    
    local flyConfigPanel = self:createElement("Frame", { 
        Name = "FlyConfigPanel", 
        BackgroundColor3 = Color3.fromRGB(30, 30, 40), 
        Size = UDim2.new(1, -20, 0, 180), 
        Position = UDim2.new(0, 10, 0, 60), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = flyConfigPanel})
    
    local flyConfigTitle = self:createElement("TextLabel", { 
        Text = "CONFIGURACIÓN DE VUELO", 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextColor3 = Color3.fromRGB(200, 200, 200), 
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 0, 25), 
        Position = UDim2.new(0, 0, 0, 5), 
        Parent = flyConfigPanel 
    })
    
    self:createFlySlider("Velocidad Base", CONFIG.BASE_SPEED, 10, 200, flyConfigPanel, 30, function(value) CONFIG.BASE_SPEED = value end)
    self:createFlySlider("Velocidad Boost", CONFIG.BOOST_SPEED, 20, 400, flyConfigPanel, 65, function(value) CONFIG.BOOST_SPEED = value end)
    self:createFlySlider("Velocidad Vertical", CONFIG.VERTICAL_SPEED, 10, 100, flyConfigPanel, 100, function(value) CONFIG.VERTICAL_SPEED = value end)
    self:createFlySlider("Aceleración", CONFIG.ACCELERATION, 10, 200, flyConfigPanel, 135, function(value) CONFIG.ACCELERATION = value end)
    
    self.speedButton = self:createElement("TextButton", { 
        Text = "   ACTIVAR SPEED", 
        Font = Enum.Font.GothamBold, 
        TextSize = 16, 
        TextColor3 = Color3.fromRGB(255, 255, 255), 
        TextXAlignment = Enum.TextXAlignment.Left, 
        BackgroundColor3 = Color3.fromRGB(100, 50, 50), 
        Size = UDim2.new(1, -20, 0, 40), 
        Position = UDim2.new(0, 10, 0, 250), 
        Parent = playerContent 
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.speedButton})
    self:createElement("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = self.speedButton})
    local speedStatusIndicator = self:createElement("Frame", { Name = "SpeedStatus", BackgroundColor3 = Color3.fromRGB(150, 40, 40), Size = UDim2.new(0, 8, 0, 25), Position = UDim2.new(1, -15, 0.5, -12.5), Parent = self.speedButton })
    self:createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = speedStatusIndicator})
    table.insert(self.connections, self.speedButton.MouseButton1Click:Connect(function() self:toggleSpeed() end))
    
    local walkSpeedLabel = self:createElement("TextLabel", { Text = "Velocidad de Caminar: " .. CONFIG.WalkSpeed, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 300), Parent = playerContent })
    
    local walkSlider = self:createElement("Frame", {
        Name = "WalkSlider",
        BackgroundColor3 = Color3.fromRGB(70, 70, 80),
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 335),
        Parent = playerContent
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = walkSlider})
    
    local walkSliderButton = self:createElement("TextButton", {
        Name = "WalkSliderButton",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, (CONFIG.WalkSpeed - 10) / 90 * (walkSlider.AbsoluteSize.X - 20), 0, 0),
        BackgroundColor3 = Color3.fromRGB(200, 100, 50),
        Text = "",
        Parent = walkSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = walkSliderButton})

    local walkDragging = false
    
    local function updateWalkSlider(input)
        if not walkDragging then return end
        
        local sliderSize = walkSlider.AbsoluteSize.X
        local mousePos = input.Position.X
        local sliderPos = walkSlider.AbsolutePosition.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        local newSpeed = math.floor(percent * 90) + 10
        CONFIG.WalkSpeed = newSpeed
        walkSpeedLabel.Text = "Velocidad de Caminar: " .. CONFIG.WalkSpeed
        
        walkSliderButton.Position = UDim2.new(0, percent * (sliderSize - 20), 0, 0)
        
        if self.isSpeedActive then
            local character = self.player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = CONFIG.WalkSpeed
            end
        end
    end

    table.insert(self.connections, walkSliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            walkDragging = true
        end
    end))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateWalkSlider(input)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            walkDragging = false
        end
    end))
    
    table.insert(self.connections, walkSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            walkDragging = true
            updateWalkSlider(input)
        end
    end))
    
    local jumpPowerLabel = self:createElement("TextLabel", { Text = "Potencia de Salto: " .. CONFIG.JumpPower, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 370), Parent = playerContent })
    
    local jumpSlider = self:createElement("Frame", {
        Name = "JumpSlider",
        BackgroundColor3 = Color3.fromRGB(70, 70, 80),
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 405),
        Parent = playerContent
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = jumpSlider})
    
    local jumpSliderButton = self:createElement("TextButton", {
        Name = "JumpSliderButton",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, (CONFIG.JumpPower - 10) / 90 * (jumpSlider.AbsoluteSize.X - 20), 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 200, 50),
        Text = "",
        Parent = jumpSlider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = jumpSliderButton})

    local jumpDragging = false
    
    local function updateJumpSlider(input)
        if not jumpDragging then return end
        
        local sliderSize = jumpSlider.AbsoluteSize.X
        local mousePos = input.Position.X
        local sliderPos = jumpSlider.AbsolutePosition.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        local newPower = math.floor(percent * 90) + 10
        CONFIG.JumpPower = newPower
        jumpPowerLabel.Text = "Potencia de Salto: " .. CONFIG.JumpPower
        
        jumpSliderButton.Position = UDim2.new(0, percent * (sliderSize - 20), 0, 0)
        
        if self.isSpeedActive then
            local character = self.player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.JumpPower = CONFIG.JumpPower
            end
        end
    end

    table.insert(self.connections, jumpSliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            jumpDragging = true
        end
    end))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateJumpSlider(input)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            jumpDragging = false
        end
    end))
    
    table.insert(self.connections, jumpSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            jumpDragging = true
            updateJumpSlider(input)
        end
    end))
    
    self.dockIcon = self:createElement("ImageButton", { Name = "DockIcon", Image = "rbxassetid://3926305904", ImageRectOffset = Vector2.new(964, 324), ImageRectSize = Vector2.new(36, 36), Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, -25, 0.5, -25), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Visible = false, Parent = self.screenGui })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.dockIcon})
    
    self:makeDraggable(self.dockIcon)
    
    table.insert(self.connections, self.dockIcon.MouseButton1Click:Connect(function() self:toggleMinimize() end))
end

function KillAuraMine:createFlySlider(name, value, min, max, parent, yPos, callback)
    local label = self:createElement("TextLabel", {
        Text = name .. ": " .. value,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, yPos),
        Parent = parent
    })
    
    local slider = self:createElement("Frame", {
        Name = name .. "Slider",
        BackgroundColor3 = Color3.fromRGB(70, 70, 80),
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 0, yPos + 20),
        Parent = parent
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 2), Parent = slider})
    
    local sliderButton = self:createElement("TextButton", {
        Name = name .. "SliderButton",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((value - min) / (max - min), -6, 0, -4),
        BackgroundColor3 = Color3.fromRGB(50, 150, 200),
        Text = "",
        Parent = slider
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = sliderButton})
    
    local dragging = false
    
    local function updateSlider(input)
        if not dragging then return end
        
        local sliderSize = slider.AbsoluteSize.X
        local mousePos = input.Position.X
        local sliderPos = slider.AbsolutePosition.X
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        local newValue = math.floor(min + (max - min) * percent)
        label.Text = name .. ": " .. newValue
        sliderButton.Position = UDim2.new(percent, -6, 0, -4)
        
        if callback then
            callback(newValue)
        end
    end
    
    table.insert(self.connections, sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end))
    
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    
    table.insert(self.connections, slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end))
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

function KillAuraMine:loadOreList()
    for _, button in pairs(self.oreButtons) do
        if button then
            button:Destroy()
        end
    end
    self.oreButtons = {}
    
    local oresFolder = Workspace:FindFirstChild("Ores")
    if not oresFolder then
        self:showNotification("No se encontró la carpeta Ores")
        return
    end
    
    local oreTypes = {}
    
    for _, ore in ipairs(oresFolder:GetChildren()) do
        local oreName = ore.Name
        if oreName and not oreTypes[oreName] then
            oreTypes[oreName] = true
        end
    end
    
    local yOffset = 5
    for oreName, _ in pairs(oreTypes) do
        local oreButton = self:createElement("TextButton", { 
            Text = oreName, 
            Font = Enum.Font.Gotham, 
            TextSize = 14, 
            TextColor3 = Color3.fromRGB(255, 255, 255), 
            BackgroundColor3 = Color3.fromRGB(50, 50, 60), 
            Size = UDim2.new(1, -10, 0, 30), 
            Position = UDim2.new(0, 5, 0, yOffset), 
            Parent = self.oreListFrame 
        })
        self:createElement("UICorner", {CornerRadius = UDim.new(0, 5), Parent = oreButton})
        
        table.insert(self.connections, oreButton.MouseButton1Click:Connect(function()
            self:selectOreType(oreName)
        end))
        
        table.insert(self.oreButtons, oreButton)
        yOffset = yOffset + 35
    end
    
    self.oreListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function KillAuraMine:selectOreType(oreName)
    self.selectedOreType = oreName
    
    if self.selectedOreLabel then
        self.selectedOreLabel.Text = "Mineral seleccionado: " .. oreName
    end
    
    for _, button in pairs(self.oreButtons) do
        if button.Text == oreName then
            button.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        else
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
    end
    
    self:showNotification("Mineral seleccionado: " .. oreName)
end

function KillAuraMine:toggleOreSelection()
    self:showNotification("El menú de minerales está integrado en el panel derecho")
end

function KillAuraMine:makeDraggable(frame)
    local dragging = false; local dragStart, startPos
    table.insert(self.connections, frame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = frame.Position end end))
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
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
    
    local animalsFolder = Workspace:FindFirstChild("Animals")
    if not animalsFolder then
        return nearbyTargets
    end
    
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

function KillAuraMine:toggleAura()
    self.isAuraActive = not self.isAuraActive
    self.auraButton.Text = self.isAuraActive and "   DESACTIVAR AURA" or "   ACTIVAR AURA"
    self.auraButton.BackgroundColor3 = self.isAuraActive and Color3.fromRGB(80, 50, 50) or Color3.fromRGB(50, 50, 60)
    self.auraButton.Status.BackgroundColor3 = self.isAuraActive and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(150, 40, 40)
    self:showNotification("Kill Aura " .. (self.isAuraActive and "activado" or "desactivado"))
end

function KillAuraMine:toggleMode()
    if CONFIG.AttackMode == "Players" then
        CONFIG.AttackMode = "Animals"
        self.modeButton.Text = "   MODO: ANIMALES"
        self.modeButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
        self:showNotification("Modo de ataque cambiado a Animales")
    elseif CONFIG.AttackMode == "Animals" then
        CONFIG.AttackMode = "Trees"
        self.modeButton.Text = "   MODO: ÁRBOLES"
        self.modeButton.BackgroundColor3 = Color3.fromRGB(50, 100, 100)
        self:showNotification("Modo de ataque cambiado a Árboles")
    else
        CONFIG.AttackMode = "Players"
        self.modeButton.Text = "   MODO: JUGADORES"
        self.modeButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
        self:showNotification("Modo de ataque cambiado a Jugadores")
    end
end

function KillAuraMine:toggleFly()
    self.isFlying = not self.isFlying
    self.flyButton.Text = self.isFlying and "   DESACTIVAR FLY" or "   ACTIVAR FLY"
    self.flyButton.BackgroundColor3 = self.isFlying and Color3.fromRGB(80, 50, 100) or Color3.fromRGB(50, 50, 100)
    self.flyButton.FlyStatus.BackgroundColor3 = self.isFlying and Color3.fromRGB(40, 150, 200) or Color3.fromRGB(150, 40, 40)
    
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
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Parent = self.screenGui
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.flyStatusFrame})
    
    local statusLabel = self:createElement("TextLabel", {
        Name = "StatusLabel",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 5),
        Text = "VUELO ACTIVADO",
        TextColor3 = Color3.fromRGB(80, 255, 150),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        BackgroundTransparency = 1,
        Parent = self.flyStatusFrame
    })
    
    local altitudeLabel = self:createElement("TextLabel", {
        Name = "AltitudeLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 30),
        Text = "ALTITUD: 0 u",
        TextColor3 = Color3.fromRGB(180, 220, 255),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        BackgroundTransparency = 1,
        Parent = self.flyStatusFrame
    })
    
    local speedBarFrame = self:createElement("Frame", {
        Size = UDim2.new(0.8, 0, 0, 8),
        Position = UDim2.new(0.1, 0, 0.55, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Parent = self.flyStatusFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = speedBarFrame})
    
    local speedFill = self:createElement("Frame", {
        Name = "SpeedFill",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 255, 150),
        BorderSizePixel = 0,
        Parent = speedBarFrame
    })
    self:createElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = speedFill})
    
    local noClipLabel = self:createElement("TextLabel", {
        Name = "NoClipLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0.75, 0),
        Text = "NO-CLIP: OFF",
        TextColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Gotham,
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
            noClipLabel.TextColor3 = enabled and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(150, 150, 150)
        end
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
    self.speedButton.Text = self.isSpeedActive and "   DESACTIVAR SPEED" or "   ACTIVAR SPEED"
    self.speedButton.BackgroundColor3 = self.isSpeedActive and Color3.fromRGB(50, 120, 50) or Color3.fromRGB(100, 50, 50)
    self.speedButton.SpeedStatus.BackgroundColor3 = self.isSpeedActive and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(150, 40, 40)
    
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

function KillAuraMine:toggleAutoCollect()
    self.isAutoCollecting = not self.isAutoCollecting
    self.autoCollectButton.Text = self.isAutoCollecting and "   DETENER AUTO RECOLECTAR" or "   AUTO RECOLECTAR"
    self.autoCollectButton.BackgroundColor3 = self.isAutoCollecting and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(50, 50, 150)
    self.autoCollectButton.AutoCollectStatus.BackgroundColor3 = self.isAutoCollecting and Color3.fromRGB(40, 150, 200) or Color3.fromRGB(150, 40, 40)
    
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

function KillAuraMine:farmNextSecret()
    if not self.isFarmingSecrets then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:showNotification("Personaje no encontrado. Reintentando en 5 segundos...")
        task.wait(5)
        self:farmNextSecret()
        return
    end
    
    local secretsFolder = Workspace:FindFirstChild("Secrets")
    if not secretsFolder or #secretsFolder:GetChildren() == 0 then
        self:showNotification("No se encontraron secretos. Reintentando en 10 segundos...")
        task.wait(10)
        self:farmNextSecret()
        return
    end

    local myPosition = character.HumanoidRootPart.Position
    local closestSecret = nil
    local closestDistance = math.huge
    
    for _, secret in ipairs(secretsFolder:GetChildren()) do
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
        character.HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(2, 5, 0))
        self:showNotification("Teletransportado a un secreto. Esperando 3 segundos...")
        task.wait(3)
        
        self:showNotification("Iniciando minado del secreto...")
        local mineTimeout = 20
        local startTime = tick()
        
        while closestSecret.Parent == secretsFolder and tick() - startTime < mineTimeout and self.isFarmingSecrets do
            if closestSecret and closestSecret.PrimaryPart then
                CONFIG.RemoteEvent:FireServer(closestSecret)
            end
            task.wait(0.5)
        end
        
        if closestSecret.Parent ~= secretsFolder then
            self:showNotification("Secreto destruido. Esperando 6 segundos...")
            task.wait(6)
            
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

function KillAuraMine:farmNextOre()
    if not self.isFarmingOres then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:showNotification("Personaje no encontrado. Reintentando en 5 segundos...")
        task.wait(5)
        self:farmNextOre()
        return
    end
    
    local oresFolder = Workspace:FindFirstChild("Ores")
    if not oresFolder then
        self:showNotification("No se encontró la carpeta Ores. Reintentando en 10 segundos...")
        task.wait(10)
        self:farmNextOre()
        return
    end

    local targetOres = {}
    for _, ore in ipairs(oresFolder:GetChildren()) do
        if ore.Name == self.selectedOreType then
            table.insert(targetOres, ore)
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
        character.HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(2, 5, 0))
        self:showNotification("Teletransportado a " .. self.selectedOreType .. ". Esperando 3 segundos...")
        task.wait(3)
        
        self:showNotification("Iniciando minado de " .. self.selectedOreType .. "...")
        local mineTimeout = 20
        local startTime = tick()
        
        while closestOre.Parent == oresFolder and tick() - startTime < mineTimeout and self.isFarmingOres do
            if closestOre and closestOre.PrimaryPart then
                CONFIG.RemoteEvent:FireServer(closestOre)
            end
            task.wait(0.5)
        end
        
        if closestOre.Parent ~= oresFolder then
            self:showNotification("Mineral destruido. Esperando 4 segundos...")
            task.wait(4)
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
    self.farmSecretsButton.Text = self.isFarmingSecrets and "   DETENER FARM SECRETS" or "   FARM SECRETS"
    self.farmSecretsButton.BackgroundColor3 = self.isFarmingSecrets and Color3.fromRGB(100, 80, 50) or Color3.fromRGB(80, 60, 40)
    self.farmSecretsButton.FarmSecretsStatus.BackgroundColor3 = self.isFarmingSecrets and Color3.fromRGB(40, 150, 100) or Color3.fromRGB(150, 40, 40)
    
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

function KillAuraMine:switchTab(tabName)
    if self.currentTab == tabName then return end
    
    self.currentTab = tabName
    
    local modulesTab = self.mainFrame.TabsContainer.ModulesTab
    local playerTab = self.mainFrame.TabsContainer.PlayerTab
    local modulesContent = self.mainFrame.ContentContainer.ModulesContent
    local playerContent = self.mainFrame.ContentContainer.PlayerContent
    
    if tabName == "Modules" then
        modulesTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        playerTab.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        modulesContent.Visible = true
        playerContent.Visible = false
    else
        modulesTab.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        playerTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        modulesContent.Visible = false
        playerContent.Visible = true
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
        self.mainFrame.Position = self.lastPosition or UDim2.new(0.5, -225, 0.5, -210); 
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
    if self.screenGui then self.screenGui:Destroy() end
    self = nil
end

local killAuraMineMenu = KillAuraMine.new()
