-- Zero TP Player v5.0
-- Complete rewrite: Tabs (Players / Teleport / Troll / Settings), UI themes, hotkeys,
-- fixes for debounces, thumbnail retry, safe pcall wrappers, improved mass actions,
-- whitelist (ignore), bring/fling/spin/loop options, UI animations, and config save/load.

-- NOTES:
-- * Config save/load uses writefile/readfile if available in your executor (pcall-wrapped).
-- * Uses os.clock() for debounces.
-- * Designed to be mobile-friendly (bigger touch targets if touch enabled).
-- * If you want additional persistence or executor-specific features (like syn.request), tell me which executor and I'll adapt.

-------------------------
-- Services & utilities
-------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = workspace

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TOUCH = UserInput.TouchEnabled
local function now() return os.clock() end

local DEBOUNCE = {}
local function canAct(k, cd)
    cd = cd or 1
    if DEBOUNCE[k] and now() - DEBOUNCE[k] < cd then return false end
    DEBOUNCE[k] = now()
    return true
end

local function safePcall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

-- safe destroy old GUI
pcall(function()
    local old = CoreGui:FindFirstChild("ZeroTPPlayerGUI_v5")
    if old then old:Destroy() end
end)

-------------------------
-- Config (save/load)
-------------------------
local CONFIG_FILE = "zero_tp_player_v5_config.json"
local config = {
    theme = "dark",            -- "dark" or "light"
    massTrollEnabled = false,
    whitelist = {},            -- userId->true
    hotkeys = { t="TP", r="Follow", y="Spectate", g="Bring", f="Stop" }
}
-- try load
do
    local ok, content = pcall(function() return readfile and readfile(CONFIG_FILE) end)
    if ok and content then
        local decodeOk, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
        if decodeOk and type(decoded) == "table" then
            for k,v in pairs(decoded) do config[k] = v end
        end
    end
end
local function saveConfig()
    pcall(function()
        if writefile and game:GetService("HttpService") then
            writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(config))
        end
    end)
end

-------------------------
-- UI Helpers
-------------------------
local function mk(parent, class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function tween(obj, props, t)
    tween = TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local BUTTON_H = TOUCH and 44 or 34
local CORNER = TOUCH and 10 or 6
local PAD = 12

-------------------------
-- Root GUI layout
-------------------------
local ScreenGui = mk(nil, "ScreenGui", {Name="ZeroTPPlayerGUI_v5", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
ScreenGui.Parent = CoreGui

local Main = mk(ScreenGui, "Frame", {
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.new(0.5,0,0.5,0),
    Size = TOUCH and UDim2.new(0.96,0,0.92,0) or UDim2.new(0,820,0,540),
    BackgroundColor3 = Color3.fromRGB(22,22,26),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
})
mk(Main, "UICorner", {CornerRadius = UDim.new(0,14)})

-- left tabs column
local Tabs = mk(Main, "Frame", {
    Size = UDim2.new(0,180,1,-PAD*2),
    Position = UDim2.new(0, PAD, 0, PAD),
    BackgroundTransparency = 1
})

-- content area
local Content = mk(Main, "Frame", {
    Size = UDim2.new(1,-(180+PAD*3), 1,-PAD*2),
    Position = UDim2.new(0, 180+PAD*2, 0, PAD),
    BackgroundTransparency = 1
})

-- Title Bar
local TitleBar = mk(Main, "Frame", {
    Size = UDim2.new(1, -PAD*2, 0, 48),
    Position = UDim2.new(0, PAD, 0, PAD),
    BackgroundTransparency = 1,
})
local TitleLabel = mk(TitleBar, "TextLabel", {
    Size = UDim2.new(0.6,0,1,0),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255,255,255),
    Text = "Zero TP Player v5.0",
    TextXAlignment = Enum.TextXAlignment.Left
})
local HotkeysLabel = mk(TitleBar, "TextLabel", {
    Size = UDim2.new(0.4, -40, 1,0),
    Position = UDim2.new(0.6, 8, 0,0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(200,200,200),
    Text = "Hotkeys: T TP · R Follow · Y Spectate · G Bring · F Stop",
    TextXAlignment = Enum.TextXAlignment.Right
})
local CloseBtn = mk(TitleBar, "TextButton", {
    Size = UDim2.new(0,36,0,36),
    Position = UDim2.new(1,-36,0,6),
    BackgroundTransparency = 1,
    Text = "✕",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255,100,100)
})
CloseBtn.MouseButton1Click:Connect(function() pcall(function() ScreenGui:Destroy() end) end)

-- styles based off theme
local function themeColor(name)
    if config.theme == "light" then
        local t = {
            bg = Color3.fromRGB(240,240,245),
            panel = Color3.fromRGB(230,230,235),
            text = Color3.fromRGB(20,20,26),
            accent = Color3.fromRGB(40,120,255)
        }
        return t[name]
    else
        local t = {
            bg = Color3.fromRGB(22,22,26),
            panel = Color3.fromRGB(34,34,40),
            text = Color3.fromRGB(240,240,245),
            accent = Color3.fromRGB(0,150,255)
        }
        return t[name]
    end
end

Main.BackgroundColor3 = themeColor("bg")
TitleLabel.TextColor3 = themeColor("text")
HotkeysLabel.TextColor3 = themeColor("text")
CloseBtn.TextColor3 = themeColor("accent")

-------------------------
-- Tab buttons
-------------------------
local tabNames = {"Players","Teleport","Troll","Settings"}
local tabButtons = {}
local currentTab = "Players"

local tabFrame = mk(Tabs, "Frame", {Size=UDim2.new(1,0,0,200), BackgroundTransparency=1})
local function mkTabButton(name, y)
    local b = mk(tabFrame, "TextButton", {
        Size = UDim2.new(1,0,0,44),
        Position = UDim2.new(0,0,0, (y-1) * 48),
        BackgroundColor3 = themeColor("panel"),
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = themeColor("text")
    })
    mk(b, "UICorner", {CornerRadius = UDim.new(0,8)})
    return b
end

for i,name in ipairs(tabNames) do
    local b = mkTabButton(name, i)
    tabButtons[name] = b
end

local function setTab(name)
    currentTab = name
    for n,btn in pairs(tabButtons) do
        if n == name then
            btn.BackgroundColor3 = themeColor("accent")
            btn.TextColor3 = themeColor("bg")
        else
            btn.BackgroundColor3 = themeColor("panel")
            btn.TextColor3 = themeColor("text")
        end
    end
    -- show/hide content frames below
    PlayersFrame.Visible = (name == "Players")
    TeleportFrame.Visible = (name == "Teleport")
    TrollFrame.Visible = (name == "Troll")
    SettingsFrame.Visible = (name == "Settings")
end

for n,btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() setTab(n) end)
end

-------------------------
-- PLAYERS TAB
-------------------------
local PlayersFrame = mk(Content, "Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
PlayersFrame.Visible = true

-- Search bar + selected label
local searchBox = mk(PlayersFrame, "TextBox", {
    Size = UDim2.new(0.6,0,0,36), Position = UDim2.new(0,0,0,0),
    PlaceholderText = "🔍 Search player...", Font = Enum.Font.Gotham, TextSize = 14,
    BackgroundColor3 = themeColor("panel"), TextColor3 = themeColor("text"), ClearTextOnFocus=false
})
mk(searchBox, "UICorner", {CornerRadius = UDim.new(0,8)})

local selectedLabel = mk(PlayersFrame, "TextLabel", {
    Size = UDim2.new(0.4, -8, 0, 36), Position = UDim2.new(0.6,8,0,0),
    BackgroundColor3 = themeColor("panel"), TextColor3 = themeColor("text"),
    Font = Enum.Font.Gotham, TextSize = 13, Text = "Selected: none"
})
mk(selectedLabel, "UICorner", {CornerRadius = UDim.new(0,8)})

-- Player list container and layout
local playerList = mk(PlayersFrame, "ScrollingFrame", {
    Size = UDim2.new(1,0,1,-64), Position = UDim2.new(0,0,0,56), BackgroundTransparency=1,
    ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y
})
local playersLayout = mk(playerList, "UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
playersLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() playerList.CanvasSize = UDim2.new(0,0,0, playersLayout.AbsoluteContentSize + 12) end)

-- state
local SelectedPlayer = nil
local FollowingPlayer, SpectatingPlayer = nil, nil
local FollowConn, SpectateConn = nil, nil

-- helper to check whitelist
local function isWhitelisted(plr) return plr and config.whitelist and config.whitelist[tostring(plr.UserId)] end

-- add player entry
local function AddPlayerEntry(plr)
    if not plr then return end
    local Entry = mk(playerList, "Frame", {Size = UDim2.new(1,0,0,86), BackgroundColor3 = themeColor("panel")})
    mk(Entry, "UICorner", {CornerRadius = UDim.new(0,8)})
    Entry.LayoutOrder = plr.UserId

    -- avatar
    local avatar = mk(Entry, "ImageLabel", {Size = UDim2.new(0,64,0,64), Position = UDim2.new(0,8,0.5,-32), BackgroundTransparency=1})
    mk(avatar, "UICorner", {CornerRadius = UDim.new(0,8)})
    -- thumbnail retry
    spawn(function()
        for i=1,3 do
            local ok, thumb = pcall(function() return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and thumb and typeof(thumb) == "string" then
                pcall(function() avatar.Image = thumb end)
                break
            end
            task.wait(0.18)
        end
    end)

    -- labels
    mk(Entry, "TextLabel", {
        Size = UDim2.new(1,-220,0,20), Position = UDim2.new(0,80,0,8),
        BackgroundTransparency=1, Text="@"..tostring(plr.Name), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=themeColor("text"), TextXAlignment=Enum.TextXAlignment.Left
    })
    mk(Entry, "TextLabel", {
        Size = UDim2.new(1,-220,0,18), Position = UDim2.new(0,80,0,32),
        BackgroundTransparency=1, Text=tostring(plr.DisplayName or ""), Font=Enum.Font.Gotham, TextSize=13, TextColor3=Color3.fromRGB(180,180,180), TextXAlignment=Enum.TextXAlignment.Left
    })

    -- buttons container
    local btns = mk(Entry, "Frame", {Size = UDim2.new(0,420,1,0), Position = UDim2.new(1,-428,0,0), BackgroundTransparency=1})
    local function btn(text, x, w, color)
        local b = mk(btns, "TextButton", {Size=UDim2.new(0,w,0,BUTTON_H), Position=UDim2.new(0,x,0,(86-BUTTON_H)/2), BackgroundColor3=color, Text=text, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=themeColor("bg")})
        mk(b, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
        return b
    end

    local TPbtn = btn("TP", 0, 56, Color3.fromRGB(0,160,100))
    local FollowBtn = btn("Follow", 66, 70, Color3.fromRGB(0,110,200))
    local SpecBtn = btn("Spectate", 148, 84, Color3.fromRGB(200,150,0))
    local TrollBtn = btn("Troll", 236, 72, Color3.fromRGB(220,60,60))
    local BringBtn = btn("Bring", 318, 64, Color3.fromRGB(160,100,220))
    local WLbtn = btn("Whitelist", 390, 78, isWhitelisted(plr) and Color3.fromRGB(20,160,80) or Color3.fromRGB(100,100,110))

    local function updateWL()
        if isWhitelisted(plr) then WLbtn.Text = "Whitelist ✓" WLbtn.BackgroundColor3 = Color3.fromRGB(20,160,80) else WLbtn.Text = "Whitelist" WLbtn.BackgroundColor3 = Color3.fromRGB(100,100,110) end
    end
    WLbtn.MouseButton1Click:Connect(function()
        config.whitelist[tostring(plr.UserId)] = not config.whitelist[tostring(plr.UserId)]
        updateWL()
        saveConfig()
    end)

    TPbtn.MouseButton1Click:Connect(function()
        stopAllModes()
        SelectedPlayer = plr
        selectedLabel.Text = "Selected: @"..plr.Name
        safeTPToPlayer(plr)
    end)
    FollowBtn.MouseButton1Click:Connect(function()
        SelectedPlayer = plr
        selectedLabel.Text = "Selected: @"..plr.Name
        if FollowingPlayer == plr then stopAllModes() else startFollowing(plr) end
    end)
    SpecBtn.MouseButton1Click:Connect(function()
        SelectedPlayer = plr
        selectedLabel.Text = "Selected: @"..plr.Name
        if SpectatingPlayer == plr then stopAllModes() else startSpectating(plr) end
    end)
    TrollBtn.MouseButton1Click:Connect(function() trollPlayer(plr) end)
    BringBtn.MouseButton1Click:Connect(function() bringPlayer(plr) end)

    Entry.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            SelectedPlayer = plr
            selectedLabel.Text = "Selected: @"..plr.Name
        end
    end)
end

-- clear & refresh
local function RefreshPlayerList()
    for _,c in ipairs(playerList:GetChildren()) do
        if c ~= playersLayout then pcall(function() c:Destroy() end) end
    end
    local q = (searchBox.Text or ""):lower()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local ok, match = pcall(function()
                local n1 = tostring(plr.Name or ""):lower()
                local n2 = tostring(plr.DisplayName or ""):lower()
                return q == "" or n1:find(q) or n2:find(q)
            end)
            if ok and match then AddPlayerEntry(plr) end
        end
    end
end

-------------------------
-- TELEPORT TAB
-------------------------
local TeleportFrame = mk(Content, "Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
TeleportFrame.Visible = false

local selLabel = mk(TeleportFrame, "TextLabel", {Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=themeColor("text"), Text="Teleport Controls (Select a player from Players tab or use search)"})
local TPbuttons = mk(TeleportFrame, "Frame", {Size=UDim2.new(1,0,0,84), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1})
local TPsel = mk(TPbuttons, "TextButton", {Size=UDim2.new(0,180,0,BUTTON_H), Position=UDim2.new(0,0,0,0), Text="TP Selected", BackgroundColor3 = Color3.fromRGB(0,150,80), Font=Enum.Font.GothamBold, TextSize=14})
mk(TPsel, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local TPrand = mk(TPbuttons, "TextButton", {Size=UDim2.new(0,160,0,BUTTON_H), Position=UDim2.new(0,196,0,0), Text="TP Random", BackgroundColor3 = Color3.fromRGB(0,110,200), Font=Enum.Font.GothamBold, TextSize=14})
mk(TPrand, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local TPspawn = mk(TPbuttons, "TextButton", {Size=UDim2.new(0,160,0,BUTTON_H), Position=UDim2.new(0,368,0,0), Text="TP Spawn", BackgroundColor3 = Color3.fromRGB(200,140,20), Font=Enum.Font.GothamBold, TextSize=14})
mk(TPspawn, "UICorner", {CornerRadius=UDim.new(0,CORNER)})

-- coords input
local coordsFrame = mk(TeleportFrame, "Frame", {Size=UDim2.new(1,0,0,48), Position=UDim2.new(0,0,0,136), BackgroundTransparency=1})
local XBox = mk(coordsFrame, "TextBox", {Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,0,0,0), PlaceholderText="X", BackgroundColor3=themeColor("panel"), Font=Enum.Font.Gotham, TextSize=14})
mk(XBox, "UICorner", {CornerRadius=UDim.new(0,6)})
local YBox = mk(coordsFrame, "TextBox", {Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,176,0,0), PlaceholderText="Y", BackgroundColor3=themeColor("panel"), Font=Enum.Font.Gotham, TextSize=14})
mk(YBox, "UICorner", {CornerRadius=UDim.new(0,6)})
local ZBox = mk(coordsFrame, "TextBox", {Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,352,0,0), PlaceholderText="Z", BackgroundColor3=themeColor("panel"), Font=Enum.Font.Gotham, TextSize=14})
mk(ZBox, "UICorner", {CornerRadius=UDim.new(0,6)})
local TPcoordsBtn = mk(coordsFrame, "TextButton", {Size=UDim2.new(0,160,1,0), Position=UDim2.new(1,-160,0,0), Text="TP → Coords", BackgroundColor3 = Color3.fromRGB(50,130,60), Font=Enum.Font.GothamBold, TextSize=14})
mk(TPcoordsBtn, "UICorner", {CornerRadius=UDim.new(0,6)})

-- teleport utilities
local function safeTPToPos(pos)
    if not pos or not LocalPlayer or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end)
end
local function safeTPToPlayer(plr)
    if not plr then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end)
    end
end

TPsel.MouseButton1Click:Connect(function() if SelectedPlayer then safeTPToPlayer(SelectedPlayer) end end)
TPrand.MouseButton1Click:Connect(function()
    local pool = {}
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(pool,p) end end
    if #pool == 0 then return end
    local t = pool[math.random(1,#pool)]
    SelectedPlayer = t
    selectedLabel.Text = "Selected: @"..t.Name
    safeTPToPlayer(t)
end)
TPspawn.MouseButton1Click:Connect(function()
    local pos
    for _,c in ipairs(Workspace:GetDescendants()) do if c:IsA("SpawnLocation") then pos = c.Position break end end
    if pos then safeTPToPos(pos) end
end)
TPcoordsBtn.MouseButton1Click:Connect(function()
    local x,y,z = tonumber(XBox.Text), tonumber(YBox.Text), tonumber(ZBox.Text)
    if x and y and z then safeTPToPos(Vector3.new(x,y,z)) else
        for _,b in ipairs({XBox,YBox,ZBox}) do local orig = b.BackgroundColor3 spawn(function() b.BackgroundColor3 = Color3.fromRGB(200,80,80) task.wait(0.25) pcall(function() b.BackgroundColor3 = orig end) end) end
    end
end)

-------------------------
-- TROLL TAB
-------------------------
local TrollFrame = mk(Content, "Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
TrollFrame.Visible = false

-- Troll controls: fling, spin, explode, freeze (freeze basic by anchoring HumanoidRootPart), loop options
local trollLabel = mk(TrollFrame, "TextLabel", {Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text="Troll Controls", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=themeColor("text")})

local trollBtns = mk(TrollFrame, "Frame", {Size=UDim2.new(1,0,0,48), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1})
local flingBtn = mk(trollBtns, "TextButton", {Size=UDim2.new(0,120,0,BUTTON_H), Position=UDim2.new(0,0,0,0), Text="Fling", BackgroundColor3=Color3.fromRGB(220,60,60), Font=Enum.Font.GothamBold})
mk(flingBtn, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local spinBtn = mk(trollBtns, "TextButton", {Size=UDim2.new(0,120,0,BUTTON_H), Position=UDim2.new(0,136,0,0), Text="Spin", BackgroundColor3=Color3.fromRGB(200,140,0), Font=Enum.Font.GothamBold})
mk(spinBtn, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local explodeBtn = mk(trollBtns, "TextButton", {Size=UDim2.new(0,140,0,BUTTON_H), Position=UDim2.new(0,280,0,0), Text="Explode", BackgroundColor3=Color3.fromRGB(180,80,0), Font=Enum.Font.GothamBold})
mk(explodeBtn, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local freezeBtn = mk(trollBtns, "TextButton", {Size=UDim2.new(0,140,0,BUTTON_H), Position=UDim2.new(0,440,0,0), Text="Freeze/Unfreeze", BackgroundColor3=Color3.fromRGB(100,100,110), Font=Enum.Font.GothamBold})
mk(freezeBtn, "UICorner", {CornerRadius=UDim.new(0,CORNER)})

-- loop toggles (fling loop)
local loopFrame = mk(TrollFrame, "Frame", {Size=UDim2.new(1,0,0,84), Position=UDim2.new(0,0,0,96), BackgroundTransparency=1})
local loopLabel = mk(loopFrame, "TextLabel", {Size=UDim2.new(0.4,0,0,28), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=13, TextColor3=themeColor("text"), Text="Loop Actions"})
local loopFlingToggle = mk(loopFrame, "TextButton", {Size=UDim2.new(0,140,0,BUTTON_H), Position=UDim2.new(0,0,0,28), Text="Fling Loop Off", BackgroundColor3=Color3.fromRGB(100,100,110)})
mk(loopFlingToggle, "UICorner", {CornerRadius=UDim.new(0,CORNER)})
local loopJumpToggle = mk(loopFrame, "TextButton", {Size=UDim2.new(0,140,0,BUTTON_H), Position=UDim2.new(0,156,0,28), Text="Jump Loop Off", BackgroundColor3=Color3.fromRGB(100,100,110)})
mk(loopJumpToggle, "UICorner", {CornerRadius=UDim.new(0,CORNER)})

local flingLoopActive, jumpLoopActive = false, false
local function flingPlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("fling_"..plr.UserId, 0.6) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local p = plr.Character.HumanoidRootPart
            p.Velocity = Vector3.new(math.random(-300,300),160,math.random(-300,300))
            p.RotVelocity = Vector3.new(math.random(-140,140),math.random(-140,140),math.random(-140,140))
        end)
    end
end
local function spinPlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("spin_"..plr.UserId, 1.2) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        coroutine.wrap(function()
            local p = plr.Character.HumanoidRootPart
            for i=1,48 do
                if not p.Parent then break end
                pcall(function() p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(30), 0) end)
                task.wait(0.04)
            end
        end)()
    end
end
local function explodePlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("explode_"..plr.UserId, 2.5) then return end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local e = Instance.new("Explosion")
            e.Position = plr.Character.HumanoidRootPart.Position
            e.BlastRadius = 6
            e.BlastPressure = 500000
            e.Parent = Workspace
        end)
    end
end

local frozen = {}
local function toggleFreeze(plr)
    if not plr or isWhitelisted(plr) then return end
    if not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if frozen[plr.UserId] then
        pcall(function() hrp.Anchored = false frozen[plr.UserId] = nil end)
    else
        pcall(function() hrp.Anchored = true frozen[plr.UserId] = true end)
    end
end

local function trollPlayer(plr)
    if not plr then return end
    pcall(function()
        flingPlayer(plr); spinPlayer(plr); explodePlayer(plr)
    end)
end

local function bringPlayer(plr)
    if not plr or isWhitelisted(plr) then return end
    if not canAct("bring_"..plr.UserId, 1.5) then return end
    if plr.Character and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            plr.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,0,3)
        end)
    end
end

-- UI hookups
flingBtn.MouseButton1Click:Connect(function() if SelectedPlayer then flingPlayer(SelectedPlayer) end end)
spinBtn.MouseButton1Click:Connect(function() if SelectedPlayer then spinPlayer(SelectedPlayer) end end)
explodeBtn.MouseButton1Click:Connect(function() if SelectedPlayer then explodePlayer(SelectedPlayer) end end)
freezeBtn.MouseButton1Click:Connect(function() if SelectedPlayer then toggleFreeze(SelectedPlayer) end end)

loopFlingToggle.MouseButton1Click:Connect(function()
    flingLoopActive = not flingLoopActive
    loopFlingToggle.Text = flingLoopActive and "Fling Loop On" or "Fling Loop Off"
    loopFlingToggle.BackgroundColor3 = flingLoopActive and Color3.fromRGB(200,60,60) or Color3.fromRGB(100,100,110)
    if flingLoopActive then
        task.spawn(function()
            while flingLoopActive do
                if SelectedPlayer then flingPlayer(SelectedPlayer) end
                task.wait(0.14)
            end
        end)
    end
end)

loopJumpToggle.MouseButton1Click:Connect(function()
    jumpLoopActive = not jumpLoopActive
    loopJumpToggle.Text = jumpLoopActive and "Jump Loop On" or "Jump Loop Off"
    loopJumpToggle.BackgroundColor3 = jumpLoopActive and Color3.fromRGB(0,160,120) or Color3.fromRGB(100,100,110)
    if jumpLoopActive then
        task.spawn(function()
            while jumpLoopActive do
                if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    pcall(function() SelectedPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
                task.wait(0.5)
            end
        end)
    end
end)

-------------------------
-- SETTINGS TAB
-------------------------
local SettingsFrame = mk(Content, "Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
SettingsFrame.Visible = false

local themeLabel = mk(SettingsFrame, "TextLabel", {Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = "Settings", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = themeColor("text")})
local themeBtn = mk(SettingsFrame, "TextButton", {Size=UDim2.new(0,220,0,BUTTON_H), Position=UDim2.new(0,0,0,40), Text = "Toggle Theme", BackgroundColor3 = themeColor("panel"), Font=Enum.Font.GothamBold})
mk(themeBtn, "UICorner", {CornerRadius = UDim.new(0,CORNER)})

local resetBtn = mk(SettingsFrame, "TextButton", {Size=UDim2.new(0,220,0,BUTTON_H), Position=UDim2.new(0,236,0,40), Text = "Reset GUI", BackgroundColor3 = Color3.fromRGB(200,80,80), Font=Enum.Font.GothamBold})
mk(resetBtn, "UICorner", {CornerRadius = UDim.new(0,CORNER)})

local saveBtn = mk(SettingsFrame, "TextButton", {Size=UDim2.new(0,220,0,BUTTON_H), Position=UDim2.new(0,0,0,96), Text = "Save Config", BackgroundColor3 = Color3.fromRGB(0,150,120), Font=Enum.Font.GothamBold})
mk(saveBtn, "UICorner", {CornerRadius = UDim.new(0,CORNER)})

local loadBtn = mk(SettingsFrame, "TextButton", {Size=UDim2.new(0,220,0,BUTTON_H), Position=UDim2.new(0,236,0,96), Text = "Load Config", BackgroundColor3 = Color3.fromRGB(100,100,200), Font=Enum.Font.GothamBold})
mk(loadBtn, "UICorner", {CornerRadius = UDim.new(0,CORNER)})

themeBtn.MouseButton1Click:Connect(function()
    config.theme = (config.theme == "dark") and "light" or "dark"
    saveConfig()
    -- update colors quickly (partial)
    Main.BackgroundColor3 = themeColor("bg")
    -- update other major elements
    TitleLabel.TextColor3 = themeColor("text")
    HotkeysLabel.TextColor3 = themeColor("text")
    CloseBtn.TextColor3 = themeColor("accent")
    -- refresh lists to rebuild colors on next refresh
    RefreshPlayerList()
end)

resetBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local old = CoreGui:FindFirstChild("ZeroTPPlayerGUI_v5")
        if old then old:Destroy() end
    end)
end)

saveBtn.MouseButton1Click:Connect(function() saveConfig() end)
loadBtn.MouseButton1Click:Connect(function()
    -- re-run load
    local ok, content = pcall(function() return readfile and readfile(CONFIG_FILE) end)
    if ok and content then
        local decodeOk, dec = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
        if decodeOk and type(dec) == "table" then
            config = dec
            saveConfig()
            RefreshPlayerList()
        end
    end
end)

-------------------------
-- Follow / Spectate / Stop helpers (shared)
-------------------------
function stopAllModes()
    FollowingPlayer = nil
    if FollowConn then pcall(function() FollowConn:Disconnect() end) FollowConn = nil end
    SpectatingPlayer = nil
    if SpectateConn then pcall(function() SpectateConn:Disconnect() end) SpectateConn = nil end
    if LocalPlayer and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() Camera.CameraSubject = hum end) end
    end
end

function startFollowing(plr)
    stopAllModes()
    if not plr then return end
    FollowingPlayer = plr
    FollowConn = RunService.Heartbeat:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            stopAllModes(); return
        end
        pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end)
    end)
end

function startSpectating(plr)
    stopAllModes()
    if not plr then return end
    SpectatingPlayer = plr
    SpectateConn = RunService.RenderStepped:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")) then stopAllModes(); return end
        pcall(function() Camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid") end)
    end)
end

-------------------------
-- Hotkeys
-------------------------
UserInput.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        local k = inp.KeyCode
        if k == Enum.KeyCode.T then if SelectedPlayer then stopAllModes(); safeTPToPlayer(SelectedPlayer) end
        elseif k == Enum.KeyCode.R then if SelectedPlayer then if FollowingPlayer == SelectedPlayer then stopAllModes() else startFollowing(SelectedPlayer) end end
        elseif k == Enum.KeyCode.Y then if SelectedPlayer then if SpectatingPlayer == SelectedPlayer then stopAllModes() else startSpectating(SelectedPlayer) end end
        elseif k == Enum.KeyCode.G then if SelectedPlayer then bringPlayer(SelectedPlayer) end
        elseif k == Enum.KeyCode.F then stopAllModes() end
    end
end)

-------------------------
-- MassTroll improved
-------------------------
local massTrollActive = false
local function MassTroll()
    if not config.massTrollEnabled then return end
    if massTrollActive then return end
    massTrollActive = true
    task.spawn(function()
        for _,plr in ipairs(Players:GetPlayers()) do
            if not massTrollActive then break end
            if plr ~= LocalPlayer and not isWhitelisted(plr) then
                trollPlayer(plr)
                task.wait(0.12)
            end
        end
        massTrollActive = false
    end)
end

-- simple hook: if mass toggle stored in config, reflect it; can be toggled via settings UI in future
config.massTrollEnabled = config.massTrollEnabled or false

-------------------------
-- Connections & loops
-------------------------
searchBox:GetPropertyChangedSignal("Text"):Connect(RefreshPlayerList)
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)

-- auto refresh loop
local refreshRunning = true
task.spawn(function()
    while refreshRunning do
        task.wait(2.5)
        pcall(RefreshPlayerList)
    end
end)

-- cleanup on destroy
ScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        refreshRunning = false
        stopAllModes()
    end
end)
Players.PlayerRemoving:Connect(function(plr) if plr == LocalPlayer then refreshRunning = false stopAllModes() end end)

-- initial setup
setTab("Players")
RefreshPlayerList()
saveConfig() -- save defaults

-- End of Zero TP Player v5.0
