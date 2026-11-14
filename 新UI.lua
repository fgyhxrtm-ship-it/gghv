-- [[此UI由风御 X制作]]
-- by 殺脚本团队.风御 
-- 若白
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local defer = (task and task.defer) or function(fn)
    if type(fn) ~= "function" then return end
    task.spawn(function()
        task.wait()
        local ok, err = pcall(fn)
        if not ok then warn("[defer]", err) end
    end)
end

local DepthOfFieldEffect = Instance.new("DepthOfFieldEffect")
DepthOfFieldEffect.Name = "FengBlurDOF"
DepthOfFieldEffect.Enabled = false

local function safeDisconnect(conn) if conn then pcall(conn.Disconnect, conn) end end

local Animation = {}
do
    local _RunService = RunService
    local _state = setmetatable({}, {__mode = "k"})
    function Animation.Apply(theme, root, shineEnabled)
        if not root then return end
        local st = _state[root]
        if st and st.conn then safeDisconnect(st.conn) end
        st = {conn = nil}; _state[root] = st
        if not theme or not shineEnabled or not theme.ShineEnabled or not theme.Shine then return end
        local cfg = theme.Shine
        local speed = cfg.Speed or 0.5
        local rotSpeed = cfg.RotationSpeed or 25
        local colorSeq = cfg.ColorSequence
        local doStroke = theme.StrokeShine and theme.StrokeDark and theme.Accent
        st.conn = _RunService.RenderStepped:Connect(function(dt)
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("UIGradient") then
                    local t = (obj:GetAttribute("_t") or 0) + dt * speed
                    obj:SetAttribute("_t", t)
                    obj.Rotation = (t * rotSpeed) % 360
                    obj.Offset = Vector2.new(math.sin(t * 0.6) * 0.18, obj.Offset.Y)
                    if colorSeq then obj.Color = colorSeq end
                elseif doStroke and obj:IsA("UIStroke") then
                    local t = (obj:GetAttribute("_t") or 0) + dt * speed
                    obj:SetAttribute("_t", t)
                    local pulse = (math.sin(t) + 1) / 2
                    obj.Thickness = 1.25 + pulse * 1.25
                    obj.Color = theme.StrokeDark:Lerp(theme.Accent, pulse)
                end
            end
        end)
        return st.conn
    end
end

local Themes = {
    Dark = { Main=Color3.fromRGB(13,13,13), Top=Color3.fromRGB(28,28,30), Text=Color3.fromRGB(240,240,245), Accent=Color3.fromRGB(80,140,255), Stroke=Color3.fromRGB(45,45,48), SubText=Color3.fromRGB(160,160,170), Element=Color3.fromRGB(45,45,50), Hover=Color3.fromRGB(60,60,70), ShineEnabled=true, Shine={Speed=0.4,RotationSpeed=20,ColorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(40,40,40)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(105,105,105)),ColorSequenceKeypoint.new(1,Color3.fromRGB(40,40,40))})}, StrokeShine=true, StrokeDark=Color3.fromRGB(40,40,40) },
}
local CurrentTheme = Themes.Dark

local SapphireStyle = {
    WindowTransparency = 0.06,
    SurfaceTransparency = 0.30,
    StrokeTransparency = 0.55,
    Radius = 12,
    GradientRotation = 45,
    Background = Color3.fromRGB(6, 6, 9),
    BackgroundAlt = Color3.fromRGB(36, 38, 46),
    Surface = Color3.fromRGB(12, 12, 16),
    Elevated = Color3.fromRGB(24, 25, 32),
    Stroke = Color3.fromRGB(88, 92, 110),
    Divider = Color3.fromRGB(52, 54, 66),
}

local Registry = {}
local ConfigObjects = {}
local ThemeListeners = {}
local function clamp(v, min, max) return math.max(min, math.min(max, v)) end
local function AddToRegistry(obj, prop, key)
    local val = CurrentTheme[key] or Themes.Dark[key] or Color3.new(1,1,1)
    table.insert(Registry, {Object = obj, Property = prop, Type = key})
    obj[prop] = val
end
local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function SerializeValue(v)
    if typeof(v) == "Color3" then
        return { __t = "Color3", hex = v:ToHex() }
    elseif type(v) == "table" then
        local o = {}
        for k, val in pairs(v) do o[k] = SerializeValue(val) end
        return o
    end
    return v
end

local function DeserializeValue(v)
    if type(v) == "table" then
        if v.__t == "Color3" and type(v.hex) == "string" then
            local ok, c = pcall(Color3.fromHex, v.hex)
            return ok and c or Color3.new(1, 1, 1)
        end
        local o = {}
        for k, val in pairs(v) do o[k] = DeserializeValue(val) end
        return o
    end
    return v
end

local ConfigIdCounter = 0
local function NewConfigId(prefix, name)
    ConfigIdCounter = ConfigIdCounter + 1
    return tostring(prefix) .. "::" .. tostring(name or "") .. "::" .. tostring(ConfigIdCounter)
end

local TextGradient = {
    Enabled = true, Time = 0, Accumulator = 0,
    Labels = {}, Objects = {}, Hooks = {}, Skipped = {},
}

function TextGradient:Skip(Label)
    if not Label then return end
    table.insert(TextGradient.Skipped, Label)
    local g = Label:FindFirstChild("FengTextGrad")
    if g then g:Destroy() end
    for i = #TextGradient.Labels, 1, -1 do
        if TextGradient.Labels[i] == Label then table.remove(TextGradient.Labels, i) end
    end
end

function TextGradient:IsSkipped(Label)
    return table.find(TextGradient.Skipped, Label) ~= nil
end

function TextGradient:_Apply(Label)
    if not Label or not Label.Parent then return end
    if TextGradient:IsSkipped(Label) then return end
    local Gradient = Label:FindFirstChild("FengTextGrad")
    if not TextGradient.Enabled then
        if Gradient then Gradient:Destroy() end
        return
    end
    if not Gradient then
        Gradient = Instance.new("UIGradient")
        Gradient.Name = "FengTextGrad"
        Gradient.Parent = Label
    end
    local Accent = CurrentTheme.Accent or Color3.fromRGB(80, 140, 255)
    local SweepX = ((TextGradient.Time * 0.9) % 2) - 1
    Gradient.Rotation = 0
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Accent:Lerp(Color3.new(1, 1, 1), 0.2)),
        ColorSequenceKeypoint.new(0.55, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Accent:Lerp(Color3.new(1, 1, 1), 0.35)),
    })
    Gradient.Offset = Vector2.new(SweepX, 0)
    if not table.find(TextGradient.Objects, Gradient) then
        table.insert(TextGradient.Objects, Gradient)
    end
    return Gradient
end

function TextGradient:Add(Label)
    if not Label then return Label end
    if TextGradient:IsSkipped(Label) then return Label end
    if not table.find(TextGradient.Labels, Label) then
        table.insert(TextGradient.Labels, Label)
    end
    TextGradient:_Apply(Label)
    return Label
end

function TextGradient:RefreshAll()
    table.clear(TextGradient.Objects)
    for Index = #TextGradient.Labels, 1, -1 do
        local Label = TextGradient.Labels[Index]
        if Label and Label.Parent then
            TextGradient:_Apply(Label)
        else
            table.remove(TextGradient.Labels, Index)
        end
    end
end

function TextGradient:SetEnabled(Enabled)
    TextGradient.Enabled = Enabled == true
    if not TextGradient.Enabled then TextGradient.Accumulator = 0 end
    TextGradient:RefreshAll()
end

function TextGradient:Animate(dt)
    if not TextGradient.Enabled then return end
    TextGradient.Accumulator = TextGradient.Accumulator + (dt or 0)
    if TextGradient.Accumulator < (1 / 30) then return end
    local ResolvedDt = TextGradient.Accumulator
    TextGradient.Accumulator = 0
    TextGradient.Time = TextGradient.Time + ResolvedDt
    local SweepX = ((TextGradient.Time * 0.9) % 2) - 1
    local Offset = Vector2.new(SweepX, 0)
    for Index = #TextGradient.Objects, 1, -1 do
        local Gradient = TextGradient.Objects[Index]
        if Gradient and Gradient.Parent then
            Gradient.Rotation = 0
            Gradient.Offset = Offset
        else
            table.remove(TextGradient.Objects, Index)
        end
    end
end

function TextGradient:AttachHook(root)
    if not root then return end
    local conn = root.DescendantAdded:Connect(function(Object)
        if Object:IsA("TextLabel") or Object:IsA("TextBox") or Object:IsA("TextButton") then
            defer(function()
                if Object.Parent then TextGradient:Add(Object) end
            end)
        end
    end)
    table.insert(TextGradient.Hooks, conn)
    task.spawn(function()
        for _, Object in ipairs(root:GetDescendants()) do
            if Object:IsA("TextLabel") or Object:IsA("TextBox") or Object:IsA("TextButton") then
                TextGradient:Add(Object)
            end
        end
    end)
end

RunService.RenderStepped:Connect(function(dt) TextGradient:Animate(dt) end)

local FengUI = {}
FengUI.TextGradient = TextGradient

function FengUI:SetTheme(name)
    if Themes[name] then
        CurrentTheme = Themes[name]
        for _, r in pairs(Registry) do if r.Object then Tween(r.Object, {[r.Property] = CurrentTheme[r.Type]}) end end
        for _, fn in pairs(ThemeListeners) do pcall(fn) end
        TextGradient:RefreshAll()
    end
end

function FengUI:SaveConfig(name, folder)
    name   = tostring(name or "config")
    folder = tostring(folder or "款脚本配置")
    local ok, err = pcall(function()
        if not isfolder(folder) then makefolder(folder) end
        local data = {}
        for id, obj in pairs(ConfigObjects) do
            if obj then
                local v
                if type(obj.Get) == "function" then
                    local ok2, got = pcall(obj.Get)
                    if ok2 then v = got end
                else
                    v = obj.Value
                end
                if v ~= nil then
                    data[id] = SerializeValue(v)
                end
            end
        end
        local encoded = HttpService:JSONEncode(data)
        writefile(folder.."/"..name..".json", encoded)
    end)
    if not ok then warn("SaveConfig error:", err) end
    return ok
end

function FengUI:LoadConfig(path)
    if type(path) ~= "string" then return false end
    if not pcall(isfile, path) then return false end
    if not isfile(path) then return false end

    local ok, raw = pcall(readfile, path)
    if not ok or not raw then return false end

    local ok2, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok2 or type(decoded) ~= "table" then return false end

    FengUI._loading = true
    for id, rawVal in pairs(decoded) do
        local obj = ConfigObjects[id]
        if obj and type(obj.Set) == "function" then
            local value = DeserializeValue(rawVal)
            pcall(function() obj.Set(value) end)
        end
    end
    FengUI._loading = false
    return true
end

local MediaManager = {Folder = "FengMediaCache"}
function MediaManager:SetFolder(f) self.Folder = f end
function MediaManager:_init(sub)
    pcall(function()
        if not isfolder(self.Folder) then makefolder(self.Folder) end
        local p = self.Folder.."/"..sub
        if not isfolder(p) then makefolder(p) end
    end)
end
function MediaManager:_rname(ext)
    local s = "abcdefghijklmnopqrstuvwxyz0123456789"
    local n = ""
    for _=1,12 do local i=math.random(1,#s) n=n..s:sub(i,i) end
    return n.."."..ext
end
function MediaManager:Audio(src, noDownload)
    if type(src) ~= "string" or src == "" then return "" end
    if src:match("^rbxassetid://") or src:match("^rbxasset://") then return src end
    if src:match("^%d+$") then return "rbxassetid://"..src end
    if not src:match("^https?://") then return "" end
    local ext = (src:match("%.(%a+)%??[^/]*$") or "mp3"):lower()
    if not ({mp3=1,ogg=1,wav=1,flac=1})[ext] then ext = "mp3" end
    self:_init("audio")
    local dir = self.Folder.."/audio"
    local mapPath = dir.."/_map.json"
    local hs = HttpService
    local map = {}
    pcall(function() if isfile(mapPath) then local ok,d = pcall(hs.JSONDecode, hs, readfile(mapPath)); if ok and type(d) == "table" then map = d end end end)
    local key = tostring(#src).."_"..src:sub(1,40):gsub("[^%w]","")
    if map[key] then
        local cp = dir.."/"..map[key]
        if isfile(cp) then local ok,a = pcall(getcustomasset, cp); if ok and a and a ~= "" then return a end end
        map[key] = nil
    end
    if noDownload then return nil end
    local fname = self:_rname(ext)
    local path = dir.."/"..fname
    local body = nil
    local reqOk = pcall(function()
        local req = (syn and syn.request) or http_request or request
        local r = req({Url=src, Method="GET", Headers={["User-Agent"]="Roblox/WinInet"}})
        if r and r.Body and #r.Body > 128 then
            local peek = r.Body:sub(1,15):lower()
            if peek:find("<!doctype") or peek:find("<html") then return end
            body = r.Body; writefile(path, body)
        end
    end)
    if reqOk and body and isfile(path) then
        local ok2,a = pcall(getcustomasset, path)
        if ok2 and a and a ~= "" then
            map[key] = fname
            pcall(function() local ok3,enc = pcall(hs.JSONEncode, hs, map); if ok3 then writefile(mapPath, enc) end end)
            return a
        end
    end
    return ""
end
function MediaManager:Video(src)
    if type(src) ~= "string" or src == "" then return "" end
    if src:match("^rbxassetid://") or src:match("^rbxasset://") then return src end
    if src:match("^%d+$") then return "rbxassetid://"..src end
    if not src:match("^https?://") then return "" end
    local ext = (src:match("%.(%a+)%??[^/]*$") or "webm"):lower()
    if not ({webm=1,mp4=1,ogg=1,mov=1})[ext] then ext = "webm" end
    if ext == "mp4" or ext == "mov" then ext = "webm" end
    self:_init("videos")
    local dir = self.Folder.."/videos"
    local mapPath = dir.."/_map.json"
    local hs = HttpService
    local map = {}
    pcall(function() if isfile(mapPath) then local ok,d = pcall(hs.JSONDecode, hs, readfile(mapPath)); if ok and type(d) == "table" then map = d end end end)
    local key = tostring(#src).."_"..src:sub(1,40):gsub("[^%w]","")
    if map[key] then
        local cp = dir.."/"..map[key]
        if isfile(cp) then local ok,a = pcall(getcustomasset, cp); if ok and a and a ~= "" then return a end end
        map[key] = nil
    end
    local fname = self:_rname(ext)
    local path = dir.."/"..fname
    local body = nil
    local reqOk = pcall(function()
        local req = (syn and syn.request) or http_request or request
        local r = req({Url=src, Method="GET", Headers={["User-Agent"]="Roblox/WinInet"}})
        if r and r.Body and #r.Body > 512 then
            local peek = r.Body:sub(1,15):lower()
            if peek:find("<!doctype") or peek:find("<html") then return end
            body = r.Body; writefile(path, body)
        end
    end)
    if reqOk and body and isfile(path) then
        local ok2,a = pcall(getcustomasset, path)
        if ok2 and a and a ~= "" then
            map[key] = fname
            pcall(function() local ok3,enc = pcall(hs.JSONEncode, hs, map); if ok3 then writefile(mapPath, enc) end end)
            return a
        end
    end
    return ""
end
function MediaManager:Image(src)
    if type(src) ~= "string" or src == "" then return "" end
    if src:match("^rbxassetid://") or src:match("^rbxasset://") then return src end
    if src:match("^%d+$") then return "rbxassetid://"..src end
    if not src:match("^https?://") then return "" end
    local ext = (src:match("%.(%a+)%??[^/]*$") or "png"):lower()
    if not ({png=1,jpg=1,jpeg=1,webp=1,gif=1})[ext] then ext = "png" end
    self:_init("images")
    local dir = self.Folder.."/images"
    local mapPath = dir.."/_map.json"
    local hs = HttpService
    local map = {}
    pcall(function() if isfile(mapPath) then local ok,d = pcall(hs.JSONDecode, hs, readfile(mapPath)); if ok and type(d) == "table" then map = d end end end)
    local key = tostring(#src).."_"..src:sub(1,40):gsub("[^%w]","")
    if map[key] then
        local cp = dir.."/"..map[key]
        if isfile(cp) then local ok,a = pcall(getcustomasset, cp); if ok and a and a ~= "" then return a end end
        map[key] = nil
    end
    local fname = self:_rname(ext)
    local path = dir.."/"..fname
    local body = nil
    local reqOk = pcall(function()
        local req = (syn and syn.request) or http_request or request
        local r = req({Url=src, Method="GET", Headers={["User-Agent"]="Roblox/WinInet"}})
        if r and r.Body and #r.Body > 128 then
            local peek = r.Body:sub(1,15):lower()
            if peek:find("<!doctype") or peek:find("<html") then return end
            body = r.Body; writefile(path, body)
        end
    end)
    if reqOk and body and isfile(path) then
        local ok2,a = pcall(getcustomasset, path)
        if ok2 and a and a ~= "" then
            map[key] = fname
            pcall(function() local ok3,enc = pcall(hs.JSONEncode, hs, map); if ok3 then writefile(mapPath, enc) end end)
            return a
        end
    end
    return ""
end

local function createLockOverlay(parent, defaultTitle)
    local cornerRadius = UDim.new(0, 8)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("UICorner") then cornerRadius = child.CornerRadius; break end
    end
    local lockFrame = Instance.new("TextButton")
    lockFrame.Size = UDim2.new(1, 0, 1, 0)
    lockFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lockFrame.BackgroundTransparency = 0.6
    lockFrame.Text = ""; lockFrame.AutoButtonColor = false
    lockFrame.Active = true; lockFrame.Visible = false; lockFrame.ZIndex = 10
    lockFrame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius; corner.Parent = lockFrame
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1; container.Parent = lockFrame
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8); layout.Parent = container
    local lockIcon = Instance.new("ImageLabel")
    lockIcon.Size = UDim2.new(0, 18, 0, 18)
    lockIcon.BackgroundTransparency = 1
    lockIcon.Image = "rbxassetid://12060512624"
    lockIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    lockIcon.ImageTransparency = 0.1; lockIcon.Parent = container
    local lockLabel = Instance.new("TextLabel")
    lockLabel.Size = UDim2.new(0, 0, 0, 20)
    lockLabel.BackgroundTransparency = 1
    lockLabel.Font = Enum.Font.GothamBold
    lockLabel.Text = defaultTitle or "已锁定"
    lockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockLabel.TextTransparency = 0.2; lockLabel.TextSize = 14
    lockLabel.AutomaticSize = Enum.AutomaticSize.X
    lockLabel.Parent = container
    TextGradient:Skip(lockLabel)
    return lockFrame, lockLabel
end

local function formatIconAsset(asset, default)
    if asset == nil or asset == "" then return default end
    if type(asset) == "number" then
        return "rbxassetid://" .. tostring(asset)
    elseif type(asset) == "string" then
        if tonumber(asset) then
            return "rbxassetid://" .. asset
        elseif asset:match("^rbxassetid://") or asset:match("^rbxasset://") or asset:match("^http") then
            return asset
        else
            return "rbxassetid://" .. asset
        end
    end
    return default
end

local CHESSBOARD_IMAGE = "http://www.roblox.com/asset/?id=14204231522"

local function createSectionBuilder(parent, contentContainer, elementWidth, windowCount, window)
    local win = window
    local padding = parent:FindFirstChild("SectionPadding")
    if not padding then
        padding = Instance.new("UIPadding")
        padding.Name = "SectionPadding"
        padding.PaddingLeft = UDim.new(0.04, 0); padding.Parent = parent
    end
    local child = {}

    local function miRow(parentFrame, height)
        height = height or 42
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, height)
        row.BackgroundTransparency = 1; row.BorderSizePixel = 0
        row.ClipsDescendants = false; row.Parent = parentFrame
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -20, 0, 1)
        line.Position = UDim2.new(0, 10, 1, -1)
        line.BackgroundColor3 = CurrentTheme.Stroke
        line.BackgroundTransparency = 0.65; line.BorderSizePixel = 0
        line.Parent = row
        AddToRegistry(line, "BackgroundColor3", "Stroke")
        return row
    end

    local function miIcon(parentFrame, asset, size, x, y)
        size = size or 18
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, size, 0, size)
        icon.Position = UDim2.new(0, x or 15, 0, y or 12)
        icon.BackgroundTransparency = 1; icon.BorderSizePixel = 0
        icon.ImageColor3 = CurrentTheme.Text
        icon.ImageTransparency = 0.25
        icon.ScaleType = Enum.ScaleType.Fit
        if type(asset) == "number" then icon.Image = "rbxassetid://"..tostring(asset)
        elseif type(asset) == "string" and asset ~= "" then
            if tonumber(asset) then icon.Image = "rbxassetid://"..asset
            elseif asset:match("^rbxassetid://") or asset:match("^http") or asset:match("^rbxasset://") then icon.Image = asset
            else icon.Image = "rbxassetid://"..asset end
        end
        icon.Parent = parentFrame
        AddToRegistry(icon, "ImageColor3", "Text")
        return icon
    end

    local function miLabel(parentFrame, text, x, y, w, size)
        local lbl = Instance.new("TextLabel")
        lbl.Text = text or ""
        lbl.Position = UDim2.new(0, x or 15, 0, y or 12)
        lbl.Size = w or UDim2.new(1, -30, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = size or 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = parentFrame
        AddToRegistry(lbl, "TextColor3", "Text")
        return lbl
    end

    local function safeConfig(config)
        if type(config) ~= "table" then
            return { Name = tostring(config or "") }
        end
        return config
    end

    child.Button = function(_, config)
        config = safeConfig(config)
        local btnText = config.Name or config.Text or ""
        local callback = config.Callback or function() end
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local TitleLbl = miLabel(Tile, btnText, 15, 12, UDim2.new(1, -30, 0, 18), 13)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.BackgroundTransparency = 1; ClickBtn.Text = ""
        ClickBtn.AutoButtonColor = false; ClickBtn.Parent = Tile
        ClickBtn.Active = not locked
        local function updateLock(state) locked = state; lockFrame.Visible = state; ClickBtn.Active = not state end
        ClickBtn.MouseEnter:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 0.65}, 0.15) end end)
        ClickBtn.MouseLeave:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 1}, 0.15) end end)
        ClickBtn.MouseButton1Down:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 0.45}, 0.08) end end)
        ClickBtn.MouseButton1Up:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 0.65}, 0.08) end end)
        ClickBtn.MouseButton1Click:Connect(function() if not locked then callback() end end)
        local self = {}
        function self.UpdateText(t) TitleLbl.Text = t end
        function self.SetVisible(v) Tile.Visible = v end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Toggle = function(_, config)
        config = safeConfig(config)
        local toggleText = config.Name or ""
        local Enabled = config.Value or false
        local callback = config.Callback or function() end
        local controlId = NewConfigId("Toggle", toggleText)
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local TitleLbl = miLabel(Tile, toggleText, 15, 12, UDim2.new(1, -75, 0, 18), 13)
        local Switch = Instance.new("Frame")
        Switch.Size = UDim2.new(0, 30, 0, 18)
        Switch.Position = UDim2.new(1, -41, 0.5, -9)
        Switch.BackgroundColor3 = Enabled and CurrentTheme.Accent or Color3.fromRGB(10, 13, 21)
        Switch.BorderSizePixel = 0; Switch.Parent = Tile
        Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
        local SwStroke = Instance.new("UIStroke")
        SwStroke.Thickness = 1
        SwStroke.Transparency = Enabled and 1 or 0.65
        SwStroke.Color = CurrentTheme.Stroke; SwStroke.Parent = Switch
        table.insert(ThemeListeners, function() SwStroke.Color = CurrentTheme.Stroke; if not Enabled then SwStroke.Transparency = 0.65 end end)
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 16, 0, 16)
        Dot.Position = Enabled and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 1, 0.5, -8)
        Dot.BackgroundColor3 = Color3.new(1, 1, 1); Dot.BorderSizePixel = 0
        Dot.Parent = Switch
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.BackgroundTransparency = 1; ClickBtn.Text = ""
        ClickBtn.AutoButtonColor = false; ClickBtn.Parent = Tile
        ClickBtn.Active = not locked
        local function updateLock(state) locked = state; lockFrame.Visible = state; ClickBtn.Active = not state end
        local function ApplyUI(v)
            Enabled = v
            if Enabled then
                Tween(Switch, {BackgroundColor3 = CurrentTheme.Accent}, 0.18)
                Tween(SwStroke, {Transparency = 1}, 0.18)
                Tween(Dot, {Position = UDim2.new(1, -17, 0.5, -8)}, 0.18)
            else
                Tween(Switch, {BackgroundColor3 = Color3.fromRGB(10, 13, 21)}, 0.18)
                Tween(SwStroke, {Transparency = 0.65}, 0.18)
                Tween(Dot, {Position = UDim2.new(0, 1, 0.5, -8)}, 0.18)
            end
        end
        ConfigObjects[controlId] = {
            Type = "Toggle",
            Value = Enabled,
            Get = function() return Enabled end,
            Set = function(v)
                if locked then return end
                v = v == true
                ApplyUI(v)
                ConfigObjects[controlId].Value = v
                callback(v)
            end,
        }
        ClickBtn.MouseEnter:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 0.65}, 0.15) end end)
        ClickBtn.MouseLeave:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 1}, 0.15) end end)
        ClickBtn.MouseButton1Click:Connect(function() if locked then return end; ApplyUI(not Enabled); ConfigObjects[controlId].Value = Enabled; callback(Enabled) end)
        local self = {}
        function self.GetValue() return Enabled end
        function self.SetValue(v) if not locked then ConfigObjects[controlId].Set(v) end end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        function self.SetVisible(v) Tile.Visible = v end
        return self
    end

    child.Slider = function(_, config)
        config = safeConfig(config)
        local sliderText = config.Name or ""
        local valueTable = config.Value or {}
        local min = valueTable.Min
        local max = valueTable.Max
        local default = valueTable.Default
        local callback = config.Callback or function() end
        local unlimited = (min == nil and max == nil)
        min = tonumber(min); max = tonumber(max)
        local Rounding = config.Rounding or 0
        local Val = tonumber(default) or (min or 0)
        local controlId = NewConfigId("Slider", sliderText)
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local rowH = 22
        local TitleLbl = miLabel(Tile, sliderText, 15, 0, UDim2.new(0, 90, 0, rowH), 13)
        TitleLbl.Position = UDim2.new(0, 15, 0.5, -rowH/2)
        local numW = unlimited and 72 or 52
        local ValueFrame = Instance.new("Frame")
        ValueFrame.Size = UDim2.new(0, numW, 0, rowH)
        ValueFrame.Position = UDim2.new(1, -(numW + 10), 0.5, -rowH/2)
        ValueFrame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        ValueFrame.BackgroundTransparency = 0; ValueFrame.BorderSizePixel = 0
        ValueFrame.ClipsDescendants = true; ValueFrame.Parent = Tile
        Instance.new("UICorner", ValueFrame).CornerRadius = UDim.new(0, 4)
        local ValueStroke = Instance.new("UIStroke")
        ValueStroke.Thickness = 1; ValueStroke.Transparency = 0.65
        ValueStroke.Color = CurrentTheme.Stroke; ValueStroke.Parent = ValueFrame
        table.insert(ThemeListeners, function() ValueStroke.Color = CurrentTheme.Stroke end)
        local ValueLabel = Instance.new("TextBox")
        ValueLabel.Text = tostring(Val)
        ValueLabel.Size = UDim2.new(1, 0, 1, 0)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.TextSize = 12
        ValueLabel.TextColor3 = CurrentTheme.Text
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Center
        ValueLabel.TextYAlignment = Enum.TextYAlignment.Center
        ValueLabel.ClearTextOnFocus = false
        ValueLabel.Parent = ValueFrame
        AddToRegistry(ValueLabel, "TextColor3", "Text")
        TextGradient:Skip(ValueLabel)
        ValueLabel.Focused:Connect(function() Tween(ValueStroke, {Transparency = 0.2}, 0.15) end)
        local trackLeft = 15 + 90 + 12
        local trackRight = numW + 10 + 10
        local Track, Fill, Knob, Bar
        if not unlimited then
            Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -(trackLeft + trackRight), 0, 6)
            Track.Position = UDim2.new(0, trackLeft, 0.5, -3)
            Track.BackgroundColor3 = CurrentTheme.Stroke
            Track.BorderSizePixel = 0; Track.Parent = Tile
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
            AddToRegistry(Track, "BackgroundColor3", "Stroke")
            local initP = (min and max and max ~= min) and ((Val - min) / (max - min)) or 0
            Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(initP, 0, 1, 0)
            Fill.BackgroundColor3 = CurrentTheme.Accent
            Fill.BorderSizePixel = 0; Fill.Parent = Track
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            AddToRegistry(Fill, "BackgroundColor3", "Accent")
            Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 12, 0, 12)
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            Knob.Position = UDim2.new(initP, 0, 0.5, 0)
            Knob.BackgroundColor3 = Color3.new(1, 1, 1)
            Knob.BorderSizePixel = 0; Knob.ZIndex = 3; Knob.Parent = Track
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            Bar = Instance.new("TextButton")
            Bar.Size = UDim2.new(1, 0, 0, 20)
            Bar.Position = UDim2.new(0, 0, 0.5, -10)
            Bar.BackgroundTransparency = 1; Bar.Text = ""
            Bar.ZIndex = 4; Bar.Parent = Track
        end
        local dragging = false
        local function Round(n, decimals)
            local factor = 10^decimals
            return math.floor(n * factor + 0.5) / factor
        end
        local function UpdateSlider(val)
            if unlimited then
                Val = tonumber(val) or Val
                ValueLabel.Text = tostring(Val)
                if ConfigObjects[controlId] then ConfigObjects[controlId].Value = Val end
                callback(Val)
                return
            end
            val = math.clamp(val, min, max)
            val = Round(val, Rounding)
            local ratio = (val - min) / (max - min)
            TweenService:Create(Fill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Position = UDim2.new(ratio, 0, 0.5, 0)}):Play()
            ValueLabel.Text = tostring(val)
            Val = val
            if ConfigObjects[controlId] then ConfigObjects[controlId].Value = val end
            callback(val)
            return val
        end
        local function GetValueFromInput(input)
            if unlimited or not Track then return Val end
            local absX = Track.AbsolutePosition.X
            local absW = Track.AbsoluteSize.X
            local ratio = math.clamp((input.Position.X - absX) / absW, 0, 1)
            return ratio * (max - min) + min
        end
        if Bar then
            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(GetValueFromInput(input))
                end
            end)
            Bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(GetValueFromInput(input))
                end
            end)
        end
        ValueLabel.FocusLost:Connect(function()
            Tween(ValueStroke, {Transparency = 0.65}, 0.15)
            local typed = tonumber(ValueLabel.Text)
            if typed then UpdateSlider(typed) else ValueLabel.Text = tostring(Val) end
        end)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        if Bar then Bar.Active = not locked end
        ValueLabel.Active = not locked
        local function updateLock(state)
            locked = state
            lockFrame.Visible = state
            if Bar then Bar.Active = not state end
            ValueLabel.Active = not state
        end
        ConfigObjects[controlId] = {
            Type = "Slider",
            Value = Val,
            Get = function() return Val end,
            Set = function(v)
                if locked then return end
                local n = tonumber(v)
                if n then UpdateSlider(n) end
            end,
        }
        table.insert(ThemeListeners, function()
            if Fill then Fill.BackgroundColor3 = CurrentTheme.Accent end
            if Track then Track.BackgroundColor3 = CurrentTheme.Stroke end
            ValueLabel.TextColor3 = CurrentTheme.Text
        end)
        UpdateSlider(Val)
        local self = {}
        function self.GetValue() return Val end
        function self.SetValue(v) if not locked then ConfigObjects[controlId].Set(v) end end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        function self.SetVisible(v) Tile.Visible = v end
        return self
    end

    child.Dropdown = function(_, config)
        config = safeConfig(config)
        local dropText = config.Name or ""
        local options = config.Values or {}
        local selectedValue = config.Value
        local multi = config.Multi == true
        local callback = config.Callback or function() end
        local controlId = NewConfigId("Dropdown", dropText)
        local parent = config.Parent or contentHolder
        local selected = multi and {} or nil
        local function initSelected()
            if multi then
                if type(selectedValue) == "table" then
                    selected = {}
                    for _, v in ipairs(selectedValue) do if table.find(options, v) then table.insert(selected, v) end end
                else selected = {} end
            else
                if selectedValue and table.find(options, selectedValue) then selected = selectedValue else selected = options[1] or "" end
            end
        end
        initSelected()
        local Dropped = false
        local Btn = miRow(parent, 42)
        local Lbl = miLabel(Btn, "", 15, 12, UDim2.new(1, -50, 0, 18), 13)
        local Icon = Instance.new("ImageLabel")
        Icon.Image = "rbxassetid://18865373378"
        Icon.Size = UDim2.new(0, 20, 0, 20)
        Icon.Position = UDim2.new(1, -30, 0.5, -10)
        Icon.BackgroundTransparency = 1; Icon.Parent = Btn
        AddToRegistry(Icon, "ImageColor3", "Accent")
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.BackgroundTransparency = 1; ClickBtn.Text = ""
        ClickBtn.AutoButtonColor = false; ClickBtn.Parent = Btn
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 0)
        Container.Visible = false; Container.ClipsDescendants = true
        Container.ZIndex = 10
        Container.BackgroundColor3 = CurrentTheme.Main
        Container.BackgroundTransparency = 0.05
        Container.Parent = parent
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)
        local List = Instance.new("UIListLayout")
        List.SortOrder = Enum.SortOrder.LayoutOrder; List.Parent = Container
        local function updateLabel()
            if multi then
                if #selected == 0 then Lbl.Text = dropText..": (无)"
                else Lbl.Text = dropText..": "..table.concat(selected, ", ") end
            else
                Lbl.Text = dropText..": "..tostring(selected)
            end
        end
        updateLabel()
        local optionButtons = {}
        local function rebuildOptions(optList)
            for _, c in ipairs(Container:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            optionButtons = {}
            for _, opt in ipairs(optList) do
                local O = Instance.new("TextButton")
                O.Size = UDim2.new(1, 0, 0, 34)
                O.Text = ""; O.BackgroundTransparency = 1
                O.AutoButtonColor = false; O.Parent = Container
                local check = Instance.new("Frame")
                check.Size = UDim2.new(0, 16, 0, 16)
                check.Position = UDim2.new(0, 10, 0.5, -8)
                check.BackgroundColor3 = CurrentTheme.Accent
                check.BackgroundTransparency = 1
                check.ZIndex = 1; check.Parent = O
                Instance.new("UICorner", check).CornerRadius = UDim.new(0, 4)
                local checkMark = Instance.new("ImageLabel")
                checkMark.Size = UDim2.new(0, 12, 0, 12)
                checkMark.Position = UDim2.new(0.5, 0, 0.5, 0)
                checkMark.AnchorPoint = Vector2.new(0.5, 0.5)
                checkMark.BackgroundTransparency = 1
                checkMark.Image = "rbxassetid://16633109272"
                checkMark.ImageTransparency = 1; checkMark.Parent = check
                AddToRegistry(checkMark, "ImageColor3", "Accent")
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -40, 1, 0)
                label.Position = UDim2.new(0, 36, 0, 0)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamMedium
                label.Text = opt; label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = O
                AddToRegistry(label, "TextColor3", "Text")
                O.MouseEnter:Connect(function() Tween(O, {BackgroundTransparency = 0.1}, 0.15) end)
                O.MouseLeave:Connect(function() Tween(O, {BackgroundTransparency = 1}, 0.15) end)
                local optData = { button = O, label = label, check = check, checkMark = checkMark, value = opt, selected = false }
                table.insert(optionButtons, optData)
                O.MouseButton1Click:Connect(function()
                    if locked then return end
                    if multi then
                        local idx = table.find(selected, opt)
                        if idx then table.remove(selected, idx); optData.selected = false
                        else table.insert(selected, opt); optData.selected = true end
                        optData.check.BackgroundTransparency = optData.selected and 0 or 1
                        optData.checkMark.ImageTransparency = optData.selected and 0 or 1
                        updateLabel()
                        if ConfigObjects[controlId] then ConfigObjects[controlId].Value = selected end
                        callback(selected)
                    else
                        selected = opt
                        for _, d in ipairs(optionButtons) do
                            d.selected = (d.value == opt)
                            d.check.BackgroundTransparency = d.selected and 0 or 1
                            d.checkMark.ImageTransparency = d.selected and 0 or 1
                        end
                        updateLabel()
                        if ConfigObjects[controlId] then ConfigObjects[controlId].Value = selected end
                        callback(selected)
                        Dropped = false
                        Tween(Container, {Size = UDim2.new(1, 0, 0, 0)}, 0.28)
                        Tween(Icon, {Rotation = 0}, 0.28)
                        task.wait(0.3)
                        Container.Visible = false
                    end
                end)
            end
            for _, d in ipairs(optionButtons) do
                if multi then d.selected = table.find(selected, d.value) ~= nil else d.selected = (d.value == selected) end
                d.check.BackgroundTransparency = d.selected and 0 or 1
                d.checkMark.ImageTransparency = d.selected and 0 or 1
            end
            if Dropped then
                local targetHeight = #optionButtons * 34
                Tween(Container, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
            end
        end
        rebuildOptions(options)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Btn, lockedTitle)
        lockFrame.Visible = locked
        ClickBtn.Active = not locked
        local function updateLock(state)
            locked = state; lockFrame.Visible = state; ClickBtn.Active = not state
            if state then Dropped = false; Container.Visible = false; Tween(Container, {Size = UDim2.new(1, 0, 0, 0)}, 0.1) end
        end
        ClickBtn.MouseEnter:Connect(function() if not locked then Tween(Btn, {BackgroundTransparency = 0.65}, 0.15) end end)
        ClickBtn.MouseLeave:Connect(function() if not locked then Tween(Btn, {BackgroundTransparency = 1}, 0.15) end end)
        ClickBtn.MouseButton1Click:Connect(function()
            if locked then return end
            Dropped = not Dropped
            if Dropped then
                Container.Visible = true
                local targetHeight = #optionButtons * 34
                Tween(Container, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.32)
                Tween(Icon, {Rotation = 180}, 0.32)
            else
                Tween(Container, {Size = UDim2.new(1, 0, 0, 0)}, 0.28)
                Tween(Icon, {Rotation = 0}, 0.28)
                task.wait(0.3)
                Container.Visible = false
            end
        end)
        local function isMouseOver(frame)
            if not frame then return false end
            local m = LocalPlayer:GetMouse()
            local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
            return m.X >= ap.X and m.X <= ap.X + as.X and m.Y >= ap.Y and m.Y <= ap.Y + as.Y
        end
        local globalClickConn
        globalClickConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if Dropped and not locked then
                    if not isMouseOver(Container) and not isMouseOver(Btn) then
                        Dropped = false
                        Tween(Container, {Size = UDim2.new(1, 0, 0, 0)}, 0.28)
                        Tween(Icon, {Rotation = 0}, 0.28)
                        task.wait(0.3)
                        Container.Visible = false
                    end
                end
            end
        end)
        ConfigObjects[controlId] = {
            Type = "Dropdown",
            Value = multi and selected or selected,
            Get = function()
                if multi then
                    local copy = {}
                    for _, v in ipairs(selected) do copy[v] = true end
                    return copy
                end
                return selected
            end,
            Set = function(val)
                if locked then return end
                if multi then
                    if type(val) == "table" then
                        selected = {}
                        for k, v in pairs(val) do
                            if v == true and type(k) == "string" then
                                if table.find(options, k) then table.insert(selected, k) end
                            elseif v ~= true and v ~= false then
                                if table.find(options, v) then table.insert(selected, v) end
                            end
                        end
                    else selected = {} end
                else
                    if val and table.find(options, val) then selected = val else selected = options[1] or "" end
                end
                for _, d in ipairs(optionButtons) do
                    if multi then d.selected = table.find(selected, d.value) ~= nil else d.selected = (d.value == selected) end
                    d.check.BackgroundTransparency = d.selected and 0 or 1
                    d.checkMark.ImageTransparency = d.selected and 0 or 1
                end
                updateLabel()
                ConfigObjects[controlId].Value = multi and selected or selected
                callback(selected)
            end,
            Refresh = function(newOptions)
                if locked then return end
                options = newOptions or {}
                selected = multi and {} or (options[1] or "")
                rebuildOptions(options)
                updateLabel()
            end
        }
        local self = {}
        function self.GetValue() return selected end
        function self.SetValue(val) if not locked then ConfigObjects[controlId].Set(val) end end
        function self.Refresh(newOptions) if not locked and ConfigObjects[controlId].Refresh then ConfigObjects[controlId].Refresh(newOptions) end end
        function self.SetVisible(state) Btn.Visible = state end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        table.insert(WindowCleanup or {}, function() safeDisconnect(globalClickConn) end)
        return self
    end

    child.Keybind = function(_, config)
        config = safeConfig(config)
        local keyText = config.Name or ""
        local defaultKey = config.Default or Enum.KeyCode.M
        local mode = config.Mode or "Toggle"
        local callback = config.Callback or function() end
        local controlId = NewConfigId("Keybind", keyText)
        local parent = config.Parent or contentHolder
        local state = { Key = defaultKey.Name, Mode = mode, Toggled = false, IsWaiting = false }
        local Tile = miRow(parent, 42)
        local TitleLbl = miLabel(Tile, keyText, 15, 12, UDim2.new(0.6, 0, 0, 18), 13)
        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.new(0, 0, 0, 30)
        KeyBtn.Position = UDim2.new(1, -10, 0.5, 0)
        KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
        KeyBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        KeyBtn.BackgroundTransparency = 0; KeyBtn.Text = ""
        KeyBtn.AutoButtonColor = false; KeyBtn.Parent = Tile
        KeyBtn.AutomaticSize = Enum.AutomaticSize.X
        Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 5)
        local keyStroke = Instance.new("UIStroke")
        keyStroke.Thickness = 1; keyStroke.Transparency = 0.65
        keyStroke.Color = CurrentTheme.Stroke; keyStroke.Parent = KeyBtn
        table.insert(ThemeListeners, function() keyStroke.Color = CurrentTheme.Stroke end)
        local innerLayout = Instance.new("UIListLayout")
        innerLayout.FillDirection = Enum.FillDirection.Horizontal
        innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        innerLayout.Padding = UDim.new(0, 4)
        innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        innerLayout.Parent = KeyBtn
        local keyPadding = Instance.new("UIPadding")
        keyPadding.PaddingLeft = UDim.new(0, 7); keyPadding.PaddingRight = UDim.new(0, 8)
        keyPadding.Parent = KeyBtn
        local mouseIco = Instance.new("ImageLabel")
        mouseIco.Size = UDim2.fromOffset(13, 13)
        mouseIco.BackgroundTransparency = 1
        mouseIco.Image = "rbxassetid://10734898592"
        mouseIco.ImageTransparency = 0.35
        mouseIco.LayoutOrder = 1; mouseIco.Parent = KeyBtn
        AddToRegistry(mouseIco, "ImageColor3", "Text")
        local KeyLabel = Instance.new("TextLabel")
        KeyLabel.Text = state.Key
        KeyLabel.Size = UDim2.new(0, 0, 0, 14)
        KeyLabel.BackgroundTransparency = 1
        KeyLabel.Font = Enum.Font.GothamMedium
        KeyLabel.TextSize = 13
        KeyLabel.TextColor3 = CurrentTheme.Text
        KeyLabel.AutomaticSize = Enum.AutomaticSize.X
        KeyLabel.LayoutOrder = 2; KeyLabel.Parent = KeyBtn
        AddToRegistry(KeyLabel, "TextColor3", "Text")
        TextGradient:Skip(KeyLabel)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        KeyBtn.Active = not locked
        local function updateLock(st) locked = st; lockFrame.Visible = st; KeyBtn.Active = not st end
        ConfigObjects[controlId] = {
            Type = "Keybind",
            Value = { Key = state.Key, Mode = state.Mode },
            Get = function() return { Key = state.Key, Mode = state.Mode } end,
            Set = function(val)
                if locked then return end
                if type(val) == "table" then
                    state.Key = val.Key or state.Key
                    state.Mode = val.Mode or state.Mode
                    KeyLabel.Text = state.Key
                    ConfigObjects[controlId].Value = { Key = state.Key, Mode = state.Mode }
                elseif type(val) == "string" then
                    state.Key = val; KeyLabel.Text = val
                    ConfigObjects[controlId].Value = { Key = val, Mode = state.Mode }
                end
            end
        }
        local function updateKeyDisplay(newKey)
            if locked then return end
            state.Key = newKey; KeyLabel.Text = newKey
            ConfigObjects[controlId].Value = { Key = newKey, Mode = state.Mode }
        end
        KeyBtn.MouseButton1Click:Connect(function()
            if locked or state.IsWaiting then return end
            state.IsWaiting = true; KeyLabel.Text = "..."
            local input = UserInputService.InputBegan:Wait()
            state.IsWaiting = false
            local newKey = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode.Name ~= "Unknown" then newKey = input.KeyCode.Name end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then newKey = "MouseLeft"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then newKey = "MouseRight" end
            if newKey then updateKeyDisplay(newKey) else KeyLabel.Text = state.Key end
        end)
        local inputConn, inputEndConn
        inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or locked or state.IsWaiting then return end
            if UserInputService:GetFocusedTextBox() then return end
            local key = state.Key
            if state.Mode == "Toggle" then
                if key == "MouseLeft" and input.UserInputType == Enum.UserInputType.MouseButton1 then state.Toggled = not state.Toggled; pcall(callback, state.Toggled)
                elseif key == "MouseRight" and input.UserInputType == Enum.UserInputType.MouseButton2 then state.Toggled = not state.Toggled; pcall(callback, state.Toggled)
                elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key then state.Toggled = not state.Toggled; pcall(callback, state.Toggled) end
            elseif state.Mode == "Hold" then
                if key == "MouseLeft" and input.UserInputType == Enum.UserInputType.MouseButton1 then pcall(callback, true)
                elseif key == "MouseRight" and input.UserInputType == Enum.UserInputType.MouseButton2 then pcall(callback, true)
                elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key then pcall(callback, true) end
            end
        end)
        inputEndConn = UserInputService.InputEnded:Connect(function(input, gpe)
            if gpe or locked or state.IsWaiting then return end
            if state.Mode == "Hold" then
                local key = state.Key
                if key == "MouseLeft" and input.UserInputType == Enum.UserInputType.MouseButton1 then pcall(callback, false)
                elseif key == "MouseRight" and input.UserInputType == Enum.UserInputType.MouseButton2 then pcall(callback, false)
                elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key then pcall(callback, false) end
            end
        end)
        local self = {}
        function self.SetValue(val, newMode) if not locked then ConfigObjects[controlId].Set(val, newMode) end end
        function self.GetValue() return { Key = state.Key, Mode = state.Mode } end
        function self.GetState() return state.Toggled end
        function self.SetMode(newMode) if not locked then state.Mode = newMode; ConfigObjects[controlId].Value = { Key = state.Key, Mode = state.Mode } end end
        function self.Destroy() safeDisconnect(inputConn); safeDisconnect(inputEndConn); Tile:Destroy(); ConfigObjects[controlId] = nil end
        function self.SetVisible(vis) Tile.Visible = vis end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Input = function(_, config)
        config = safeConfig(config)
        local inputText = config.Name or ""
        local default = config.Value or ""
        local callback = config.Callback or function() end
        local options = config or {}
        local placeholder = options.Placeholder or ""
        local finished = options.Finished == true
        local numeric = options.Numeric == true
        local maxLength = options.MaxLength or options.CharacterLimit
        local acceptedChars = options.AcceptedCharacters
        local onChanged = options.OnChanged
        local controlId = NewConfigId("Input", inputText)
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local NameLbl = miLabel(Tile, inputText, 15, 12, UDim2.new(0.6, 0, 0, 18), 13)
        local BoxContainer = Instance.new("Frame")
        BoxContainer.Size = UDim2.new(0.3, 0, 0, 28)
        BoxContainer.Position = UDim2.new(0.7, -10, 0.5, -14)
        BoxContainer.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        BoxContainer.BackgroundTransparency = 0
        BoxContainer.ClipsDescendants = true; BoxContainer.BorderSizePixel = 0
        BoxContainer.Parent = Tile
        Instance.new("UICorner", BoxContainer).CornerRadius = UDim.new(0, 6)
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Thickness = 1; boxStroke.Transparency = 0.65
        boxStroke.Color = CurrentTheme.Stroke; boxStroke.Parent = BoxContainer
        table.insert(ThemeListeners, function() boxStroke.Color = CurrentTheme.Stroke end)
        local InputBox = Instance.new("TextBox")
        InputBox.Text = tostring(default)
        InputBox.PlaceholderText = placeholder
        InputBox.Size = UDim2.new(1, -10, 1, 0)
        InputBox.Position = UDim2.new(0, 5, 0, 0)
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 13
        InputBox.TextXAlignment = Enum.TextXAlignment.Left
        InputBox.ClearTextOnFocus = false
        InputBox.BackgroundTransparency = 1
        InputBox.Parent = BoxContainer
        AddToRegistry(InputBox, "TextColor3", "Accent")
        TextGradient:Skip(InputBox)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        InputBox.Active = not locked
        local function filterText(text)
            if maxLength then text = text:sub(1, maxLength) end
            if numeric then
                local filtered = text:gsub("[^%d%-]", "")
                if filtered:match("^-") then filtered = "-"..filtered:gsub("-", "") else filtered = filtered:gsub("-", "") end
                return filtered
            end
            if type(acceptedChars) == "function" then return acceptedChars(text)
            elseif acceptedChars == "Alphabetic" then return text:gsub("[^a-zA-Z]", "")
            elseif acceptedChars == "AlphaNumeric" then return text:gsub("[^a-zA-Z0-9]", "") end
            return text
        end
        local function updateValue()
            if locked then return end
            local filtered = filterText(InputBox.Text)
            if filtered ~= InputBox.Text then InputBox.Text = filtered end
            if ConfigObjects[controlId] then ConfigObjects[controlId].Value = filtered end
            if callback then pcall(callback, filtered) end
            if onChanged then pcall(onChanged, filtered) end
        end
        InputBox.Focused:Connect(function() if not locked then Tween(boxStroke, {Transparency = 0.2}, 0.15) end end)
        InputBox.FocusLost:Connect(function()
            Tween(boxStroke, {Transparency = 0.65}, 0.15)
            if finished then updateValue() end
        end)
        if not finished then
            InputBox:GetPropertyChangedSignal("Text"):Connect(function()
                if locked then return end
                local raw = InputBox.Text
                local filtered = filterText(raw)
                if filtered ~= raw then InputBox.Text = filtered end
                if ConfigObjects[controlId] then ConfigObjects[controlId].Value = InputBox.Text end
                if callback then pcall(callback, InputBox.Text) end
                if onChanged then pcall(onChanged, InputBox.Text) end
            end)
        end
        local function updateLock(st) locked = st; lockFrame.Visible = st; InputBox.Active = not st end
        ConfigObjects[controlId] = {
            Type = "Input",
            Value = InputBox.Text,
            Get = function() return InputBox.Text end,
            Set = function(val)
                if locked then return end
                local filtered = filterText(tostring(val))
                InputBox.Text = filtered
                ConfigObjects[controlId].Value = filtered
                if callback then pcall(callback, filtered) end
            end
        }
        local self = {}
        function self.UpdateText(newText) if not locked then local f = filterText(tostring(newText)); InputBox.Text = f; ConfigObjects[controlId].Value = f end end
        function self.GetText() return InputBox.Text end
        function self.SetVisible(state) Tile.Visible = state end
        function self.UpdatePlaceholder(p) InputBox.PlaceholderText = p end
        function self.SetValue(val) self.UpdateText(val) end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Textbox = function(_, config)
        config = safeConfig(config)
        local boxText = config.Name or ""
        local placeholder = config.Placeholder or ""
        local callback = config.Callback or function() end
        local controlId = NewConfigId("Textbox", boxText)
        local parent = config.Parent or contentHolder
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 0, 70)
        Frame.BackgroundTransparency = 1; Frame.BorderSizePixel = 0
        Frame.Parent = parent
        local Lbl = miLabel(Frame, boxText, 15, 10, UDim2.new(1, -30, 0, 20), 13)
        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1, -30, 0, 28)
        Box.Position = UDim2.new(0, 15, 0, 35)
        Box.Text = ""; Box.PlaceholderText = placeholder
        Box.Font = Enum.Font.GothamMedium
        Box.TextSize = 12; Box.Parent = Frame
        Box.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        Box.BackgroundTransparency = 0; Box.BorderSizePixel = 0
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
        AddToRegistry(Box, "TextColor3", "Text")
        TextGradient:Skip(Box)
        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Thickness = 1; BoxStroke.Transparency = 0.65
        BoxStroke.Color = CurrentTheme.Stroke; BoxStroke.Parent = Box
        table.insert(ThemeListeners, function() BoxStroke.Color = CurrentTheme.Stroke end)
        Box.Focused:Connect(function() Tween(BoxStroke, {Transparency = 0.2}, 0.15) end)
        Box.FocusLost:Connect(function()
            if locked then return end
            Tween(BoxStroke, {Transparency = 0.65}, 0.15)
            ConfigObjects[controlId].Value = Box.Text
            callback(Box.Text)
        end)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Frame, lockedTitle)
        lockFrame.Visible = locked
        Box.Active = not locked
        local function updateLock(st) locked = st; lockFrame.Visible = st; Box.Active = not st end
        ConfigObjects[controlId] = {
            Type = "Textbox",
            Value = "",
            Get = function() return Box.Text end,
            Set = function(val)
                if locked then return end
                Box.Text = tostring(val or "")
                ConfigObjects[controlId].Value = Box.Text
                callback(Box.Text)
            end,
        }
        local self = {}
        function self.SetValue(v) if not locked then ConfigObjects[controlId].Set(v) end end
        function self.GetValue() return Box.Text end
        function self.SetVisible(state) Frame.Visible = state end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Label = function(_, config)
        config = safeConfig(config)
        local labelText = config.Name or ""
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local TextLabel = miLabel(Tile, labelText, 15, 12, UDim2.new(1, -30, 0, 18), 13)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        local function updateLock(st) locked = st; lockFrame.Visible = st end
        local self = {}
        function self.UpdateText(newText) TextLabel.Text = newText end
        function self.SetVisible(state) Tile.Visible = state end
        function self.Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Image = function(_, config)
        config = safeConfig(config)
        local title = config.Name or "图片"
        local subtitle = config.SubName or ""
        local description = config.Description or {}
        if type(description) == "string" then description = { description } end
        local iconAsset = config.Icon or config.ImageLink or ""
        local iconColor = config.IconColor or CurrentTheme.Text
        local callback = config.Callback or function() end
        local parent = config.Parent or contentHolder
        local function formatIcon(asset)
            if type(asset) == "number" then return "rbxassetid://"..tostring(asset)
            elseif type(asset) == "string" then
                if tonumber(asset) then return "rbxassetid://"..asset
                elseif asset:match("^rbxassetid://") then return asset
                elseif asset:match("^http") then return asset
                else return "rbxassetid://"..asset end
            end
            return "rbxassetid://78229538488090"
        end
        local imageFrame = Instance.new("Frame")
        imageFrame.Size = UDim2.new(1, 0, 0, 0)
        imageFrame.AutomaticSize = Enum.AutomaticSize.Y
        imageFrame.BackgroundTransparency = 1; imageFrame.BorderSizePixel = 0
        imageFrame.Parent = parent
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12); padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 12); padding.PaddingBottom = UDim.new(0, 12)
        padding.Parent = imageFrame
        local horizontal = Instance.new("Frame")
        horizontal.Size = UDim2.new(1, 0, 1, 0)
        horizontal.BackgroundTransparency = 1; horizontal.Parent = imageFrame
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 80, 0, 80)
        iconImg.Position = UDim2.new(0, 0, 0, 0)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = formatIcon(iconAsset)
        iconImg.ImageColor3 = iconColor; iconImg.Parent = horizontal
        Instance.new("UICorner", iconImg).CornerRadius = UDim.new(0, 12)
        local textContainer = Instance.new("Frame")
        textContainer.Size = UDim2.new(1, -92, 1, 0)
        textContainer.Position = UDim2.new(0, 92, 0, 0)
        textContainer.BackgroundTransparency = 1
        textContainer.AutomaticSize = Enum.AutomaticSize.Y
        textContainer.Parent = horizontal
        local textLayout = Instance.new("UIListLayout")
        textLayout.Padding = UDim.new(0, 6)
        textLayout.SortOrder = Enum.SortOrder.LayoutOrder
        textLayout.Parent = textContainer
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 0)
        titleLabel.AutomaticSize = Enum.AutomaticSize.Y
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = title; titleLabel.TextSize = 15
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextWrapped = true; titleLabel.Parent = textContainer
        AddToRegistry(titleLabel, "TextColor3", "Text")
        if subtitle ~= "" then
            local subtitleLabel = Instance.new("TextLabel")
            subtitleLabel.Size = UDim2.new(1, 0, 0, 0)
            subtitleLabel.AutomaticSize = Enum.AutomaticSize.Y
            subtitleLabel.BackgroundTransparency = 1
            subtitleLabel.Font = Enum.Font.Gotham
            subtitleLabel.Text = subtitle; subtitleLabel.TextSize = 12
            subtitleLabel.TextTransparency = 0.5
            subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            subtitleLabel.TextWrapped = true
            subtitleLabel.Parent = textContainer
            AddToRegistry(subtitleLabel, "TextColor3", "Text")
        end
        for _, line in ipairs(description) do
            local descLabel = Instance.new("TextLabel")
            descLabel.Size = UDim2.new(1, 0, 0, 0)
            descLabel.AutomaticSize = Enum.AutomaticSize.Y
            descLabel.BackgroundTransparency = 1
            descLabel.Font = Enum.Font.Gotham
            descLabel.Text = line; descLabel.TextSize = 12
            descLabel.TextTransparency = 0.3
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.TextWrapped = true
            descLabel.Parent = textContainer
            AddToRegistry(descLabel, "TextColor3", "Text")
        end
        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1; clickBtn.Text = ""
        clickBtn.Parent = imageFrame
        clickBtn.MouseButton1Click:Connect(callback)
        local self = {}
        function self.UpdateTitle(newTitle) titleLabel.Text = newTitle end
        function self.SetIcon(newIcon, newColor)
            iconImg.Image = formatIcon(newIcon)
            if newColor then iconImg.ImageColor3 = newColor end
        end
        function self.SetVisible(state) imageFrame.Visible = state end
        return self
    end

    child.Divider = function(_, config)
        config = safeConfig(config)
        local parent    = config.Parent or contentHolder
        local labelText = tostring(config.Text or config.Name or "")

        local container = Instance.new("Frame")
        container.Size              = UDim2.new(1, 0, 0, 10)
        container.BackgroundTransparency = 1
        container.BorderSizePixel   = 0
        container.Parent            = parent

        do
            local siblings = parent:GetChildren()
            for i, sib in ipairs(siblings) do
                if sib == container then
                    if i > 1 then
                        local prev = siblings[i - 1]
                        for _, c in ipairs(prev:GetChildren()) do
                            if c:IsA("Frame")
                                and c.Size.Y.Offset == 1
                                and c.Position.Y.Scale == 1
                                and c.BackgroundTransparency < 1 then
                                c.Visible = false
                            end
                        end
                    end
                    break
                end
            end
        end

        local leftLine = Instance.new("Frame")
        leftLine.AnchorPoint          = Vector2.new(0, 0.5)
        leftLine.BackgroundColor3     = CurrentTheme.Stroke
        leftLine.BackgroundTransparency = 0.650
        leftLine.BorderSizePixel      = 0
        leftLine.Position             = UDim2.new(0, 10, 0.5, 0)
        leftLine.Size                 = UDim2.new(0.5, -20, 0, 1)
        leftLine.Parent               = container
        AddToRegistry(leftLine, "BackgroundColor3", "Stroke")

        local textLabel = Instance.new("TextLabel")
        textLabel.AnchorPoint          = Vector2.new(0.5, 0.5)
        textLabel.BackgroundTransparency = 1.000
        textLabel.BorderSizePixel      = 0
        textLabel.Position             = UDim2.fromScale(0.5, 0.5)
        textLabel.Size                 = UDim2.new(0, 0, 0, 10)
        textLabel.Font                 = Enum.Font.GothamMedium
        textLabel.Text                 = labelText
        textLabel.TextColor3           = CurrentTheme.Text
        textLabel.TextSize             = 10.000
        textLabel.TextTransparency     = 0.500
        textLabel.Parent               = container
        AddToRegistry(textLabel, "TextColor3", "Text")

        local rightLine = Instance.new("Frame")
        rightLine.AnchorPoint          = Vector2.new(1, 0.5)
        rightLine.BackgroundColor3     = CurrentTheme.Stroke
        rightLine.BackgroundTransparency = 0.650
        rightLine.BorderSizePixel      = 0
        rightLine.Position             = UDim2.new(1, -10, 0.5, 0)
        rightLine.Size                 = UDim2.new(0.5, -20, 0, 1)
        rightLine.Parent               = container
        AddToRegistry(rightLine, "BackgroundColor3", "Stroke")

        local function UpdateDivider()
            local Text = textLabel.Text

            if Text == "" then
                textLabel.Visible = false
                leftLine.Size     = UDim2.new(1, -20, 0, 1)
                rightLine.Visible = false
                return
            end

            textLabel.Visible = true
            rightLine.Visible = true

            local MaxTextWidth = math.max(40, container.AbsoluteSize.X - 70)
            local TextWidth = math.min(
                TextService:GetTextSize(
                    Text,
                    textLabel.TextSize,
                    textLabel.Font,
                    Vector2.new(math.huge, math.huge)
                ).X + 16,
                MaxTextWidth
            )

            textLabel.Size = UDim2.new(0, TextWidth, 0, 10)
            leftLine.Size  = UDim2.new(0.5, -(TextWidth / 2) - 12, 0, 1)
            rightLine.Size = UDim2.new(0.5, -(TextWidth / 2) - 12, 0, 1)
        end

        UpdateDivider()
        container:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateDivider)

        local self = {}
        function self.SetVisible(state) container.Visible = state end
        function self.SetText(newText)
            textLabel.Text = tostring(newText or "")
            UpdateDivider()
            return self
        end
        function self.GetText() return textLabel.Text end
        function self.UpdateText(newText)
            textLabel.Text = tostring(newText or "")
            UpdateDivider()
            return self
        end
        function self.Destroy() container:Destroy() end
        return self
    end

    child.Space = function(_, config)
        config = safeConfig(config)
        local height = (config and config.Height) or 8
        local parent = config and config.Parent or contentHolder
        local sp = Instance.new("Frame")
        sp.Size = UDim2.new(1, 0, 0, height)
        sp.BackgroundTransparency = 1; sp.BorderSizePixel = 0
        sp.Parent = parent
        local self = {}
        function self.SetHeight(h) height = h; sp.Size = UDim2.new(1, 0, 0, height) end
        function self.SetVisible(state) sp.Visible = state end
        function self.Destroy() sp:Destroy() end
        return self
    end

    child.Checkbox = function(_, config)
        config = safeConfig(config)
        local title = config.Name or ""
        local default = config.Default or false
        local callback = config.Callback or function() end
        local controlId = NewConfigId("Checkbox", title)
        local parent = config.Parent or contentHolder
        local Tile = miRow(parent, 42)
        local TitleLbl = miLabel(Tile, title, 15, 12, UDim2.new(1, -60, 0, 18), 13)
        local box = Instance.new("Frame")
        box.Size = UDim2.fromOffset(20, 20)
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -12, 0.5, 0)
        box.BackgroundColor3 = default and CurrentTheme.Accent or Color3.fromRGB(26, 28, 36)
        box.BorderSizePixel = 0; box.Parent = Tile
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Thickness = 1.4
        boxStroke.Transparency = default and 1 or 0.4
        boxStroke.Color = default and CurrentTheme.Accent or CurrentTheme.Stroke
        boxStroke.Parent = box
        local check = Instance.new("ImageLabel")
        check.Size = UDim2.fromOffset(14, 14)
        check.AnchorPoint = Vector2.new(0.5, 0.5)
        check.Position = UDim2.new(0.5, 0, 0.5, 0)
        check.BackgroundTransparency = 1
        check.Image = "rbxassetid://10709790644"
        check.ImageColor3 = Color3.new(1, 1, 1)
        check.ImageTransparency = default and 0 or 1
        check.Parent = box
        local h = { Value = default, Callback = callback, Type = "Checkbox" }
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.BackgroundTransparency = 1; ClickBtn.Text = ""
        ClickBtn.AutoButtonColor = false; ClickBtn.Parent = Tile
        ClickBtn.Active = not locked
        local function updateLock(st) locked = st; lockFrame.Visible = st; ClickBtn.Active = not st end
        local function updateColors()
            if h.Value then
                box.BackgroundColor3 = CurrentTheme.Accent
                boxStroke.Color = CurrentTheme.Accent
                boxStroke.Transparency = 1
                check.ImageTransparency = 0
            else
                box.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
                boxStroke.Color = CurrentTheme.Stroke
                boxStroke.Transparency = 0.4
                check.ImageTransparency = 1
            end
        end
        table.insert(ThemeListeners, updateColors)
        function h:SetValue(val)
            if locked then return end
            val = not (not val)
            h.Value = val; updateColors()
            if ConfigObjects[controlId] then ConfigObjects[controlId].Value = val end
            pcall(callback, val); pcall(h.Changed, val)
        end
        function h:OnChanged(_, cb) h.Changed = cb; cb(h.Value) end
        function h:GetValue() return h.Value end
        function h:SetVisible(vis) Tile.Visible = vis end
        function h:Destroy() Tile:Destroy(); ConfigObjects[controlId] = nil end
        function h:Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function h:Unlock() updateLock(false) end
        function h:IsLocked() return locked end
        ClickBtn.MouseEnter:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 0.65}, 0.15) end end)
        ClickBtn.MouseLeave:Connect(function() if not locked then Tween(Tile, {BackgroundTransparency = 1}, 0.15) end end)
        ClickBtn.MouseButton1Click:Connect(function() if not locked then h:SetValue(not h.Value) end end)
        h:SetValue(default)
        ConfigObjects[controlId] = {
            Type = "Checkbox",
            Value = h.Value,
            Get = function() return h.Value end,
            Set = function(val) h:SetValue(val) end,
        }
        return h
    end

    child.Colorpicker = function(_, config)
        config = safeConfig(config)
        local cpTitle       = config.Name or config.Title or "Colorpicker"
        local defaultColor  = config.Default or config.Value or Color3.fromRGB(255, 255, 255)
        local callback      = config.Callback or function() end
        local transCfg      = config.Transparency
        local hasTransparency = (transCfg ~= nil)
        local controlId     = NewConfigId("Colorpicker", cpTitle)
        local parent        = config.Parent or contentHolder

        local state = { Default = defaultColor, Transparency = transCfg, Hue = 0, Sat = 0, Vib = 0 }
        state.Hue, state.Sat, state.Vib = Color3.toHSV(defaultColor)

        local Tile = miRow(parent, 42)
        local TitleLbl = miLabel(Tile, cpTitle, 15, 12, UDim2.new(1, -70, 0, 18), 13)

        local PreviewWrap = Instance.new("Frame")
        PreviewWrap.Size = UDim2.fromOffset(40, 26)
        PreviewWrap.Position = UDim2.new(1, -50, 0.5, -13)
        PreviewWrap.BackgroundTransparency = 1
        PreviewWrap.BorderSizePixel = 0
        PreviewWrap.Parent = Tile
        Instance.new("UICorner", PreviewWrap).CornerRadius = UDim.new(0, 6)

        local PreviewChecker = Instance.new("ImageLabel")
        PreviewChecker.Size = UDim2.fromScale(1, 1)
        PreviewChecker.BackgroundTransparency = 1
        PreviewChecker.Image = CHESSBOARD_IMAGE
        PreviewChecker.ImageTransparency = 0.35
        PreviewChecker.ScaleType = Enum.ScaleType.Tile
        PreviewChecker.TileSize = UDim2.fromOffset(10, 10)
        PreviewChecker.ZIndex = 1
        PreviewChecker.Parent = PreviewWrap
        Instance.new("UICorner", PreviewChecker).CornerRadius = UDim.new(0, 6)

        local PreviewBtn = Instance.new("TextButton")
        PreviewBtn.Size = UDim2.fromScale(1, 1)
        PreviewBtn.BackgroundColor3 = state.Default
        PreviewBtn.BackgroundTransparency = hasTransparency and state.Transparency or 0
        PreviewBtn.BorderSizePixel = 0
        PreviewBtn.Text = ""
        PreviewBtn.AutoButtonColor = false
        PreviewBtn.ZIndex = 2
        PreviewBtn.Parent = PreviewWrap
        Instance.new("UICorner", PreviewBtn).CornerRadius = UDim.new(0, 6)

        local previewStroke = Instance.new("UIStroke")
        previewStroke.Thickness = 1.5
        previewStroke.Color = CurrentTheme.Stroke
        previewStroke.Transparency = 0.3
        previewStroke.Parent = PreviewBtn
        table.insert(ThemeListeners, function() previewStroke.Color = CurrentTheme.Stroke end)

        local locked      = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(Tile, lockedTitle)
        lockFrame.Visible = locked
        PreviewBtn.Active = not locked

        local dialogOpen = false
        local function OpenColorpicker()
            if locked or dialogOpen then return end
            local sg = parent
            while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
            if not sg then return end
            dialogOpen = true

            local W = { Hue = state.Hue, Sat = state.Sat, Vib = state.Vib, Transparency = state.Transparency or 0 }
            local function CurColor() return Color3.fromHSV(W.Hue, W.Sat, W.Vib) end
            local TextPadding = 10

            local Overlay = Instance.new("Frame")
            Overlay.Size = UDim2.fromScale(1, 1)
            Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
            Overlay.BackgroundTransparency = 1
            Overlay.ZIndex = 500
            Overlay.Active = true
            Overlay.Parent = sg

            local MainContainer = Instance.new("ImageLabel")
            MainContainer.Image = "rbxassetid://8992230677"
            MainContainer.ScaleType = Enum.ScaleType.Slice
            MainContainer.SliceCenter = Rect.new(99, 99, 99, 99)
            MainContainer.ImageTransparency = 1
            MainContainer.ImageColor3 = CurrentTheme.Main
            MainContainer.BackgroundTransparency = 1
            MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            MainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            MainContainer.AutomaticSize = Enum.AutomaticSize.XY
            MainContainer.Visible = false
            MainContainer.ZIndex = 501
            MainContainer.Parent = Overlay
            Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 26)

            local Main = Instance.new("Frame")
            Main.Size = UDim2.new(0, 280, 0, 0)
            Main.AutomaticSize = Enum.AutomaticSize.Y
            Main.BackgroundTransparency = 1
            Main.Visible = false
            Main.ZIndex = 502
            Main.Parent = MainContainer

            local Title = Instance.new("TextLabel")
            Title.Text = cpTitle
            Title.TextSize = 20
            local fontOk = pcall(function()
                Title.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
            end)
            if not fontOk then Title.Font = Enum.Font.GothamBold end
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Size = UDim2.new(1, 0, 0, 0)
            Title.AutomaticSize = Enum.AutomaticSize.Y
            Title.TextColor3 = CurrentTheme.Text
            Title.BackgroundTransparency = 1
            Title.Parent = Main
            AddToRegistry(Title, "TextColor3", "Text")
            local titlePad = Instance.new("UIPadding")
            titlePad.PaddingTop    = UDim.new(0, TextPadding / 2)
            titlePad.PaddingLeft   = UDim.new(0, TextPadding / 2)
            titlePad.PaddingRight  = UDim.new(0, TextPadding / 2)
            titlePad.PaddingBottom = UDim.new(0, TextPadding / 2)
            titlePad.Parent = Title

            local SatVibMap = Instance.new("ImageLabel")
            SatVibMap.Size = UDim2.fromOffset(160, 158)
            SatVibMap.Position = UDim2.fromOffset(0, 40 + TextPadding)
            SatVibMap.Image = "rbxassetid://4155801252"
            SatVibMap.BackgroundColor3 = Color3.fromHSV(W.Hue, 1, 1)
            SatVibMap.BackgroundTransparency = 0
            SatVibMap.ZIndex = 3
            SatVibMap.Parent = Main
            Instance.new("UICorner", SatVibMap).CornerRadius = UDim.new(0, 8)

            local SatVibDot = Instance.new("Frame")
            SatVibDot.Size = UDim2.fromOffset(14, 14)
            SatVibDot.AnchorPoint = Vector2.new(0.5, 0.5)
            SatVibDot.Position = UDim2.new(W.Sat, 0, 1 - W.Vib, 0)
            SatVibDot.BackgroundColor3 = CurColor()
            SatVibDot.BorderSizePixel = 0
            SatVibDot.ZIndex = 4
            SatVibDot.Parent = SatVibMap
            Instance.new("UICorner", SatVibDot).CornerRadius = UDim.new(1, 0)
            local dotStroke = Instance.new("UIStroke")
            dotStroke.Thickness = 2
            dotStroke.Transparency = 0.1
            dotStroke.Color = CurrentTheme.Text
            dotStroke.Parent = SatVibDot
            table.insert(ThemeListeners, function() dotStroke.Color = CurrentTheme.Text end)

            local HueSlider = Instance.new("Frame")
            HueSlider.Size = UDim2.fromOffset(6, 192)
            HueSlider.Position = UDim2.fromOffset(180, 40 + TextPadding)
            HueSlider.BackgroundTransparency = 1
            HueSlider.Parent = Main

            local HueBar = Instance.new("Frame")
            HueBar.Size = UDim2.fromScale(1, 1)
            HueBar.BorderSizePixel = 0
            HueBar.Parent = HueSlider
            Instance.new("UICorner", HueBar).CornerRadius = UDim.new(1, 0)
            local hueKeys = {}
            for i = 0, 10 do
                table.insert(hueKeys, ColorSequenceKeypoint.new(i / 10, Color3.fromHSV(i / 10, 1, 1)))
            end
            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new(hueKeys)
            hueGrad.Rotation = 90
            hueGrad.Parent = HueBar

            local HueGrip = Instance.new("Frame")
            HueGrip.Size = UDim2.fromOffset(14, 14)
            HueGrip.AnchorPoint = Vector2.new(0.5, 0.5)
            HueGrip.Position = UDim2.new(0.5, 0, W.Hue, 0)
            HueGrip.BackgroundColor3 = Color3.fromHSV(W.Hue, 1, 1)
            HueGrip.BorderSizePixel = 0
            HueGrip.ZIndex = 3
            HueGrip.Parent = HueSlider
            Instance.new("UICorner", HueGrip).CornerRadius = UDim.new(1, 0)
            local hueGripStroke = Instance.new("UIStroke")
            hueGripStroke.Thickness = 2
            hueGripStroke.Transparency = 0.1
            hueGripStroke.Color = CurrentTheme.Text
            hueGripStroke.Parent = HueGrip
            table.insert(ThemeListeners, function() hueGripStroke.Color = CurrentTheme.Text end)

            local AlphaSlider, AlphaGrip, AlphaBar
            if hasTransparency then
                AlphaSlider = Instance.new("Frame")
                AlphaSlider.Size = UDim2.fromOffset(6, 192)
                AlphaSlider.Position = UDim2.fromOffset(210, 40 + TextPadding)
                AlphaSlider.BackgroundTransparency = 1
                AlphaSlider.Parent = Main

                local Checker = Instance.new("Frame")
                Checker.Size = UDim2.fromScale(1, 1)
                Checker.BackgroundColor3 = Color3.new(1, 1, 1)
                Checker.BorderSizePixel = 0
                Checker.Parent = AlphaSlider
                Instance.new("UICorner", Checker).CornerRadius = UDim.new(1, 0)

                local CheckerImg = Instance.new("ImageLabel")
                CheckerImg.Size = UDim2.fromScale(1, 1)
                CheckerImg.BackgroundTransparency = 1
                CheckerImg.Image = CHESSBOARD_IMAGE
                CheckerImg.ImageTransparency = 0.35
                CheckerImg.ScaleType = Enum.ScaleType.Tile
                CheckerImg.TileSize = UDim2.fromOffset(10, 10)
                CheckerImg.Parent = Checker
                Instance.new("UICorner", CheckerImg).CornerRadius = UDim.new(1, 0)

                AlphaBar = Instance.new("Frame")
                AlphaBar.Size = UDim2.fromScale(1, 1)
                AlphaBar.BackgroundColor3 = CurColor()
                AlphaBar.BackgroundTransparency = W.Transparency
                AlphaBar.BorderSizePixel = 0
                AlphaBar.ZIndex = 2
                AlphaBar.Parent = AlphaSlider
                Instance.new("UICorner", AlphaBar).CornerRadius = UDim.new(1, 0)
                local alphaGrad = Instance.new("UIGradient")
                alphaGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                alphaGrad.Rotation = 270
                alphaGrad.Parent = AlphaBar

                AlphaGrip = Instance.new("Frame")
                AlphaGrip.Size = UDim2.fromOffset(14, 14)
                AlphaGrip.AnchorPoint = Vector2.new(0.5, 0.5)
                AlphaGrip.Position = UDim2.new(0.5, 0, 1 - W.Transparency, 0)
                AlphaGrip.BackgroundColor3 = CurColor()
                AlphaGrip.BorderSizePixel = 0
                AlphaGrip.ZIndex = 3
                AlphaGrip.Parent = AlphaSlider
                Instance.new("UICorner", AlphaGrip).CornerRadius = UDim.new(1, 0)
                local alphaGripStroke = Instance.new("UIStroke")
                alphaGripStroke.Thickness = 2
                alphaGripStroke.Transparency = 0.1
                alphaGripStroke.Color = CurrentTheme.Text
                alphaGripStroke.Parent = AlphaGrip
                table.insert(ThemeListeners, function() alphaGripStroke.Color = CurrentTheme.Text end)
            end

            local Preview1 = Instance.new("Frame")
            Preview1.Size = UDim2.fromOffset(75, 24)
            Preview1.Position = UDim2.fromOffset(0, 208 + TextPadding)
            Preview1.BackgroundTransparency = 1
            Preview1.BorderSizePixel = 0
            Preview1.Parent = Main
            Instance.new("UICorner", Preview1).CornerRadius = UDim.new(0, 8)

            local P1Checker = Instance.new("ImageLabel")
            P1Checker.Size = UDim2.fromScale(1, 1)
            P1Checker.BackgroundTransparency = 1
            P1Checker.Image = CHESSBOARD_IMAGE
            P1Checker.ImageTransparency = 0.35
            P1Checker.ScaleType = Enum.ScaleType.Tile
            P1Checker.TileSize = UDim2.fromOffset(10, 10)
            P1Checker.ZIndex = 1
            P1Checker.Parent = Preview1
            Instance.new("UICorner", P1Checker).CornerRadius = UDim.new(0, 8)

            local P1Color = Instance.new("Frame")
            P1Color.Size = UDim2.fromScale(1, 1)
            P1Color.BackgroundColor3 = CurColor()
            P1Color.BackgroundTransparency = hasTransparency and W.Transparency or 0
            P1Color.BorderSizePixel = 0
            P1Color.ZIndex = 2
            P1Color.Parent = Preview1
            Instance.new("UICorner", P1Color).CornerRadius = UDim.new(0, 8)

            local Preview2 = Instance.new("Frame")
            Preview2.Size = UDim2.fromOffset(75, 24)
            Preview2.Position = UDim2.fromOffset(85, 208 + TextPadding)
            Preview2.BackgroundColor3 = CurColor()
            Preview2.BackgroundTransparency = 0
            Preview2.BorderSizePixel = 0
            Preview2.Parent = Main
            Instance.new("UICorner", Preview2).CornerRadius = UDim.new(0, 8)

            local InputsFrame = Instance.new("Frame")
            InputsFrame.AutomaticSize = Enum.AutomaticSize.XY
            InputsFrame.Size = UDim2.new(0, 0, 0, 0)
            InputsFrame.Position = UDim2.fromOffset(hasTransparency and 240 or 210, 40 + TextPadding)
            InputsFrame.BackgroundTransparency = 1
            InputsFrame.Parent = Main
            local inputsList = Instance.new("UIListLayout")
            inputsList.FillDirection = Enum.FillDirection.Vertical
            inputsList.Padding = UDim.new(0, 4)
            inputsList.Parent = InputsFrame

            local function CreateNewInput(labelText, defaultText)
                local holder = Instance.new("Frame")
                holder.Size = UDim2.fromOffset(150, 42)
                holder.BackgroundTransparency = 1
                holder.Parent = InputsFrame

                local scale = Instance.new("UIScale")
                scale.Scale = 0.85
                scale.Parent = holder

                local box = Instance.new("Frame")
                box.Size = UDim2.fromScale(1, 1)
                box.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
                box.BorderSizePixel = 0
                box.Parent = holder
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

                local boxStroke = Instance.new("UIStroke")
                boxStroke.Thickness = 1
                boxStroke.Transparency = 0.65
                boxStroke.Color = CurrentTheme.Stroke
                boxStroke.Parent = box
                table.insert(ThemeListeners, function() boxStroke.Color = CurrentTheme.Stroke end)

                local tb = Instance.new("TextBox")
                tb.Size = UDim2.new(1, -20, 1, 0)
                tb.Position = UDim2.new(0, 10, 0, 0)
                tb.BackgroundTransparency = 1
                tb.Font = Enum.Font.GothamBold
                tb.TextSize = 14
                tb.TextColor3 = CurrentTheme.Text
                tb.TextXAlignment = Enum.TextXAlignment.Left
                tb.ClearTextOnFocus = false
                tb.Text = tostring(defaultText)
                tb.Parent = box
                AddToRegistry(tb, "TextColor3", "Text")
                TextGradient:Skip(tb)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.fromOffset(30, 20)
                lbl.Position = UDim2.new(1, -40, 0.5, -10)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 12
                lbl.Text = labelText
                lbl.TextColor3 = CurrentTheme.Text
                lbl.TextTransparency = 0.4
                lbl.TextXAlignment = Enum.TextXAlignment.Right
                lbl.Parent = box
                AddToRegistry(lbl, "TextColor3", "Text")
                TextGradient:Skip(lbl)

                return tb
            end

            local c0 = CurColor()
            local HexInput = CreateNewInput("Hex", "#" .. c0:ToHex())
            local RInput  = CreateNewInput("R",  math.floor(c0.R * 255 + 0.5))
            local GInput  = CreateNewInput("G",  math.floor(c0.G * 255 + 0.5))
            local BInput  = CreateNewInput("B",  math.floor(c0.B * 255 + 0.5))
            local AlphaInput
            if hasTransparency then
                AlphaInput = CreateNewInput("A", math.floor((1 - W.Transparency) * 100 + 0.5))
            end

            local InputsX = hasTransparency and 240 or 210
            local InputsVisualRight = InputsX + 150 * 0.85

            local ButtonsFrame = Instance.new("Frame")
            ButtonsFrame.Size = UDim2.new(0, InputsVisualRight, 0, 40)
            ButtonsFrame.Position = UDim2.fromOffset(0, 254 + TextPadding)
            ButtonsFrame.BackgroundTransparency = 1
            ButtonsFrame.Parent = Main

            local suppressInput = false
            local function SyncUI()
                local cur = CurColor()
                SatVibMap.BackgroundColor3 = Color3.fromHSV(W.Hue, 1, 1)
                SatVibDot.Position = UDim2.new(W.Sat, 0, 1 - W.Vib, 0)
                SatVibDot.BackgroundColor3 = cur
                HueGrip.Position = UDim2.new(0.5, 0, W.Hue, 0)
                HueGrip.BackgroundColor3 = Color3.fromHSV(W.Hue, 1, 1)
                if AlphaBar then
                    AlphaBar.BackgroundColor3 = cur
                    AlphaBar.BackgroundTransparency = W.Transparency
                end
                if AlphaGrip then
                    AlphaGrip.Position = UDim2.new(0.5, 0, 1 - W.Transparency, 0)
                    AlphaGrip.BackgroundColor3 = cur
                end
                P1Color.BackgroundColor3 = cur
                P1Color.BackgroundTransparency = hasTransparency and W.Transparency or 0
                Preview2.BackgroundColor3 = cur
                PreviewBtn.BackgroundColor3 = cur
                PreviewBtn.BackgroundTransparency = hasTransparency and W.Transparency or 0

                if not suppressInput then
                    suppressInput = true
                    HexInput.Text = "#" .. cur:ToHex()
                    RInput.Text = tostring(math.floor(cur.R * 255 + 0.5))
                    GInput.Text = tostring(math.floor(cur.G * 255 + 0.5))
                    BInput.Text = tostring(math.floor(cur.B * 255 + 0.5))
                    if AlphaInput then
                        AlphaInput.Text = tostring(math.floor((1 - W.Transparency) * 100 + 0.5))
                    end
                    suppressInput = false
                end
            end

            local Mouse = Players.LocalPlayer:GetMouse()

            local function UpdateFromMap()
                local apX = SatVibMap.AbsolutePosition.X
                local apW = apX + SatVibMap.AbsoluteSize.X
                local mx  = math.clamp(Mouse.X, apX, apW)

                local apY = SatVibMap.AbsolutePosition.Y
                local apH = apY + SatVibMap.AbsoluteSize.Y
                local my  = math.clamp(Mouse.Y, apY, apH)

                W.Sat = (mx - apX) / (apW - apX)
                W.Vib = 1 - ((my - apY) / (apH - apY))
                SyncUI()
            end

            local function UpdateFromHue()
                local apY = HueSlider.AbsolutePosition.Y
                local apH = apY + HueSlider.AbsoluteSize.Y
                local my  = math.clamp(Mouse.Y, apY, apH)
                W.Hue = (my - apY) / (apH - apY)
                SyncUI()
            end

            local function UpdateFromAlpha()
                if not AlphaSlider then return end
                local apY = AlphaSlider.AbsolutePosition.Y
                local apH = apY + AlphaSlider.AbsoluteSize.Y
                local my  = math.clamp(Mouse.Y, apY, apH)
                W.Transparency = 1 - ((my - apY) / (apH - apY))
                SyncUI()
            end

            SatVibMap.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        UpdateFromMap()
                        RunService.RenderStepped:Wait()
                    end
                end
            end)

            HueSlider.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        UpdateFromHue()
                        RunService.RenderStepped:Wait()
                    end
                end
            end)

            if AlphaSlider then
                AlphaSlider.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            UpdateFromAlpha()
                            RunService.RenderStepped:Wait()
                        end
                    end
                end)
            end

            local function ApplyFromRGB()
                if suppressInput then return end
                local r = math.clamp(tonumber(RInput.Text) or 0, 0, 255)
                local g = math.clamp(tonumber(GInput.Text) or 0, 0, 255)
                local b = math.clamp(tonumber(BInput.Text) or 0, 0, 255)
                W.Hue, W.Sat, W.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                SyncUI()
            end
            HexInput.FocusLost:Connect(function()
                if suppressInput then return end
                local txt = HexInput.Text:gsub("#", "")
                local ok, col = pcall(Color3.fromHex, txt)
                if ok and typeof(col) == "Color3" then
                    W.Hue, W.Sat, W.Vib = Color3.toHSV(col)
                    SyncUI()
                end
            end)
            RInput.FocusLost:Connect(ApplyFromRGB)
            GInput.FocusLost:Connect(ApplyFromRGB)
            BInput.FocusLost:Connect(ApplyFromRGB)
            if AlphaInput then
                AlphaInput.FocusLost:Connect(function()
                    if suppressInput then return end
                    local a = math.clamp(tonumber(AlphaInput.Text) or 0, 0, 100)
                    W.Transparency = 1 - a / 100
                    SyncUI()
                end)
            end

            local function CloseDialog()
                dialogOpen = false
                Tween(Main, {BackgroundTransparency = 1}, 0.1)
                Tween(MainContainer, {ImageTransparency = 1}, 0.12)
                Tween(Overlay, {BackgroundTransparency = 1}, 0.12)
                task.delay(0.16, function() Overlay:Destroy() end)
            end

            local function MakeDialogButton(text, isPrimary, onClick, side)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.fromOffset(100, 40)
                btn.BackgroundColor3 = isPrimary and CurrentTheme.Accent or Color3.fromRGB(26, 28, 36)
                btn.BorderSizePixel = 0
                btn.Text = text
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 14
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.AutoButtonColor = false
                if side == "right" then
                    btn.AnchorPoint = Vector2.new(1, 0)
                    btn.Position = UDim2.new(1, 0, 0, 0)
                else
                    btn.AnchorPoint = Vector2.new(0, 0)
                    btn.Position = UDim2.new(0, 0, 0, 0)
                end
                btn.Parent = ButtonsFrame
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
                if not isPrimary then
                    local s = Instance.new("UIStroke")
                    s.Color = CurrentTheme.Stroke
                    s.Thickness = 1
                    s.Transparency = 0.5
                    s.Parent = btn
                    table.insert(ThemeListeners, function() s.Color = CurrentTheme.Stroke end)
                end
                btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.15}, 0.12) end)
                btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0}, 0.12) end)
                btn.MouseButton1Click:Connect(onClick)
                return btn
            end

            MakeDialogButton("取消", false, function()
                CloseDialog()
            end, "left")

            MakeDialogButton("确认", true, function()
                local cur = CurColor()
                state.Default = cur
                state.Hue, state.Sat, state.Vib = W.Hue, W.Sat, W.Vib
                if hasTransparency then state.Transparency = W.Transparency end
                PreviewBtn.BackgroundColor3 = cur
                PreviewBtn.BackgroundTransparency = hasTransparency and state.Transparency or 0
                ConfigObjects[controlId].Value = { Color = cur, Transparency = state.Transparency }
                pcall(callback, cur, state.Transparency)
                CloseDialog()
            end, "right")

            Tween(Overlay, {BackgroundTransparency = 0.35}, 0.15)
            MainContainer.Visible = true
            Tween(MainContainer, {ImageTransparency = 0}, 0.15)
            task.spawn(function()
                task.wait(0.05)
                Main.Visible = true
            end)
        end

        PreviewBtn.MouseButton1Click:Connect(OpenColorpicker)

        ConfigObjects[controlId] = {
            Type = "Colorpicker",
            Value = { Color = state.Default, Transparency = state.Transparency },
            Get = function()
                return { Color = state.Default, Transparency = state.Transparency }
            end,
            Set = function(val)
                if locked then return end
                if type(val) == "table" and val.Color then
                    state.Default = val.Color
                    state.Hue, state.Sat, state.Vib = Color3.toHSV(val.Color)
                    if val.Transparency ~= nil then state.Transparency = val.Transparency end
                elseif typeof(val) == "Color3" then
                    state.Default = val
                    state.Hue, state.Sat, state.Vib = Color3.toHSV(val)
                end
                PreviewBtn.BackgroundColor3 = state.Default
                PreviewBtn.BackgroundTransparency = hasTransparency and state.Transparency or 0
                ConfigObjects[controlId].Value = { Color = state.Default, Transparency = state.Transparency }
                pcall(callback, state.Default, state.Transparency)
            end,
        }

        local self = {}
        function self.GetValue() return state.Default, state.Transparency end
        function self.SetValue(col, tr)
            if locked then return end
            if col then
                state.Default = col
                state.Hue, state.Sat, state.Vib = Color3.toHSV(col)
            end
            if tr ~= nil then state.Transparency = tr end
            PreviewBtn.BackgroundColor3 = state.Default
            PreviewBtn.BackgroundTransparency = hasTransparency and state.Transparency or 0
            ConfigObjects[controlId].Value = { Color = state.Default, Transparency = state.Transparency }
            pcall(callback, state.Default, state.Transparency)
        end
        function self.SetVisible(v) Tile.Visible = v end
        function self.Lock(title)
            locked = true; lockFrame.Visible = true; PreviewBtn.Active = false
            if title then lockLabel.Text = title; lockedTitle = title end
        end
        function self.Unlock() locked = false; lockFrame.Visible = false; PreviewBtn.Active = true end
        function self.IsLocked() return locked end
        function self.Destroy() Tile:Destroy(); ConfigObjects[controlId] = nil end
        return self
    end

    child.ProgressBar = function(_, config)
        config = safeConfig(config)
        local name = config.Name or ""
        local valueConfig = config.Value or {}
        local min = valueConfig.Min or 0
        local max = valueConfig.Max or 100
        local default = valueConfig.Default or min
        local showPercent = config.ShowPercent ~= false
        local callback = config.Callback or function() end
        local controlId = NewConfigId("ProgressBar", name)
        local parent = config.Parent or contentHolder
        local containerHeight = (name ~= "" and 46 or 26)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, containerHeight)
        wrap.BackgroundTransparency = 1; wrap.BorderSizePixel = 0
        wrap.Parent = parent
        local titleLbl = nil
        if name ~= "" then
            titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -50, 0, 16)
            titleLbl.Position = UDim2.new(0, 15, 0, 10)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Font = Enum.Font.GothamMedium
            titleLbl.Text = name; titleLbl.TextSize = 14
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = wrap
            AddToRegistry(titleLbl, "TextColor3", "Text")
        end
        local pctLbl = nil
        if showPercent then
            pctLbl = Instance.new("TextLabel")
            pctLbl.Size = UDim2.new(0, 50, 0, 16)
            pctLbl.Position = UDim2.new(1, -50, 0, 10)
            pctLbl.BackgroundTransparency = 1
            pctLbl.Font = Enum.Font.Gotham
            pctLbl.Text = "0%"; pctLbl.TextSize = 13
            pctLbl.TextXAlignment = Enum.TextXAlignment.Right
            pctLbl.TextTransparency = 0.5; pctLbl.Parent = wrap
            AddToRegistry(pctLbl, "TextColor3", "Text")
            TextGradient:Skip(pctLbl)
        end
        local rail = Instance.new("Frame")
        rail.Size = UDim2.new(1, -30, 0, 8)
        rail.Position = UDim2.new(0, 15, 1, -14)
        rail.BackgroundColor3 = CurrentTheme.Stroke
        rail.BackgroundTransparency = 0.4; rail.BorderSizePixel = 0
        rail.Parent = wrap
        Instance.new("UICorner", rail).CornerRadius = UDim.new(1, 0)
        AddToRegistry(rail, "BackgroundColor3", "Stroke")
        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = CurrentTheme.Accent
        fill.BorderSizePixel = 0; fill.Parent = rail
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        AddToRegistry(fill, "BackgroundColor3", "Accent")
        local h = { Value = math.clamp(default, min, max), Min = min, Max = max, Type = "ProgressBar", Frame = wrap }
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(wrap, lockedTitle)
        lockFrame.Visible = locked
        local function updateLock(st) locked = st; lockFrame.Visible = st end
        function h:SetTitle(s) if titleLbl then titleLbl.Text = tostring(s or "") end end
        function h:SetValue(val)
            if locked then return end
            val = math.clamp(tonumber(val) or h.Min, h.Min, h.Max)
            h.Value = val
            local alpha = (h.Max > h.Min) and (val - h.Min) / (h.Max - h.Min) or 0
            Tween(fill, {Size = UDim2.fromScale(alpha, 1)}, 0.2)
            if pctLbl then pctLbl.Text = math.floor(alpha * 100).."%" end
            if callback then pcall(callback, val) end
            if ConfigObjects[controlId] then ConfigObjects[controlId].Value = val end
        end
        function h:Destroy() wrap:Destroy(); ConfigObjects[controlId] = nil end
        function h:SetVisible(state) wrap.Visible = state end
        function h:Lock(title) updateLock(true); if title then lockLabel.Text = title; lockedTitle = title end end
        function h:Unlock() updateLock(false) end
        function h:IsLocked() return locked end
        h:SetValue(default)
        ConfigObjects[controlId] = {
            Type = "ProgressBar",
            Value = h.Value,
            Get = function() return h.Value end,
            Set = function(val) h:SetValue(val) end,
        }
        return h
    end

    child.CodeBlock = function(_, config)
        config = safeConfig(config)

        local codeName    = config.Name or "Code"
        local codeText    = tostring(config.Code or "")
        local richText    = config.RichText == true
        local copyEnabled = config.Copy ~= false
        local copyText    = config.CopyText or "Copy"
        local locked      = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local parent      = config.Parent or contentHolder
        local controlId   = NewConfigId("CodeBlock", codeName)

        local CodeFrame   = Instance.new("Frame")
        local UICorner    = Instance.new("UICorner")
        local CodeLabel   = Instance.new("TextLabel")
        local CodeCorner  = Instance.new("UICorner")
        local CodePadding = Instance.new("UIPadding")
        local CopyButton  = Instance.new("Frame")
        local CopyCorner  = Instance.new("UICorner")
        local CopyStroke  = Instance.new("UIStroke")
        local CopyIcon    = Instance.new("ImageLabel")
        local LineFrame   = Instance.new("Frame")

        CodeFrame.Name = "CodeBlock_Frame"
        CodeFrame.Parent = parent
        CodeFrame.BackgroundColor3 = CurrentTheme.Main
        CodeFrame.BackgroundTransparency = 1.000
        CodeFrame.BorderSizePixel = 0
        CodeFrame.ClipsDescendants = true
        CodeFrame.Size = UDim2.new(1, 0, 0, 60)
        AddToRegistry(CodeFrame, "BackgroundColor3", "Main")

        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = CodeFrame

        CodeLabel.Name = "CodeBlock_Label"
        CodeLabel.Parent = CodeFrame
        CodeLabel.BackgroundColor3 = Color3.fromRGB(18, 19, 25)
        CodeLabel.BackgroundTransparency = 0.150
        CodeLabel.BorderSizePixel = 0
        CodeLabel.Position = UDim2.new(0, 10, 0, 7)
        CodeLabel.Size = UDim2.new(1, -20, 0, 40)
        CodeLabel.Font = Enum.Font.Code
        CodeLabel.RichText = richText
        CodeLabel.Text = codeText
        CodeLabel.TextColor3 = CurrentTheme.Text
        CodeLabel.TextSize = 12.000
        CodeLabel.TextTransparency = 0.200
        CodeLabel.TextWrapped = true
        CodeLabel.TextXAlignment = Enum.TextXAlignment.Left
        CodeLabel.TextYAlignment = Enum.TextYAlignment.Top
        AddToRegistry(CodeLabel, "TextColor3", "Text")
        TextGradient:Skip(CodeLabel)

        CodeCorner.CornerRadius = UDim.new(0, 5)
        CodeCorner.Parent = CodeLabel

        CodePadding.PaddingTop    = UDim.new(0, 7)
        CodePadding.PaddingBottom = UDim.new(0, 7)
        CodePadding.PaddingLeft   = UDim.new(0, 7)
        CodePadding.PaddingRight  = UDim.new(0, copyEnabled and 35 or 7)
        CodePadding.Parent = CodeLabel

        CopyButton.Name = "CodeBlock_CopyButton"
        CopyButton.Parent = CodeFrame
        CopyButton.AnchorPoint = Vector2.new(1, 0)
        CopyButton.BackgroundColor3 = CurrentTheme.Element or Color3.fromRGB(26, 28, 36)
        CopyButton.BackgroundTransparency = copyEnabled and 0.100 or 1
        CopyButton.BorderSizePixel = 0
        CopyButton.ClipsDescendants = true
        CopyButton.Position = UDim2.new(1, -16, 0, 13)
        CopyButton.Size = UDim2.new(0, 24, 0, 24)
        CopyButton.Visible = copyEnabled
        CopyButton.ZIndex = 12
        AddToRegistry(CopyButton, "BackgroundColor3", "Element")

        CopyCorner.CornerRadius = UDim.new(0, 5)
        CopyCorner.Parent = CopyButton

        CopyStroke.Transparency = 0.650
        CopyStroke.Color = CurrentTheme.Stroke
        CopyStroke.Parent = CopyButton
        table.insert(ThemeListeners, function() CopyStroke.Color = CurrentTheme.Stroke end)

        CopyIcon.Name = "CodeBlock_CopyIcon"
        CopyIcon.Parent = CopyButton
        CopyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CopyIcon.BackgroundTransparency = 1
        CopyIcon.BorderSizePixel = 0
        CopyIcon.Position = UDim2.fromScale(0.5, 0.5)
        CopyIcon.Size = UDim2.new(0, 15, 0, 15)
        CopyIcon.ZIndex = 13
        CopyIcon.Image = "rbxassetid://103287906385313"
        CopyIcon.ImageColor3 = CurrentTheme.Text
        CopyIcon.ImageTransparency = 0.250
        CopyIcon.ScaleType = Enum.ScaleType.Fit
        AddToRegistry(CopyIcon, "ImageColor3", "Text")

        LineFrame.Name = "CodeBlock_Line"
        LineFrame.Parent = CodeFrame
        LineFrame.AnchorPoint = Vector2.new(0.5, 1)
        LineFrame.BackgroundColor3 = CurrentTheme.Stroke
        LineFrame.BackgroundTransparency = 0.650
        LineFrame.BorderSizePixel = 0
        LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
        LineFrame.Size = UDim2.new(1, -20, 0, 1)
        AddToRegistry(LineFrame, "BackgroundColor3", "Stroke")

        local function UpdateCodeSize()
            if not CodeFrame.Parent then return end
            local Width = math.max(120, CodeFrame.AbsoluteSize.X - 32)
            local Size = TextService:GetTextSize(
                CodeLabel.Text, CodeLabel.TextSize, CodeLabel.Font,
                Vector2.new(Width, math.huge)
            )
            local Height = math.max(40, Size.Y + 14)
            CodeLabel.Size = UDim2.new(1, -20, 0, Height)
            CodeFrame.Size = UDim2.new(1, 0, 0, Height + 15)
        end

        local function GetClipboardWriter()
            return setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard) or nil
        end

        local ICON_COPY  = "rbxassetid://103287906385313"
        local ICON_CHECK = "rbxassetid://10709790644"

        local function Copy()
            local Writer = GetClipboardWriter()
            if not Writer then
                CopyIcon.Image = ICON_COPY
                return false
            end
            local Success = pcall(function() Writer(codeText) end)
            CopyIcon.Image = Success and ICON_CHECK or ICON_COPY
            task.delay(0.85, function()
                if CopyIcon and CopyIcon.Parent then
                    CopyIcon.Image = ICON_COPY
                end
            end)
            return Success
        end

        local CopyInput = Instance.new("TextButton")
        CopyInput.Name = "CodeBlock_CopyInput"
        CopyInput.Size = UDim2.fromScale(1, 1)
        CopyInput.BackgroundTransparency = 1
        CopyInput.Text = ""
        CopyInput.AutoButtonColor = false
        CopyInput.Parent = CopyButton
        CopyInput.MouseButton1Click:Connect(Copy)

        CopyInput.MouseEnter:Connect(function()
            Tween(CopyButton, { BackgroundTransparency = 0 }, 0.175)
            Tween(CopyIcon, { ImageTransparency = 0 }, 0.175)
        end)
        CopyInput.MouseLeave:Connect(function()
            Tween(CopyButton, { BackgroundTransparency = 0.100 }, 0.175)
            Tween(CopyIcon, { ImageTransparency = 0.250 }, 0.175)
        end)

        local lockFrame, lockLabel = createLockOverlay(CodeFrame, lockedTitle)
        lockFrame.Visible = locked
        local function updateLock(state)
            locked = state
            lockFrame.Visible = state
        end

        task.defer(UpdateCodeSize)
        CodeFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCodeSize)

        ConfigObjects[controlId] = {
            Type = "CodeBlock",
            Value = codeText,
            Get = function() return codeText end,
            Set = function(v)
                if locked then return end
                codeText = tostring(v or "")
                CodeLabel.Text = codeText
                UpdateCodeSize()
            end,
        }

        local self = {}
        function self:Copy()
            return Copy()
        end
        function self:SetCode(code)
            codeText = tostring(code or "")
            CodeLabel.Text = codeText
            ConfigObjects[controlId].Value = codeText
            UpdateCodeSize()
            return self
        end
        function self:GetCode()
            return codeText
        end
        function self:SetRichText(value)
            richText = value == true
            CodeLabel.RichText = richText
            UpdateCodeSize()
            return self
        end
        function self:SetVisible(value)
            CodeFrame.Visible = value ~= false
            return self
        end
        function self:SetCopyEnabled(value)
            copyEnabled = value == true
            CopyButton.Visible = copyEnabled
            CodePadding.PaddingRight = UDim.new(0, copyEnabled and 35 or 7)
            return self
        end
        function self:SetCopyText(value)
            copyText = tostring(value or "Copy")
            return self
        end
        function self:Lock(title)
            updateLock(true)
            if title then lockLabel.Text = title; lockedTitle = title end
            return self
        end
        function self:Unlock()
            updateLock(false)
            return self
        end
        function self:IsLocked()
            return locked
        end
        function self:Destroy()
            CodeFrame:Destroy()
            ConfigObjects[controlId] = nil
        end
        return self
    end

    child.UserFrame = function(_, config)
        config = safeConfig(config)
        local name         = config.Name    or "用户"
        local profile      = config.Profile or ""
        local expires      = config.Expires or ""
        local parent       = config.Parent  or contentHolder
        local buttonIcon   = config.ButtonIcon
        local names        = config.Names        or { "输入框 1", "输入框 2" }
        local placeholders = config.Placeholders or { "", "" }
        local defaults     = config.Defaults     or { "", "" }
        local onChanged    = config.OnChanged

        local TOP_H = 60
        local ROW_H = 42
        local GAP   = 4
        local EXPANDED_H = GAP + ROW_H + GAP + ROW_H + GAP

        local UserFrame = Instance.new("Frame")
        UserFrame.Size = UDim2.new(1, 0, 0, TOP_H)
        UserFrame.BackgroundTransparency = 1
        UserFrame.BorderSizePixel = 0
        UserFrame.ClipsDescendants = true
        UserFrame.Parent = parent

        local TopBar = Instance.new("Frame")
        TopBar.Size = UDim2.new(1, 0, 0, TOP_H)
        TopBar.BackgroundTransparency = 1
        TopBar.BorderSizePixel = 0
        TopBar.Parent = UserFrame

        local LogoImage = Instance.new("ImageLabel")
        LogoImage.Size = UDim2.fromOffset(45, 45)
        LogoImage.Position = UDim2.fromOffset(10, 7)
        LogoImage.BackgroundTransparency = 1
        LogoImage.Image = (profile ~= "" and profile) or "rbxasset://textures/ui/clb_robux_20@3x.png"
        LogoImage.Parent = TopBar
        Instance.new("UICorner", LogoImage).CornerRadius = UDim.new(1, 0)

        local UserLabel = Instance.new("TextLabel")
        UserLabel.Size = UDim2.new(1, -110, 0, 15)
        UserLabel.Position = UDim2.new(0, 65, 0, 12)
        UserLabel.BackgroundTransparency = 1
        UserLabel.Font = Enum.Font.GothamMedium
        UserLabel.Text = name
        UserLabel.TextColor3 = CurrentTheme.Text
        UserLabel.TextSize = 13
        UserLabel.TextTransparency = 0.2
        UserLabel.TextXAlignment = Enum.TextXAlignment.Left
        UserLabel.TextTruncate = Enum.TextTruncate.AtEnd
        UserLabel.Parent = TopBar
        AddToRegistry(UserLabel, "TextColor3", "Text")

        local UserStatusLabel = Instance.new("TextLabel")
        UserStatusLabel.Size = UDim2.new(1, -110, 0, 15)
        UserStatusLabel.Position = UDim2.new(0, 65, 0, 27)
        UserStatusLabel.BackgroundTransparency = 1
        UserStatusLabel.Font = Enum.Font.GothamMedium
        UserStatusLabel.Text = expires
        UserStatusLabel.TextColor3 = CurrentTheme.Text
        UserStatusLabel.TextSize = 13
        UserStatusLabel.TextTransparency = 0.2
        UserStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        UserStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
        UserStatusLabel.Parent = TopBar
        AddToRegistry(UserStatusLabel, "TextColor3", "Text")
        TextGradient:Skip(UserStatusLabel)

        local Btn, BtnIcon = nil, nil
        if buttonIcon and tostring(buttonIcon) ~= "" then
            Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 26, 0, 26)
            Btn.Position = UDim2.new(1, -10, 0, 17)
            Btn.AnchorPoint = Vector2.new(1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = TopBar

            BtnIcon = Instance.new("ImageLabel")
            BtnIcon.Size = UDim2.new(1, -2, 1, -2)
            BtnIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
            BtnIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            BtnIcon.BackgroundTransparency = 1
            BtnIcon.Image = "rbxassetid://" .. tostring(buttonIcon)
            BtnIcon.ImageColor3 = CurrentTheme.Text
            BtnIcon.ImageTransparency = 0.4
            BtnIcon.ScaleType = Enum.ScaleType.Fit
            BtnIcon.Parent = Btn
            AddToRegistry(BtnIcon, "ImageColor3", "Text")

            Btn.MouseEnter:Connect(function() Tween(BtnIcon, {ImageTransparency = 0.1}, 0.15) end)
            Btn.MouseLeave:Connect(function() Tween(BtnIcon, {ImageTransparency = 0.4}, 0.15) end)
        end

        local Expanded = Instance.new("Frame")
        Expanded.Size = UDim2.new(1, 0, 0, 0)
        Expanded.Position = UDim2.new(0, 0, 0, TOP_H)
        Expanded.BackgroundTransparency = 1
        Expanded.BorderSizePixel = 0
        Expanded.ClipsDescendants = true
        Expanded.Parent = UserFrame

        local Boxes = {}
        for i = 1, 2 do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, ROW_H)
            Row.Position = UDim2.new(0, 0, 0, GAP + (i - 1) * (ROW_H + GAP))
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.Parent = Expanded

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, -20, 0, 1)
            Line.Position = UDim2.new(0, 10, 1, -1)
            Line.BackgroundColor3 = CurrentTheme.Stroke
            Line.BackgroundTransparency = 0.65
            Line.BorderSizePixel = 0
            Line.Parent = Row
            AddToRegistry(Line, "BackgroundColor3", "Stroke")

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Size = UDim2.new(0.6, 0, 0, 18)
            NameLbl.Position = UDim2.new(0, 15, 0, 12)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Font = Enum.Font.GothamMedium
            NameLbl.TextSize = 13
            NameLbl.Text = names[i] or ("输入框 " .. i)
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            NameLbl.Parent = Row
            AddToRegistry(NameLbl, "TextColor3", "Text")

            local BoxContainer = Instance.new("Frame")
            BoxContainer.Size = UDim2.new(0.3, 0, 0, 28)
            BoxContainer.Position = UDim2.new(0.7, -10, 0.5, -14)
            BoxContainer.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            BoxContainer.BackgroundTransparency = 0
            BoxContainer.ClipsDescendants = true
            BoxContainer.BorderSizePixel = 0
            BoxContainer.Parent = Row
            Instance.new("UICorner", BoxContainer).CornerRadius = UDim.new(0, 6)

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Thickness = 1
            boxStroke.Transparency = 0.65
            boxStroke.Color = CurrentTheme.Stroke
            boxStroke.Parent = BoxContainer
            table.insert(ThemeListeners, function() boxStroke.Color = CurrentTheme.Stroke end)

            local Box = Instance.new("TextBox")
            Box.Text = defaults[i] or ""
            Box.PlaceholderText = placeholders[i] or ""
            Box.Size = UDim2.new(1, -10, 1, 0)
            Box.Position = UDim2.new(0, 5, 0, 0)
            Box.Font = Enum.Font.GothamBold
            Box.TextSize = 13
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.ClearTextOnFocus = false
            Box.BackgroundTransparency = 1
            Box.TextColor3 = CurrentTheme.Accent
            Box.Parent = BoxContainer
            AddToRegistry(Box, "TextColor3", "Accent")
            TextGradient:Skip(Box)

            Box.Focused:Connect(function() Tween(boxStroke, {Transparency = 0.2}, 0.15) end)
            Box.FocusLost:Connect(function() Tween(boxStroke, {Transparency = 0.65}, 0.15) end)

            Box:GetPropertyChangedSignal("Text"):Connect(function()
                local txt = Box.Text
                if i == 1 then
                    UserLabel.Text = txt
                elseif i == 2 then
                    UserStatusLabel.Text = txt
                end
                if onChanged then pcall(onChanged, i, txt) end
            end)

            Boxes[i] = Box
        end

        local opened = false
        local function toggle()
            opened = not opened
            local targetH = opened and EXPANDED_H or 0
            Tween(Expanded, {Size = UDim2.new(1, 0, 0, targetH)}, 0.28)
            Tween(UserFrame, {Size = UDim2.new(1, 0, 0, TOP_H + targetH)}, 0.28)
            if BtnIcon then
                Tween(BtnIcon, {Rotation = opened and 180 or 0}, 0.28)
            end
        end

        if Btn then Btn.MouseButton1Click:Connect(toggle) end

        local self = {}
        function self:SetUsername(n)
            local t = tostring(n or "")
            if Boxes[2] then Boxes[2].Text = t end
            UserStatusLabel.Text = t
        end
        function self:SetExpires(e)
            local t = tostring(e or "")
            if Boxes[1] then Boxes[1].Text = t end
            UserLabel.Text = t
        end
        function self:SetProfile(p) LogoImage.Image = p or "rbxasset://textures/ui/clb_robux_20@3x.png" end
        function self:SetVisible(v) UserFrame.Visible = v ~= false end
        function self:GetValue(idx) return Boxes[idx] and Boxes[idx].Text or "" end
        function self:SetValue(idx, text) if Boxes[idx] then Boxes[idx].Text = tostring(text or "") end end
        function self:GetOpened() return opened end
        function self:SetOpened(v)
            v = v == true
            if v ~= opened then toggle() end
        end
        return self
    end

    child.Video = function(_, config)
        config = safeConfig(config)
        local opts = config or {}
        local parent = opts.Parent or contentHolder
        if not parent then return end
        local radius = opts.Radius or 8
        local src = opts.Video or ""
        local looped = opts.Looped ~= false
        local vol = opts.Volume or 0
        local auto = opts.AutoPlay ~= false
        local aspect = opts.AspectRatio or "16:9"
        local function resolveMedia(s)
            if type(s) ~= "string" or s == "" then return "" end
            if s:match("^rbxassetid://") or s:match("^rbxasset://") then return s end
            if s:match("^%d+$") then return "rbxassetid://"..s end
            if s:match("^https?://") then return MediaManager:Video(s) end
            return ""
        end
        local function applyIcon(imgLabel, iconName)
            if not imgLabel then return end
            local imageMap = {play="rbxassetid://10734923549", pause="rbxassetid://10734919336", stop="rbxassetid://10734972621", volume="rbxassetid://10747376008", external="rbxassetid://10747366266"}
            imgLabel.Image = imageMap[iconName] or ""
        end
        local function parseRatio(r)
            if type(r) == "number" then return r end
            if type(r) == "string" then
                local rw, rh = r:match("(%d+):(%d+)")
                if rw and rh and tonumber(rh) ~= 0 then return tonumber(rw)/tonumber(rh) end
            end
            return 16/9
        end
        local ratioNum = parseRatio(aspect)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1,-16,0,180)
        wrap.BackgroundColor3 = CurrentTheme.Main
        wrap.BackgroundTransparency = 0.6
        wrap.BorderSizePixel = 0; wrap.ClipsDescendants = true
        wrap.Parent = parent
        AddToRegistry(wrap, "BackgroundColor3", "Main")
        local function recalcAspect()
            local w = wrap.AbsoluteSize.X
            if w > 0 and ratioNum and ratioNum > 0 then
                wrap.Size = UDim2.new(1,-16,0,math.floor(w/ratioNum))
            end
        end
        wrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcAspect)
        defer(recalcAspect)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0,radius); corner.Parent = wrap
        local resolved = resolveMedia(src)
        local hasVideo = (resolved ~= "")
        local vid = nil
        if hasVideo then
            local vfOk, vf = pcall(Instance.new, "VideoFrame")
            if vfOk and vf then
                vid = vf
                vid.Size = UDim2.fromScale(1,1)
                vid.BackgroundTransparency = 1
                vid.Looped = looped; vid.Volume = vol
                vid.ZIndex = 1; vid.Video = resolved; vid.Parent = wrap
                local vidCorner = Instance.new("UICorner")
                vidCorner.CornerRadius = UDim.new(0,radius); vidCorner.Parent = vid
            else
                hasVideo = false
            end
        end
        local placeholder = Instance.new("Frame")
        placeholder.Size = UDim2.fromScale(1,1)
        placeholder.BackgroundTransparency = 1
        placeholder.Visible = not hasVideo
        placeholder.ZIndex = 2; placeholder.Parent = wrap
        local phImg = Instance.new("ImageLabel")
        phImg.Size = UDim2.fromOffset(32,32)
        phImg.Position = UDim2.new(0.5,0,0.5,-14)
        phImg.AnchorPoint = Vector2.new(0.5,0.5)
        phImg.BackgroundTransparency = 1
        phImg.ImageTransparency = 0.4
        phImg.ZIndex = 3; phImg.Parent = placeholder
        AddToRegistry(phImg, "ImageColor3", "SubText")
        applyIcon(phImg, "play")
        local phText = Instance.new("TextLabel")
        phText.Size = UDim2.new(1,0,0,16)
        phText.Position = UDim2.new(0,0,0.5,20)
        phText.AnchorPoint = Vector2.new(0,0)
        phText.BackgroundTransparency = 1
        phText.Text = "视频不可用"
        phText.TextSize = 11
        phText.Font = Enum.Font.GothamMedium
        phText.TextTransparency = 0.5
        phText.ZIndex = 3; phText.Parent = placeholder
        AddToRegistry(phText, "TextColor3", "SubText")
        if not hasVideo then
            local mod = {Frame=wrap, Type="Video", VideoFrame=nil}
            function mod:Destroy() wrap:Destroy() end
            function mod:SetVideo(s) end
            function mod:SetVolume(v) end
            function mod:Play() end
            function mod:Pause() end
            function mod:Stop() end
            function mod:SetAspectRatio(r) end
            return mod
        end
        local cgOk, overlay = pcall(Instance.new, "CanvasGroup")
        if not cgOk or not overlay then
            if vid then vid:Destroy() vid = nil end
            placeholder.Visible = true
            local mod = {Frame=wrap, Type="Video", VideoFrame=nil}
            function mod:Destroy() wrap:Destroy() end
            function mod:SetVideo(s) end
            function mod:SetVolume(v) end
            function mod:Play() end
            function mod:Pause() end
            function mod:Stop() end
            function mod:SetAspectRatio(r) end
            return mod
        end
        overlay.Size = UDim2.new(1,0,0,54)
        overlay.Position = UDim2.new(0,0,1,0)
        overlay.AnchorPoint = Vector2.new(0,1)
        overlay.BackgroundTransparency = 1
        overlay.GroupTransparency = 1
        overlay.ZIndex = 5; overlay.Parent = wrap
        local gradFr = Instance.new("Frame")
        gradFr.Size = UDim2.fromScale(1,1)
        gradFr.BackgroundColor3 = Color3.fromRGB(0,0,0)
        gradFr.BackgroundTransparency = 0
        gradFr.BorderSizePixel = 0
        gradFr.ZIndex = 5; gradFr.Parent = overlay
        local grad = Instance.new("UIGradient")
        grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1)})
        grad.Rotation = 90; grad.Parent = gradFr
        local seekRow = Instance.new("Frame")
        seekRow.Size = UDim2.new(1,-12,0,16)
        seekRow.Position = UDim2.new(0,6,0,4)
        seekRow.BackgroundTransparency = 1
        seekRow.ZIndex = 6; seekRow.Parent = overlay
        local timeCur = Instance.new("TextLabel")
        timeCur.Size = UDim2.fromOffset(36,16)
        timeCur.BackgroundTransparency = 1
        timeCur.Text = "0:00"; timeCur.TextSize = 10
        timeCur.Font = Enum.Font.GothamMedium
        timeCur.TextColor3 = Color3.fromRGB(220,220,220)
        timeCur.ZIndex = 7; timeCur.Parent = seekRow
        TextGradient:Skip(timeCur)
        local seekContainer = Instance.new("Frame")
        seekContainer.Size = UDim2.new(1,-84,0,16)
        seekContainer.Position = UDim2.fromOffset(40,0)
        seekContainer.BackgroundTransparency = 1
        seekContainer.ZIndex = 6; seekContainer.Parent = seekRow
        local seekRail = Instance.new("TextButton")
        seekRail.Size = UDim2.new(1,0,0,5)
        seekRail.Position = UDim2.new(0,0,0.5,-2)
        seekRail.BackgroundColor3 = Color3.fromRGB(80,80,90)
        seekRail.BorderSizePixel = 0
        seekRail.ZIndex = 7; seekRail.Text = ""
        seekRail.AutoButtonColor = false; seekRail.Parent = seekContainer
        Instance.new("UICorner", seekRail).CornerRadius = UDim.new(1,0)
        local seekFill = Instance.new("Frame")
        seekFill.Size = UDim2.new(0,0,1,0)
        seekFill.BackgroundColor3 = CurrentTheme.Accent
        seekFill.BorderSizePixel = 0
        seekFill.ZIndex = 8; seekFill.Parent = seekRail
        Instance.new("UICorner", seekFill).CornerRadius = UDim.new(1,0)
        local seekKnob = Instance.new("Frame")
        seekKnob.Size = UDim2.fromOffset(12,12)
        seekKnob.Position = UDim2.new(0,0,0.5,0)
        seekKnob.AnchorPoint = Vector2.new(0.5,0.5)
        seekKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        seekKnob.BorderSizePixel = 0
        seekKnob.ZIndex = 9; seekKnob.Parent = seekRail
        Instance.new("UICorner", seekKnob).CornerRadius = UDim.new(1,0)
        local timeDur = Instance.new("TextLabel")
        timeDur.Size = UDim2.fromOffset(36,16)
        timeDur.Position = UDim2.new(1,-36,0,0)
        timeDur.BackgroundTransparency = 1
        timeDur.Text = "0:00"; timeDur.TextSize = 10
        timeDur.Font = Enum.Font.GothamMedium
        timeDur.TextColor3 = Color3.fromRGB(160,160,170)
        timeDur.ZIndex = 7; timeDur.Parent = seekRow
        TextGradient:Skip(timeDur)
        local ctrlRow = Instance.new("Frame")
        ctrlRow.Size = UDim2.new(1,-12,0,26)
        ctrlRow.Position = UDim2.new(0,6,0,24)
        ctrlRow.BackgroundTransparency = 1
        ctrlRow.ZIndex = 6; ctrlRow.Parent = overlay
        local function ctrlBtn(iconName, cb)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromOffset(22,22)
            btn.BackgroundTransparency = 1; btn.Text = ""
            btn.ZIndex = 7; btn.AutoButtonColor = false; btn.Parent = ctrlRow
            local ic = Instance.new("ImageLabel")
            ic.Size = UDim2.fromOffset(16,16)
            ic.Position = UDim2.new(0.5,0,0.5,0)
            ic.AnchorPoint = Vector2.new(0.5,0.5)
            ic.BackgroundTransparency = 1; ic.ZIndex = 8; ic.Parent = btn
            AddToRegistry(ic, "ImageColor3", "Text")
            applyIcon(ic, iconName)
            btn.MouseButton1Click:Connect(function() pcall(cb) end)
            return btn, ic
        end
        local playing = auto
        local playBtn, playIco = ctrlBtn("play", function() end)
        local pauseBtn, pauseIco = ctrlBtn("pause", function() end)
        local stopBtn, stopIco = ctrlBtn("stop", function() end)
        local volIco = Instance.new("ImageLabel")
        volIco.Size = UDim2.fromOffset(14,14)
        volIco.Position = UDim2.fromOffset(68,4)
        volIco.BackgroundTransparency = 1; volIco.ZIndex = 7; volIco.Parent = ctrlRow
        AddToRegistry(volIco, "ImageColor3", "SubText")
        applyIcon(volIco, "volume")
        local volLbl = Instance.new("TextLabel")
        volLbl.Size = UDim2.fromOffset(32,22)
        volLbl.Position = UDim2.fromOffset(84,0)
        volLbl.BackgroundTransparency = 1
        volLbl.Text = tostring(math.floor(vol*100)).."%"
        volLbl.TextSize = 10
        volLbl.Font = Enum.Font.Gotham
        volLbl.ZIndex = 7; volLbl.Parent = ctrlRow
        AddToRegistry(volLbl, "TextColor3", "SubText")
        TextGradient:Skip(volLbl)
        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        btnLayout.Padding = UDim.new(0,2); btnLayout.Parent = ctrlRow
        local ctrlVisible = false
        local fadeTimer = 0
        local function showOverlay()
            ctrlVisible = true; fadeTimer = 3
            Tween(overlay, {GroupTransparency=0}, 0.18)
        end
        local function hideOverlay()
            ctrlVisible = false
            Tween(overlay, {GroupTransparency=1}, 0.3)
        end
        local vidClickBtn = Instance.new("TextButton")
        vidClickBtn.Size = UDim2.fromScale(1,1)
        vidClickBtn.BackgroundTransparency = 1
        vidClickBtn.Text = ""; vidClickBtn.ZIndex = 4
        vidClickBtn.AutoButtonColor = false; vidClickBtn.Parent = wrap
        vidClickBtn.MouseButton1Click:Connect(function()
            if ctrlVisible then fadeTimer = 3 else showOverlay() end
        end)
        local function resetFade() fadeTimer = 3 end
        playBtn.MouseButton1Click:Connect(function()
            if vid then pcall(function() vid:Play() end) end
            playing = true; playBtn.Visible = false; pauseBtn.Visible = true; resetFade()
        end)
        pauseBtn.MouseButton1Click:Connect(function()
            if vid then pcall(function() vid:Pause() end) end
            playing = false; playBtn.Visible = true; pauseBtn.Visible = false; resetFade()
        end)
        stopBtn.MouseButton1Click:Connect(function()
            if vid then pcall(function() vid:Stop() end) end
            playing = false; playBtn.Visible = true; pauseBtn.Visible = false; resetFade()
        end)
        pauseBtn.Visible = auto; playBtn.Visible = not auto
        local seeking = false
        local function vidSeek(posX)
            resetFade()
            local rx = seekRail.AbsolutePosition.X
            local rw = seekRail.AbsoluteSize.X
            local pct = math.clamp((posX-rx)/rw,0,1)
            seekFill.Size = UDim2.new(pct,0,1,0)
            seekKnob.Position = UDim2.new(pct,0,0.5,0)
            if vid and vid.TimeLength and vid.TimeLength>0 then
                pcall(function() vid.TimePosition = vid.TimeLength * pct end)
            end
        end
        seekRail.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                seeking = true
                vidSeek(inp.Position.X)
                resetFade()
                inp.Changed:Connect(function()
                    if inp.UserInputState==Enum.UserInputState.End then seeking = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if seeking and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                vidSeek(inp.Position.X)
            end
        end)
        local function fmtTime(s) s = math.max(0, math.floor(s or 0)); return string.format("%d:%02d", math.floor(s/60), s%60) end
        local hbConn = RunService.Heartbeat:Connect(function(dt)
            if not wrap.Parent then return end
            if ctrlVisible then
                fadeTimer = fadeTimer - dt
                if fadeTimer <= 0 and not seeking then hideOverlay() end
            end
            if not vid then return end
            local dur = vid.TimeLength or 0
            local pos = 0; pcall(function() pos = vid.TimePosition end)
            if dur > 0 and not seeking then
                local pct = math.clamp(pos/dur,0,1)
                seekFill.Size = UDim2.new(pct,0,1,0)
                seekKnob.Position = UDim2.new(pct,0,0.5,0)
            end
            timeCur.Text = fmtTime(pos)
            timeDur.Text = fmtTime(dur)
        end)
        if auto and hasVideo then
            task.spawn(function()
                task.wait(0.08)
                if vid and vid.Parent then
                    pcall(function() vid:Play() end)
                    playing = true
                    pauseBtn.Visible = true
                    playBtn.Visible = false
                end
            end)
        end
        local mod = {Frame=wrap, Type="Video", VideoFrame=vid}
        function mod:Play() if vid then pcall(function() vid:Play() end); playing=true; playBtn.Visible=false; pauseBtn.Visible=true end end
        function mod:Pause() if vid then pcall(function() vid:Pause() end); playing=false; playBtn.Visible=true; pauseBtn.Visible=false end end
        function mod:Stop() if vid then pcall(function() vid:Stop() end); playing=false; playBtn.Visible=true; pauseBtn.Visible=false end end
        function mod:SetVideo(s) if vid then local r=resolveMedia(s); if r~="" then vid.Video=r; placeholder.Visible=false else placeholder.Visible=true end end end
        function mod:SetVolume(v) if vid then vid.Volume=math.clamp(v,0,1) end; volLbl.Text=tostring(math.floor(math.clamp(v,0,1)*100)).."%" end
        function mod:SetAspectRatio(r) ratioNum=parseRatio(r); recalcAspect() end
        function mod:Destroy() safeDisconnect(hbConn); wrap:Destroy() end
        return mod
    end

    child.Audio = function(_, config)
        config = safeConfig(config)
        local opts = config or {}
        local parent = opts.Parent or contentHolder
        if not parent then return end
        local title = opts.Name or opts.Title or "音频"
        local subtitle = opts.SubName or opts.SubTitle or ""
        local src = opts.Audio or opts.Sound or ""
        local vol = (opts.Volume ~= nil) and math.clamp(opts.Volume, 0, 10) or 0.5
        local looped = opts.Looped ~= false
        local auto = opts.AutoPlay ~= false
        local playOutside = opts.PlayOutsideWindow == true
        local function resolve(s, noDownload)
            local mm = MediaManager
            if mm then return mm:Audio(s, noDownload) end
            if type(s) ~= "string" or s == "" then return "" end
            if s:match("^rbxassetid://") or s:match("^rbxasset://") then return s end
            if s:match("^%d+$") then return "rbxassetid://"..s end
            return ""
        end
        local isHttp = type(src) == "string" and src:match("^https?://")
        local resolved = isHttp and resolve(src, true) or resolve(src, false)
        local pendingDownload = isHttp and (not resolved or resolved == "")
        local hasAudio = (resolved ~= nil and resolved ~= "") or pendingDownload
        local snd = nil
        local function initSound(resolvedId)
            local s2 = Instance.new("Sound")
            s2.Name = "FengAudio"
            pcall(function() s2.SoundId = resolvedId end)
            s2.Volume = vol; s2.Looped = looped
            if playOutside then s2.RollOffMaxDistance = 10000; s2.Parent = game:GetService("SoundService")
            else s2.Parent = workspace end
            return s2
        end
        if hasAudio and not pendingDownload then snd = initSound(resolved) end
        local wrapHeight = (title ~= "" or subtitle ~= "") and 118 or 96
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, -16, 0, wrapHeight)
        wrap.BackgroundColor3 = CurrentTheme.Top
        wrap.BackgroundTransparency = 0.6; wrap.BorderSizePixel = 0
        wrap.Parent = parent
        Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)
        AddToRegistry(wrap, "BackgroundColor3", "Top")
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10); padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = wrap
        local topRow = Instance.new("Frame")
        topRow.Size = UDim2.new(1, 0, 0, (title ~= "" or subtitle ~= "") and 38 or 28)
        topRow.BackgroundTransparency = 1; topRow.Parent = wrap
        local audioIcon = Instance.new("ImageLabel")
        audioIcon.Size = UDim2.fromOffset(20, 20)
        audioIcon.Position = UDim2.new(0, 0, 0.5, 0)
        audioIcon.AnchorPoint = Vector2.new(0, 0.5)
        audioIcon.BackgroundTransparency = 1
        audioIcon.Image = "rbxassetid://10747376008"
        audioIcon.ZIndex = 2; audioIcon.Parent = topRow
        AddToRegistry(audioIcon, "ImageColor3", hasAudio and "Accent" or "SubText")
        local titleHolder = Instance.new("Frame")
        titleHolder.Size = UDim2.new(1, -110, 1, 0)
        titleHolder.Position = UDim2.new(0, 28, 0, 0)
        titleHolder.BackgroundTransparency = 1
        titleHolder.ZIndex = 2; titleHolder.Parent = topRow
        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(1, 0, 0, 16)
        statusLbl.Position = UDim2.new(0, 0, 0, (title ~= "" or subtitle ~= "") and 2 or 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = (title ~= "" and title) or (hasAudio and "音频" or "无音频源")
        statusLbl.TextSize = (title ~= "" or subtitle ~= "") and 12 or 11
        statusLbl.Font = (title ~= "" or subtitle ~= "") and Enum.Font.GothamBold or Enum.Font.Gotham
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
        statusLbl.ZIndex = 2; statusLbl.Parent = titleHolder
        AddToRegistry(statusLbl, "TextColor3", "Text")
        if subtitle ~= "" then
            local subtitleLbl = Instance.new("TextLabel")
            subtitleLbl.Size = UDim2.new(1, 0, 0, 13)
            subtitleLbl.Position = UDim2.new(0, 0, 0, 20)
            subtitleLbl.BackgroundTransparency = 1
            subtitleLbl.Text = subtitle; subtitleLbl.TextSize = 10
            subtitleLbl.Font = Enum.Font.Gotham
            subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            subtitleLbl.ZIndex = 2; subtitleLbl.Parent = titleHolder
            AddToRegistry(subtitleLbl, "TextColor3", "SubText")
        end
        local controls = Instance.new("Frame")
        controls.Size = UDim2.new(0, 116, 1, 0)
        controls.Position = UDim2.new(1, 0, 0, 0)
        controls.AnchorPoint = Vector2.new(1, 0)
        controls.BackgroundTransparency = 1
        controls.Visible = hasAudio; controls.Parent = topRow
        local ctrlLayout = Instance.new("UIListLayout")
        ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
        ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        ctrlLayout.Padding = UDim.new(0, 4); ctrlLayout.Parent = controls
        local function ctrlBtn(iconId, cb)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromOffset(24, 24)
            btn.BackgroundTransparency = 1; btn.Text = ""
            btn.AutoButtonColor = false; btn.ZIndex = 3; btn.Parent = controls
            local ic = Instance.new("ImageLabel")
            ic.Size = UDim2.fromOffset(16, 16)
            ic.Position = UDim2.new(0.5, 0, 0.5, 0)
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.BackgroundTransparency = 1; ic.ZIndex = 4; ic.Parent = btn
            AddToRegistry(ic, "ImageColor3", "Text")
            local icons = { play = "rbxassetid://10734923549", pause = "rbxassetid://10734919336", stop = "rbxassetid://10734972621" }
            ic.Image = icons[iconId] or ""
            btn.MouseButton1Click:Connect(function() pcall(cb) end)
            return btn, ic
        end
        local playing = false
        local playBtn, pauseBtn
        if hasAudio then
            local _downloading = false
            local function _doPlay()
                if not snd then return end
                pcall(function() snd:Play() end)
                playing = true
                if playBtn then playBtn.Visible = false end
                if pauseBtn then pauseBtn.Visible = true end
            end
            local function _triggerPlay()
                if _downloading then return end
                if snd then _doPlay(); return end
                if pendingDownload then
                    _downloading = true
                    task.spawn(function()
                        local got = resolve(src, false)
                        _downloading = false
                        if got and got ~= "" then
                            pendingDownload = false
                            snd = initSound(got)
                            _doPlay()
                        end
                    end)
                end
            end
            playBtn = ctrlBtn("play", _triggerPlay)
            pauseBtn = ctrlBtn("pause", function()
                if snd then snd:Pause() end
                playing = false
                if playBtn then playBtn.Visible = true end
                if pauseBtn then pauseBtn.Visible = false end
            end)
            pauseBtn.Visible = false
            ctrlBtn("stop", function()
                if snd then pcall(function() snd:Stop(); snd.TimePosition = 0 end) end
                playing = false
                if playBtn then playBtn.Visible = true end
                if pauseBtn then pauseBtn.Visible = false end
            end)
            if auto and snd then _doPlay() end
        end
        local seekRowOffset = (title ~= "" or subtitle ~= "") and 56 or 36
        local seekRow = Instance.new("Frame")
        seekRow.Size = UDim2.new(1, 0, 0, 24)
        seekRow.Position = UDim2.new(0, 0, 0, seekRowOffset)
        seekRow.BackgroundTransparency = 1
        seekRow.Visible = hasAudio; seekRow.Parent = wrap
        local curLbl = Instance.new("TextLabel")
        curLbl.Size = UDim2.fromOffset(34, 20)
        curLbl.Position = UDim2.new(0, 0, 0.5, 0)
        curLbl.AnchorPoint = Vector2.new(0, 0.5)
        curLbl.BackgroundTransparency = 1
        curLbl.Text = "0:00"; curLbl.TextSize = 10
        curLbl.Font = Enum.Font.Gotham
        curLbl.TextXAlignment = Enum.TextXAlignment.Left
        curLbl.Parent = seekRow
        AddToRegistry(curLbl, "TextColor3", "SubText")
        TextGradient:Skip(curLbl)
        local durLbl = Instance.new("TextLabel")
        durLbl.Size = UDim2.fromOffset(34, 20)
        durLbl.Position = UDim2.new(1, 0, 0.5, 0)
        durLbl.AnchorPoint = Vector2.new(1, 0.5)
        durLbl.BackgroundTransparency = 1
        durLbl.Text = "0:00"; durLbl.TextSize = 10
        durLbl.Font = Enum.Font.Gotham
        durLbl.TextXAlignment = Enum.TextXAlignment.Right
        durLbl.Parent = seekRow
        AddToRegistry(durLbl, "TextColor3", "SubText")
        TextGradient:Skip(durLbl)
        local rail = Instance.new("Frame")
        rail.Size = UDim2.new(1, -76, 0, 4)
        rail.Position = UDim2.new(0, 38, 0.5, 0)
        rail.AnchorPoint = Vector2.new(0, 0.5)
        rail.BackgroundColor3 = CurrentTheme.SubText
        rail.BackgroundTransparency = 0.65
        rail.Parent = seekRow
        AddToRegistry(rail, "BackgroundColor3", "SubText")
        Instance.new("UICorner", rail).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = CurrentTheme.Accent
        fill.Parent = rail
        AddToRegistry(fill, "BackgroundColor3", "Accent")
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.BackgroundColor3 = CurrentTheme.Accent
        knob.Parent = rail
        AddToRegistry(knob, "BackgroundColor3", "Accent")
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local function fmtTime(s) s = math.max(0, math.floor(s or 0)); return string.format("%d:%02d", math.floor(s/60), s%60) end
        local dragging = false
        local function seekTo(inputX)
            if not snd then return end
            local railX = rail.AbsolutePosition.X
            local railW = rail.AbsoluteSize.X
            if railW <= 0 then return end
            local pct = math.clamp((inputX - railX) / railW, 0, 1)
            local dur = snd.TimeLength or 0
            if dur > 0 then pcall(function() snd.TimePosition = pct * dur end) end
        end
        rail.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; seekTo(inp.Position.X)
            end
        end)
        rail.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                seekTo(inp.Position.X)
            end
        end)
        local hbConn = RunService.Heartbeat:Connect(function()
            if not wrap.Parent then return end
            if not snd then return end
            local dur = snd.TimeLength or 0
            local pos = snd.TimePosition or 0
            curLbl.Text = fmtTime(pos)
            durLbl.Text = fmtTime(dur)
            local pct = dur > 0 and (pos / dur) or 0
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
        end)
        local mod = { Frame = wrap, Type = "Audio", Sound = snd }
        function mod:Play() if snd then pcall(function() snd:Play() end) end end
        function mod:Pause() if snd then pcall(function() snd:Pause() end) end end
        function mod:Stop() if snd then pcall(function() snd:Stop() end) end end
        function mod:SetVolume(v) if snd then snd.Volume = math.clamp(v, 0, 10) end end
        function mod:Destroy() safeDisconnect(hbConn); if snd then pcall(function() snd:Stop(); snd:Destroy() end) end; wrap:Destroy() end
        return mod
    end

    child.Social = function(_, config)
        config = safeConfig(config)
        local parent = config.Parent or contentHolder
        if not parent then return end
        local displayName = tostring(config.Name or config.DisplayName or "")
        local subName = tostring(config.SubName or config.Subtitle or "")
        local platform = tostring(config.SmlName or config.Platform or "")
        local avatarSrc = config.Logo or config.Avatar or ""
        local copyText = tostring(config.copy or "")
        local buttonText = tostring(config.Cbn or "复制")
        if displayName == "" then displayName = "用户" end
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, 64)
        wrap.BackgroundTransparency = 1; wrap.BorderSizePixel = 0
        wrap.Parent = parent
        local avatarBg = Instance.new("Frame")
        avatarBg.Size = UDim2.fromOffset(42, 42)
        avatarBg.Position = UDim2.new(0, 11, 0.5, 0)
        avatarBg.AnchorPoint = Vector2.new(0, 0.5)
        avatarBg.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        avatarBg.BorderSizePixel = 0; avatarBg.Parent = wrap
        avatarBg.ClipsDescendants = true
        Instance.new("UICorner", avatarBg).CornerRadius = UDim.new(1, 0)
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.fromScale(1, 1)
        avatarImg.BackgroundTransparency = 1; avatarImg.Parent = avatarBg
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Text = displayName
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(1, -140, 0, 16)
        nameLbl.Position = UDim2.new(0, 62, 0, 9)
        nameLbl.Parent = wrap
        AddToRegistry(nameLbl, "TextColor3", "Text")
        if subName ~= "" then
            local subNameLbl = Instance.new("TextLabel")
            subNameLbl.Text = subName
            subNameLbl.Font = Enum.Font.Gotham
            subNameLbl.TextSize = 11
            subNameLbl.TextXAlignment = Enum.TextXAlignment.Left
            subNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            subNameLbl.BackgroundTransparency = 1
            subNameLbl.Size = UDim2.new(1, -140, 0, 13)
            subNameLbl.Position = UDim2.new(0, 62, 0, 27)
            subNameLbl.Parent = wrap
            AddToRegistry(subNameLbl, "TextColor3", "SubText")
            TextGradient:Skip(subNameLbl)
        end
        if platform ~= "" then
            local platformLbl = Instance.new("TextLabel")
            platformLbl.Text = platform
            platformLbl.Font = Enum.Font.Gotham
            platformLbl.TextSize = 10
            platformLbl.TextTransparency = 0.3
            platformLbl.TextXAlignment = Enum.TextXAlignment.Left
            platformLbl.BackgroundTransparency = 1
            platformLbl.Size = UDim2.new(1, -140, 0, 12)
            platformLbl.Position = UDim2.new(0, 62, 0, subName ~= "" and 42 or 27)
            platformLbl.Parent = wrap
            AddToRegistry(platformLbl, "TextColor3", "SubText")
            TextGradient:Skip(platformLbl)
        end
        if copyText ~= "" then
            local copyBtn = Instance.new("TextButton")
            copyBtn.Text = buttonText
            copyBtn.Size = UDim2.fromOffset(52, 26)
            copyBtn.Position = UDim2.new(1, -11, 0.5, 0)
            copyBtn.AnchorPoint = Vector2.new(1, 0.5)
            copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyBtn.Font = Enum.Font.GothamMedium
            copyBtn.TextSize = 12
            copyBtn.BackgroundColor3 = Color3.fromRGB(39, 40, 49)
            copyBtn.BorderSizePixel = 0; copyBtn.Parent = wrap
            Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
            copyBtn.MouseButton1Click:Connect(function()
                pcall(function() toclipboard(copyText) end)
            end)
        end
        task.spawn(function()
            local imgUrl = nil
            if avatarSrc ~= "" then
                if avatarSrc:match("^rbxassetid://") or avatarSrc:match("^rbxasset://") or avatarSrc:match("^http") then
                    imgUrl = avatarSrc
                elseif tonumber(avatarSrc) then
                    imgUrl = "rbxassetid://"..avatarSrc
                end
            end
            if imgUrl and imgUrl ~= "" then
                local ok, asset = pcall(function() return MediaManager:Image(imgUrl) end)
                if ok and asset and asset ~= "" then avatarImg.Image = asset end
            end
        end)
        local mod = { Frame = wrap, Type = "Social" }
        function mod:SetName(n) displayName = tostring(n or ""); nameLbl.Text = displayName end
        function mod:Destroy() wrap:Destroy() end
        return mod
    end

    child.Paragraph = function(_, config)
        config = safeConfig(config)
        local title = config.Name or ""
        local content = config.Content or ""
        local parent = config.Parent or contentHolder
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
        frame.Parent = parent
        local labelHolder = Instance.new("Frame")
        labelHolder.Size = UDim2.new(1, -20, 0, 0)
        labelHolder.Position = UDim2.new(0, 10, 0, 0)
        labelHolder.BackgroundTransparency = 1
        labelHolder.AutomaticSize = Enum.AutomaticSize.Y
        labelHolder.Parent = frame
        local holderLayout = Instance.new("UIListLayout")
        holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        holderLayout.Parent = labelHolder
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 13); padding.PaddingBottom = UDim.new(0, 13)
        padding.Parent = labelHolder
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 14)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamMedium
        titleLabel.Text = title; titleLabel.TextSize = 13
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.RichText = true; titleLabel.Parent = labelHolder
        AddToRegistry(titleLabel, "TextColor3", "Text")
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Size = UDim2.new(1, 0, 0, 14)
        contentLabel.BackgroundTransparency = 1
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.Text = content; contentLabel.TextSize = 12
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextWrapped = true
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.RichText = true; contentLabel.Parent = labelHolder
        AddToRegistry(contentLabel, "TextColor3", "SubText")
        TextGradient:Skip(contentLabel)
        local locked = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local lockFrame, lockLabel = createLockOverlay(frame, lockedTitle)
        lockFrame.Visible = locked
        local function updateLock(st) locked = st; lockFrame.Visible = st end
        local self = {}
        function self.SetName(n) titleLabel.Text = n end
        function self.SetContent(c) contentLabel.Text = c end
        function self.SetVisible(state) frame.Visible = state end
        function self.Destroy() frame:Destroy() end
        function self.Lock(t) updateLock(true); if t then lockLabel.Text = t; lockedTitle = t end end
        function self.Unlock() updateLock(false) end
        function self.IsLocked() return locked end
        return self
    end

    child.Viewport = function(_, config)
        config = safeConfig(config)
        local opts = config or {}
        local parent = opts.Parent or contentHolder
        if not parent then return end
        local UIS = UserInputService
        local height = opts.Height or 200
        local focused = (opts.Focused ~= false)
        local interactive = (opts.Interactive ~= false)
        local camera = opts.Camera or Instance.new("Camera")
        local obj = opts.Object
        local aspectRatio = opts.AspectRatio
        local radius = opts.Radius or 8
        assert(obj, "Viewport - Missing Object")
        local function parseRatio(r)
            if type(r) == "number" then return r end
            if type(r) == "string" then
                local w, h = r:match("(%d+):(%d+)")
                if w and h and tonumber(h) ~= 0 then return tonumber(w)/tonumber(h) end
            end
            return nil
        end
        local wrap = Instance.new("Frame")
        wrap.Name = "ViewportHolder"
        wrap.Size = UDim2.new(1,-16,0,height)
        wrap.BackgroundTransparency = 0.92
        wrap.BackgroundColor3 = CurrentTheme.Main
        wrap.BorderSizePixel = 0; wrap.ClipsDescendants = true
        wrap.Parent = parent
        AddToRegistry(wrap, "BackgroundColor3", "Main")
        local wrapStroke = Instance.new("UIStroke")
        wrapStroke.Thickness = 1
        wrapStroke.Color = CurrentTheme.Stroke
        wrapStroke.Transparency = 0.6
        wrapStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        wrapStroke.Parent = wrap
        table.insert(ThemeListeners, function() wrapStroke.Color = CurrentTheme.Stroke end)
        local wrapCorner = Instance.new("UICorner")
        wrapCorner.CornerRadius = UDim.new(0,radius); wrapCorner.Parent = wrap
        local ratioNum = parseRatio(aspectRatio)
        local function recalcAspect()
            if not ratioNum or ratioNum <= 0 then return end
            local w = wrap.AbsoluteSize.X
            if w > 0 then wrap.Size = UDim2.new(1,-16,0,math.floor(w/ratioNum)) end
        end
        wrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcAspect)
        defer(recalcAspect)
        local bg = Instance.new("ImageLabel")
        bg.Size = UDim2.fromScale(1,1)
        bg.BackgroundTransparency = 0.1
        bg.BorderSizePixel = 0
        bg.Image = ""; bg.BackgroundColor3 = Color3.fromRGB(15,15,20)
        bg.Parent = wrap
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0,radius); bgCorner.Parent = bg
        AddToRegistry(bg, "BackgroundColor3", "Main")
        local vp = Instance.new("ViewportFrame")
        vp.Name = "Viewport"
        vp.Size = UDim2.fromScale(1,1)
        vp.BackgroundTransparency = 1
        vp.CurrentCamera = camera
        vp.Active = interactive; vp.Parent = wrap
        obj.Parent = vp
        local Dragging = false
        local Pinching = false
        local LastMousePos = nil
        local ScrollFrameRef = nil
        local function findScrollFrame(inst)
            while inst do
                if inst:IsA("ScrollingFrame") then return inst end
                inst = inst.Parent
            end
            return nil
        end
        ScrollFrameRef = findScrollFrame(wrap)
        local function isMouseInViewport(pos)
            local ap = vp.AbsolutePosition
            local as = vp.AbsoluteSize
            return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
        end
        local function focusCamera()
            local mpos = obj:GetPivot().Position
            local size = obj:IsA("BasePart") and obj.Size or select(2, obj:GetBoundingBox(0))
            local ext = math.max(size.X, size.Y, size.Z)
            camera.CFrame = CFrame.new(mpos + Vector3.new(0, ext/2, ext*2), mpos)
        end
        if focused then defer(focusCamera) end
        vp.MouseEnter:Connect(function()
            if interactive and ScrollFrameRef then ScrollFrameRef.ScrollingEnabled = false end
        end)
        vp.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                if ScrollFrameRef then ScrollFrameRef.ScrollingEnabled = true end
            end
        end)
        vp.InputBegan:Connect(function(inp)
            if interactive then
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or (inp.UserInputType == Enum.UserInputType.Touch and not Pinching) then
                    Dragging = true; LastMousePos = inp.Position
                end
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if interactive then
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if interactive and Dragging and not Pinching then
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    local delta = inp.Position - LastMousePos
                    LastMousePos = inp.Position
                    local pos = obj:GetPivot().Position
                    local ry = CFrame.fromAxisAngle(Vector3.new(0,1,0), -delta.X*0.02)
                    camera.CFrame = CFrame.new(pos) * ry * CFrame.new(-pos) * camera.CFrame
                    local rx = CFrame.fromAxisAngle(camera.CFrame.RightVector, -delta.Y*0.02)
                    local pitched = CFrame.new(pos) * rx * CFrame.new(-pos) * camera.CFrame
                    if pitched.UpVector.Y > 0.1 then camera.CFrame = pitched end
                end
            end
        end)
        vp.InputChanged:Connect(function(inp)
            if interactive then
                if inp.UserInputType == Enum.UserInputType.MouseWheel then
                    if not isMouseInViewport(UIS:GetMouseLocation()) then return end
                    local zoom = inp.Position.Z * 2
                    camera.CFrame = camera.CFrame + camera.CFrame.LookVector * zoom
                end
            end
        end)
        local self = {
            Frame = wrap, Type = "Viewport", Object = obj, Camera = camera,
            Interactive = interactive, Height = height, Focused = focused, Value = nil
        }
        function self:SetObject(newObj, clone)
            if clone then newObj = newObj:Clone() end
            if self.Object then self.Object:Destroy() end
            self.Object = newObj; self.Object.Parent = vp
            if self.Focused then focusCamera() end
        end
        function self:SetHeight(h) self.Height = h; wrap.Size = UDim2.new(1,-16,0,h) end
        function self:SetAspectRatio(ratio) ratioNum = parseRatio(ratio); if ratioNum then recalcAspect() else wrap.Size = UDim2.new(1,-16,0,self.Height) end end
        function self:Focus() if self.Object then focusCamera() end end
        function self:SetCamera(cam) self.Camera = cam; vp.CurrentCamera = cam end
        function self:SetInteractive(val) self.Interactive = val; vp.Active = val end
        function self:SetValue(dist)
            local ok, mpos = pcall(function() return self.Object:GetPivot().Position end)
            if not ok then return end
            local dir = (self.Camera.CFrame.Position - mpos)
            if dir.Magnitude < 1e-4 then dir = Vector3.new(0,0,1) end
            dir = dir.Unit
            self.Camera.CFrame = CFrame.new(mpos + dir * dist, mpos)
            self.Value = dist
        end
        function self:Destroy() wrap:Destroy() end
        return self
    end

    child.Tabbox = function(_, config)
        if type(config) == "string" then config = { Name = config } end
        config = config or {}
        local tabboxName = config.Name or "Tabbox"
        local parent = config.Parent or contentContainer or parent
        if not parent then return nil end

        local tabboxObj = { Tabs = {}, ActiveTab = nil }

        local tabboxFrame = Instance.new("Frame")
        tabboxFrame.Name = "TabboxFrame"
        tabboxFrame.Size = UDim2.new(1, -5, 0, 0)
        tabboxFrame.BackgroundColor3 = CurrentTheme.Main
        tabboxFrame.BackgroundTransparency = 0.5
        tabboxFrame.BorderSizePixel = 0
        tabboxFrame.ClipsDescendants = true
        tabboxFrame.Parent = parent
        Instance.new("UICorner", tabboxFrame).CornerRadius = UDim.new(0, 10)
        AddToRegistry(tabboxFrame, "BackgroundColor3", "Main")

        local tabboxStroke = Instance.new("UIStroke")
        tabboxStroke.Thickness = 1
        tabboxStroke.Transparency = 0.65
        tabboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        tabboxStroke.Parent = tabboxFrame
        AddToRegistry(tabboxStroke, "Color", "Stroke")

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "TabboxTitle"
        titleLbl.Size = UDim2.new(1, -20, 0, 15)
        titleLbl.Position = UDim2.new(0, 10, 0, 5)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamMedium
        titleLbl.TextSize = 11
        titleLbl.Text = tabboxName
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTransparency = 0.5
        titleLbl.Parent = tabboxFrame
        AddToRegistry(titleLbl, "TextColor3", "Text")
        TextGradient:Skip(titleLbl)

        local buttonHolder = Instance.new("Frame")
        buttonHolder.Name = "TabboxButtons"
        buttonHolder.Size = UDim2.new(1, -16, 0, 26)
        buttonHolder.Position = UDim2.new(0, 8, 0, 24)
        buttonHolder.BackgroundTransparency = 1
        buttonHolder.Parent = tabboxFrame
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
        buttonLayout.Padding = UDim.new(0, 5)
        buttonLayout.Parent = buttonHolder

        local contentWrap = Instance.new("Frame")
        contentWrap.Name = "TabboxContent"
        contentWrap.Size = UDim2.new(1, -10, 0, 0)
        contentWrap.Position = UDim2.new(0, 5, 0, 56)
        contentWrap.BackgroundTransparency = 1
        contentWrap.Parent = tabboxFrame

        local HEADER_H = 56

        local function refreshHeight()
            local contentH = 0
            if tabboxObj.ActiveTab and tabboxObj.ActiveTab.ContentLayout then
                contentH = tabboxObj.ActiveTab.ContentLayout.AbsoluteContentSize.Y
            end
            local totalH = HEADER_H + contentH + 8
            TweenService:Create(tabboxFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                Size = UDim2.new(1, -5, 0, totalH)
            }):Play()
            contentWrap.Size = UDim2.new(1, -10, 0, contentH)
        end

        tabboxObj.AddTab = function(_, tabConfig)
            if type(tabConfig) == "string" then tabConfig = { Name = tabConfig } end
            tabConfig = tabConfig or {}
            local tabName = tabConfig.Name or "Tab"

            local subTab = { Name = tabName, Icon = tabConfig.Icon }

            local btn = Instance.new("TextButton")
            btn.Name = "SubTabButton"
            btn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = buttonHolder
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Thickness = 1
            btnStroke.Transparency = 1
            btnStroke.Color = CurrentTheme.Stroke
            btnStroke.Parent = btn
            table.insert(ThemeListeners, function() btnStroke.Color = CurrentTheme.Stroke end)

            local btnLabel = Instance.new("TextLabel")
            btnLabel.Size = UDim2.new(1, 0, 1, 0)
            btnLabel.BackgroundTransparency = 1
            btnLabel.Font = Enum.Font.GothamMedium
            btnLabel.Text = tabName
            btnLabel.TextSize = 11
            btnLabel.TextTransparency = 0.5
            btnLabel.Parent = btn
            AddToRegistry(btnLabel, "TextColor3", "Text")

            local txtSize = TextService:GetTextSize(tabName, 11, Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge))
            btn.Size = UDim2.new(0, txtSize.X + 24, 1, 0)

            local contentFrame = Instance.new("Frame")
            contentFrame.Name = "SubTabContent"
            contentFrame.Size = UDim2.new(1, 0, 0, 0)
            contentFrame.AutomaticSize = Enum.AutomaticSize.Y
            contentFrame.BackgroundTransparency = 1
            contentFrame.Visible = false
            contentFrame.Parent = contentWrap

            local contentList = Instance.new("UIListLayout")
            contentList.Padding = UDim.new(0, 0)
            contentList.SortOrder = Enum.SortOrder.LayoutOrder
            contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            contentList.Parent = contentFrame

            subTab.ContentLayout = contentList
            subTab.ContentFrame = contentFrame

            local function setActive(active)
                if active then
                    btn.BackgroundTransparency = 0.5
                    btnStroke.Transparency = 0.65
                    btnLabel.TextTransparency = 0
                    contentFrame.Visible = true
                else
                    btn.BackgroundTransparency = 1
                    btnStroke.Transparency = 1
                    btnLabel.TextTransparency = 0.5
                    contentFrame.Visible = false
                end
            end
            subTab.SetActive = setActive

            btn.MouseButton1Click:Connect(function()
                tabboxObj.ActiveTab = subTab
                for _, t in ipairs(tabboxObj.Tabs) do
                    t:SetActive(t == subTab)
                end
                refreshHeight()
            end)

            table.insert(tabboxObj.Tabs, subTab)

            if not tabboxObj.ActiveTab then
                tabboxObj.ActiveTab = subTab
                setActive(true)
            else
                setActive(false)
            end

            contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if tabboxObj.ActiveTab == subTab then
                    refreshHeight()
                end
            end)

            local subBuilder = createSectionBuilder(contentFrame, contentFrame, elementWidth, windowCount, win)
            return setmetatable({}, {
                __index = function(_, key)
                    local fn = subBuilder[key]
                    if key == "Section" then
                        return function(self, cfg) return fn(subBuilder, cfg) end
                    end
                    if type(fn) == "function" then
                        return function(self, cfg)
                            cfg = cfg or {}
                            if type(cfg) == "table" and cfg.Parent == nil then
                                cfg.Parent = contentFrame
                            end
                            return fn(subBuilder, cfg)
                        end
                    end
                    return fn
                end
            })
        end

        tabboxObj.SetVisible = function(_, vis) tabboxFrame.Visible = vis end
        tabboxObj.Destroy = function(_) tabboxFrame:Destroy() end

        refreshHeight()
        return tabboxObj
    end

    child.AddCenterTabbox = function(self, name)
        return self:Tabbox({ Name = name })
    end

    local functions = {}
    for k, v in pairs(child) do functions[k] = v end

    local function createSection(_, config)
        if type(config) == "string" then config = { Name = config }
        elseif type(config) ~= "table" then config = {} end

        local tabEntries = {}
        for i = 1, #config do
            local entry = config[i]
            if type(entry) == "table" and entry.Key ~= nil then
                table.insert(tabEntries, entry)
            end
        end
        local hasTabs = #tabEntries > 0

        local sectionTitle    = config.Name or config.Title or ""
        local sectionSubtitle = config.SubName or config.Subtitle or ""
        local sectionIcon     = config.Logo or config.Icon or nil
        local collapsible     = config.Collapsible == true
        local collapsed       = collapsible and (config.Collapsed == false)
        local locked      = config.Locked == true
        local lockedTitle = config.TextLocked or config.LockMessage or "已锁定"
        local hasTitle    = (sectionTitle ~= "")
        local hasSubtitle = (sectionSubtitle ~= "")
        local hasIcon     = (sectionIcon ~= nil)
        local hasHeader   = hasTitle or hasSubtitle or hasIcon
        local HEADER_LEFT = 12
        local ARROW_W     = collapsible and 26 or 0
        local ICON_SIZE = hasSubtitle and 40 or 32
        local TITLE_SIZE = 15
        local TITLE_H    = 20
        local SUB_SIZE = 12
        local SUB_H    = 16
        local SUB_GAP  = 2
        local HEADER_H
        if hasHeader then HEADER_H = hasSubtitle and 56 or 44 else HEADER_H = 4 end
        local COLLAPSED_H
        if hasSubtitle then COLLAPSED_H = 50
        elseif hasHeader then COLLAPSED_H = 40
        else COLLAPSED_H = collapsible and 40 or 4 end
        local CONTENT_TOP = hasHeader and (HEADER_H + 4) or 4
        local ICON_TOP       = math.floor((COLLAPSED_H - ICON_SIZE) / 2)
        local TEXT_BLOCK_H   = hasSubtitle and (TITLE_H + SUB_GAP + SUB_H) or TITLE_H
        local TEXT_BLOCK_TOP = math.floor((COLLAPSED_H - TEXT_BLOCK_H) / 2)
        local TITLE_TOP      = TEXT_BLOCK_TOP
        local SUB_TOP        = TEXT_BLOCK_TOP + TITLE_H + SUB_GAP
        local ARROW_TOP      = math.floor((COLLAPSED_H - 18) / 2)
        local MIUI_TWEEN = TweenInfo.new(0.3, Enum.EasingStyle.Quart)

        local sectionFrame = Instance.new("Frame")
        sectionFrame.Size = UDim2.new(1, -5, 0, 0)
        sectionFrame.AnchorPoint = Vector2.new(0, 0)
        sectionFrame.Position = UDim2.new(0, 0, 0, 0)
        sectionFrame.BackgroundTransparency = 1
        sectionFrame.ClipsDescendants = true; sectionFrame.Parent = parent

        local contentContainer = Instance.new("Frame")
        contentContainer.Size = UDim2.new(1, -5, 0, 0)
        contentContainer.Position = UDim2.new(0, 0, 0, 0)
        contentContainer.AnchorPoint = Vector2.new(0, 0)
        contentContainer.BackgroundTransparency = 0.5
        contentContainer.ClipsDescendants = true
        contentContainer.Parent = sectionFrame
        AddToRegistry(contentContainer, "BackgroundColor3", "Main")

        local contentStroke = Instance.new("UIStroke")
        contentStroke.Thickness = 1; contentStroke.Transparency = 0.65
        contentStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        contentStroke.Parent = contentContainer
        AddToRegistry(contentStroke, "Color", "Stroke")

        local contentCorner = Instance.new("UICorner")
        contentCorner.CornerRadius = UDim.new(0, 10); contentCorner.Parent = contentContainer

        local iconLabel = nil
        local iconGap = 0
        if hasIcon then
            iconLabel = Instance.new("ImageLabel")
            iconLabel.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
            iconLabel.Position = UDim2.new(0, HEADER_LEFT, 0, ICON_TOP)
            iconLabel.BackgroundTransparency = 1
            iconLabel.ImageColor3 = Color3.new(1, 1, 1)
            if tonumber(sectionIcon) then iconLabel.Image = "rbxassetid://"..tostring(sectionIcon)
            else iconLabel.Image = tostring(sectionIcon) end
            Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 8)
            iconLabel.Parent = contentContainer
            AddToRegistry(iconLabel, "ImageColor3", "Text")
            iconGap = ICON_SIZE + 10
        end

        local titleLabel = nil
        if hasTitle then
            titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -(HEADER_LEFT * 2 + iconGap + ARROW_W), 0, TITLE_H)
            titleLabel.Position = UDim2.new(0, HEADER_LEFT + iconGap, 0, TITLE_TOP)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.Text = sectionTitle; titleLabel.TextSize = TITLE_SIZE
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextYAlignment = Enum.TextYAlignment.Center
            titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
            titleLabel.TextColor3 = CurrentTheme.Accent
            titleLabel.Parent = contentContainer
            AddToRegistry(titleLabel, "TextColor3", "Accent")
        end

        local subtitleLabel = nil
        if hasSubtitle then
            subtitleLabel = Instance.new("TextLabel")
            subtitleLabel.Size = UDim2.new(1, -(HEADER_LEFT * 2 + iconGap + ARROW_W), 0, SUB_H)
            subtitleLabel.Position = UDim2.new(0, HEADER_LEFT + iconGap, 0, SUB_TOP)
            subtitleLabel.BackgroundTransparency = 1
            subtitleLabel.Font = Enum.Font.Gotham
            subtitleLabel.Text = sectionSubtitle; subtitleLabel.TextSize = SUB_SIZE
            subtitleLabel.TextTransparency = 0.4
            subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
            subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
            subtitleLabel.Parent = contentContainer
            AddToRegistry(subtitleLabel, "TextColor3", "SubText")
            TextGradient:Skip(subtitleLabel)
        end

        local collapseArrow = nil
        if collapsible then
            collapseArrow = Instance.new("ImageLabel")
            collapseArrow.Size = UDim2.new(0, 18, 0, 18)
            collapseArrow.AnchorPoint = Vector2.new(1, 0.5)
            collapseArrow.Position = UDim2.new(1, -10, 0, ARROW_TOP + 9)
            collapseArrow.BackgroundTransparency = 1
            collapseArrow.Image = "rbxassetid://122444883127455"
            collapseArrow.ImageColor3 = CurrentTheme.Text
            collapseArrow.ImageTransparency = 0.35
            collapseArrow.ScaleType = Enum.ScaleType.Fit
            collapseArrow.Rotation = collapsed and 180 or 0
            collapseArrow.Parent = contentContainer
            AddToRegistry(collapseArrow, "ImageColor3", "Text")
        end

        local contentHolder = Instance.new("Frame")
        contentHolder.Size = UDim2.new(1, -13, 0, 0)
        contentHolder.Position = UDim2.new(0, 8, 0, CONTENT_TOP)
        contentHolder.AnchorPoint = Vector2.new(0, 0)
        contentHolder.BackgroundTransparency = 1
        contentHolder.AutomaticSize = Enum.AutomaticSize.None
        contentHolder.ClipsDescendants = false
        contentHolder.Parent = contentContainer
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 0)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        contentLayout.Parent = contentHolder

        local bottomPadding = Instance.new("Frame")
        bottomPadding.Size = UDim2.new(1, 0, 0, 4)
        bottomPadding.BackgroundTransparency = 1
        bottomPadding.LayoutOrder = 9999
        bottomPadding.Parent = contentHolder

        contentContainer.Visible = true; contentHolder.Visible = true

        local lockFrame, lockLabel = createLockOverlay(sectionFrame, lockedTitle)
        lockFrame.Size = UDim2.new(1, -5, 1, 0)
        lockFrame.Position = UDim2.new(0, 0, 0, 0)
        lockFrame.AnchorPoint = Vector2.new(0, 0)
        local _lockCorner = lockFrame:FindFirstChildOfClass("UICorner")
        if _lockCorner and contentCorner then
            _lockCorner.CornerRadius = contentCorner.CornerRadius
        end
        lockFrame.ZIndex = 200; lockFrame.Visible = locked

        local collapsedState = collapsed
        local function getContentHeight() return contentLayout.AbsoluteContentSize.Y or 0 end
        local function getTargetHeight()
            if collapsedState then return COLLAPSED_H end
            return getContentHeight() + CONTENT_TOP + 4
        end
        local function updateHeight(instant)
            local targetH = getTargetHeight()
            if instant then
                contentContainer.Size = UDim2.new(1, -5, 0, targetH)
                sectionFrame.Size = UDim2.new(1, -5, 0, targetH)
            else
                TweenService:Create(contentContainer, MIUI_TWEEN, {Size = UDim2.new(1, -5, 0, targetH)}):Play()
                TweenService:Create(sectionFrame, MIUI_TWEEN, {Size = UDim2.new(1, -5, 0, targetH)}):Play()
            end
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not collapsedState then updateHeight(false) end
        end)
        contentHolder.ChildAdded:Connect(function()
            task.wait(0.05)
            if not collapsedState then updateHeight(false) end
        end)
        contentHolder.ChildRemoved:Connect(function()
            task.wait(0.05)
            if not collapsedState then updateHeight(false) end
        end)
        if collapsedState then contentHolder.Visible = false end
        defer(function() updateHeight(true) end)

        local function setCollapsed(state, instant)
            if not collapsible then return end
            state = state == true
            if collapsedState == state then return end
            collapsedState = state
            if collapseArrow then
                TweenService:Create(collapseArrow, MIUI_TWEEN, { Rotation = state and 180 or 0 }):Play()
            end
            contentHolder.Visible = not state
            updateHeight(instant)
        end

        if collapsible then
            local headBtn = Instance.new("TextButton")
            headBtn.Size = UDim2.new(1, 0, 0, HEADER_H)
            headBtn.Position = UDim2.new(0, 0, 0, 0)
            headBtn.BackgroundTransparency = 1
            headBtn.Text = ""; headBtn.ZIndex = 5
            headBtn.AutoButtonColor = false
            headBtn.Parent = contentContainer
            headBtn.MouseButton1Click:Connect(function()
                if locked then return end
                setCollapsed(not collapsedState, false)
            end)
        end

        local tabBuilders = {}
        if hasTabs then
            local tabBar = Instance.new("Frame")
            tabBar.Name = "SectionTabBar"
            tabBar.Size = UDim2.new(1, 0, 0, 28)
            tabBar.BackgroundTransparency = 1
            tabBar.Parent = contentHolder
            local tabBarLayout = Instance.new("UIListLayout")
            tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
            tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
            tabBarLayout.Padding = UDim.new(0, 5)
            tabBarLayout.Parent = tabBar

            local tabSpacer = Instance.new("Frame")
            tabSpacer.Name = "TabSpacer"
            tabSpacer.Size = UDim2.new(1, 0, 0, 5)
            tabSpacer.BackgroundTransparency = 1
            tabSpacer.Parent = contentHolder

            local tabContentWrap = Instance.new("Frame")
            tabContentWrap.Name = "SectionTabContentWrap"
            tabContentWrap.Size = UDim2.new(1, 0, 0, 0)
            tabContentWrap.BackgroundTransparency = 1
            tabContentWrap.Parent = contentHolder

            local tabDataMap = {}
            local activeTabKey = nil
            local tabCount = #tabEntries
            local widthScale = 1 / math.max(tabCount, 1)

            local function refreshTabWrapHeight()
                if activeTabKey and tabDataMap[activeTabKey] then
                    local h = tabDataMap[activeTabKey].layout.AbsoluteContentSize.Y
                    tabContentWrap.Size = UDim2.new(1, 0, 0, h)
                end
            end

            local function switchTab(key)
                if activeTabKey == key then return end
                activeTabKey = key
                for k, data in pairs(tabDataMap) do
                    local active = (k == key)
                    data.frame.Visible = active
                    Tween(data.btn, {
                        BackgroundTransparency = active and 0.150 or 1,
                        BackgroundColor3 = CurrentTheme.Top,
                    }, 0.18)
                    Tween(data.stroke, {
                        Transparency = active and 0.650 or 1,
                    }, 0.18)
                    if data.icon then
                        Tween(data.icon, {
                            ImageColor3 = active and CurrentTheme.Accent or Color3.fromRGB(223, 223, 223),
                            ImageTransparency = active and 0 or 0.5,
                        }, 0.18)
                    end
                    if data.label then
                        Tween(data.label, {
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextTransparency = active and 0 or 0.5,
                        }, 0.18)
                    end
                end
                refreshTabWrapHeight()
            end

            for _, entry in ipairs(tabEntries) do
                local key            = tostring(entry.Key)
                local tabName        = entry.Name or key
                local tabIcon        = entry.Icon
                local tabLocked      = entry.Locked == true
                local tabLockedTitle = entry.LockedTitle
                                    or entry.TextLocked
                                    or entry.LockMessage
                                    or "已锁定"

                local btn = Instance.new("TextButton")
                btn.Name = "SectionTab_"..key
                btn.BackgroundColor3 = CurrentTheme.Top
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Size = UDim2.new(widthScale, -4, 1, 0)
                btn.Parent = tabBar
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

                local btnStroke = Instance.new("UIStroke")
                btnStroke.Thickness = 1
                btnStroke.Transparency = 1
                btnStroke.Color = CurrentTheme.Stroke
                btnStroke.Parent = btn
                table.insert(ThemeListeners, function() btnStroke.Color = CurrentTheme.Stroke end)

                local iconLabel = nil
                if tabIcon and tostring(tabIcon) ~= "" then
                    iconLabel = Instance.new("ImageLabel")
                    iconLabel.AnchorPoint = Vector2.new(0, 0.5)
                    iconLabel.Position = UDim2.new(0, 7, 0.5, 0)
                    iconLabel.Size = UDim2.new(0, 18, 0, 18)
                    iconLabel.BackgroundTransparency = 1
                    iconLabel.ImageColor3 = Color3.fromRGB(223, 223, 223)
                    iconLabel.ImageTransparency = 0.5
                    iconLabel.ScaleType = Enum.ScaleType.Fit
                    if tonumber(tabIcon) then
                        iconLabel.Image = "rbxassetid://"..tostring(tabIcon)
                    else
                        iconLabel.Image = tostring(tabIcon)
                    end

                    local uiScale = Instance.new("UIScale")
                    uiScale.Name = "ModernIconScale"
                    uiScale.Scale = 0.82
                    uiScale.Parent = iconLabel

                    iconLabel.Parent = btn
                end

                local textLbl = Instance.new("TextLabel")
                textLbl.Name = "TabText"
                textLbl.AnchorPoint = Vector2.new(0, 0.5)
                textLbl.Position = UDim2.new(0, 29, 0.5, 0)
                textLbl.Size = UDim2.new(1, -34, 0, 15)
                textLbl.BackgroundTransparency = 1
                textLbl.Font = Enum.Font.GothamMedium
                textLbl.Text = tabName
                textLbl.TextSize = 11
                textLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                textLbl.TextTransparency = 0.5
                textLbl.TextXAlignment = Enum.TextXAlignment.Left
                textLbl.TextTruncate = Enum.TextTruncate.AtEnd
                textLbl.Parent = btn

                if tabLocked then
                    local tabLockFrame, tabLockLabel = createLockOverlay(btn, tabLockedTitle)
                    tabLockFrame.Visible = true
                    tabLockFrame.ZIndex = 5
                    if tabLockLabel then
                        tabLockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end

                local tabFrame = Instance.new("Frame")
                tabFrame.Name = "TabContent_"..key
                tabFrame.Size = UDim2.new(1, 0, 0, 0)
                tabFrame.AutomaticSize = Enum.AutomaticSize.Y
                tabFrame.BackgroundTransparency = 1
                tabFrame.Visible = false
                tabFrame.Parent = tabContentWrap
                local tabLayout = Instance.new("UIListLayout")
                tabLayout.Padding = UDim.new(0, 0)
                tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
                tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                tabLayout.Parent = tabFrame

                tabDataMap[key] = {
                    frame = tabFrame, layout = tabLayout,
                    btn = btn, stroke = btnStroke,
                    icon = iconLabel, label = textLbl,
                    locked = tabLocked,
                }

                local subBuilder = createSectionBuilder(tabFrame, tabFrame, elementWidth, windowCount, win)
                tabBuilders[key] = setmetatable({}, {
                    __index = function(_, k)
                        local fn = subBuilder[k]
                        if k == "Section" then
                            return function(self, cfg) return fn(subBuilder, cfg) end
                        end
                        if type(fn) == "function" then
                            return function(self, cfg)
                                cfg = cfg or {}
                                if type(cfg) == "table" and cfg.Parent == nil then
                                    cfg.Parent = tabFrame
                                end
                                return fn(subBuilder, cfg)
                            end
                        end
                        return fn
                    end
                })

                btn.MouseButton1Click:Connect(function()
                    if locked or tabLocked then return end
                    switchTab(key)
                end)

                tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if activeTabKey == key then refreshTabWrapHeight() end
                end)
            end

            if tabEntries[1] then
                local firstKey = tostring(tabEntries[1].Key)
                local firstData = tabDataMap[firstKey]
                if firstData and not firstData.locked then
                    activeTabKey = nil
                    switchTab(firstKey)
                else
                    for _, entry in ipairs(tabEntries) do
                        local k = tostring(entry.Key)
                        local d = tabDataMap[k]
                        if d and not d.locked then
                            activeTabKey = nil
                            switchTab(k)
                            break
                        end
                    end
                end
            end
        end

        local sectionObj = {}
        for methodName, methodFn in pairs(child) do
            sectionObj[methodName] = function(_, cfg)
                cfg = cfg or {}
                cfg.Parent = contentHolder
                return methodFn(_, cfg)
            end
        end
        sectionObj.SetVisible = function(_, vis) sectionFrame.Visible = vis end
        sectionObj.SetTitle = function(_, text)
            if titleLabel then titleLabel.Text = text or ""; titleLabel.Visible = (text ~= nil and text ~= "") end
        end
        sectionObj.SetSubtitle = function(_, text)
            if subtitleLabel then subtitleLabel.Text = text or ""; subtitleLabel.Visible = (text ~= nil and text ~= "") end
        end
        sectionObj.SetCollapsed = function(_, state) setCollapsed(state, false); return sectionObj end
        sectionObj.ToggleCollapsed = function(_) setCollapsed(not collapsedState, false); return sectionObj end
        sectionObj.GetCollapsed = function(_) return collapsedState end
        sectionObj.SetCollapsible = function(_, state) collapsible = state == true; return sectionObj end
        sectionObj.IsCollapsible = function(_) return collapsible end
        sectionObj.SetLocked = function(_, state) locked = state == true; lockFrame.Visible = locked; return sectionObj end
        sectionObj.SetTextLocked = function(_, text) lockedTitle = text or "已锁定"; lockLabel.Text = lockedTitle; return sectionObj end
        sectionObj.SetMessage = function(_, text) lockedTitle = text or "已锁定"; lockLabel.Text = lockedTitle; return sectionObj end
        sectionObj.GetLocked = function(_) return locked end
        sectionObj.Lock = function(_, text)
            if text then lockedTitle = text; lockLabel.Text = lockedTitle end
            locked = true; lockFrame.Visible = true
            return sectionObj
        end
        sectionObj.Unlock = function(_) locked = false; lockFrame.Visible = false; return sectionObj end

        if hasTabs then
            return setmetatable({}, {
                __index = function(_, key)
                    if sectionObj[key] ~= nil then
                        return sectionObj[key]
                    end
                    if tabBuilders[key] ~= nil then
                        return tabBuilders[key]
                    end
                    return nil
                end
            })
        end

        return sectionObj
    end

    functions.Section = createSection
    return functions
end

local function BuildColorPresetDropdown(scroll, page, mainFrame, gradient)
    local rgb = Color3.fromRGB
    local PALETTES = {
        {
            Name = "默认",
            Accent = rgb(78, 132, 255), Background = rgb(6, 6, 9), BackgroundAlt = rgb(36, 38, 46),
            Surface = rgb(12, 12, 16), Elevated = rgb(24, 25, 32), Hover = rgb(33, 34, 43),
            Stroke = rgb(88, 92, 110), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "白黑",
            Accent = rgb(222, 222, 228), Background = rgb(5, 5, 6), BackgroundAlt = rgb(48, 48, 52),
            Surface = rgb(11, 11, 12), Elevated = rgb(24, 24, 27), Hover = rgb(34, 34, 38),
            Stroke = rgb(92, 92, 100), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "紫色",
            Accent = rgb(146, 112, 255), Background = rgb(8, 7, 14), BackgroundAlt = rgb(34, 26, 58),
            Surface = rgb(14, 12, 24), Elevated = rgb(27, 23, 44), Hover = rgb(37, 32, 58),
            Stroke = rgb(96, 84, 140), Text = rgb(236, 232, 248), SubText = rgb(160, 152, 186),
        },
        {
            Name = "青色",
            Accent = rgb(38, 192, 232), Background = rgb(4, 8, 11), BackgroundAlt = rgb(16, 36, 48),
            Surface = rgb(9, 15, 20), Elevated = rgb(19, 30, 39), Hover = rgb(26, 40, 52),
            Stroke = rgb(70, 104, 124), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "翡翠绿",
            Accent = rgb(62, 204, 134), Background = rgb(5, 9, 8), BackgroundAlt = rgb(18, 40, 31),
            Surface = rgb(9, 15, 13), Elevated = rgb(19, 30, 26), Hover = rgb(26, 40, 35),
            Stroke = rgb(70, 112, 96), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "橙色",
            Accent = rgb(246, 172, 52), Background = rgb(10, 8, 5), BackgroundAlt = rgb(42, 31, 16),
            Surface = rgb(16, 13, 9), Elevated = rgb(31, 26, 19), Hover = rgb(42, 35, 25),
            Stroke = rgb(118, 98, 66), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "红色",
            Accent = rgb(232, 62, 82), Background = rgb(10, 6, 7), BackgroundAlt = rgb(44, 18, 23),
            Surface = rgb(16, 10, 12), Elevated = rgb(32, 20, 24), Hover = rgb(44, 28, 33),
            Stroke = rgb(122, 72, 82), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
        {
            Name = "猛男高富帅",
            Accent = rgb(242, 112, 172), Background = rgb(10, 6, 9), BackgroundAlt = rgb(44, 20, 36),
            Surface = rgb(16, 10, 15), Elevated = rgb(32, 20, 30), Hover = rgb(44, 28, 41),
            Stroke = rgb(122, 76, 108), Text = rgb(232, 233, 240), SubText = rgb(152, 154, 168),
        },
    }

    local ROW_H, PAD = 30, 4
    local MENU_W = 190

    local Tile = Instance.new("Frame")
    Tile.Size = UDim2.new(1, -24, 0, 42)
    Tile.Position = UDim2.new(0, 12, 0, 174)
    Tile.BackgroundTransparency = 1
    Tile.BorderSizePixel = 0
    Tile.ZIndex = 103
    Tile.Parent = scroll

    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, -20, 0, 1)
    Line.Position = UDim2.new(0, 10, 1, -1)
    Line.BackgroundColor3 = CurrentTheme.Stroke
    Line.BackgroundTransparency = 0.65
    Line.BorderSizePixel = 0
    Line.ZIndex = 103
    Line.Parent = Tile
    AddToRegistry(Line, "BackgroundColor3", "Stroke")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -130, 0, 18)
    Label.Position = UDim2.new(0, 15, 0.5, -9)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.Text = "颜色预设"
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.TextColor3 = CurrentTheme.Text
    Label.ZIndex = 103
    Label.Parent = Tile
    AddToRegistry(Label, "TextColor3", "Text")

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 100, 0, 26)
    Btn.Position = UDim2.new(1, -15, 0.5, 0)
    Btn.AnchorPoint = Vector2.new(1, 0.5)
    Btn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.ZIndex = 103
    Btn.Parent = Tile
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Transparency = 0.65
    BtnStroke.Color = CurrentTheme.Stroke
    BtnStroke.Parent = Btn
    table.insert(ThemeListeners, function() BtnStroke.Color = CurrentTheme.Stroke end)

    local ValueLbl = Instance.new("TextLabel")
    ValueLbl.Size = UDim2.new(1, -22, 1, 0)
    ValueLbl.BackgroundTransparency = 1
    ValueLbl.Font = Enum.Font.GothamBold
    ValueLbl.TextSize = 12
    ValueLbl.TextXAlignment = Enum.TextXAlignment.Left
    ValueLbl.Position = UDim2.new(0, 8, 0, 0)
    ValueLbl.TextColor3 = CurrentTheme.Text
    ValueLbl.ZIndex = 104
    ValueLbl.Parent = Btn
    AddToRegistry(ValueLbl, "TextColor3", "Text")
    TextGradient:Skip(ValueLbl)

    local Chevron = Instance.new("ImageLabel")
    Chevron.Size = UDim2.new(0, 14, 0, 14)
    Chevron.Position = UDim2.new(1, -18, 0.5, -7)
    Chevron.BackgroundTransparency = 1
    Chevron.Image = "rbxassetid://18865373378"
    Chevron.ImageColor3 = CurrentTheme.Accent
    Chevron.ZIndex = 105
    Chevron.Parent = Btn
    AddToRegistry(Chevron, "ImageColor3", "Accent")

    local Menu = Instance.new("Frame")
    Menu.Size = UDim2.new(0, MENU_W, 0, #PALETTES * ROW_H + PAD * 2)
    Menu.BackgroundColor3 = CurrentTheme.Main
    Menu.BackgroundTransparency = 0.02
    Menu.BorderSizePixel = 0
    Menu.ClipsDescendants = true
    Menu.Visible = false
    Menu.ZIndex = 220
    Menu.Parent = page

    local MenuCorner = Instance.new("UICorner", Menu)
    MenuCorner.CornerRadius = UDim.new(0, 8)

    local MenuStroke = Instance.new("UIStroke", Menu)
    MenuStroke.Thickness = 1
    MenuStroke.Transparency = 0.35
    MenuStroke.Color = CurrentTheme.Stroke
    table.insert(ThemeListeners, function()
        Menu.BackgroundColor3 = CurrentTheme.Main
        MenuStroke.Color = CurrentTheme.Stroke
    end)

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 0)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Menu

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, PAD)
    Padding.PaddingBottom = UDim.new(0, PAD)
    Padding.PaddingLeft = UDim.new(0, PAD)
    Padding.PaddingRight = UDim.new(0, PAD)
    Padding.Parent = Menu

    local Swatches = {}
    local Selected = PALETTES[1].Name

    local function ApplyPalette(p)
        Selected = p.Name
        ValueLbl.Text = p.Name

        CurrentTheme.Accent   = p.Accent
        CurrentTheme.Main     = p.Surface
        CurrentTheme.Top      = p.BackgroundAlt
        CurrentTheme.Text     = p.Text
        CurrentTheme.SubText  = p.SubText
        CurrentTheme.Stroke   = p.Stroke
        CurrentTheme.Element  = p.Elevated
        CurrentTheme.Hover    = p.Hover

        for _, entry in ipairs(Registry) do
            local val = CurrentTheme[entry.Type]
            if val and typeof(val) == "Color3" and entry.Object then
                Tween(entry.Object, { [entry.Property] = val }, 0.25)
            end
        end

        if gradient then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, p.BackgroundAlt),
                ColorSequenceKeypoint.new(0.55, p.Background),
                ColorSequenceKeypoint.new(1, p.Background),
            })
        end
        if mainFrame then
            mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        end

        for _, fn in ipairs(ThemeListeners) do pcall(fn) end
        TextGradient:RefreshAll()

        for _, sw in ipairs(Swatches) do
            sw.Check.Visible = sw.Name == p.Name
        end
    end

    for index, p in ipairs(PALETTES) do
        local Row = Instance.new("TextButton")
        Row.Size = UDim2.new(1, 0, 0, ROW_H)
        Row.BackgroundTransparency = 0.6
        Row.BackgroundColor3 = CurrentTheme.Main
        Row.Text = ""
        Row.AutoButtonColor = false
        Row.LayoutOrder = index
        Row.ZIndex = 221
        Row.Parent = Menu
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 5)

        local Swatch = Instance.new("Frame")
        Swatch.Size = UDim2.new(0, 12, 0, 12)
        Swatch.Position = UDim2.new(0, 10, 0.5, -6)
        Swatch.BackgroundColor3 = p.Accent
        Swatch.BorderSizePixel = 0
        Swatch.ZIndex = 222
        Swatch.Parent = Row
        Instance.new("UICorner", Swatch).CornerRadius = UDim.new(0, 3)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -50, 1, 0)
        NameLbl.Position = UDim2.new(0, 30, 0, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.Text = p.Name
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextColor3 = CurrentTheme.Text
        NameLbl.ZIndex = 222
        NameLbl.Parent = Row
        AddToRegistry(NameLbl, "TextColor3", "Text")
        TextGradient:Skip(NameLbl)

        local Check = Instance.new("ImageLabel")
        Check.Size = UDim2.new(0, 12, 0, 12)
        Check.Position = UDim2.new(1, -20, 0.5, -6)
        Check.BackgroundTransparency = 1
        Check.Image = "rbxassetid://18865373378"
        Check.ImageColor3 = p.Accent
        Check.Visible = false
        Check.ZIndex = 222
        Check.Parent = Row

        Swatches[#Swatches + 1] = { Name = p.Name, Check = Check }

        Row.MouseEnter:Connect(function() Tween(Row, { BackgroundTransparency = 0.2 }, 0.12) end)
        Row.MouseLeave:Connect(function() Tween(Row, { BackgroundTransparency = 0.6 }, 0.12) end)
        Row.MouseButton1Click:Connect(function()
            ApplyPalette(p)
            Menu.Visible = false
            Chevron.Rotation = 0
        end)
    end

    local function PositionMenu()
        local pageAbs = page.AbsolutePosition
        local btnAbs = Btn.AbsolutePosition
        local pageH = page.AbsoluteSize.Y
        local x = btnAbs.X - pageAbs.X - (MENU_W - Btn.AbsoluteSize.X)
        x = math.max(4, math.min(x, page.AbsoluteSize.X - MENU_W - 4))
        local y = btnAbs.Y - pageAbs.Y + Btn.AbsoluteSize.Y + 6
        if y + Menu.AbsoluteSize.Y > pageH - 4 then
            y = btnAbs.Y - pageAbs.Y - Menu.AbsoluteSize.Y - 6
        end
        y = math.max(4, y)
        Menu.Position = UDim2.new(0, x, 0, y)
    end

    Btn.MouseEnter:Connect(function() Tween(Tile, { BackgroundTransparency = 0.65 }, 0.15) end)
    Btn.MouseLeave:Connect(function() Tween(Tile, { BackgroundTransparency = 1 }, 0.15) end)
    Btn.MouseButton1Click:Connect(function()
        if Menu.Visible then
            Menu.Visible = false
            Chevron.Rotation = 0
            return
        end
        PositionMenu()
        Menu.Visible = true
        Chevron.Rotation = 180
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not Menu.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local px, py = input.Position.X, input.Position.Y
        local function inside(obj)
            local ap, sz = obj.AbsolutePosition, obj.AbsoluteSize
            return px >= ap.X and px <= ap.X + sz.X and py >= ap.Y and py <= ap.Y + sz.Y
        end
        if inside(Menu) or inside(Btn) then return end
        Menu.Visible = false
        Chevron.Rotation = 0
    end)

    Selected = PALETTES[1].Name
    ValueLbl.Text = Selected
    for _, sw in ipairs(Swatches) do sw.Check.Visible = (sw.Name == Selected) end
end

local FRAME_STYLE_OPTIONS = {
    "Clean Rounded",
    "Sharp Tactical",
    "Double Frame",
    "Corner Brackets",
    "Tech Segments",
    "Glass Outline",
    "Botanical Garden",
    "Royal Baroque",
    "Off",
}

local FRAME_STYLE_LABELS = {
    ["Clean Rounded"] = "圆润洁净",
    ["Sharp Tactical"] = "锐利战术",
    ["Double Frame"] = "双层边框",
    ["Corner Brackets"] = "边角括线",
    ["Tech Segments"] = "科技分段",
    ["Glass Outline"] = "玻璃描边",
    ["Botanical Garden"] = "植物花园",
    ["Royal Baroque"] = "皇家专用边框",
    ["Off"] = "关闭",
}

local FRAME_STYLE_ALIASES = {}
for styleKey, styleLabel in pairs(FRAME_STYLE_LABELS) do
    FRAME_STYLE_ALIASES[styleLabel] = styleKey
end

local function FrameStyleLabel(style)
    return FRAME_STYLE_LABELS[style] or tostring(style or "")
end

local FrameStyleState = {
    Value = "Off",
    Strength = 1,
    Apply = nil,
    ShadowOn = false,
    ShadowSpec = nil,
    Outset = 0,
}

local SHADOW_BASE_THICKNESS = { 6, 5, 4, 3 }

local function MakeShadowSpec(scale, alpha)
    local spec = {}
    for index, thickness in ipairs(SHADOW_BASE_THICKNESS) do
        spec[index] = { Thickness = thickness * (scale or 1), Transparency = alpha or 0.9 }
    end
    return spec
end

local FRAME_DECOR_OUTSET_SCALE = 1.0

local function BorderOutset()
    local spec = FrameStyleState.ShadowSpec
    local maxThickness = 0
    if spec then
        for _, entry in ipairs(spec) do
            local thickness = tonumber(entry.Thickness) or 0
            if thickness > maxThickness then maxThickness = thickness end
        end
    end
    return maxThickness * FRAME_DECOR_OUTSET_SCALE
end

local function RefreshWindowShadow(strokes, visible, instant)
    if not strokes then return end
    local spec = FrameStyleState.ShadowSpec
    for index, stroke in ipairs(strokes) do
        if stroke then
            local entry = spec and spec[index] or nil
            if entry and entry.Thickness then stroke.Thickness = entry.Thickness end
            if entry and entry.Color then stroke.Color = entry.Color end
            local alpha = entry and entry.Transparency or 0.9
            local target = visible and alpha or 1
            if instant then
                stroke.Transparency = target
            else
                Tween(stroke, { Transparency = target }, 0.3)
            end
        end
    end
end

local function BuildFrameStyleSystem(MainFrame, ScreenGui, windowShadowStrokes)
    if not MainFrame or not ScreenGui then return end

    local ShadowStrokes = windowShadowStrokes or {}

    local FS = FrameStyleState
    local BaseRadius = SapphireStyle.Radius or 12
    local FALLBACK_ACCENT = Color3.fromRGB(80, 140, 255)

    local function accentColor()
        return CurrentTheme.Accent or FALLBACK_ACCENT
    end

    local function newGui(className, props)
        local obj = Instance.new(className)
        local parent = nil
        for key, value in pairs(props or {}) do
            if key == "Parent" then parent = value else obj[key] = value end
        end
        if parent then obj.Parent = parent end
        return obj
    end

    local function corner(obj, radius)
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, radius)
        uiCorner.Parent = obj
        return uiCorner
    end

    local function setRadius(obj, radius)
        if not obj then return end
        local uiCorner = obj:FindFirstChildOfClass("UICorner")
        if uiCorner then uiCorner.CornerRadius = UDim.new(0, radius) end
    end

    local Root = newGui("Frame", {
        Name = "FengFrameStyleRoot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Active = false,
        Visible = true,
        ZIndex = 900,
        Parent = ScreenGui,
    })
    local MainScale = MainFrame:FindFirstChild("FitScale")
    local RootScale = newGui("UIScale", { Parent = Root, Scale = 1 })

    local function newAccentStroke(thickness, transparency)
        local stroke = Instance.new("UIStroke")
        stroke.Color = accentColor()
        stroke.Thickness = thickness
        stroke.Transparency = transparency
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = MainFrame
        return stroke
    end
    local glowSharp = newAccentStroke(1, 1)
    local glowMid = newAccentStroke(1, 1)
    local glowOuter = newAccentStroke(1, 1)
    local mainStroke = newAccentStroke(1, 0.30)

    local segments = {}
    local function makeSegment(name)
        local segment = newGui("Frame", {
            Parent = Root,
            Name = name,
            BackgroundColor3 = accentColor(),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Visible = false,
            Active = false,
            ZIndex = 902,
        })
        corner(segment, 3)
        segments[name] = segment
        return segment
    end
    for _, name in ipairs({
        "TopLeftHorizontal", "TopLeftVertical",
        "TopRightHorizontal", "TopRightVertical",
        "BottomLeftHorizontal", "BottomLeftVertical",
        "BottomRightHorizontal", "BottomRightVertical",
        "TopCenter", "BottomCenter", "LeftCenter", "RightCenter",
    }) do
        makeSegment(name)
    end

    local cornerArcs = {}
    for _, def in ipairs({
        { Name = "TopLeft", Anchor = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), SignX = 0, SignY = 0 },
        { Name = "TopRight", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), SignX = -1, SignY = 0 },
        { Name = "BottomLeft", Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), SignX = 0, SignY = -1 },
        { Name = "BottomRight", Anchor = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), SignX = -1, SignY = -1 },
    }) do
        local clip = newGui("Frame", {
            Parent = Root,
            Name = "FengArcClip" .. def.Name,
            AnchorPoint = def.Anchor,
            Position = def.Position,
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            Active = false,
            ZIndex = 900,
        })
        local ring = newGui("Frame", {
            Parent = clip,
            Name = "Ring",
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 24, 0, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = true,
            Active = false,
            ZIndex = 900,
        })
        local ringCorner = newGui("UICorner", { Parent = ring, CornerRadius = UDim.new(0, 12) })
        local ringStroke = newGui("UIStroke", {
            Parent = ring,
            Color = accentColor(),
            Thickness = 3,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        cornerArcs[def.Name] = {
            Clip = clip,
            Ring = ring,
            Corner = ringCorner,
            Stroke = ringStroke,
            SignX = def.SignX,
            SignY = def.SignY,
        }
    end

    local innerFrame = newGui("Frame", {
        Parent = Root,
        Name = "FengInnerFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -12, 1, -12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 901,
    })
    local innerCorner = corner(innerFrame, 14)
    local innerStroke = newGui("UIStroke", {
        Parent = innerFrame,
        Color = accentColor(),
        Thickness = 1,
        Transparency = 0.40,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local ornament = {
        Assets = {},
        Ids = {
            ["Botanical Garden"] = 74175820853754,
            ["Royal Baroque"] = 79280254837043,
        },
    }

    local function resolveFrameAsset(style)
        local cached = ornament.Assets[style]
        if cached ~= nil then
            return cached or nil
        end
        local id = ornament.Ids[style]
        if not id then
            ornament.Assets[style] = false
            return nil
        end
        local asset = "rbxassetid://" .. tostring(id)
        ornament.Assets[style] = asset
        return asset
    end

    local ornamentGlow = newGui("ImageLabel", {
        Parent = Root,
        Name = "FengOrnamentFrameGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 28, 1, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ImageColor3 = accentColor(),
        ImageTransparency = 0.78,
        ScaleType = Enum.ScaleType.Stretch,
        Visible = false,
        Active = false,
        ZIndex = 900,
    })
    local ornamentMain = newGui("ImageLabel", {
        Parent = Root,
        Name = "FengOrnamentFrameMain",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 12, 1, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ImageColor3 = accentColor(),
        ImageTransparency = 0.02,
        ScaleType = Enum.ScaleType.Stretch,
        Visible = false,
        Active = false,
        ZIndex = 905,
    })

    local function hideSegments()
        for _, segment in pairs(segments) do
            segment.Visible = false
        end
        for _, arc in pairs(cornerArcs) do
            arc.Clip.Visible = false
        end
    end

    local function placeSegment(name, position, size, anchorPoint, color, transparency)
        local segment = segments[name]
        if not segment then return end
        segment.AnchorPoint = anchorPoint or Vector2.zero
        segment.Position = position
        segment.Size = size
        segment.BackgroundColor3 = color
        segment.BackgroundTransparency = transparency or 0
        segment.Visible = true
    end

    local allowedStyles = {}
    for _, name in ipairs(FRAME_STYLE_OPTIONS) do
        allowedStyles[name] = true
    end
    local legacyMap = {
        ["Neon Pulse"] = "Clean Rounded",
        ["Soft Breathing"] = "Glass Outline",
        ["Soft Glow"] = "Glass Outline",
        ["Comet Sweep"] = "Tech Segments",
        ["Rainbow Pulse"] = "Tech Segments",
        ["Electric Flicker"] = "Corner Brackets",
        ["Static"] = "Double Frame",
        ["Quantum Dots"] = "Clean Rounded",
        ["Neon Flow"] = "Clean Rounded",
        ["Star Drift"] = "Clean Rounded",
    }

    local function normalizeStyle(value)
        if type(value) == "table" then value = value[1] end
        value = tostring(value or "Off")
        value = FRAME_STYLE_ALIASES[value] or legacyMap[value] or value
        if allowedStyles[value] then return value end
        return "Off"
    end

    local function configureCornerArcs(color, transparency, thickness, radius)
        for _, arc in pairs(cornerArcs) do
            local arcRadius = math.max(1, radius)
            arc.Clip.Size = UDim2.new(0, arcRadius, 0, arcRadius)
            arc.Ring.Size = UDim2.new(0, arcRadius * 2, 0, arcRadius * 2)
            arc.Ring.Position = UDim2.new(0, arc.SignX * arcRadius, 0, arc.SignY * arcRadius)
            arc.Corner.CornerRadius = UDim.new(0, arcRadius)
            arc.Stroke.Color = color
            arc.Stroke.Thickness = thickness or 3
            arc.Stroke.Transparency = transparency or 0
            arc.Clip.Visible = true
        end
    end

    local function configureCornerBrackets(color, horizontalLength, verticalLength, thickness, transparency, radius)
        local thicknessValue = thickness or 3
        local outset = BorderOutset()
        local arc = math.max(0, radius or 0) + outset
        local outward = -thicknessValue * 0.5
        local inward = thicknessValue * 0.5
        local h = UDim2.new(0, horizontalLength, 0, thicknessValue)
        local v = UDim2.new(0, thicknessValue, 0, verticalLength)
        placeSegment("TopLeftHorizontal", UDim2.new(0, arc, 0, outward), h, Vector2.new(0, 0), color, transparency)
        placeSegment("TopLeftVertical", UDim2.new(0, outward, 0, arc), v, Vector2.new(0, 0), color, transparency)
        placeSegment("TopRightHorizontal", UDim2.new(1, -arc, 0, outward), h, Vector2.new(1, 0), color, transparency)
        placeSegment("TopRightVertical", UDim2.new(1, inward, 0, arc), v, Vector2.new(1, 0), color, transparency)
        placeSegment("BottomLeftHorizontal", UDim2.new(0, arc, 1, inward), h, Vector2.new(0, 1), color, transparency)
        placeSegment("BottomLeftVertical", UDim2.new(0, outward, 1, -arc), v, Vector2.new(0, 1), color, transparency)
        placeSegment("BottomRightHorizontal", UDim2.new(1, -arc, 1, inward), h, Vector2.new(1, 1), color, transparency)
        placeSegment("BottomRightVertical", UDim2.new(1, inward, 1, -arc), v, Vector2.new(1, 1), color, transparency)
        configureCornerArcs(color, transparency, thicknessValue, arc)
    end

    local function applyStyle(requestedStyle)
        local style = normalizeStyle(requestedStyle)
        local accent = accentColor()
        local strength = math.clamp(tonumber(FS.Strength) or 1, 0.65, 1.60)
        local bright = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.30)

        FS.Value = style
        hideSegments()
        innerFrame.Visible = false
        ornamentMain.Visible = false
        ornamentGlow.Visible = false
        ornamentMain.Image = ""
        ornamentGlow.Image = ""

        glowSharp.Color = accent
        glowMid.Color = accent
        glowOuter.Color = accent
        mainStroke.Color = accent
        innerStroke.Color = bright

        glowSharp.Thickness = 1
        glowMid.Thickness = 1
        glowOuter.Thickness = 1
        glowSharp.Transparency = 1
        glowMid.Transparency = 1
        glowOuter.Transparency = 1
        mainStroke.Thickness = 1
        mainStroke.Transparency = 0.30

        local radius = BaseRadius
        local innerInset = 6
        local innerRadius = math.max(2, radius - 4)
        FS.ShadowSpec = MakeShadowSpec(1, 0.9)

        if style == "Botanical Garden" then
            radius = 22
            FS.ShadowSpec = MakeShadowSpec(1.25, 0.50)
            innerInset = 8
            innerRadius = math.max(2, radius - innerInset)
            mainStroke.Thickness = 0.9 * strength
            mainStroke.Transparency = 0.48
            local asset = resolveFrameAsset(style)
            if asset then
                ornamentMain.Image = asset
                ornamentGlow.Image = asset
                ornamentMain.ImageColor3 = accent
                ornamentGlow.ImageColor3 = bright
                ornamentMain.ImageTransparency = math.clamp(0.10 - (strength - 1) * 0.07, 0.01, 0.18)
                ornamentGlow.ImageTransparency = math.clamp(0.84 - (strength - 1) * 0.08, 0.68, 0.90)
                ornamentMain.Size = UDim2.new(1, 74 * strength, 1, 48 * strength)
                ornamentGlow.Size = UDim2.new(1, 86 * strength, 1, 60 * strength)
                ornamentMain.Visible = true
                ornamentGlow.Visible = true
            else
                configureCornerBrackets(accent, 112, 72, math.max(3, 4 * strength), 0.02, radius)
            end
        elseif style == "Royal Baroque" then
            radius = 14
            FS.ShadowSpec = MakeShadowSpec(1.0, 0.55)
            innerInset = 8
            innerRadius = math.max(2, radius - innerInset)
            mainStroke.Thickness = 0.8 * strength
            mainStroke.Transparency = 0.62
            local asset = resolveFrameAsset(style)
            if asset then
                ornamentMain.Image = asset
                ornamentGlow.Image = asset
                ornamentMain.ImageColor3 = accent
                ornamentGlow.ImageColor3 = bright
                ornamentMain.ImageTransparency = math.clamp(0.04 - (strength - 1) * 0.03, 0, 0.10)
                ornamentGlow.ImageTransparency = math.clamp(0.72 - (strength - 1) * 0.08, 0.54, 0.82)
                ornamentMain.Size = UDim2.new(1, 34 * strength, 1, 30 * strength)
                ornamentGlow.Size = UDim2.new(1, 44 * strength, 1, 40 * strength)
                ornamentMain.Visible = true
                ornamentGlow.Visible = true
            else
                innerFrame.Visible = true
                innerFrame.Size = UDim2.new(1, -2 * innerInset, 1, -2 * innerInset)
                innerStroke.Thickness = 1.8 * strength
                innerStroke.Transparency = 0.16
                configureCornerBrackets(bright, 118, 74, math.max(3, 5 * strength), 0, radius)
            end
        elseif style == "Off" then
            radius = BaseRadius
            FS.ShadowSpec = MakeShadowSpec(1, 0.9)
            mainStroke.Transparency = 1
        elseif style == "Clean Rounded" then
            radius = 20
            FS.ShadowSpec = MakeShadowSpec(1.15, 0.55)
            innerInset = 8
            innerRadius = math.max(2, radius - innerInset)
            glowSharp.Thickness = 2.0 * strength
            glowSharp.Transparency = 0.04
            glowMid.Thickness = 6.5 * strength
            glowMid.Transparency = 0.78
            glowOuter.Thickness = 14 * strength
            glowOuter.Transparency = 0.93
            mainStroke.Thickness = 1.4 * strength
            mainStroke.Transparency = 0.10
        elseif style == "Sharp Tactical" then
            radius = 4
            FS.ShadowSpec = MakeShadowSpec(0.75, 0.78)
            innerInset = 5
            innerRadius = math.max(1, radius - innerInset)
            glowSharp.Thickness = 3.0 * strength
            glowSharp.Transparency = 0.02
            mainStroke.Thickness = 1.2 * strength
            mainStroke.Transparency = 0.08
            configureCornerBrackets(bright, 44, 34, math.max(3, 4 * strength), 0.02, radius)
        elseif style == "Double Frame" then
            radius = 14
            FS.ShadowSpec = MakeShadowSpec(0.9, 0.60)
            innerInset = math.max(4, math.floor(radius * 0.5))
            innerRadius = math.max(2, radius - innerInset)
            glowSharp.Thickness = 2.0 * strength
            glowSharp.Transparency = 0.04
            mainStroke.Thickness = 1.2 * strength
            mainStroke.Transparency = 0.10
            innerFrame.Visible = true
            innerFrame.Size = UDim2.new(1, -2 * innerInset, 1, -2 * innerInset)
            innerStroke.Thickness = 1.5 * strength
            innerStroke.Transparency = 0.20
        elseif style == "Corner Brackets" then
            radius = 12
            FS.ShadowSpec = MakeShadowSpec(0.8, 0.50)
            innerInset = 6
            innerRadius = math.max(2, radius - innerInset)
            mainStroke.Thickness = 0.8 * strength
            mainStroke.Transparency = 0.64
            configureCornerBrackets(accent, 86, 58, math.max(3, 4 * strength), 0, radius)
        elseif style == "Tech Segments" then
            radius = 8
            FS.ShadowSpec = MakeShadowSpec(0.7, 0.55)
            innerInset = 5
            innerRadius = math.max(2, radius - innerInset)
            local segmentThickness = math.max(2, 3 * strength)
            mainStroke.Thickness = 0.8 * strength
            mainStroke.Transparency = 0.68
            configureCornerBrackets(accent, 132, 28, segmentThickness, 0.04, radius)
            placeSegment("TopCenter", UDim2.new(0.5, 0, 0, -segmentThickness * 0.5), UDim2.new(0, 92, 0, segmentThickness), Vector2.new(0.5, 0), bright, 0.05)
            placeSegment("BottomCenter", UDim2.new(0.5, 0, 1, segmentThickness * 0.5), UDim2.new(0, 174, 0, segmentThickness), Vector2.new(0.5, 1), accent, 0.06)
            placeSegment("LeftCenter", UDim2.new(0, -segmentThickness * 0.5, 0.5, 0), UDim2.new(0, segmentThickness, 0, 132), Vector2.new(0, 0.5), bright, 0.10)
            placeSegment("RightCenter", UDim2.new(1, segmentThickness * 0.5, 0.5, 0), UDim2.new(0, segmentThickness, 0, 188), Vector2.new(1, 0.5), accent, 0.04)
        elseif style == "Glass Outline" then
            radius = 26
            FS.ShadowSpec = MakeShadowSpec(1.3, 0.35)
            innerInset = 5
            innerRadius = math.max(2, radius - innerInset)
            glowSharp.Thickness = 1.1 * strength
            glowSharp.Transparency = 0.12
            glowMid.Thickness = 9 * strength
            glowMid.Transparency = 0.78
            glowOuter.Thickness = 24 * strength
            glowOuter.Transparency = 0.94
            mainStroke.Thickness = 1.0 * strength
            mainStroke.Transparency = 0.18
            innerFrame.Visible = true
            innerFrame.Size = UDim2.new(1, -2 * innerInset, 1, -2 * innerInset)
            innerStroke.Thickness = 0.8 * strength
            innerStroke.Transparency = 0.66
        end

        FS.Outset = BorderOutset()

        setRadius(MainFrame, radius)
        if innerCorner then
            innerCorner.CornerRadius = UDim.new(0, math.max(2, innerRadius + (FS.Outset or 0)))
        end
        for _, segment in pairs(segments) do
            local segmentCorner = segment:FindFirstChildOfClass("UICorner")
            if segmentCorner then
                segmentCorner.CornerRadius = UDim.new(0, style == "Sharp Tactical" and 1 or 2)
            end
        end
        RefreshWindowShadow(ShadowStrokes, FS.ShadowOn, true)
        return style
    end

    local function applyStyleSafe(requestedStyle)
        local ok, result = pcall(applyStyle, requestedStyle)
        if ok then return result end
        warn("该样式已被关闭:", tostring(result))
        pcall(function()
            hideSegments()
            ornamentMain.Visible = false
            ornamentMain.Image = ""
            ornamentGlow.Visible = false
            ornamentGlow.Image = ""
            innerFrame.Visible = false
            local fallback = accentColor()
            glowSharp.Color = fallback
            glowSharp.Thickness = 2
            glowSharp.Transparency = 0.08
            glowMid.Thickness = 1
            glowMid.Transparency = 1
            glowOuter.Thickness = 1
            glowOuter.Transparency = 1
            mainStroke.Color = fallback
            mainStroke.Thickness = 1
            mainStroke.Transparency = 1
            setRadius(MainFrame, BaseRadius)
        end)
        FS.Value = "Off"
        FS.ShadowSpec = MakeShadowSpec(1, 0.9)
        FS.Outset = BorderOutset()
        RefreshWindowShadow(ShadowStrokes, FS.ShadowOn, true)
        return "Off"
    end

    table.insert(ThemeListeners, function()
        pcall(applyStyleSafe, FS.Value)
    end)

    RunService.RenderStepped:Connect(function()
        if not Root or not Root.Parent then return end
        if not MainFrame or not MainFrame.Parent then
            Root.Visible = false
            return
        end
        Root.Visible = MainFrame.Visible
        Root.AnchorPoint = MainFrame.AnchorPoint
        local alpha = 0
        pcall(function() alpha = FS.Outset or 0 end)
        if type(alpha) ~= "number" then alpha = 0 end
        local anchor = MainFrame.AnchorPoint
        local position = MainFrame.Position
        local size = MainFrame.Size
        Root.Position = UDim2.new(
            position.X.Scale,
            position.X.Offset + alpha * (2 * anchor.X - 1),
            position.Y.Scale,
            position.Y.Offset + alpha * (2 * anchor.Y - 1)
        )
        Root.Size = UDim2.new(
            size.X.Scale,
            size.X.Offset + 2 * alpha,
            size.Y.Scale,
            size.Y.Offset + 2 * alpha
        )
        if MainScale then
            RootScale.Scale = MainScale.Scale
        end
    end)

    FS.Apply = applyStyleSafe
    applyStyleSafe(FS.Value)
    return applyStyleSafe
end

local function BuildFrameStyleDropdown(scroll, page, mainFrame)
    local ROW_H, PAD = 24, 4
    local MENU_W = 190
    local ROW_Y = 216

    local Tile = Instance.new("Frame")
    Tile.Size = UDim2.new(1, -24, 0, 42)
    Tile.Position = UDim2.new(0, 12, 0, ROW_Y)
    Tile.BackgroundTransparency = 1
    Tile.BorderSizePixel = 0
    Tile.ZIndex = 103
    Tile.Parent = scroll

    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, -20, 0, 1)
    Line.Position = UDim2.new(0, 10, 1, -1)
    Line.BackgroundColor3 = CurrentTheme.Stroke
    Line.BackgroundTransparency = 0.65
    Line.BorderSizePixel = 0
    Line.ZIndex = 103
    Line.Parent = Tile
    AddToRegistry(Line, "BackgroundColor3", "Stroke")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -130, 0, 18)
    Label.Position = UDim2.new(0, 15, 0.5, -9)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.Text = "边框风格"
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.TextColor3 = CurrentTheme.Text
    Label.ZIndex = 103
    Label.Parent = Tile
    AddToRegistry(Label, "TextColor3", "Text")

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 100, 0, 26)
    Btn.Position = UDim2.new(1, -15, 0.5, 0)
    Btn.AnchorPoint = Vector2.new(1, 0.5)
    Btn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.ZIndex = 103
    Btn.Parent = Tile
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Transparency = 0.65
    BtnStroke.Color = CurrentTheme.Stroke
    BtnStroke.Parent = Btn
    table.insert(ThemeListeners, function() BtnStroke.Color = CurrentTheme.Stroke end)

    local ValueLbl = Instance.new("TextLabel")
    ValueLbl.Size = UDim2.new(1, -22, 1, 0)
    ValueLbl.BackgroundTransparency = 1
    ValueLbl.Font = Enum.Font.GothamBold
    ValueLbl.TextSize = 11
    ValueLbl.TextXAlignment = Enum.TextXAlignment.Left
    ValueLbl.Position = UDim2.new(0, 8, 0, 0)
    ValueLbl.TextColor3 = CurrentTheme.Text
    ValueLbl.TextTruncate = Enum.TextTruncate.AtEnd
    ValueLbl.ZIndex = 104
    ValueLbl.Parent = Btn
    AddToRegistry(ValueLbl, "TextColor3", "Text")
    TextGradient:Skip(ValueLbl)

    local Chevron = Instance.new("ImageLabel")
    Chevron.Size = UDim2.new(0, 14, 0, 14)
    Chevron.Position = UDim2.new(1, -18, 0.5, -7)
    Chevron.BackgroundTransparency = 1
    Chevron.Image = "rbxassetid://18865373378"
    Chevron.ImageColor3 = CurrentTheme.Accent
    Chevron.ZIndex = 105
    Chevron.Parent = Btn
    AddToRegistry(Chevron, "ImageColor3", "Accent")

    local MenuHolder = mainFrame or page
    local Menu = Instance.new("Frame")
    Menu.Size = UDim2.new(0, MENU_W, 0, #FRAME_STYLE_OPTIONS * ROW_H + PAD * 2)
    Menu.BackgroundColor3 = CurrentTheme.Main
    Menu.BackgroundTransparency = 0.02
    Menu.BorderSizePixel = 0
    Menu.ClipsDescendants = true
    Menu.Visible = false
    Menu.ZIndex = 220
    Menu.Parent = MenuHolder

    Instance.new("UICorner", Menu).CornerRadius = UDim.new(0, 8)

    local MenuStroke = Instance.new("UIStroke", Menu)
    MenuStroke.Thickness = 1
    MenuStroke.Transparency = 0.35
    MenuStroke.Color = CurrentTheme.Stroke
    table.insert(ThemeListeners, function()
        Menu.BackgroundColor3 = CurrentTheme.Main
        MenuStroke.Color = CurrentTheme.Stroke
    end)

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 0)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Menu

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, PAD)
    Padding.PaddingBottom = UDim.new(0, PAD)
    Padding.PaddingLeft = UDim.new(0, PAD)
    Padding.PaddingRight = UDim.new(0, PAD)
    Padding.Parent = Menu

    local Checks = {}

    local function SetStyle(style)
        FrameStyleState.Value = style
        ValueLbl.Text = FrameStyleLabel(style)
        if FrameStyleState.Apply then pcall(FrameStyleState.Apply, style) end
        for _, item in ipairs(Checks) do
            item.Check.Visible = item.Name == style
        end
    end

    for index, styleName in ipairs(FRAME_STYLE_OPTIONS) do
        local Row = Instance.new("TextButton")
        Row.Size = UDim2.new(1, 0, 0, ROW_H)
        Row.BackgroundTransparency = 0.6
        Row.BackgroundColor3 = CurrentTheme.Main
        Row.Text = ""
        Row.AutoButtonColor = false
        Row.LayoutOrder = index
        Row.ZIndex = 221
        Row.Parent = Menu
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 5)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -40, 1, 0)
        NameLbl.Position = UDim2.new(0, 10, 0, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.Text = FrameStyleLabel(styleName)
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.TextColor3 = CurrentTheme.Text
        NameLbl.ZIndex = 222
        NameLbl.Parent = Row
        AddToRegistry(NameLbl, "TextColor3", "Text")
        TextGradient:Skip(NameLbl)

        local Check = Instance.new("ImageLabel")
        Check.Size = UDim2.new(0, 12, 0, 12)
        Check.Position = UDim2.new(1, -20, 0.5, -6)
        Check.BackgroundTransparency = 1
        Check.Image = "rbxassetid://18865373378"
        Check.ImageColor3 = CurrentTheme.Accent
        Check.Visible = false
        Check.ZIndex = 222
        Check.Parent = Row
        AddToRegistry(Check, "ImageColor3", "Accent")

        Checks[#Checks + 1] = { Name = styleName, Check = Check }

        Row.MouseEnter:Connect(function() Tween(Row, { BackgroundTransparency = 0.2 }, 0.12) end)
        Row.MouseLeave:Connect(function() Tween(Row, { BackgroundTransparency = 0.6 }, 0.12) end)
        Row.MouseButton1Click:Connect(function()
            SetStyle(styleName)
            Menu.Visible = false
            Chevron.Rotation = 0
        end)
    end

    local function PositionMenu()
        local holderPos = MenuHolder.AbsolutePosition
        local holderSize = MenuHolder.AbsoluteSize
        local btnAbs = Btn.AbsolutePosition
        local btnSize = Btn.AbsoluteSize
        local menuH = Menu.AbsoluteSize.Y
        if menuH <= 0 then menuH = #FRAME_STYLE_OPTIONS * ROW_H + PAD * 2 end
        local x = btnAbs.X - holderPos.X - (MENU_W - btnSize.X)
        x = math.max(4, math.min(x, holderSize.X - MENU_W - 4))
        local y = btnAbs.Y - holderPos.Y + btnSize.Y + 6
        if y + menuH > holderSize.Y - 4 then
            y = btnAbs.Y - holderPos.Y - menuH - 6
        end
        y = math.max(4, y)
        Menu.Position = UDim2.new(0, x, 0, y)
    end

    Btn.MouseEnter:Connect(function() Tween(Tile, { BackgroundTransparency = 0.65 }, 0.15) end)
    Btn.MouseLeave:Connect(function() Tween(Tile, { BackgroundTransparency = 1 }, 0.15) end)
    Btn.MouseButton1Click:Connect(function()
        if Menu.Visible then
            Menu.Visible = false
            Chevron.Rotation = 0
            return
        end
        PositionMenu()
        Menu.Visible = true
        Chevron.Rotation = 180
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not Menu.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local px, py = input.Position.X, input.Position.Y
        local function inside(obj)
            local ap, sz = obj.AbsolutePosition, obj.AbsoluteSize
            return px >= ap.X and px <= ap.X + sz.X and py >= ap.Y and py <= ap.Y + sz.Y
        end
        if inside(Menu) or inside(Btn) then return end
        Menu.Visible = false
        Chevron.Rotation = 0
    end)

    if page then
        page:GetPropertyChangedSignal("Visible"):Connect(function()
            if not page.Visible then
                Menu.Visible = false
                Chevron.Rotation = 0
            end
        end)
    end

    ValueLbl.Text = FrameStyleLabel(FrameStyleState.Value)
    for _, item in ipairs(Checks) do
        item.Check.Visible = item.Name == FrameStyleState.Value
    end
end

local function BuildConfigMenu(MainFrame, RightHeader, ScreenGui, Window)
    local BUILDER_ICONS_PATH =
        "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

    local ICON_FONT_REGULAR = Font.new(
        BUILDER_ICONS_PATH,
        Enum.FontWeight.Regular,
        Enum.FontStyle.Normal
    )
    local ICON_FONT_BOLD = Font.new(
        BUILDER_ICONS_PATH,
        Enum.FontWeight.Bold,
        Enum.FontStyle.Normal
    )

    local function SetIconMode(Label, IconName)
        if not Label or not IconName or IconName == "" then
            if Label then Label.Text = "" end
            return
        end
        IconName = tostring(IconName)
        local useBold = string.lower(string.sub(IconName, -5)) == "-bold"
        if useBold then
            Label.Text = IconName:sub(1, -6)
            Label.FontFace = ICON_FONT_BOLD
        else
            Label.Text = IconName
            Label.FontFace = ICON_FONT_REGULAR
        end
        Label:SetAttribute("FengIconFont", true)
    end

    local CONFIG_DIR          = "款脚本配置"
    local DEFAULT_CONFIG_NAME = "默认配置"
    local MENU_WIDTH          = 220
    local MENU_INITIAL_HEIGHT = 110
    local TWEEN_SPEED         = 0.175

    local function EnsureConfigDir()
        pcall(function()
            if not isfolder(CONFIG_DIR) then
                makefolder(CONFIG_DIR)
            end
        end)
    end

    local function ConfigPath(name)
        return CONFIG_DIR .. "/" .. tostring(name) .. ".json"
    end

    local function ConfigExists(name)
        local ok, r = pcall(isfile, ConfigPath(name))
        return ok and r == true
    end

    local function ListAllConfigs()
        local out = {}
        pcall(function()
            if not isfolder(CONFIG_DIR) then return end
            for _, path in ipairs(listfiles(CONFIG_DIR)) do
                local n = path:match("([^/\\]+)%.json$")
                if n and #n > 0 then
                    table.insert(out, n)
                end
            end
        end)
        return out
    end

    local function SerializeConfig()
        local raw = {}
        for id, obj in pairs(ConfigObjects) do
            if obj then
                local v
                if type(obj.Get) == "function" then
                    local ok2, got = pcall(obj.Get)
                    if ok2 then v = got end
                else
                    v = obj.Value
                end
                if v ~= nil then
                    raw[id] = v
                end
            end
        end
        local wrapped = SerializeValue(raw)
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(wrapped)
        end)
        return ok and encoded or nil
    end

    local function WriteConfig(name, overwrite)
        name = tostring(name or DEFAULT_CONFIG_NAME)
        name = string.sub(name, 1, 24)
        if name == "" then return false end
        if name:find("/", 1, true) or name:find("\\", 1, true) then
            return false
        end

        EnsureConfigDir()

        if ConfigExists(name) and not overwrite then
            return false
        end

        local data = SerializeConfig()
        if not data then return false end

        local ok = pcall(writefile, ConfigPath(name), data)
        return ok
    end

    local function ReadConfig(name)
        if not ConfigExists(name) then return false end

        local ok, raw = pcall(readfile, ConfigPath(name))
        if not ok or not raw then return false end

        local ok2, decoded = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if not ok2 or type(decoded) ~= "table" then
            return false
        end

        local data = DeserializeValue(decoded)

        for id, value in pairs(data) do
            local obj = ConfigObjects[id]
            if obj and type(obj.Set) == "function" then
                pcall(function() obj.Set(value) end)
            end
        end
        return true
    end

    local function DeleteConfig(name)
        if name == DEFAULT_CONFIG_NAME then return false end
        if type(delfile) ~= "function" then return false end
        return pcall(delfile, ConfigPath(name))
    end

    local ConfigFrame = Instance.new("Frame")
    ConfigFrame.Name                 = "ConfigFrame"
    ConfigFrame.AnchorPoint          = Vector2.new(0, 0.5)
    ConfigFrame.BackgroundColor3     = Color3.fromRGB(13, 17, 22)
    ConfigFrame.BackgroundTransparency = 0.750
    ConfigFrame.BorderSizePixel      = 0
    ConfigFrame.Position             = UDim2.new(0, 10, 0.5, 0)
    ConfigFrame.Size                 = UDim2.new(0, 115, 0, 30)
    ConfigFrame.ZIndex               = 9
    ConfigFrame.Parent               = RightHeader
    AddToRegistry(ConfigFrame, "BackgroundColor3", "Top")

    local cfgFrameCorner = Instance.new("UICorner")
    cfgFrameCorner.CornerRadius = UDim.new(0, 4)
    cfgFrameCorner.Parent       = ConfigFrame

    local cfgFrameStroke = Instance.new("UIStroke")
    cfgFrameStroke.Transparency = 0.650
    cfgFrameStroke.Color        = CurrentTheme.Stroke
    cfgFrameStroke.Parent       = ConfigFrame
    table.insert(ThemeListeners, function()
        cfgFrameStroke.Color = CurrentTheme.Stroke
    end)

    local ConfigIcon = Instance.new("TextLabel")
    ConfigIcon.Name                 = "ConfigIcon"
    ConfigIcon.AnchorPoint          = Vector2.new(0, 0.5)
    ConfigIcon.BackgroundTransparency = 1
    ConfigIcon.BorderSizePixel      = 0
    ConfigIcon.Position             = UDim2.new(0, 2, 0.5, 0)
    ConfigIcon.Size                 = UDim2.new(0, 25, 0, 25)
    ConfigIcon.ZIndex               = 9
    ConfigIcon.TextColor3           = Color3.fromRGB(223, 223, 223)
    ConfigIcon.TextTransparency     = 0.250
    ConfigIcon.TextSize             = 20
    ConfigIcon.Parent               = ConfigFrame
    SetIconMode(ConfigIcon, "pencil-square")

    local ConfigLine = Instance.new("Frame")
    ConfigLine.Name                 = "ConfigLine"
    ConfigLine.BackgroundColor3     = CurrentTheme.Stroke
    ConfigLine.BackgroundTransparency = 0.650
    ConfigLine.BorderSizePixel      = 0
    ConfigLine.Position             = UDim2.new(0, 30, 0, 0)
    ConfigLine.Size                 = UDim2.new(0, 1, 1, 0)
    ConfigLine.Parent               = ConfigFrame
    AddToRegistry(ConfigLine, "BackgroundColor3", "Stroke")

    local ConfigName = Instance.new("TextLabel")
    ConfigName.Name                 = "ConfigName"
    ConfigName.AnchorPoint          = Vector2.new(0, 0.5)
    ConfigName.BackgroundTransparency = 1
    ConfigName.BorderSizePixel      = 0
    ConfigName.Position             = UDim2.new(0, 40, 0.5, 0)
    ConfigName.Size                 = UDim2.new(1, -67, 0, 15)
    ConfigName.ZIndex               = 9
    ConfigName.Font                 = Enum.Font.GothamMedium
    ConfigName.Text                 = DEFAULT_CONFIG_NAME
    ConfigName.TextColor3           = CurrentTheme.Text
    ConfigName.TextSize             = 12
    ConfigName.TextTransparency     = 0.350
    ConfigName.TextXAlignment       = Enum.TextXAlignment.Left
    ConfigName.TextTruncate         = Enum.TextTruncate.AtEnd
    ConfigName.Parent               = ConfigFrame
    AddToRegistry(ConfigName, "TextColor3", "Text")
    TextGradient:Skip(ConfigName)

    local ConfigBthIcon = Instance.new("TextLabel")
    ConfigBthIcon.Name              = "ConfigBthIcon"
    ConfigBthIcon.AnchorPoint       = Vector2.new(1, 0.5)
    ConfigBthIcon.BackgroundTransparency = 1
    ConfigBthIcon.BorderSizePixel   = 0
    ConfigBthIcon.Position          = UDim2.new(1, -2, 0.5, 0)
    ConfigBthIcon.Size              = UDim2.new(0, 25, 0, 25)
    ConfigBthIcon.ZIndex            = 9
    ConfigBthIcon.TextColor3        = Color3.fromRGB(223, 223, 223)
    ConfigBthIcon.TextTransparency  = 0.250
    ConfigBthIcon.TextSize          = 20
    ConfigBthIcon.Parent            = ConfigFrame
    SetIconMode(ConfigBthIcon, "chevron-small-down")

    local ConfigMenu = Instance.new("Frame")
    ConfigMenu.Name                 = "ConfigMenu"
    ConfigMenu.AnchorPoint          = Vector2.new(0.5, 0)
    ConfigMenu.BackgroundColor3     = Color3.fromRGB(20, 22, 27)
    ConfigMenu.BackgroundTransparency = 0.035
    ConfigMenu.BorderSizePixel      = 0
    ConfigMenu.ClipsDescendants     = true
    ConfigMenu.Position             = UDim2.new(255, 255, 255, 255)
    ConfigMenu.Size                 = UDim2.new(0, MENU_WIDTH, 0, MENU_INITIAL_HEIGHT)
    ConfigMenu.ZIndex               = 151
    ConfigMenu.Visible              = false
    ConfigMenu.Parent               = ScreenGui

    local cfgMenuCorner = Instance.new("UICorner")
    cfgMenuCorner.CornerRadius = UDim.new(0, 10)
    cfgMenuCorner.Parent       = ConfigMenu

    local cfgMenuLayout = Instance.new("UIListLayout")
    cfgMenuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cfgMenuLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    cfgMenuLayout.Padding             = UDim.new(0, 4)
    cfgMenuLayout.Parent              = ConfigMenu

    local cfgMenuStroke = Instance.new("UIStroke")
    cfgMenuStroke.Transparency = 0.650
    cfgMenuStroke.Color        = CurrentTheme.Stroke
    cfgMenuStroke.Parent       = ConfigMenu
    table.insert(ThemeListeners, function()
        cfgMenuStroke.Color = CurrentTheme.Stroke
    end)

    local cfgShadowStrokes = {}
    for _, thick in ipairs({6, 5, 4, 3}) do
        local s = Instance.new("UIStroke")
        s.Thickness         = thick
        s.Color             = Color3.new(0, 0, 0)
        s.Transparency      = 1
        s.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
        s.Parent            = ConfigMenu
        table.insert(cfgShadowStrokes, s)
    end

    local function SetCfgShadow(visible)
        for _, s in ipairs(cfgShadowStrokes) do
            Tween(s, { Transparency = visible and 0.9 or 1 }, 0.175)
        end
    end

    local InputFrame = Instance.new("Frame")
    InputFrame.Name                 = "InputFrame"
    InputFrame.BackgroundTransparency = 1
    InputFrame.BorderSizePixel      = 0
    InputFrame.Size                 = UDim2.new(1, 0, 0, 30)
    InputFrame.ZIndex               = 154
    InputFrame.LayoutOrder          = 0
    InputFrame.Parent               = ConfigMenu

    local BasedLabel = Instance.new("TextLabel")
    BasedLabel.Name                 = "BasedLabel"
    BasedLabel.BackgroundTransparency = 1
    BasedLabel.BorderSizePixel      = 0
    BasedLabel.Position             = UDim2.new(0, 11, 0, 6)
    BasedLabel.Size                 = UDim2.new(0, 60, 0, 15)
    BasedLabel.ZIndex               = 154
    BasedLabel.Font                 = Enum.Font.GothamMedium
    BasedLabel.Text                 = "配置列表"
    BasedLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
    BasedLabel.TextSize             = 13
    BasedLabel.TextTransparency     = 0.200
    BasedLabel.TextXAlignment       = Enum.TextXAlignment.Left
    BasedLabel.Parent               = InputFrame
    AddToRegistry(BasedLabel, "TextColor3", "Text")
    TextGradient:Skip(BasedLabel)

    local LineFrame_Config = Instance.new("Frame")
    LineFrame_Config.Name                  = "LineFrame"
    LineFrame_Config.AnchorPoint           = Vector2.new(0.5, 1)
    LineFrame_Config.BackgroundColor3      = CurrentTheme.Stroke
    LineFrame_Config.BackgroundTransparency = 0.650
    LineFrame_Config.BorderSizePixel       = 0
    LineFrame_Config.Position              = UDim2.new(0.5, 0, 1, 0)
    LineFrame_Config.Size                  = UDim2.new(1, -20, 0, 1)
    LineFrame_Config.ZIndex                = 154
    LineFrame_Config.Parent                = InputFrame
    AddToRegistry(LineFrame_Config, "BackgroundColor3", "Stroke")

    local BasedHandler = Instance.new("Frame")
    BasedHandler.Name               = "BasedHandler"
    BasedHandler.AnchorPoint        = Vector2.new(1, 0)
    BasedHandler.BackgroundTransparency = 1
    BasedHandler.BorderSizePixel    = 0
    BasedHandler.Position           = UDim2.new(1, -11, 0, 2)
    BasedHandler.Size               = UDim2.new(0, 130, 0, 25)
    BasedHandler.ZIndex             = 154
    BasedHandler.Parent             = InputFrame

    local BasedLayout = Instance.new("UIListLayout")
    BasedLayout.FillDirection        = Enum.FillDirection.Horizontal
    BasedLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
    BasedLayout.SortOrder            = Enum.SortOrder.LayoutOrder
    BasedLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
    BasedLayout.Padding              = UDim.new(0, 5)
    BasedLayout.Parent               = BasedHandler

    local TextInput = Instance.new("Frame")
    TextInput.Name              = "TextInput"
    TextInput.BackgroundColor3  = Color3.fromRGB(26, 28, 36)
    TextInput.BorderSizePixel   = 0
    TextInput.ClipsDescendants  = true
    TextInput.Size              = UDim2.new(0, 100, 0, 18)
    TextInput.ZIndex            = 154
    TextInput.LayoutOrder       = 1
    TextInput.Parent            = BasedHandler
    Instance.new("UICorner", TextInput).CornerRadius = UDim.new(0, 4)

    local TextInputStroke = Instance.new("UIStroke")
    TextInputStroke.Transparency = 0.650
    TextInputStroke.Color        = CurrentTheme.Stroke
    TextInputStroke.Parent       = TextInput
    table.insert(ThemeListeners, function()
        TextInputStroke.Color = CurrentTheme.Stroke
    end)

    local TextBox = Instance.new("TextBox")
    TextBox.AnchorPoint           = Vector2.new(0, 0.5)
    TextBox.BackgroundTransparency = 1
    TextBox.BorderSizePixel       = 0
    TextBox.Position              = UDim2.new(0, 5, 0.5, 0)
    TextBox.Size                  = UDim2.new(1, -5, 0, 17)
    TextBox.ZIndex                = 154
    TextBox.ClearTextOnFocus      = false
    TextBox.Font                  = Enum.Font.GothamMedium
    TextBox.PlaceholderText       = "配置名称 ..."
    TextBox.Text                  = ""
    TextBox.TextColor3            = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize              = 11
    TextBox.TextTransparency      = 0.350
    TextBox.TextXAlignment        = Enum.TextXAlignment.Left
    TextBox.Parent                = TextInput
    TextGradient:Skip(TextBox)

    local AddBtn = Instance.new("Frame")
    AddBtn.Name               = "AddConfigBtn"
    AddBtn.BackgroundColor3   = Color3.fromRGB(39, 40, 49)
    AddBtn.BackgroundTransparency = 1
    AddBtn.BorderSizePixel    = 0
    AddBtn.ClipsDescendants   = true
    AddBtn.Size               = UDim2.new(0, 20, 0, 18)
    AddBtn.ZIndex             = 153
    AddBtn.LayoutOrder        = 2
    AddBtn.Parent             = BasedHandler
    Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 4)

    local AddIcon = Instance.new("TextLabel")
    AddIcon.Name               = "AddIcon"
    AddIcon.AnchorPoint        = Vector2.new(0.5, 0.5)
    AddIcon.BackgroundTransparency = 1
    AddIcon.BorderSizePixel    = 0
    AddIcon.Position           = UDim2.new(0.5, 0, 0.5, 0)
    AddIcon.Size               = UDim2.new(1, 0, 1, 0)
    AddIcon.ZIndex             = 153
    AddIcon.TextColor3         = Color3.fromRGB(223, 223, 223)
    AddIcon.TextTransparency   = 0.350
    AddIcon.TextSize           = 15
    AddIcon.Parent             = AddBtn
    SetIconMode(AddIcon, "plus-large")

    local RefreshConfigList
    local CloseMenu
    local OpenMenu
    local isOpen = false
    local outsideConn_cfg
    local selectedConfigName = DEFAULT_CONFIG_NAME

    local function MakeSymbolButton(parent, iconName, hoverColor, callback, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3    = Color3.fromRGB(39, 40, 49)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel     = 0
        btn.ClipsDescendants    = true
        btn.Size                = UDim2.new(0, 20, 0, 18)
        btn.ZIndex              = 153
        btn.Text                = ""
        btn.AutoButtonColor     = false
        btn.LayoutOrder         = layoutOrder or 1
        btn.Parent              = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local icon = Instance.new("TextLabel")
        icon.AnchorPoint        = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.BorderSizePixel    = 0
        icon.Position           = UDim2.new(0.5, 0, 0.5, 0)
        icon.Size               = UDim2.new(1, 0, 1, 0)
        icon.ZIndex             = 154
        icon.TextColor3         = Color3.fromRGB(223, 223, 223)
        icon.TextTransparency   = 0.400
        icon.TextSize           = 15
        icon.Parent             = btn
        SetIconMode(icon, iconName)

        btn.MouseEnter:Connect(function()
            Tween(icon, { TextColor3 = hoverColor, TextTransparency = 0.200 }, TWEEN_SPEED)
        end)
        btn.MouseLeave:Connect(function()
            Tween(icon, { TextColor3 = Color3.fromRGB(223, 223, 223), TextTransparency = 0.400 }, TWEEN_SPEED)
        end)
        btn.MouseButton1Click:Connect(callback)

        return btn, icon
    end

    local function RenderConfigItem(name, order)
        local item = Instance.new("Frame")
        item.Name              = "ConfigItem"
        item.BackgroundColor3  = Color3.fromRGB(21, 20, 27)
        item.BackgroundTransparency = 0
        item.BorderSizePixel   = 0
        item.Size              = UDim2.new(1, -10, 0, 30)
        item.ZIndex            = 153
        item.LayoutOrder       = order
        item.Parent            = ConfigMenu
        item:SetAttribute("ConfigItem", true)
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 5)

        local itemStroke = Instance.new("UIStroke")
        itemStroke.Transparency = 0.500
        itemStroke.Color        = CurrentTheme.Stroke
        itemStroke.Parent       = item
        table.insert(ThemeListeners, function()
            itemStroke.Color = CurrentTheme.Stroke
        end)

        local itemLabel = Instance.new("TextLabel")
        itemLabel.Name              = "ConfigNameLbl"
        itemLabel.BackgroundTransparency = 1
        itemLabel.BorderSizePixel   = 0
        itemLabel.Position          = UDim2.new(0, 11, 0, 7)
        itemLabel.Size              = UDim2.new(1, -95, 0, 15)
        itemLabel.ZIndex            = 153
        itemLabel.Font              = Enum.Font.GothamMedium
        itemLabel.Text              = name
        itemLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
        itemLabel.TextSize          = 13
        itemLabel.TextTransparency  = 0.200
        itemLabel.TextXAlignment    = Enum.TextXAlignment.Left
        itemLabel.TextTruncate      = Enum.TextTruncate.AtEnd
        itemLabel.Parent            = item

        local btnHolder = Instance.new("Frame")
        btnHolder.AnchorPoint       = Vector2.new(1, 0)
        btnHolder.BackgroundTransparency = 1
        btnHolder.BorderSizePixel   = 0
        btnHolder.Position          = UDim2.new(1, -11, 0, 2)
        btnHolder.Size              = UDim2.new(0, 80, 0, 25)
        btnHolder.ZIndex            = 153
        btnHolder.Parent            = item

        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection        = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
        btnLayout.SortOrder            = Enum.SortOrder.LayoutOrder
        btnLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
        btnLayout.Padding              = UDim.new(0, 5)
        btnLayout.Parent               = btnHolder

        MakeSymbolButton(
            btnHolder, "trash-can",
            Color3.fromRGB(223, 125, 125),
            function()
                if name == DEFAULT_CONFIG_NAME then return end
                DeleteConfig(name)
                if RefreshConfigList then RefreshConfigList() end
            end,
            1
        )

        MakeSymbolButton(
            btnHolder, "pencil-square",
            CurrentTheme.Accent,
            function()
                if WriteConfig(name, true) then
                    selectedConfigName = name
                    ConfigName.Text = name
                    if RefreshConfigList then RefreshConfigList() end
                end
            end,
            2
        )

        MakeSymbolButton(
            btnHolder, "arrow-right-from-portrait-rectangle",
            CurrentTheme.Accent,
            function()
                if ReadConfig(name) then
                    selectedConfigName = name
                    ConfigName.Text = name
                    if RefreshConfigList then RefreshConfigList() end
                end
            end,
            3
        )

        item.MouseEnter:Connect(function()
            Tween(itemStroke, { Transparency = 0.250 }, TWEEN_SPEED)
        end)
        item.MouseLeave:Connect(function()
            Tween(itemStroke, { Transparency = 0.500 }, TWEEN_SPEED)
        end)

        return item
    end

    RefreshConfigList = function()
        for _, child in ipairs(ConfigMenu:GetChildren()) do
            if child:GetAttribute("ConfigItem") then
                child:Destroy()
            end
        end

        local names = ListAllConfigs()
        table.sort(names)

        local defaultIdx = table.find(names, DEFAULT_CONFIG_NAME)
        if defaultIdx and defaultIdx > 1 then
            table.remove(names, defaultIdx)
            table.insert(names, 1, DEFAULT_CONFIG_NAME)
        end

        for i, name in ipairs(names) do
            RenderConfigItem(name, i)
        end
    end

    local function ApplyMenuRender(open)
        if open then
            local absPos  = ConfigFrame.AbsolutePosition
            ConfigMenu.Position = UDim2.fromOffset(absPos.X + 110, absPos.Y + 96)
            ConfigMenu.Visible  = true

            local targetH = cfgMenuLayout.AbsoluteContentSize.Y + 5
            Tween(ConfigMenu, {
                BackgroundTransparency = 0.035,
                Position = UDim2.fromOffset(absPos.X + 110, absPos.Y + 95),
                Size = UDim2.new(0, MENU_WIDTH, 0, targetH),
            }, TWEEN_SPEED)

            Tween(cfgMenuStroke,  { Transparency = 0.650 }, TWEEN_SPEED)
            Tween(BasedLabel,     { TextTransparency = 0.200 }, TWEEN_SPEED)
            Tween(TextInputStroke,{ Transparency = 0.650 }, TWEEN_SPEED)
            Tween(LineFrame_Config, { BackgroundTransparency = 0.650 }, TWEEN_SPEED)
            Tween(TextInput,      { BackgroundTransparency = 0 }, TWEEN_SPEED)
            Tween(TextBox,        { TextTransparency = 0.350 }, TWEEN_SPEED)
            Tween(AddIcon,        { TextTransparency = 0.350 }, TWEEN_SPEED)
            Tween(ConfigBthIcon,  { Rotation = 180 }, TWEEN_SPEED)
            SetCfgShadow(true)
        else
            Tween(ConfigBthIcon, { Rotation = 0 }, TWEEN_SPEED)
            Tween(ConfigMenu, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(
                    ConfigFrame.AbsolutePosition.X + 110,
                    ConfigFrame.AbsolutePosition.Y + 96
                ),
            }, TWEEN_SPEED)
            Tween(cfgMenuStroke,  { Transparency = 1 }, TWEEN_SPEED)
            Tween(BasedLabel,     { TextTransparency = 1 }, TWEEN_SPEED)
            Tween(TextInputStroke,{ Transparency = 1 }, TWEEN_SPEED)
            Tween(LineFrame_Config, { BackgroundTransparency = 1 }, TWEEN_SPEED)
            Tween(TextInput,      { BackgroundTransparency = 1 }, TWEEN_SPEED)
            Tween(TextBox,        { TextTransparency = 1 }, TWEEN_SPEED)
            Tween(AddIcon,        { TextTransparency = 1 }, TWEEN_SPEED)
            SetCfgShadow(false)

            task.delay(0.20, function()
                if not isOpen then
                    ConfigMenu.Visible = false
                end
            end)
        end
    end

    OpenMenu = function()
        if isOpen then return end
        isOpen = true

        RefreshConfigList()
        ApplyMenuRender(true)

        if outsideConn_cfg then
            outsideConn_cfg:Disconnect()
            outsideConn_cfg = nil
        end
        local configMouse = LocalPlayer:GetMouse()
        outsideConn_cfg = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                local function Inside(frame)
                    if not frame or not frame.Parent then return false end
                    local ap, sz = frame.AbsolutePosition, frame.AbsoluteSize
                    return configMouse.X >= ap.X and configMouse.X <= ap.X + sz.X
                       and configMouse.Y >= ap.Y and configMouse.Y <= ap.Y + sz.Y
                end

                if not Inside(ConfigMenu) and not Inside(ConfigFrame) then
                    if outsideConn_cfg then
                        outsideConn_cfg:Disconnect()
                        outsideConn_cfg = nil
                    end
                    isOpen = false
                    ApplyMenuRender(false)
                end
            end
        end)
    end

    CloseMenu = function()
        if outsideConn_cfg then
            outsideConn_cfg:Disconnect()
            outsideConn_cfg = nil
        end
        if not isOpen then return end
        isOpen = false
        ApplyMenuRender(false)
    end

    local OpenButton = Instance.new("TextButton")
    OpenButton.Name              = "OpenButton"
    OpenButton.AnchorPoint       = Vector2.new(0, 0.5)
    OpenButton.BackgroundTransparency = 1
    OpenButton.BorderSizePixel   = 0
    OpenButton.Position          = UDim2.new(0, 31, 0.5, 0)
    OpenButton.Size              = UDim2.new(1, -31, 1, 0)
    OpenButton.ZIndex            = 10
    OpenButton.Text              = ""
    OpenButton.AutoButtonColor   = false
    OpenButton.Parent            = ConfigFrame

    OpenButton.MouseButton1Click:Connect(function()
        if isOpen then
            CloseMenu()
        else
            OpenMenu()
        end
    end)

    local SaveIconInput = Instance.new("TextButton")
    SaveIconInput.Name              = "SaveIconInput"
    SaveIconInput.AnchorPoint       = Vector2.new(0, 0.5)
    SaveIconInput.BackgroundTransparency = 1
    SaveIconInput.BorderSizePixel   = 0
    SaveIconInput.Position          = UDim2.new(0, 0, 0.5, 0)
    SaveIconInput.Size              = UDim2.new(0, 31, 1, 0)
    SaveIconInput.ZIndex            = 11
    SaveIconInput.Text              = ""
    SaveIconInput.AutoButtonColor   = false
    SaveIconInput.Parent            = ConfigFrame

    SaveIconInput.MouseEnter:Connect(function()
        Tween(ConfigIcon, { TextTransparency = 0.100 }, TWEEN_SPEED)
    end)
    SaveIconInput.MouseLeave:Connect(function()
        Tween(ConfigIcon, { TextTransparency = 0.250 }, TWEEN_SPEED)
    end)
    SaveIconInput.MouseButton1Click:Connect(function()
        if WriteConfig(selectedConfigName or DEFAULT_CONFIG_NAME, true) then
            RefreshConfigList()
        end
    end)

    local AddBtnInput = Instance.new("TextButton")
    AddBtnInput.Size              = UDim2.new(1, 0, 1, 0)
    AddBtnInput.BackgroundTransparency = 1
    AddBtnInput.Text              = ""
    AddBtnInput.AutoButtonColor   = false
    AddBtnInput.ZIndex            = 155
    AddBtnInput.Parent            = AddBtn

    AddBtnInput.MouseEnter:Connect(function()
        Tween(AddIcon, { TextTransparency = 0.100 }, TWEEN_SPEED)
    end)
    AddBtnInput.MouseLeave:Connect(function()
        Tween(AddIcon, { TextTransparency = 0.350 }, TWEEN_SPEED)
    end)
    AddBtnInput.MouseButton1Click:Connect(function()
        local cfgName = TextBox.Text
        if not cfgName or not cfgName:byte() then return end
        if cfgName:find("/", 1, true) or cfgName:find("\\", 1, true) then return end
        cfgName = string.sub(cfgName, 1, 24)

        if WriteConfig(cfgName, true) then
            TextBox.Text       = ""
            selectedConfigName = cfgName
            ConfigName.Text    = cfgName
            RefreshConfigList()
        end
    end)

    cfgMenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not isOpen then return end
        local targetH = cfgMenuLayout.AbsoluteContentSize.Y + 5
        Tween(ConfigMenu, { Size = UDim2.new(0, MENU_WIDTH, 0, targetH) }, TWEEN_SPEED)
    end)

    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not MainFrame.Visible then
            CloseMenu()
        end
    end)

    task.spawn(function()
        task.wait(0.35)
        EnsureConfigDir()
        if not ConfigExists(DEFAULT_CONFIG_NAME) then
            WriteConfig(DEFAULT_CONFIG_NAME, true)
        end
        RefreshConfigList()
    end)

    Window._configFrameRef = ConfigFrame
end
function FengUI:CreateWindow(Config)
    ConfigIdCounter = 0

    local Window = {}
    local Title = Config.Name or "FengYu"
    local Subtitle = Config.SubName
    local Keybind = Config.Keybind
    if type(Keybind) == "string" then
        Keybind = Enum.KeyCode[Keybind] or Keybind
    end
    local IconAsset = Config.Logo or Config.Icon
    local SceneId = Config.Scene

    local CardMode = Config.Card == true
    local PageService, HomePage, HomeContent, HomeList
    local PageContainer, PageContent, PageList, updatePageCanvas
    local CardReturnBtn

    if Config.Theme then
        if type(Config.Theme) == "string" then
            if Themes[Config.Theme] then CurrentTheme = Themes[Config.Theme] end
        elseif type(Config.Theme) == "table" then
            local t = Config.Theme
            local function toC3(v)
                if type(v) == "table" then return Color3.fromRGB(v[1] or 0, v[2] or 0, v[3] or 0)
                elseif type(v) == "userdata" then return v
                else return Color3.new(0,0,0) end
            end
            local customTheme = {}
            for k, v in pairs(CurrentTheme) do customTheme[k] = v end
            if t.Main then customTheme.Main = toC3(t.Main) end
            if t.Top then customTheme.Top = toC3(t.Top) end
            if t.Text then customTheme.Text = toC3(t.Text) end
            if t.Accent then customTheme.Accent = toC3(t.Accent) end
            if t.Stroke then customTheme.Stroke = toC3(t.Stroke) end
            if t.SubText then customTheme.SubText = toC3(t.SubText) end
            if t.Element then customTheme.Element = toC3(t.Element) end
            if t.Hover then customTheme.Hover = toC3(t.Hover) end
            if t.ShineEnabled ~= nil then customTheme.ShineEnabled = t.ShineEnabled end
            if t.Shine then customTheme.Shine = t.Shine end
            if t.StrokeShine ~= nil then customTheme.StrokeShine = t.StrokeShine end
            if t.StrokeDark then customTheme.StrokeDark = toC3(t.StrokeDark) end
            local customName = t.Name or "Custom"
            Themes[customName] = customTheme
            CurrentTheme = customTheme
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FengYu-Bento"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.IgnoreGuiInset = true end)
pcall(function()
    ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) elseif gethui then ScreenGui.Parent = gethui() end

    TextGradient:AttachHook(ScreenGui)

    local Notification = Instance.new("Frame")
    local NotificationLayout = Instance.new("UIListLayout")

    Notification.Name = "Notification"
    Notification.Parent = ScreenGui
    Notification.AnchorPoint = Vector2.new(1, 0)
    Notification.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notification.BackgroundTransparency = 1.000
    Notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Notification.BorderSizePixel = 0
    Notification.Position = UDim2.new(1, -25, 0, 25)
    Notification.Size = UDim2.new(0, 25, 0, 25)
    Notification.ZIndex = 500

    NotificationLayout.Parent = Notification
    NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationLayout.Padding = UDim.new(0, 0)

    local Notifier = {}

    function Notifier.new(Config)
        Config = Config or {}
        local CustomIcon = Config.Icon

        if Config.Name == nil then Config.Name = "款脚本温馨提示" end
        if Config.Content == nil then Config.Content = "你个废物会不会用通知" end
        if Config.Logo == nil then Config.Logo = "rbxasset://textures/ui/VerifiedBadgeNameIcon.png" end
        if Config.Icon == nil then Config.Icon = CustomIcon end
        if Config.Duration == nil then Config.Duration = 5 end

        local IconSource = Config.Icon or Config.Logo
        local IconId = formatIconAsset(IconSource, "rbxassetid://84830962019412")
        local IsImageIcon = IconId ~= ""

        local ContainerFrame = Instance.new("Frame")
        local NotifyFrame = Instance.new("Frame")
        local UICorner = Instance.new("UICorner")
        local UIStroke = Instance.new("UIStroke")
        local LogoImage = Instance.new("ImageLabel")
        local LogoIcon = Instance.new("ImageLabel")
        local UICorner_2 = Instance.new("UICorner")
        local NotifyName = Instance.new("TextLabel")
        local NotifyContent = Instance.new("TextLabel")

        local shadowStrokes = {}
        for _, thick in ipairs({6, 5, 4, 3}) do
            local s = Instance.new("UIStroke")
            s.Thickness = thick
            s.Color = Color3.new(0, 0, 0)
            s.Transparency = 1
            s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            s.Parent = NotifyFrame
            table.insert(shadowStrokes, s)
        end
        local function SetShadow(visible)
            for _, s in ipairs(shadowStrokes) do
                Tween(s, { Transparency = visible and 0.9 or 1 }, 0.175)
            end
        end
        SetShadow(true)

        ContainerFrame.Name = "Notification_Container"
        ContainerFrame.Parent = Notification
        ContainerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ContainerFrame.BackgroundTransparency = 1.000
        ContainerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ContainerFrame.BorderSizePixel = 0
        ContainerFrame.Size = UDim2.new(0, 0, 0, 100)

        NotifyFrame.Name = "Notification_Frame"
        NotifyFrame.Parent = ContainerFrame
        NotifyFrame.AnchorPoint = Vector2.new(1, 0)
        NotifyFrame.BackgroundColor3 = CurrentTheme.Top
        NotifyFrame.BackgroundTransparency = 0.075
        NotifyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyFrame.BorderSizePixel = 0
        NotifyFrame.ClipsDescendants = true
        NotifyFrame.Position = UDim2.new(0, 750, 0, 0)
        NotifyFrame.Size = UDim2.new(0, 220, 0, 55)
        NotifyFrame.ZIndex = 130

        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = NotifyFrame

        UIStroke.Transparency = 0.650
        UIStroke.Color = CurrentTheme.Stroke
        UIStroke.Parent = NotifyFrame
        table.insert(ThemeListeners, function() UIStroke.Color = CurrentTheme.Stroke end)

        LogoImage.Name = "Notification_LogoImage"
        LogoImage.Parent = NotifyFrame
        LogoImage.AnchorPoint = Vector2.new(0, 0.5)
        LogoImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LogoImage.BackgroundTransparency = 1.000
        LogoImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LogoImage.BorderSizePixel = 0
        LogoImage.Position = UDim2.new(0, 10, 0.5, 0)
        LogoImage.Size = UDim2.new(0, 35, 0, 35)
        LogoImage.ZIndex = 131
        LogoImage.Image = IsImageIcon and IconId or ""
        LogoImage.ImageColor3 = CurrentTheme.Text
        LogoImage.ImageTransparency = IsImageIcon and 0 or 1
        AddToRegistry(LogoImage, "ImageColor3", "Text")

        UICorner_2.CornerRadius = UDim.new(0, 7)
        UICorner_2.Parent = LogoImage

        LogoIcon.Name = "Notification_LogoIcon"
        LogoIcon.Parent = NotifyFrame
        LogoIcon.AnchorPoint = Vector2.new(0, 0.5)
        LogoIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LogoIcon.BackgroundTransparency = 1.000
        LogoIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LogoIcon.BorderSizePixel = 0
        LogoIcon.Position = UDim2.new(0, 10, 0.5, 0)
        LogoIcon.Size = UDim2.new(0, 35, 0, 35)
        LogoIcon.ZIndex = 131
        LogoIcon.Image = (not IsImageIcon) and IconId or ""
        LogoIcon.ImageColor3 = CurrentTheme.Text
        LogoIcon.ImageTransparency = IsImageIcon and 1 or 0.150
        LogoIcon.ScaleType = Enum.ScaleType.Fit
        AddToRegistry(LogoIcon, "ImageColor3", "Text")

        NotifyName.Name = "Notification_NotifyName"
        NotifyName.Parent = NotifyFrame
        NotifyName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NotifyName.BackgroundTransparency = 1.000
        NotifyName.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyName.BorderSizePixel = 0
        NotifyName.Position = UDim2.new(0, 50, 0, 7)
        NotifyName.Size = UDim2.new(0, 200, 0, 20)
        NotifyName.ZIndex = 132
        NotifyName.Font = Enum.Font.GothamBold
        NotifyName.Text = Config.Name
        NotifyName.TextColor3 = CurrentTheme.Text
        NotifyName.TextSize = 17.000
        NotifyName.TextXAlignment = Enum.TextXAlignment.Left
        AddToRegistry(NotifyName, "TextColor3", "Text")
        TextGradient:Add(NotifyName)

        NotifyContent.Name = "Notification_NotifyContent"
        NotifyContent.Parent = NotifyFrame
        NotifyContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NotifyContent.BackgroundTransparency = 1.000
        NotifyContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyContent.BorderSizePixel = 0
        NotifyContent.Position = UDim2.new(0, 50, 0, 28)
        NotifyContent.Size = UDim2.new(0, 200, 0, 15)
        NotifyContent.ZIndex = 132
        NotifyContent.Font = Enum.Font.GothamBold
        NotifyContent.Text = Config.Content
        NotifyContent.TextColor3 = CurrentTheme.Text
        NotifyContent.TextSize = 12.000
        NotifyContent.TextTransparency = 0.650
        NotifyContent.TextXAlignment = Enum.TextXAlignment.Left
        AddToRegistry(NotifyContent, "TextColor3", "Text")
        TextGradient:Skip(NotifyContent)

        local Size1 = TextService:GetTextSize(NotifyName.Text, NotifyName.TextSize, NotifyName.Font, Vector2.new(math.huge, math.huge))
        local Size2 = TextService:GetTextSize(NotifyContent.Text, NotifyContent.TextSize, NotifyContent.Font, Vector2.new(math.huge, math.huge))

        local MainSize = math.max(Size1.X, Size2.X)

        NotifyFrame.Size = UDim2.new(0, MainSize + 65, 0, 55)

        Tween(NotifyFrame, { Position = UDim2.new(1, 0, 0, 0) }, 0.5)

        ContainerFrame.Size = UDim2.new(0, 0, 0, 65)

        task.delay(Config.Duration or 5, function()
            SetShadow(false)

            Tween(NotifyFrame, { BackgroundTransparency = 1 }, 0.175)
            Tween(UIStroke, { Transparency = 1 }, 0.175)
            Tween(LogoImage, { ImageTransparency = 1 }, 0.175)
            Tween(LogoIcon, { ImageTransparency = 1 }, 0.175)
            Tween(NotifyName, { TextTransparency = 1 }, 0.175)
            Tween(NotifyContent, { TextTransparency = 1 }, 0.175)

            task.wait(0.125)

            Tween(ContainerFrame, { Size = UDim2.new(0, 0, 0, 0) }, 0.175)

            task.wait(0.125)

            ContainerFrame:Destroy()
        end)

        return NotifyFrame
    end

    FengUI.__NotificationCache = Notifier

    local FINAL_WIDTH = 500
    local FINAL_HEIGHT = 299

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.ClipsDescendants = true
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    MainFrame.BackgroundTransparency = SapphireStyle.WindowTransparency
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, SapphireStyle.Radius)

    local WindowGradient = Instance.new("UIGradient")
    WindowGradient.Rotation = SapphireStyle.GradientRotation
    WindowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, SapphireStyle.BackgroundAlt),
        ColorSequenceKeypoint.new(0.55, SapphireStyle.Background),
        ColorSequenceKeypoint.new(1, SapphireStyle.Background),
    })
    WindowGradient.Parent = MainFrame

    local shadowStrokes = {}
    for _, thick in ipairs({6, 5, 4, 3}) do
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thick
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Transparency = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = MainFrame
        table.insert(shadowStrokes, stroke)
    end

local WindowScale = Instance.new("NumberValue")
WindowScale.Name = "MinimizeMultiplier"
WindowScale.Value = 1
local FitScale = Instance.new("UIScale")
FitScale.Name = "FitScale"
FitScale.Scale = 1
FitScale.Parent = MainFrame
WindowScale.Changed:Connect(function()
    FitScale.Scale = math.max(WindowScale.Value, 0.001)
end)

    local function setShadowVisible(visible, instant)
        FrameStyleState.ShadowOn = visible and true or false
        RefreshWindowShadow(shadowStrokes, FrameStyleState.ShadowOn, instant)
    end

    setShadowVisible(false, true)

    FrameStyleState.Apply = BuildFrameStyleSystem(MainFrame, ScreenGui, shadowStrokes)

    local Resizer = Instance.new("TextButton")
    Resizer.Parent = MainFrame
    Resizer.BackgroundTransparency = 0.8
    Resizer.BackgroundColor3 = Color3.new(1, 1, 1)
    Resizer.Position = UDim2.new(1, 5, 1, 5)
    Resizer.Size = UDim2.new(0, 24, 0, 24)
    Resizer.AnchorPoint = Vector2.new(1, 1)
    Resizer.Text = ""; Resizer.ZIndex = 30; Resizer.Visible = false
    local isResizing = false
    local resizeStart = Vector2.new(0, 0)
    local startSize = UDim2.new(0, 0, 0, 0)
    Resizer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = true; resizeStart = input.Position; startSize = MainFrame.Size
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            MainFrame.Size = UDim2.new(0, math.max(400, startSize.X.Offset + delta.X), 0, math.max(250, startSize.Y.Offset + delta.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isResizing = false end
    end)

    local LeftMenuFrame = Instance.new("Frame")
    LeftMenuFrame.Size = UDim2.new(0, 150, 1, 0)
    LeftMenuFrame.BackgroundTransparency = 1
    LeftMenuFrame.Parent = MainFrame

    local HeadFrame = Instance.new("Frame")
    HeadFrame.Size = UDim2.new(1, 0, 0, 50)
    HeadFrame.BackgroundTransparency = 1
    HeadFrame.Parent = LeftMenuFrame

    local LogoImage = Instance.new("ImageLabel")
    LogoImage.AnchorPoint = Vector2.new(0, 0.5)
    LogoImage.Position    = UDim2.new(0, 10, 0.5, 0)
    LogoImage.Size        = UDim2.new(0, 35, 0, 35)
    LogoImage.BackgroundTransparency = 1
    LogoImage.Image = formatIconAsset(IconAsset, "rbxassetid://84830962019412")
    LogoImage.Parent = HeadFrame
    AddToRegistry(LogoImage, "ImageColor3", "Text")
    Instance.new("UICorner", LogoImage).CornerRadius = UDim.new(0, 7)

    local WindowName = Instance.new("TextLabel")
    WindowName.Size = UDim2.new(1, -65, 0, 25)
    WindowName.Position = UDim2.new(0, 55, 0, 4)
    WindowName.BackgroundTransparency = 1
    WindowName.Font = Enum.Font.GothamBold
    WindowName.Text = Title; WindowName.TextSize = 18
    WindowName.TextXAlignment = Enum.TextXAlignment.Left
    WindowName.Parent = HeadFrame
    AddToRegistry(WindowName, "TextColor3", "Text")

    local WindowContent = Instance.new("TextLabel")
    WindowContent.Size = UDim2.new(1, -65, 0, 15)
    WindowContent.Position = UDim2.new(0, 55, 0, 25)
    WindowContent.BackgroundTransparency = 1
    WindowContent.Font = Enum.Font.GothamMedium
    WindowContent.Text = Subtitle or ""; WindowContent.TextSize = 9
    WindowContent.TextTransparency = 0.65
    WindowContent.TextXAlignment = Enum.TextXAlignment.Left
    WindowContent.Parent = HeadFrame
    AddToRegistry(WindowContent, "TextColor3", "SubText")
    TextGradient:Skip(WindowContent)

    local LineFrame = Instance.new("Frame")
    LineFrame.Size = UDim2.new(1, -10, 0, 1)
    LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
    LineFrame.AnchorPoint = Vector2.new(0.5, 1)
    LineFrame.BackgroundTransparency = 0.65
    LineFrame.BorderSizePixel = 0; LineFrame.Parent = HeadFrame
    AddToRegistry(LineFrame, "BackgroundColor3", "Stroke")

    local LeftScrollingFrame = Instance.new("ScrollingFrame")
    LeftScrollingFrame.Size = UDim2.new(1, -10, 1, -100)
    LeftScrollingFrame.Position = UDim2.new(0.5, 0, 0, 50)
    LeftScrollingFrame.AnchorPoint = Vector2.new(0.5, 0)
    LeftScrollingFrame.BackgroundTransparency = 1
    LeftScrollingFrame.ScrollBarThickness = 0
    LeftScrollingFrame.Parent = LeftMenuFrame
    local TabList = Instance.new("UIListLayout")
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 0)
    TabList.Parent = LeftScrollingFrame
    local function updateTabCanvas()
        LeftScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 10)
    end
    TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas)
    task.spawn(updateTabCanvas)

    local BottomFrame = Instance.new("Frame")
    BottomFrame.Size = UDim2.new(1, 0, 0, 50)
    BottomFrame.Position = UDim2.new(0, 0, 1, 0)
    BottomFrame.AnchorPoint = Vector2.new(0, 1)
    BottomFrame.BackgroundTransparency = 1
    BottomFrame.Parent = LeftMenuFrame

    local LineFrame_2 = Instance.new("Frame")
    LineFrame_2.Size = UDim2.new(1, -10, 0, 1)
    LineFrame_2.Position = UDim2.new(0.5, 0, 0, 0)
    LineFrame_2.AnchorPoint = Vector2.new(0.5, 0)
    LineFrame_2.BackgroundTransparency = 0.65
    LineFrame_2.BorderSizePixel = 0
    LineFrame_2.Parent = BottomFrame
    AddToRegistry(LineFrame_2, "BackgroundColor3", "Stroke")

    local AccountProfile = Instance.new("ImageLabel")
    local OriginalAccountProfileImage = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    AccountProfile.Size = UDim2.new(0, 35, 0, 35)
    AccountProfile.Position = UDim2.new(0, 10, 0.5, -17.5)
    AccountProfile.BackgroundTransparency = 1
    AccountProfile.Image = OriginalAccountProfileImage
    AccountProfile.Parent = BottomFrame
    Instance.new("UICorner", AccountProfile).CornerRadius = UDim.new(1, 0)

    local AccountName = Instance.new("TextLabel")
    AccountName.Size = UDim2.new(0, 100, 0, 25)
    AccountName.Position = UDim2.new(0, 55, 0, 5)
    AccountName.BackgroundTransparency = 1
    AccountName.Font = Enum.Font.GothamBold
    AccountName.Text = LocalPlayer.DisplayName
    AccountName.TextSize = 14
    AccountName.TextXAlignment = Enum.TextXAlignment.Left
    AccountName.TextTruncate = Enum.TextTruncate.SplitWord
    AccountName.Parent = BottomFrame
    AddToRegistry(AccountName, "TextColor3", "Text")

    local ExpireLabel = Instance.new("TextLabel")
    ExpireLabel.Size = UDim2.new(0, 120, 0, 15)
    ExpireLabel.Position = UDim2.new(0, 55, 0, 25)
    ExpireLabel.BackgroundTransparency = 1
    ExpireLabel.Font = Enum.Font.GothamMedium
    ExpireLabel.Text = LocalPlayer.Name
    ExpireLabel.TextSize = 10
    ExpireLabel.TextTransparency = 0.65
    ExpireLabel.TextXAlignment = Enum.TextXAlignment.Left
    ExpireLabel.Parent = BottomFrame
    AddToRegistry(ExpireLabel, "TextColor3", "SubText")
    TextGradient:Skip(ExpireLabel)

    local UserSettingButton = Instance.new("TextLabel")
    UserSettingButton.Size = UDim2.new(0, 25, 0, 25)
    UserSettingButton.Position = UDim2.new(1, -7, 0.5, 0)
    UserSettingButton.AnchorPoint = Vector2.new(1, 0.5)
    UserSettingButton.BackgroundTransparency = 1
    local ffOk = pcall(function()
        UserSettingButton.FontFace = Font.new(
            "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json",
            Enum.FontWeight.Regular, Enum.FontStyle.Normal
        )
    end)
    if not ffOk then UserSettingButton.Font = Enum.Font.GothamBold end
    UserSettingButton.Text = "chevron-large-right"
    UserSettingButton.TextSize = 20
    UserSettingButton.TextColor3 = CurrentTheme.Text
    UserSettingButton.TextTransparency = 0.5
    UserSettingButton.TextXAlignment = Enum.TextXAlignment.Center
    UserSettingButton.TextYAlignment = Enum.TextYAlignment.Center
    UserSettingButton.Parent = BottomFrame
    AddToRegistry(UserSettingButton, "TextColor3", "Text")
    TextGradient:Skip(UserSettingButton)

    local PlayerCardArrowIcon = Instance.new("ImageLabel")
    PlayerCardArrowIcon.Name = "PlayerCardArrowIcon"
    PlayerCardArrowIcon.Size = UDim2.new(0, 20, 0, 20)
    PlayerCardArrowIcon.Position = UDim2.new(1, -9.5, 0.5, 0)
    PlayerCardArrowIcon.AnchorPoint = Vector2.new(1, 0.5)
    PlayerCardArrowIcon.BackgroundTransparency = 1
    PlayerCardArrowIcon.Image = "rbxassetid://12966849577"
    PlayerCardArrowIcon.ImageColor3 = CurrentTheme.Text
    PlayerCardArrowIcon.ImageTransparency = 0.5
    PlayerCardArrowIcon.Visible = false
    PlayerCardArrowIcon.Parent = BottomFrame
    AddToRegistry(PlayerCardArrowIcon, "ImageColor3", "Text")

    local BottomClick = Instance.new("TextButton")
    BottomClick.Size = UDim2.new(1, 0, 1, 0)
    BottomClick.BackgroundTransparency = 1
    BottomClick.Text = ""; BottomClick.AutoButtonColor = false
    BottomClick.Parent = BottomFrame

    local SettingsPanel = Instance.new("Frame")
    SettingsPanel.Name = "SettingsSidebarBackdrop"
    SettingsPanel.Size = UDim2.new(1, 0, 1, 0)
    SettingsPanel.AnchorPoint = Vector2.new(0, 0)
    SettingsPanel.Position = UDim2.new(0, 0, 0, 0)
    SettingsPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SettingsPanel.BackgroundTransparency = 1
    SettingsPanel.BorderSizePixel = 0
    SettingsPanel.Visible = false
    SettingsPanel.ZIndex = 100
    SettingsPanel.Parent = MainFrame
    local SettingsRightShade = Instance.new("Frame")
    SettingsRightShade.Name = "SettingsRightBackground"
    SettingsRightShade.Position = UDim2.new(1, 0, 0, 0)
    SettingsRightShade.Size = UDim2.new(1, -151, 1, 0)
    SettingsRightShade.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SettingsRightShade.BackgroundTransparency = 0
    SettingsRightShade.BorderSizePixel = 0
    SettingsRightShade.ZIndex = 100
    SettingsRightShade.Parent = SettingsPanel

    local SettingsBox = Instance.new("Frame")
    SettingsBox.Name = "SidebarMain"
    SettingsBox.Size = UDim2.new(0, 151, 1, -50)
    SettingsBox.Position = UDim2.new(0, -151, 0, 0)
    SettingsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SettingsBox.BackgroundTransparency = 0
    SettingsBox.BorderSizePixel = 0
    SettingsBox.ClipsDescendants = true
    SettingsBox.ZIndex = 101
    SettingsBox.Parent = SettingsPanel

    local SidebarTitle = Instance.new("TextLabel")
    SidebarTitle.Size = UDim2.new(0, 105, 0, 32)
    SidebarTitle.Position = UDim2.new(0, 42, 0.01618, -3)
    SidebarTitle.BackgroundTransparency = 1
    SidebarTitle.Font = Enum.Font.Gotham
    SidebarTitle.Text = "设置面板"
    SidebarTitle.TextSize = 16
    SidebarTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
    SidebarTitle.ZIndex = 102
    SidebarTitle.Parent = SettingsBox

    local SidebarTitleIconFrame = Instance.new("Frame")
    SidebarTitleIconFrame.Name = "SidebarTitleIconFrame"
    SidebarTitleIconFrame.Size = UDim2.new(0, 32, 0, 32)
    SidebarTitleIconFrame.Position = UDim2.new(0, 5, 0.01618, -3)
    SidebarTitleIconFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SidebarTitleIconFrame.BackgroundTransparency = 0
    SidebarTitleIconFrame.BorderSizePixel = 0
    SidebarTitleIconFrame.ZIndex = 102
    SidebarTitleIconFrame.Parent = SettingsBox
    Instance.new("UICorner", SidebarTitleIconFrame).CornerRadius = UDim.new(0, 8)

    local SidebarTitleIcon = Instance.new("ImageLabel")
    SidebarTitleIcon.Size = UDim2.new(0, 28, 0, 28)
    SidebarTitleIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SidebarTitleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SidebarTitleIcon.BackgroundTransparency = 1
    SidebarTitleIcon.Image = "rbxassetid://84830962019412"
    SidebarTitleIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    SidebarTitleIcon.ZIndex = 103
    SidebarTitleIcon.Parent = SidebarTitleIconFrame

    local SettingsSep = Instance.new("Frame")
    SettingsSep.Size = UDim2.new(0, 135, 0, 1)
    SettingsSep.Position = UDim2.new(0.5, 0, 0.145, 0)
    SettingsSep.AnchorPoint = Vector2.new(0.5, 0)
    SettingsSep.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SettingsSep.BackgroundTransparency = 0.5
    SettingsSep.BorderSizePixel = 0
    SettingsSep.ZIndex = 102
    SettingsSep.Parent = SettingsBox

    local SettingsContent = Instance.new("Frame")
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.ZIndex = 102
    SettingsContent.Parent = SettingsPanel

    local function MakeNavBtn(text, iconAsset, yOffset)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 133, 0, 25)
        btn.Position = UDim2.new(0.05376, 0, 0, yOffset)
        btn.BackgroundTransparency = 1
        btn.Text = "       " .. text
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(101, 101, 101)
        btn.AutoButtonColor = false
        btn.ZIndex = 102
        btn.Parent = SettingsBox
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.new(0, 15, 0, 15)
        ic.Position = UDim2.new(0, 0, 0.24, 0)
        ic.BackgroundTransparency = 1
        ic.Image = iconAsset
        ic.ImageColor3 = Color3.fromRGB(101, 101, 101)
        ic.ZIndex = 103
        ic.Parent = btn
        return btn, ic
    end

    local PlayerBtn, PlayerIcon     = MakeNavBtn("玩家卡片",    "rbxassetid://134669175143859", 42)
    local SettingsBtn, SettingsIcon = MakeNavBtn("UI设置",   "rbxassetid://10734910187", 67)
    local CustBtn, CustIcon          = MakeNavBtn("特效设置", "rbxassetid://12974219084", 92)
    local PlayerPage = Instance.new("Frame")
    PlayerPage.Size = UDim2.new(1, -151, 1, 0)
    PlayerPage.Position = UDim2.new(0, 151, 0, 0)
    PlayerPage.BackgroundTransparency = 1
    PlayerPage.Visible = false
    PlayerPage.ZIndex = 102
    PlayerPage.Parent = SettingsContent

    local PTitle = Instance.new("TextLabel")
    PTitle.Size = UDim2.new(1, -24, 0, 24)
    PTitle.Position = UDim2.new(0, 12, 0, 8)
    PTitle.BackgroundTransparency = 1
    PTitle.Font = Enum.Font.Gotham
    PTitle.Text = "玩家卡片"
    PTitle.TextSize = 20
    PTitle.TextXAlignment = Enum.TextXAlignment.Left
    PTitle.TextColor3 = CurrentTheme.Text
    PTitle.ZIndex = 103
    PTitle.Parent = PlayerPage
    AddToRegistry(PTitle, "TextColor3", "Text")

    local PDesc = Instance.new("TextLabel")
    PDesc.Size = UDim2.new(1, -24, 0, 16)
    PDesc.Position = UDim2.new(0, 12, 0, 28)
    PDesc.BackgroundTransparency = 1
    PDesc.Font = Enum.Font.Gotham
    PDesc.Text = "修改左下角显示的名字与头像"
    PDesc.TextSize = 12
    PDesc.TextWrapped = true
    PDesc.TextTransparency = 0.6
    PDesc.TextXAlignment = Enum.TextXAlignment.Left
    PDesc.TextColor3 = CurrentTheme.Text
    PDesc.ZIndex = 103
    PDesc.Parent = PlayerPage
    AddToRegistry(PDesc, "TextColor3", "SubText")
    TextGradient:Skip(PDesc)


    local PlayerHeaderDivider = Instance.new("Frame")
    PlayerHeaderDivider.Size = UDim2.new(1, -24, 0, 1)
    PlayerHeaderDivider.Position = UDim2.new(0, 12, 0, 49)
    PlayerHeaderDivider.BackgroundColor3 = CurrentTheme.Stroke
    PlayerHeaderDivider.BackgroundTransparency = 0.55
    PlayerHeaderDivider.BorderSizePixel = 0
    PlayerHeaderDivider.ZIndex = 103
    PlayerHeaderDivider.Parent = PlayerPage
    AddToRegistry(PlayerHeaderDivider, "BackgroundColor3", "Stroke")

    local PlayerClip = Instance.new("Frame")
    PlayerClip.Name = "PlayerContentClip"
    PlayerClip.Size = UDim2.new(1, 0, 1, -49)
    PlayerClip.Position = UDim2.new(0, 0, 0, 49)
    PlayerClip.BackgroundTransparency = 1
    PlayerClip.BorderSizePixel = 0
    PlayerClip.ClipsDescendants = true
    PlayerClip.ZIndex = 103
    PlayerClip.Parent = PlayerPage

    local PlayerScroll = Instance.new("ScrollingFrame")
    PlayerScroll.Size = UDim2.new(1, -24, 1, -10)
    PlayerScroll.Position = UDim2.new(0, 12, 0, 10)
    PlayerScroll.BackgroundTransparency = 1
    PlayerScroll.BorderSizePixel = 0
    PlayerScroll.ClipsDescendants = true
    PlayerScroll.ScrollBarThickness = 3
    PlayerScroll.ScrollBarImageColor3 = CurrentTheme.Accent
    PlayerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    PlayerScroll.ScrollingEnabled = true
    PlayerScroll.Active = true
    PlayerScroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PlayerScroll.ZIndex = 103
    PlayerScroll.Parent = PlayerClip

    local PlayerCardHolder = Instance.new("Frame")
    PlayerCardHolder.Name = "CenteredPlayerCardHolder"
    PlayerCardHolder.Size = UDim2.new(0, 320, 0, 0)
    PlayerCardHolder.Position = UDim2.new(0.5, 0, 0, 0)
    PlayerCardHolder.AnchorPoint = Vector2.new(0.5, 0)
    PlayerCardHolder.AutomaticSize = Enum.AutomaticSize.Y
    PlayerCardHolder.BackgroundTransparency = 1
    PlayerCardHolder.BorderSizePixel = 0
    PlayerCardHolder.Parent = PlayerScroll

    local playerBuilder = createSectionBuilder(PlayerCardHolder, PlayerCardHolder, 320, 1, Window)
    Window._playerCard = playerBuilder:UserFrame({
        Name    = LocalPlayer.DisplayName,
        Profile = Players:GetUserThumbnailAsync(LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150),
        Expires = LocalPlayer.Name,
        ButtonIcon = 9405931578,
        Names        = { "副名字", "名字" },
        Placeholders = { "输入副名字", "输入名字" },
        Defaults     = { LocalPlayer.DisplayName, LocalPlayer.Name },
        OnChanged = function(idx, text)
            if idx == 1 then
                AccountName.Text = (text ~= "" and text) or LocalPlayer.DisplayName
            elseif idx == 2 then
                ExpireLabel.Text = (text ~= "" and text) or LocalPlayer.Name
            end
        end,
        Parent = PlayerCardHolder,
    })

    local SettingsPage = Instance.new("Frame")
    SettingsPage.Size = UDim2.new(1, -151, 1, 0)
    SettingsPage.Position = UDim2.new(0, 151, 0, 0)
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Visible = false
    SettingsPage.ZIndex = 102
    SettingsPage.Parent = SettingsContent

    local STitle = Instance.new("TextLabel")
    STitle.Size = UDim2.new(1, -24, 0, 24)
    STitle.Position = UDim2.new(0, 12, 0, 8)
    STitle.BackgroundTransparency = 1
    STitle.Font = Enum.Font.Gotham
    STitle.Text = "UI设置"
    STitle.TextSize = 20
    STitle.TextXAlignment = Enum.TextXAlignment.Left
    STitle.TextColor3 = CurrentTheme.Text
    STitle.ZIndex = 103
    STitle.Parent = SettingsPage
    AddToRegistry(STitle, "TextColor3", "Text")

    local SDesc = Instance.new("TextLabel")
    SDesc.Size = UDim2.new(1, -24, 0, 16)
    SDesc.Position = UDim2.new(0, 12, 0, 28)
    SDesc.BackgroundTransparency = 1
    SDesc.Font = Enum.Font.Gotham
    SDesc.Text = "只有几个基础设置"
    SDesc.TextSize = 12
    SDesc.TextWrapped = true
    SDesc.TextTransparency = 0.6
    SDesc.TextXAlignment = Enum.TextXAlignment.Left
    SDesc.TextColor3 = CurrentTheme.Text
    SDesc.ZIndex = 103
    SDesc.Parent = SettingsPage
    AddToRegistry(SDesc, "TextColor3", "SubText")
    TextGradient:Skip(SDesc)


    local SettingsHeaderDivider = Instance.new("Frame")
    SettingsHeaderDivider.Size = UDim2.new(1, -24, 0, 1)
    SettingsHeaderDivider.Position = UDim2.new(0, 12, 0, 49)
    SettingsHeaderDivider.BackgroundColor3 = CurrentTheme.Stroke
    SettingsHeaderDivider.BackgroundTransparency = 0.55
    SettingsHeaderDivider.BorderSizePixel = 0
    SettingsHeaderDivider.ZIndex = 103
    SettingsHeaderDivider.Parent = SettingsPage
    AddToRegistry(SettingsHeaderDivider, "BackgroundColor3", "Stroke")

    local SettingsClip = Instance.new("Frame")
    SettingsClip.Name = "UISettingsContentClip"
    SettingsClip.Size = UDim2.new(1, 0, 1, -49)
    SettingsClip.Position = UDim2.new(0, 0, 0, 49)
    SettingsClip.BackgroundTransparency = 1
    SettingsClip.BorderSizePixel = 0
    SettingsClip.ClipsDescendants = true
    SettingsClip.ZIndex = 103
    SettingsClip.Parent = SettingsPage

    local SettingsScroll = Instance.new("ScrollingFrame")
    SettingsScroll.Name = "UISettingsScroll"
    SettingsScroll.Size = UDim2.new(1, -24, 1, -10)
    SettingsScroll.Position = UDim2.new(0, 12, 0, 10)
    SettingsScroll.BackgroundTransparency = 1
    SettingsScroll.BorderSizePixel = 0
    SettingsScroll.ScrollBarThickness = 3
    SettingsScroll.ScrollBarImageColor3 = CurrentTheme.Accent
    SettingsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    SettingsScroll.ScrollingEnabled = true
    SettingsScroll.Active = true
    SettingsScroll.ClipsDescendants = true
    SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SettingsScroll.ZIndex = 103
    SettingsScroll.Parent = SettingsClip

    local function MakeKeybind(parent, label, defaultValue, callback, yOffset)
        local Tile = Instance.new("Frame")
        Tile.Size = UDim2.new(1, -24, 0, 42)
        Tile.Position = UDim2.new(0, 12, 0, yOffset)
        Tile.BackgroundTransparency = 1
        Tile.BorderSizePixel = 0
        Tile.ZIndex = 103
        Tile.Parent = parent

        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, -20, 0, 1)
        Line.Position = UDim2.new(0, 10, 1, -1)
        Line.BackgroundColor3 = CurrentTheme.Stroke
        Line.BackgroundTransparency = 0.65
        Line.BorderSizePixel = 0
        Line.ZIndex = 103
        Line.Parent = Tile
        AddToRegistry(Line, "BackgroundColor3", "Stroke")

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -130, 0, 18)
        Lbl.Position = UDim2.new(0, 15, 0.5, -9)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.Text = label
        Lbl.TextSize = 13
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.TextTruncate = Enum.TextTruncate.AtEnd
        Lbl.TextColor3 = CurrentTheme.Text
        Lbl.ZIndex = 103
        Lbl.Parent = Tile
        AddToRegistry(Lbl, "TextColor3", "Text")

        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.new(0, 100, 0, 26)
        KeyBtn.Position = UDim2.new(1, -15, 0.5, 0)
        KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
        KeyBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        KeyBtn.Text = ""
        KeyBtn.AutoButtonColor = false
        KeyBtn.ZIndex = 103
        KeyBtn.Parent = Tile
        Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 5)

        local KeyStroke = Instance.new("UIStroke")
        KeyStroke.Thickness = 1
        KeyStroke.Transparency = 0.65
        KeyStroke.Color = CurrentTheme.Stroke
        KeyStroke.Parent = KeyBtn
        table.insert(ThemeListeners, function() KeyStroke.Color = CurrentTheme.Stroke end)

        local KeyLbl = Instance.new("TextLabel")
        KeyLbl.Size = UDim2.new(1, 0, 1, 0)
        KeyLbl.BackgroundTransparency = 1
        KeyLbl.Font = Enum.Font.GothamBold
        KeyLbl.TextSize = 12
        KeyLbl.TextColor3 = CurrentTheme.Text
        KeyLbl.ZIndex = 104
        KeyLbl.Parent = KeyBtn
        AddToRegistry(KeyLbl, "TextColor3", "Text")
        TextGradient:Skip(KeyLbl)

        local state = { Value = defaultValue, IsWaiting = false }
        local function Refresh()
            if state.Value and state.Value.Name then
                KeyLbl.Text = state.Value.Name
            else
                KeyLbl.Text = "无"
            end
        end
        Refresh()

        local inputConn
        KeyBtn.MouseEnter:Connect(function() Tween(Tile, {BackgroundTransparency = 0.65}, 0.15) end)
        KeyBtn.MouseLeave:Connect(function() Tween(Tile, {BackgroundTransparency = 1}, 0.15) end)
        KeyBtn.MouseButton1Click:Connect(function()
            if state.IsWaiting then return end
            state.IsWaiting = true
            KeyLbl.Text = "..."
            if inputConn then inputConn:Disconnect(); inputConn = nil end
            inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                state.IsWaiting = false
                if inputConn then inputConn:Disconnect(); inputConn = nil end
                if input.UserInputType == Enum.UserInputType.Keyboard
                    and input.KeyCode.Name ~= "Unknown" then
                    state.Value = input.KeyCode
                    Refresh()
                    if callback then pcall(callback, input.KeyCode) end
                else
                    Refresh()
                end
            end)
        end)

        return state
    end

    local function MakeToggle(parent, label, defaultValue, callback, yOffset)
        local Tile = Instance.new("Frame")
        Tile.Size = UDim2.new(1, -24, 0, 42)
        Tile.Position = UDim2.new(0, 12, 0, yOffset)
        Tile.BackgroundTransparency = 1
        Tile.BorderSizePixel = 0
        Tile.ZIndex = 103
        Tile.Parent = parent

        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, -20, 0, 1)
        Line.Position = UDim2.new(0, 10, 1, -1)
        Line.BackgroundColor3 = CurrentTheme.Stroke
        Line.BackgroundTransparency = 0.65
        Line.BorderSizePixel = 0
        Line.ZIndex = 103
        Line.Parent = Tile
        AddToRegistry(Line, "BackgroundColor3", "Stroke")

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -75, 0, 18)
        Lbl.Position = UDim2.new(0, 15, 0.5, -9)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.Text = label
        Lbl.TextSize = 13
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.TextTruncate = Enum.TextTruncate.AtEnd
        Lbl.TextColor3 = CurrentTheme.Text
        Lbl.ZIndex = 103
        Lbl.Parent = Tile
        AddToRegistry(Lbl, "TextColor3", "Text")

        local Switch = Instance.new("Frame")
        Switch.Size = UDim2.new(0, 30, 0, 18)
        Switch.Position = UDim2.new(1, -41, 0.5, -9)
        Switch.BackgroundColor3 = defaultValue and CurrentTheme.Accent or Color3.fromRGB(10, 13, 21)
        Switch.BorderSizePixel = 0
        Switch.ZIndex = 103
        Switch.Parent = Tile
        Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

        local SwStroke = Instance.new("UIStroke")
        SwStroke.Thickness = 1
        SwStroke.Transparency = defaultValue and 1 or 0.65
        SwStroke.Color = CurrentTheme.Stroke
        SwStroke.Parent = Switch

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 16, 0, 16)
        Dot.Position = defaultValue and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 1, 0.5, -8)
        Dot.BackgroundColor3 = Color3.new(1, 1, 1)
        Dot.BorderSizePixel = 0
        Dot.ZIndex = 104
        Dot.Parent = Switch
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        local state = { Value = defaultValue }

        table.insert(ThemeListeners, function()
            SwStroke.Color = CurrentTheme.Stroke
            if not state.Value then SwStroke.Transparency = 0.65 end
        end)

        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.BackgroundTransparency = 1
        ClickBtn.Text = ""
        ClickBtn.AutoButtonColor = false
        ClickBtn.ZIndex = 104
        ClickBtn.Parent = Tile

        local function ApplyUI(v)
            state.Value = v
            if v then
                Tween(Switch, {BackgroundColor3 = CurrentTheme.Accent}, 0.18)
                Tween(SwStroke, {Transparency = 1}, 0.18)
                Tween(Dot, {Position = UDim2.new(1, -17, 0.5, -8)}, 0.18)
            else
                Tween(Switch, {BackgroundColor3 = Color3.fromRGB(10, 13, 21)}, 0.18)
                Tween(SwStroke, {Transparency = 0.65}, 0.18)
                Tween(Dot, {Position = UDim2.new(0, 1, 0.5, -8)}, 0.18)
            end
        end

        ClickBtn.MouseEnter:Connect(function() Tween(Tile, {BackgroundTransparency = 0.65}, 0.15) end)
        ClickBtn.MouseLeave:Connect(function() Tween(Tile, {BackgroundTransparency = 1}, 0.15) end)

        ClickBtn.MouseButton1Click:Connect(function()
            ApplyUI(not state.Value)
            pcall(callback, state.Value)
        end)

        return state
    end

    local CompactSidebarState = { Value = false }
    local ApplyCompactSidebar

    MakeKeybind(SettingsScroll, "菜单绑定键", Keybind, function(KeyCode)
        Keybind = KeyCode
    end, 6)

    MakeToggle(SettingsScroll, "文字渐变", true, function(enabled)
        TextGradient:SetEnabled(enabled)
    end, 48)

    MakeToggle(SettingsScroll, "自定义光标", false, function(enabled)
        FengUI:SetCustomCursor(enabled)
    end, 90)

    MakeToggle(SettingsScroll, "紧凑侧栏", false, function(enabled)
        CompactSidebarState.Value = enabled
        if ApplyCompactSidebar then ApplyCompactSidebar(enabled, false) end
    end, 132)

    BuildColorPresetDropdown(SettingsScroll, SettingsPage, MainFrame, WindowGradient)

    BuildFrameStyleDropdown(SettingsScroll, SettingsPage, MainFrame)

    local CustPage = Instance.new("Frame")
    CustPage.Size = UDim2.new(1, -151, 1, 0)
    CustPage.Position = UDim2.new(0, 151, 0, 0)
    CustPage.BackgroundTransparency = 1
    CustPage.Visible = false
    CustPage.ZIndex = 102
    CustPage.Parent = SettingsContent

    local DESIGN_ACCENT = CurrentTheme.Accent or Color3.fromRGB(80, 140, 255)
    local DESIGN_PANEL = Color3.fromRGB(5, 11, 20)
    local DESIGN_CARD = Color3.fromRGB(9, 17, 29)
    local DESIGN_HOVER = Color3.fromRGB(16, 29, 45)
    local DESIGN_LINE = Color3.fromRGB(28, 42, 58)

    local CustTitle = Instance.new("TextLabel")
    CustTitle.Size = UDim2.new(1, -24, 0, 24)
    CustTitle.Position = UDim2.new(0, 12, 0, 8)
    CustTitle.BackgroundTransparency = 1
    CustTitle.Font = Enum.Font.Gotham
    CustTitle.Text = "特效设置"
    CustTitle.TextSize = 20
    CustTitle.TextXAlignment = Enum.TextXAlignment.Left
    CustTitle.TextColor3 = CurrentTheme.Text
    CustTitle.ZIndex = 103
    CustTitle.Parent = CustPage
    AddToRegistry(CustTitle, "TextColor3", "Text")

    local CustDesc = Instance.new("TextLabel")
    CustDesc.Size = UDim2.new(1, -24, 0, 16)
    CustDesc.Position = UDim2.new(0, 12, 0, 28)
    CustDesc.BackgroundTransparency = 1
    CustDesc.Font = Enum.Font.Gotham
    CustDesc.Text = "选择视觉效果"
    CustDesc.TextSize = 12
    CustDesc.TextWrapped = true
    CustDesc.TextTransparency = 0.6
    CustDesc.TextXAlignment = Enum.TextXAlignment.Left
    CustDesc.TextColor3 = CurrentTheme.Text
    CustDesc.ZIndex = 103
    CustDesc.Parent = CustPage
    AddToRegistry(CustDesc, "TextColor3", "SubText")
    TextGradient:Skip(CustDesc)


    local CustHeaderDivider = Instance.new("Frame")
    CustHeaderDivider.Size = UDim2.new(1, -24, 0, 1)
    CustHeaderDivider.Position = UDim2.new(0, 12, 0, 49)
    CustHeaderDivider.BackgroundColor3 = CurrentTheme.Stroke
    CustHeaderDivider.BackgroundTransparency = 0.55
    CustHeaderDivider.BorderSizePixel = 0
    CustHeaderDivider.ZIndex = 103
    CustHeaderDivider.Parent = CustPage
    AddToRegistry(CustHeaderDivider, "BackgroundColor3", "Stroke")

local fireImage = "rbxassetid://79479663112923"
local function fireNoise(seed) return (math.sin(seed * 12.9898 + 78.233) * 43758.5453) % 1 end
local function fireGradient(object, colors, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colors[1]),
        ColorSequenceKeypoint.new(0.5, colors[2]),
        ColorSequenceKeypoint.new(1, colors[3]),
    })
    g.Rotation = rotation or 90
    g.Parent = object
    return g
end
local function loadFireAsset()
    local customAsset = getcustomasset or getsynasset
    if type(customAsset) ~= "function" or type(writefile) ~= "function" then return end
    local function valid(body)
        return type(body) == "string" and #body == 1172326
            and body:sub(1, 8) == "\137PNG\13\10\26\10"
            and body:sub(13, 16) == "IHDR" and body:sub(-8, -5) == "IEND"
    end
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, body = pcall(function()
            if isfile(fireAssetFile) then return readfile(fireAssetFile) end
        end)
        if ok and valid(body) then
            local registered, uri = pcall(customAsset, fireAssetFile)
            if registered and type(uri) == "string" and uri ~= "" then fireImage = uri end
        end
    end
    if fireImage == "" then
        for attempt = 1, 2 do
            if not ScreenGui.Parent then return end
            local ok, body = pcall(function() return game:HttpGet(fireAssetUrl) end)
            if ok and valid(body) then
                local wrote = pcall(writefile, fireAssetFile, body)
                if wrote then
                    local registered, uri = pcall(customAsset, fireAssetFile)
                    if registered and type(uri) == "string" and uri ~= "" then
                        fireImage = uri
                        break
                    end
                end
            end
            if attempt == 1 then task.wait(0.6) end
        end
    end
end
task.spawn(loadFireAsset)

    local CustClip = Instance.new("Frame")
    CustClip.Name = "EffectContentClip"
    CustClip.Size = UDim2.new(1, 0, 1, -49)
    CustClip.Position = UDim2.new(0, 0, 0, 49)
    CustClip.BackgroundTransparency = 1
    CustClip.BorderSizePixel = 0
    CustClip.ClipsDescendants = true
    CustClip.ZIndex = 103
    CustClip.Parent = CustPage

    local FxHolder = Instance.new("ScrollingFrame")
    FxHolder.Name = "EffectCardHolder"
    FxHolder.Size = UDim2.new(1, -24, 1, -10)
    FxHolder.Position = UDim2.new(0, 12, 0, 10)
    FxHolder.BackgroundTransparency = 1
    FxHolder.BorderSizePixel = 0
    FxHolder.ClipsDescendants = true
    FxHolder.ScrollBarThickness = 3
    FxHolder.ScrollBarImageColor3 = DESIGN_ACCENT
    FxHolder.ScrollingDirection = Enum.ScrollingDirection.Y
    FxHolder.ScrollingEnabled = true
    FxHolder.Active = true
    FxHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    FxHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    FxHolder.ZIndex = 103
    FxHolder.Parent = CustClip
    local FxGridContainer = Instance.new("Frame")
    FxGridContainer.Name = "CenteredEffectGrid"
    FxGridContainer.Size = UDim2.new(1, 0, 0, 0)
    FxGridContainer.Position = UDim2.new(0, 0, 0, 0)
    FxGridContainer.AnchorPoint = Vector2.new(0, 0)
    FxGridContainer.AutomaticSize = Enum.AutomaticSize.Y
    FxGridContainer.BackgroundTransparency = 1
    FxGridContainer.BorderSizePixel = 0
    FxGridContainer.Parent = FxHolder

    local FxGrid = Instance.new("UIGridLayout")
    FxGrid.CellSize = UDim2.new(1/3, -6, 0, 88)
    FxGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    FxGrid.FillDirection = Enum.FillDirection.Horizontal
    FxGrid.FillDirectionMaxCells = 3
    FxGrid.SortOrder = Enum.SortOrder.LayoutOrder
    FxGrid.Parent = FxGridContainer
    FxGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentHeight = FxGrid.AbsoluteContentSize.Y + 8
        FxGridContainer.Size = UDim2.new(1, 0, 0, contentHeight)
        FxHolder.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
    end)
    local FxPreviewItems = {}
    local FxPreviewColors = {
        matrix = Color3.fromRGB(45, 255, 135), rain = Color3.fromRGB(105, 190, 255),
        sakura = Color3.fromRGB(255, 135, 190), stars = Color3.fromRGB(175, 150, 255),
        snow = Color3.fromRGB(220, 245, 255), glitch = Color3.fromRGB(255, 70, 145),
        fire = Color3.fromRGB(50, 150, 255),
    }
    local FxGlyphs = {"ア", "カ", "サ", "タ", "ナ", "ハ", "マ", "ヤ", "0", "1", "7", "#", "%"}
    local FxSparkles = {"✦", "✧", "★", "✺", "✶"}
    local function CreateFxViewport(parent, key)
        local viewport = Instance.new("Frame")
        viewport.Name = "LiveEffectPreview"
        viewport.Size = UDim2.new(1, -12, 0, 54)
        viewport.Position = UDim2.new(0, 6, 0, 6)
        viewport.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        viewport.BorderSizePixel = 0
        viewport.ClipsDescendants = true
        viewport.Active = false
        viewport.ZIndex = 105
        viewport.Parent = parent
        Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 7)
        local outline = Instance.new("UIStroke")
        outline.Color = FxPreviewColors[key] or DESIGN_ACCENT
        outline.Transparency = 0.4
        outline.Thickness = 1
        outline.Parent = viewport
        table.insert(FxPreviewItems, {Frame = viewport, Key = key, Timer = 0, SpawnTimer = 0})
        return viewport
    end
    local function addPreviewParticle(item, kind)
    local frame = item.Frame
    if not frame or not frame.Parent then return end
    local key = item.Key
    local w, h = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
    if w < 20 or h < 20 then return end
    local particleClass = (kind == "glyph" or kind == "spark") and "TextLabel" or "Frame"
    local particle = Instance.new(particleClass)
    particle.BorderSizePixel = 0
    particle.BackgroundTransparency = 1
    particle.ZIndex = 107
    if kind == "glyph" then
        particle.Size = UDim2.fromOffset(10, 13)
        particle.Font = Enum.Font.Code
        particle.TextSize = 10
        particle.Text = FxGlyphs[math.random(#FxGlyphs)]
        particle.TextColor3 = math.random() < 0.25 and Color3.fromRGB(220,255,220) or FxPreviewColors[key]
        particle.TextTransparency = math.random(5, 35) / 100
    elseif kind == "spark" then
        local n = math.random(10, 16)
        particle.Size = UDim2.fromOffset(n, n)
        particle.Font = Enum.Font.SourceSansBold
        particle.TextSize = n
        particle.Text = FxSparkles[math.random(#FxSparkles)]
        particle.TextColor3 = ({Color3.fromRGB(255,223,128), Color3.fromRGB(255,255,255), FxPreviewColors[key]})[math.random(3)]
        particle.TextTransparency = 0.1
    else
        local color = FxPreviewColors[key] or Color3.fromRGB(255,255,255)
        if key == "rain" then
            particle.Size = UDim2.fromOffset(2, math.random(9, 16))
            particle.BackgroundColor3 = Color3.fromRGB(195, 225, 255)
            particle.BackgroundTransparency = 0.25
            particle.Rotation = -22
        elseif key == "sakura" then
            particle.Size = UDim2.fromOffset(math.random(6, 9), math.random(4, 7))
            particle.BackgroundColor3 = ({Color3.fromRGB(255,183,197), Color3.fromRGB(255,209,220), Color3.fromRGB(248,200,220)})[math.random(3)]
            particle.BackgroundTransparency = 0.12
            Instance.new("UICorner", particle).CornerRadius = UDim.new(0.6, 0)
        elseif key == "snow" then
            local n = math.random(2, 4)
            particle.Size = UDim2.fromOffset(n, n)
            particle.BackgroundColor3 = Color3.fromRGB(245, 250, 255)
            particle.BackgroundTransparency = 0.12
            Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
        elseif key == "fire" then
            local n = math.random(4, 10)
            particle.Size = UDim2.fromOffset(n, n * 1.5)
            particle.BackgroundColor3 = ({Color3.fromRGB(160, 230, 255), Color3.fromRGB(50, 150, 255), Color3.fromRGB(20, 60, 200)})[math.random(3)]
            particle.BackgroundTransparency = math.random(20, 60) / 100
            Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
        else
            particle.Size = UDim2.fromOffset(math.random(18, math.max(20, math.floor(w * 0.75))), math.random(2, 5))
            particle.BackgroundColor3 = ({Color3.fromRGB(0,255,240), Color3.fromRGB(255,0,115), Color3.fromRGB(255,230,0), color})[math.random(4)]
            particle.BackgroundTransparency = 0.12
        end
    end
    local x = math.random(0, math.max(0, math.floor(w - 12)))
    local y = (key == "stars" or key == "glitch") and math.random(8, math.max(8, math.floor(h - 18))) or -16
    
    if key == "fire" then
        y = h + 10
    end
    
    particle.Position = UDim2.fromOffset(x, y)
    particle.Parent = frame
    local duration = key == "glitch" and (0.16 + math.random() * 0.18) or (1.0 + math.random() * 1.5)
    local goal = {}
    if key == "stars" then
        goal.Position = UDim2.fromOffset(x + math.random(-4, 4), y - math.random(3, 10))
        goal.TextTransparency = 1
    elseif key == "glitch" then
        goal.Position = UDim2.fromOffset(x + math.random(-12, 12), y)
        goal.BackgroundTransparency = 1
    elseif key == "fire" then
        goal.Position = UDim2.fromOffset(x + math.random(-15, 15), y - math.random(30, 60))
        goal.Size = UDim2.fromOffset(1, 1)
        goal.BackgroundTransparency = 1
    else
        goal.Position = UDim2.fromOffset(math.clamp(x + math.random(-12, 12), 0, math.max(0, math.floor(w - 12))), h + 8)
        if particle:IsA("TextLabel") then goal.TextTransparency = 1 else goal.BackgroundTransparency = 1 end
    end
    local tween = TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Connect(function() if particle and particle.Parent then particle:Destroy() end end)
end
    local FxPreviewConn = RunService.RenderStepped:Connect(function(dt)
    for i = #FxPreviewItems, 1, -1 do
        local item = FxPreviewItems[i]
        if not item.Frame or not item.Frame.Parent then
            table.remove(FxPreviewItems, i)
        else
            item.Timer += dt
            item.SpawnTimer += dt
            local interval = item.Key == "matrix" and 0.075 or item.Key == "rain" and 0.055 or item.Key == "sakura" and 0.18 or item.Key == "stars" and 0.12 or item.Key == "snow" and 0.09 or item.Key == "fire" and 0.05 or 0.065
            if item.SpawnTimer >= interval then
                item.SpawnTimer = 0
                local count = item.Key == "glitch" and math.random(1, 3) or (item.Key == "rain" or item.Key == "fire") and 2 or 1
                for _ = 1, count do
                    local kind = item.Key == "matrix" and "glyph" or item.Key == "stars" and "spark" or "shape"
                    addPreviewParticle(item, kind)
                end
            end
            if item.Key == "glitch" and math.random() < 0.025 then
                item.Frame.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
            else
                item.Frame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
            end
        end
    end
end)

    local EffectState    = { matrix=false, rain=false, sakura=false, stars=false, snow=false, glitch=false, fire=false}
    local EffectContainers = {}
    local EffectConns      = {}

    local function StopEffect(key)
        if EffectConns[key] then EffectConns[key]:Disconnect(); EffectConns[key] = nil end
        if EffectContainers[key] then EffectContainers[key]:Destroy(); EffectContainers[key] = nil end
    end

local function StartEffect(key)
    StopEffect(key)
    
if key == "fire" then

        local fireHost = Instance.new("Frame")
        fireHost.Name = "FengUI_OuterFire"
        fireHost.BackgroundTransparency = 1
        fireHost.BorderSizePixel = 0
        fireHost.ClipsDescendants = false
        fireHost.Active = false
        fireHost.ZIndex = MainFrame.ZIndex
        
        fireHost.AnchorPoint = MainFrame.AnchorPoint
        fireHost.Position = MainFrame.Position
        fireHost.Size = MainFrame.Size
        fireHost.Parent = ScreenGui
        EffectContainers[key] = fireHost

        local fireScale = Instance.new("UIScale")
        fireScale.Parent = fireHost

local fireLightBlue = Color3.fromRGB(160, 230, 255)
local fireBlue = Color3.fromRGB(50, 150, 255)
local fireDeepBlue = Color3.fromRGB(20, 60, 200)
        local perimeter = {10, 7, 10, 7}
        local roots, wisps, embers = {}, {}, {}

        local function fireImageLabel(parent, name)
    local image = Instance.new("ImageLabel")
    image.Name = name
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = fireImage
    image.ScaleType = Enum.ScaleType.Stretch
    image.AnchorPoint = Vector2.new(0.5, 1)
    image.Active = false
    image.ZIndex = 1
    image.Parent = parent
    return image
end

        for side, count in ipairs(perimeter) do
            for i = 1, count do
                local fraction = (i - 0.5) / count
                local seed = (#roots + 1) * 1.713
                local root = Instance.new("Frame")
                root.Name = "FireRoot"
                root.BackgroundTransparency = 1
                root.BorderSizePixel = 0
                root.Size = UDim2.fromOffset(1, 1)
                root.ZIndex = 1
                root.Parent = fireHost
                local layers = {}
                for layer = 1, 2 do
                    local image = fireImageLabel(root, layer == 1 and "FireVeil" or "FireBody")
                    local wash = fireGradient(image, {fireLightBlue:Lerp(Color3.fromRGB(200, 240, 255), 0.35), fireBlue, fireDeepBlue}, 90)
                    wash.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.30),
                        NumberSequenceKeypoint.new(0.2, 0.02),
                        NumberSequenceKeypoint.new(0.78, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    image.ImageTransparency = 1
                    layers[layer] = image
                end
                local core = fireImageLabel(root, "FireCore")
                local coreLight = fireGradient(core, {fireDeepBlue, fireBlue, Color3.fromRGB(235, 250, 255)}, 90)
                coreLight.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(0.35, 0),
                    NumberSequenceKeypoint.new(0.78, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                core.ImageTransparency = 1
                roots[#roots + 1] = {node = root, layers = layers, core = core, seed = seed, fraction = fraction, side = side, height = 0.85 + fireNoise(seed) * 0.29}
            end
        end
        for i = 1, 8 do
            local image = fireImageLabel(fireHost, "RisingFireWisp")
            fireGradient(image, {fireLightBlue, fireBlue, fireDeepBlue}, 90)
            image.ImageTransparency = 1
            wisps[i] = {node = image, seed = i * 1.391, rate = 0.53 + fireNoise(i) * 0.17}
        end
        for i = 1, 12 do
            local ember = Instance.new("Frame")
            ember.Name = "RisingFireEmber"
            ember.Size = UDim2.fromOffset(1.5, 3.5)
            ember.AnchorPoint = Vector2.new(0.5, 0.5)
            ember.BackgroundColor3 = i % 2 == 0 and fireLightBlue or fireBlue
            ember.BackgroundTransparency = 1
            ember.BorderSizePixel = 0
            ember.ZIndex = 2
            ember.Parent = fireHost
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = ember
            embers[i] = {node = ember, seed = i * 0.713, rate = 0.38 + fireNoise(i + 6) * 0.22}
        end

        local fireClock = 0
        EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
            if not ScreenGui.Parent then StopEffect(key); return end
            fireClock += dt

            fireHost.Position = MainFrame.Position
            fireHost.AnchorPoint = MainFrame.AnchorPoint
            fireHost.Size = MainFrame.Size
            fireScale.Scale = FitScale.Scale
            fireHost.Visible = MainFrame.Visible and WindowScale.Value > 0.12
            
            if not fireHost.Visible then return end

            local width = fireHost.AbsoluteSize.X
            local height = fireHost.AbsoluteSize.Y
            if width < 40 or height < 40 then return end

            for _, p in ipairs(roots) do
                local baseX, baseY, flameWidth, flameHeight
                if p.side == 1 or p.side == 3 then
                    baseX = width * p.fraction
                    baseY = p.side == 1 and 4 or height + 4
                    flameWidth = math.clamp(width / perimeter[p.side] * 1.4, 18, 66)
                    flameHeight = (p.side == 1 and 64 or 55) * p.height
                else
                    baseX = p.side == 2 and width + 2 or -2
                    baseY = height * p.fraction
                    flameWidth = 38
                    flameHeight = math.clamp(height / perimeter[p.side] * 1.45, 66, 92) * p.height
                end
                p.node.Position = UDim2.fromOffset(baseX, baseY)
                for layer, image in ipairs(p.layers) do
                    local age = (fireClock * (0.61 + fireNoise(p.seed) * 0.18) + p.seed + (layer - 1) * 0.5) % 1
                    local envelope = math.sin(age * math.pi) ^ 2
                    local bend = math.sin(fireClock * 2.5 + p.seed) * 2 + math.sin(fireClock * 4.3 - p.seed) * 0.7
                    image.Position = UDim2.fromOffset(bend + math.sin(age * math.pi) * (layer == 1 and -3 or 3), -age * 5)
                    image.Size = UDim2.fromOffset(flameWidth * (1.1 - age * 0.2), flameHeight * (0.73 + age * 0.53))
                    image.Rotation = bend * (layer == 1 and -1.5 or 2)
                    image.ImageTransparency = 1 - envelope * 0.87
                end
                p.core.Position = UDim2.fromOffset(math.sin(fireClock * 3 - p.seed) * 1.5, 0)
                p.core.Size = UDim2.fromOffset(flameWidth * 0.63, flameHeight * 0.76)
                p.core.Rotation = math.sin(fireClock * 2.6 + p.seed) * 3
                p.core.ImageTransparency = 0.64 - 0.12 * math.sin(fireClock * 3.1 + p.seed) ^ 2
            end
            for _, p in ipairs(wisps) do
                local age = (fireClock * p.rate + p.seed) % 1
                local envelope = math.sin(age * math.pi) ^ 2
                local side = math.floor(p.seed * 10) % 3
                local x = -5 + (width + 10) * fireNoise(p.seed) + math.sin(age * 4 + p.seed) * 5 * age
                local y = height - 10 - age * (height + 48)
                if side == 0 then y = 3 - age * 60
                else
                    x = side == 1 and -8 or width + 8
                    y = height * fireNoise(p.seed + 2) - age * 62
                end
                p.node.Position = UDim2.fromOffset(x, y)
                p.node.Size = UDim2.fromOffset(30 * (1 - age * 0.38), 42 + age * 13)
                p.node.Rotation = math.sin(fireClock * 2 + p.seed) * 7
                p.node.ImageTransparency = 1 - envelope * 0.66
            end
            for _, p in ipairs(embers) do
                local age = (fireClock * p.rate + p.seed) % 1
                local side = math.floor(p.seed * 10) % 3
                local x = -8 + (width + 16) * fireNoise(p.seed + 4) + math.sin(age * 5 + p.seed) * 4
                local y = height - 5 - age * (height + 54)
                if side == 0 then y = -8 - age * 48
                else
                    x = (side == 1 and -11 or width + 11) + math.sin(age * 5 + p.seed) * 3
                    y = height * fireNoise(p.seed + 5) - age * 64
                end
                p.node.Position = UDim2.fromOffset(x, y)
                p.node.BackgroundTransparency = 1 - math.sin(age * math.pi) ^ 2 * 0.62
            end
        end)
        return
    end
        local container = Instance.new("Frame")
        container.Name = "UIEffect_" .. key
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.ClipsDescendants = true
        container.ZIndex = 150
        container.Parent = MainFrame
        EffectContainers[key] = container
        local size = MainFrame.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            RunService.Heartbeat:Wait()
            size = MainFrame.AbsoluteSize
        end
        if size.X <= 0 or size.Y <= 0 then
            size = Vector2.new(500, 299)
        end

        if key == "matrix" then
            local GLYPHS = {
                "ア","イ","ウ","エ","オ","カ","キ","ク","ケ","コ",
                "サ","シ","ス","セ","ソ","タ","チ","ツ","テ","ト",
                "ナ","ニ","ヌ","ネ","ノ","ハ","ヒ","フ","ヘ","ホ",
                "0","1","2","3","4","5","6","7","8","9","X","Z","#","%","*","&"
            }
            local t = 0
            EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
                if not container.Parent then StopEffect(key); return end
                t += dt
                if t < 0.04 then return end
                t = 0
                for _ = 1, 2 do
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(0, 14, 0, 14)
                    label.BackgroundTransparency = 1
                    label.Font = Enum.Font.Code
                    label.TextSize = 12
                    label.Text = GLYPHS[math.random(#GLYPHS)]
                    label.ZIndex = 151
                    if math.random() < 0.20 then
                        label.TextColor3 = Color3.fromRGB(220, 255, 220)
                        label.TextTransparency = 0.05
                    else
                        label.TextColor3 = Color3.fromRGB(0, 255, 100)
                        label.TextTransparency = math.random(15, 35) / 100
                    end
                    local colStep = 14
                    local colIndex = math.random(0, math.max(1, math.floor(size.X / colStep) - 1))
                    local startX = colIndex * colStep + 2
                    label.Position = UDim2.new(0, startX, 0, -15)
                    label.Parent = container
                    local tw = TweenService:Create(label,
                        TweenInfo.new(math.random(140, 250) / 100, Enum.EasingStyle.Linear),
                        { Position = UDim2.new(0, startX, 0, size.Y + 15), TextTransparency = 1 })
                    tw:Play()
                    tw.Completed:Connect(function() label:Destroy() end)
                end
            end)

        elseif key == "rain" then
            EffectConns[key] = RunService.RenderStepped:Connect(function()
                if not container.Parent then StopEffect(key); return end
                for _ = 1, 2 do
                    local drop = Instance.new("Frame")
                    drop.Size = UDim2.new(0, 1, 0, math.random(12, 22))
                    drop.BackgroundColor3 = Color3.fromRGB(200, 225, 255)
                    drop.BackgroundTransparency = math.random(35, 65) / 100
                    drop.BorderSizePixel = 0
                    drop.Rotation = -25
                    drop.ZIndex = 151
                    local startX = math.random(-50, math.floor(size.X))
                    drop.Position = UDim2.new(0, startX, 0, -20)
                    drop.Parent = container
                    local tw = TweenService:Create(drop,
                        TweenInfo.new(math.random(30, 50) / 100, Enum.EasingStyle.Linear),
                        {
                            Position = UDim2.new(0, startX + (size.Y * 0.45), 0, size.Y + 30),
                            BackgroundTransparency = 1
                        })
                    tw:Play()
                    tw.Completed:Connect(function() drop:Destroy() end)
                end
            end)

        elseif key == "sakura" then
            local PETAL_COLORS = {
                Color3.fromRGB(255, 183, 197), Color3.fromRGB(255, 192, 203),
                Color3.fromRGB(255, 209, 220), Color3.fromRGB(248, 200, 220),
                Color3.fromRGB(255, 105, 180),
            }
            local t = 0
            EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
                if not container.Parent then StopEffect(key); return end
                t += dt
                if t < 0.12 then return end
                t = 0
                local petal = Instance.new("Frame")
                petal.Size = UDim2.new(0, math.random(8, 14), 0, math.random(12, 18))
                petal.BackgroundColor3 = PETAL_COLORS[math.random(#PETAL_COLORS)]
                petal.BackgroundTransparency = math.random(10, 35) / 100
                petal.BorderSizePixel = 0
                petal.Rotation = math.random(0, 360)
                petal.ZIndex = 151
                Instance.new("UICorner", petal).CornerRadius = UDim.new(0.6, 0)
                local startX = math.random(-30, math.floor(size.X + 30))
                petal.Position = UDim2.new(0, startX, 0, -20)
                petal.Parent = container
                local spin = (math.random() > 0.5 and 1 or -1) * math.random(180, 540)
                local tw = TweenService:Create(petal,
                    TweenInfo.new(math.random(350, 600) / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {
                        Position = UDim2.new(0, startX + math.random(-80, 100), 0, size.Y + 25),
                        Rotation = petal.Rotation + spin,
                        BackgroundTransparency = 1
                    })
                tw:Play()
                tw.Completed:Connect(function() petal:Destroy() end)
            end)

        elseif key == "stars" then
            local SPARKLE_ICONS = { "✦", "✧", "★", "✨", "✺", "✶" }
            local SPARKLE_COLORS = {
                Color3.fromRGB(255, 223, 128), Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 192, 230),
                Color3.fromRGB(220, 180, 255),
            }
            local t = 0
            EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
                if not container.Parent then StopEffect(key); return end
                t += dt
                if t < 0.08 then return end
                t = 0
                local baseSize = math.random(10, 18)
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0, baseSize, 0, baseSize)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = baseSize
                label.Text = SPARKLE_ICONS[math.random(#SPARKLE_ICONS)]
                label.TextColor3 = SPARKLE_COLORS[math.random(#SPARKLE_COLORS)]
                label.TextTransparency = 1
                label.Rotation = math.random(-30, 30)
                label.ZIndex = 151
                local startX = math.random(10, math.max(10, math.floor(size.X - 20)))
                local startY = math.random(10, math.max(10, math.floor(size.Y - 20)))
                label.Position = UDim2.new(0, startX, 0, startY)
                label.Parent = container
                local lifetime = math.random(120, 220) / 100
                local floatDist = math.random(15, 35)
                local fadeIn = TweenService:Create(label,
                    TweenInfo.new(lifetime * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        TextTransparency = math.random(0, 20) / 100,
                        Position = UDim2.new(0, startX, 0, startY - floatDist * 0.4),
                        Rotation = label.Rotation + 15,
                        Size = UDim2.new(0, baseSize + 4, 0, baseSize + 4)
                    })
                local fadeOut = TweenService:Create(label,
                    TweenInfo.new(lifetime * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {
                        TextTransparency = 1,
                        Position = UDim2.new(0, startX + math.random(-10, 10), 0, startY - floatDist),
                        Rotation = label.Rotation + math.random(-45, 45),
                        Size = UDim2.new(0, baseSize - 2, 0, baseSize - 2)
                    })
                fadeIn:Play()
                fadeIn.Completed:Connect(function() fadeOut:Play() end)
                fadeOut.Completed:Connect(function() label:Destroy() end)
            end)

        elseif key == "snow" then
            local t = 0
            EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
                if not container.Parent then StopEffect(key); return end
                t += dt
                if t < 0.08 then return end
                t = 0
                local flakeSize = math.random(3, 6)
                local flake = Instance.new("Frame")
                flake.Size = UDim2.new(0, flakeSize, 0, flakeSize)
                flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                flake.BackgroundTransparency = math.random(10, 40) / 100
                flake.BorderSizePixel = 0
                flake.ZIndex = 151
                Instance.new("UICorner", flake).CornerRadius = UDim.new(1, 0)
                local startX = math.random(-20, math.floor(size.X + 20))
                flake.Position = UDim2.new(0, startX, 0, -10)
                flake.Parent = container
                local tw = TweenService:Create(flake,
                    TweenInfo.new(math.random(250, 450) / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.new(0, startX + math.random(-40, 60), 0, size.Y + 15),
                        BackgroundTransparency = 1
                    })
                tw:Play()
                tw.Completed:Connect(function() flake:Destroy() end)
            end)

        elseif key == "glitch" then
            local GLITCH_COLORS = {
                Color3.fromRGB(0, 255, 240), Color3.fromRGB(255, 0, 115),
                Color3.fromRGB(255, 230, 0), Color3.fromRGB(0, 150, 255),
                Color3.fromRGB(255, 255, 255),
            }
            local t = 0
            EffectConns[key] = RunService.RenderStepped:Connect(function(dt)
                if not container.Parent then StopEffect(key); return end
                t += dt
                if t < math.random(3, 8) / 100 then return end
                t = 0
                for _ = 1, math.random(1, 3) do
                    local thickness = math.random(1, 4)
                    local width = size.X * (math.random(20, 95) / 100)
                    local line = Instance.new("Frame")
                    line.Size = UDim2.new(0, width, 0, thickness)
                    line.BackgroundColor3 = GLITCH_COLORS[math.random(#GLITCH_COLORS)]
                    line.BackgroundTransparency = math.random(10, 30) / 100
                    line.BorderSizePixel = 0
                    line.ZIndex = 151
                    local startX = math.random(-10, math.max(0, math.floor(size.X - width + 10)))
                    local startY = math.random(5, math.max(5, math.floor(size.Y - thickness)))
                    line.Position = UDim2.new(0, startX, 0, startY)
                    line.Parent = container
                    local tw = TweenService:Create(line,
                        TweenInfo.new(math.random(4, 12) / 100, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.new(0, startX + math.random(-25, 25), 0, startY),
                            BackgroundTransparency = 1
                        })
                    tw:Play()
                    tw.Completed:Connect(function() line:Destroy() end)
                end
            end)
        end
    end

    local ACTIVE_BG    = Color3.fromRGB(12, 24, 39)
    local INACTIVE_BG  = DESIGN_CARD
    local ACTIVE_TXT   = Color3.fromRGB(248, 252, 255)
    local INACTIVE_TXT = Color3.fromRGB(132, 149, 171)
    local EffectButtonRefs = {}

    local function MakeFxBtn(text, key, iconAsset)
        local btn = Instance.new("TextButton")
        btn.Name = "EffectCard_" .. key
        btn.Size = UDim2.new(1/3, -6, 0, 88)
        btn.BackgroundColor3 = INACTIVE_BG
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ClipsDescendants = true
        btn.ZIndex = 103
        btn.Parent = FxGridContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Name = "ChoiceStroke"
        btnStroke.Color = DESIGN_LINE
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.24
        btnStroke.Parent = btn

        local preview = CreateFxViewport(btn, key)

        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.new(0, 11, 0, 11)
        ic.Position = UDim2.new(0, 8, 0, 66)
        ic.BackgroundTransparency = 1
        ic.Image = iconAsset
        ic.ImageColor3 = INACTIVE_TXT
        ic.ScaleType = Enum.ScaleType.Fit
        ic.ZIndex = 104
        ic.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -34, 0, 16)
        lbl.Position = UDim2.new(0, 23, 0, 63)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = text
        lbl.TextSize = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.TextColor3 = INACTIVE_TXT
        lbl.ZIndex = 104
        lbl.Parent = btn

        local function Refresh()
            local on = EffectState[key] == true
            local targetBg = on and ACTIVE_BG or INACTIVE_BG
            local targetText = on and ACTIVE_TXT or INACTIVE_TXT
            Tween(btn, {BackgroundColor3 = targetBg}, 0.15)
            Tween(lbl, {TextColor3 = targetText}, 0.15)
            Tween(ic, {ImageColor3 = on and DESIGN_ACCENT or INACTIVE_TXT}, 0.15)
            Tween(btnStroke, {
                Color = on and DESIGN_ACCENT or DESIGN_LINE,
                Transparency = on and 0.02 or 0.24
            }, 0.15)
        end

        btn.MouseEnter:Connect(function()
            if not EffectState[key] then
                Tween(btn, {BackgroundColor3 = DESIGN_HOVER}, 0.12)
                Tween(btnStroke, {Color = DESIGN_ACCENT, Transparency = 0.35}, 0.12)
            end
        end)
        btn.MouseLeave:Connect(function()
            Refresh()
        end)
        btn.MouseButton1Click:Connect(function()
            EffectState[key] = not EffectState[key]
            Refresh()
            if EffectState[key] then
                StartEffect(key)
            else
                StopEffect(key)
            end
        end)

        EffectButtonRefs[key] = {Refresh = Refresh, Button = btn}
        Refresh()
        return btn
    end

    MakeFxBtn("代码雨", "matrix", "rbxassetid://10709810463")
    MakeFxBtn("下雨",   "rain",   "rbxassetid://10723344432")
    MakeFxBtn("花瓣",   "sakura", "rbxassetid://10723425539")
    MakeFxBtn("星空",   "stars",  "rbxassetid://10734966248")
    MakeFxBtn("雪花",   "snow",   "rbxassetid://10734964600")
    MakeFxBtn("错误",   "glitch", "rbxassetid://10734887784")
    MakeFxBtn("火焰特效", "fire", "rbxassetid://129855843582244")
    CustPage.Destroying:Connect(function()
        if FxPreviewConn then FxPreviewConn:Disconnect(); FxPreviewConn = nil end
        table.clear(FxPreviewItems)
    end)

    table.insert(ThemeListeners, function()
        DESIGN_ACCENT = CurrentTheme.Accent or Color3.fromRGB(80, 140, 255)
        FxHolder.ScrollBarImageColor3 = DESIGN_ACCENT
        PlayerScroll.ScrollBarImageColor3 = DESIGN_ACCENT
        for _, refs in pairs(EffectButtonRefs) do
            if refs and type(refs.Refresh) == "function" then
                pcall(refs.Refresh)
            end
        end
        end)

    local function ShowPage(page)
        PlayerPage.Visible    = (page == "player")
        SettingsPage.Visible  = (page == "settings")
        CustPage.Visible      = (page == "customize")
        local pOn = (page == "player")
        local sOn = (page == "settings")
        local cOn = (page == "customize")
        PlayerBtn.TextColor3    = pOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        SettingsBtn.TextColor3  = sOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        CustBtn.TextColor3      = cOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        PlayerIcon.ImageColor3    = pOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        SettingsIcon.ImageColor3  = sOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        CustIcon.ImageColor3      = cOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
    end
    PlayerBtn.MouseButton1Click:Connect(function() ShowPage("player") end)
    SettingsBtn.MouseButton1Click:Connect(function() ShowPage("settings") end)
    CustBtn.MouseButton1Click:Connect(function() ShowPage("customize") end)
    ShowPage("player")

    Window._userCard = Window._playerCard

    local settingsOpen = false
    local outsideConn = nil

    local function isInside(m, frame)
        if not frame then return false end
        local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
        return m.X >= ap.X and m.X <= ap.X + as.X and m.Y >= ap.Y and m.Y <= ap.Y + as.Y
    end

    local function animateSettingsText(showText)
        local roots = {SettingsBox, SettingsContent}
        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local original = obj:GetAttribute("SettingsOriginalTextTransparency")
                    if original == nil then
                        original = obj.TextTransparency
                        obj:SetAttribute("SettingsOriginalTextTransparency", original)
                    end
                    if showText then
                        obj.TextTransparency = 1
                        Tween(obj, {TextTransparency = original}, 0.22)
                    else
                        Tween(obj, {TextTransparency = 1}, 0.16)
                    end
                end
            end
        end
    end

    local function closeSettings()
        settingsOpen = false
        AccountProfile.Image = OriginalAccountProfileImage
        UserSettingButton.Visible = true
        PlayerCardArrowIcon.Visible = false
        if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
        animateSettingsText(false)
        Tween(SettingsBox, {Position = UDim2.new(0, -151, 0, 0)}, 0.25)
        Tween(SettingsRightShade, {Position = UDim2.new(1, 0, 0, 0)}, 0.25)
        task.delay(0.26, function()
            if not settingsOpen then SettingsPanel.Visible = false end
        end)
    end

    local function openSettings()
        settingsOpen = true
        AccountProfile.Image = OriginalAccountProfileImage
        UserSettingButton.Visible = false
        PlayerCardArrowIcon.Visible = true
        SettingsPanel.Visible = true
        SettingsBox.Position = UDim2.new(0, -151, 0, 0)
        SettingsRightShade.Position = UDim2.new(1, 0, 0, 0)
        SettingsPanel.BackgroundTransparency = 1
        animateSettingsText(true)
        Tween(SettingsBox, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
        Tween(SettingsRightShade, {Position = UDim2.new(0, 151, 0, 0)}, 0.3)
        if outsideConn then outsideConn:Disconnect() end
        local settingsMouse = LocalPlayer:GetMouse()
        outsideConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if not isInside(settingsMouse, SettingsPanel)
                and not isInside(settingsMouse, BottomFrame) then
                    closeSettings()
                end
            end
        end)
    end

    local function toggleSettings()
        if settingsOpen then
            closeSettings()
        else
            openSettings()
        end
    end

    BottomFrame.MouseEnter:Connect(function()
        Tween(UserSettingButton, {TextTransparency = 0.25}, 0.18)
    end)
    BottomFrame.MouseLeave:Connect(function()
        Tween(UserSettingButton, {TextTransparency = 0.5}, 0.18)
    end)
    BottomClick.MouseButton1Click:Connect(toggleSettings)

    local RightMenuFrame = Instance.new("Frame")
    RightMenuFrame.Size = UDim2.new(1, -151, 1, 0)
    RightMenuFrame.Position = UDim2.new(0, 151, 0, 0)
    RightMenuFrame.BackgroundTransparency = 0.6
    RightMenuFrame.ClipsDescendants = true
    RightMenuFrame.Parent = MainFrame
    Instance.new("UICorner", RightMenuFrame).CornerRadius = UDim.new(0, 13)
    AddToRegistry(RightMenuFrame, "BackgroundColor3", "Main")

    local RightStroke = Instance.new("UIStroke")
    RightStroke.Thickness = 1
    RightStroke.Transparency = 0.65
    RightStroke.Parent = RightMenuFrame
    AddToRegistry(RightStroke, "Color", "Stroke")

    if CardMode then
        RightMenuFrame.Size = UDim2.new(1, 0, 1, 0)
        RightMenuFrame.Position = UDim2.new(0, 0, 0, 0)
        RightMenuFrame.BackgroundTransparency = 1
        RightStroke.Transparency = 1
        LineFrame.Visible = false
        LeftScrollingFrame.Visible = false
        BottomFrame.Visible = false
    end

    CompactSidebarState.Width        = 150
    CompactSidebarState.CompactWidth = 56

    local function sidebarGap()
        return (CompactSidebarState.Value and CompactSidebarState.CompactWidth
                or CompactSidebarState.Width) + 1
    end

    ApplyCompactSidebar = function(enabled, instant)
        local compact = enabled == true
        CompactSidebarState.Value = compact
        local width = compact and CompactSidebarState.CompactWidth or CompactSidebarState.Width
        local time  = instant and 0 or 0.25
        local gap   = sidebarGap()

        Tween(LeftMenuFrame, { Size = UDim2.new(0, width, 1, 0) }, time)
        if not CardMode then
            Tween(RightMenuFrame, {
                Position = UDim2.new(0, gap, 0, 0),
                Size     = UDim2.new(1, -gap, 1, 0),
            }, time)
        end

        for _, page in ipairs({ PlayerPage, SettingsPage, CustPage }) do
            if page then
                Tween(page, {
                    Position = UDim2.new(0, gap, 0, 0),
                    Size     = UDim2.new(1, -gap, 1, 0),
                }, time)
            end
        end
        if SettingsRightShade then
            Tween(SettingsRightShade, { Size = UDim2.new(1, -gap, 1, 0) }, time)
        end

        WindowName.Visible    = not compact
        WindowContent.Visible = not compact

        AccountName.Visible        = not compact
        ExpireLabel.Visible        = not compact
        UserSettingButton.Visible  = not compact

        for _, state in ipairs(Window._tabs or {}) do
            if state.textLabel then state.textLabel.Visible = not compact end
        end

        for _, card in ipairs(Window._cards or {}) do
            for _, t in ipairs(card.cardTabs or {}) do
                if t.textLabel then t.textLabel.Visible = not compact end
            end
        end
    end

    task.defer(function()
        pcall(function() ApplyCompactSidebar(CompactSidebarState.Value, true) end)
    end)

    local RightHeader = Instance.new("Frame")
    RightHeader.Size = UDim2.new(1, 0, 0, 50)
    RightHeader.BackgroundTransparency = 1
    RightHeader.Parent = RightMenuFrame

    local LineFrame_3 = Instance.new("Frame")
    LineFrame_3.Size = UDim2.new(1, -10, 0, 1)
    LineFrame_3.Position = UDim2.new(0.5, 0, 1, 0)
    LineFrame_3.AnchorPoint = Vector2.new(0.5, 1)
    LineFrame_3.BackgroundTransparency = 0.65
    LineFrame_3.BorderSizePixel = 0; LineFrame_3.Parent = RightHeader
    AddToRegistry(LineFrame_3, "BackgroundColor3", "Stroke")

    local resizerVisible = false
    local ButtonGroup = Instance.new("Frame")
    ButtonGroup.Size = UDim2.new(0, 180, 1, 0)
    ButtonGroup.Position = UDim2.new(1, -190, 0, 0)
    ButtonGroup.BackgroundTransparency = 1; ButtonGroup.Parent = RightHeader
    local ButtonLayout = Instance.new("UIListLayout")
    ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ButtonLayout.Padding = UDim.new(0, 5); ButtonLayout.Parent = ButtonGroup
    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingRight = UDim.new(0, 10); ButtonPadding.Parent = ButtonGroup

    local function createControlButton(iconAsset, fallbackText, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 32, 0, 32)
        btn.AutoButtonColor = false; btn.Text = ""
        btn.BackgroundTransparency = 0.2
        btn.BackgroundColor3 = CurrentTheme.Element or CurrentTheme.Top
        btn.Parent = ButtonGroup
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 0, 0, 0)
        accent.AnchorPoint = Vector2.new(0.5, 0.5)
        accent.Position = UDim2.new(0.5, 0, 0.5, 0)
        accent.BackgroundTransparency = 1; accent.ZIndex = 2
        accent.BackgroundColor3 = CurrentTheme.Accent
        accent.Parent = btn
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 7)
        local content
        if iconAsset then
            content = Instance.new("ImageLabel")
            content.Size = UDim2.new(0, 14, 0, 14)
            content.AnchorPoint = Vector2.new(0.5, 0.5)
            content.Position = UDim2.new(0.5, 0, 0.5, 0)
            content.BackgroundTransparency = 1
            content.Image = iconAsset
            content.ImageColor3 = CurrentTheme.Text
            content.ImageTransparency = 0.3
            content.ZIndex = 3; content.Parent = btn
        else
            content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, 0, 1, 0)
            content.BackgroundTransparency = 1
            content.Font = Enum.Font.GothamBold
            content.Text = fallbackText or ""
            content.TextSize = 18
            content.TextColor3 = CurrentTheme.Text
            content.TextTransparency = 0.3
            content.ZIndex = 3; content.Parent = btn
        end
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundTransparency = 0}, 0.2)
            if content then
                local p = content:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
                Tween(content, {[p] = 0}, 0.2)
            end
            Tween(accent, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.2}, 0.2)
            if content then
                local p = content:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
                Tween(content, {[p] = 0.3}, 0.2)
            end
            Tween(accent, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn, content
    end

    if CardMode then
        CardReturnBtn = createControlButton("rbxassetid://130391877219356", nil, function()
            if Window._setHomeLayout then Window._setHomeLayout(true) end
        end)
        CardReturnBtn.Name = "CardReturnBtn"
        CardReturnBtn.LayoutOrder = -1
        CardReturnBtn.Visible = false
    end

    local MinimizeBtn = createControlButton(nil, "−", function() end)
    local MaximizeBtn = createControlButton("rbxassetid://6031090998", nil, function()
        resizerVisible = not resizerVisible
        Resizer.Visible = resizerVisible
    end)
    local CloseBtn2 = createControlButton("rbxassetid://130510492706892", nil, function() ScreenGui:Destroy() end)

    BuildConfigMenu(MainFrame, RightHeader, ScreenGui, Window)

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 1, -50)
    TabContainer.Position = UDim2.new(0, 0, 0, 50)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ClipsDescendants = true
    TabContainer.Parent = RightMenuFrame

    if CardMode then
        PageService = Instance.new("UIPageLayout")
        PageService.Parent = TabContainer
        PageService.TweenTime = 0.5
        PageService.EasingStyle = Enum.EasingStyle.Exponential
        PageService.EasingDirection = Enum.EasingDirection.Out
        PageService.HorizontalAlignment = Enum.HorizontalAlignment.Left
        PageService.GamepadInputEnabled = false
        PageService.ScrollWheelInputEnabled = false
        PageService.TouchInputEnabled = false

        HomePage = Instance.new("Frame")
        HomePage.Name = "HomePage"
        HomePage.Size = UDim2.new(1, 0, 1, 0)
        HomePage.BackgroundTransparency = 1
        HomePage.Parent = TabContainer

        local HomeScroll = Instance.new("ScrollingFrame")
        HomeScroll.Name = "HomeScroll"
        HomeScroll.Size = UDim2.new(1, 0, 1, 0)
        HomeScroll.BackgroundTransparency = 1
        HomeScroll.ScrollBarThickness = 0
        HomeScroll.ScrollBarImageTransparency = 1
        HomeScroll.ScrollingEnabled = true
        HomeScroll.ClipsDescendants = true
        HomeScroll.Parent = HomePage

        HomeContent = Instance.new("Frame")
        HomeContent.Name = "HomeContent"
        HomeContent.Size = UDim2.new(1, -24, 0, 60)
        HomeContent.Position = UDim2.new(0, 12, 0, 12)
        HomeContent.BackgroundTransparency = 1
        HomeContent.Parent = HomeScroll

        HomeList = Instance.new("UIGridLayout")
        HomeList.CellSize = UDim2.new(0.5, -8, 0, 60)
        HomeList.CellPadding = UDim2.new(0, 16, 0, 16)
        HomeList.SortOrder = Enum.SortOrder.LayoutOrder
        HomeList.FillDirection = Enum.FillDirection.Horizontal
        HomeList.FillDirectionMaxCells = 2
        HomeList.Parent = HomeContent

        local function updateHomeCanvas()
            local contentH = math.max(HomeList.AbsoluteContentSize.Y + 24, 60)
            HomeContent.Size = UDim2.new(1, -24, 0, contentH)
            HomeScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(contentH + 12, 100))
        end
        HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHomeCanvas)
        HomeContent.ChildAdded:Connect(function()
            task.wait(0.05)
            updateHomeCanvas()
        end)
        HomeContent.ChildRemoved:Connect(function()
            task.wait(0.05)
            updateHomeCanvas()
        end)
        task.spawn(function()
            task.wait()
            updateHomeCanvas()
        end)

        local function setHomeLayout(isHome)
            local cfgFrame = Window._configFrameRef
            if isHome then
                LeftScrollingFrame.Visible = false
                BottomFrame.Visible = false
                LineFrame.Visible = false

                Tween(RightMenuFrame, {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1
                }, 0.2)
                Tween(RightStroke, { Transparency = 1 }, 0.2)

                if cfgFrame then cfgFrame.Visible = false end
                if CardReturnBtn then CardReturnBtn.Visible = false end

                if PageService and HomePage then
                    pcall(function() PageService:JumpTo(HomePage) end)
                end

                for _, s in ipairs(Window._tabs) do
                    s.btn.BackgroundTransparency = 1
                    s.isActive = false
                    if s.glow then BackgroundTransparency = 1 end
                    if s.textLabel then Tween(s.textLabel, {TextTransparency = 0.3}, 0.2) end
                end
                Window._activeTab = nil
                Window._activeCard = nil
            else
                LeftScrollingFrame.Visible = true
                BottomFrame.Visible = true
                LineFrame.Visible = true

                Tween(RightMenuFrame, {
                    Size = UDim2.new(1, -sidebarGap(), 1, 0),
                    Position = UDim2.new(0, sidebarGap(), 0, 0),
                    BackgroundTransparency = 0.6
                }, 0.2)
                Tween(RightStroke, { Transparency = 0.65 }, 0.2)

                if cfgFrame then cfgFrame.Visible = true end
                if CardReturnBtn then CardReturnBtn.Visible = true end

                if Window._activeCard and Window._activeCard.pageContainer and PageService then
                    pcall(function() PageService:JumpTo(Window._activeCard.pageContainer) end)
                end

                if Window._refreshCardTabsVisibility then
                    Window._refreshCardTabsVisibility(Window._activeCard)
                end
            end
        end
        Window._setHomeLayout = setHomeLayout

        Window._refreshCardTabsVisibility = function(card)
    for _, tabState in ipairs(Window._tabs) do
        if tabState.btn and tabState.btn.Parent then
            if card then
                tabState.btn.Visible = (tabState.card == card)
            else
                tabState.btn.Visible = (tabState.card == nil)
            end
        end
    end
    for _, catState in ipairs(Window._categories or {}) do
        if catState.frame and catState.frame.Parent then
            if catState.content then
                local hasMatching = false
                for _, tabState in ipairs(Window._tabs) do
                    if tabState.btn and tabState.btn.Parent == catState.content then
                        if card and tabState.card == card then hasMatching = true; break end
                        if not card and tabState.card == nil then hasMatching = true; break end
                    end
                end
                catState.frame.Visible = hasMatching
            else
                if card then
                    catState.frame.Visible = (catState.card == card)
                else
                    catState.frame.Visible = (catState.card == nil)
                end
            end
        end
    end
end
    else
        PageContainer = Instance.new("ScrollingFrame")
        PageContainer.Size = UDim2.new(1, 0, 1, 0)
        PageContainer.BackgroundTransparency = 1
        PageContainer.ScrollBarThickness = 0
        PageContainer.ScrollingEnabled = true
        PageContainer.Parent = TabContainer

        PageContent = Instance.new("Frame")
        PageContent.Size = UDim2.new(1, 0, 0, 0)
        PageContent.AutomaticSize = Enum.AutomaticSize.Y
        PageContent.BackgroundTransparency = 1
        PageContent.Parent = PageContainer

        PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 0)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = PageContent

        updatePageCanvas = function()
            PageContainer.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
        end
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
        task.spawn(updatePageCanvas)
    end

    local dragToggle = false
    local dragStart, startPos

    local function handleDragBegin(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = MainFrame.Position
            local input_end
            input_end = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false; input_end:Disconnect()
                end
            end)
        end
    end

    HeadFrame.InputBegan:Connect(handleDragBegin)

    if CardMode then
        RightHeader.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local m = LocalPlayer:GetMouse()
            local function inside(f)
                if not f or not f.Visible then return false end
                local p, s = f.AbsolutePosition, f.AbsoluteSize
                return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
            end
            if inside(ButtonGroup) then return end
            if CardReturnBtn and inside(CardReturnBtn) then return end
            handleDragBegin(input)
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

local function AnimateWindowIn()
    MainFrame.Visible  = true
    MainFrame.Size     = UDim2.new(0, FINAL_WIDTH, 0, FINAL_HEIGHT)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    WindowScale.Value  = 0
    TweenService:Create(WindowScale,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Value = 1 }
    ):Play()
    setShadowVisible(true, false)
end
    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if MainFrame.Visible then setShadowVisible(true, false)
        else setShadowVisible(false, false) end
    end)
    task.delay(0.1, AnimateWindowIn)

local MenuIcon
do
    local iconSize = 40
    local draggable = true
    local DragRate = 25
    local DRAG_THRESHOLD = 6
    local ENABLE_SHADOW_ROLL = true

    local IconRoot     = Instance.new("Frame")
    local IconPop      = Instance.new("UIScale")
    local UICornerIcon = Instance.new("UICorner")
    local Stroke       = Instance.new("UIStroke")
    local Gradient     = Instance.new("UIGradient")
    local IconImage    = Instance.new("ImageLabel")
    local UICornerImg  = Instance.new("UICorner")

    IconRoot.Name                    = "FengMenuIcon"
    IconRoot.Parent                  = ScreenGui
    IconRoot.AnchorPoint             = Vector2.new(0, 0.5)
    IconRoot.BackgroundColor3        = Color3.fromRGB(20, 22, 27)
    IconRoot.BackgroundTransparency  = 1
    IconRoot.BorderSizePixel         = 0
    IconRoot.Size                    = UDim2.fromOffset(iconSize, iconSize)
    IconRoot.Position                = UDim2.new(0.92, 0, 0.01, iconSize / 2)
    IconRoot.ZIndex                  = 900
    IconRoot.ClipsDescendants        = false
    IconRoot.Active                  = true
    IconRoot.Visible                 = false

    IconPop.Scale  = 0.5
    IconPop.Parent = IconRoot

    UICornerIcon.CornerRadius = UDim.new(0, math.floor(iconSize * 0.28))
    UICornerIcon.Parent       = IconRoot

    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness       = 2
    Stroke.Color           = Color3.fromRGB(255, 255, 255)
    Stroke.Transparency    = 1
    Stroke.Parent          = IconRoot
    Gradient.Rotation      = 0
    Gradient.Parent        = Stroke

    IconImage.Name                   = "IconImg"
    IconImage.Parent                 = IconRoot
    IconImage.AnchorPoint            = Vector2.new(0.5, 0.5)
    IconImage.BackgroundTransparency = 1
    IconImage.BorderSizePixel        = 0
    IconImage.Position               = UDim2.fromScale(0.5, 0.5)
    IconImage.Size                   = UDim2.fromScale(1, 1)
    IconImage.ZIndex                 = 901
    IconImage.Image                  = "rbxassetid://84830962019412"
    IconImage.ImageColor3            = Color3.fromRGB(255, 255, 255)
    IconImage.ImageTransparency      = 1
    IconImage.ScaleType              = Enum.ScaleType.Stretch

    UICornerImg.CornerRadius = UDim.new(0, math.floor(iconSize * 0.28))
    UICornerImg.Parent       = IconImage

    local shadowStrokesIcon = {}
    local shadowGradients   = {}
    for _, thick in ipairs({6, 5, 4, 3}) do
        local s = Instance.new("UIStroke")
        s.Thickness       = thick
        s.Color           = Color3.new(0, 0, 0)
        s.Transparency    = 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent          = IconRoot
        table.insert(shadowStrokesIcon, s)

        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.4),
            NumberSequenceKeypoint.new(1.00, 0.0),
        })
        g.Parent = s
        table.insert(shadowGradients, g)
    end

    local shadowRollThread = nil
    local function SetIconShadow(visible)
        if shadowRollThread then
            pcall(task.cancel, shadowRollThread)
            shadowRollThread = nil
        end
        for _, s in ipairs(shadowStrokesIcon) do
            TweenService:Create(s, TweenInfo.new(0.175), {
                Transparency = visible and 0.9 or 1,
            }):Play()
        end
        if visible and ENABLE_SHADOW_ROLL then
            shadowRollThread = task.spawn(function()
                while true do
                    task.wait(0.025)
                    for _, g in ipairs(shadowGradients) do
                        if g.Parent then
                            g.Rotation = g.Rotation + 20
                        end
                    end
                end
            end)
        end
    end

    local function ApplyBorderAppearance()
        if not IconRoot.Parent then return end
        local Accent  = CurrentTheme.Accent or Color3.fromRGB(80, 140, 255)
        local Second  = Accent:Lerp(Color3.new(1, 1, 1), 0.55)
        local Clarity = 1
        local Peak    = 1 - Clarity
        local Base    = 1 - (Clarity * 0.45)
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Accent),
            ColorSequenceKeypoint.new(0.3, Accent),
            ColorSequenceKeypoint.new(0.5, Second),
            ColorSequenceKeypoint.new(0.7, Accent),
            ColorSequenceKeypoint.new(1,   Accent),
        })
        Gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   Base),
            NumberSequenceKeypoint.new(0.3, Base),
            NumberSequenceKeypoint.new(0.5, Peak),
            NumberSequenceKeypoint.new(0.7, Base),
            NumberSequenceKeypoint.new(1,   Base),
        })
    end
    ApplyBorderAppearance()

    local borderConn = RunService.RenderStepped:Connect(function(dt)
        if not IconRoot.Parent then return end
        if Stroke.Transparency >= 0.99 then return end
        Gradient.Rotation = (Gradient.Rotation + 90 * math.min(dt, 0.1)) % 360
    end)
    IconRoot.Destroying:Connect(function()
        if borderConn then borderConn:Disconnect(); borderConn = nil end
        if shadowRollThread then pcall(task.cancel, shadowRollThread); shadowRollThread = nil end
    end)

    table.insert(ThemeListeners, ApplyBorderAppearance)

    local Visible   = false
    local ShowToken = 0

    local function SetIconVisible(val)
        if Visible == val then return end
        Visible   = val
        ShowToken = ShowToken + 1
        local Token    = ShowToken
        local ShowInfo = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
        local HideInfo = TweenInfo.new(0.3,  Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local QuadOut  = TweenInfo.new(0.3,  Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
        local QuadIn   = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)

        if val then
            if not IconRoot.Visible then
                IconPop.Scale     = 0.15
                IconRoot.Rotation = -40
            end
            IconRoot.Visible = true
            TweenService:Create(IconPop,   ShowInfo, { Scale = 1 }):Play()
            TweenService:Create(IconRoot,  ShowInfo, { Rotation = 0 }):Play()
            TweenService:Create(IconRoot,  QuadOut,  { BackgroundTransparency = 0 }):Play()
            TweenService:Create(Stroke,    QuadOut,  { Transparency = 0 }):Play()
            TweenService:Create(IconImage, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = 0,
            }):Play()
            SetIconShadow(true)
        else
            TweenService:Create(IconPop,   HideInfo, { Scale = 0 }):Play()
            TweenService:Create(IconRoot,  HideInfo, { Rotation = 40 }):Play()
            TweenService:Create(IconRoot,  QuadIn,   { BackgroundTransparency = 1 }):Play()
            TweenService:Create(Stroke,    QuadIn,   { Transparency = 1 }):Play()
            TweenService:Create(IconImage, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                ImageTransparency = 1,
            }):Play()
            SetIconShadow(false)
            task.delay(0.34, function()
                if Token == ShowToken and not Visible and IconRoot.Parent then
                    IconRoot.Visible  = false
                    IconRoot.Rotation = 0
                end
            end)
        end
    end

    local function clampPosition(pos)
        local screenSize = ScreenGui.AbsoluteSize
        local sz = iconSize
        local nx = math.clamp(pos.X.Scale * screenSize.X + pos.X.Offset, 0, screenSize.X - sz)
        local ny = math.clamp(pos.Y.Scale * screenSize.Y + pos.Y.Offset, sz / 2, screenSize.Y - sz / 2)
        return UDim2.new(0, nx, 0, ny)
    end

    IconRoot.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local dragStart = input.Position
        local startPos  = IconRoot.Position
        local moved     = false
        local moveConn, endConn, followConn
        local base       = clampPosition(startPos)
        local curX, curY = base.X.Offset, base.Y.Offset
        local tgtX, tgtY = curX, curY
        local velX, velY = 0, 0
        local released   = false

        local function stopFollow()
            if followConn then followConn:Disconnect(); followConn = nil end
        end
        local function startFollow()
            if followConn then return end
            followConn = RunService.RenderStepped:Connect(function(dt)
                if not IconRoot.Parent then stopFollow(); return end
                dt = math.min(dt, 0.05)
                local decay   = math.exp(-DragRate * dt)
                local changeX = curX - tgtX
                local changeY = curY - tgtY
                local tempX   = (velX + DragRate * changeX) * dt
                local tempY   = (velY + DragRate * changeY) * dt
                velX = (velX - DragRate * tempX) * decay
                velY = (velY - DragRate * tempY) * decay
                curX = tgtX + (changeX + tempX) * decay
                curY = tgtY + (changeY + tempY) * decay
                if released
                    and math.abs(tgtX - curX) < 0.15
                    and math.abs(tgtY - curY) < 0.15
                    and math.abs(velX) < 4
                    and math.abs(velY) < 4 then
                    curX, curY, velX, velY = tgtX, tgtY, 0, 0
                    IconRoot.Position = UDim2.new(0, math.round(curX), 0, math.round(curY))
                    stopFollow()
                    return
                end
                IconRoot.Position = UDim2.new(0, math.round(curX), 0, math.round(curY))
            end)
        end

        moveConn = UserInputService.InputChanged:Connect(function(mv)
            if mv.UserInputType ~= Enum.UserInputType.MouseMovement
            and mv.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = mv.Position - dragStart
            if (moved or delta.Magnitude > DRAG_THRESHOLD) and draggable then
                moved = true
                local raw = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
                local target = clampPosition(raw)
                tgtX, tgtY   = target.X.Offset, target.Y.Offset
                startFollow()
            end
        end)

        endConn = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            moveConn:Disconnect()
            endConn:Disconnect()
            released = true
            if not followConn then stopFollow() end
            if not moved then
                Window:ToggleInterface()
            end
        end)
    end)

    MenuIcon = {
        Root    = IconRoot,
        Visible = false,
        _size   = iconSize,
        SetVisible = function(_, val)
            SetIconVisible(val == true)
        end,
        GetCenter = function(_)
            local Screen = ScreenGui.AbsoluteSize
            local Pos    = IconRoot.Position
            return Vector2.new(
                Pos.X.Scale * Screen.X + Pos.X.Offset + (iconSize / 2),
                Pos.Y.Scale * Screen.Y + Pos.Y.Offset
            )
        end,
        OnWindowToggle = function(_, windowVisible)
            SetIconVisible(not windowVisible)
        end,
        SetSize = function(_, sz)
            iconSize      = sz
            IconRoot.Size = UDim2.fromOffset(sz, sz)
            IconRoot.Position = UDim2.new(0.92, 0, 0.01, sz / 2)
            UICornerIcon.CornerRadius = UDim.new(0, math.floor(sz * 0.28))
            UICornerImg.CornerRadius  = UDim.new(0, math.floor(sz * 0.28))
        end,
        SetIcon = function(_, src)
            if type(src) == "number" then
                IconImage.Image = "rbxassetid://" .. tostring(src)
            elseif type(src) == "string" and src ~= "" then
                if tonumber(src) then
                    IconImage.Image = "rbxassetid://" .. src
                else
                    IconImage.Image = src
                end
            end
        end,
        SetIconColor = function(_, c)
            if typeof(c) == "Color3" then
                IconImage.ImageColor3 = c
            end
        end,
    }
end

MainFrame.Visible = true

do
    local hideList = { RightMenuFrame }
    if not CardMode then
        table.insert(hideList, 1, LeftMenuFrame)
    end

    local function setContentVisible(v)
        for _, c in ipairs(hideList) do
            if c then c.Visible = v end
        end
    end

    local MinState = {
        Minimized     = false,
        Minimizing    = false,
        RestorePos    = nil,
        RestoreSize   = nil,
        MinimizeStart = 0,
    }

    function Window:_IsShrunk()
        return WindowScale.Value < 0.5
    end

    function Window:Minimize()
        if MinState.Minimizing then return end
        if not MainFrame.Visible then return end
        if WindowScale.Value < 0.5 then return end

        MinState.Minimizing    = true
        MinState.MinimizeStart = os.clock()
        MinState.RestorePos    = MainFrame.Position
        MinState.RestoreSize   = MainFrame.Size

        local Target = UDim2.new(0, 40, 0.5, 0)
        if MenuIcon then
            local Center = MenuIcon:GetCenter()
            Target = UDim2.fromOffset(math.max(Center.X, 0), Center.Y)
        end

        Resizer.Visible = false

        local Tween_ = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        TweenService:Create(MainFrame, Tween_, {
            Position = Target,
            Rotation = 0,
        }):Play()

        local ScaleTween = TweenService:Create(WindowScale, Tween_, { Value = 0.04 })
        ScaleTween:Play()

        task.delay(0.18, function()
            if not MinState.Minimizing then return end
            setShadowVisible(false, false)
            setContentVisible(false)
        end)

        task.delay(0.36, function()
            if not MinState.Minimizing then return end
            if MenuIcon then MenuIcon:SetVisible(true) end
        end)

        ScaleTween.Completed:Once(function(state)
            if state ~= Enum.PlaybackState.Completed then return end
            if not MinState.Minimizing then return end
            MinState.Minimizing = false
            MinState.Minimized  = true

            MainFrame.Visible = false

            MainFrame.Position = MinState.RestorePos
            if MinState.RestoreSize then
                MainFrame.Size = MinState.RestoreSize
            end
            MainFrame.Rotation = 0
            WindowScale.Value  = 1

            if MenuIcon then MenuIcon:SetVisible(true) end
        end)
    end

    function Window:Restore()
        if not MinState.Minimized then
            if MinState.Minimizing then
                if os.clock() - MinState.MinimizeStart < 1.2 then
                    return
                end
                MinState.Minimizing = false
            else
                return
            end
        end
        MinState.Minimized = false

        local ballCenter
        if MenuIcon then
            ballCenter = MenuIcon:GetCenter()
        end

        if MinState.RestoreSize then
            MainFrame.Size = MinState.RestoreSize
        end
        if ballCenter then
            MainFrame.Position = UDim2.fromOffset(ballCenter.X, ballCenter.Y)
        elseif MinState.RestorePos then
            MainFrame.Position = MinState.RestorePos
        end

        WindowScale.Value  = 0.04
        MainFrame.Rotation = 0
        MainFrame.Visible  = true

        local Tween_ = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if MinState.RestorePos then
            TweenService:Create(MainFrame, Tween_, { Position = MinState.RestorePos }):Play()
        end
        TweenService:Create(WindowScale, Tween_, { Value = 1 }):Play()

        task.delay(0.12, function()
            if not MainFrame.Visible then return end
            setContentVisible(true)
            setShadowVisible(true, false)
            Resizer.Visible = resizerVisible == true
        end)

        task.delay(0.28, function()
            if MenuIcon then MenuIcon:SetVisible(false) end
        end)
    end

    function Window:ToggleInterface()
        if MinState.Minimizing then
            if os.clock() - MinState.MinimizeStart < 1.2 then
                return
            end
            MinState.Minimizing = false
        end

        if MinState.Minimized or Window:_IsShrunk() then
            Window:Restore()
            return
        end

        if MainFrame.Visible then
            Window:Minimize()
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if Keybind and input.KeyCode == Keybind then
            Window:ToggleInterface()
        end
    end)

    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not MainFrame.Visible and not MinState.Minimizing and not MinState.Minimized then
            if MenuIcon then MenuIcon:SetVisible(true) end
        end
    end)
end

    Window._currentCategory = nil
    function Window:Category(config)
    local name = type(config) == "table" and config.Name or config
    local collapsible = type(config) == "table" and config.Collapsible or false
    local opened = true
    if type(config) == "table" and config.Opened ~= nil then opened = config.Opened end
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, 0, 0, 0)
    categoryFrame.AutomaticSize = Enum.AutomaticSize.Y
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = LeftScrollingFrame
    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Vertical
    catLayout.SortOrder = Enum.SortOrder.LayoutOrder
    catLayout.Padding = UDim.new(0, 0); catLayout.Parent = categoryFrame
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundTransparency = 1
    header.Text = name
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamBold
    header.TextSize = 13
    header.TextColor3 = CurrentTheme.Text
    header.TextTransparency = 0.5
    header.Parent = categoryFrame
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10); pad.Parent = header
    AddToRegistry(header, "TextColor3", "Text")
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 12, 0, 12)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://8240930340"
    arrow.ImageColor3 = CurrentTheme.Text
    arrow.ImageTransparency = 0.3
    arrow.Visible = collapsible
    arrow.Rotation = opened and 0 or 180
    arrow.Parent = header
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -10, 0.5, 0)
    AddToRegistry(arrow, "ImageColor3", "Text")
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.None
    content.ClipsDescendants = true
    content.Visible = true; content.Parent = categoryFrame
    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 4)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentList.Parent = content
    local currentTween = nil
    local function getContentHeight() return contentList.AbsoluteContentSize.Y or 0 end
    local function setContentHeight(targetHeight, animate)
        targetHeight = math.max(0, targetHeight)
        local currentHeight = content.Size.Y.Offset
        if animate and currentHeight ~= targetHeight then
            if currentTween then currentTween:Cancel(); currentTween = nil end
            currentTween = TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)})
            currentTween:Play()
            currentTween.Completed:Connect(function() currentTween = nil; task.spawn(updateTabCanvas) end)
        else
            content.Size = UDim2.new(1, 0, 0, targetHeight)
            task.spawn(updateTabCanvas)
        end
    end
    local function toggleCategory()
        if not collapsible then return end
        opened = not opened
        Tween(arrow, {Rotation = opened and 0 or 180}, 0.25)
        local targetHeight = opened and getContentHeight() or 0
        setContentHeight(targetHeight, true)
    end
    header.MouseButton1Click:Connect(toggleCategory)
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if opened then
            local h = getContentHeight()
            if math.abs(h - content.Size.Y.Offset) > 0.5 then setContentHeight(h, false) end
        end
    end)
    task.spawn(function()
        task.wait()
        local h = getContentHeight()
        local initialHeight = opened and h or 0
        content.Size = UDim2.new(1, 0, 0, initialHeight)
        updateTabCanvas()
    end)
Window._currentCategory = {
    frame = categoryFrame, content = content, contentList = contentList,
    header = header, label = header, arrow = arrow,
    collapsible = collapsible, opened = opened, toggle = toggleCategory,
    card = CardMode and (Window._pendingCardContext or Window._lastCard) or nil,
}
Window._categories = Window._categories or {}
table.insert(Window._categories, Window._currentCategory)
table.insert(ThemeListeners, function() header.TextColor3 = CurrentTheme.Text; arrow.ImageColor3 = CurrentTheme.Text end)
return Window._currentCategory
end

    function Window:TabDivider()
    local parentContainer = LeftScrollingFrame
    local activeCat = Window._currentCategory
    local activeCard = CardMode and (Window._pendingCardContext or Window._lastCard) or nil
    if activeCat and (not CardMode or activeCat.card == activeCard) then
        parentContainer = activeCat.content
    end
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, 0)
    line.BackgroundColor3 = CurrentTheme.Stroke
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0; line.Parent = parentContainer
    AddToRegistry(line, "BackgroundColor3", "Stroke")
    if CardMode and parentContainer == LeftScrollingFrame then
        Window._categories = Window._categories or {}
        table.insert(Window._categories, { frame = line, card = activeCard })
        if Window._activeCard and activeCard and Window._activeCard ~= activeCard then
            line.Visible = false
        end
    end
end

    Window._cards = {}
    function Window:Card(cfg)
        cfg = cfg or {}
        if not CardMode then
            local proxy = {}
            function proxy:Tab(name, icon)
                return Window:Tab(name, icon)
            end
            return proxy
        end

        local cardName  = cfg.Name or cfg.Title or "卡片"
        local cardDesc  = cfg.Desc or cfg.Description or cfg.SubName or ""
        local cardIcon  = cfg.Icon or cfg.Logo or 127194456372995
        local cardImage = cfg.Image or cfg.Banner

        local cardFrame = Instance.new("Frame")
        cardFrame.Name = "HomeCard"
        cardFrame.Size = UDim2.new(0, 0, 0, 60)
        cardFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        cardFrame.BorderSizePixel = 0
        cardFrame.ClipsDescendants = true
        cardFrame.Parent = HomeContent
        Instance.new("UICorner", cardFrame).CornerRadius = UDim.new(0, 5)

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = CurrentTheme.Accent:Lerp(Color3.fromRGB(10, 10, 10), 0.55)
        cardStroke.Thickness = 1
        cardStroke.Parent = cardFrame
        table.insert(ThemeListeners, function()
            if cardFrame.Parent then
                cardStroke.Color = CurrentTheme.Accent:Lerp(Color3.fromRGB(10, 10, 10), 0.55)
            end
        end)

        if cardImage and tostring(cardImage) ~= "" then
            local banner = Instance.new("ImageLabel")
            banner.Size = UDim2.new(1, 0, 1, 0)
            banner.BackgroundTransparency = 1
            banner.Image = formatIconAsset(cardImage, "")
            banner.ScaleType = Enum.ScaleType.Crop
            banner.ZIndex = 1
            banner.Parent = cardFrame
            Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 5)
        end

        local info = Instance.new("Frame")
        info.Size = UDim2.new(1, 0, 1, 0)
        info.BackgroundTransparency = 1
        info.ZIndex = 2
        info.Parent = cardFrame
        local infoPad = Instance.new("UIPadding")
        infoPad.PaddingLeft = UDim.new(0, 15)
        infoPad.Parent = info
        local infoLayout = Instance.new("UIListLayout")
        infoLayout.Padding = UDim.new(0, 10)
        infoLayout.FillDirection = Enum.FillDirection.Horizontal
        infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
        infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        infoLayout.Parent = info

        local cardIconImg = Instance.new("ImageLabel")
        cardIconImg.Size = UDim2.new(0, 25, 0, 25)
        cardIconImg.BackgroundTransparency = 1
        cardIconImg.LayoutOrder = -1
        cardIconImg.Image = formatIconAsset(cardIcon, "rbxassetid://9904843409")
        cardIconImg.ImageColor3 = Color3.new(1, 1, 1)
        cardIconImg.ZIndex = 3
        cardIconImg.Parent = info

        local textFrame = Instance.new("Frame")
        textFrame.Size = UDim2.new(0, 150, 0, 32)
        textFrame.BackgroundTransparency = 1
        textFrame.ZIndex = 2
        textFrame.Parent = info
        local textLayout = Instance.new("UIListLayout")
        textLayout.Padding = UDim.new(0, 2)
        textLayout.SortOrder = Enum.SortOrder.LayoutOrder
        textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        textLayout.Parent = textFrame

        local cardTitle = Instance.new("TextLabel")
        cardTitle.Size = UDim2.new(0, 150, 0, 14)
        cardTitle.BackgroundTransparency = 1
        cardTitle.Font = Enum.Font.GothamBold
        cardTitle.Text = cardName
        cardTitle.TextSize = 15
        cardTitle.TextColor3 = CurrentTheme.Accent
        cardTitle.TextXAlignment = Enum.TextXAlignment.Left
        cardTitle.ZIndex = 3
        cardTitle.Parent = textFrame
        AddToRegistry(cardTitle, "TextColor3", "Accent")
        TextGradient:Skip(cardTitle)

        local cardDescLbl = Instance.new("TextLabel")
        cardDescLbl.Size = UDim2.new(0, 150, 0, 10)
        cardDescLbl.BackgroundTransparency = 1
        cardDescLbl.Font = Enum.Font.GothamMedium
        cardDescLbl.Text = cardDesc
        cardDescLbl.TextSize = 10
        cardDescLbl.TextColor3 = CurrentTheme.Text
        cardDescLbl.TextTransparency = 0.3
        cardDescLbl.TextXAlignment = Enum.TextXAlignment.Left
        cardDescLbl.ZIndex = 3
        cardDescLbl.Parent = textFrame
        AddToRegistry(cardDescLbl, "TextColor3", "Text")
        TextGradient:Skip(cardDescLbl)

        local cardObj = {
            Name = cardName,
            Frame = cardFrame,
            Tabs = {},
            cardTabs = {},
            activeCardTab = nil,
            targetTabState = nil,
            pageContainer = nil,
            pageService = nil,
        }

        if CardMode then
            local cardPageContainer = Instance.new("Frame")
            cardPageContainer.Name = "CardPageContainer_" .. cardName
            cardPageContainer.Size = UDim2.new(1, 0, 1, 0)
            cardPageContainer.BackgroundTransparency = 1
            cardPageContainer.ClipsDescendants = true
            cardPageContainer.Parent = TabContainer

            cardObj.pageContainer = cardPageContainer
        end

        local cardClick = Instance.new("TextButton")
        cardClick.Size = UDim2.new(1, 0, 1, 0)
        cardClick.BackgroundTransparency = 1
        cardClick.Text = ""
        cardClick.AutoButtonColor = false
        cardClick.ZIndex = 10
        cardClick.Parent = cardFrame

        function cardObj:Tab(name, icon)
            local prev = Window._pendingCardContext
            Window._pendingCardContext = cardObj
            local tabBuilder = Window:Tab(name, icon)
            Window._pendingCardContext = prev

            local tabState = Window._tabs[#Window._tabs]
            cardObj.targetTabState = tabState

            return tabBuilder
        end

        cardClick.MouseButton1Click:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local relX = mouse.X - cardFrame.AbsolutePosition.X
            local relY = mouse.Y - cardFrame.AbsolutePosition.Y
            if relX >= 0 and relY >= 0
                and relX <= cardFrame.AbsoluteSize.X and relY <= cardFrame.AbsoluteSize.Y then
                local circle = Instance.new("Frame")
                circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                circle.BackgroundTransparency = 0.75
                circle.BorderSizePixel = 0
                circle.AnchorPoint = Vector2.new(0.5, 0.5)
                circle.Position = UDim2.new(0, relX, 0, relY)
                circle.Size = UDim2.new(0, 0, 0, 0)
                circle.ZIndex = 15
                circle.Parent = cardFrame
                Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
                local tw = TweenService:Create(circle,
                    TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {
                        Size = UDim2.new(0, cardFrame.AbsoluteSize.X * 1.5, 0,
                                             cardFrame.AbsoluteSize.X * 1.5),
                        BackgroundTransparency = 1,
                    }
                )
                tw.Completed:Connect(function() circle:Destroy() end)
                tw:Play()
            end

            Window._activeCard = cardObj
            if PageService and cardObj.pageContainer then
                pcall(function() PageService:JumpTo(cardObj.pageContainer) end)
            end
            if Window._refreshCardTabsVisibility then
                Window._refreshCardTabsVisibility(cardObj)
            end
            if Window._setHomeLayout then Window._setHomeLayout(false) end

            local targetTab = cardObj.activeCardTab or cardObj.cardTabs[1]
            if targetTab and targetTab.openTab then
                targetTab.openTab()
            end
        end)

        table.insert(Window._cards, cardObj)
        Window._lastCard = cardObj
        return cardObj
    end

    Window._activeTab = nil
    Window._activeCard = nil
    Window._tabs = {}
    function Window:Tab(name, icon)
        local tabLocked      = false
        local tabLockedTitle = "已锁定"
        if type(name) == "table" then
            local cfg = name
            name = cfg.Name or cfg.Text or "Tab"
            icon = cfg.Icon or cfg.Logo
            tabLocked = cfg.Locked == true
            tabLockedTitle = cfg.LockedTitle
                          or cfg.TextLocked
                          or cfg.LockMessage
                          or "已锁定"
        end

        local cardContext = Window._pendingCardContext
if CardMode and not cardContext then
    cardContext = Window._lastCard
end

local parentContainer = LeftScrollingFrame
local activeCat = Window._currentCategory
if activeCat and (not CardMode or activeCat.card == cardContext) then
    parentContainer = activeCat.content
end
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = tostring(name)
        TabBtn.Size = UDim2.new(1, 0, 0, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.BackgroundColor3 = CurrentTheme.Element
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = parentContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 7)

        local tabIndicator = Instance.new("Frame")
        tabIndicator.AnchorPoint = Vector2.new(0, 0.5)
        tabIndicator.Position = UDim2.new(0, 0, 0.5, 0)
        tabIndicator.Size = UDim2.fromOffset(3, 0)
        tabIndicator.BackgroundColor3 = CurrentTheme.Accent
        tabIndicator.BorderSizePixel = 0
        tabIndicator.Parent = TabBtn
        Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(0, 2)

        local TabIcon
        if icon then
            TabIcon = Instance.new("ImageLabel")
            TabIcon.Name = "TabIcon"
            TabIcon.Size = UDim2.new(0, 28, 0, 28)
            TabIcon.Position = UDim2.new(0, 10, 0.5, -14)
            TabIcon.BackgroundTransparency = 1
            if tonumber(icon) then
                TabIcon.Image = "rbxassetid://" .. icon
            else
                TabIcon.Image = icon
            end
            TabIcon.Parent = TabBtn
            AddToRegistry(TabIcon, "ImageColor3", "Text")
            Instance.new("UICorner", TabIcon).CornerRadius = UDim.new(0, 8)
        end

        local TabText = Instance.new("TextLabel")
        TabText.Name = "TabTitle"
        TabText.Size = UDim2.new(1, -53, 1, 0)
        TabText.Position = UDim2.fromOffset(43, 0)
        TabText.BackgroundTransparency = 1
        TabText.Font = Enum.Font.GothamMedium
        TabText.Text = name
        TabText.TextColor3 = CurrentTheme.SubText
        TabText.TextTransparency = 0
        TabText.TextSize = 13
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.TextTruncate = Enum.TextTruncate.AtEnd
        TabText.Parent = TabBtn
        AddToRegistry(TabText, "TextColor3", "Text")

        local state
        local tabHovered = false
        local tabTweens = {}
        local function paintTabEntry(active, animate)
            for _, oldTween in pairs(tabTweens) do
                pcall(function() oldTween:Cancel() end)
            end
            table.clear(tabTweens)

            local duration = animate and 0.16 or 0
            local hovering = tabHovered and not tabLocked
            local backgroundTransparency = hovering and 0 or (active and 0.55 or 1)
            local textColor = (active or hovering) and CurrentTheme.Text or CurrentTheme.SubText
            local targets = {
                {TabBtn, {BackgroundColor3 = CurrentTheme.Element, BackgroundTransparency = backgroundTransparency}},
                {TabText, {TextColor3 = textColor}},
                {tabIndicator, {BackgroundColor3 = CurrentTheme.Accent, Size = UDim2.fromOffset(3, active and 16 or 0)}}
            }
            for _, item in ipairs(targets) do
                local tw = TweenService:Create(item[1], TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), item[2])
                table.insert(tabTweens, tw)
                tw:Play()
            end
        end
        TabBtn.MouseEnter:Connect(function()
            if tabLocked then return end
            tabHovered = true
            paintTabEntry(state and state.isActive or false, true)
        end)
        TabBtn.MouseLeave:Connect(function()
            tabHovered = false
            if tabLocked then return end
            paintTabEntry(state and state.isActive or false, true)
        end)

        local tabLockFrame, tabLockLabel = nil, nil
        if tabLocked then
            tabLockFrame, tabLockLabel = createLockOverlay(TabBtn, tabLockedTitle)
            tabLockFrame.Visible = true
            tabLockFrame.ZIndex = 20
            if tabLockLabel then
                tabLockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 0
        Page.ScrollingEnabled = true

        if CardMode then
            if cardContext and cardContext.pageContainer then
                Page.Parent = cardContext.pageContainer
            else
                Page.Parent = TabContainer
            end
            Page.Visible = false
            Page.Position = UDim2.new(0, 0, 0, 60)
        else
            Page.Visible = false
            Page.Position = UDim2.new(0, 0, 0, 60)
            Page.Parent = PageContainer
        end
        Instance.new("UICorner", Page).CornerRadius = UDim.new(0, 16)
        Page.ClipsDescendants = true

        local PageContentLocal = Instance.new("Frame")
        PageContentLocal.Size = UDim2.new(1, 0, 0, 0)
        PageContentLocal.AutomaticSize = Enum.AutomaticSize.Y
        PageContentLocal.BackgroundTransparency = 1
        PageContentLocal.Parent = Page
        local PageListLocal = Instance.new("UIListLayout")
        PageListLocal.Padding = UDim.new(0, 8)
        PageListLocal.SortOrder = Enum.SortOrder.LayoutOrder
        PageListLocal.HorizontalAlignment = Enum.HorizontalAlignment.Left
        PageListLocal.Parent = PageContentLocal
        local function updatePageCanvasLocal()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageListLocal.AbsoluteContentSize.Y + 10)
        end
        PageListLocal:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvasLocal)
        task.spawn(updatePageCanvasLocal)

        state = {isActive = false, btn = TabBtn, page = Page, textLabel = TabText, iconLabel = TabIcon, indicator = tabIndicator, locked = tabLocked, card = cardContext, paintStyle = paintTabEntry}

        local function openTab()
            if tabLocked then return end
            if Window._activeTab == state and not CardMode then return end
            for _, s in ipairs(Window._tabs) do
                s.isActive = false
                if s.paintStyle then
                    s.paintStyle(false, true)
                else
                    s.btn.BackgroundColor3 = CurrentTheme.Element
                    s.btn.BackgroundTransparency = 1
                end
            end
            state.isActive = true
            paintTabEntry(true, true)

            if CardMode then
                local targetCard = state.card
                if targetCard and targetCard.pageContainer then
                    local switchingCard = (Window._activeCard ~= targetCard)
                    Window._activeCard = targetCard
                    
                    if targetCard.activeCardTab and targetCard.activeCardTab.page then
                        targetCard.activeCardTab.page.Visible = false
                    end
                    
                    targetCard.activeCardTab = state
                    Page.Visible = true
                    Page.Position = UDim2.new(0, 0, 0, 60)
                    Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.5)

                    if switchingCard then
                        if PageService then
                            pcall(function() PageService:JumpTo(targetCard.pageContainer) end)
                        end
                        if Window._refreshCardTabsVisibility then
                            Window._refreshCardTabsVisibility(targetCard)
                        end
                    end
                else
                    if PageService then
                        pcall(function() PageService:JumpTo(Page) end)
                    end
                end
                if Window._setHomeLayout then
                    Window._setHomeLayout(false)
                end
            else
                if Window._activeTab then Window._activeTab.page.Visible = false end
                Page.Visible = true
                Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.5)
            end
            Window._activeTab = state
        end

        TabBtn.MouseButton1Click:Connect(openTab)
        state.openTab = openTab

        if not Window._activeTab and not tabLocked and not CardMode then
            openTab()
        end

        table.insert(Window._tabs, state)
        if CardMode and cardContext then
            if not table.find(cardContext.cardTabs, state) then
                table.insert(cardContext.cardTabs, state)
            end
            if not cardContext.activeCardTab then
                cardContext.activeCardTab = state
            end
        end
        if name == "Config" then TabBtn.LayoutOrder = 99998 end
        if name == "Settings" then TabBtn.LayoutOrder = 99999 end
        table.insert(ThemeListeners, function()
            for _, s in ipairs(Window._tabs) do
                if s.paintStyle then
                    s.paintStyle(s.isActive, false)
                else
                    s.btn.BackgroundColor3 = CurrentTheme.Element
                    s.btn.BackgroundTransparency = s.isActive and 0 or 1
                    if s.indicator then s.indicator.BackgroundColor3 = CurrentTheme.Accent end
                    if s.textLabel then
                        s.textLabel.TextColor3 = (s.isActive or false) and CurrentTheme.Text or CurrentTheme.SubText
                    end
                end
            end
        end)
        return createSectionBuilder(PageContentLocal, PageContentLocal, 330, 1, Window)
    end

    function Window:CreateHomeTab(Config)
        Config = Config or {}
        local title  = Config.Title or Config.Name or "仪表盘"
        local icon   = Config.Icon or Config.Logo or "rbxassetid://9904843409"
        local qqLink = tostring(Config.QQGroup or "https://qm.qq.com/q/GDgGTuT66I")

        local function _CheckObsidianCompat()
            local missing = {}
            local function Need(name, ok)
                if not ok then table.insert(missing, name) end
            end

            Need("cloneref",          (cloneref or clonereference))
            Need("getgenv",           getgenv)
            Need("gethui",            gethui)
            Need("protectgui",        (syn and syn.protect_gui) or protectgui)
            Need("getcustomasset",    getcustomasset)
            Need("writefile",         writefile)
            Need("readfile",          readfile)
            Need("isfile",            isfile)
            Need("isfolder",          isfolder)
            Need("makefolder",        makefolder)
            Need("listfiles",         listfiles)
            Need("delfile",           delfile)
            Need("setclipboard",      setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard))
            Need("request",           (syn and syn.request) or http_request or request)
            Need("sethiddenproperty", sethiddenproperty)
            Need("setscriptable",     setscriptable)

            return (#missing == 0), missing
        end

        local _ObsidianOK, _ObsidianMissing = _CheckObsidianCompat()

        local changelog = Config.ScriptChangelog or Config.Changelog or {}
        local segCfg    = type(Config.Segments) == "table" and Config.Segments or {}

        local prevPending = Window._pendingCardContext
        local targetCard
        if Config.Card == false then
            targetCard = nil
        else
            targetCard = Config.Card or prevPending
            if not targetCard and CardMode then targetCard = Window._lastCard end
        end
        if targetCard then Window._pendingCardContext = targetCard end
        local TabBuilder = Window:Tab(title, icon)
        Window._pendingCardContext = prevPending

        local tabState = Window._tabs[#Window._tabs]
        if not tabState then return TabBuilder end
        local Page = tabState.page
        local PageContent = Page:FindFirstChildWhichIsA("Frame")
        if not PageContent then return TabBuilder end

        local Player       = LocalPlayer
        local ExecutorName = "Unknown"
        local Region       = "未知"
        local TimeFunction = RunService:IsRunning() and time or os.clock
        local StartedAt    = TimeFunction()

        pcall(function()
            if identifyexecutor then
                local ok, name = pcall(identifyexecutor)
                if ok and name then ExecutorName = tostring(name) end
            end
        end)
        pcall(function()
            Region = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(Player)
        end)

        local function Elapsed()
            local e = math.max(0, TimeFunction() - StartedAt)
            if e < 60 then return math.floor(e) .. " 秒" end
            if e < 3600 then return math.floor(e / 60) .. " 分" end
            return math.floor(e / 3600) .. " 小时"
        end

        local function Panel(parent, size, pos)
            local p = Instance.new("Frame")
            p.BackgroundColor3 = CurrentTheme.Top
            p.BackgroundTransparency = 0.25
            p.BorderSizePixel = 0
            p.ClipsDescendants = true
            p.Size = size
            p.Position = pos or UDim2.fromOffset(0, 0)
            p.Parent = parent
            Instance.new("UICorner", p).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke")
            s.Color = CurrentTheme.Stroke
            s.Transparency = 0.68
            s.Parent = p
            table.insert(ThemeListeners, function()
                p.BackgroundColor3 = CurrentTheme.Top
                s.Color = CurrentTheme.Stroke
            end)
            return p
        end

        local function MakeText(parent, txt, sz, bold, transp)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.BorderSizePixel = 0
            l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
            l.Text = tostring(txt or "")
            l.TextColor3 = CurrentTheme.Text
            l.TextSize = sz or 12
            l.TextTransparency = transp or 0
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextYAlignment = Enum.TextYAlignment.Center
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.Parent = parent
            AddToRegistry(l, "TextColor3", "Text")
            return l
        end

        local function MakeIcon(parent, src, sz, color)
            local i = Instance.new("ImageLabel")
            i.BackgroundTransparency = 1
            i.BorderSizePixel = 0
            i.Size = UDim2.fromOffset(sz or 16, sz or 16)
            i.ScaleType = Enum.ScaleType.Fit
            i.ImageColor3 = color or CurrentTheme.Text
            if type(src) == "number" then
                i.Image = "rbxassetid://" .. src
            elseif type(src) == "string" and src ~= "" then
                if tonumber(src) then
                    i.Image = "rbxassetid://" .. src
                elseif src:match("^rbxasset") or src:match("^http") then
                    i.Image = src
                else
                    i.Image = "rbxassetid://" .. src
                end
            end
            i.Parent = parent
            table.insert(ThemeListeners, function()
                i.ImageColor3 = CurrentTheme.Text
            end)
            return i
        end

        local function FitTextToWidth(Label, BaseSize, MinSize, Wrapped)
            BaseSize = BaseSize or Label.TextSize
            MinSize = MinSize or 8
            Label.TextSize = BaseSize
            defer(function()
                if not Label or not Label.Parent then return end
                local W = math.max(1, Label.AbsoluteSize.X)
                local H = math.max(1, Label.AbsoluteSize.Y)
                local sz = BaseSize
                while sz > MinSize do
                    local b = TextService:GetTextSize(Label.Text, sz, Label.Font,
                        Wrapped and Vector2.new(W, math.huge) or Vector2.new(math.huge, H))
                    if b.X <= W and (not Wrapped or b.Y <= H) then break end
                    sz = sz - 1
                end
                Label.TextSize = sz
            end)
        end

        local HomeFonts = {}
        do
            local function tryLoad(relPath, weight, style)
                if type(getcustomasset) ~= "function" then return nil end
                if type(isfile) == "function" then
                    local ok, exists = pcall(isfile, relPath)
                    if not ok or not exists then return nil end
                end
                local ok, asset = pcall(getcustomasset, relPath)
                if not ok or not asset or asset == "" then return nil end
                local ok2, font = pcall(Font.new, asset, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
                return ok2 and font or nil
            end

            HomeFonts.eyebrow = tryLoad("BasedHub/fonts/Archivo-ExpandedBold.ttf",
                Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            HomeFonts.title = tryLoad("BasedHub/fonts/InstrumentSerif-Italic.ttf",
                Enum.FontWeight.Regular, Enum.FontStyle.Italic)
            HomeFonts.body = tryLoad("BasedHub/fonts/Inter-Regular.ttf",
                Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            if not HomeFonts.eyebrow then HomeFonts.eyebrow = Font.fromEnum(Enum.Font.GothamBold) end
            if not HomeFonts.title then
                local ok, f = pcall(function()
                    return Font.fromName("Merriweather", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
                end)
                HomeFonts.title = ok and f or Font.fromEnum(Enum.Font.GothamBold)
            end
            if not HomeFonts.body then HomeFonts.body = Font.fromEnum(Enum.Font.Gotham) end
        end

        local Root = Instance.new("Frame")
        Root.Name = "HomeDashboard"
        Root.Size = UDim2.new(1, -8, 0, 0)
        Root.AutomaticSize = Enum.AutomaticSize.Y
        Root.BackgroundTransparency = 1
        Root.BorderSizePixel = 0
        Root.Parent = PageContent
        local RL = Instance.new("UIListLayout")
        RL.Padding = UDim.new(0, 8)
        RL.SortOrder = Enum.SortOrder.LayoutOrder
        RL.Parent = Root

        local Profile = Panel(Root, UDim2.new(1, 0, 0, 170))
        Profile.LayoutOrder = 1
        Profile.ClipsDescendants = true

        local Banner = Instance.new("ImageLabel")
        Banner.Name = "Still"
        Banner.BackgroundTransparency = 1
        Banner.BorderSizePixel = 0
        Banner.Image = "rbxassetid://83701039519151"
        Banner.ScaleType = Enum.ScaleType.Crop
        Banner.Size = UDim2.new(0.62, 0, 1, -40)
        Banner.Position = UDim2.fromScale(1, 0)
        Banner.AnchorPoint = Vector2.new(1, 0)
        Banner.ImageTransparency = 0.25
        Banner.Parent = Profile
        Instance.new("UICorner", Banner).CornerRadius = UDim.new(0, 8)

        local BannerFade = Instance.new("UIGradient")
        BannerFade.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.55, 0.35),
            NumberSequenceKeypoint.new(1, 0.1),
        })
        BannerFade.Parent = Banner

        local HeroText = Instance.new("Frame")
        HeroText.Name = "Text"
        HeroText.BackgroundTransparency = 1
        HeroText.Size = UDim2.new(0.66, 0, 1, -40)
        HeroText.Parent = Profile
        local TP = Instance.new("UIPadding")
        TP.PaddingTop    = UDim.new(0, 14)
        TP.PaddingRight  = UDim.new(0, 0)
        TP.PaddingBottom = UDim.new(0, 14)
        TP.PaddingLeft   = UDim.new(0, 24)
        TP.Parent = HeroText
        local TL = Instance.new("UIListLayout")
        TL.SortOrder = Enum.SortOrder.LayoutOrder
        TL.VerticalAlignment = Enum.VerticalAlignment.Bottom
        TL.Padding = UDim.new(0, 6)
        TL.Parent = HeroText

        local Eyebrow = Instance.new("Frame")
        Eyebrow.Name = "Eyebrow"
        Eyebrow.BackgroundTransparency = 1
        Eyebrow.Size = UDim2.new(1, 0, 0, 20)
        Eyebrow.LayoutOrder = 1
        Eyebrow.Parent = HeroText
        local EL = Instance.new("UIListLayout")
        EL.FillDirection = Enum.FillDirection.Horizontal
        EL.VerticalAlignment = Enum.VerticalAlignment.Center
        EL.Padding = UDim.new(0, 8)
        EL.SortOrder = Enum.SortOrder.LayoutOrder
        EL.Parent = Eyebrow

        local Pip = Instance.new("Frame")
        Pip.Name = "Pip"
        Pip.Size = UDim2.fromOffset(7, 7)
        Pip.BorderSizePixel = 0
        Pip.LayoutOrder = 1
        Pip.BackgroundColor3 = CurrentTheme.Accent
        Pip.Parent = Eyebrow
        Instance.new("UICorner", Pip).CornerRadius = UDim.new(1, 0)
        table.insert(ThemeListeners, function()
            Pip.BackgroundColor3 = CurrentTheme.Accent
        end)

        local PipRing = Instance.new("Frame")
        PipRing.Name = "Ring"
        PipRing.AnchorPoint = Vector2.new(0.5, 0.5)
        PipRing.Position = UDim2.fromScale(0.5, 0.5)
        PipRing.Size = UDim2.fromScale(1, 1)
        PipRing.BackgroundColor3 = CurrentTheme.Accent
        PipRing.BackgroundTransparency = 0.5
        PipRing.BorderSizePixel = 0
        PipRing.Parent = Pip
        Instance.new("UICorner", PipRing).CornerRadius = UDim.new(1, 0)
        table.insert(ThemeListeners, function()
            PipRing.BackgroundColor3 = CurrentTheme.Accent
        end)

        local pipPhase, pipConn = 0, nil
        pipConn = RunService.RenderStepped:Connect(function(dt)
            if not (Pip.Parent and PipRing.Parent) then
                if pipConn then pipConn:Disconnect(); pipConn = nil end
                return
            end
            pipPhase = (pipPhase + dt / 1.8) % 1
            local p = 1 - (1 - pipPhase) ^ 3
            PipRing.Size = UDim2.fromScale(1 + p * 2.4, 1 + p * 2.4)
            PipRing.BackgroundTransparency = 0.5 + 0.5 * p
        end)

        local EyebrowText = Instance.new("TextLabel")
        EyebrowText.Name = "EyebrowText"
        EyebrowText.BackgroundTransparency = 1
        EyebrowText.BorderSizePixel = 0
        EyebrowText.FontFace = HomeFonts.eyebrow
        EyebrowText.TextSize = 10
        EyebrowText.Text = "FengYu Hub"
        EyebrowText.TextColor3 = CurrentTheme.Accent
        EyebrowText.TextXAlignment = Enum.TextXAlignment.Left
        EyebrowText.TextYAlignment = Enum.TextYAlignment.Center
        EyebrowText.Size = UDim2.new(0, 0, 0, 14)
        EyebrowText.AutomaticSize = Enum.AutomaticSize.X
        EyebrowText.LayoutOrder = 2
        EyebrowText.Parent = Eyebrow
        AddToRegistry(EyebrowText, "TextColor3", "Accent")

        local HeroTitle = Instance.new("TextLabel")
        HeroTitle.Name = "HeroTitle"
        HeroTitle.BackgroundTransparency = 1
        HeroTitle.BorderSizePixel = 0
        HeroTitle.FontFace = HomeFonts.title
        HeroTitle.TextSize = 46
        HeroTitle.Text = "No Next"
        HeroTitle.TextColor3 = CurrentTheme.Text
        HeroTitle.TextXAlignment = Enum.TextXAlignment.Left
        HeroTitle.TextYAlignment = Enum.TextYAlignment.Center
        HeroTitle.TextTruncate = Enum.TextTruncate.AtEnd
        HeroTitle.Size = UDim2.new(1, 0, 0, 0)
        HeroTitle.AutomaticSize = Enum.AutomaticSize.Y
        HeroTitle.LayoutOrder = 2
        HeroTitle.Parent = HeroText
        AddToRegistry(HeroTitle, "TextColor3", "Text")
        TextGradient:Add(HeroTitle)

        local HeroSub = Instance.new("TextLabel")
        HeroSub.Name = "HeroSub"
        HeroSub.BackgroundTransparency = 1
        HeroSub.BorderSizePixel = 0
        HeroSub.FontFace = HomeFonts.body
        HeroSub.TextSize = 13
        HeroSub.Text = "回不去的何止是时间"
        HeroSub.TextColor3 = CurrentTheme.Text
        HeroSub.TextTransparency = 0.25
        HeroSub.TextXAlignment = Enum.TextXAlignment.Left
        HeroSub.TextYAlignment = Enum.TextYAlignment.Center
        HeroSub.TextWrapped = true
        HeroSub.Size = UDim2.new(1, 0, 0, 0)
        HeroSub.AutomaticSize = Enum.AutomaticSize.Y
        HeroSub.LayoutOrder = 3
        HeroSub.Parent = HeroText
        AddToRegistry(HeroSub, "TextColor3", "SubText")
        TextGradient:Skip(HeroSub)

        local SegBox = Instance.new("Frame")
        SegBox.Name = "SegBar"
        SegBox.AnchorPoint = Vector2.new(0, 1)
        SegBox.Position = UDim2.new(0, 12, 1, -4)
        SegBox.Size = UDim2.new(1, -24, 0, 34)
        SegBox.BackgroundTransparency = 1
        SegBox.BorderSizePixel = 0
        SegBox.Parent = Profile
        local SL = Instance.new("UIListLayout")
        SL.FillDirection = Enum.FillDirection.Horizontal
        SL.HorizontalAlignment = Enum.HorizontalAlignment.Left
        SL.VerticalAlignment = Enum.VerticalAlignment.Center
        SL.SortOrder = Enum.SortOrder.LayoutOrder
        SL.Padding = UDim.new(0, 8)
        SL.Parent = SegBox

        local CH = Instance.new("Frame")
        CH.BackgroundTransparency = 1
        CH.BorderSizePixel = 0
        CH.Size = UDim2.new(1, 0, 0, 0)
        CH.AutomaticSize = Enum.AutomaticSize.Y
        CH.LayoutOrder = 2
        CH.Parent = Root

        local function NewPage(parent)
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 0)
            f.AutomaticSize = Enum.AutomaticSize.Y
            f.Visible = false
            f.Parent = parent
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Parent = f
            return f, l
        end

        local DetailsPage = NewPage(CH)
        local ScriptPage  = NewPage(CH)
        local OtherPage   = NewPage(CH)

        local segButtons = {}
        local function MakeSegment(segName, text, ic)
            local lblW = math.max(48,
                TextService:GetTextSize(tostring(text), 12, Enum.Font.GothamBold,
                    Vector2.new(math.huge, math.huge)).X)
            local btnW = lblW + 40
            local bt = Panel(SegBox, UDim2.fromOffset(btnW, 34))
            bt.BackgroundTransparency = 0.55

            local lbl = MakeText(bt, text, 12, true, 0.25)
            lbl.Position = UDim2.new(0, 0, 0, 0)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.TextXAlignment = Enum.TextXAlignment.Center

            segButtons[segName] = { Root = bt, Label = lbl }

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.fromScale(1, 1)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = bt

            hit.MouseButton1Click:Connect(function()
                DetailsPage.Visible = (segName == "Details")
                ScriptPage.Visible  = (segName == "Script")
                OtherPage.Visible   = (segName == "Other")
                for n, s in pairs(segButtons) do
                    local active = (n == segName)
                    Tween(s.Root, {BackgroundTransparency = active and 0.08 or 0.55}, 0.2)
                    if s.Icon then
                        s.Icon.ImageColor3 = active and CurrentTheme.Accent or CurrentTheme.Text
                    end
                    s.Label.TextColor3  = active and CurrentTheme.Accent or CurrentTheme.Text
                    s.Label.TextTransparency = active and 0 or 0.25
                end
            end)
        end

        local segSpec = {
            Details = segCfg.Details or segCfg[1] or {},
            Script  = segCfg.Script  or segCfg[2] or {},
            Other   = segCfg.Other   or segCfg[3] or {},
        }
        local showDetails = segSpec.Details.Show ~= false and Config.ShowDetailsSegment ~= false
        local showScript  = segSpec.Script.Show  ~= false and Config.ShowScriptSegment  ~= false
        local showOther   = segSpec.Other.Show   ~= false and Config.ShowOtherSegment   ~= false

        if showDetails then
            MakeSegment("Details",
                segSpec.Details.Text or segSpec.Details.Name or Config.DetailsText or "详情信息",
                segSpec.Details.Icon or Config.DetailsIcon or 9904843409)
        end
        if showScript then
            MakeSegment("Script",
                segSpec.Script.Text or segSpec.Script.Name or Config.ScriptText or "脚本更新",
                segSpec.Script.Icon or Config.ScriptIcon or 9904743710)
        end
        if showOther then
            MakeSegment("Other",
                segSpec.Other.Text or segSpec.Other.Name or Config.OtherText or "其他更新",
                segSpec.Other.Icon or Config.OtherIcon or 9904843410)
        end

        local fpsAccum, fpsFrames, currentFps = 0, 0, 60
        RunService.RenderStepped:Connect(function(dt)
            fpsAccum = fpsAccum + dt
            fpsFrames = fpsFrames + 1
            if fpsAccum >= 0.5 then
                currentFps = math.floor(fpsFrames / fpsAccum + 0.5)
                fpsAccum, fpsFrames = 0, 0
            end
        end)

        local function getPing()
            local ok, value = pcall(function() return Player:GetNetworkPing() end)
            if ok and type(value) == "number" and value > 0 then
                return math.floor(value * 1000 + 0.5)
            end
            return 0
        end

        local sessionStart = os.clock()
        local function getSession()
            local s = math.floor(os.clock() - sessionStart)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end

        local StatsRow = Instance.new("Frame")
        StatsRow.Name = "Stats"
        StatsRow.Size = UDim2.new(1, 0, 0, 52)
        StatsRow.BackgroundTransparency = 1
        StatsRow.BorderSizePixel = 0
        StatsRow.LayoutOrder = 1
        StatsRow.Parent = DetailsPage

        local statSpecs = {
            { icon = "rbxassetid://105442920358687", label = "帧率", read = function() return tostring(currentFps) end },
            { icon = "rbxassetid://105253464688580", label = "延迟", read = function() return tostring(getPing()) .. " ms" end },
            { icon = "rbxassetid://17415913624",     label = "玩家", read = function() return tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers) end },
            { icon = "rbxassetid://6761866149",      label = "时长", read = getSession },
        }
        local statTiles = {}
        for index, spec in ipairs(statSpecs) do
            local tile = Panel(StatsRow, UDim2.new(0.25, -2, 1, 0), UDim2.new((index - 1) * 0.25, (index - 1) * 1, 0, 0))

            local iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.fromOffset(16, 16)
            iconImg.Position = UDim2.fromOffset(12, 10)
            iconImg.BackgroundTransparency = 1
            iconImg.BorderSizePixel = 0
            iconImg.Image = spec.icon
            iconImg.ImageColor3 = CurrentTheme.SubText or CurrentTheme.Text
            iconImg.ImageTransparency = 0.35
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.Parent = tile
            AddToRegistry(iconImg, "ImageColor3", "SubText")

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -40, 0, 14)
            titleLabel.Position = UDim2.fromOffset(32, 10)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 11
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextYAlignment = Enum.TextYAlignment.Center
            titleLabel.TextColor3 = CurrentTheme.SubText or CurrentTheme.Text
            titleLabel.TextTransparency = 0.45
            titleLabel.Text = spec.label
            titleLabel.Parent = tile
            AddToRegistry(titleLabel, "TextColor3", "SubText")
            TextGradient:Skip(titleLabel)

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(1, -20, 0, 20)
            valueLabel.Position = UDim2.fromOffset(12, 25)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextSize = 17
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left
            valueLabel.TextYAlignment = Enum.TextYAlignment.Center
            valueLabel.TextColor3 = CurrentTheme.Text
            valueLabel.Text = spec.read()
            valueLabel.Parent = tile
            AddToRegistry(valueLabel, "TextColor3", "Text")
            TextGradient:Skip(valueLabel)

            statTiles[index] = { label = valueLabel, read = spec.read }
        end

        RunService.Heartbeat:Connect(function()
            for _, tile in ipairs(statTiles) do
                tile.label.Text = tile.read()
            end
        end)

        local DW = Instance.new("Frame")
        DW.BackgroundTransparency = 1
        DW.BorderSizePixel = 0
        DW.Size = UDim2.new(1, 0, 0, 0)
        DW.AutomaticSize = Enum.AutomaticSize.Y
        DW.LayoutOrder = 2
        DW.Parent = DetailsPage
        local DWL = Instance.new("UIListLayout")
        DWL.FillDirection = Enum.FillDirection.Horizontal
        DWL.SortOrder = Enum.SortOrder.LayoutOrder
        DWL.Padding = UDim.new(0, 8)
        DWL.Parent = DW

        local LeftCol = Instance.new("Frame")
        LeftCol.BackgroundTransparency = 1
        LeftCol.BorderSizePixel = 0
        LeftCol.Size = UDim2.new(0.52, -4, 0, 0)
        LeftCol.AutomaticSize = Enum.AutomaticSize.Y
        LeftCol.LayoutOrder = 1
        LeftCol.Parent = DW
        local LCL = Instance.new("UIListLayout")
        LCL.Padding = UDim.new(0, 8)
        LCL.SortOrder = Enum.SortOrder.LayoutOrder
        LCL.Parent = LeftCol

        local RightCol = Instance.new("Frame")
        RightCol.BackgroundTransparency = 1
        RightCol.BorderSizePixel = 0
        RightCol.Size = UDim2.new(0.48, -4, 0, 0)
        RightCol.AutomaticSize = Enum.AutomaticSize.Y
        RightCol.LayoutOrder = 2
        RightCol.Parent = DW
        local RCL = Instance.new("UIListLayout")
        RCL.Padding = UDim.new(0, 8)
        RCL.SortOrder = Enum.SortOrder.LayoutOrder
        RCL.Parent = RightCol

        local function MakeStat(parent, ttl, val, xScale, y, wScale)
            local st = Panel(parent, UDim2.new(wScale, -6, 0, 42),
                UDim2.new(xScale, 3, 0, y))
            st.BackgroundTransparency = 0.3
            local t = MakeText(st, ttl, 10, true, 0.13)
            t.Position = UDim2.fromOffset(10, 6)
            t.Size = UDim2.new(1, -20, 0, 13)
            local v = MakeText(st, val, 10, false, 0.35)
            v.Position = UDim2.fromOffset(10, 20)
            v.Size = UDim2.new(1, -20, 0, 13)
            return v
        end

        local QQCard = Panel(LeftCol, UDim2.new(1, 0, 0, 68))
        QQCard.LayoutOrder = 2
        QQCard.BackgroundColor3 = CurrentTheme.Accent
        QQCard.BackgroundTransparency = 0.18
        table.insert(ThemeListeners, function()
            QQCard.BackgroundColor3 = CurrentTheme.Accent
        end)
        local QGrad = Instance.new("UIGradient")
        QGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CurrentTheme.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 22)),
        })
        QGrad.Parent = QQCard

        local QTitle = MakeText(QQCard, "QQ 群", 20, true, 0)
        QTitle.Position = UDim2.fromOffset(18, 12)
        QTitle.Size = UDim2.new(1, -36, 0, 25)

        local QSub = MakeText(QQCard,
            qqLink ~= "" and "点击复制 QQ 群链接" or "未配置 QQ 群链接",
            12, false, 0.25)
        QSub.Position = UDim2.fromOffset(18, 38)
        QSub.Size = UDim2.new(1, -36, 0, 18)

        local QClick = Instance.new("TextButton")
        QClick.Size = UDim2.fromScale(1, 1)
        QClick.BackgroundTransparency = 1
        QClick.Text = ""
        QClick.AutoButtonColor = false
        QClick.Parent = QQCard
        QClick.MouseButton1Click:Connect(function()
            if qqLink == "" then return end
            pcall(function()
                if setclipboard then setclipboard(qqLink)
                elseif toclipboard then toclipboard(qqLink)
                elseif set_clipboard then set_clipboard(qqLink) end
            end)
        end)

        local ExecutorCard = Panel(LeftCol, UDim2.new(1, 0, 0, 92))
        ExecutorCard.LayoutOrder = 1

        local ExecStatus = "未知"
        local ExecColor  = CurrentTheme.Accent

        if _ObsidianOK then
            ExecStatus = "你的注入器完全兼容"
            ExecColor  = Color3.fromRGB(45, 180, 115)
        elseif #_ObsidianMissing <= 3 then
            ExecStatus = "部分兼容：缺少 " .. table.concat(_ObsidianMissing, ", ") .. "（只能使用UI的部分功能）"
            ExecColor  = Color3.fromRGB(230, 170, 60)
        else
            ExecStatus = "不兼容款脚本：缺少 " .. table.concat(_ObsidianMissing, ", ")
            ExecColor  = Color3.fromRGB(220, 70, 70)
        end

        ExecutorCard.BackgroundColor3 = ExecColor
        ExecutorCard.BackgroundTransparency = 0.18
        local EGrad = Instance.new("UIGradient")
        EGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ExecColor),
            ColorSequenceKeypoint.new(0.58, Color3.fromRGB(13, 17, 22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
        })
        EGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.55, 0),
            NumberSequenceKeypoint.new(1, 0),
        })
        EGrad.Parent = ExecutorCard

        local ETitle = MakeText(ExecutorCard, ExecutorName, 17, true, 0)
        ETitle.Position = UDim2.fromOffset(18, 16)
        ETitle.Size = UDim2.new(1, -36, 0, 22)

        local ESub = MakeText(ExecutorCard, ExecStatus, 12, false, 0.15)
        ESub.Position = UDim2.fromOffset(18, 42)
        ESub.Size = UDim2.new(1, -36, 0, 40)
        ESub.TextWrapped = true
        ESub.TextTruncate = Enum.TextTruncate.None
        ESub.TextYAlignment = Enum.TextYAlignment.Top
        FitTextToWidth(ESub, 12, 8, true)

        local FriendsCard = Panel(RightCol, UDim2.new(1, 0, 0, 166))
        FriendsCard.LayoutOrder = 1

        local FTitle = MakeText(FriendsCard, "好友", 16, true, 0)
        FTitle.Position = UDim2.fromOffset(16, 12)
        FTitle.Size = UDim2.new(1, -32, 0, 20)

        local FSub = MakeText(FriendsCard, "查看你的好友现在在做什么", 10, false, 0.48)
        FSub.Position = UDim2.fromOffset(16, 32)
        FSub.Size = UDim2.new(1, -32, 0, 14)

        local FriendLabels = {}
        FriendLabels.InServer = MakeStat(FriendsCard, "本服务器", "...", 0,   58,  0.5)
        FriendLabels.Offline  = MakeStat(FriendsCard, "离线",     "...", 0.5, 58,  0.5)
        FriendLabels.Online   = MakeStat(FriendsCard, "在线",     "...", 0,   104, 0.5)
        FriendLabels.All      = MakeStat(FriendsCard, "全部",     "...", 0.5, 104, 0.5)

        local function FillChangelog(Page, Entries, EmptyText)
            local Holder = Panel(Page, UDim2.new(1, 0, 0, 40))
            Holder.AutomaticSize = Enum.AutomaticSize.Y
            local L = Instance.new("UIListLayout")
            L.Padding = UDim.new(0, 8)
            L.SortOrder = Enum.SortOrder.LayoutOrder
            L.Parent = Holder
            local P = Instance.new("UIPadding")
            P.PaddingTop = UDim.new(0, 12)
            P.PaddingBottom = UDim.new(0, 12)
            P.PaddingLeft = UDim.new(0, 12)
            P.PaddingRight = UDim.new(0, 12)
            P.Parent = Holder

            if type(Entries) ~= "table" or #Entries <= 0 then
                local em = MakeText(Holder, EmptyText, 13, false, 0.25)
                em.Size = UDim2.new(1, 0, 0, 26)
                return
            end

            for i, Entry in ipairs(Entries) do
                local TitleText = tostring(Entry.Title or Entry.Name or ("更新 " .. i))
                local DateText  = Entry.Date and tostring(Entry.Date) or ""
                local DescText  = tostring(Entry.Description or Entry.Content or "")

                local Item = Panel(Holder, UDim2.new(1, 0, 0, 0))
                Item.AutomaticSize = Enum.AutomaticSize.Y
                Item.LayoutOrder = i

                local ItemPad = Instance.new("UIPadding")
                ItemPad.PaddingTop    = UDim.new(0, 10)
                ItemPad.PaddingBottom = UDim.new(0, 10)
                ItemPad.PaddingLeft   = UDim.new(0, 14)
                ItemPad.PaddingRight  = UDim.new(0, 14)
                ItemPad.Parent = Item

                local VBox = Instance.new("Frame")
                VBox.BackgroundTransparency = 1
                VBox.BorderSizePixel = 0
                VBox.Size = UDim2.new(1, 0, 0, 0)
                VBox.AutomaticSize = Enum.AutomaticSize.Y
                VBox.Parent = Item

                local VL = Instance.new("UIListLayout")
                VL.Padding = UDim.new(0, 4)
                VL.SortOrder = Enum.SortOrder.LayoutOrder
                VL.Parent = VBox

                local t = MakeText(VBox, TitleText, 14, true, 0)
                t.Size = UDim2.new(1, 0, 0, 18)
                t.LayoutOrder = 1

                if DateText ~= "" then
                    local dt = MakeText(VBox, DateText, 11, false, 0.5)
                    dt.Size = UDim2.new(1, 0, 0, 14)
                    dt.LayoutOrder = 2
                end

                if DescText ~= "" then
                    local d = MakeText(VBox, DescText, 11, false, 0.3)
                    d.Size = UDim2.new(1, 0, 0, 18)
                    d.LayoutOrder = 3
                    d.TextWrapped = true
                    d.TextTruncate = Enum.TextTruncate.None
                    d.TextYAlignment = Enum.TextYAlignment.Top

                    defer(function()
                        if not d.Parent or not VBox.Parent then return end
                        local W = math.max(60, VBox.AbsoluteSize.X)
                        local H = TextService:GetTextSize(
                            d.Text, d.TextSize, d.Font,
                            Vector2.new(W, math.huge)
                        ).Y + 4
                        d.Size = UDim2.new(1, 0, 0, H)
                    end)
                end
            end
        end

        FillChangelog(ScriptPage, changelog, "暂无脚本更新")
        FillChangelog(OtherPage, Config.OtherChangelog, "暂无其他更新")

        local FriendCache = {
            All = "...", Online = "...", Offline = "...", InServer = "...",
            Cooldown = 0,
        }
        local function UpdateFriends()
            if FriendCache.Cooldown > 0 then
                FriendCache.Cooldown = FriendCache.Cooldown - 1
                return
            end
            FriendCache.Cooldown = 30
            task.spawn(function()
                local done = false
                task.delay(8, function() done = true end)
                local OnlineFriends, TotalFriends, InServer = 0, 0, 0
                pcall(function()
                    OnlineFriends = #Player:GetFriendsOnline()
                end)
                if done then return end
                pcall(function()
                    local Pages = Players:GetFriendsAsync(Player.UserId)
                    while true do
                        if done then return end
                        for _, Data in ipairs(Pages:GetCurrentPage()) do
                            TotalFriends = TotalFriends + 1
                            if Players:FindFirstChild(Data.Username) then
                                InServer = InServer + 1
                            end
                        end
                        if Pages.IsFinished then break end
                        Pages:AdvanceToNextPageAsync()
                    end
                end)
                if done then return end
                done = true
                FriendCache.All      = tostring(TotalFriends) .. " 个好友"
                FriendCache.Online   = tostring(OnlineFriends) .. " 个好友"
                FriendCache.Offline  = tostring(math.max(TotalFriends - OnlineFriends, 0)) .. " 个好友"
                FriendCache.InServer = InServer > 0 and tostring(InServer) .. " 个好友" or "无好友"
            end)
        end

        local Accumulator = 0
        local function UpdateHome(dt)
            Accumulator = Accumulator + (dt or 0)
            if Accumulator < 0.5 then return end
            Accumulator = 0

            if FriendLabels.InServer then FriendLabels.InServer.Text = FriendCache.InServer end
            if FriendLabels.Offline  then FriendLabels.Offline.Text  = FriendCache.Offline end
            if FriendLabels.Online   then FriendLabels.Online.Text   = FriendCache.Online end
            if FriendLabels.All      then FriendLabels.All.Text      = FriendCache.All end
            UpdateFriends()
        end

        DetailsPage.Visible = true
        if segButtons["Details"] then
            segButtons["Details"].Root.BackgroundTransparency = 0.08
            if segButtons["Details"].Icon then
                segButtons["Details"].Icon.ImageColor3 = CurrentTheme.Accent
            end
            segButtons["Details"].Label.TextColor3 = CurrentTheme.Accent
            segButtons["Details"].Label.TextTransparency = 0
        end

        local HomeConn = RunService.RenderStepped:Connect(UpdateHome)
        Window._homeCleanup = Window._homeCleanup or {}
        table.insert(Window._homeCleanup, function()
            safeDisconnect(HomeConn)
            if pipConn then pipConn:Disconnect(); pipConn = nil end
        end)

        TabBuilder.HomeRoot = Root
        TabBuilder.GetHomeSection = function() return Root end
        return TabBuilder
    end

    function Window:Execute(config)
        config = config or {}
        local tabName = config.Name or "Execute"
        local tabIcon = config.Icon or "rbxassetid://10734923549"
        local TweenService = game:GetService("TweenService")

        local prevPending = Window._pendingCardContext
        local targetCard
        if config.Card == false then
            targetCard = nil
        else
            targetCard = config.Card or prevPending
            if not targetCard and CardMode then targetCard = Window._lastCard end
        end
        if targetCard then Window._pendingCardContext = targetCard end
        self:Tab(tabName, tabIcon)
        Window._pendingCardContext = prevPending

        local tabState = self._tabs[#self._tabs]
        local Page = tabState.page

        Page.ScrollingEnabled = false
        Page.ScrollBarThickness = 0
        local oldContent = Page:FindFirstChildWhichIsA("Frame")
        if oldContent then oldContent:Destroy() end

        local quickrun = Instance.new("Frame")
        quickrun.Name = "quickrun"
        quickrun.Size = UDim2.new(1, -16, 1, -16)
        quickrun.Position = UDim2.new(0, 8, 0, 8)
        quickrun.BackgroundTransparency = 1
        quickrun.BorderSizePixel = 0
        quickrun.ClipsDescendants = true
        quickrun.Parent = Page

        local tabsFrame = Instance.new("ScrollingFrame")
        tabsFrame.Name = "tabs"
        tabsFrame.Active = true
        tabsFrame.BorderSizePixel = 0
        tabsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabsFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
        tabsFrame.BackgroundTransparency = 1
        tabsFrame.Size = UDim2.new(1, 0, 0, 25)
        tabsFrame.Position = UDim2.new(0, 0, 0, 0)
        tabsFrame.ScrollBarThickness = 0
        tabsFrame.ScrollingDirection = Enum.ScrollingDirection.X
        tabsFrame.Parent = quickrun

        local tabsLayout = Instance.new("UIListLayout")
        tabsLayout.Padding = UDim.new(0, 5)
        tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabsLayout.FillDirection = Enum.FillDirection.Horizontal
        tabsLayout.Parent = tabsFrame

        local addTab = Instance.new("ImageButton")
        addTab.Name = "addtab"
        addTab.BorderSizePixel = 0
        addTab.BackgroundTransparency = 1
        addTab.Image = "rbxassetid://10734924532"
        addTab.Size = UDim2.new(0, 20, 0, 20)
        addTab.LayoutOrder = 9999
        addTab.Parent = tabsFrame

        local buttonsHolder = Instance.new("Frame")
        buttonsHolder.Name = "buttonsholder"
        buttonsHolder.Size = UDim2.new(1, 0, 0, 32)
        buttonsHolder.Position = UDim2.new(0, 0, 1, -32)
        buttonsHolder.BackgroundTransparency = 1
        buttonsHolder.Parent = quickrun

        local btnLayout = Instance.new("UIListLayout")
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnLayout.Padding = UDim.new(0, 5)
        btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.Parent = buttonsHolder

        local editor = Instance.new("ScrollingFrame")
        editor.Name = "editor"
        editor.Active = true
        editor.BorderSizePixel = 0
        editor.BackgroundTransparency = 1
        editor.Size = UDim2.new(1, 0, 1, -65)
        editor.Position = UDim2.new(0, 0, 0, 33)
        editor.CanvasSize = UDim2.new(0, 0, 0, 0)
        editor.ScrollBarImageColor3 = Color3.fromRGB(101, 101, 101)
        editor.ScrollBarThickness = 2
        editor.ClipsDescendants = true
        editor.Parent = quickrun

        local lines = Instance.new("TextLabel")
        lines.Name = "Lines"
        lines.ZIndex = 4
        lines.BorderSizePixel = 0
        lines.TextSize = 14
        lines.TextYAlignment = Enum.TextYAlignment.Top
        lines.BackgroundTransparency = 1
        lines.Font = Enum.Font.Code
        lines.TextColor3 = Color3.fromRGB(255, 255, 255)
        lines.Size = UDim2.new(0, 21, 1, 0)
        lines.ClipsDescendants = true
        lines.Text = "1"
        lines.Parent = editor
        TextGradient:Skip(lines)

        local lineHighlight = Instance.new("Frame")
        lineHighlight.Name = "LineHighlight"
        lineHighlight.Visible = false
        lineHighlight.ZIndex = 0
        lineHighlight.BorderSizePixel = 0
        lineHighlight.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
        lineHighlight.Size = UDim2.new(1, 0, 0, 14)
        lineHighlight.Parent = editor

        local textBox = Instance.new("TextBox")
        textBox.Name = "TextBox"
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.PlaceholderColor3 = Color3.fromRGB(101, 101, 101)
        textBox.BorderSizePixel = 0
        textBox.TextSize = 14
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.TextYAlignment = Enum.TextYAlignment.Top
        textBox.BackgroundTransparency = 1
        textBox.Font = Enum.Font.Code
        textBox.MultiLine = true
        textBox.ClearTextOnFocus = false
        textBox.Size = UDim2.new(1, 0, 1, 0)
        textBox.Position = UDim2.new(0, 25, 0, 0)
        textBox.Text = ""
        textBox.Parent = editor
        TextGradient:Skip(textBox)

        local layerSpecs = {
            { name = "Comments_",        zindex = 5, color = Color3.fromRGB(60, 201, 60) },
            { name = "Globals_",         zindex = 5, color = Color3.fromRGB(133, 215, 248) },
            { name = "Keywords_",        zindex = 5, color = Color3.fromRGB(249, 110, 125) },
            { name = "Numbers_",         zindex = 4, color = Color3.fromRGB(255, 199, 0) },
            { name = "RemoteHighlight_", zindex = 5, color = Color3.fromRGB(0, 145, 255) },
            { name = "Strings_",         zindex = 5, color = Color3.fromRGB(174, 242, 150) },
            { name = "Tokens_",          zindex = 5, color = Color3.fromRGB(255, 255, 255) },
        }
        for _, spec in ipairs(layerSpecs) do
            local l = Instance.new("TextLabel")
            l.Name = spec.name
            l.ZIndex = spec.zindex
            l.TextSize = 14
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextYAlignment = Enum.TextYAlignment.Top
            l.BackgroundTransparency = 1
            l.BorderSizePixel = 0
            l.Font = Enum.Font.Code
            l.TextColor3 = spec.color
            l.Size = UDim2.new(1, 0, 1, 0)
            l.Text = ""
            l.Parent = textBox
            TextGradient:Skip(l)
        end

        local function makeBtn(text, width, layoutOrder, iconId, onClick)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, width, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.LayoutOrder = layoutOrder
            btn.Parent = buttonsHolder
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 15, 0, 15)
            icon.ImageColor3 = Color3.fromRGB(101, 101, 101)
            icon.AnchorPoint = Vector2.new(0, 0.5)
            icon.Position = UDim2.new(0, 10, 0.5, 0)
            icon.Image = iconId
            icon.BackgroundTransparency = 1
            icon.Parent = btn

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -30, 1, 0)
            lbl.Position = UDim2.new(0, 28, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(101, 101, 101)
            lbl.Text = text
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.Parent = btn
            TextGradient:Skip(lbl)

            local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local hoverTween = TweenService:Create(btn, info, { BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
            local iconHover = TweenService:Create(icon, info, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
            local lblHover = TweenService:Create(lbl, info, { TextColor3 = Color3.fromRGB(255, 255, 255) })
            local normalTween = TweenService:Create(btn, info, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
            local iconNormal = TweenService:Create(icon, info, { ImageColor3 = Color3.fromRGB(100, 100, 100) })
            local lblNormal = TweenService:Create(lbl, info, { TextColor3 = Color3.fromRGB(100, 100, 100) })

            btn.MouseEnter:Connect(function() hoverTween:Play(); iconHover:Play(); lblHover:Play() end)
            btn.MouseLeave:Connect(function() normalTween:Play(); iconNormal:Play(); lblNormal:Play() end)
            btn.MouseButton1Click:Connect(function() pcall(onClick) end)
            return btn
        end

        makeBtn("复制", 76, 1, "rbxassetid://10709812159", function()
            local writer = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
            if writer then pcall(writer, textBox.Text) end
        end)
        makeBtn("清空", 76, 2, "rbxassetid://10709819059", function()
            textBox.Text = ""
        end)
        makeBtn("执行", 76, 3, "rbxassetid://10734923549", function()
            local code = textBox.Text
            if code ~= "" then
                local fn = loadstring(code)
                if fn then fn() end
            end
        end)

        local ACTIVE_BG = Color3.fromRGB(40, 40, 40)
        local INACTIVE_BG = Color3.fromRGB(30, 30, 30)
        local ACTIVE_TEXT = Color3.fromRGB(255, 255, 255)
        local INACTIVE_TEXT = Color3.fromRGB(100, 100, 100)

        local tabs = {}
        local activeTab = nil
        local createTabButton, setTabActiveStyle, activateTab, closeTab, createTab

        local function renumberTabs()
            for i, t in ipairs(tabs) do
                t.title = "Tab " .. i
                if t.button then
                    local titleLbl = t.button:FindFirstChild("tabtitle")
                    if titleLbl then titleLbl.Text = t.title end
                end
            end
        end

        createTabButton = function(tabData)
            local btn = Instance.new("Frame")
            btn.Name = "tab" .. (#tabs + 1)
            btn.BackgroundColor3 = INACTIVE_BG
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, 90, 0, 25)
            btn.LayoutOrder = #tabs + 1
            btn.ClipsDescendants = true
            btn.Parent = tabsFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

            local titleLbl = Instance.new("TextLabel")
            titleLbl.Name = "tabtitle"
            titleLbl.BorderSizePixel = 0
            titleLbl.TextSize = 14
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.BackgroundTransparency = 1
            titleLbl.Font = Enum.Font.Gotham
            titleLbl.TextColor3 = INACTIVE_TEXT
            titleLbl.Size = UDim2.new(0, 47, 0, 25)
            titleLbl.Text = tabData.title
            titleLbl.Position = UDim2.new(0, 10, 0, 0)
            titleLbl.Parent = btn
            TextGradient:Skip(titleLbl)

            local closeBtn = Instance.new("ImageButton")
            closeBtn.Name = "close"
            closeBtn.BorderSizePixel = 0
            closeBtn.BackgroundTransparency = 1
            closeBtn.ImageColor3 = INACTIVE_TEXT
            closeBtn.Image = "rbxassetid://10747384394"
            closeBtn.Size = UDim2.new(0, 15, 0, 15)
            closeBtn.Position = UDim2.new(0.76667, 0, 0.2, 0)
            closeBtn.Parent = btn

            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activateTab(tabData)
                end
            end)

            closeBtn.MouseButton1Click:Connect(function() closeTab(tabData) end)
            return btn
        end

        setTabActiveStyle = function(tabData, isActive)
            local btn = tabData.button
            if not btn then return end
            btn.BackgroundColor3 = isActive and ACTIVE_BG or INACTIVE_BG
            local titleLbl = btn:FindFirstChild("tabtitle")
            local closeBtn = btn:FindFirstChild("close")
            if titleLbl then titleLbl.TextColor3 = isActive and ACTIVE_TEXT or INACTIVE_TEXT end
            if closeBtn then closeBtn.ImageColor3 = isActive and ACTIVE_TEXT or INACTIVE_TEXT end
        end

        activateTab = function(tabData)
            if activeTab == tabData then return end
            if activeTab and textBox then activeTab.text = textBox.Text end
            for _, t in ipairs(tabs) do setTabActiveStyle(t, false) end
            activeTab = tabData
            setTabActiveStyle(tabData, true)
            if textBox then textBox.Text = tabData.text or "" end
        end

        closeTab = function(tabData)
            local idx
            for i, t in ipairs(tabs) do if t == tabData then idx = i break end end
            if not idx then return end
            if activeTab == tabData and textBox then tabData.text = textBox.Text end
            if tabData.button then tabData.button:Destroy() end
            table.remove(tabs, idx)
            if #tabs == 0 then
                activeTab = nil
                createTab()
                return
            end
            renumberTabs()
            if activeTab == tabData then
                activeTab = nil
                activateTab(tabs[math.min(idx, #tabs)])
            end
        end

        createTab = function()
            local tabData = { title = "Tab " .. (#tabs + 1), text = "" }
            tabData.button = createTabButton(tabData)
            table.insert(tabs, tabData)
            activateTab(tabData)
            return tabData
        end

        addTab.MouseButton1Click:Connect(function() createTab() end)
        createTab()

        local lua_keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
        local global_env = {"getrawmetatable", "game", "workspace", "script", "math", "string", "table", "print", "wait", "BrickColor", "Color3", "next", "pairs", "ipairs", "select", "unpack", "Instance", "Vector2", "Vector3", "CFrame", "Ray", "UDim2", "Enum", "assert", "error", "warn", "tick", "loadstring", "_G", "shared", "getfenv", "setfenv", "newproxy", "setmetatable", "getmetatable", "os", "debug", "pcall", "ypcall", "xpcall", "rawequal", "rawset", "rawget", "tonumber", "tostring", "type", "typeof", "_VERSION", "coroutine", "delay", "require", "spawn", "LoadLibrary", "settings", "stats", "time", "UserSettings", "version", "Axes", "ColorSequence", "Faces", "ColorSequenceKeypoint", "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "gcinfo", "elapsedTime", "collectgarbage", "PhysicalProperties", "Rect", "Region3", "Region3int16", "UDim", "Vector2int16", "Vector3int16"}

        local Source = textBox
        local Lines = lines
        local LineHighlight = lineHighlight
        local currentHighlightTween = nil
        local currentHighlightLine = -1

        local function updateLineHighlight()
            if not LineHighlight then return end
            local cursorPos = Source.CursorPosition
            if cursorPos < 0 then LineHighlight.Visible = false return end
            local text = Source.Text
            local textUpToCursor = text:sub(1, cursorPos)
            local lineNum = 1
            for _ in textUpToCursor:gmatch("\n") do lineNum = lineNum + 1 end
            if lineNum == currentHighlightLine then return end
            currentHighlightLine = lineNum

            local totalLines = 1
            for _ in text:gmatch("\n") do totalLines = totalLines + 1 end
            local lineHeight = 14
            if totalLines > 0 and Source.TextBounds.Y > 0 then
                lineHeight = Source.TextBounds.Y / totalLines
                if lineHeight < 1 then lineHeight = 14 end
            end
            local targetY = (lineNum - 1) * lineHeight

            if currentHighlightTween then currentHighlightTween:Cancel() end
            LineHighlight.Visible = true
            currentHighlightTween = TweenService:Create(LineHighlight, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, targetY), Size = UDim2.new(1, 0, 0, lineHeight) })
            currentHighlightTween:Play()
        end

        local function Highlight(string_, keywords)
            local K = {}
            local S = string_
            local Token = { ["="] = true, ["."] = true, [","] = true, ["("] = true, [")"] = true, ["["] = true, ["]"] = true, ["{"] = true, ["}"] = true, [":"] = true, ["*"] = true, ["/"] = true, ["+"] = true, ["-"] = true, ["%"] = true, [";"] = true, ["~"] = true }
            for i, v in pairs(keywords) do K[v] = true end
            S = S:gsub(".", function(c) if Token[c] ~= nil then return "\32" else return c end end)
            S = S:gsub("%S+", function(c) if K[c] ~= nil then return c else return (" "):rep(#c) end end)
            return S
        end

        local function hTokens(string_)
            local Token = { ["="] = true, ["."] = true, [","] = true, ["("] = true, [")"] = true, ["["] = true, ["]"] = true, ["{"] = true, ["}"] = true, [":"] = true, ["*"] = true, ["/"] = true, ["+"] = true, ["-"] = true, ["%"] = true, [";"] = true, ["~"] = true }
            local A = ""
            string_:gsub(".", function(c)
                if Token[c] ~= nil then A = A .. c
                elseif c == "\n" then A = A .. "\n"
                elseif c == "\t" then A = A .. "\t"
                else A = A .. "\32" end
            end)
            return A
        end

        local function strings(string_)
            local highlight = ""
            local quote = false
            string_:gsub(".", function(c)
                if quote == false and c == "\"" then quote = true
                elseif quote == true and c == "\"" then quote = false end
                if quote == false and c == "\"" then highlight = highlight .. "\""
                elseif c == "\n" then highlight = highlight .. "\n"
                elseif c == "\t" then highlight = highlight .. "\t"
                elseif quote == true then highlight = highlight .. c
                else highlight = highlight .. "\32" end
            end)
            return highlight
        end

        local function comments(string_)
            local ret = ""
            string_:gsub("[^\r\n]+", function(c)
                local comm = false
                local i = 0
                c:gsub(".", function(n)
                    i = i + 1
                    if c:sub(i, i + 1) == "--" then comm = true end
                    if comm == true then ret = ret .. n else ret = ret .. "\32" end
                end)
            end)
            return ret
        end

        local function numbers(string_)
            local A = ""
            string_:gsub(".", function(c)
                if tonumber(c) ~= nil then A = A .. c
                elseif c == "\n" then A = A .. "\n"
                elseif c == "\t" then A = A .. "\t"
                else A = A .. "\32" end
            end)
            return A
        end

        local function highlight_source(type_)
            if type_ == "Text" then
                Source.Text = Source.Text:gsub("\13", "")
                Source.Text = Source.Text:gsub("\t", "      ")
                local s = Source.Text
                if Source.Keywords_ then Source.Keywords_.Text = Highlight(s, lua_keywords) end
                if Source.Globals_ then Source.Globals_.Text = Highlight(s, global_env) end
                if Source.RemoteHighlight_ then Source.RemoteHighlight_.Text = Highlight(s, {"FireServer", "fireServer", "InvokeServer", "invokeServer"}) end
                if Source.Tokens_ then Source.Tokens_.Text = hTokens(s) end
                if Source.Numbers_ then Source.Numbers_.Text = numbers(s) end
                if Source.Strings_ then Source.Strings_.Text = strings(s) end
                local lin = 1
                s:gsub("\n", function() lin = lin + 1 end)
                Lines.Text = ""
                for i = 1, lin do Lines.Text = Lines.Text .. i .. "\n" end
            end
        end

        highlight_source("Text")
        updateLineHighlight()

        Source.Changed:Connect(function(prop)
            highlight_source(prop)
            if prop == "CursorPosition" or prop == "Text" then updateLineHighlight() end
        end)

        Source.TextEditable = true
        Source.MultiLine = true
        Source.TextWrapped = false
        editor.CanvasSize = UDim2.new(1, 0, 1, 0)
        Source.Size = UDim2.new(1, 0, 1, 0)

        local autoScrollV, autoScrollH = true, true
        local threshold = 25
        local currentTween = nil

        editor:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            local maxScrollY = editor.AbsoluteCanvasSize.Y - editor.AbsoluteSize.Y
            local maxScrollX = editor.AbsoluteCanvasSize.X - editor.AbsoluteSize.X
            if maxScrollY > 0 then autoScrollV = (editor.CanvasPosition.Y >= maxScrollY - threshold) end
            if maxScrollX > 0 then autoScrollH = (editor.CanvasPosition.X >= maxScrollX - threshold) end
        end)

        local function updateScrollAndSize()
            task.defer(function()
                if not Source.Parent then return end
                local cW, cH = editor.AbsoluteSize.X, editor.AbsoluteSize.Y
                local tW, tH = Source.TextBounds.X, Source.TextBounds.Y
                local nW = math.max(cW, tW + 20)
                local nH = math.max(cH, tH + 20)

                Source.Size = UDim2.new(0, nW, 0, nH)
                editor.CanvasSize = UDim2.new(0, nW, 0, nH)

                local targetX, targetY = nil, nil
                if autoScrollH and tW > cW then targetX = math.max(0, nW - cW) end
                if autoScrollV and tH > cH then targetY = math.max(0, nH - cH) end
                if targetX or targetY then
                    local newX = targetX or editor.CanvasPosition.X
                    local newY = targetY or editor.CanvasPosition.Y
                    if currentTween then currentTween:Cancel() end
                    currentTween = TweenService:Create(editor, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CanvasPosition = Vector2.new(newX, newY) })
                    currentTween:Play()
                end
            end)
        end

        Source:GetPropertyChangedSignal("Text"):Connect(updateScrollAndSize)
        Source:GetPropertyChangedSignal("TextBounds"):Connect(updateScrollAndSize)

        return {
            Frame = quickrun,
            TextBox = textBox,
            Execute = function()
                local code = textBox.Text
                if code ~= "" then
                    local fn = loadstring(code)
                    if fn then fn() end
                end
            end
        }
    end

    function Window:Console(config)
        config = config or {}
        local tabName = config.Name or "Console"
        local tabIcon = config.Icon or "rbxassetid://10734982144"
        local LogService = game:GetService("LogService")
        local TweenService = game:GetService("TweenService")

        local prevPending = Window._pendingCardContext
        local targetCard
        if config.Card == false then
            targetCard = nil
        else
            targetCard = config.Card or prevPending
            if not targetCard and CardMode then targetCard = Window._lastCard end
        end
        if targetCard then Window._pendingCardContext = targetCard end
        self:Tab(tabName, tabIcon)
        Window._pendingCardContext = prevPending

        local tabState = self._tabs[#self._tabs]
        local Page = tabState.page

        Page.ScrollingEnabled = false
        Page.ScrollBarThickness = 0
        local oldContent = Page:FindFirstChildWhichIsA("Frame")
        if oldContent then oldContent:Destroy() end

        local wrap = Instance.new("Frame")
        wrap.Name = "Console_Wrap"
        wrap.Size = UDim2.new(1, -16, 1, -16)
        wrap.Position = UDim2.new(0, 8, 0, 8)
        wrap.BackgroundTransparency = 1
        wrap.BorderSizePixel = 0
        wrap.ClipsDescendants = true
        wrap.Parent = Page

        local consoleHolder = Instance.new("Frame")
        consoleHolder.Name = "consoleholder"
        consoleHolder.Position = UDim2.new(0, 0, 0, 0)
        consoleHolder.Size = UDim2.new(1, 0, 1, 0)
        consoleHolder.BackgroundTransparency = 1
        consoleHolder.BorderSizePixel = 0
        consoleHolder.ClipsDescendants = true
        consoleHolder.Parent = wrap

        local hintLabel = Instance.new("TextLabel")
        hintLabel.Name = "Console_Hint"
        hintLabel.Size = UDim2.new(1, -20, 0, 14)
        hintLabel.Position = UDim2.new(0, 0, 0, 2)
        hintLabel.BackgroundTransparency = 1
        hintLabel.Font = Enum.Font.GothamMedium
        hintLabel.Text = "没有控制台输出"
        hintLabel.TextSize = 11
        hintLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
        hintLabel.TextXAlignment = Enum.TextXAlignment.Left
        hintLabel.ZIndex = 2
        hintLabel.Parent = consoleHolder
        TextGradient:Skip(hintLabel)

        local c = Instance.new("ScrollingFrame")
        c.Name = "c"
        c.Size = UDim2.new(1, 0, 1, -72)
        c.Position = UDim2.new(0, 0, 0, 22)
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.CanvasSize = UDim2.new(0, 0, 0, 0)
        c.ScrollBarThickness = 2
        c.ScrollBarImageColor3 = Color3.fromRGB(81, 81, 81)
        c.ScrollingDirection = Enum.ScrollingDirection.Y
        c.Parent = consoleHolder

        local logBox = Instance.new("TextBox")
        logBox.Name = "yesc"
        logBox.Size = UDim2.new(1, 0, 0, 0)
        logBox.Position = UDim2.new(0, 0, 0, 0)
        logBox.BackgroundTransparency = 1
        logBox.BorderSizePixel = 0
        logBox.TextEditable = false
        logBox.MultiLine = true
        logBox.RichText = true
        logBox.TextSize = 13
        logBox.Font = Enum.Font.Code
        logBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        logBox.TextXAlignment = Enum.TextXAlignment.Left
        logBox.TextYAlignment = Enum.TextYAlignment.Top
        logBox.TextWrapped = true
        logBox.ClearTextOnFocus = false
        logBox.PlaceholderText = ""
        logBox.Text = ""
        logBox.Parent = c
        TextGradient:Skip(logBox)

        local buttonsHolder = Instance.new("Frame")
        buttonsHolder.Name = "buttonsholder"
        buttonsHolder.Size = UDim2.new(1, 0, 0, 32)
        buttonsHolder.Position = UDim2.new(0, 0, 1, -32)
        buttonsHolder.BackgroundTransparency = 1
        buttonsHolder.Parent = consoleHolder

        local bl = Instance.new("UIListLayout")
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
        bl.VerticalAlignment = Enum.VerticalAlignment.Center
        bl.Padding = UDim.new(0, 6)
        bl.SortOrder = Enum.SortOrder.LayoutOrder
        bl.Parent = buttonsHolder

        local function makeConsoleBtn(text, iconId, width, layoutOrder, onClick)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, width, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.LayoutOrder = layoutOrder
            btn.Parent = buttonsHolder
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            local ic = Instance.new("ImageLabel")
            ic.Size = UDim2.new(0, 14, 0, 14)
            ic.Position = UDim2.new(0, 10, 0.5, 0)
            ic.AnchorPoint = Vector2.new(0, 0.5)
            ic.BackgroundTransparency = 1
            ic.Image = iconId
            ic.ImageColor3 = Color3.fromRGB(200, 200, 200)
            ic.ScaleType = Enum.ScaleType.Fit
            ic.ZIndex = 2
            ic.Parent = btn

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 1, 0)
            lbl.Position = UDim2.new(0, 28, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamMedium
            lbl.Text = text
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.ZIndex = 2
            lbl.Parent = btn
            TextGradient:Skip(lbl)

            local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local hoverTween  = TweenService:Create(btn, info, { BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
            local hoverIc     = TweenService:Create(ic,  info, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
            local hoverLb     = TweenService:Create(lbl, info, { TextColor3 = Color3.fromRGB(255, 255, 255) })
            local normalTween = TweenService:Create(btn, info, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
            local normalIc    = TweenService:Create(ic,  info, { ImageColor3 = Color3.fromRGB(200, 200, 200) })
            local normalLb    = TweenService:Create(lbl, info, { TextColor3 = Color3.fromRGB(200, 200, 200) })

            btn.MouseEnter:Connect(function() hoverTween:Play(); hoverIc:Play(); hoverLb:Play() end)
            btn.MouseLeave:Connect(function() normalTween:Play(); normalIc:Play(); normalLb:Play() end)
            btn.MouseButton1Click:Connect(function() pcall(onClick) end)
            return btn, ic, lbl
        end

        local sdOverlay = nil
        local sg = nil
        local cur = wrap
        while cur do
            if cur:IsA("ScreenGui") then sg = cur break end
            cur = cur.Parent
        end

        if sg then
            sdOverlay = Instance.new("Frame")
            sdOverlay.Name = "savedialog"
            sdOverlay.Size = UDim2.new(1, 0, 1, 0)
            sdOverlay.Position = UDim2.new(0, 0, 0, 0)
            sdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            sdOverlay.BackgroundTransparency = 0.2
            sdOverlay.BorderSizePixel = 0
            sdOverlay.Visible = false
            sdOverlay.ZIndex = 500
            sdOverlay.Active = true
            sdOverlay.Parent = sg

            local sdMain = Instance.new("Frame")
            sdMain.Name = "main"
            sdMain.AnchorPoint = Vector2.new(0.5, 0.5)
            sdMain.Position = UDim2.new(0.5, 0, 0.5, 0)
            sdMain.Size = UDim2.new(0, 274, 0, 126)
            sdMain.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
            sdMain.BorderSizePixel = 0
            sdMain.ZIndex = 501
            sdMain.Parent = sdOverlay
            Instance.new("UICorner", sdMain).CornerRadius = UDim.new(0, 10)

            local sdTitle = Instance.new("TextLabel")
            sdTitle.Name = "tit(s)"
            sdTitle.Size = UDim2.new(0, 200, 0, 30)
            sdTitle.Position = UDim2.new(0, 9, 0, 9)
            sdTitle.BackgroundTransparency = 1
            sdTitle.Font = Enum.Font.GothamMedium
            sdTitle.TextSize = 18
            sdTitle.Text = "保存到工作区"
            sdTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            sdTitle.TextXAlignment = Enum.TextXAlignment.Left
            sdTitle.TextYAlignment = Enum.TextYAlignment.Top
            sdTitle.ZIndex = 502
            sdTitle.Parent = sdMain
            TextGradient:Skip(sdTitle)

            local sdDesc = Instance.new("TextLabel")
            sdDesc.Name = "desc"
            sdDesc.Size = UDim2.new(0, 258, 0, 30)
            sdDesc.Position = UDim2.new(0, 9, 0, 30)
            sdDesc.BackgroundTransparency = 1
            sdDesc.Font = Enum.Font.Gotham
            sdDesc.TextSize = 13
            sdDesc.Text = "将在执行器工作区文件夹中保存一个文件"
            sdDesc.TextColor3 = Color3.fromRGB(160, 160, 160)
            sdDesc.TextXAlignment = Enum.TextXAlignment.Left
            sdDesc.TextYAlignment = Enum.TextYAlignment.Top
            sdDesc.TextWrapped = true
            sdDesc.ZIndex = 502
            sdDesc.Parent = sdMain
            TextGradient:Skip(sdDesc)

            local sdClose = Instance.new("ImageButton")
            sdClose.Name = "close"
            sdClose.Size = UDim2.new(0, 20, 0, 20)
            sdClose.Position = UDim2.new(1, -32, 0, 14)
            sdClose.BackgroundTransparency = 1
            sdClose.Image = "rbxassetid://10747384394"
            sdClose.BorderSizePixel = 0
            sdClose.ZIndex = 502
            sdClose.Parent = sdMain
            sdClose.MouseButton1Click:Connect(function()
                sdOverlay.Visible = false
            end)

            local sdInput = Instance.new("TextBox")
            sdInput.Name = "TextBox"
            sdInput.AnchorPoint = Vector2.new(0.5, 0)
            sdInput.Position = UDim2.new(0.5, 0, 0, 66)
            sdInput.Size = UDim2.new(0, 253, 0, 26)
            sdInput.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
            sdInput.BorderSizePixel = 0
            sdInput.Font = Enum.Font.Gotham
            sdInput.TextSize = 13
            sdInput.Text = ""
            sdInput.PlaceholderText = "例如：风御牛逼.txt"
            sdInput.PlaceholderColor3 = Color3.fromRGB(101, 101, 101)
            sdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
            sdInput.TextWrapped = true
            sdInput.TextXAlignment = Enum.TextXAlignment.Left
            sdInput.ClearTextOnFocus = false
            sdInput.ZIndex = 502
            sdInput.Parent = sdMain
            Instance.new("UICorner", sdInput).CornerRadius = UDim.new(0, 6)
            local sdPad = Instance.new("UIPadding")
            sdPad.PaddingLeft = UDim.new(0, 8)
            sdPad.Parent = sdInput
            TextGradient:Skip(sdInput)

            local sdDone = Instance.new("TextButton")
            sdDone.Name = "save"
            sdDone.Size = UDim2.new(0, 72, 0, 28)
            sdDone.Position = UDim2.new(1, -34, 1, -34)
            sdDone.AnchorPoint = Vector2.new(1, 0)
            sdDone.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            sdDone.Text = ""
            sdDone.AutoButtonColor = false
            sdDone.BorderSizePixel = 0
            sdDone.ZIndex = 502
            sdDone.Parent = sdMain
            Instance.new("UICorner", sdDone).CornerRadius = UDim.new(0, 8)

            local sdDoneIcon = Instance.new("ImageLabel")
            sdDoneIcon.Size = UDim2.new(0, 14, 0, 14)
            sdDoneIcon.Position = UDim2.new(0, 10, 0.5, 0)
            sdDoneIcon.AnchorPoint = Vector2.new(0, 0.5)
            sdDoneIcon.BackgroundTransparency = 1
            sdDoneIcon.Image = "rbxassetid://10709790644"
            sdDoneIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            sdDoneIcon.ScaleType = Enum.ScaleType.Fit
            sdDoneIcon.ZIndex = 2
            sdDoneIcon.Parent = sdDone

            local sdDoneLbl = Instance.new("TextLabel")
            sdDoneLbl.Size = UDim2.new(1, -32, 1, 0)
            sdDoneLbl.Position = UDim2.new(0, 28, 0, 0)
            sdDoneLbl.BackgroundTransparency = 1
            sdDoneLbl.Font = Enum.Font.GothamMedium
            sdDoneLbl.Text = "完成"
            sdDoneLbl.TextSize = 13
            sdDoneLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            sdDoneLbl.TextXAlignment = Enum.TextXAlignment.Center
            sdDoneLbl.TextYAlignment = Enum.TextYAlignment.Center
            sdDoneLbl.ZIndex = 2
            sdDoneLbl.Parent = sdDone
            TextGradient:Skip(sdDoneLbl)

            local sdInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local sdHover   = TweenService:Create(sdDone, sdInfo, { BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
            local sdHoverI  = TweenService:Create(sdDoneIcon, sdInfo, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
            local sdHoverL  = TweenService:Create(sdDoneLbl, sdInfo, { TextColor3 = Color3.fromRGB(255, 255, 255) })
            local sdNormal  = TweenService:Create(sdDone, sdInfo, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
            local sdNormalI = TweenService:Create(sdDoneIcon, sdInfo, { ImageColor3 = Color3.fromRGB(200, 200, 200) })
            local sdNormalL = TweenService:Create(sdDoneLbl, sdInfo, { TextColor3 = Color3.fromRGB(200, 200, 200) })
            sdDone.MouseEnter:Connect(function() sdHover:Play(); sdHoverI:Play(); sdHoverL:Play() end)
            sdDone.MouseLeave:Connect(function() sdNormal:Play(); sdNormalI:Play(); sdNormalL:Play() end)

            sdDone.MouseButton1Click:Connect(function()
                local name = sdInput.Text
                local raw = logBox.Text
                if raw == "" then return end
                local clean = raw:gsub("<[^>]->", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
                if type(writefile) == "function" then
                    pcall(writefile, name, clean)
                end
                sdInput.Text = ""
                sdOverlay.Visible = false
            end)

            local visConn
            visConn = Page:GetPropertyChangedSignal("Visible"):Connect(function()
                if not Page.Visible then sdOverlay.Visible = false end
            end)
            wrap.Destroying:Connect(function()
                if visConn then visConn:Disconnect() end
                if sdOverlay then sdOverlay:Destroy() end
            end)
        end

        makeConsoleBtn("清空", "rbxassetid://10709819059", 76, 1, function()
            logBox.Text = ""
            c.CanvasSize = UDim2.new(0, 0, 0, 0)
            logBox.Size = UDim2.new(1, 0, 0, 0)
        end)

        makeConsoleBtn("保存", "rbxassetid://10734941499", 76, 2, function()
            if sdOverlay then sdOverlay.Visible = true end
        end)

        makeConsoleBtn("复制", "rbxassetid://10709812159", 76, 3, function()
            local raw = logBox.Text
            if raw == "" then return end
            local clean = raw:gsub("<[^>]->", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
            local writer = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
            if writer then pcall(writer, clean) end
        end)

        local autoScroll = true
        local isTweening = false
        local currentTween = nil

        local colors = {
            [Enum.MessageType.MessageOutput]  = "FFFFFF",
            [Enum.MessageType.MessageInfo]    = "FFFFFF",
            [Enum.MessageType.MessageWarning] = "FFFF00",
            [Enum.MessageType.MessageError]   = "FF0000",
        }

        local scrollPosConn = c:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if isTweening then return end
            local max = c.CanvasSize.Y.Offset - c.AbsoluteWindowSize.Y
            if max > 0 then
                autoScroll = (c.CanvasPosition.Y >= max - 15)
            end
        end)

        local boundsConn = logBox:GetPropertyChangedSignal("TextBounds"):Connect(function()
            local maxY = logBox.TextBounds.Y
            c.CanvasSize = UDim2.new(0, 0, 0, maxY)
            logBox.Size = UDim2.new(1, 0, 0, maxY)
            if autoScroll then
                local targetY = math.max(0, maxY - c.AbsoluteWindowSize.Y)
                if currentTween then currentTween:Cancel() end
                isTweening = true
                currentTween = TweenService:Create(c, TweenInfo.new(0.15, Enum.EasingStyle.Sine),
                    { CanvasPosition = Vector2.new(0, targetY) })
                local tw = currentTween
                tw.Completed:Once(function()
                    if currentTween == tw then isTweening = false end
                end)
                tw:Play()
            end
        end)

        local logConn = LogService.MessageOut:Connect(function(msg, msgType)
            local hex = colors[msgType] or "FFFFFF"
            local t = tick()
            local stamp = string.format("[%s.%03d]",
                os.date("%H:%M:%S", t),
                math.floor((t % 1) * 1000))
            msg = msg:gsub("<", "&lt;"):gsub(">", "&gt;")
            logBox.Text = logBox.Text .. string.format('<font color="#%s">%s %s</font>\n', hex, stamp, msg)
        end)

        local function updateHint()
            hintLabel.Visible = (logBox.Text == "")
        end
        local hintConn = logBox:GetPropertyChangedSignal("Text"):Connect(updateHint)
        updateHint()

        wrap.Destroying:Connect(function()
            if logConn then logConn:Disconnect() end
            if boundsConn then boundsConn:Disconnect() end
            if scrollPosConn then scrollPosConn:Disconnect() end
            if hintConn then hintConn:Disconnect() end
            if currentTween then currentTween:Cancel() end
        end)

        return {
            Frame = wrap,
            LogBox = logBox,
            Clear = function() logBox.Text = "" end,
            GetLogText = function() return logBox.Text end
        }
    end

    function Window:Dialog(Config)
        Config = Config or {}
        local Dialog = {Closed = false}
        local Overlay = Instance.new("Frame")
        local Panel = Instance.new("Frame")
        local UICorner = Instance.new("UICorner")
        local UIStroke = Instance.new("UIStroke")
        local DTitle = Instance.new("TextLabel")
        local Content = Instance.new("TextLabel")
        local Divider = Instance.new("Frame")
        local ButtonHolder = Instance.new("Frame")
        local ButtonLayout = Instance.new("UIListLayout")
        Overlay.Parent = MainFrame
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Size = UDim2.fromScale(1, 1); Overlay.ZIndex = 180
        Overlay.Active = true
        Panel.Parent = Overlay
        Panel.AnchorPoint = Vector2.new(0.5, 0.5)
        Panel.Position = UDim2.fromScale(0.5, 0.5)
        Panel.BackgroundColor3 = Color3.fromRGB(13, 17, 22)
        Panel.BackgroundTransparency = 1
        Panel.ClipsDescendants = true
        Panel.Size = UDim2.new(0, 365, 0, 188)
        Panel.ZIndex = 181
        UICorner.CornerRadius = UDim.new(0, 12); UICorner.Parent = Panel
        UIStroke.Transparency = 1
        UIStroke.Color = Color3.fromRGB(45, 48, 58); UIStroke.Parent = Panel
        DTitle.Parent = Panel
        DTitle.BackgroundTransparency = 1
        DTitle.Position = UDim2.new(0, 18, 0, 18)
        DTitle.Size = UDim2.new(1, -36, 0, 21)
        DTitle.ZIndex = 183
        DTitle.Font = Enum.Font.GothamBold
        DTitle.Text = Config.Title or "提示"
        DTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        DTitle.TextTransparency = 1
        DTitle.TextXAlignment = Enum.TextXAlignment.Left
        AddToRegistry(DTitle, "TextColor3", "Text")
        Content.Parent = Panel
        Content.BackgroundTransparency = 1
        Content.Position = UDim2.new(0, 18, 0, 48)
        Content.Size = UDim2.new(1, -36, 0, 76)
        Content.ZIndex = 183
        Content.Font = Enum.Font.GothamMedium
        Content.Text = Config.Content or ""
        Content.TextColor3 = Color3.fromRGB(255, 255, 255)
        Content.TextTransparency = 1
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        AddToRegistry(Content, "TextColor3", "Text")
        Divider.Parent = Panel
        Divider.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
        Divider.BackgroundTransparency = 1
        Divider.Position = UDim2.new(0, 14, 1, -54)
        Divider.Size = UDim2.new(1, -28, 0, 1)
        Divider.ZIndex = 182
        AddToRegistry(Divider, "BackgroundColor3", "Stroke")
        ButtonHolder.Parent = Panel
        ButtonHolder.AnchorPoint = Vector2.new(1, 1)
        ButtonHolder.BackgroundTransparency = 1
        ButtonHolder.Position = UDim2.new(1, -16, 1, -14)
        ButtonHolder.Size = UDim2.new(1, -32, 0, 32)
        ButtonHolder.ZIndex = 182
        ButtonLayout.Parent = ButtonHolder
        ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
        ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        ButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ButtonLayout.Padding = UDim.new(0, 8)
        function Dialog:Close(Result)
            if Dialog.Closed then return Result end
            Dialog.Closed = true
            Tween(Overlay, {BackgroundTransparency = 1}, 0.15)
            Tween(Panel, {BackgroundTransparency = 1, Size = UDim2.new(0, 365, 0, 188)}, 0.15)
            task.delay(0.2, function() Overlay:Destroy() end)
            pcall(Config.Callback, Result)
            return Result
        end
        local function AddDialogButton(Text, Primary, Callback)
            local Button = Instance.new("Frame")
            Button.Parent = ButtonHolder
            Button.BackgroundColor3 = Primary and CurrentTheme.Accent or Color3.fromRGB(26, 28, 36)
            Button.BackgroundTransparency = 1
            Button.ClipsDescendants = true
            Button.Size = UDim2.new(0, math.max(78, TextService:GetTextSize(Text, 12, Enum.Font.GothamBold, Vector2.new(math.huge, math.huge)).X + 32), 0, 32)
            Button.ZIndex = 183
            Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)
            local Stroke = Instance.new("UIStroke")
            Stroke.Transparency = 1
            Stroke.Color = Primary and CurrentTheme.Accent or Color3.fromRGB(45, 48, 58)
            Stroke.Parent = Button
            local Label = Instance.new("TextLabel")
            Label.Parent = Button
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.fromScale(1, 1)
            Label.ZIndex = 184
            Label.Font = Primary and Enum.Font.GothamBold or Enum.Font.GothamMedium
            Label.Text = Text
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextSize = 12
            Label.TextTransparency = 1
            AddToRegistry(Label, "TextColor3", "Text")
            local Input = Instance.new("TextButton")
            Input.Size = UDim2.fromScale(1, 1)
            Input.BackgroundTransparency = 1; Input.Text = ""
            Input.Parent = Button
            Input.MouseButton1Click:Connect(function()
                local Result = Callback and Callback() or Text
                Dialog:Close(Result)
            end)
            Input.MouseEnter:Connect(function() Tween(Button, {BackgroundTransparency = Primary and 0 or 0.08}, 0.15) end)
            Input.MouseLeave:Connect(function() Tween(Button, {BackgroundTransparency = Primary and 0.1 or 0.25}, 0.15) end)
            Tween(Button, {BackgroundTransparency = Primary and 0.1 or 0.25}, 0.1)
            Tween(Stroke, {Transparency = Primary and 1 or 0.65}, 0.1)
            Tween(Label, {TextTransparency = 0}, 0.1)
        end
        for _, BtnConfig in ipairs(Config.Buttons or {{Text = "确定", Primary = true}}) do
            AddDialogButton(BtnConfig.Text, BtnConfig.Primary, BtnConfig.Callback)
        end
        Tween(Overlay, {BackgroundTransparency = 0.28}, 0.25)
        Tween(Panel, {BackgroundTransparency = 0.025, Size = UDim2.new(0, 392, 0, 200)}, 0.25)
        Tween(UIStroke, {Transparency = 0.65}, 0.25)
        Tween(DTitle, {TextTransparency = 0}, 0.25)
        Tween(Content, {TextTransparency = 0.25}, 0.25)
        Tween(Divider, {BackgroundTransparency = 0.72}, 0.25)
        return Dialog
    end

    function Window:Notify(Config)
        if type(Config) == "string" then
            Config = { Content = Config }
        end
        Config = Config or {}
        return Notifier.new(Config)
    end

    function Window:SetKeybind(key)
        if type(key) == "string" then
            key = Enum.KeyCode[key] or key
        end
        Keybind = key
    end
    function Window:Destroy()
        for _, fn in ipairs(Window._homeCleanup or {}) do pcall(fn) end
        Window._homeCleanup = nil
        for k in pairs(EffectConns) do pcall(StopEffect, k) end
        ScreenGui:Destroy()
    end
    function Window:SetSubtitle(newSubtitle) WindowContent.Text = newSubtitle or "" end

    function Window:SetAccount(cfg)
        cfg = cfg or {}
        if cfg.ShowUser == false then
            AccountProfile.Image = ""
            AccountProfile.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            AccountProfile.BackgroundTransparency = 0.25
            AccountProfile.ImageColor3 = CurrentTheme.Accent
            AccountName.Text = cfg.Expires  or "自定义菜单"
            ExpireLabel.Text = cfg.Username or "设置"
            if Window._userCard then
                Window._userCard:SetValue(1, cfg.Expires  or "自定义菜单")
                Window._userCard:SetValue(2, cfg.Username or "设置")
            end
        else
            AccountProfile.Image = cfg.Profile
                or Players:GetUserThumbnailAsync(LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            AccountProfile.BackgroundColor3 = Color3.new(1, 1, 1)
            AccountProfile.BackgroundTransparency = 1
            AccountName.Text = cfg.Expires  or LocalPlayer.DisplayName
            ExpireLabel.Text = cfg.Username or LocalPlayer.Name
            if Window._userCard then
                Window._userCard:SetValue(1, cfg.Expires  or LocalPlayer.DisplayName)
                Window._userCard:SetValue(2, cfg.Username or LocalPlayer.Name)
                if cfg.Profile then Window._userCard:SetProfile(cfg.Profile) end
            end
        end
    end
    Window:SetAccount({ ShowUser = (Config.ShowUser ~= false) })

    if CardMode and PageService and HomePage then
        task.spawn(function()
            repeat task.wait() until MainFrame.Visible
            task.wait(0.15)
            pcall(function() PageService:JumpTo(HomePage) end)
            if Window._setHomeLayout then Window._setHomeLayout(true) end
        end)
    end

    Window._pendingCardContext = nil
    Window._cardMode = CardMode
    return Window
end

do
    local cursorScreen = Instance.new("ScreenGui")
    cursorScreen.Name = "FengCustomCursor"
    cursorScreen.IgnoreGuiInset = true
    cursorScreen.DisplayOrder = 2147483647
    cursorScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    cursorScreen.ResetOnSpawn = false
    cursorScreen.Enabled = false
    cursorScreen.Parent = CoreGui
    local cursorRoot = Instance.new("Frame")
    cursorRoot.BackgroundTransparency = 1
    cursorRoot.Size = UDim2.new(0, 20, 0, 20)
    cursorRoot.ZIndex = 2147483647
    cursorRoot.Visible = false
    cursorRoot.Parent = cursorScreen
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(1, 0, 1, 0)
    img.Image = "rbxassetid://132511743665753"
    img.ImageColor3 = Color3.fromRGB(90, 165, 255)
    img.ScaleType = Enum.ScaleType.Fit
    img.Rotation = -90
    img.Parent = cursorRoot
    local cursorConn = RunService.RenderStepped:Connect(function()
        if not cursorRoot.Visible then return end
        local loc = UserInputService:GetMouseLocation()
        cursorRoot.Position = UDim2.new(0, loc.X - 2, 0, loc.Y - 2)
    end)
    FengUI._cursorObjects = { Screen = cursorScreen, Root = cursorRoot, Image = img, Connection = cursorConn, Enabled = false }
    function FengUI:SetCustomCursor(enabled)
        enabled = enabled == true
        if FengUI._cursorObjects then
            FengUI._cursorObjects.Root.Visible = enabled
            FengUI._cursorObjects.Screen.Enabled = enabled
            FengUI._cursorObjects.Enabled = enabled
            pcall(function() UserInputService.MouseIconEnabled = not enabled end)
        end
    end
    function FengUI:ToggleCustomCursor()
        local current = FengUI._cursorObjects and FengUI._cursorObjects.Enabled or false
        FengUI:SetCustomCursor(not current)
    end
    function FengUI:CleanupCursor()
        if FengUI._cursorObjects then
            safeDisconnect(FengUI._cursorObjects.Connection)
            if FengUI._cursorObjects.Screen then FengUI._cursorObjects.Screen:Destroy() end
            FengUI._cursorObjects = nil
        end
    end
end

return FengUI