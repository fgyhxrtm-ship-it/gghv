local success, library = pcall(function()
    return loadstring(game:HttpGet("UI"))()
end)

if not success then
    print("欢迎使用")  
    return
end

local Window = library:CreateWindow({
    Name = "殺脚本",
    SubName = "内部测试",
    Keybind = Enum.KeyCode.RightShift,
    Logo = 93541172717831,
    Scene = 000,
    Theme = "Dark"
})

Window.CurrentConfig = "None"

Window:Category({
    Name = "殺脚本功能列表",
    Collapsible = true,
    Opened = true, 
})
Window:TabDivider()

Window:CreateHomeTab({
    Name = "仪表盘",
    Logo = "84830962019412",
    DiscordInvite = "",
      SupportedExecutors = { "Delta", "Synapse X", "Krnl", "Codex", "Arceus X" },
      UnsupportedExecutors = { "Roblox Studio" },
      Segments = {
          Details = { Text = "你的信息", Icon = "no" },
          Script = { Text = "更新日志", Icon = "no" },
      },
    Changelog = {
        {
            Title = "版本",
            Description = "你好",
        },
    },
})

local FengYu = Window:Tab("基础测试", "84830962019412")

local Feng = FengYu:Section({
    Name = "标题",
    SubName = "副标题",
    Logo = "84830962019412",
    Collapsible = true,
    Collapsed = true,
    Locked = false,
    TextLocked = "未解锁",
})

Feng:Image({
    Name = "标签",
    SubName = "副标签",
    Description = {"标签一", "标签二", "标签三"},
    Icon = "rbxassetid://84830962019412",
    IconColor = Color3.fromRGB(255, 255, 255),
    StrokeColor = Color3.fromRGB(85, 255, 0),
    Callback = function()
        print("图片项被点击了！")
        Window:Notification("提示", "你点击了 Shadow", "Info", 2)
    end
})

Feng:Social({
    Name = "你好",
    SubName = "风御 X",
    SmlName = "快手",
    copy = "风御", -- 必填
    Cbn = "复制",
    Logo = "rbxassetid://84830962019412"
})

Feng:CodeBlock({
    Name = "殺脚本源码",
    Code = [[
Feng:Button({
    Name = "按钮",
    Callback = function()
        print("按钮点击")
    end
})

Feng:Toggle({
    Name = "开关",
    Value = true,
    Callback = function(state)
        print("自动执行:", state)
    end
})

Feng:Slider({
    Name = "滑块",
    Value = {
        Min = 1,
        Max = 100,
        Default = 50,
    },
    Callback = function(value) 
        print("速度:", value)
    end
})
]],
    Copy = true,
    RichText = false,
})

local FengYu = Window:Tab("播放测试", "84830962019412")

local Feng = FengYu:Section({
    Name = "全新的播放功能",
    Logo = "84830962019412",
    open = true
})

Feng:Video({
    Video = "rbxassetid://5608337069",
    Name = "视频哦",
    AutoPlay = true,
    Looped = true,
    Volume = 0.5,
    AspectRatio = "16:9",
    Radius = 8,
})

local Feng = FengYu:Section({
    Name = "全部新的音频播放功能",
    Logo = "84830962019412",
    open = true
})

Feng:Audio({
    Name = "音频测试",
    SubName = "副标签",
    Audio = "rbxassetid://122343512566988",
    Volume = 0.8,
    Looped = true,
    AutoPlay = false,
    PlayOutsideWindow = false
})

local FengYu = Window:Tab("视口测试", "84830962019412")

local Feng = FengYu:Section({
    Name = "3D块使用方法",
    Logo = "84830962019412",
    open = true
})

local demoModel = Instance.new("Part")
demoModel.Shape = Enum.PartType.Ball
demoModel.Size = Vector3.new(4, 4, 4)
demoModel.BrickColor = BrickColor.new("Bright blue")
demoModel.Material = Enum.Material.Neon
demoModel.CFrame = CFrame.new(0, 0, 0)
demoModel.Anchored = true
demoModel.Parent = workspace
local vpCamera = Instance.new("Camera")
vpCamera.CFrame = CFrame.new(Vector3.new(0, 3, 10), Vector3.new(0, 0, 0))

local vp = Feng:Viewport({
    Height = 200,
    AspectRatio = "16:9",
    Object = demoModel,
    Camera = vpCamera,
    Focused = true,
    Interactive = true,
})

Feng:Button({
    Name = "换成红色圆柱体",
    Icon = "solar/refresh-bold",
    Callback = function()
        local np = Instance.new("Part")
        np.Shape = Enum.PartType.Cylinder
        np.Size = Vector3.new(6, 3, 3)
        np.BrickColor = BrickColor.new("Bright red")
        np.Material = Enum.Material.SmoothPlastic
        np.Anchored = true
        np.Parent = workspace
        vp:SetObject(np, false)
        vp:Focus()
        Window:Notification("3D窗口", "对象已替换", "Info", 2)
    end,
})

local FengYu = Window:Tab("按钮", "84830962019412")

local Feng = FengYu:Section({
    Name = "按钮使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Button({
    Name = "按钮",
    Callback = function()
        print("按钮点击")
    end
})

Feng:Button({
    Name = "按钮",
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function()
        print("按钮点击")
    end
})

local FengYu = Window:Tab("开关", "84830962019412")

local Feng = FengYu:Section({
    Name = "开关使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Toggle({
    Name = "开关",
    Value = true,
    Callback = function(state)
        print("开关执行:", state)
    end
})

Feng:Checkbox({
    Name = "复选框",
    Default = true,
    Callback = function(val)
        print("复选框值:", val)
    end
})

Feng:Toggle({
    Name = "开关",
    Locked = true,
    LockedTitle = "已锁定",
    Value = true,
    Callback = function(state)
        print("开关执行:", state)
    end
})

Feng:Checkbox({
    Name = "复选框",
    Default = true,
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(val)
        print("复选框值:", val)
    end
})

local FengYu = Window:Tab("子分类", "84830962019412")

local Feng = FengYu:Section({
    Name = "标题",
    SubName = "副标题",
    Logo = "84830962019412",
    Collapsible = true,
    Collapsed = true,
    { 
        Key = "ESP",
        Name = "ESP",
        Icon = "rbxassetid://1"
    },
    { 
        Key = "Camera",
        Name = "Camera",
        Icon = "rbxassetid://84830962019412" 
    },
    { 
        Key = "Lighting",
        Name = "Lighting",
        Icon = "rbxassetid://3" 
    },
})

Feng.ESP:Button({
    Name = "按钮",
    Callback = function()
        print("按钮点击")
    end
})

Feng.ESP:Button({
    Name = "按钮",
    Callback = function()
        print("按钮点击")
    end
})

Feng.ESP:Button({
    Name = "按钮",
    Callback = function()
        print("按钮点击")
    end
})

Feng.Camera:Toggle({
    Name = "开关",
    Value = true,
    Callback = function(state)
        print("开关执行:", state)
    end
})

Feng.Camera:Toggle({
    Name = "开关",
    Value = true,
    Callback = function(state)
        print("开关执行:", state)
    end
})

Feng.Lighting:Slider({
    Name = "滑块",
    Value = {
        Min = 1,
        Max = 100,
        Default = 50,
    },
    Callback = function(value) 
        print("速度:", value)
    end
})

local FengYu = Window:Tab("进度条", "84830962019412")

local Feng = FengYu:Section({
    Name = "进度条使用方法",
    Logo = "84830962019412",
    open = true
})

local pb = Feng:ProgressBar({
    Name = "进度条",
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    ShowPercent = true,
    Callback = function(val)
        print("当前进度:", val)
    end
})

Feng:Button({
    Name = "增加 10",
    Callback = function()
        local newVal = math.min(pb.Value + 10, pb.Max)
        pb:SetValue(newVal)
    end
})

Feng:Button({
    Name = "减少 10",
    Callback = function()
        local newVal = math.max(pb.Value - 10, pb.Min)
        pb:SetValue(newVal)
    end
})

Feng:Button({
    Name = "重置为 50",
    Callback = function()
        pb:SetValue(50)
    end
})

local FengYu = Window:Tab("滑块", "84830962019412")

local Feng = FengYu:Section({
    Name = "滑块使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Slider({
    Name = "滑块",
    Value = {
        Min = 1,
        Max = 100,
        Default = 50,
    },
    Callback = function(value) 
        print("速度:", value)
    end
})

Feng:Slider({
    Name = "小数点.滑块",
    Value = {
        Min = 1,
        Max = 100,
        Default = 50,
    },
    Rounding = 1, --支持两个
    Callback = function(value) 
        print("速度:", value)
    end
})

Feng:Slider({
    Name = "滑块",
    Value = {
        Min = 1,
        Max = 100,
        Default = 50,
    },
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(value) 
        print("速度:", value)
    end
})

local FengYu = Window:Tab("下拉式", "84830962019412")

local Feng = FengYu:Section({
    Name = "下拉式使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Dropdown({
    Name = "下拉式",
    Values = { 
        "A", 
        "B", 
        "C", 
        "D" 
    },
    Value = "A", 
    Multi = false,
    Callback = function(choose)
        print("已选择:", choose)
    end
})

Feng:Dropdown({
    Name = "下拉式.多选",
    Values = { 
        "A", 
        "B", 
        "C", 
        "D" 
    },
    Value = { 
        "A", 
        "C" 
    },
    Multi = true,
    Callback = function(val)
        print("已选择:", table.concat(val, ", "))
    end
})

Feng:Dropdown({
    Name = "下拉式",
    Values = { 
        "A", 
        "B", 
        "C", 
        "D" 
    },
    Value = "A", 
    Multi = false,
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(choose)
        print("已选择:", choose)
    end
})

local FengYu = Window:Tab("输入框", "84830962019412")

local Feng = FengYu:Section({
    Name = "输入框使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Textbox({
    Name = "输入名称",
    Placeholder = "请输入...",
    Callback = function(text)
        print("输入:", text)
    end
})

Feng:Input({
    Name = "输入",
    Value = "默认值",
    Placeholder = "输入...",
    Finished = true,
    Numeric = false,
    MaxLength = 20,
    Callback = function(val) 
        print("输入完成:", val) 
    end
})

Feng:Textbox({
    Name = "输入名称",
    Placeholder = "请输入...",
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(text)
        print("输入:", text)
    end
})

Feng:Input({
    Name = "输入",
    Value = "默认值",
    Placeholder = "输入...",
    Finished = true,
    Numeric = false,
    MaxLength = 20,
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(val) 
        print("输入完成:", val) 
    end
})

local FengYu = Window:Tab("标签", "84830962019412")

local Feng = FengYu:Section({
    Name = "标签使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Label({
    Name = "这是一个普通标签"
})

Feng:Paragraph({
    Name = "再普通不过的标签",
    Content = "标签1 \n 标签2 \n 标签3 \n 标签4"
})

Feng:Space({ Height = 20 })

Feng:Paragraph({
    Name = "<font color='#ff6666'>★ 彩色标题</font>",
    Content = "支持 <b>加粗</b>、<i>斜体</i> 和 <font color='#66ff66'>颜色</font>。"
})

Feng:Divider({ Name = "分隔线" })
Feng:Divider()

local FengYu = Window:Tab("按键绑定", "84830962019412")

local Feng = FengYu:Section({
    Name = "按键绑定使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Keybind({
    Name = "按键绑定",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Callback = function(state)
        print("Keybind state:", state)
    end
})

Feng:Keybind({
    Name = "按键绑定",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Locked = true,
    LockedTitle = "已锁定",
    Callback = function(state)
        print("Keybind state:", state)
    end
})

local FengYu = Window:Tab("颜色选择器", "84830962019412")

local Feng = FengYu:Section({
    Name = "颜色选择器使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Colorpicker({
    Name = "颜色选择器",
    Default = Color3.fromRGB(80, 140, 255),
    Transparency = 0.2,
    Callback = function(color, transparency)
        print("新颜色:", color:ToHex(), "透明度:", transparency)
    end
})

local FengYu = Window:Tab("通知", "84830962019412")

local Feng = FengYu:Section({
    Name = "通知使用方法",
    Logo = "84830962019412",
    open = true
})

Feng:Button({
    Name = "通知",
    Callback = function()
        Window:Notify({
            Name = "通知",
            Content = "通知通知通知通知通知通知通知通知通知",
            Icon = 84830962019412,
        })
    end
})
