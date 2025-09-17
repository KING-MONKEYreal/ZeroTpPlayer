local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Remove old GUI safely
if game.CoreGui:FindFirstChild("ZeroTPPlayerGUI") then
    pcall(function() game.CoreGui.ZeroTPPlayerGUI:Destroy() end)
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZeroTPPlayerGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame (responsive for mobile)
local Frame = Instance.new("Frame")
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
if UserInput.TouchEnabled then
    Frame.Size = UDim2.new(0.96, 0, 0.92, 0)
else
    Frame.Size = UDim2.new(0, 420, 0, 560)
end
Frame.BackgroundColor3 = Color3.fromRGB(22,22,26)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,14)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = Frame
TitleBar.Size = UDim2.new(1,0,0,44)
TitleBar.BackgroundColor3 = Color3.fromRGB(34,34,40)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,14)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TitleBar
TitleLabel.Size = UDim2.new(1,-220,1,0)
TitleLabel.Position = UDim2.new(0,12,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Zero TP Player v5.0"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local ControlsLabel = Instance.new("TextLabel")
ControlsLabel.Parent = TitleBar
ControlsLabel.Size = UDim2.new(0,200,1,0)
ControlsLabel.Position = UDim2.new(1,-220,0,0)
ControlsLabel.BackgroundTransparency = 1
ControlsLabel.Text = "Hotkeys: T TP · R Follow · Y Spectate · F Stop"
ControlsLabel.Font = Enum.Font.Gotham
ControlsLabel.TextSize = 12
ControlsLabel.TextColor3 = Color3.fromRGB(200,200,200)
ControlsLabel.TextXAlignment = Enum.TextXAlignment.Right

local StopAllBtn = Instance.new("TextButton")
StopAllBtn.Parent = TitleBar
StopAllBtn.Size = UDim2.new(0,88,1,0)
StopAllBtn.Position = UDim2.new(1,-104,0,0)
StopAllBtn.BackgroundTransparency = 1
StopAllBtn.Text = "Stop All"
StopAllBtn.Font = Enum.Font.GothamBold
StopAllBtn.TextSize = 14
StopAllBtn.TextColor3 = Color3.fromRGB(255,180,80)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Size = UDim2.new(0,36,1,0)
CloseBtn.Position = UDim2.new(1,-40,0,0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.TextColor3 = Color3.fromRGB(255,80,80)
CloseBtn.MouseButton1Click:Connect(function() pcall(function() ScreenGui:Destroy() end) end)

-- Search & Controls area
local TopArea = Instance.new("Frame", Frame)
TopArea.Size = UDim2.new(1,-24,0,84)
TopArea.Position = UDim2.new(0,12,0,54)
TopArea.BackgroundTransparency = 1

local SearchBar = Instance.new("TextBox")
SearchBar.Parent = TopArea
SearchBar.Size = UDim2.new(0.62, 0, 0, 36)
SearchBar.Position = UDim2.new(0,0,0,0)
SearchBar.BackgroundColor3 = Color3.fromRGB(48,48,60)
SearchBar.TextColor3 = Color3.new(1,1,1)
SearchBar.PlaceholderText = "🔍 Search player..."
SearchBar.Font = Enum.Font.Gotham
SearchBar.TextSize = 14
SearchBar.ClearTextOnFocus = false
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0,8)

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Parent = TopArea
SelectedLabel.Size = UDim2.new(0.38, -10, 0, 36)
SelectedLabel.Position = UDim2.new(0.62, 10, 0, 0)
SelectedLabel.BackgroundColor3 = Color3.fromRGB(45,45,55)
SelectedLabel.TextColor3 = Color3.fromRGB(220,220,220)
SelectedLabel.Text = "Selected: none"
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.TextSize = 13
Instance.new("UICorner", SelectedLabel).CornerRadius = UDim.new(0,8)

-- Teleport controls (random, spawn, coords)
local TeleportArea = Instance.new("Frame", Frame)
TeleportArea.Size = UDim2.new(1,-24,0,72)
TeleportArea.Position = UDim2.new(0,12,0,148)
TeleportArea.BackgroundTransparency = 1

local TPSelectedBtn = Instance.new("TextButton", TeleportArea)
TPSelectedBtn.Size = UDim2.new(0,120,0,36)
TPSelectedBtn.Position = UDim2.new(0,0,0,0)
TPSelectedBtn.BackgroundColor3 = Color3.fromRGB(0,150,80)
TPSelectedBtn.Text = "TP Selected"
TPSelectedBtn.Font = Enum.Font.GothamBold
TPSelectedBtn.TextSize = 14
TPSelectedBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TPSelectedBtn).CornerRadius = UDim.new(0,8)

local TPRandomBtn = Instance.new("TextButton", TeleportArea)
TPRandomBtn.Size = UDim2.new(0,120,0,36)
TPRandomBtn.Position = UDim2.new(0,132,0,0)
TPRandomBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
TPRandomBtn.Text = "TP Random"
TPRandomBtn.Font = Enum.Font.GothamBold
TPRandomBtn.TextSize = 14
TPRandomBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TPRandomBtn).CornerRadius = UDim.new(0,8)

local TPSpawnBtn = Instance.new("TextButton", TeleportArea)
TPSpawnBtn.Size = UDim2.new(0,140,0,36)
TPSpawnBtn.Position = UDim2.new(0,264,0,0)
TPSpawnBtn.BackgroundColor3 = Color3.fromRGB(180,140,0)
TPSpawnBtn.Text = "TP to Spawn"
TPSpawnBtn.Font = Enum.Font.GothamBold
TPSpawnBtn.TextSize = 14
TPSpawnBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TPSpawnBtn).CornerRadius = UDim.new(0,8)

-- Custom coordinate inputs
local CoordArea = Instance.new("Frame", Frame)
CoordArea.Size = UDim2.new(1,-24,0,48)
CoordArea.Position = UDim2.new(0,12,0,230)
CoordArea.BackgroundTransparency = 1

local XBox = Instance.new("TextBox", CoordArea)
XBox.Size = UDim2.new(0,120,1,0)
XBox.Position = UDim2.new(0,0,0,0)
XBox.PlaceholderText = "X"
XBox.ClearTextOnFocus = false
XBox.Font = Enum.Font.Gotham
XBox.TextSize = 14
Instance.new("UICorner", XBox).CornerRadius = UDim.new(0,6)
XBox.BackgroundColor3 = Color3.fromRGB(48,48,60)

local YBox = XBox:Clone()
YBox.Parent = CoordArea
YBox.Position = UDim2.new(0,132,0,0)
YBox.PlaceholderText = "Y"

local ZBox = XBox:Clone()
ZBox.Parent = CoordArea
ZBox.Position = UDim2.new(0,264,0,0)
ZBox.PlaceholderText = "Z"

local TPCoordsBtn = Instance.new("TextButton", CoordArea)
TPCoordsBtn.Size = UDim2.new(0,120,1,0)
TPCoordsBtn.Position = UDim2.new(0,396,0,0)
TPCoordsBtn.BackgroundColor3 = Color3.fromRGB(50,120,50)
TPCoordsBtn.Text = "TP → Coords"
TPCoordsBtn.Font = Enum.Font.GothamBold
TPCoordsBtn.TextSize = 14
TPCoordsBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TPCoordsBtn).CornerRadius = UDim.new(0,6)

-- Player List container
local PlayerList = Instance.new("ScrollingFrame", Frame)
PlayerList.Size = UDim2.new(1,-24,1,-320)
PlayerList.Position = UDim2.new(0,12,0,290)
PlayerList.BackgroundTransparency = 1
PlayerList.CanvasSize = UDim2.new(0,0,0,0)
PlayerList.ScrollBarThickness = 8
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(180,180,180)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", PlayerList)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0,8)

local function updateCanvas()
    local absSize = ListLayout.AbsoluteContentSize
    PlayerList.CanvasSize = UDim2.new(0,0,0, absSize + 12)
end
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

-- Modes & state
local SelectedPlayer = nil
local FollowingPlayer, SpectatingPlayer
local FollowConn, SpectateConn
local actionDebounce = {}
local massTrollEnabled = false
local whitelist = {} -- keys are userId -> true

local function isWhitelisted(plr)
    if not plr then return false end
    return whitelist[plr.UserId] == true
end

local function canAct(key, cooldown)
    cooldown = cooldown or 1
    if actionDebounce[key] and tick() - actionDebounce[key] < cooldown then
        return false
    end
    actionDebounce[key] = tick()
    return true
end

local function StopAllModes()
    SelectedPlayer = SelectedPlayer
    FollowingPlayer = nil
    if FollowConn then pcall(function() FollowConn:Disconnect() end) FollowConn = nil end
    SpectatingPlayer = nil
    if SpectateConn then pcall(function() SpectateConn:Disconnect() end) SpectateConn = nil end
    if LocalPlayer and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() Camera.CameraSubject = hum end) end
    end
end

local function SafeTPtoPos(pos)
    if not pos or not LocalPlayer or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
    end)
end

local function SafeTPToPlayer(plr)
    if not plr then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end)
    end
end

local function StartFollowing(plr)
    StopAllModes()
    if not plr then return end
    FollowingPlayer = plr
    FollowConn = RunService.Heartbeat:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            StopAllModes()
            return
        end
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end)
    end)
end

local function StartSpectating(plr)
    StopAllModes()
    if not plr then return end
    SpectatingPlayer = plr
    SpectateConn = RunService.RenderStepped:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")) then
            StopAllModes()
            return
        end
        pcall(function()
            Camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
        end)
    end)
end

-- Troll functions with debounces (MassTroll will skip whitelisted players)
local function FlingPlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("fling_"..plr.UserId, 0.6) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local part = plr.Character.HumanoidRootPart
            part.Velocity = Vector3.new(math.random(-250,250),150,math.random(-250,250))
            part.RotVelocity = Vector3.new(math.random(-120,120),math.random(-120,120),math.random(-120,120))
        end)
    end
end

local function SpinPlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("spin_"..plr.UserId, 1.2) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        coroutine.wrap(function()
            local part = plr.Character.HumanoidRootPart
            for i=1,48 do
                if not part.Parent then break end
                pcall(function()
                    part.CFrame = part.CFrame * CFrame.Angles(0,math.rad(30),0)
                end)
                task.wait(0.04)
            end
        end)()
    end
end

local function ExplodePlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("explode_"..plr.UserId, 2.5) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local explosion = Instance.new("Explosion")
            explosion.Position = plr.Character.HumanoidRootPart.Position
            explosion.BlastRadius = 6
            explosion.BlastPressure = 500000
            explosion.Parent = workspace
        end)
    end
end

local function TrollPlayer(plr)
    if not plr then return end
    pcall(function()
        FlingPlayer(plr)
        SpinPlayer(plr)
        ExplodePlayer(plr)
    end)
end

local function MassTroll()
    if not massTrollEnabled then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not isWhitelisted(plr) then
            TrollPlayer(plr)
            task.wait(0.12)
        end
    end
end

-- UI: Create Player Entry
local function AddPlayerEntry(plr)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1,0,0,82)
    Entry.BackgroundColor3 = Color3.fromRGB(38,38,46)
    Entry.LayoutOrder = plr.UserId
    Instance.new("UICorner", Entry).CornerRadius = UDim.new(0,8)
    Entry.Parent = PlayerList

    Entry.BackgroundTransparency = 1
    TweenService:Create(Entry, TweenInfo.new(0.18), {BackgroundTransparency=0}):Play()

    local Avatar = Instance.new("ImageLabel")
    Avatar.Parent = Entry
    Avatar.Size = UDim2.new(0,56,0,56)
    Avatar.Position = UDim2.new(0,10,0.5,-28)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = ""
    Avatar.Name = "Avatar"
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0,8)

    spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and thumb and typeof(thumb) == "string" then
            pcall(function() Avatar.Image = thumb end)
        end
    end)

    local Name = Instance.new("TextLabel", Entry)
    Name.Size = UDim2.new(1,-220,0,20)
    Name.Position = UDim2.new(0,76,0,8)
    Name.BackgroundTransparency = 1
    Name.Text = "@"..tostring(plr.Name)
    Name.TextColor3 = Color3.new(1,1,1)
    Name.Font = Enum.Font.GothamBold
    Name.TextSize = 14
    Name.TextXAlignment = Enum.TextXAlignment.Left

    local Display = Instance.new("TextLabel", Entry)
    Display.Size = UDim2.new(1,-220,0,18)
    Display.Position = UDim2.new(0,76,0,30)
    Display.BackgroundTransparency = 1
    Display.Text = tostring(plr.DisplayName or "")
    Display.TextColor3 = Color3.fromRGB(190,190,190)
    Display.Font = Enum.Font.Gotham
    Display.TextSize = 13
    Display.TextXAlignment = Enum.TextXAlignment.Left

    local btnContainer = Instance.new("Frame", Entry)
    btnContainer.Size = UDim2.new(0,300,1,0)
    btnContainer.Position = UDim2.new(1,-312,0,0)
    btnContainer.BackgroundTransparency = 1

    local function makeButton(text, posX, width, color)
        local btn = Instance.new("TextButton")
        btn.Parent = btnContainer
        btn.Size = UDim2.new(0,width,0,30)
        btn.Position = UDim2.new(0,posX,0,26)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        return btn
    end

    local TP = makeButton("TP", 0, 50, Color3.fromRGB(0,150,80))
    TP.MouseButton1Click:Connect(function()
        StopAllModes()
        SelectedPlayer = plr
        SelectedLabel.Text = "Selected: @"..plr.Name
        SafeTPToPlayer(plr)
    end)

    local Follow = makeButton("Follow", 62, 66, Color3.fromRGB(0,110,200))
    Follow.MouseButton1Click:Connect(function()
        if FollowingPlayer == plr then
            StopAllModes()
        else
            SelectedPlayer = plr
            SelectedLabel.Text = "Selected: @"..plr.Name
            StartFollowing(plr)
        end
    end)

    local Spec = makeButton("Spectate", 136, 74, Color3.fromRGB(200,150,0))
    Spec.MouseButton1Click:Connect(function()
        if SpectatingPlayer == plr then
            StopAllModes()
        else
            SelectedPlayer = plr
            SelectedLabel.Text = "Selected: @"..plr.Name
            StartSpectating(plr)
        end
    end)

    local TrollBtn = makeButton("Troll", 216, 66, Color3.fromRGB(220,60,60))
    TrollBtn.MouseButton1Click:Connect(function()
        TrollPlayer(plr)
    end)

    local IgnoreBtn = makeButton("Ignore", 288, 66, Color3.fromRGB(100,100,110))
    local function updateIgnoreButton()
        if whitelist[plr.UserId] then
            IgnoreBtn.Text = "Whitelist ✓"
            IgnoreBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
        else
            IgnoreBtn.Text = "Whitelist"
            IgnoreBtn.BackgroundColor3 = Color3.fromRGB(100,100,110)
        end
    end
    updateIgnoreButton()
    IgnoreBtn.MouseButton1Click:Connect(function()
        whitelist[plr.UserId] = not whitelist[plr.UserId]
        updateIgnoreButton()
    end)

    -- entry click selects player
    Entry.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            SelectedPlayer = plr
            SelectedLabel.Text = "Selected: @"..plr.Name
        end
    end)
end

-- Refresh Player List
local function RefreshList()
    for _,child in ipairs(PlayerList:GetChildren()) do
        if child ~= ListLayout and not child:IsA("UISizeConstraint") then
            pcall(function() child:Destroy() end)
        end
    end

    local text = (SearchBar.Text or ""):lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local nameMatch = false
            pcall(function()
                local n1 = tostring(plr.Name or ""):lower()
                local n2 = tostring(plr.DisplayName or ""):lower()
                if text == "" or n1:find(text) or n2:find(text) then
                    nameMatch = true
                end
            end)
            if nameMatch then
                AddPlayerEntry(plr)
            end
        end
    end
    updateCanvas()
end

-- Teleport buttons behavior
TPSelectedBtn.MouseButton1Click:Connect(function()
    if SelectedPlayer then
        StopAllModes()
        SafeTPToPlayer(SelectedPlayer)
    end
end)

TPRandomBtn.MouseButton1Click:Connect(function()
    local pool = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pool, p) end
    end
    if #pool == 0 then return end
    local target = pool[math.random(1,#pool)]
    StopAllModes()
    SelectedPlayer = target
    SelectedLabel.Text = "Selected: @"..target.Name
    SafeTPToPlayer(target)
end)

TPSpawnBtn.MouseButton1Click:Connect(function()
    -- try common spawn names, else use workspace:FindFirstChildWhichIsA(SpawnLocation)
    local pos = nil
    local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildWhichIsA(workspace.SpawnLocation and typeof(workspace.SpawnLocation) or nil) -- kept safe
    -- fallback: find any SpawnLocation instance
    if not spawn then
        for _,c in ipairs(workspace:GetChildren()) do
            if c:IsA("SpawnLocation") then spawn = c break end
        end
    end
    if spawn and spawn:IsA("BasePart") then pos = spawn.Position end
    if not pos then
        -- last resort: try to use LocalPlayer's team spawn
        local teamSpawn = workspace:FindFirstChild(LocalPlayer.Team and tostring(LocalPlayer.Team.Name) or "")
        if teamSpawn and teamSpawn:IsA("BasePart") then pos = teamSpawn.Position end
    end
    if pos then SafeTPtoPos(pos) end
end)

TPCoordsBtn.MouseButton1Click:Connect(function()
    local x = tonumber(XBox.Text)
    local y = tonumber(YBox.Text)
    local z = tonumber(ZBox.Text)
    if x and y and z then
        StopAllModes()
        SafeTPtoPos(Vector3.new(x,y,z))
    else
        -- small visual feedback: flash boxes
        for _,b in ipairs({XBox,YBox,ZBox}) do
            local orig = b.BackgroundColor3
            spawn(function()
                b.BackgroundColor3 = Color3.fromRGB(160,60,60)
                task.wait(0.25)
                b.BackgroundColor3 = orig
            end)
        end
    end
end)

-- Hotkeys
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.T then -- TP to selected
            if SelectedPlayer then StopAllModes() SafeTPToPlayer(SelectedPlayer) end
        elseif key == Enum.KeyCode.R then -- toggle follow
            if SelectedPlayer then
                if FollowingPlayer == SelectedPlayer then StopAllModes() else StartFollowing(SelectedPlayer) end
            end
        elseif key == Enum.KeyCode.Y then -- toggle spectate
            if SelectedPlayer then
                if SpectatingPlayer == SelectedPlayer then StopAllModes() else StartSpectating(SelectedPlayer) end
            end
        elseif key == Enum.KeyCode.F then
            StopAllModes()
        end
    end
end)

-- Connections
SearchBar:GetPropertyChangedSignal("Text"):Connect(RefreshList)
Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)

-- Auto refresh loop
local refreshRunning = true
task.spawn(function()
    while refreshRunning do
        task.wait(2.5)
        pcall(RefreshList)
    end
end)

-- StopAll button
StopAllBtn.MouseButton1Click:Connect(function()
    StopAllModes()
end)

-- Footer: MassTroll controls
local footer = Instance.new("Frame", Frame)
footer.Size = UDim2.new(1,-24,0,46)
footer.Position = UDim2.new(0,12,1,-60)
footer.BackgroundTransparency = 1

local MassToggle = Instance.new("TextButton", footer)
MassToggle.Size = UDim2.new(0,160,1,0)
MassToggle.Position = UDim2.new(0,0,0,0)
MassToggle.BackgroundColor3 = Color3.fromRGB(120,120,130)
MassToggle.Text = "Enable MassTroll"
MassToggle.Font = Enum.Font.GothamBold
MassToggle.TextSize = 14
MassToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", MassToggle).CornerRadius = UDim.new(0,8)

local MassAction = Instance.new("TextButton", footer)
MassAction.Size = UDim2.new(0,160,1,0)
MassAction.Position = UDim2.new(0,176,0,0)
MassAction.BackgroundColor3 = Color3.fromRGB(200,50,50)
MassAction.Text = "Mass Troll Now"
MassAction.Font = Enum.Font.GothamBold
MassAction.TextSize = 14
MassAction.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", MassAction).CornerRadius = UDim.new(0,8)

MassToggle.MouseButton1Click:Connect(function()
    massTrollEnabled = not massTrollEnabled
    if massTrollEnabled then
        MassToggle.Text = "MassTroll ✅"
        MassToggle.BackgroundColor3 = Color3.fromRGB(0,150,0)
    else
        MassToggle.Text = "Enable MassTroll"
        MassToggle.BackgroundColor3 = Color3.fromRGB(120,120,130)
    end
end)

MassAction.MouseButton1Click:Connect(function()
    if not massTrollEnabled then
        MassToggle.Text = "Enable MassTroll (confirm)"
        MassToggle.BackgroundColor3 = Color3.fromRGB(200,160,0)
        return
    end
    task.spawn(function()
        pcall(MassTroll)
    end)
end)

-- Initial populate
RefreshList()

-- Cleanup
local function onDestroy()
    refreshRunning = false
    StopAllModes()
end
ScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then onDestroy() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer then onDestroy() end
end)

wait("5")
print("Updated to new version if you paid for this you got scammed")
wait("3")
print("update done")