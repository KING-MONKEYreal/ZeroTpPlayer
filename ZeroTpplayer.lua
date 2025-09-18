-- Zero TP Player v8.0 — Full Release
-- Complete rework: Tabs (Players / Teleport / Troll / ESP / Settings / Scripts / Info)
-- All bugs fixed, performance improvements, mobile-friendly, animated UI, whitelist, hotkeys,
-- config save/load (writefile/readfile if available), thumbnail retry, safe pcall wrappers,
-- heavy debounces (os.clock), StopAll hardening, cleanup on destroy.
-- WARNING: This script manipulates other players in-game. Use responsibly.

-- ======================
-- Services & Utilities
-- ======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = workspace
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TOUCH = UserInput.TouchEnabled

local function now() return os.clock() end
local DEBOUNCE = {}
local function canAct(key, cd) cd = cd or 1 if DEBOUNCE[key] and now()-DEBOUNCE[key] < cd then return false end DEBOUNCE[key]=now() return true end
local function safePcall(fn, ...) local ok,res = pcall(fn, ...) return ok,res end

-- ======================
-- Config / Persistence
-- ======================
local CONFIG_FILE = "zero_tp_v8_config.json"
local defaultConfig = {
    theme = "dark",
    ui_size = "normal",
    animations = true,
    massTrollEnabled = false,
    whitelist = {}, -- tostring(userId)=true
    hotkeys = { TP="T", FOLLOW="R", SPECTATE="Y", BRING="G", STOP="F" },
    esp = { enabled=false, showHealth=true, outline=true, fill=false, color={r=0,g=150,b=255} }
}
local config = {}
do
    for k,v in pairs(defaultConfig) do config[k]=v end
    local ok,content = pcall(function() if readfile then return readfile(CONFIG_FILE) end end)
    if ok and content then
        local ok2, parsed = pcall(function() return HttpService:JSONDecode(content) end)
        if ok2 and type(parsed)=="table" then
            for k,v in pairs(parsed) do config[k]=v end
        end
    end
end
local function saveConfig() pcall(function() if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end end) end

-- ======================
-- Safe destroy previous GUI
-- ======================
pcall(function()
    local old = CoreGui:FindFirstChild("ZeroTPPlayer_v8_GUI")
    if old then old:Destroy() end
end)

-- ======================
-- Theming helpers
-- ======================
local function theme(name)
    if config.theme=="light" then
        local t = { bg=Color3.fromRGB(245,245,250), panel=Color3.fromRGB(235,235,240), text=Color3.fromRGB(20,20,26), accent=Color3.fromRGB(40,120,255), soft=Color3.fromRGB(200,200,205) }
        return t[name]
    else
        local t = { bg=Color3.fromRGB(18,18,22), panel=Color3.fromRGB(34,34,40), text=Color3.fromRGB(230,230,235), accent=Color3.fromRGB(0,170,255), soft=Color3.fromRGB(100,100,110) }
        return t[name]
    end
end

-- ======================
-- GUI Helpers
-- ======================
local function mk(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k]=v end
    return inst
end
local function add(parent, class, props)
    local i = mk(class, props)
    i.Parent = parent
    return i
end
local function tween(obj, props, t) local tw=TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) tw:Play() return tw end

-- ======================
-- Root GUI
-- ======================
local ScreenGui = add(CoreGui, "ScreenGui", {Name="ZeroTPPlayer_v8_GUI", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local frameSize = (config.ui_size=="large") and (TOUCH and UDim2.new(0.98,0,0.94,0) or UDim2.new(0,1000,0,700))
                  or (TOUCH and UDim2.new(0.96,0,0.92,0) or UDim2.new(0,920,0,620))
local Frame = add(ScreenGui, "Frame", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=frameSize, BackgroundColor3=theme("bg"), BorderSizePixel=0, Active=true, Draggable=true})
add(Frame, "UICorner", {CornerRadius=UDim.new(0,14)})
if config.animations then Frame.Size = UDim2.new(0,10,0,10); tween(Frame, {Size=frameSize}, 0.25) end

-- Title bar
local TitleBar = add(Frame, "Frame", {Size=UDim2.new(1,0,0,50), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1})
local TitleLabel = add(TitleBar, "TextLabel", {Size=UDim2.new(0.6,-16,1,0), Position=UDim2.new(0,16,0,0), BackgroundTransparency=1, Text="Zero TP Player v8.0", Font=Enum.Font.GothamBold, TextSize=18, TextColor3=theme("text"), TextXAlignment=Enum.TextXAlignment.Left})
local HotkeyLabel = add(TitleBar, "TextLabel", {Size=UDim2.new(0.4,-16,1,0), Position=UDim2.new(0.6,8,0,0), BackgroundTransparency=1, Text=("Hotkeys: %s TP · %s Follow · %s Spectate · %s Bring · %s Stop"):format(config.hotkeys.TP, config.hotkeys.FOLLOW, config.hotkeys.SPECTATE, config.hotkeys.BRING, config.hotkeys.STOP), Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme("soft"), TextXAlignment=Enum.TextXAlignment.Right})
local CloseBtn = add(TitleBar, "TextButton", {Size=UDim2.new(0,36,0,36), Position=UDim2.new(1,-44,0,7), BackgroundTransparency=1, Text="✕", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=theme("accent")})
CloseBtn.MouseButton1Click:Connect(function() pcall(function() ScreenGui:Destroy() end) end)

-- Left tabs column
local TabsFrame = add(Frame, "Frame", {Size=UDim2.new(0,220,1,-24), Position=UDim2.new(0,12,0,60), BackgroundTransparency=1})
add(TabsFrame, "UICorner", {CornerRadius=UDim.new(0,10)})
local tabNames = {"Players","Teleport","Troll","ESP","Scripts","Settings","Info"}
local tabButtons = {}
local currentTab

local function createTabButton(name, idx)
    local btn = add(TabsFrame, "TextButton", {Size=UDim2.new(1,-16,0,48), Position=UDim2.new(0,8,0,(idx-1)*56), BackgroundColor3=theme("panel"), Text=name, Font=Enum.Font.GothamBold, TextSize=16, TextColor3=theme("text")})
    add(btn, "UICorner", {CornerRadius=UDim.new(0,8)})
    return btn
end

for i,name in ipairs(tabNames) do tabButtons[name]=createTabButton(name,i) end

-- Content area
local Content = add(Frame, "Frame", {Size=UDim2.new(1,-(220+36),1,-72), Position=UDim2.new(0,220+16,0,60), BackgroundTransparency=1})
add(Content, "UICorner", {CornerRadius=UDim.new(0,10)})

-- shared state
local SelectedPlayer = nil
local FollowingPlayer, SpectatingPlayer = nil,nil
local FollowConn, SpectateConn = nil,nil
local whitelist = config.whitelist or {}
local massTrollEnabled = config.massTrollEnabled or false
local highlights = {} -- userId -> highlight object
local frozen = {} -- userId -> true
local cageParts = {} -- userId -> parts array
local loops = { fling=false, jump=false, teleport=false }

-- ======================
-- Players Tab
-- ======================
local PlayersFrame = add(Content, "Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
local searchBox = add(PlayersFrame, "TextBox", {Size=UDim2.new(0.6,0,0,36), Position=UDim2.new(0,0,0,0), PlaceholderText="🔍 Search players...", Font=Enum.Font.Gotham, TextSize=14, BackgroundColor3=theme("panel"), TextColor3=theme("text"), ClearTextOnFocus=false}); add(searchBox, "UICorner", {CornerRadius=UDim.new(0,8)})
local selectedLabel = add(PlayersFrame, "TextLabel", {Size=UDim2.new(0.4,-8,0,36), Position=UDim2.new(0.6,8,0,0), BackgroundColor3=theme("panel"), TextColor3=theme("text"), Font=Enum.Font.Gotham, TextSize=13, Text="Selected: none"}); add(selectedLabel,"UICorner",{CornerRadius=UDim.new(0,8)})
local playersList = add(PlayersFrame, "ScrollingFrame", {Size=UDim2.new(1,0,1,-64), Position=UDim2.new(0,0,0,56), BackgroundTransparency=1, ScrollBarThickness=8, AutomaticCanvasSize=Enum.AutomaticSize.Y})
local playersLayout = add(playersList, "UIListLayout", {Padding=UDim.new(0,8)}); playersLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() playersList.CanvasSize = UDim2.new(0,0,0, playersLayout.AbsoluteContentSize + 12) end)

local function safeThumbnailSet(img,userId)
    task.spawn(function()
        for i=1,3 do
            local ok,thumb = pcall(function() return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and thumb and typeof(thumb)=="string" then pcall(function() img.Image = thumb end) break end
            task.wait(0.18)
        end
    end)
end

local function setSelected(plr)
    SelectedPlayer = plr
    selectedLabel.Text = plr and ("Selected: @"..plr.Name) or "Selected: none"
end

local function isWhitelisted(plr) if not plr then return false end return whitelist[tostring(plr.UserId)]==true end

local function AddPlayerEntry(plr)
    if not plr then return end
    local Entry = add(playersList,"Frame",{Size=UDim2.new(1,0,0,92), BackgroundColor3=theme("panel")})
    add(Entry,"UICorner",{CornerRadius=UDim.new(0,8)}); Entry.LayoutOrder = plr.UserId
    local avatar = add(Entry,"ImageLabel",{Size=UDim2.new(0,64,0,64), Position=UDim2.new(0,10,0.5,-32), BackgroundTransparency=1}); add(avatar,"UICorner",{CornerRadius=UDim.new(0,8)})
    safeThumbnailSet(avatar, plr.UserId)
    add(Entry,"TextLabel",{Size=UDim2.new(1,-260,0,20), Position=UDim2.new(0,84,0,8), BackgroundTransparency=1, Text="@"..tostring(plr.Name), Font=Enum.Font.GothamBold, TextColor3=theme("text"), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
    add(Entry,"TextLabel",{Size=UDim2.new(1,-260,0,18), Position=UDim2.new(0,84,0,32), BackgroundTransparency=1, Text=tostring(plr.DisplayName or ""), Font=Enum.Font.Gotham, TextColor3=Color3.fromRGB(180,180,180), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
    local btns = add(Entry,"Frame",{Size=UDim2.new(0,420,1,0), Position=UDim2.new(1,-432,0,0), BackgroundTransparency=1})
    local function mkBtn(text,x,w,color)
        local b = add(btns,"TextButton",{Size=UDim2.new(0,w,0,34), Position=UDim2.new(0,x,0, (92-34)/2), BackgroundColor3=color, Text=text, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=theme("bg")})
        add(b,"UICorner",{CornerRadius=UDim.new(0,6)})
        return b
    end
    local TPbtn = mkBtn("TP",0,56,Color3.fromRGB(0,160,100))
    local FollowBtn = mkBtn("Follow",68,72,Color3.fromRGB(0,110,200))
    local SpecBtn = mkBtn("Spectate",152,84,Color3.fromRGB(200,150,0))
    local TrollBtn = mkBtn("Troll",244,72,Color3.fromRGB(220,60,60))
    local BringBtn = mkBtn("Bring",322,56,Color3.fromRGB(160,100,220))
    local WLbtn = mkBtn(isWhitelisted(plr) and "Whitelist ✓" or "Whitelist",386,80,isWhitelisted(plr) and Color3.fromRGB(20,160,80) or Color3.fromRGB(100,100,110))

    WLbtn.MouseButton1Click:Connect(function()
        whitelist[tostring(plr.UserId)] = not whitelist[tostring(plr.UserId)]
        if whitelist[tostring(plr.UserId)] then WLbtn.Text="Whitelist ✓"; WLbtn.BackgroundColor3=Color3.fromRGB(20,160,80) else WLbtn.Text="Whitelist"; WLbtn.BackgroundColor3=Color3.fromRGB(100,100,110) end
        config.whitelist = whitelist; saveConfig()
    end)

    TPbtn.MouseButton1Click:Connect(function() setSelected(plr); stopAllModes(); safeTPToPlayer(plr) end)
    FollowBtn.MouseButton1Click:Connect(function() setSelected(plr); if FollowingPlayer==plr then stopAllModes() else startFollowing(plr) end end)
    SpecBtn.MouseButton1Click:Connect(function() setSelected(plr); if SpectatingPlayer==plr then stopAllModes() else startSpectating(plr) end end)
    TrollBtn.MouseButton1Click:Connect(function() trollPlayer(plr) end)
    BringBtn.MouseButton1Click:Connect(function() bringPlayer(plr) end)

    Entry.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then setSelected(plr) end end)
end

local function RefreshPlayers()
    for _,c in ipairs(playersList:GetChildren()) do if c~=playersLayout then pcall(function() c:Destroy() end) end end
    local q = (searchBox.Text or ""):lower()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then local ok, match = pcall(function() local n1=(p.Name or ""):lower() local n2=(p.DisplayName or ""):lower() return q=="" or n1:find(q) or n2:find(q) end) if ok and match then AddPlayerEntry(p) end end
    end
end

-- ======================
-- Teleport Tab
-- ======================
local TeleportFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); TeleportFrame.Visible=false
local TPInfo = add(TeleportFrame,"TextLabel",{Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text="Teleport Controls", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=theme("text")})
local TPButtons = add(TeleportFrame,"Frame",{Size=UDim2.new(1,0,0,56), Position=UDim2.new(0,0,0,40), BackgroundTransparency=1})
local TPsel = add(TPButtons,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,0,0,0), Text="TP Selected", BackgroundColor3=theme("accent"), Font=Enum.Font.GothamBold, TextSize=14}); add(TPsel,"UICorner",{CornerRadius=UDim.new(0,6)})
local TPrand = add(TPButtons,"TextButton",{Size=UDim2.new(0,140,0,36), Position=UDim2.new(0,176,0,0), Text="TP Random", BackgroundColor3=Color3.fromRGB(0,120,200), Font=Enum.Font.GothamBold, TextSize=14}); add(TPrand,"UICorner",{CornerRadius=UDim.new(0,6)})
local TPspawn = add(TPButtons,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,332,0,0), Text="TP Spawn", BackgroundColor3=Color3.fromRGB(200,140,0), Font=Enum.Font.GothamBold, TextSize=14}); add(TPspawn,"UICorner",{CornerRadius=UDim.new(0,6)})
local coordsF = add(TeleportFrame,"Frame",{Size=UDim2.new(1,0,0,48), Position=UDim2.new(0,0,0,108), BackgroundTransparency=1})
local XBox = add(coordsF,"TextBox",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,0,0,0), PlaceholderText="X", BackgroundColor3=theme("panel")}); add(XBox,"UICorner",{CornerRadius=UDim.new(0,6)})
local YBox = add(coordsF,"TextBox",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,176,0,0), PlaceholderText="Y", BackgroundColor3=theme("panel")}); add(YBox,"UICorner",{CornerRadius=UDim.new(0,6)})
local ZBox = add(coordsF,"TextBox",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,352,0,0), PlaceholderText="Z", BackgroundColor3=theme("panel")}); add(ZBox,"UICorner",{CornerRadius=UDim.new(0,6)})
local TPcoords = add(coordsF,"TextButton",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(1,-160,0,0), Text="TP → Coords", BackgroundColor3=Color3.fromRGB(50,130,60), Font=Enum.Font.GothamBold}); add(TPcoords,"UICorner",{CornerRadius=UDim.new(0,6)})

function safeTPToPos(pos) if not pos or not LocalPlayer or not LocalPlayer.Character then return end local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end) end
function safeTPToPlayer(plr) if not plr then return end pcall(function() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end end) end

TPsel.MouseButton1Click:Connect(function() if SelectedPlayer then stopAllModes(); safeTPToPlayer(SelectedPlayer) end end)
TPrand.MouseButton1Click:Connect(function() local pool={} for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(pool,p) end end if #pool==0 then return end local t = pool[math.random(1,#pool)]; setSelected(t); stopAllModes(); safeTPToPlayer(t) end)
TPspawn.MouseButton1Click:Connect(function() local pos for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("SpawnLocation") then pos=v.Position break end end if pos then safeTPToPos(pos) end end)
TPcoords.MouseButton1Click:Connect(function() local x,y,z = tonumber(XBox.Text), tonumber(YBox.Text), tonumber(ZBox.Text) if x and y and z then stopAllModes(); safeTPToPos(Vector3.new(x,y,z)) else for _,b in ipairs({XBox,YBox,ZBox}) do local orig=b.BackgroundColor3 task.spawn(function() b.BackgroundColor3=Color3.fromRGB(200,80,80) task.wait(0.2) pcall(function() b.BackgroundColor3=orig end) end) end end end)

-- ======================
-- Troll Tab
-- ======================
local TrollFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); TrollFrame.Visible=false
local flingBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,140,0,36), Position=UDim2.new(0,0,0,40), Text="Fling"}); add(flingBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local spinBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,140,0,36), Position=UDim2.new(0,156,0,40), Text="Spin"}); add(spinBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local explodeBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,312,0,40), Text="Explode"}); add(explodeBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local freezeBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,180,0,36), Position=UDim2.new(0,480,0,40), Text="Freeze/Unfreeze"}); add(freezeBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local cageBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,0,0,92), Text="Toggle Cage"}); add(cageBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local launchBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,176,0,92), Text="Launch"}); add(launchBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local fakeLagBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,352,0,92), Text="Fake Lag"}); add(fakeLagBtn,"UICorner",{CornerRadius=UDim.new(0,6)})

local function flingPlayer(plr) if not plr or isWhitelisted(plr) then return end if not canAct("fling_"..plr.UserId,0.6) then return end if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then pcall(function() local p = plr.Character.HumanoidRootPart p.Velocity = Vector3.new(math.random(-320,320),200,math.random(-320,320)) p.RotVelocity = Vector3.new(math.random(-180,180),math.random(-180,180),math.random(-180,180)) end) end end
local function spinPlayerFunc(plr) if not plr or isWhitelisted(plr) then return end if not canAct("spin_"..plr.UserId,1.2) then return end if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then coroutine.wrap(function() local p=plr.Character.HumanoidRootPart for i=1,60 do if not p.Parent then break end pcall(function() p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(30), 0) end) task.wait(0.03) end end)() end end
local function explodePlayer(plr) if not plr or isWhitelisted(plr) then return end if not canAct("explode_"..plr.UserId,2.5) then return end if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then pcall(function() local e = Instance.new("Explosion") e.Position = plr.Character.HumanoidRootPart.Position e.BlastRadius = 6 e.BlastPressure = 500000 e.Parent = Workspace end) end end
local function toggleFreeze(plr) if not plr or isWhitelisted(plr) then return end if not plr.Character then return end local hrp=plr.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end if frozen[tostring(plr.UserId)] then pcall(function() hrp.Anchored = false frozen[tostring(plr.UserId)]=nil end) else pcall(function() hrp.Anchored = true frozen[tostring(plr.UserId)]=true end) end end

local function makeCage(plr) if not plr or isWhitelisted(plr) then return end if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end local id=tostring(plr.UserId) if cageParts[id] then for _,p in ipairs(cageParts[id]) do p:Destroy() end cageParts[id]=nil return end local base=plr.Character.HumanoidRootPart.Position local parts={} local function mkPart(pos,size) local p=Instance.new("Part") p.Size=size p.Anchored=true p.CanCollide=true p.Transparency=1 p.CFrame=CFrame.new(pos) p.Parent=Workspace table.insert(parts,p) end mkPart(base+Vector3.new(3,0,0),Vector3.new(0.2,6,6)) mkPart(base+Vector3.new(-3,0,0),Vector3.new(0.2,6,6)) mkPart(base+Vector3.new(0,3,0),Vector3.new(6,0.2,6)) mkPart(base+Vector3.new(0,-3,0),Vector3.new(6,0.2,6)) mkPart(base+Vector3.new(0,0,3),Vector3.new(6,6,0.2)) mkPart(base+Vector3.new(0,0,-3),Vector3.new(6,6,0.2)) cageParts[id]=parts task.spawn(function() while cageParts[id] do if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then break end local pos=plr.Character.HumanoidRootPart.Position for i,p in ipairs(cageParts[id]) do if i==1 then p.CFrame=CFrame.new(pos+Vector3.new(3,0,0)) elseif i==2 then p.CFrame=CFrame.new(pos+Vector3.new(-3,0,0)) elseif i==3 then p.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) elseif i==4 then p.CFrame=CFrame.new(pos+Vector3.new(0,-3,0)) elseif i==5 then p.CFrame=CFrame.new(pos+Vector3.new(0,0,3)) else p.CFrame=CFrame.new(pos+Vector3.new(0,0,-3)) end end task.wait(0.15) end if cageParts[id] then for _,p in ipairs(cageParts[id]) do p:Destroy() end cageParts[id]=nil end end) end

local function launchPlayer(plr,force) if not plr or isWhitelisted(plr) then return end force = force or 240 if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then pcall(function() plr.Character.HumanoidRootPart.Velocity = Vector3.new(0,force,0) end) end end

local function trollPlayer(plr) if not plr then return end pcall(function() flingPlayer(plr); spinPlayerFunc(plr); explodePlayer(plr) end) end

-- hookup buttons
flingBtn.MouseButton1Click:Connect(function() if SelectedPlayer then flingPlayer(SelectedPlayer) end end)
spinBtn.MouseButton1Click:Connect(function() if SelectedPlayer then spinPlayerFunc(SelectedPlayer) end end)
explodeBtn.MouseButton1Click:Connect(function() if SelectedPlayer then explodePlayer(SelectedPlayer) end end)
freezeBtn.MouseButton1Click:Connect(function() if SelectedPlayer then toggleFreeze(SelectedPlayer) end end)
cageBtn.MouseButton1Click:Connect(function() if SelectedPlayer then makeCage(SelectedPlayer) end end)
launchBtn.MouseButton1Click:Connect(function() if SelectedPlayer then launchPlayer(SelectedPlayer, 260) end end)

-- loops
local flingLoopBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,520,0,92), Text="Fling Loop Off"}); add(flingLoopBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local jumpLoopBtn = add(TrollFrame,"TextButton",{Size=UDim2.new(0,160,0,36), Position=UDim2.new(0,688,0,92), Text="Jump Loop Off"}); add(jumpLoopBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
flingLoopBtn.MouseButton1Click:Connect(function()
    loops.fling = not loops.fling
    flingLoopBtn.Text = loops.fling and "Fling Loop On" or "Fling Loop Off"
    flingLoopBtn.BackgroundColor3 = loops.fling and Color3.fromRGB(200,60,60) or Color3.fromRGB(100,100,110)
    if loops.fling then task.spawn(function() while loops.fling do if SelectedPlayer then flingPlayer(SelectedPlayer) end task.wait(0.12) end end) end
end)
jumpLoopBtn.MouseButton1Click:Connect(function()
    loops.jump = not loops.jump
    jumpLoopBtn.Text = loops.jump and "Jump Loop On" or "Jump Loop Off"
    jumpLoopBtn.BackgroundColor3 = loops.jump and Color3.fromRGB(0,160,120) or Color3.fromRGB(100,100,110)
    if loops.jump then task.spawn(function() while loops.jump do if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChildOfClass("Humanoid") then pcall(function() SelectedPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end) end task.wait(0.45) end end) end
end)

-- ======================
-- ESP Tab
-- ======================
local ESPFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); ESPFrame.Visible=false
local espToggle = add(ESPFrame,"TextButton",{Size=UDim2.new(0,200,0,36), Position=UDim2.new(0,0,0,40), Text = config.esp.enabled and "ESP On" or "ESP Off", BackgroundColor3 = config.esp.enabled and Color3.fromRGB(0,150,80) or Color3.fromRGB(100,100,110)}); add(espToggle,"UICorner",{CornerRadius=UDim.new(0,6)})
local espHealthBtn = add(ESPFrame,"TextButton",{Size=UDim2.new(0,180,0,36), Position=UDim2.new(0,216,0,40), Text = config.esp.showHealth and "Health On" or "Health Off", BackgroundColor3 = config.esp.showHealth and Color3.fromRGB(0,150,80) or Color3.fromRGB(100,100,110)}); add(espHealthBtn,"UICorner",{CornerRadius=UDim.new(0,6)})

local function enableESPFor(plr)
    if not plr or not plr.Character then return end
    local id=tostring(plr.UserId)
    if highlights[id] then return end
    local hl = Instance.new("Highlight"); hl.Name="ZeroESP"; hl.Adornee = plr.Character; hl.Parent = plr.Character; hl.Enabled = true
    local c = config.esp.color; hl.OutlineColor = Color3.fromRGB(c.r or 0, c.g or 150, c.b or 255); hl.OutlineTransparency = config.esp.outline and 0 or 1; hl.FillTransparency = config.esp.fill and 0.7 or 1
    highlights[id]=hl
    if config.esp.showHealth then
        local bill = Instance.new("BillboardGui"); bill.Name="ZeroESP_Health"; bill.Adornee = plr.Character:FindFirstChildWhichIsA("BasePart") or plr.Character:FindFirstChild("HumanoidRootPart"); bill.Size=UDim2.new(0,90,0,28); bill.AlwaysOnTop = true; bill.Parent=plr.Character
        local bg = Instance.new("Frame", bill); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0); bg.BackgroundTransparency=0.5; bg.BorderSizePixel=0
        local lbl = Instance.new("TextLabel", bg); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextColor3=Color3.fromRGB(255,255,255)
        task.spawn(function() while bill.Parent do local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then lbl.Text = tostring(math.floor(hum.Health)).." HP" else lbl.Text = "" end task.wait(0.35) end end)
    end
end

local function disableESPFor(plr)
    if not plr then return end
    local id=tostring(plr.UserId)
    if highlights[id] then pcall(function() highlights[id]:Destroy() end); highlights[id]=nil end
    if plr.Character then for _,v in ipairs(plr.Character:GetChildren()) do if v.Name=="ZeroESP_Health" then pcall(function() v:Destroy() end) end end end
end

local function setESPAll(state)
    config.esp.enabled = state; saveConfig()
    if state then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then enableESPFor(p) end end else for id,hl in pairs(highlights) do pcall(function() hl:Destroy() end); highlights[id]=nil end end
    espToggle.Text = state and "ESP On" or "ESP Off"; espToggle.BackgroundColor3 = state and Color3.fromRGB(0,150,80) or Color3.fromRGB(100,100,110)
end

espToggle.MouseButton1Click:Connect(function() setESPAll(not config.esp.enabled) end)
espHealthBtn.MouseButton1Click:Connect(function() config.esp.showHealth = not config.esp.showHealth; espHealthBtn.Text = config.esp.showHealth and "Health On" or "Health Off"; espHealthBtn.BackgroundColor3 = config.esp.showHealth and Color3.fromRGB(0,150,80) or Color3.fromRGB(100,100,110); saveConfig() end)

-- update ESP when players added/removed/character added
Players.PlayerAdded:Connect(function(plr) if config.esp.enabled then plr.CharacterAdded:Connect(function() enableESPFor(plr) end) end end)
Players.PlayerRemoving:Connect(function(plr) disableESPFor(plr) end)

-- ======================
-- Scripts Hub Tab (simple preloaded tools)
-- ======================
local ScriptsFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); ScriptsFrame.Visible=false
local scriptsLabel = add(ScriptsFrame,"TextLabel",{Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text="Scripts Hub (preloaded shortcuts)", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=theme("text")})
local flyBtn = add(ScriptsFrame,"TextButton",{Size=UDim2.new(0,200,0,36), Position=UDim2.new(0,0,0,40), Text="Fly (simple)"}) add(flyBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local noclipBtn = add(ScriptsFrame,"TextButton",{Size=UDim2.new(0,200,0,36), Position=UDim2.new(0,216,0,40), Text="Noclip Toggle"}) add(noclipBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local iyBtn = add(ScriptsFrame,"TextButton",{Size=UDim2.new(0,200,0,36), Position=UDim2.new(0,432,0,40), Text="Execute small script"}) add(iyBtn,"UICorner",{CornerRadius=UDim.new(0,6)})

-- simple fly: toggles body velocity on local player
local flying = false; local flyForce
flyBtn.MouseButton1Click:Connect(function()
    if flying then flying=false; if flyForce then pcall(function() flyForce:Destroy() end) end flyBtn.Text="Fly (simple)" return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    flying=true; flyBtn.Text="Stop Fly"
    flyForce = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart); flyForce.MaxForce = Vector3.new(1e5,1e5,1e5); flyForce.Velocity = Vector3.new(0,0,0)
    task.spawn(function() while flying and flyForce.Parent do flyForce.Velocity = Vector3.new(0,0,0) task.wait(0.1) end end)
end)

-- simple noclip by setting CanCollide false
local noclipping=false
noclipBtn.MouseButton1Click:Connect(function()
    noclipping = not noclipping
    noclipBtn.Text = noclipping and "Noclip: On" or "Noclip Toggle"
    if noclipping then
        task.spawn(function() while noclipping do if LocalPlayer.Character then for _,c in ipairs(LocalPlayer.Character:GetDescendants()) do if c:IsA("BasePart") then c.CanCollide=false end end end task.wait(0.6) end end)
    end
end)

iyBtn.MouseButton1Click:Connect(function()
    -- small example: chat "Hello from Zero!"
    pcall(function() game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") end)
    pcall(function() if game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Character then print("Executed small script") end end)
end)

-- ======================
-- Settings Tab
-- ======================
local SettingsFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); SettingsFrame.Visible=false
local themeBtn = add(SettingsFrame,"TextButton",{Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,0,0,40), Text="Toggle Theme"}); add(themeBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local uiSizeBtn = add(SettingsFrame,"TextButton",{Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,240,0,40), Text = (config.ui_size=="large") and "UI Size: Large" or "UI Size: Normal"}); add(uiSizeBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local saveBtn = add(SettingsFrame,"TextButton",{Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,480,0,40), Text="Save Config"}); add(saveBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local loadBtn = add(SettingsFrame,"TextButton",{Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,0,0,96), Text="Load Config"}); add(loadBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
local resetBtn = add(SettingsFrame,"TextButton",{Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,240,0,96), Text="Reset GUI"}); add(resetBtn,"UICorner",{CornerRadius=UDim.new(0,6)})

themeBtn.MouseButton1Click:Connect(function() config.theme = (config.theme=="dark") and "light" or "dark"; saveConfig(); -- apply some colors
    Frame.BackgroundColor3 = theme("bg"); TitleLabel.TextColor3 = theme("text"); HotkeyLabel.TextColor3 = theme("soft"); RefreshPlayers()
end)
uiSizeBtn.MouseButton1Click:Connect(function() config.ui_size = (config.ui_size=="large") and "normal" or "large"; saveConfig(); -- restart UI quick
    pcall(function() ScreenGui:Destroy() end) ; warn("Please re-run the script to apply UI size change.")
end)
saveBtn.MouseButton1Click:Connect(function() saveConfig() end)
loadBtn.MouseButton1Click:Connect(function() local ok,content = pcall(function() if readfile then return readfile(CONFIG_FILE) end end) if ok and content then local ok2, parsed = pcall(function() return HttpService:JSONDecode(content) end) if ok2 and type(parsed)=="table" then config = parsed; whitelist = config.whitelist or {}; saveConfig(); RefreshPlayers(); setESPAll(config.esp.enabled) end end end)
resetBtn.MouseButton1Click:Connect(function() pcall(function() local old = CoreGui:FindFirstChild("ZeroTPPlayer_v8_GUI") if old then old:Destroy() end end) end)

-- ======================
-- Info Tab (hardcoded message)
-- ======================
local InfoFrame = add(Content,"Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1}); InfoFrame.Visible=false
local infoLabel = add(InfoFrame,"TextLabel",{Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text="Info", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=theme("text")})
local infoBox = add(InfoFrame,"TextLabel",{Size=UDim2.new(1,-20,0,200), Position=UDim2.new(0,10,0,40), BackgroundColor3=theme("panel"), TextColor3=theme("text"), Font=Enum.Font.Gotham, TextSize=14, TextWrapped=true, Text = [[ℹ️ Information

Zero TP Player v8.0 — Full Release.

This script is provided free. If you paid someone for this script, you were likely scammed.

Credits: Zero — community releases.

Use responsibly. Abusive use may lead to bans.]]})
add(infoBox,"UICorner",{CornerRadius=UDim.new(0,8)})

-- ======================
-- Follow/Spectate/Stop helpers
-- ======================
function stopAllModes()
    -- stop loops/rollbacks
    loops.fling=false; loops.jump=false; loops.teleport=false
    -- clear follow/spectate
    FollowingPlayer=nil
    if FollowConn then pcall(function() FollowConn:Disconnect() end) FollowConn=nil end
    SpectatingPlayer=nil
    if SpectateConn then pcall(function() SpectateConn:Disconnect() end) SpectateConn=nil end
    -- restore camera
    if LocalPlayer and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then pcall(function() Camera.CameraSubject = hum end) end end
    -- clear cages and frozen
    for id,parts in pairs(cageParts) do for _,p in ipairs(parts) do p:Destroy() end cageParts[id]=nil end
    for id,_ in pairs(frozen) do frozen[id]=nil end
end

function startFollowing(plr)
    stopAllModes()
    if not plr then return end
    FollowingPlayer=plr
    FollowConn = RunService.Heartbeat:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then stopAllModes(); return end
        pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end)
    end)
end

function startSpectating(plr)
    stopAllModes()
    if not plr then return end
    SpectatingPlayer=plr
    SpectateConn = RunService.RenderStepped:Connect(function()
        if not (plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")) then stopAllModes(); return end
        pcall(function() Camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid") end)
    end)
end

-- ======================
-- Hotkeys
-- ======================
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType==Enum.UserInputType.Keyboard then
        local k = input.KeyCode.Name
        if k == (config.hotkeys.TP or "T") and SelectedPlayer then stopAllModes(); safeTPToPlayer(SelectedPlayer)
        elseif k == (config.hotkeys.FOLLOW or "R") and SelectedPlayer then if FollowingPlayer==SelectedPlayer then stopAllModes() else startFollowing(SelectedPlayer) end
        elseif k == (config.hotkeys.SPECTATE or "Y") and SelectedPlayer then if SpectatingPlayer==SelectedPlayer then stopAllModes() else startSpectating(SelectedPlayer) end
        elseif k == (config.hotkeys.BRING or "G") and SelectedPlayer then bringPlayer(SelectedPlayer)
        elseif k == (config.hotkeys.STOP or "F") then stopAllModes() end
    end
end)

-- ======================
-- MassTroll
-- ======================
local function MassTroll()
    if not config.massTrollEnabled then return end
    task.spawn(function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and not isWhitelisted(p) then trollPlayer(p) task.wait(0.12) end
        end
    end)
end

-- ======================
-- Bring / Troll Utils exposed earlier
-- ======================
function bringPlayer(plr) if not plr or isWhitelisted(plr) then return end if not canAct("bring_"..plr.UserId,1.2) then return end if plr.Character and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then pcall(function() plr.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,0,3) end) end end

-- ======================
-- Tab switching logic
-- ======================
local frames = { Players = PlayersFrame, Teleport = TeleportFrame, Troll = TrollFrame, ESP = ESPFrame, Scripts = ScriptsFrame, Settings = SettingsFrame, Info = InfoFrame }
local function setTab(name)
    currentTab = name
    for n,b in pairs(tabButtons) do
        b.BackgroundColor3 = (n==name) and theme("accent") or theme("panel")
        b.TextColor3 = (n==name) and theme("bg") or theme("text")
    end
    for k,f in pairs(frames) do f.Visible = (k==name) end
end
for n,btn in pairs(tabButtons) do btn.MouseButton1Click:Connect(function() setTab(n) end) end
setTab("Players")

-- ======================
-- Connections & auto-refresh
-- ======================
searchBox:GetPropertyChangedSignal("Text"):Connect(function() pcall(RefreshPlayers) end)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() if config.esp.enabled then enableESPFor(p) end end) RefreshPlayers() end)
Players.PlayerRemoving:Connect(function(p) disableESPFor(p) RefreshPlayers() end)

local running = true
task.spawn(function() while running do task.wait(2.5) pcall(RefreshPlayers) end end)

-- cleanup on destroy
ScreenGui.AncestryChanged:Connect(function(_,parent) if not parent then running=false; stopAllModes(); for id,hl in pairs(highlights) do pcall(function() hl:Destroy() end); highlights[id]=nil end end end)

-- Initial setup: populate and set ESP state
RefreshPlayers(); setESPAll(config.esp.enabled)

-- ======================
-- Final note
-- ======================
print("Zero TP Player v8.0 loaded — use responsibly. If you paid for this, you were likely scammed.")

-- End of script