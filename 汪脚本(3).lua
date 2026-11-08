-- This file has been deobfuscated using Hurricane https://discord.com/invite/AbeurBzKXe

local lib = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local localPlayer = game:GetService("Players").LocalPlayer
local userId = localPlayer.UserId
local str = "script_count_" .. userId .. ".txt"
local n = 0

if pcall(function()
	return readfile(str)
end) then
	local v = readfile(str)
	n = tonumber(v) or 0
end

local n2 = n + 1

pcall(function()
	writefile(str, tostring(n2))
end)

kbTadaAsset = nil

task.spawn(function()
	local ok, result = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/TADA.WAV")
	end)

	if ok and result then
		pcall(function()
			if makefolder and not isfolder("汪脚本") then
				makefolder("汪脚本")
			end

			writefile("汪脚本/TADA.WAV", result)
		end)

		local ok2, result2 = pcall(function()
			return getcustomasset("汪脚本/TADA.WAV")
		end)

		if ok2 and result2 then
			kbTadaAsset = result2
		end
	end
end)

kbDingAsset = nil

task.spawn(function()
	local ok, result = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/DING.WAV")
	end)

	if ok and result then
		pcall(function()
			if makefolder and not isfolder("汪脚本") then
				makefolder("汪脚本")
			end

			writefile("汪脚本/DING.WAV", result)
		end)

		local ok2, result2 = pcall(function()
			return getcustomasset("汪脚本/DING.WAV")
		end)

		if ok2 and result2 then
			kbDingAsset = result2
		end
	end
end)

kbPlayDing = function()
	if kbToggleSoundMuted then
		return
	end

	if not kbDingAsset then
		pcall(function()
			local wav = getcustomasset("汪脚本/DING.WAV")

			if wav then
				kbDingAsset = wav
			end
		end)
	end

	if not kbDingAsset then
		return
	end

	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = kbDingAsset
		sound.Volume = 2
		sound.Parent = game:GetService("SoundService")
		game:GetService("SoundService"):PlayLocalSound(sound)

		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

kbPlayTada = function()
	if not kbTadaAsset then
		pcall(function()
			local wav = getcustomasset("汪脚本/TADA.WAV")

			if wav then
				kbTadaAsset = wav
			end
		end)
	end

	if not kbTadaAsset then
		return
	end

	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = kbTadaAsset
		sound.Volume = 2
		sound.Parent = game:GetService("SoundService")
		game:GetService("SoundService"):PlayLocalSound(sound)

		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local flag = false

pcall(function()
	if isfile("汪脚本/配置/autoload.txt") then
		local txt = readfile("汪脚本/配置/autoload.txt")

		if txt and txt ~= "" then
			local str2 = "汪脚本/配置" .. "/" .. txt .. ".json"

			if isfile(str2) then
				local data = HttpService:JSONDecode(readfile(str2))

				if type(data) == "table" then
					local settingsTab = data["SettingsTab/关闭开头弹窗音效"]

					if settingsTab and settingsTab.t == "Toggle" then
						flag = settingsTab.v
					end
				end
			end
		end
	end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
game:GetService("VirtualInputManager")
local localPlayer2 = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local tbl = {}
local handlers = {}

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		for k, v in pairs(tbl) do
			if handlers[k] then
				handlers[k](v)
			end

			tbl[k] = nil
		end
	end
end)

local flag2 = not flag

if flag2 then
	kbPlayDing()
end

lib:Notify({
	Title = "汪脚本--通用",
	Content = "作者：汪拜大帝\nQQ：3999698324\n感谢ROB支持",
	Icon = "rbxassetid://5107182114",
	Duration = 5,
})

task.wait(1.5)

if flag2 then
	kbPlayDing()
end

lib:Notify({ Title = "永久免费", Content = "汪脚本永久免费如果你是花钱购买，请联系商家退款", Duration = 5 })
local flag3 = false
local screenGui = nil
local textButton = nil
local frame = nil
local n3 = 60
local flag4 = false
local tbl2 = {}
local tbl3 = {}
local tbl4 = {}
local thread = nil
local flag5 = false

local function fn(arg)
	local character = arg.Character

	if character then
		pcall(function()
			local espHighlight = character:FindFirstChild("EspHighlight")

			if espHighlight then
				espHighlight:Destroy()
			end
		end)

		pcall(function()
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoidRootPart then
				local espBillboard = humanoidRootPart:FindFirstChild("EspBillboard")

				if espBillboard then
					espBillboard:Destroy()
				end
			end
		end)
	end

	tbl2[arg] = nil
	tbl4[arg] = nil
end

local function fn2(arg)
	if tbl3[arg] then
		for _, v in ipairs(tbl3[arg]) do
			pcall(function()
				v:Disconnect()
			end)
		end

		tbl3[arg] = nil
	end
end

local fn3 = nil

fn3 = function(arg)
	if arg == localPlayer2 then
		return
	end
	local character = arg.Character
	if not character then
		return
	end

	pcall(function()
		local espHighlight = character:FindFirstChild("EspHighlight")

		if espHighlight then
			espHighlight:Destroy()
		end
	end)

	pcall(function()
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		if humanoidRootPart then
			local espBillboard = humanoidRootPart:FindFirstChild("EspBillboard")

			if espBillboard then
				espBillboard:Destroy()
			end
		end
	end)

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		task.spawn(function()
			if pcall(function()
				character:WaitForChild("HumanoidRootPart", 5)
			end) and flag4 and arg.Parent then
				fn3(arg)
			end
		end)

		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "EspHighlight"
	highlight.Parent = character
	highlight.FillTransparency = 0.5
	highlight.FillColor = Color3.fromRGB(255, 255, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	tbl4[arg] = highlight
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "EspBillboard"
	billboardGui.Parent = humanoidRootPart
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "NameLabel"
	textLabel.Parent = billboardGui
	textLabel.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = arg.Name
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.SourceSansBold
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Name = "DistLabel"
	textLabel2.Parent = billboardGui
	textLabel2.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel2.Position = UDim2.new(0, 0, 0.5, 0)
	textLabel2.BackgroundTransparency = 1
	textLabel2.Text = "0m"
	textLabel2.TextColor3 = Color3.fromRGB(255, 255, 0)
	textLabel2.TextStrokeTransparency = 0
	textLabel2.TextSize = 12
	textLabel2.Font = Enum.Font.SourceSans
	tbl2[arg] = billboardGui
end

local function fn4(arg)
	if arg == localPlayer2 then
		return
	end

	if tbl3[arg] then
		for _, v in ipairs(tbl3[arg]) do
			pcall(function()
				v:Disconnect()
			end)
		end
	end

	tbl3[arg] = {}

	local connection = arg.CharacterAdded:Connect(function(character)
		task.spawn(function()
			pcall(function()
				character:WaitForChild("HumanoidRootPart", 5)
			end)

			if flag4 then
				task.wait(0.1)
				fn3(arg)
			end
		end)
	end)

	local connection2 = arg.CharacterRemoving:Connect(function()
		fn(arg)
	end)

	table.insert(tbl3[arg], connection)
	table.insert(tbl3[arg], connection2)

	if arg.Character and flag4 then
		fn3(arg)
	end
end

Players.PlayerAdded:Connect(function(player)
	if flag4 then
		task.spawn(function()
			fn4(player)
		end)
	end

	if AntiFlingEnabled then
		task.spawn(function()
			setupAntiFlingForPlayer(player)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	fn(player)
	fn2(player)
end)

local function fn5()
	if thread then
		return
	end
	flag5 = true

	thread = task.spawn(function()
		while flag5 do
			local character = localPlayer2.Character
			local position = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer2 then
					local character2 = player.Character
					local parent = tbl2[player] and tbl2[player].Parent
					local parent2 = tbl4[player] and tbl4[player].Parent

					if character2 and character2:FindFirstChild("HumanoidRootPart") then
						if not parent or not parent2 then
							pcall(function()
								fn3(player)
							end)
						elseif position then
							local distLabel = tbl2[player]
							distLabel = distLabel and distLabel:FindFirstChild("DistLabel")

							if distLabel then
								distLabel.Text = string.format("%.0fm", (character2.HumanoidRootPart.Position - position).Magnitude)
							end
						end
					elseif parent or parent2 then
						pcall(function()
							fn(player)
						end)
					end
				end
			end

			task.wait(0.1)
		end
	end)
end

local function fn6()
	flag5 = false
	thread = nil
end

local connection = nil
local flag6 = false
local flag7 = false
local flag8 = false
local connection2 = nil
local flag9 = false
local n4 = 360
local connection3 = nil
local flag10 = false
local connection4 = nil
local tbl5 = {}
local flag11 = false
local connection5 = nil
local tbl6 = {}
local tbl7 = {}

local function fn7(arg)
	if arg == localPlayer2 then
		return
	end
	local character = arg.Character
	if not character then
		return
	end

	pcall(function()
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if tbl6[descendant] == nil then
					tbl6[descendant] = descendant.CanCollide
				end

				descendant.CanCollide = false
			end
		end
	end)
end

local function fn8(arg)
	if arg == localPlayer2 then
		return
	end
	local character = arg.Character
	if not character then
		return
	end

	pcall(function()
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if tbl6[descendant] ~= nil then
					descendant.CanCollide = tbl6[descendant]
					tbl6[descendant] = nil
				end
			end
		end
	end)
end

local function fn9()
	for k, v in pairs(tbl6) do
		pcall(function()
			if k and k.Parent then
				k.CanCollide = v
			end
		end)
	end

	tbl6 = {}
end

local function fn10(arg)
	if arg == localPlayer2 then
		return
	end
	fn7(arg)

	if tbl7[arg] then
		pcall(function()
			tbl7[arg]:Disconnect()
		end)
	end

	tbl7[arg] = arg.CharacterAdded:Connect(function()
		if not flag11 then
			return
		end

		task.spawn(function()
			task.wait(0.3)

			if flag11 and arg.Parent then
				fn7(arg)
			end
		end)
	end)
end

local function fn11(arg)
	if tbl7[arg] then
		pcall(function()
			tbl7[arg]:Disconnect()
		end)

		tbl7[arg] = nil
	end

	fn8(arg)
end

local function fn12()
	if connection5 then
		connection5:Disconnect()
	end

	for _, player in ipairs(Players:GetPlayers()) do
		fn10(player)
	end

	local n5 = 0

	connection5 = RunService.Heartbeat:Connect(function()
		local now = tick()

		if now - n5 >= 0.5 then
			n5 = now

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer2 and player.Character then
					pcall(function()
						for _, descendant in ipairs(player.Character:GetDescendants()) do
							if descendant:IsA("BasePart") and descendant.CanCollide then
								if tbl6[descendant] == nil then
									tbl6[descendant] = descendant.CanCollide
								end

								descendant.CanCollide = false
							end
						end
					end)
				end
			end
		end

		local character = localPlayer2.Character

		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoidRootPart then
				if humanoidRootPart.AssemblyLinearVelocity.Magnitude > 100 then
					humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				end

				if humanoidRootPart.AssemblyAngularVelocity.Magnitude > 20 then
					humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end)
end

local function fn13()
	if connection5 then
		connection5:Disconnect()
	end

	connection5 = nil

	for _, v in pairs(tbl7) do
		pcall(function()
			v:Disconnect()
		end)
	end

	tbl7 = {}
	fn9()
end

Players.PlayerRemoving:Connect(function(player)
	fn11(player)
end)

local function fn14()
	if connection3 then
		connection3:Disconnect()
	end

	connection3 = nil

	pcall(function()
		if getgenv().kbSpinBAV then
			getgenv().kbSpinBAV:Destroy()
		end
	end)

	local character = localPlayer2.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local humanoidRootPart = character.HumanoidRootPart
	getgenv().kbSpinBAV = Instance.new("BodyAngularVelocity")
	getgenv().kbSpinBAV.Name = "KbSpinBAV"
	getgenv().kbSpinBAV.Parent = humanoidRootPart
	local vector = Vector3.new
	getgenv().kbSpinBAV.AngularVelocity = vector(0, math.rad(n4), 0)
	getgenv().kbSpinBAV.MaxTorque = Vector3.new(0, 1e9, 0)
	getgenv().kbSpinBAV.P = 10000

	connection3 = RunService.Heartbeat:Connect(function()
		if getgenv().kbSpinBAV and getgenv().kbSpinBAV.Parent then
			local vector2 = Vector3.new
			getgenv().kbSpinBAV.AngularVelocity = vector2(0, math.rad(n4), 0)
		end
	end)
end

local function fn15()
	flag9 = false

	if connection3 then
		connection3:Disconnect()
	end

	connection3 = nil

	pcall(function()
		if getgenv().kbSpinBAV then
			getgenv().kbSpinBAV:Destroy()
		end
	end)
end

local function fn16()
	if connection4 then
		connection4:Disconnect()
	end

	connection4 = localPlayer2.Idled:Connect(function()
		local VirtualUser = game:GetService("VirtualUser")
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)
end

local function fn17()
	if connection4 then
		connection4:Disconnect()
	end

	connection4 = nil
end

local function fn18()
	local character = localPlayer2.Character
	if character then
		return character:FindFirstChild("Humanoid")
	end
end

local flag12 = false

local function fn19()
	local character = localPlayer2.Character
	if not character then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	if connection then
		connection:Disconnect()
	end

	connection = humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if not flag12 then
			return
		end

		if humanoid.Jump then
			humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 50, humanoidRootPart.Velocity.Z)
		end
	end)
end

local tbl8 = {
	enabled = false,
	target = nil,
	conn = nil,
	range = 1.5,
	faceTarget = false,
	sink = false,
	sinkDepth = 0,
}

local function fn20(target)
	if tbl8.conn then
		tbl8.conn:Disconnect()
	end

	tbl8.target = target
	tbl8.enabled = true

	tbl8.conn = RunService.Heartbeat:Connect(function()
		if not tbl8.enabled then
			return
		end

		if not tbl8.target then
			return
		end
		local character = tbl8.target.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end
		local character2 = localPlayer2.Character
		if not character2 or not character2:FindFirstChild("HumanoidRootPart") then
			return
		end
		local humanoidRootPart = character2.HumanoidRootPart
		local humanoidRootPart2 = character.HumanoidRootPart
		local humanoid = character2:FindFirstChildOfClass("Humanoid")
		local cFrame = humanoidRootPart2.CFrame * CFrame.new(0, 0, tbl8.range)

		if tbl8.faceTarget then
			cFrame = CFrame.new(cFrame.Position, humanoidRootPart2.Position)

			if tbl8.sink and tbl8.sinkDepth > 0 then
				cFrame *= CFrame.Angles(0.43633231299858238, 0, 0)
			end
		end

		if tbl8.sink and tbl8.sinkDepth > 0 then
			local rotation = cFrame.Rotation
			cFrame = CFrame.new(cFrame.Position.X, cFrame.Position.Y - tbl8.sinkDepth, cFrame.Position.Z) * rotation
		end

		if character2.PrimaryPart then
			character2:PivotTo(cFrame)
		else
			humanoidRootPart.CFrame = cFrame
		end

		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
		end
	end)

	lib:Notify({ Title = "锁人", Content = "开始锁定 " .. target.Name, Duration = 3 })
end

local function fn21()
	tbl8.enabled = false

	if tbl8.conn then
		tbl8.conn:Disconnect()
	end

	tbl8.conn = nil
	tbl8.target = nil
	local character = localPlayer2.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end

	lib:Notify({ Title = "锁人", Content = "已停止锁人", Duration = 3 })
end

local screenGui2 = nil
local frame2 = nil

local function fn22()
	if screenGui2 then
		return
	end
	screenGui2 = Instance.new("ScreenGui")
	screenGui2.Name = "CrosshairGui"
	screenGui2.Parent = localPlayer2.PlayerGui
	screenGui2.ResetOnSpawn = false
	screenGui2.IgnoreGuiInset = true
	frame2 = Instance.new("Frame")
	frame2.Name = "Crosshair"
	frame2.Parent = screenGui2
	frame2.Size = UDim2.new(0, 30, 0, 30)
	frame2.Position = UDim2.new(0.5, -15, 0.5, -15)
	frame2.BackgroundTransparency = 1
	frame2.Visible = false
	local frame3 = Instance.new("Frame")
	frame3.Parent = frame2
	frame3.Size = UDim2.new(1, 0, 0, 2)
	frame3.Position = UDim2.new(0, 0, 0.5, -1)
	frame3.BackgroundColor3 = Color3.new(1, 1, 1)
	frame3.BorderSizePixel = 0
	local frame4 = Instance.new("Frame")
	frame4.Parent = frame2
	frame4.Size = UDim2.new(0, 2, 1, 0)
	frame4.Position = UDim2.new(0.5, -1, 0, 0)
	frame4.BackgroundColor3 = Color3.new(1, 1, 1)
	frame4.BorderSizePixel = 0
	local frame5 = Instance.new("Frame")
	frame5.Parent = frame2
	frame5.Size = UDim2.new(0, 6, 0, 6)
	frame5.Position = UDim2.new(0.5, -3, 0.5, -3)
	frame5.BackgroundColor3 = Color3.new(1, 1, 1)
	frame5.BorderSizePixel = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = frame5
end

local n5 = 0
local connection6 = nil

local function fn23()
	if connection6 then
		return
	end

	connection6 = RunService.Heartbeat:Connect(function()
		local now = tick()
		if now - n5 < 0.2 then
			return
		end
		n5 = now

		if not flag7 then
			if frame2 then
				frame2.Visible = false
			end

			return
		end

		if not screenGui2 then
			fn22()
		end

		if flag8 then
			frame2.Rotation = (frame2.Rotation + 2) % 360
		else
			frame2.Rotation = 0
		end

		frame2.Visible = true
	end)
end

local function fn24()
	if connection6 then
		connection6:Disconnect()
	end

	connection6 = nil

	if frame2 then
		frame2.Visible = false
	end
end

local flag13 = false

local function fn25()
	if flag13 then
		return 0
	end
	flag13 = true
	local backpack = localPlayer2:FindFirstChild("Backpack")

	if not backpack then
		backpack = Instance.new("Backpack")
		backpack.Parent = localPlayer2
	end

	local n6 = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if not (player == localPlayer2 or not player.Character) then
			local tbl9 = {}
			local backpack2 = player:FindFirstChild("Backpack")
			local inventory = player:FindFirstChild("Inventory")
			local storage = player:FindFirstChild("Storage")
			local bag = player:FindFirstChild("Bag")
			local character = player.Character
			local findFirstChild = character.FindFirstChild
			tbl9[1] = backpack2
			tbl9[2] = inventory
			tbl9[3] = storage
			tbl9[4] = bag

			do
				local values = table.pack(findFirstChild(character, "Backpack"))
				table.move(values, 1, values.n, 5, tbl9)
			end

			for _, v in ipairs(tbl9) do
				if v then
					for _, child in ipairs(v:GetChildren()) do
						if child:IsA("Tool") or child:IsA("Model") or child:IsA("Part") or child:IsA("Accessory") then
							if pcall(function()
								child.Parent = backpack
							end) then
								n6 += 1
								task.wait(0.1)
							end
						end
					end
				end
			end
		end
	end

	flag13 = false
	return n6
end

local function fn26()
	local leaderstats = localPlayer2:FindFirstChild("leaderstats")

	if leaderstats then
		for _, child in ipairs(leaderstats:GetChildren()) do
			if child:IsA("IntValue") or child:IsA("NumberValue") then
				child.Value = 999
			end
		end
	end

	local stats = localPlayer2:FindFirstChild("Stats") or localPlayer2:FindFirstChild("stats")

	if stats then
		for _, child in ipairs(stats:GetChildren()) do
			if child:IsA("IntValue") or child:IsA("NumberValue") then
				child.Value = 999
			end
		end
	end
end

local function fn27(arg)
	if arg and arg.Character and arg.Character:FindFirstChild("HumanoidRootPart") then
		local character = localPlayer2.Character

		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = arg.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 3)
		end
	end
end

local function fn28()
	local position = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart") and localPlayer2.Character.HumanoidRootPart.Position
	if not position then
		return nil
	end
	local huge = math.huge
	local v = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer2 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local magnitude = (player.Character.HumanoidRootPart.Position - position).Magnitude

			if magnitude < huge then
				huge = magnitude
				v = player
			end
		end
	end

	return v
end

local function fn29(arg)
	if not arg or not arg.Character then
		lib:Notify({ Title = "提示", Content = "目标玩家无效", Duration = 3 })
		return
	end
	local character = localPlayer2.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	local character2 = arg.Character
	local humanoid2 = character2:FindFirstChildOfClass("Humanoid")
	local rootPart2 = humanoid2 and humanoid2.RootPart
	local head = character2:FindFirstChild("Head")
	local accessory = character2:FindFirstChildOfClass("Accessory")
	local handle = accessory and accessory:FindFirstChild("Handle")
	if not character or not humanoid or not rootPart then
		lib:Notify({ Title = "提示", Content = "你的角色无效", Duration = 3 })
		return
	end

	if rootPart.Velocity.Magnitude < 50 then
		local cFrame = rootPart.CFrame
		getgenv().OldPos = cFrame
	end

	if not getgenv().FPDH then
		local fallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight
		getgenv().FPDH = fallenPartsDestroyHeight
	end

	if head then
		Workspace.CurrentCamera.CameraSubject = head
	elseif not head and handle then
		Workspace.CurrentCamera.CameraSubject = handle
	elseif humanoid2 and rootPart2 then
		Workspace.CurrentCamera.CameraSubject = humanoid2
	end

	if not character2:FindFirstChildWhichIsA("BasePart") then
		lib:Notify({ Title = "提示", Content = "目标没有有效部位", Duration = 3 })
		return
	end

	local function fn30(arg2, arg3, arg4)
		rootPart.CFrame = CFrame.new(arg2.Position) * arg3 * arg4
		character:SetPrimaryPartCFrame(CFrame.new(arg2.Position) * arg3 * arg4)
		rootPart.Velocity = Vector3.new(90000000, 900000000, 90000000)
		rootPart.RotVelocity = Vector3.new(900000000, 900000000, 900000000)
	end

	local function fn31(arg2)
		local n6 = tick() + 2
		local n7 = 0

		while true do
			if rootPart and humanoid2 then
				if arg2.Velocity.Magnitude < 50 then
					n7 += 100
					local n8 = humanoid2.MoveDirection * arg2.Velocity.Magnitude / 1.25
					local cframe = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, 0) + n8, cframe(math.rad(n7), 0, 0))
					task.wait()
					local n9 = humanoid2.MoveDirection * arg2.Velocity.Magnitude / 1.25
					local cframe2 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0) + n9, cframe2(math.rad(n7), 0, 0))
					task.wait()
					local n10 = humanoid2.MoveDirection * arg2.Velocity.Magnitude / 1.25
					local cframe3 = CFrame.Angles
					fn30(arg2, CFrame.new(2.25, 1.5, -2.25) + n10, cframe3(math.rad(n7), 0, 0))
					task.wait()
					local n11 = humanoid2.MoveDirection * arg2.Velocity.Magnitude / 1.25
					local cframe4 = CFrame.Angles
					fn30(arg2, CFrame.new(-2.25, -1.5, 2.25) + n11, cframe4(math.rad(n7), 0, 0))
					task.wait()
					local moveDirection = humanoid2.MoveDirection
					local cframe5 = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, 0) + moveDirection, cframe5(math.rad(n7), 0, 0))
					task.wait()
					local moveDirection2 = humanoid2.MoveDirection
					local cframe6 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0) + moveDirection2, cframe6(math.rad(n7), 0, 0))
					task.wait()
				else
					local cframe = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, humanoid2.WalkSpeed), cframe(1.5707963267948966, 0, 0))
					task.wait()
					local cframe2 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, -humanoid2.WalkSpeed), cframe2(0, 0, 0))
					task.wait()
					local cframe3 = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, humanoid2.WalkSpeed), cframe3(1.5707963267948966, 0, 0))
					task.wait()
					local cframe4 = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, rootPart2.Velocity.Magnitude / 1.25), cframe4(1.5707963267948966, 0, 0))
					task.wait()
					local cframe5 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, -rootPart2.Velocity.Magnitude / 1.25), cframe5(0, 0, 0))
					task.wait()
					local cframe6 = CFrame.Angles
					fn30(arg2, CFrame.new(0, 1.5, rootPart2.Velocity.Magnitude / 1.25), cframe6(1.5707963267948966, 0, 0))
					task.wait()
					local cframe7 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0), cframe7(1.5707963267948966, 0, 0))
					task.wait()
					local cframe8 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0), cframe8(0, 0, 0))
					task.wait()
					local cframe9 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0), cframe9(-1.5707963267948966, 0, 0))
					task.wait()
					local cframe10 = CFrame.Angles
					fn30(arg2, CFrame.new(0, -1.5, 0), cframe10(0, 0, 0))
					task.wait()
				end

				if not (arg2.Velocity.Magnitude > 500 or arg2.Parent ~= arg.Character or arg.Parent ~= Players or arg.Character ~= character2 or humanoid2 and humanoid2.Sit or humanoid.Health <= 0 or tick() > n6) then
					continue
				end
			end

			break
		end
	end

	Workspace.FallenPartsDestroyHeight = (0/0)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "EpixVel"
	bodyVelocity.Parent = rootPart
	bodyVelocity.Velocity = Vector3.new(900000000, 900000000, 900000000)
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	if rootPart2 and head then
		if (rootPart2.CFrame.p - head.CFrame.p).Magnitude > 5 then
			fn31(head)
		else
			fn31(rootPart2)
		end
	elseif rootPart2 and not head then
		fn31(rootPart2)
	elseif not rootPart2 and head then
		fn31(head)
	else
		if not (not rootPart2 and not head and accessory and handle) then
			lib:Notify({ Title = "提示", Content = "找不到合适的甩飞部位", Duration = 3 })
			bodyVelocity:Destroy()
			return
		end

		fn31(handle)
	end

	bodyVelocity:Destroy()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	Workspace.CurrentCamera.CameraSubject = humanoid

	while true do
		rootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
		character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
		humanoid:ChangeState("GettingUp")

		for _, child in pairs(character:GetChildren()) do
			if child:IsA("BasePart") then
				child.Velocity = Vector3.new()
				child.RotVelocity = Vector3.new()
			end
		end

		task.wait()
		if not ((rootPart.Position - getgenv().OldPos.p).Magnitude < 25) then
			continue
		end
		break
	end

	Workspace.FallenPartsDestroyHeight = getgenv().FPDH
	lib:Notify({ Title = "甩飞完成", Content = "已完成对 " .. arg.Name .. " 的甩飞", Duration = 3 })
end

local walkSpeed = 16

local function fn30(arg)
	walkSpeed = arg
	if connection2 then
		return
	end
	local n6 = 0

	connection2 = RunService.Heartbeat:Connect(function()
		local now = tick()
		if now - n6 < 1 then
			return
		end
		n6 = now
		local v = fn18()

		if v then
			if v.WalkSpeed ~= walkSpeed then
				v.WalkSpeed = walkSpeed
			end
		end
	end)
end

local function fn31()
	if connection2 then
		connection2:Disconnect()
		connection2 = nil
	end
end

local function fn32()
	local localPlayer3 = game:GetService("Players").LocalPlayer
	local name = "撸管（r15）"

	local function fn33()
		if localPlayer3:FindFirstChild("Backpack") then
			local r15 = localPlayer3.Backpack:FindFirstChild("撸管（r15）")

			if r15 then
				r15:Destroy()
			end
		end

		if localPlayer3.Character then
			local r15 = localPlayer3.Character:FindFirstChild("撸管（r15）")

			if r15 then
				r15:Destroy()
			end
		end

		if workspace:FindFirstChild("animationContainer") then
			workspace.animationContainer:Destroy()
		end
	end

	local function fn34()
		fn33()
		local humanoid = (localPlayer3.Character or localPlayer3.CharacterAdded:Wait()):WaitForChild("Humanoid")
		local backpack = localPlayer3:WaitForChild("Backpack")

		local function fn35()
			return humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
		end

		local animation = Instance.new("Animation")
		animation.Name = "animationContainer"
		animation.Parent = workspace

		if fn35() == "R15" then
			animation.AnimationId = "rbxassetid://698251653"
		else
			animation.AnimationId = "rbxassetid://72042024"
		end

		local tool = Instance.new("Tool")
		tool.Name = name
		tool.RequiresHandle = false
		tool.Parent = backpack
		local flag14 = false
		local v = nil

		tool.Equipped:Connect(function()
			local character = localPlayer3.Character
			character = character and character:FindFirstChild("Humanoid")

			if character then
				character = character:FindFirstChildOfClass("Animator") or character:WaitForChild("Animator")
			end

			if not character then
				return
			end
			flag14 = true

			while flag14 do
				if not v then
					v = character:LoadAnimation(animation)
				end

				v:Play()
				v:AdjustSpeed(0.7)
				v.TimePosition = 0.6
				task.wait(0.1)

				while flag14 and v and v.TimePosition < 0.7 do
					task.wait(0.05)
				end

				if v then
					v:Stop()
					v:Destroy()
					v = nil
				end
			end
		end)

		tool.Unequipped:Connect(function()
			flag14 = false

			if v then
				v:Stop()
				v:Destroy()
				v = nil
			end
		end)

		humanoid.Died:Connect(function()
			flag14 = false

			if v then
				v:Stop()
				v:Destroy()
				v = nil
			end
		end)
	end

	fn34()

	if _G.AutoToolConnection then
		_G.AutoToolConnection:Disconnect()
	end

	_G.AutoToolConnection = localPlayer3.CharacterAdded:Connect(function()
		localPlayer3:WaitForChild("Backpack")
		task.wait(0.5)
		fn34()
	end)
end

local flag14 = false
local v = nil
local connection7 = nil
local n6 = 5
local n7 = 0
local flag15 = true

local function fn33()
	if connection7 then
		connection7:Disconnect()
	end

	n7 = tick()
	flag15 = true

	connection7 = RunService.Heartbeat:Connect(function(deltaTime)
		if not flag14 or not v or not v.Character then
			return
		end
		local now = tick()
		local character = localPlayer2.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end
		local humanoidRootPart = v.Character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local humanoidRootPart2 = character.HumanoidRootPart
		local position = humanoidRootPart.Position
		local lookVector = humanoidRootPart.CFrame.LookVector
		local n8 = now - n7

		if 1 / math.max(n6, 0.1) <= n8 then
			n7 = now
			flag15 = not flag15
		end

		local n9

		if flag15 then
			n9 = position + lookVector * -2.5
		else
			n9 = position + lookVector * 2.5
		end

		humanoidRootPart2.CFrame = CFrame.new(humanoidRootPart2.Position:Lerp(n9, math.min(deltaTime * 10, 1)), n9 + lookVector)
	end)
end

local function fn34()
	flag14 = false
	v = nil

	if connection7 then
		connection7:Disconnect()
	end

	connection7 = nil

	if tbl5.harassBtn then
		tbl5.harassBtn.Text = "操人"
	end

	if tbl5.harassNearestBtn then
		tbl5.harassNearestBtn.Text = "操最近的人"
	end

	lib:Notify({ Title = "操人", Content = "已停止操人", Duration = 2 })
end

local function fn35()
	if screenGui then
		screenGui:Destroy()
	end

	screenGui = Instance.new("ScreenGui", CoreGui)
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	textButton = Instance.new("TextButton", screenGui)
	textButton.Size = UDim2.new(0, 60, 0, 60)
	textButton.Position = UDim2.new(1, -80, 1, -80)
	textButton.BackgroundColor3 = Color3.new(0, 0.5, 1)
	textButton.Text = "↑"
	textButton.TextColor3 = Color3.new(1, 1, 1)
	textButton.TextSize = 40
	textButton.Font = Enum.Font.SourceSansBold
	textButton.Active = true
	textButton.Draggable = true
	Instance.new("UICorner", textButton).CornerRadius = UDim.new(1, 0)
	local textButton2 = Instance.new("TextButton", screenGui)
	textButton2.Size = UDim2.new(0, 24, 0, 24)
	textButton2.Position = UDim2.new(1, -86, 1, -86)
	textButton2.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	textButton2.Text = "⚙"
	textButton2.TextColor3 = Color3.new(1, 1, 1)
	textButton2.TextSize = 18
	textButton2.Font = Enum.Font.SourceSansBold
	textButton2.Active = true
	textButton2.Draggable = true
	Instance.new("UICorner", textButton2).CornerRadius = UDim.new(1, 0)
	frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 220, 0, 140)
	frame.Position = UDim2.new(1, -240, 1, -160)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.Visible = false
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local textButton3 = Instance.new("TextButton", frame)
	textButton3.Size = UDim2.new(0, 20, 0, 20)
	textButton3.Position = UDim2.new(1, -25, 0, 5)
	textButton3.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	textButton3.Text = "X"
	textButton3.TextColor3 = Color3.new(1, 1, 1)
	textButton3.Font = Enum.Font.SourceSansBold
	Instance.new("UICorner", textButton3).CornerRadius = UDim.new(1, 0)

	textButton3.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	local textLabel = Instance.new("TextLabel", frame)
	textLabel.Size = UDim2.new(1, -30, 0, 30)
	textLabel.Position = UDim2.new(0, 10, 0, 5)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "跳跃高度：" .. n3 .. "mm"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.SourceSansBold
	local textBox = Instance.new("TextBox", frame)
	textBox.Size = UDim2.new(0.6, 0, 0, 30)
	textBox.Position = UDim2.new(0.2, 0, 0, 50)
	textBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	textBox.Text = tostring(n3)
	textBox.TextColor3 = Color3.new(1, 1, 1)
	textBox.Font = Enum.Font.SourceSansBold
	Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
	local textButton4 = Instance.new("TextButton", frame)
	textButton4.Size = UDim2.new(0.4, 0, 0, 30)
	textButton4.Position = UDim2.new(0.1, 0, 0, 90)
	textButton4.BackgroundColor3 = Color3.new(0, 0.6, 0)
	textButton4.Text = "确认"
	textButton4.TextColor3 = Color3.new(1, 1, 1)
	textButton4.Font = Enum.Font.SourceSansBold
	Instance.new("UICorner", textButton4).CornerRadius = UDim.new(0, 6)

	textButton4.MouseButton1Click:Connect(function()
		local num = tonumber(textBox.Text)

		if num and num >= 16 and num <= 100 then
			n3 = num
			textLabel.Text = "跳跃高度：" .. n3 .. "mm"
		end
	end)

	local textButton5 = Instance.new("TextButton", frame)
	textButton5.Size = UDim2.new(0.4, 0, 0, 30)
	textButton5.Position = UDim2.new(0.5, 0, 0, 90)
	textButton5.BackgroundColor3 = Color3.new(0.8, 0.4, 0)
	textButton5.Text = "默认"
	textButton5.TextColor3 = Color3.new(1, 1, 1)
	textButton5.Font = Enum.Font.SourceSansBold
	Instance.new("UICorner", textButton5).CornerRadius = UDim.new(0, 6)

	textButton5.MouseButton1Click:Connect(function()
		n3 = 60
		textBox.Text = "60"
		textLabel.Text = "跳跃高度：" .. n3 .. "mm"
	end)

	textButton2.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)

	textButton.MouseButton1Click:Connect(function()
		if not flag3 then
			return
		end
		local character = localPlayer2.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoidRootPart and humanoid and humanoid.Health > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, n3, humanoidRootPart.Velocity.Z)
		end
	end)
end

local function fn36()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		frame = nil
		textButton = nil
	end
end

local str2 = "servers_" .. userId .. ".json"
local tbl9 = {}

local function fn37()
	local ok, result = pcall(function()
		return readfile(str2)
	end)

	if ok and result and result ~= "" then
		local data = HttpService:JSONDecode(result)

		if data and type(data) == "table" then
			tbl9 = {}

			for _, v2 in ipairs(data) do
				if type(v2) == "string" then
					table.insert(tbl9, { id = v2, name = v2 })
				elseif type(v2) == "table" and v2.id then
					table.insert(tbl9, { id = tostring(v2.id), name = v2.name or tostring(v2.id) })
				end
			end
		end
	end

	local tbl10 = {}
	local tbl11 = {}

	for _, v2 in ipairs(tbl9) do
		if not tbl10[v2.id] then
			tbl10[v2.id] = true
			table.insert(tbl11, v2)
		end
	end

	tbl9 = tbl11
end

fn37()

local function fn38(arg, arg2)
	lib:Notify({
		Title = arg2 or "提示",
		Content = pcall(function()
			if setclipboard then
				setclipboard(arg)
			elseif game:GetService("ClipboardService") then
				game:GetService("ClipboardService"):SetClipboard(arg)
			else
				error("无法访问剪贴板")
			end
		end) and "已复制: " .. arg or "复制失败，请手动复制：" .. arg,
		Duration = 3,
	})
end

local v2 = lib:CreateWindow({
	Title = "汪脚本--通用",
	Icon = "rbxassetid://5107182114",
	IconThemed = true,
	Author = "汪拜大帝 | QQ:3999698324 | 已执行 " .. n2 .. " 次",
	Folder = "汪脚本",
	Size = UDim2.fromOffset(800, 450),
	Transparent = true,
	Theme = "Dark",
	User = { Enabled = false },
	SideBarWidth = 200,
	ScrollBarEnabled = true,
	ToggleKey = Enum.KeyCode.N,
})

task.spawn(function()
	task.wait(1.5)

	pcall(function()
		local main = v2.UIElements.Main
		local topBar = main:FindFirstChild("TopBar") or main:FindFirstChild("Header") or main:FindFirstChild("TitleBar")
		local v3

		if not topBar then
			for _, child in ipairs(main:GetChildren()) do
				local isFrame = child:IsA("Frame")

				if isFrame then
					isFrame = child.Name:lower():find("top") or child.Name:lower():find("header") or child.Name:lower():find("title")
				end

				if isFrame then
					topBar = child
					break
				end
			end

			v3 = topBar
		else
			v3 = topBar
		end

		if v3 then
			for _, descendant in ipairs(v3:GetDescendants()) do
				if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
					local text = descendant.Text or ""
					local str3 = descendant.Name:lower()

					if text == "X" or text == "x" or text == "_" or text == "-" or str3:find("close") or str3:find("exit") or str3:find("minimize") or str3:find("hide") then
						local textButton2 = Instance.new("TextButton")
						textButton2.Name = "KbFixBtn"
						textButton2.Size = UDim2.new(1, 0, 1, 0)
						textButton2.BackgroundTransparency = 1
						textButton2.Text = ""
						textButton2.ZIndex = descendant.ZIndex + 100
						textButton2.Parent = descendant

						textButton2.MouseButton1Click:Connect(function()
							main.Visible = false
						end)
					end
				end
			end
		end
	end)
end)

local color = Color3.fromHex

v2:EditOpenButton({
	Title = "汪脚本--通用",
	Icon = "globe",
	CornerRadius = UDim.new(0, 16),
	StrokeThickness = 2,
	Color = ColorSequence.new(Color3.fromHex("FF0F7B"), color("F89B29")),
	Draggable = true,
})

local tbl10 = {
	NotifyTab = v2:Tab({ Title = "通知", Icon = "bell" }),
	MainTab = v2:Tab({ Title = "主要", Icon = "zap" }),
	SecondaryTab = v2:Tab({ Title = "次要", Icon = "mouse-pointer-2" }),
	MiscTab = v2:Tab({ Title = "杂项", Icon = "settings-2" }),
	GamesTab = v2:Tab({ Title = "支持服务器", Icon = "gamepad-2" }),
	SettingsTab = v2:Tab({ Title = "设置", Icon = "settings" }),
}

kbCfgElements = {}

for k, v3 in pairs(tbl10) do
	for _, v4 in ipairs({ "Toggle", "Slider", "Dropdown", "Input" }) do
		local v5 = v3[v4]

		if v5 then
			v3[v4] = function(arg, arg2)
				local v6 = v5(arg, arg2)

				if arg2 and arg2.Title then
					local str3 = k .. "/" .. arg2.Title

					if k ~= "SettingsTab" or arg2.Title == "关闭启动音效" or arg2.Title == "关闭按钮音效" or arg2.Title == "关闭开头弹窗音效" then
						kbCfgElements[str3] = { el = v6, mtype = v4 }
					end
				end

				return v6
			end
		end
	end
end

kbCfgFolder = "汪脚本/配置"

pcall(function()
	if makefolder and not isfolder("汪脚本") then
		makefolder("汪脚本")
	end

	if makefolder and not isfolder(kbCfgFolder) then
		makefolder(kbCfgFolder)
	end
end)

kbListConfigs = function()
	local tbl11 = {}

	if listfiles then
		local ok, result = pcall(function()
			return listfiles(kbCfgFolder)
		end)

		if ok and result then
			for _, v3 in ipairs(result) do
				local match = v3:match("([^/\\]+)%.json$")

				if match then
					table.insert(tbl11, match)
				end
			end
		end
	end

	table.sort(tbl11)
	return tbl11
end

kbSaveConfig = function(arg)
	local tbl11 = {}

	for k, v3 in pairs(kbCfgElements) do
		local el = v3.el
		local value

		if v3.mtype == "Toggle" then
			value = el.Value
		elseif v3.mtype == "Slider" then
			value = tonumber(el.Value.Default) or el.Value.Default
		else
			value = el.Value
		end

		if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
			tbl11[k] = { t = v3.mtype, v = value }
		end
	end

	if kbCurrentBg then
		tbl11["SettingsTab/切换背景图"] = { t = "Background", v = kbCurrentBg }
	end

	writefile(kbCfgFolder .. "/" .. arg .. ".json", HttpService:JSONEncode(tbl11))
end

kbLoadConfig = function(arg)
	local str3 = kbCfgFolder .. "/" .. arg .. ".json"
	if not isfile or not isfile(str3) then
		return false
	end

	local ok, result = pcall(function()
		return HttpService:JSONDecode(readfile(str3))
	end)

	if not ok or type(result) ~= "table" then
		return false
	end
	local notify = lib.Notify
	local v3 = kbPlayDing

	lib.Notify = function()
	end

	kbPlayDing = function()
	end

	for k, v4 in pairs(result) do
		local v5 = kbCfgElements[k]

		if v5 and v4.t == v5.mtype then
			pcall(function()
				if v5.mtype == "Dropdown" then
					v5.el:Select(v4.v)
				else
					v5.el:Set(v4.v)
				end
			end)
		end
	end

	kbPlayDing = v3
	lib.Notify = notify
	tbl = {}
	local settingsTab = result["SettingsTab/切换背景图"]

	if settingsTab and settingsTab.v and kbApplyBackground then
		pcall(function()
			kbApplyBackground(settingsTab.v)
		end)
	end

	return true
end

v2:SelectTab(1)

tbl10.NotifyTab:Paragraph({
	Title = "汪脚本--通用",
	Desc = "创作者：汪拜大帝\n感谢ROB支持\n您已执行 " .. n2 .. " 次，谢谢您的支持！",
	Image = "rbxassetid://5107182114",
	ImageSize = 42,
})

local function fn39(arg)
	local n8 = math.floor(arg)
	local str3 = ""
	local n9

	if n8 < 0 then
		str3 = "-"
		n9 = -n8
	else
		n9 = n8
	end

	return str3 .. string.format("%d天%d小时%d分钟", math.floor(n9 / 1440), math.floor(n9 % 1440 / 60), n9 % 60)
end

local v3 = os.date("*t")
local now = os.time({ year = 2026, month = 9, day = 6, hour = 15, min = 0, sec = 0 })
local now2 = os.time({ year = v3.year, month = 2, day = 9, hour = 2, min = 27, sec = 0 })

if os.time() < now2 then
	now2 = os.time({ year = v3.year - 1, month = 2, day = 9, hour = 2, min = 27, sec = 0 })
end

local now3 = os.time({ year = os.date("*t", now2).year + 1, month = 2, day = 9, hour = 2, min = 27, sec = 0 })
tbl10.NotifyTab:Paragraph({ Title = "距离最近一次更新", Desc = fn39((os.time() - now) / 60) })
tbl10.NotifyTab:Paragraph({ Title = "脚本诞生日期：2月9日 2:27", Desc = "已诞生 " .. fn39((os.time() - now2) / 60) })
tbl10.NotifyTab:Paragraph({ Title = "距离一周年还有", Desc = fn39((now3 - os.time()) / 60) })
tbl10.NotifyTab:Divider()

tbl10.NotifyTab:Button({
	Title = "ROB脚本v3",
	Desc = "必须用gi加速器",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "ROB脚本v3", Content = "正在加载中...\n必须用gi加速器", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.gitcode.com/ROB5201314/robscript/raw/main/ROB.V3"))()
		end)
	end,
})

tbl10.NotifyTab:Divider()

tbl10.NotifyTab:Button({
	Title = "复制作者QQ",
	Callback = function()
		kbPlayDing()
		fn38("3999698324", "作者QQ")
	end,
})

tbl10.NotifyTab:Button({
	Title = "复制大群: 461440703",
	Callback = function()
		kbPlayDing()
		fn38("461440703", "大群")
	end,
})

tbl10.NotifyTab:Button({
	Title = "复制群1: 1106203175",
	Callback = function()
		kbPlayDing()
		fn38("1106203175", "群1")
	end,
})

tbl10.NotifyTab:Button({
	Title = "复制群2: 1001577641",
	Callback = function()
		kbPlayDing()
		fn38("1001577641", "群2")
	end,
})

tbl10.NotifyTab:Button({
	Title = "复制群3: 239824789",
	Callback = function()
		kbPlayDing()
		fn38("239824789", "群3")
	end,
})

tbl10.NotifyTab:Button({
	Title = "复制群4: 1065927925",
	Callback = function()
		kbPlayDing()
		fn38("1065927925", "群4")
	end,
})

tbl10.NotifyTab:Button({
	Title = "汪脚本解卡主群：1102037300",
	Callback = function()
		kbPlayDing()
		fn38("1102037300", "汪脚本解卡主群")
	end,
})

tbl10.NotifyTab:Button({
	Title = "汪脚本解卡二群：973191542",
	Callback = function()
		kbPlayDing()
		fn38("973191542", "汪脚本解卡二群")
	end,
})

local v4 = nil

tbl10.NotifyTab:Button({
	Title = "捐赠我",
	Desc = "你的支持为我带来动力",
	Callback = function()
		kbPlayTada()

		task.spawn(function()
			if not v4 then
				local ok, result = pcall(function()
					local response = game:HttpGet("https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1784393101511_712.jpg")

					pcall(function()
						if makefolder and not isfolder("汪脚本") then
							makefolder("汪脚本")
						end
					end)

					writefile("汪脚本/赞赏码.jpg", response)
					return getcustomasset("汪脚本/赞赏码.jpg")
				end)

				if not (ok and result) then
					lib:Notify({ Title = "捐赠我", Content = "图片加载失败", Duration = 3 })
					return
				end
				v4 = result
				lib:Notify({ Title = "捐赠我", Content = "赞赏码已保存到你的相册", Duration = 3 })
			else
				lib:Notify({ Title = "捐赠我", Content = "赞赏码已保存到相册，不会再保存", Duration = 3 })
			end

			local playerGui = CoreGui

			if not pcall(function()
				local screenGui3 = Instance.new("ScreenGui")
				screenGui3.Parent = CoreGui
				screenGui3:Destroy()
			end) then
				playerGui = localPlayer2:WaitForChild("PlayerGui")
			end

			local donateGui = playerGui:FindFirstChild("DonateGui")

			if donateGui then
				donateGui:Destroy()
			end

			local screenGui3 = Instance.new("ScreenGui")
			screenGui3.Name = "DonateGui"
			screenGui3.ResetOnSpawn = false
			screenGui3.Parent = playerGui
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			imageLabel.Size = UDim2.new(0, 0, 0, 0)
			imageLabel.Position = UDim2.new(0.5, 0, 0.33, 0)
			imageLabel.Image = v4
			imageLabel.Parent = screenGui3
			local textButton2 = Instance.new("TextButton")
			textButton2.Size = UDim2.new(0, 30, 0, 30)
			textButton2.Position = UDim2.new(1, -30, 0, 0)
			textButton2.BackgroundTransparency = 1
			textButton2.BorderSizePixel = 0
			textButton2.Text = "X"
			textButton2.TextColor3 = Color3.new(0, 0, 0)
			textButton2.TextScaled = true
			textButton2.Font = Enum.Font.SourceSansBold
			textButton2.Parent = imageLabel

			textButton2.MouseButton1Click:Connect(function()
				screenGui3:Destroy()
			end)

			local out = Enum.EasingDirection.Out
			local back = Enum.EasingStyle.Back
			imageLabel:TweenSize(UDim2.new(0, 300, 0, 300), out, back, 0.3, true)
		end)
	end,
})

tbl10.NotifyTab:Paragraph({ Title = "目前捐赠最多的人：", Desc = "宥\nQQ：1072765538\n捐赠金额：52（牛逼）" })

tbl10.MainTab:Toggle({
	Title = "透视",
	Value = false,
	Callback = function(arg)
		flag4 = arg
		lib:Notify({ Title = "透视", Content = arg and "已打开" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end

		if arg then
			fn5()

			for _, player in ipairs(Players:GetPlayers()) do
				fn4(player)
			end
		else
			fn6()

			for _, player in ipairs(Players:GetPlayers()) do
				fn(player)
			end
		end
	end,
})

tbl10.MainTab:Button({
	Title = "飞行",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "飞行脚本", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/fly.lua"))()
		end)
	end,
})

local flag16 = false
local n8 = 50
local connection8 = nil
local bodyVelocity = nil
local bodyGyro = nil

local function fn40()
	if connection8 then
		connection8:Disconnect()
		connection8 = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	local character = localPlayer2.Character
	character = character and character:FindFirstChildOfClass("Humanoid")

	if character then
		character.PlatformStand = false
	end
end

local function fn41()
	fn40()
	local character = localPlayer2.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not humanoidRootPart then
		return
	end
	humanoid.PlatformStand = true
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1000000, 1000000, 1000000)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = humanoidRootPart
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1000000, 1000000, 1000000)
	bodyGyro.P = 10000
	bodyGyro.D = 500
	bodyGyro.Parent = humanoidRootPart
	local ControlModule = nil

	pcall(function()
		ControlModule = require(localPlayer2:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	end)

	connection8 = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent then
			return
		end
		local vector = Vector3.zero

		if ControlModule then
			local ok, result = pcall(function()
				return ControlModule:GetMoveVector()
			end)

			local v5 = ok and result
			local vector2 = Vector3.zero

			if v5 then
				vector = result
			else
				vector = vector2
			end
		end

		bodyVelocity.Velocity = currentCamera.CFrame:VectorToWorldSpace(vector) * n8
		bodyGyro.CFrame = currentCamera.CFrame
	end)
end

localPlayer2.CharacterAdded:Connect(function()
	if flag16 then
		task.wait(1)
		fn41()
	end
end)

tbl10.MainTab:Toggle({
	Title = "飞行v2",
	Value = false,
	Callback = function(arg)
		flag16 = arg

		if arg then
			fn41()
		else
			fn40()
		end

		lib:Notify({ Title = "飞行v2", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

local v5 = tbl10.MainTab:Slider({
	Title = "飞行v2速度 (当前: 50)",
	Value = { Min = 10, Max = 200, Default = 50 },
	Callback = function(flyv2speed)
		tbl.flyv2speed = flyv2speed
	end,
})

handlers.flyv2speed = function(arg)
	kbPlayDing()
	n8 = arg
	lib:Notify({ Title = "飞行v2速度", Content = "已设置为：" .. arg, Duration = 2 })
end

tbl10.MainTab:Input({
	Title = "输入飞行v2速度",
	Placeholder = "10 - 200",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		local n9 = math.floor(num)

		if n9 > 200 then
			n9 = 200
		end

		if n9 < 10 then
			n9 = 10
		end

		v5:Set(n9)
		tbl.flyv2speed = nil
		handlers.flyv2speed(n9)
	end,
})

local tbl11 = {
	Speed = 100,
	State = {
		enabled = false,
		hrp = nil,
		hum = nil,
		microThread = nil,
		healthThread = nil,
		diedConn = nil,
		targetPos = nil,
		lastTime = 0,
	},
	Anchor = {
		active = false,
		head = nil,
		hrp = nil,
		hum = nil,
		rayLength = 3.5,
		rayCount = 12,
		verticalLayers = 3,
	},
	Control = nil,
}

task.spawn(function()
	pcall(function()
		local playerModule = localPlayer.PlayerScripts:FindFirstChild("PlayerModule")

		if playerModule then
			tbl11.Control = require(playerModule):GetControls()
		end
	end)
end)

tbl11.RefreshParts = function()
	local character = localPlayer.Character

	if not character then
		tbl11.State.hrp = nil
		tbl11.State.hum = nil
		tbl11.Anchor.hrp = nil
		tbl11.Anchor.head = nil
		tbl11.Anchor.hum = nil
		return
	end

	tbl11.State.hrp = character:FindFirstChild("HumanoidRootPart")
	tbl11.State.hum = character:FindFirstChildOfClass("Humanoid")
	tbl11.Anchor.hrp = tbl11.State.hrp
	tbl11.Anchor.head = character:FindFirstChild("Head")
	tbl11.Anchor.hum = tbl11.State.hum
end

tbl11.DetectWall = function()
	local hrp = tbl11.Anchor.hrp
	if not hrp then
		return false
	end
	local position = hrp.Position
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = { localPlayer.Character }

	for i = 1, tbl11.Anchor.rayCount do
		local n9 = i / tbl11.Anchor.rayCount * 2 * 3.1415926535897931
		local v6 = math.cos(n9)
		local v7 = math.sin(n9)

		for i2 = -(tbl11.Anchor.verticalLayers - 1) // 2, (tbl11.Anchor.verticalLayers - 1) // 2 do
			local hit = workspace:Raycast(position, Vector3.new(v6, i2 * 0.5, v7).Unit * tbl11.Anchor.rayLength, raycastParams)
			if hit and hit.Instance and hit.Instance.CanCollide and hit.Instance.Transparency < 0.9 then
				return true
			end
		end
	end

	return false
end

tbl11.EnterAnchor = function()
	if tbl11.Anchor.active then
		return
	end

	if not tbl11.Anchor.head or not tbl11.Anchor.hrp or not tbl11.Anchor.hum then
		return
	end
	tbl11.Anchor.head.Anchored = true
	tbl11.Anchor.hum.PlatformStand = true
	tbl11.Anchor.active = true
end

tbl11.ExitAnchor = function()
	if not tbl11.Anchor.active then
		return
	end

	if tbl11.Anchor.head and tbl11.Anchor.hum then
		tbl11.Anchor.head.Anchored = false
		tbl11.Anchor.hum.PlatformStand = false
	end

	tbl11.Anchor.active = false
end

tbl11.MicroStepLoop = function()
	tbl11.State.targetPos = tbl11.State.hrp.Position
	tbl11.State.lastTime = tick()

	while tbl11.State.enabled do
		local now4 = tick()
		local n9 = now4 - tbl11.State.lastTime
		tbl11.State.lastTime = now4

		if not (not tbl11.State.hrp or not tbl11.State.hrp.Parent) then
			local v6 = tbl11.DetectWall()

			if v6 and not tbl11.Anchor.active then
				tbl11.EnterAnchor()
			elseif not v6 and tbl11.Anchor.active then
				tbl11.ExitAnchor()
			end

			local n10

			if tbl11.Control then
				local moveVector = tbl11.Control:GetMoveVector()
				local cFrame = workspace.CurrentCamera.CFrame
				n10 = cFrame.LookVector * -moveVector.Z + cFrame.RightVector * moveVector.X
			else
				n10 = tbl11.State.hum and tbl11.State.hum.MoveDirection or Vector3.zero
			end

			local n11

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				n11 = 1
			else
				n11 = 0

				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					n11 = -1
				end
			end

			local speed = tbl11.Speed
			tbl11.State.targetPos = tbl11.State.targetPos + (n10 + Vector3.new(0, n11, 0)) * speed * n9
			local position = tbl11.State.hrp.Position
			local n12 = tbl11.State.targetPos - position
			local magnitude = n12.Magnitude

			if magnitude > 0 then
				local v7 = math.ceil(magnitude / 10)
				local n13 = n12 / v7

				for i = 1, v7 do
					if tbl11.State.enabled then
						position += n13
						local rotation = tbl11.State.hrp.CFrame.Rotation
						tbl11.State.hrp.CFrame = CFrame.new(position) * rotation
						tbl11.State.hrp.Velocity = Vector3.zero
						continue
					end

					break
				end
			else
				local rotation = tbl11.State.hrp.CFrame.Rotation
				tbl11.State.hrp.CFrame = CFrame.new(tbl11.State.targetPos) * rotation
				tbl11.State.hrp.Velocity = Vector3.zero
			end

			if tbl11.State.hum then
				tbl11.State.hum:ChangeState(Enum.HumanoidStateType.Climbing)
			end

			task.wait(0.001)
			continue
		end

		break
	end
end

tbl11.HealthLockLoop = function()
	while tbl11.State.enabled do
		if tbl11.State.hum and tbl11.State.hum.Health <= 0 then
			tbl11.State.hum.Health = tbl11.State.hum.MaxHealth
		end

		task.wait(0.1)
	end
end

tbl11.Start = function()
	if tbl11.State.enabled then
		return
	end
	tbl11.RefreshParts()
	if not tbl11.State.hrp or not tbl11.State.hum then
		return
	end
	tbl11.State.enabled = true
	tbl11.State.hum:ChangeState(Enum.HumanoidStateType.Climbing)
	tbl11.State.microThread = task.spawn(tbl11.MicroStepLoop)
	tbl11.State.healthThread = task.spawn(tbl11.HealthLockLoop)

	tbl11.State.diedConn = tbl11.State.hum.Died:Connect(function()
		if tbl11.State.hum and tbl11.State.enabled then
			tbl11.State.hum.Health = tbl11.State.hum.MaxHealth
			tbl11.State.hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

tbl11.Stop = function()
	tbl11.State.enabled = false
	tbl11.ExitAnchor()

	if tbl11.State.microThread then
		pcall(function()
			task.cancel(tbl11.State.microThread)
		end)

		tbl11.State.microThread = nil
	end

	if tbl11.State.healthThread then
		pcall(function()
			task.cancel(tbl11.State.healthThread)
		end)

		tbl11.State.healthThread = nil
	end

	if tbl11.State.diedConn then
		tbl11.State.diedConn:Disconnect()
		tbl11.State.diedConn = nil
	end

	if tbl11.State.hum then
		tbl11.State.hum:ChangeState(Enum.HumanoidStateType.Running)
	end
end

localPlayer.CharacterAdded:Connect(function()
	if tbl11.State.enabled then
		tbl11.Stop()
		task.wait(0.2)
		tbl11.Start()
	end
end)

tbl10.MainTab:Toggle({
	Title = "绕过飞行（大部分游戏能绕过）",
	Value = false,
	Callback = function(arg)
		if arg then
			tbl11.Start()
			lib:Notify({ Title = "绕过飞行", Content = "已开启（大部分游戏能绕过）", Duration = 3 })
			kbPlayDing()
		else
			tbl11.Stop()
			lib:Notify({ Title = "绕过飞行", Content = "已关闭", Duration = 3 })
			kbPlayDing()
		end
	end,
})

local v6 = tbl10.MainTab:Slider({
	Title = "绕过飞行速度 (当前: 100)",
	Value = { Min = 10, Max = 500, Default = 100 },
	Callback = function(bypassflyspeed)
		tbl.bypassflyspeed = bypassflyspeed
	end,
})

handlers.bypassflyspeed = function(speed)
	kbPlayDing()
	tbl11.Speed = speed
	lib:Notify({ Title = "绕过飞行速度", Content = "已设置为：" .. speed, Duration = 2 })
end

tbl10.MainTab:Input({
	Title = "输入绕过飞行速度",
	Placeholder = "10 - 500",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		local n9 = math.floor(num)

		if n9 > 500 then
			n9 = 500
		end

		if n9 < 10 then
			n9 = 10
		end

		v6:Set(n9)
		tbl.bypassflyspeed = nil
		handlers.bypassflyspeed(n9)
	end,
})

tbl10.MainTab:Toggle({
	Title = "飞车",
	Value = false,
	Callback = function(feiCheOn)
		getgenv()._feiCheOn = feiCheOn
		getgenv()._feiCheSpeed = getgenv()._feiCheSpeed or 50

		if feiCheOn then
			local function fn42()
				local character = localPlayer2.Character
				if not character then
					return
				end
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					return
				end

				if getgenv()._feiCheBV then
					pcall(function()
						getgenv()._feiCheBV:Destroy()
					end)
				end

				if getgenv()._feiCheBG then
					pcall(function()
						getgenv()._feiCheBG:Destroy()
					end)
				end

				getgenv()._feiCheBV = Instance.new("BodyVelocity")
				getgenv()._feiCheBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				getgenv()._feiCheBV.Velocity = Vector3.zero
				getgenv()._feiCheBV.Parent = humanoidRootPart
				getgenv()._feiCheBG = Instance.new("BodyGyro")
				getgenv()._feiCheBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				getgenv()._feiCheBG.P = 100000
				getgenv()._feiCheBG.D = 5000
				getgenv()._feiCheBG.Parent = humanoidRootPart

				if getgenv()._feiCheConn then
					pcall(function()
						getgenv()._feiCheConn:Disconnect()
					end)
				end

				local renderStepped = RunService.RenderStepped

				getgenv()._feiCheConn = renderStepped:Connect(function()
					if not getgenv()._feiCheBV or not getgenv()._feiCheBV.Parent then
						return
					end

					if not getgenv()._feiCheBG or not getgenv()._feiCheBG.Parent then
						return
					end
					local cFrame = workspace.CurrentCamera.CFrame
					local lookVector = cFrame.LookVector
					getgenv()._feiCheBV.Velocity = lookVector * getgenv()._feiCheSpeed
					getgenv()._feiCheBG.CFrame = cFrame
				end)
			end

			fn42()
			kbPlayDing()
			lib:Notify({ Title = "飞车", Content = "已开启，自动向前飞行", Duration = 3 })
		else
			if getgenv()._feiCheConn then
				pcall(function()
					getgenv()._feiCheConn:Disconnect()
				end)

				getgenv()._feiCheConn = nil
			end

			if getgenv()._feiCheBV then
				pcall(function()
					getgenv()._feiCheBV:Destroy()
				end)

				getgenv()._feiCheBV = nil
			end

			if getgenv()._feiCheBG then
				pcall(function()
					getgenv()._feiCheBG:Destroy()
				end)

				getgenv()._feiCheBG = nil
			end

			kbPlayDing()
			lib:Notify({ Title = "飞车", Content = "已关闭", Duration = 3 })
		end
	end,
})

local v7 = tbl10.MainTab:Slider({
	Title = "飞车速度 (当前: 50)",
	Value = { Min = 10, Max = 500, Default = 50 },
	Callback = function(feiCheSpeed)
		getgenv()._feiCheSpeed = feiCheSpeed
		tbl.feichespeed = feiCheSpeed
	end,
})

handlers.feichespeed = function(arg)
	kbPlayDing()
	lib:Notify({ Title = "飞车速度", Content = "已设置为：" .. arg, Duration = 2 })
end

tbl10.MainTab:Input({
	Title = "输入飞车速度",
	Placeholder = "10 - 500",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		local n9 = math.floor(num)

		if n9 > 500 then
			n9 = 500
		end

		if n9 < 10 then
			n9 = 10
		end

		v7:Set(n9)
		tbl.feichespeed = nil
		handlers.feichespeed(n9)
	end,
})

tbl10.MainTab:Button({
	Title = "建造方块",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "建造方块", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://pastebin.com/raw/Zt4kkQG9"))()
		end)
	end,
})

localPlayer2.CharacterAdded:Connect(function()
	if flag12 then
		task.wait(0.3)
		fn19()
	end
end)

tbl10.MainTab:Toggle({
	Title = "无限跳",
	Value = false,
	Callback = function(arg)
		flag12 = arg

		if arg then
			fn19()
			lib:Notify({ Title = "无限跳", Content = "已开启", Duration = 3 })
			kbPlayDing()
		else
			if connection then
				connection:Disconnect()
			end

			connection = nil
			lib:Notify({ Title = "无限跳", Content = "已关闭", Duration = 3 })
			kbPlayDing()
		end
	end,
})

tbl10.MainTab:Toggle({
	Title = "穿墙",
	Value = false,
	Callback = function(arg)
		local Workspace_ = game:GetService("Workspace")
		local Players2 = game:GetService("Players")

		if arg then
			Clipon = true

			if not Stepped or not Stepped.Connected then
				Stepped = game:GetService("RunService").Stepped:Connect(function()
					if not Clipon then
						return
					end

					for _, child in pairs(Workspace_:GetChildren()) do
						if child.Name == Players2.LocalPlayer.Name then
							for _, child2 in pairs(Workspace_[Players2.LocalPlayer.Name]:GetChildren()) do
								if child2:IsA("BasePart") then
									child2.CanCollide = false
								end
							end
						end
					end
				end)
			end
		else
			Clipon = false

			if Stepped then
				Stepped:Disconnect()
			end

			for _, child in pairs(Workspace_:GetChildren()) do
				if child.Name == Players2.LocalPlayer.Name then
					for _, child2 in pairs(Workspace_[Players2.LocalPlayer.Name]:GetChildren()) do
						if child2:IsA("BasePart") then
							child2.CanCollide = true
						end
					end
				end
			end
		end

		lib:Notify({ Title = "穿墙", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

local flag17 = false
local walkSpeed2 = 16

tbl10.MainTab:Toggle({
	Title = "修改移速",
	Value = false,
	Callback = function(arg)
		flag17 = arg

		if arg then
			local v8 = fn18()

			if v8 then
				v8.WalkSpeed = walkSpeed2
			end

			fn30(walkSpeed2)
			lib:Notify({ Title = "修改移速", Content = "已开启，当前移速：" .. walkSpeed2, Duration = 3 })
			kbPlayDing()
		else
			fn31()
			local v8 = fn18()

			if v8 then
				v8.WalkSpeed = 16
			end

			lib:Notify({ Title = "修改移速", Content = "已关闭，恢复默认移速", Duration = 3 })
		end
	end,
})

local v8 = tbl10.MainTab:Slider({
	Title = "移速数值 (当前: 16)",
	Value = { Min = 5, Max = 1000, Default = 16 },
	Callback = function(speedvalue)
		walkSpeed2 = speedvalue
		tbl.speedvalue = speedvalue

		if flag17 then
			local v8 = fn18()

			if v8 then
				v8.WalkSpeed = speedvalue
			end

			fn30(speedvalue)
		end
	end,
})

handlers.speedvalue = function()
	kbPlayDing()
end

tbl10.MainTab:Input({
	Title = "输入移速数值",
	Placeholder = "5 - 1000",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		kbPlayDing()
		local n9 = math.floor(num)

		if n9 > 1000 then
			n9 = 1000
		end

		if n9 < 5 then
			n9 = 5
		end

		v8:Set(n9)
		tbl.speedvalue = nil
	end,
})

tbl10.MainTab:Toggle({
	Title = "夜视",
	Value = false,
	Callback = function(arg)
		flag6 = arg
		local Lighting = game:GetService("Lighting")

		if flag6 then
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
			Lighting.ColorShift_Top = Color3.new(1, 1, 1)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 100000
			Lighting.Brightness = 1
			Lighting.GlobalShadows = false
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.ClockTime = 12
		else
			Lighting.Ambient = Color3.new(0, 0, 0)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.ColorShift_Top = Color3.new(0, 0, 0)
			Lighting.FogEnd = 1000
			Lighting.FogStart = 0
			Lighting.Brightness = 1
			Lighting.GlobalShadows = true
			Lighting.OutdoorAmbient = Color3.new(0.7, 0.7, 0.7)
		end

		lib:Notify({ Title = "夜视", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.MainTab:Button({
	Title = "偷取道具",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "偷取道具", Content = "正在偷取道具中...", Duration = 5 })

		task.spawn(function()
			local v9 = fn25()
			lib:Notify({ Title = "偷取完成", Content = "共偷取 " .. tostring(v9) .. " 个道具", Duration = 3 })
		end)
	end,
})

tbl10.MainTab:Toggle({
	Title = "解锁跳跃",
	Value = false,
	Callback = function(arg)
		flag3 = arg

		if arg then
			fn35()
		else
			fn36()
		end

		lib:Notify({ Title = "解锁跳跃", Content = arg and "已显示跳跃按钮" or "已隐藏跳跃按钮", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.MainTab:Button({
	Title = "甩飞全部人",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "甩飞", Content = "开始甩飞所有玩家...", Duration = 3 })

		task.spawn(function()
			local n9 = 0

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer2 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					fn29(player)
					n9 += 1
					task.wait(0.5)
				end
			end

			lib:Notify({ Title = "甩飞完成", Content = "共甩飞 " .. tostring(n9) .. " 个玩家", Duration = 3 })
		end)
	end,
})

tbl10.MainTab:Toggle({
	Title = "碰飞",
	Value = false,
	Callback = function(kbTouchFlingOn)
		getgenv().kbTouchFlingOn = kbTouchFlingOn

		if kbTouchFlingOn then
			if not getgenv().kbOldFPDH then
				local fallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
				getgenv().kbOldFPDH = fallenPartsDestroyHeight
			end

			workspace.FallenPartsDestroyHeight = (0/0)

			getgenv().kbTouchFlingThread = task.spawn(function()
				local n9 = 0.1

				while getgenv().kbTouchFlingOn do
					RunService.Heartbeat:Wait()
					local character = localPlayer2.Character
					character = character and character:FindFirstChild("HumanoidRootPart")

					if character then
						local velocity = character.Velocity
						character.Velocity = velocity * 10000 + Vector3.new(0, 10000, 0)
						RunService.RenderStepped:Wait()
						character.Velocity = velocity
						RunService.Stepped:Wait()
						character.Velocity = velocity + Vector3.new(0, n9, 0)
						n9 = -n9
					end
				end
			end)

			lib:Notify({ Title = "碰飞", Content = "已开启，别人碰到你将被瞬间弹飞", Duration = 3 })
			kbPlayDing()
		else
			getgenv().kbTouchFlingOn = false

			pcall(function()
				workspace.FallenPartsDestroyHeight = getgenv().kbOldFPDH
			end)

			lib:Notify({ Title = "碰飞", Content = "已关闭", Duration = 3 })
			kbPlayDing()
		end
	end,
})

tbl10.MainTab:Button({
	Title = "甩飞最近的人",
	Callback = function()
		kbPlayDing()
		local v9 = nil
		local position = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart") and localPlayer2.Character.HumanoidRootPart.Position
		if not position then
			lib:Notify({ Title = "甩飞", Content = "你的角色未加载", Duration = 3 })
			return
		end
		local huge = math.huge

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer2 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local magnitude = (player.Character.HumanoidRootPart.Position - position).Magnitude

				if magnitude < huge then
					v9 = player
					huge = magnitude
				end
			end
		end

		if v9 then
			lib:Notify({ Title = "甩飞", Content = "正在甩飞 " .. v9.Name, Duration = 3 })

			task.spawn(function()
				fn29(v9)
			end)
		else
			lib:Notify({ Title = "甩飞", Content = "未找到其他玩家", Duration = 3 })
		end
	end,
})

local v9 = nil

flingDropdown = tbl10.MainTab:Dropdown({
	Title = "选定甩飞玩家",
	Values = {},
	Callback = function(arg)
		if v9 and v9.Name == arg then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == arg and player ~= localPlayer2 then
				v9 = player
				break
			end
		end
	end,
})

tbl10.MainTab:Button({
	Title = "确定执行甩飞",
	Callback = function()
		kbPlayDing()

		if v9 and v9.Parent then
			lib:Notify({ Title = "甩飞", Content = "已选定 " .. v9.Name .. "，开始甩飞", Duration = 3 })

			task.spawn(function()
				fn29(v9)
			end)

			v9 = nil

			pcall(function()
				flingDropdown:Select(nil)
			end)
		else
			lib:Notify({ Title = "甩飞", Content = "请先选择玩家", Duration = 3 })
		end
	end,
})

tbl10.MainTab:Toggle({
	Title = "循环甩飞",
	Value = false,
	Callback = function(arg)
		kbPlayDing()

		if arg then
			lib:Notify({ Title = "循环甩飞", Content = "已开启，将持续甩飞选定目标", Duration = 3 })

			task.spawn(function()
				while arg do
					if v9 and v9.Parent and v9.Character then
						pcall(function()
							fn29(v9)
						end)
					end

					task.wait(1)
				end
			end)
		else
			lib:Notify({ Title = "循环甩飞", Content = "已关闭", Duration = 3 })
		end
	end,
})

tbl10.MainTab:Button({
	Title = "祖国人汉化",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "祖国人汉化", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/-/refs/heads/main/祖国人汉化"))()
		end)
	end,
})

tbl10.MainTab:Button({
	Title = "飞踢脚本汉化（执行有点慢耐心等待）",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "飞踢脚本汉化", Content = "正在加载中...执行有点慢耐心等待", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/-/refs/heads/main/飞踢脚本汉化"))()
		end)
	end,
})

tbl10.MainTab:Button({
	Title = "自瞄",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "自瞄", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/自瞄"))()
		end)
	end,
})

tbl10.MainTab:Toggle({
	Title = "防甩飞",
	Value = false,
	Callback = function(arg)
		flag11 = arg

		if arg then
			fn12()
		else
			fn13()
		end

		lib:Notify({ Title = "防甩飞", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

local tbl12 = {
	On = false,
	Range = 10,
	Conn = nil,
	LastScan = 0,
	Do = function(arg, arg2)
		local character = localPlayer2.Character
		if not character then
			return 0
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return 0
		end
		local position = humanoidRootPart.Position
		local n9 = 0

		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				local parent = descendant.Parent

				if parent and parent:IsA("BasePart") then
					if (parent.Position - position).Magnitude <= arg2 then
						pcall(function()
							fireproximityprompt(descendant)
						end)

						n9 += 1
					end
				end
			end
		end

		return n9
	end,
	FullMap = function()
		if not localPlayer2.Character then
			return
		end

		task.spawn(function()
			local n9 = 0

			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") then
					pcall(function()
						fireproximityprompt(descendant)
					end)

					n9 += 1

					if n9 % 40 == 0 then
						task.wait()
					end
				end
			end

			lib:Notify({ Title = "全图交互", Content = "已交互 " .. tostring(n9) .. " 个对象", Duration = 3 })
		end)
	end,
	Start = function(arg)
		if arg.Conn then
			return
		end
		arg.LastScan = 0

		arg.Conn = RunService.Heartbeat:Connect(function()
			local now4 = tick()
			if now4 - arg.LastScan < 0.3 then
				return
			end
			arg.LastScan = now4
			arg:Do(arg.Range)
		end)
	end,
	Stop = function(arg)
		if arg.Conn then
			arg.Conn:Disconnect()
		end

		arg.Conn = nil
	end,
}

local v10 = nil
local str3 = ""
local connection9 = nil
local v11 = nil

local function fn42()
	if connection9 then
		connection9:Disconnect()
		connection9 = nil
	end

	if v10 then
		v10:Destroy()
		v10 = nil
	end

	local v12 = v11
	local parent = v11

	if v12 then
		parent = v12.Parent
	end

	if parent then
		localPlayer2.Character = v12
		local humanoid = v12:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.PlatformStand = false
		end

		currentCamera.CameraSubject = humanoid

		for _, descendant in ipairs(v12:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.Transparency = 0
			end
		end

		if v12:FindFirstChild("HumanoidRootPart") then
			v12.HumanoidRootPart.CanCollide = false
		end
	end

	v11 = nil
end

local function fn43(arg)
	local v12 = Players:FindFirstChild(arg)
	if not v12 or not v12.Character then
		lib:Notify({ Title = "错误", Content = "目标玩家不存在或角色未加载", Type = "error" })
		return
	end
	fn42()
	task.wait(0.2)
	local character = v12.Character
	local character2 = localPlayer2.Character
	if not character2 then
		lib:Notify({ Title = "错误", Content = "你的角色未加载", Type = "error" })
		return
	end
	v11 = character2
	character.Archivable = true
	local clone = character:Clone()
	clone.Name = "PossessedClone"
	clone.Parent = workspace
	v10 = clone
	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = clone:FindFirstChild("HumanoidRootPart")

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("SelectionBox") or descendant:IsA("SelectionSphere") or descendant:IsA("BoxHandleAdornment") or descendant:IsA("Highlight") then
			descendant:Destroy()
		end
	end

	if humanoidRootPart then
		humanoidRootPart.Transparency = 1
	end

	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	end

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BodyMover") or descendant:IsA("LinearVelocity") or descendant:IsA("VectorForce") or descendant:IsA("AlignPosition") or descendant:IsA("AlignOrientation") or descendant:IsA("Torque") then
			descendant:Destroy()
		end
	end

	for _, descendant in ipairs(character2:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.Transparency = 1
		end

		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end

	if character2:FindFirstChild("HumanoidRootPart") then
		character2.HumanoidRootPart.CanCollide = false
	end

	localPlayer2.Character = clone
	currentCamera.CameraSubject = humanoid
	local animate = clone:FindFirstChild("Animate")

	if animate then
		animate.Disabled = true
		task.wait(0.1)
		animate.Disabled = false
	end

	local humanoid2 = character2:FindFirstChildOfClass("Humanoid")

	if humanoid2 then
		humanoid2.Died:Connect(function()
			fn42()
		end)
	end

	local humanoid3 = character2:FindFirstChildOfClass("Humanoid")

	if humanoid3 then
		humanoid3.PlatformStand = true
	end

	connection9 = RunService.Heartbeat:Connect(function()
		if clone and clone.Parent and humanoidRootPart and v11 and v11:FindFirstChild("HumanoidRootPart") then
			local humanoidRootPart2 = v11.HumanoidRootPart
			humanoidRootPart2.CFrame = humanoidRootPart.CFrame
			humanoidRootPart2.AssemblyLinearVelocity = Vector3.zero
			humanoidRootPart2.AssemblyAngularVelocity = Vector3.zero

			for _, descendant in ipairs(v11:GetDescendants()) do
				if descendant:IsA("BasePart") then
					if descendant.CanCollide then
						descendant.CanCollide = false
					end

					if descendant.Transparency < 1 then
						descendant.Transparency = 1
					end
				elseif descendant:IsA("Decal") and descendant.Transparency < 1 then
					descendant.Transparency = 1
				end
			end

			local flag18 = humanoid

			if humanoid then
				local climbing = Enum.HumanoidStateType.Climbing
				flag18 = humanoid:GetState() == climbing
			end

			if flag18 then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
	end)

	lib:Notify({ Title = "成功", Content = "已伪装成: " .. arg .. "（仅自己可见）", Type = "success" })
end

kbSoulOn = false
kbSoulNoReturn = false
kbSoulOriginCF = nil
kbInv1On = false
kbInv2On = false
kbInvRealChar = nil
kbInvFakeChar = nil
kbInvOldFPDH = nil
kbInvRespawnConn = nil
kbInvTrans = {}
kbInvToggles = {}
kbShowHalfOn = false

kbInvResetTrans = function()
	for k, v12 in pairs(kbInvTrans) do
		pcall(function()
			if k and k.Parent then
				k.Transparency = v12
			end
		end)
	end

	kbInvTrans = {}
end

kbInvApplyTrans = function(arg)
	if not arg then
		return
	end

	for _, descendant in ipairs(arg:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if kbInvTrans[descendant] == nil then
				kbInvTrans[descendant] = descendant.Transparency
			end

			descendant.Transparency = 0.5
		end
	end
end

kbInvResetAll = function()
	kbSoulOn = false
	kbSoulOriginCF = nil
	kbInv1On = false
	kbInv2On = false

	if kbInvRespawnConn then
		pcall(function()
			kbInvRespawnConn:Disconnect()
		end)

		kbInvRespawnConn = nil
	end

	kbInvResetTrans()

	pcall(function()
		if kbInvFakeChar then
			kbInvFakeChar:Destroy()
		end
	end)

	kbInvFakeChar = nil
	kbInvRealChar = nil

	if kbInvOldFPDH then
		pcall(function()
			workspace.FallenPartsDestroyHeight = kbInvOldFPDH
		end)

		kbInvOldFPDH = nil
	end
end

kbInvSetup = function()
	if kbInvFakeChar and kbInvFakeChar.Parent then
		return true
	end
	local character = localPlayer2.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		lib:Notify({ Title = "提示", Content = "角色未加载", Duration = 3 })
		return false
	end

	pcall(function()
		character.Archivable = true
	end)

	local ok, character2 = pcall(function()
		return character:Clone()
	end)

	if not ok or not character2 then
		lib:Notify({ Title = "提示", Content = "克隆失败，当前注入器不支持", Duration = 3 })
		return false
	end
	kbInvOldFPDH = workspace.FallenPartsDestroyHeight
	workspace.FallenPartsDestroyHeight = (0/0)
	kbInvRealChar = character
	character2.Parent = workspace
	localPlayer2.Character = character2
	kbInvFakeChar = character2

	pcall(function()
		for _, descendant in ipairs(character2:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.Transparency = kbShowHalfOn and 0.5 or 1
			end
		end
	end)

	local humanoid = character2:FindFirstChildOfClass("Humanoid")

	if humanoid then
		workspace.CurrentCamera.CameraSubject = humanoid
	end

	kbInvRespawnConn = localPlayer2.CharacterAdded:Connect(function(character3)
		local flag18 = kbInvFakeChar ~= nil or kbInvRealChar ~= nil
		kbInvResetAll()

		pcall(function()
			for _, v12 in pairs(kbInvToggles) do
				v12:Set(false)
			end
		end)

		if flag18 then
			task.spawn(function()
				task.wait(0.5)
				local humanoid2 = character3 and character3:FindFirstChildOfClass("Humanoid")

				if humanoid2 then
					workspace.CurrentCamera.CameraSubject = humanoid2
				end
			end)
		end
	end)

	return true
end

kbInvCheckRestore = function()
	if kbSoulOn or kbInv1On or kbInv2On then
		return
	end
	local v12 = kbInvFakeChar
	local v13 = kbInvRealChar
	local cFrame = nil

	if v12 and v12.Parent then
		local humanoidRootPart = v12:FindFirstChild("HumanoidRootPart")

		if humanoidRootPart then
			cFrame = humanoidRootPart.CFrame
		end
	end

	if kbInvRespawnConn then
		pcall(function()
			kbInvRespawnConn:Disconnect()
		end)

		kbInvRespawnConn = nil
	end

	kbInvResetTrans()

	pcall(function()
		if v12 then
			v12:Destroy()
		end
	end)

	kbInvFakeChar = nil
	kbInvRealChar = nil

	if kbInvOldFPDH then
		pcall(function()
			workspace.FallenPartsDestroyHeight = kbInvOldFPDH
		end)

		kbInvOldFPDH = nil
	end

	if v13 and v13.Parent ~= nil then
		pcall(function()
			v13.Parent = workspace
		end)

		localPlayer2.Character = v13

		if cFrame then
			pcall(function()
				v13:MoveTo(cFrame.Position)
			end)
		end

		local humanoid = v13:FindFirstChildOfClass("Humanoid")

		if humanoid then
			workspace.CurrentCamera.CameraSubject = humanoid
		end
	end
end

kbInvToggles[2] = tbl10.MainTab:Toggle({
	Title = "隐身v1",
	Default = false,
	Callback = function(arg)
		kbPlayDing()

		if arg then
			if not kbInvSetup() then
				pcall(function()
					kbInvToggles[2]:Set(false)
				end)

				return
			end

			kbInv1On = true

			task.spawn(function()
				local v12 = kbInvRealChar
				if not v12 then
					return
				end
				local flag18 = v12.Parent == nil

				if flag18 then
					pcall(function()
						v12.Parent = workspace
					end)
				end

				pcall(function()
					v12:MoveTo(v12:GetPivot().Position - Vector3.new(0, 10000, 0))
				end)

				task.wait(0.3)

				if flag18 and kbSoulOn then
					pcall(function()
						v12.Parent = nil
					end)
				end
			end)

			lib:Notify({ Title = "隐身v1", Content = "已开启", Duration = 3 })
		else
			kbInv1On = false

			pcall(function()
				if kbInvRealChar then
					kbInvRealChar:MoveTo(kbInvRealChar:GetPivot().Position + Vector3.new(0, 10000, 0))
				end
			end)

			kbInvCheckRestore()
			lib:Notify({ Title = "隐身v1", Content = "已关闭", Duration = 3 })
		end
	end,
})

kbInvToggles[3] = tbl10.MainTab:Toggle({
	Title = "隐身v2",
	Default = false,
	Callback = function(arg)
		kbPlayDing()

		if arg then
			local character = localPlayer2.Character

			if not character then
				lib:Notify({ Title = "隐身v2", Content = "角色未加载", Duration = 3 })

				pcall(function()
					kbInvToggles[3]:Set(false)
				end)

				return
			end

			kbInv2On = true

			task.spawn(function()
				if kbInvOldFPDH then
					pcall(function()
						workspace.FallenPartsDestroyHeight = kbInvOldFPDH
					end)

					kbInvOldFPDH = nil
				end

				pcall(function()
					character:MoveTo(Vector3.new(0, -1000000, 0))
				end)
			end)

			lib:Notify({ Title = "隐身v2", Content = "已开启", Duration = 3 })
		else
			kbInv2On = false
			kbInvCheckRestore()
			lib:Notify({ Title = "隐身v2", Content = "已关闭，重置角色即可恢复", Duration = 3 })
		end
	end,
})

kbInvToggles[4] = tbl10.MainTab:Toggle({
	Title = "显示半透明",
	Default = false,
	Callback = function(content)
		kbPlayDing()
		kbShowHalfOn = content

		pcall(function()
			if kbInvFakeChar then
				for _, descendant in ipairs(kbInvFakeChar:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("Decal") then
						descendant.Transparency = content and 0.5 or 1
					end
				end
			end
		end)

		local v12 = lib
		local notify = v12.Notify
		local tbl13 = { Title = "显示半透明" }
		content = content and "已开启"
		tbl13.Content = content or "已关闭"
		tbl13.Duration = 3
		notify(v12, tbl13)
	end,
})

tbl10.MainTab:Button({
	Title = "设置重生点",
	Callback = function()
		kbPlayDing()
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local position = humanoidRootPart.Position
		getgenv()._kbSpawnPos = position

		if getgenv()._kbSpawnPart and getgenv()._kbSpawnPart.Parent then
			getgenv()._kbSpawnPart:Destroy()
		end

		local part = Instance.new("Part")
		part.Name = "KbSpawnMarker"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.CFrame = CFrame.new(getgenv()._kbSpawnPos)
		part.Parent = workspace
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Size = UDim2.new(0, 120, 0, 40)
		billboardGui.StudsOffset = Vector3.new(0, -3, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.Parent = part
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "重生点"
		textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextSize = 18
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Parent = billboardGui
		getgenv()._kbSpawnPart = part

		if getgenv()._kbSpawnConn then
			pcall(function()
				getgenv()._kbSpawnConn:Disconnect()
			end)
		end

		local characterAdded = localPlayer.CharacterAdded

		getgenv()._kbSpawnConn = characterAdded:Connect(function(arg)
			if not getgenv()._kbSpawnPos then
				return
			end

			task.spawn(function()
				local humanoidRootPart2 = arg:WaitForChild("HumanoidRootPart", 3)

				if humanoidRootPart2 then
					task.wait(0.1)

					pcall(function()
						humanoidRootPart2.CFrame = CFrame.new(getgenv()._kbSpawnPos)
					end)
				end
			end)
		end)

		lib:Notify({ Title = "设置重生点", Content = "重生点已设置", Duration = 3 })
	end,
})

tbl10.MainTab:Button({
	Title = "删除重生点",
	Callback = function()
		kbPlayDing()
		getgenv()._kbSpawnPos = nil

		if getgenv()._kbSpawnPart and getgenv()._kbSpawnPart.Parent then
			getgenv()._kbSpawnPart:Destroy()
		end

		getgenv()._kbSpawnPart = nil

		if getgenv()._kbSpawnConn then
			pcall(function()
				getgenv()._kbSpawnConn:Disconnect()
			end)

			getgenv()._kbSpawnConn = nil
		end

		lib:Notify({ Title = "删除重生点", Content = "重生点已删除", Duration = 3 })
	end,
})

ImpersonateDropdown = tbl10.MainTab:Dropdown({
	Title = "选择要伪装成的玩家",
	Multi = false,
	Values = {},
	Callback = function(arg)
		str3 = arg
	end,
})

local flag18 = false

local function fn44()
	if flag18 then
		return
	end
	flag18 = true

	task.delay(0.5, function()
		flag18 = false
		local tbl13 = {}

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer2 then
				table.insert(tbl13, player.Name)
			end
		end

		if flingDropdown then
			flingDropdown:Refresh(tbl13)
		end

		if lockDropdown then
			lockDropdown:Refresh(tbl13)
		end

		if harassDropdown then
			harassDropdown:Refresh(tbl13)
		end

		if tpDropdown then
			tpDropdown:Refresh(tbl13)
		end

		if ImpersonateDropdown then
			ImpersonateDropdown:Refresh(tbl13)
		end
	end)
end

tbl10.MainTab:Button({
	Title = "刷新玩家列表",
	Callback = function()
		kbPlayDing()
		fn44()
	end,
})

tbl10.MainTab:Button({
	Title = "变身成他人（栽赃）",
	Callback = function()
		kbPlayDing()

		if str3 ~= "" then
			fn43(str3)
		else
			lib:Notify({ Title = "提示", Content = "请先选择一名玩家", Type = "warning" })
		end
	end,
})

tbl10.MainTab:Button({
	Title = "取消伪装",
	Callback = function()
		kbPlayDing()
		fn42()
		lib:Notify({ Title = "提示", Content = "已取消伪装", Type = "info" })
	end,
})

fn44()

tbl10.MainTab:Toggle({
	Title = "自动交互",
	Value = false,
	Callback = function(on)
		tbl12.On = on

		if on then
			tbl12:Start()
		else
			tbl12:Stop()
		end

		lib:Notify({ Title = "自动交互", Content = on and "已开启" or "已关闭", Duration = 3 })

		if on then
			kbPlayDing()
		end
	end,
})

tbl10.MainTab:Slider({
	Title = "交互范围",
	Value = { Min = 1, Max = 100, Default = 10 },
	Callback = function(range)
		tbl12.Range = range
	end,
})

tbl10.MainTab:Input({
	Title = "输入交互范围",
	Placeholder = "1 - 100",
	Callback = function(arg)
		local num = tonumber(arg)

		if num then
			local range = math.floor(num)

			if range > 100 then
				range = 100
			end

			if range < 1 then
				range = 1
			end

			tbl12.Range = range
		end
	end,
})

tbl10.MainTab:Button({
	Title = "全图交互",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "全图交互", Content = "正在全图交互中...", Duration = 3 })
		tbl12:FullMap()
	end,
})

kbInvToggles[1] = tbl10.SecondaryTab:Toggle({
	Title = "灵魂出窍",
	Desc = "留下本体在原地，别人看不到你虚体，别人能看到你的本体",
	Default = false,
	Callback = function(arg)
		kbPlayDing()

		if arg then
			if not kbInvSetup() then
				pcall(function()
					kbInvToggles[1]:Set(false)
				end)

				return
			end

			kbSoulOn = true
			kbInvApplyTrans(kbInvFakeChar)
			local v12 = kbInvRealChar

			if v12 then
				local humanoidRootPart = v12:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					kbSoulOriginCF = humanoidRootPart.CFrame

					pcall(function()
						humanoidRootPart.Anchored = true
					end)
				end
			end

			lib:Notify({ Title = "灵魂出窍", Content = "已开启", Duration = 3 })
		else
			kbSoulOn = false
			kbInvResetTrans()
			local v12 = kbInvRealChar
			local v13 = kbSoulOriginCF
			kbSoulOriginCF = nil

			if v12 then
				local humanoidRootPart = v12:FindFirstChild("HumanoidRootPart")

				pcall(function()
					if humanoidRootPart then
						humanoidRootPart.Anchored = false
					end
				end)
			end

			kbInvCheckRestore()

			if not kbSoulNoReturn and v13 then
				pcall(function()
					if v12 and v12.Parent then
						v12:MoveTo(v13.Position)
					end
				end)
			end

			lib:Notify({ Title = "灵魂出窍", Content = "已关闭", Duration = 3 })
		end
	end,
})

tbl10.SecondaryTab:Toggle({
	Title = "灵魂出窍关闭时不回原点",
	Desc = "开启后，关闭灵魂出窍时留在虚体所在位置，默认关闭",
	Default = false,
	Callback = function(arg)
		kbPlayDing()
		kbSoulNoReturn = arg
		lib:Notify({ Title = "灵魂出窍关闭时不回原点", Content = arg and "已开启" or "已关闭", Duration = 3 })
	end,
})

tbl10.SecondaryTab:Button({
	Title = "自动翻译",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "自动翻译", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/自动翻译"))()
		end)
	end,
})

tbl10.SecondaryTab:Button({
	Title = "传送最近玩家",
	Callback = function()
		kbPlayDing()
		local character = localPlayer2.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			lib:Notify({ Title = "传送", Content = "你的角色未加载", Duration = 3 })
			return
		end
		local position = character.HumanoidRootPart.Position
		local huge = math.huge
		local v12 = nil

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer2 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local magnitude = (player.Character.HumanoidRootPart.Position - position).Magnitude

				if magnitude < huge then
					huge = magnitude
					v12 = player
				end
			end
		end

		if v12 and v12.Character and v12.Character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = v12.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 3)
			lib:Notify({ Title = "传送", Content = "已传送到 " .. v12.Name, Duration = 3 })
		else
			lib:Notify({ Title = "传送", Content = "未找到其他玩家", Duration = 3 })
		end
	end,
})

local v12 = nil

tpDropdown = tbl10.SecondaryTab:Dropdown({
	Title = "选定传送玩家",
	Values = {},
	Callback = function(arg)
		if v12 and v12.Name == arg then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == arg and player ~= localPlayer2 then
				v12 = player
				break
			end
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "确定传送到此人",
	Callback = function()
		kbPlayDing()

		if v12 and v12.Parent and v12.Character and v12.Character:FindFirstChild("HumanoidRootPart") then
			fn27(v12)
			lib:Notify({ Title = "传送", Content = "已传送到 " .. v12.Name, Duration = 3 })
		else
			lib:Notify({ Title = "传送", Content = "请先选择玩家", Duration = 3 })
		end
	end,
})

local tbl13 = {}
local n9 = 0
local tbl14 = {}
local flag19 = false

local function fn45(arg)
	return "标点" .. tostring(arg)
end

local function fn46()
	if not markerDropdown then
		return
	end
	local tbl15 = {}

	for _, v13 in ipairs(tbl13) do
		table.insert(tbl15, v13.name)
	end

	markerDropdown:Refresh(tbl15)
end

local function fn47(arg)
	local character = localPlayer2.Character

	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = CFrame.new(arg.pos)
	end
end

tbl10.SecondaryTab:Button({
	Title = "保存标点",
	Callback = function()
		kbPlayDing()
		local character = localPlayer2.Character
		character = character and character:FindFirstChild("HumanoidRootPart")
		if not character then
			lib:Notify({ Title = "标点", Content = "你的角色未加载", Duration = 3 })
			return
		end
		n9 += 1
		local v13 = fn45(n9)
		local part = Instance.new("Part")
		part.Name = v13
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.one
		part.CFrame = CFrame.new(character.Position - Vector3.new(0, 2.5, 0))
		part.Parent = workspace
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "MarkerLabel"
		billboardGui.Size = UDim2.new(0, 100, 0, 40)
		billboardGui.StudsOffset = Vector3.new(0, 1, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.Parent = part
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = v13
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextSize = 18
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Parent = billboardGui
		table.insert(tbl13, { name = v13, pos = character.Position, part = part })
		fn46()
		lib:Notify({ Title = "标点", Content = "已保存 " .. v13, Duration = 3 })
	end,
})

markerDropdown = tbl10.SecondaryTab:Dropdown({
	Title = "选定标点（可多选）",
	Values = {},
	Multi = true,
	Callback = function(arg)
		tbl14 = {}

		if type(arg) == "table" then
			for k, v13 in pairs(arg) do
				if type(k) == "number" then
					tbl14[v13] = true
				elseif v13 then
					tbl14[k] = true
				end
			end
		elseif type(arg) == "string" then
			tbl14[arg] = true
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "传送标记点",
	Callback = function()
		kbPlayDing()

		task.spawn(function()
			local n10 = 0

			for _, v13 in ipairs(tbl13) do
				if tbl14[v13.name] then
					fn47(v13)
					n10 += 1
					task.wait(0.5)
				end
			end

			if n10 == 0 then
				lib:Notify({ Title = "标点", Content = "请先选定标点", Duration = 3 })
			end
		end)
	end,
})

tbl10.SecondaryTab:Toggle({
	Title = "全部循环传送",
	Value = false,
	Callback = function(arg)
		flag19 = arg

		if arg then
			task.spawn(function()
				while flag19 do
					local n10 = 0

					for _, v13 in ipairs(tbl13) do
						if flag19 then
							if tbl14[v13.name] then
								fn47(v13)
								n10 += 1
								task.wait(0.5)
							end

							continue
						end

						break
					end

					if n10 == 0 then
						task.wait(0.5)
					end
				end
			end)
		end

		lib:Notify({ Title = "全部循环传送", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

local v13 = nil

lockDropdown = tbl10.SecondaryTab:Dropdown({
	Title = "选定锁人玩家",
	Values = {},
	Callback = function(arg)
		if v13 and v13.Name == arg then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == arg and player ~= localPlayer2 then
				v13 = player
				break
			end
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "确定执行锁人",
	Callback = function()
		kbPlayDing()

		if v13 and v13.Parent then
			lib:Notify({ Title = "锁人", Content = "已选定 " .. v13.Name .. "，开始锁人", Duration = 3 })
			fn20(v13)
		else
			lib:Notify({ Title = "锁人", Content = "请先选择玩家", Duration = 3 })
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "停止锁人",
	Callback = function()
		kbPlayDing()
		fn21()
		v13 = nil

		if lockDropdown then
			pcall(function()
				lockDropdown:Select(nil)
			end)
		end
	end,
})

local v14 = tbl10.SecondaryTab:Slider({
	Title = "锁人距离 (当前: 1.5m)",
	Value = { Min = 0, Max = 10, Default = 1.5 },
	Callback = function(range)
		tbl8.range = range
		tbl.lockrange = range
	end,
})

handlers.lockrange = function(arg)
	kbPlayDing()
	lib:Notify({ Title = "锁人距离", Content = "已设置为：" .. arg .. "m", Duration = 2 })
end

tbl10.SecondaryTab:Input({
	Title = "输入锁人距离",
	Placeholder = "0 - 10",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		kbPlayDing()
		local n10 = math.floor(num * 100) / 100

		if n10 > 10 then
			n10 = 10
		end

		if n10 < 0 then
			n10 = 0
		end

		v14:Set(n10)
		tbl.lockrange = nil
		handlers.lockrange(n10)
	end,
})

tbl10.SecondaryTab:Toggle({
	Title = "面朝他",
	Value = false,
	Callback = function(faceTarget)
		kbPlayDing()
		tbl8.faceTarget = faceTarget
		lib:Notify({ Title = "面朝他", Content = faceTarget and "已开启" or "已关闭", Duration = 3 })
	end,
})

tbl10.SecondaryTab:Toggle({
	Title = "下陷",
	Value = false,
	Callback = function(sink)
		kbPlayDing()
		tbl8.sink = sink
		lib:Notify({ Title = "下陷", Content = sink and "已开启" or "已关闭", Duration = 3 })
	end,
})

local v15 = tbl10.SecondaryTab:Slider({
	Title = "下陷深度 (当前: 0m)",
	Value = { Min = 0, Max = 5, Default = 0 },
	Callback = function(sinkDepth)
		tbl8.sinkDepth = sinkDepth
		tbl.locksink = sinkDepth
	end,
})

handlers.locksink = function(arg)
	kbPlayDing()
	lib:Notify({ Title = "下陷深度", Content = "已设置为：" .. arg .. "m", Duration = 2 })
end

tbl10.SecondaryTab:Input({
	Title = "输入下陷深度",
	Placeholder = "0 - 5",
	Callback = function(arg)
		local num = tonumber(arg)
		if not num then
			return
		end
		kbPlayDing()
		local n10 = math.floor(num * 100) / 100

		if n10 > 5 then
			n10 = 5
		end

		if n10 < 0 then
			n10 = 0
		end

		v15:Set(n10)
		tbl.locksink = nil
		handlers.locksink(n10)
	end,
})

tbl10.SecondaryTab:Button({
	Title = "复制当前坐标",
	Callback = function()
		kbPlayDing()
		local character = localPlayer2.Character

		if character and character:FindFirstChild("HumanoidRootPart") then
			local position = character.HumanoidRootPart.Position
			fn38(string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z), "坐标")
		else
			lib:Notify({ Title = "坐标", Content = "角色未加载", Duration = 3 })
		end
	end,
})

local str4 = ""

tbl10.SecondaryTab:Input({
	Title = "输入坐标 (X,Y,Z)",
	Placeholder = "例如: 100, 50, 200",
	Callback = function(arg)
		if not arg or arg == "" then
			return
		end
		kbPlayDing()
		str4 = arg
	end,
})

tbl10.SecondaryTab:Button({
	Title = "执行坐标传送",
	Callback = function()
		kbPlayDing()
		if not str4 or str4 == "" then
			return
		end
		local tbl15 = {}

		for match in str4:gmatch("[^,]+") do
			local insert = table.insert
			local v16 = table.pack(tonumber(match:match("%S+")))
			insert(tbl15, table.unpack(v16, 1, v16.n))
		end

		if #tbl15 >= 3 and tbl15[1] and tbl15[2] and tbl15[3] then
			local character = localPlayer2.Character

			if character and character:FindFirstChild("HumanoidRootPart") then
				character.HumanoidRootPart.CFrame = CFrame.new(tbl15[1], tbl15[2], tbl15[3])
			end
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "爬墙",
	Callback = function()
		kbPlayDing()
		loadstring(game:HttpGet("https://pastebin.com/raw/zXk4Rq2r"))()
	end,
})

tbl10.SecondaryTab:Button({
	Title = "撸管",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "撸管", Content = "正在生成工具...", Duration = 3 })

		task.spawn(function()
			fn32()
		end)
	end,
})

local v16 = nil

harassDropdown = tbl10.SecondaryTab:Dropdown({
	Title = "选定操人目标",
	Values = {},
	Callback = function(arg)
		if v16 and v16.Name == arg then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == arg and player ~= localPlayer2 then
				v16 = player
				break
			end
		end
	end,
})

fn44()

tbl10.SecondaryTab:Button({
	Title = "确定执行操人",
	Callback = function()
		kbPlayDing()

		if v16 and v16.Parent then
			lib:Notify({ Title = "操人", Content = "已选定 " .. v16.Name .. "，开始操人", Duration = 3 })
			v = v16
			flag14 = true
			fn33()
		else
			lib:Notify({ Title = "操人", Content = "请先选择玩家", Duration = 3 })
		end
	end,
})

tbl10.SecondaryTab:Button({
	Title = "停止操人",
	Callback = function()
		kbPlayDing()
		fn34()
		v16 = nil
	end,
})

tbl10.SecondaryTab:Slider({
	Title = "操人速度 (当前: 5)",
	Value = { Min = 1, Max = 20, Default = 5 },
	Callback = function(harassspeed)
		tbl.harassspeed = harassspeed
	end,
})

handlers.harassspeed = function(arg)
	kbPlayDing()
	n6 = arg
	lib:Notify({ Title = "操人速度", Content = "已设置为：" .. arg .. " 次/秒", Duration = 2 })
end

tbl10.SecondaryTab:Button({
	Title = "操最近的人",
	Callback = function()
		kbPlayDing()

		if flag14 then
			fn34()
		else
			local v17 = fn28()

			if v17 then
				v = v17
				flag14 = true
				fn33()
				lib:Notify({ Title = "操人", Content = "开始疯狂操 " .. v17.Name .. "！", Duration = 3 })
			else
				lib:Notify({ Title = "操人", Content = "未找到其他玩家", Duration = 3 })
			end
		end
	end,
})

tbl10.SecondaryTab:Toggle({
	Title = "原地旋转",
	Value = false,
	Callback = function(arg)
		flag9 = arg

		if arg then
			fn14()
		else
			fn15()
		end

		lib:Notify({ Title = "原地旋转", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.SecondaryTab:Slider({
	Title = "旋转速度 (当前: 360)",
	Value = { Min = 1, Max = 10000, Default = 360 },
	Callback = function(spinspeed)
		tbl.spinspeed = spinspeed
	end,
})

handlers.spinspeed = function(arg)
	kbPlayDing()
	n4 = arg
	lib:Notify({ Title = "旋转速度", Content = "已设置为：" .. arg .. " 度/秒", Duration = 2 })
end

local flag20 = false
local y = nil
local v17 = nil
local connection10 = nil
local v18 = nil

local function fn48()
	if v17 then
		pcall(function()
			v17:Destroy()
		end)

		v17 = nil
	end
end

local function fn49()
	if connection10 then
		connection10:Disconnect()
		connection10 = nil
	end

	fn48()
	y = nil
	v18 = nil
end

tbl10.SecondaryTab:Toggle({
	Title = "踏空行走",
	Value = false,
	Callback = function(arg)
		flag20 = arg

		if arg then
			local character = localPlayer2.Character
			local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
			character = character and character:FindFirstChildOfClass("Humanoid")

			if not humanoidRootPart or not character then
				lib:Notify({ Title = "踏空行走", Content = "未找到人物，开启失败", Duration = 3 })
				flag20 = false
				return
			end

			y = humanoidRootPart.Position.Y
			local n10 = (character.HipHeight or 2) + humanoidRootPart.Size.Y / 2

			connection10 = RunService.Heartbeat:Connect(function()
				if not flag20 then
					return
				end
				local character2 = localPlayer2.Character
				character2 = character2 and character2:FindFirstChild("HumanoidRootPart")

				if not character2 then
					fn48()
					v18 = nil
					return
				end

				local position = character2.Position

				if math.abs(position.Y - y) > 3 then
					fn48()
					v18 = nil
					return
				end

				if v18 and (Vector2.new(position.X, position.Z) - Vector2.new(v18.X, v18.Z)).Magnitude < 0.5 then
					return
				end
				fn48()
				local part = Instance.new("Part")
				part.Name = "AirWalkPlatform"
				part.Size = Vector3.new(6, 1, 6)
				part.Anchored = true
				part.CanCollide = true
				part.Transparency = 0.6
				part.Color = Color3.fromRGB(120, 120, 255)
				part.CFrame = CFrame.new(position.X, y - n10 - 0.55, position.Z)
				part.Parent = workspace
				v17 = part
				v18 = position
			end)

			lib:Notify({ Title = "踏空行走", Content = "已开启，锁定高度：" .. string.format("%.1f", y), Duration = 3 })
			kbPlayDing()
		else
			fn49()
			lib:Notify({ Title = "踏空行走", Content = "已关闭", Duration = 3 })
		end
	end,
})

localPlayer2.CharacterAdded:Connect(function()
	if flag20 then
		fn49()
		flag20 = false
	end
end)

local str5 = ""
local sound = nil
local clone = nil

tbl10.MiscTab:Toggle({
	Title = "修改天空盒子（有两秒延迟）",
	Value = false,
	Callback = function(arg)
		local Lighting = game:GetService("Lighting")

		if arg then
			local sky = Lighting:FindFirstChildOfClass("Sky")

			if sky and not clone then
				clone = sky:Clone()
			end

			if sky then
				sky:Destroy()
			end

			local sky2 = Instance.new("Sky")
			sky2.SkyboxBk = "rbxassetid://113517588654522"
			sky2.SkyboxDn = "rbxassetid://113517588654522"
			sky2.SkyboxFt = "rbxassetid://113517588654522"
			sky2.SkyboxLf = "rbxassetid://113517588654522"
			sky2.SkyboxRt = "rbxassetid://113517588654522"
			sky2.SkyboxUp = "rbxassetid://113517588654522"
			sky2.Parent = Lighting
			lib:Notify({ Title = "天空盒子", Content = "已修改（仅自己可见）", Duration = 3 })
			kbPlayDing()
		else
			local sky = Lighting:FindFirstChildOfClass("Sky")

			if sky then
				sky:Destroy()
			end

			if clone then
				clone.Parent = Lighting
				clone = nil
			end

			lib:Notify({ Title = "天空盒子", Content = "已恢复", Duration = 3 })
		end
	end,
})

tbl10.MiscTab:Input({
	Title = "输入音乐ID",
	Placeholder = "输入音乐ID",
	Callback = function(arg)
		if not arg or arg == "" then
			return
		end
		kbPlayDing()
		str5 = arg
	end,
})

tbl10.MiscTab:Button({
	Title = "确认播放",
	Callback = function()
		kbPlayDing()
		local str6 = tostring(str5):gsub("%D", "")
		if str6 == "" then
			lib:Notify({ Title = "音乐", Content = "请先输入音乐ID", Duration = 3 })
			return
		end

		if sound and sound.SoundId == "rbxassetid://" .. str6 and sound.IsPaused then
			sound:Resume()
			lib:Notify({ Title = "音乐", Content = "继续播放: " .. str6, Duration = 3 })
			return
		end

		if sound then
			sound:Destroy()
			sound = nil
		end

		sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. str6
		sound.Volume = 1
		sound.Looped = true
		sound.Parent = localPlayer2:WaitForChild("PlayerGui")
		sound:Play()
		lib:Notify({ Title = "音乐", Content = "正在播放: " .. str6, Duration = 3 })
	end,
})

tbl10.MiscTab:Button({
	Title = "取消播放",
	Callback = function()
		kbPlayDing()

		if sound then
			sound:Stop()
			sound:Destroy()
			sound = nil
			lib:Notify({ Title = "音乐", Content = "已取消播放", Duration = 3 })
		else
			lib:Notify({ Title = "音乐", Content = "当前没有播放的音乐", Duration = 3 })
		end
	end,
})

tbl10.MiscTab:Button({
	Title = "停止播放",
	Callback = function()
		kbPlayDing()

		if sound then
			sound:Pause()
			lib:Notify({ Title = "音乐", Content = "已暂停，点确认播放继续", Duration = 3 })
		else
			lib:Notify({ Title = "音乐", Content = "当前没有播放的音乐", Duration = 3 })
		end
	end,
})

tbl10.MiscTab:Button({
	Title = "实体动作游泳",
	Desc = "先点击此按钮一次之后点击飞，然后再点击此按钮一次",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "实体动作游泳", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/fly.lua"))()
		end)
	end,
})

tbl10.MiscTab:Button({
	Title = "显示时间",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "显示时间", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://pastebin.com/raw/0zKLyd4W"))()
		end)
	end,
})

tbl10.MiscTab:Button({
	Title = "美化包排行榜第一",
	Callback = function()
		kbPlayDing()
		fn26()
		lib:Notify({ Title = "美化包", Content = "数值已修改为999（若游戏支持）", Duration = 3 })
	end,
})

tbl10.MiscTab:Toggle({
	Title = "准星",
	Value = false,
	Callback = function(arg)
		flag7 = arg

		if arg then
			fn23()
		else
			fn24()
		end

		lib:Notify({ Title = "准星", Content = arg and "已显示" or "已隐藏", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Toggle({
	Title = "准星旋转",
	Value = false,
	Callback = function(arg)
		flag8 = arg
		lib:Notify({ Title = "准星旋转", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Toggle({
	Title = "反挂机踢出",
	Value = false,
	Callback = function(arg)
		flag10 = arg

		if arg then
			fn16()
		else
			fn17()
		end

		lib:Notify({ Title = "反挂机踢出", Content = arg and "已开启" or "已关闭", Duration = 3 })

		if arg then
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Button({
	Title = "复制实例ID (JobId)",
	Callback = function()
		kbPlayDing()
		fn38(game.JobId, "实例ID")
	end,
})

local str6 = ""

tbl10.MiscTab:Input({
	Title = "实例ID传送",
	Placeholder = "输入实例ID (JobId)",
	Callback = function(arg)
		if not arg or arg == "" then
			return
		end
		kbPlayDing()
		str6 = arg
	end,
})

tbl10.MiscTab:Button({
	Title = "执行实例ID传送",
	Callback = function()
		kbPlayDing()
		if not str6 or str6 == "" then
			lib:Notify({ Title = "实例ID传送", Content = "请先输入实例ID", Duration = 3 })
			return
		end
		lib:Notify({ Title = "实例ID传送", Content = "正在传送...", Duration = 5 })

		pcall(function()
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, str6, localPlayer2)
		end)
	end,
})

tbl10.MiscTab:Button({
	Title = "复制数字ID (PlaceId)",
	Callback = function()
		kbPlayDing()
		fn38(tostring(game.PlaceId), "数字ID")
	end,
})

tbl10.MiscTab:Input({
	Title = "数字ID传送",
	Placeholder = "输入PlaceId，例如: 286090429",
	Callback = function(arg)
		if not arg or arg == "" then
			return
		end
		local num = tonumber(arg)

		if num then
			kbPlayDing()
			lib:Notify({ Title = "数字ID传送", Content = "正在传送到 PlaceId: " .. tostring(num) .. " ...", Duration = 5 })

			pcall(function()
				game:GetService("TeleportService"):Teleport(num, localPlayer2)
			end)
		else
			lib:Notify({ Title = "传送失败", Content = "请输入有效的数字ID", Duration = 3 })
		end
	end,
})

tbl10.MiscTab:Divider()
local str7 = "你被踢出了游戏"
local str8 = ""

tbl10.MiscTab:Input({
	Title = "自定义踢出内容",
	Placeholder = "输入踢出内容",
	Callback = function(arg)
		if arg and arg ~= "" then
			str7 = arg
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Input({
	Title = "自定义错误代码",
	Placeholder = "输入错误代码，例如: 267",
	Callback = function(arg)
		if arg and arg ~= "" then
			kbPlayDing()
			str8 = arg
		end
	end,
})

tbl10.MiscTab:Button({
	Title = "执行自定义踢出",
	Callback = function()
		kbPlayDing()
		local v19 = str7

		if str8 and str8 ~= "" then
			v19 ..= "\n\n（错误代码：" .. str8 .. "）"
		end

		localPlayer2:Kick(v19)
	end,
})

tbl10.MiscTab:Divider()
local str9 = "确认操作"
local str10 = "你确定要执行此操作吗？"

tbl10.MiscTab:Input({
	Title = "弹窗标题",
	Placeholder = "输入弹窗标题",
	Callback = function(arg)
		if arg and arg ~= "" then
			str9 = arg
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Input({
	Title = "弹窗内容",
	Placeholder = "输入弹窗内容",
	Callback = function(arg)
		if arg and arg ~= "" then
			str10 = arg
			kbPlayDing()
		end
	end,
})

tbl10.MiscTab:Button({
	Title = "弹出确认窗口",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = str9, Content = str10, Duration = 10 })
	end,
})

tbl10.MiscTab:Divider()

tbl10.MiscTab:Button({
	Title = "坐下",
	Callback = function()
		kbPlayDing()

		pcall(function()
			game.Players.LocalPlayer.Character.Humanoid.Sit = true
		end)
	end,
})

tbl10.GamesTab:Button({
	Title = "复制加载器代码",
	Callback = function()
		kbPlayDing()
		fn38("loadstring(game:HttpGet(\"https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/汪脚本加载器\"))()", "加载器代码")
	end,
})

tbl10.GamesTab:Button({
	Title = "执行加载器",
	Desc = "根据你所在的服务器加载对应的汪脚本支持服务器",
	Callback = function()
		kbPlayDing()
		lib:Notify({ Title = "执行加载器", Content = "正在加载中...", Duration = 5 })

		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/汪脚本加载器"))()
		end)
	end,
})

tbl10.GamesTab:Divider()
local str11 = "加载中..."
local v19 = nil

task.spawn(function()
	local ok, result = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/支持服务器")
	end)

	if ok and result and result ~= "" then
		str11 = result
	else
		str11 = "加载失败，请检查链接"
	end

	if v19 then
		pcall(function()
			v19:SetDesc(str11)
		end)
	end
end)

v19 = tbl10.GamesTab:Paragraph({ Title = "汪脚本支持的服务器：", Desc = str11 })

tbl10.GamesTab:Paragraph({
	Title = "汪脚本--通用",
	Desc = "作者：汪拜大帝",
	Image = "rbxassetid://113517588654522",
	ImageSize = 60,
	Thumbnail = "rbxassetid://113517588654522",
	ThumbnailSize = 220,
})

v2:OnClose(function()
	print("界面已关闭。")
end)

task.spawn(function()
	local flag21 = false

	tbl10.SettingsTab:Toggle({
		Title = "关闭启动音效",
		Desc = "需要保存配置使用",
		Value = false,
		Callback = function(arg)
			flag21 = arg
			lib:Notify({ Title = "关闭启动音效", Content = arg and "启动音效已静音" or "启动音效已恢复", Duration = 3 })

			if arg then
				kbPlayDing()
			end
		end,
	})

	tbl10.SettingsTab:Toggle({
		Title = "关闭按钮音效",
		Desc = "需要保存配置使用",
		Value = false,
		Callback = function(arg)
			kbToggleSoundMuted = arg
			lib:Notify({ Title = "关闭按钮音效", Content = arg and "按钮音效已静音" or "按钮音效已恢复", Duration = 3 })

			if arg then
				kbPlayDing()
			end
		end,
	})

	tbl10.SettingsTab:Toggle({
		Title = "关闭开头弹窗音效",
		Desc = "需要保存配置使用",
		Value = false,
		Callback = function(arg)
			flag = arg
			lib:Notify({ Title = "关闭开头弹窗音效", Content = arg and "开头弹窗音效已静音" or "开头弹窗音效已恢复", Duration = 3 })

			if arg then
				kbPlayDing()
			end
		end,
	})

	local v20 = nil
	local v21 = nil
	local v22 = nil
	local v23 = nil

	local function fn50()
		local v24 = kbListConfigs()

		if v21 then
			v21.Values = v24

			pcall(function()
				v21:Refresh(v24)
			end)
		end

		if v22 then
			v22.Values = v24

			pcall(function()
				v22:Refresh(v24)
			end)
		end

		if v23 then
			v23.Values = v24

			pcall(function()
				v23:Refresh(v24)
			end)
		end
	end

	local str12 = ""

	tbl10.SettingsTab:Input({
		Title = "输入配置名字",
		Placeholder = "配置名字",
		Callback = function(arg)
			if not arg or arg == "" then
				return
			end
			kbPlayDing()
			str12 = arg
		end,
	})

	tbl10.SettingsTab:Button({
		Title = "保存当前配置",
		Callback = function()
			kbPlayDing()
			if not str12 or str12 == "" then
				lib:Notify({ Title = "保存当前配置", Content = "请先在上面输入配置名字", Duration = 3 })
				return
			end

			local ok, result = pcall(function()
				kbSaveConfig(str12)
			end)

			if ok then
				lib:Notify({ Title = "保存当前配置", Content = "已保存配置：" .. str12, Duration = 3 })
				fn50()
			else
				lib:Notify({ Title = "保存当前配置", Content = "保存失败：" .. tostring(result), Duration = 3 })
			end
		end,
	})

	v21 = tbl10.SettingsTab:Dropdown({
		Title = "选择配置",
		Values = kbListConfigs(),
		Callback = function(arg)
			v20 = arg
		end,
	})

	tbl10.SettingsTab:Button({
		Title = "加载配置",
		Callback = function()
			kbPlayDing()
			if not v20 then
				lib:Notify({ Title = "加载配置", Content = "请先在上面选择一个配置", Duration = 3 })
				return
			end
			local v24 = v20

			if kbLoadConfig(v24) then
				lib:Notify({ Title = "加载配置", Content = "已加载配置：" .. v24, Duration = 3 })
			else
				lib:Notify({ Title = "加载配置", Content = "加载失败：" .. v24, Duration = 3 })
			end

			v20 = nil

			pcall(function()
				v21:Select(nil)
			end)
		end,
	})

	local v24 = nil
	local str13 = kbCfgFolder .. "/autoload.txt"

	if isfile and isfile(str13) then
		local v25 = readfile(str13)

		if v25 and v25 ~= "" then
			v24 = v25
		end
	end

	v22 = tbl10.SettingsTab:Dropdown({
		Title = "自动加载配置",
		Values = kbListConfigs(),
		Callback = function(arg)
			v24 = arg
		end,
	})

	local v25 = nil

	v25 = tbl10.SettingsTab:Toggle({
		Title = "自动加载",
		Value = v24 ~= nil,
		Callback = function(arg)
			if arg then
				if not v24 then
					lib:Notify({ Title = "自动加载", Content = "请先在上面选择一个配置", Duration = 3 })

					if v25 then
						pcall(function()
							v25:Set(false)
						end)
					end

					return
				end

				writefile(str13, v24)
				lib:Notify({ Title = "自动加载", Content = "已设置自动加载配置：" .. v24, Duration = 3 })
				kbPlayDing()
			else
				pcall(function()
					if isfile(str13) then
						delfile(str13)
					end
				end)

				lib:Notify({ Title = "自动加载", Content = "已关闭自动加载", Duration = 3 })
			end
		end,
	})

	local tbl15 = {}

	v23 = tbl10.SettingsTab:Dropdown({
		Title = "删除配置",
		Values = kbListConfigs(),
		Multi = true,
		Callback = function(arg)
			tbl15 = arg
		end,
	})

	tbl10.SettingsTab:Button({
		Title = "删除此配置",
		Callback = function()
			kbPlayDing()
			local tbl16 = {}

			if type(tbl15) == "table" then
				for _, v26 in pairs(tbl15) do
					if type(v26) == "table" and v26.Title then
						table.insert(tbl16, v26.Title)
					elseif type(v26) == "string" then
						table.insert(tbl16, v26)
					end
				end
			elseif type(tbl15) == "string" then
				table.insert(tbl16, tbl15)
			end

			if #tbl16 == 0 then
				lib:Notify({ Title = "删除此配置", Content = "请先在上面选择一个或多个配置", Duration = 3 })
				return
			end
			local n10 = 0

			for _, v26 in ipairs(tbl16) do
				local str14 = kbCfgFolder .. "/" .. v26 .. ".json"

				pcall(function()
					if isfile(str14) then
						delfile(str14)
						n10 += 1
					end
				end)

				if v24 == v26 then
					v24 = nil

					pcall(function()
						if isfile(str13) then
							delfile(str13)
						end
					end)

					pcall(function()
						v25:Set(false)
					end)
				end
			end

			lib:Notify({ Title = "删除此配置", Content = "已删除 " .. n10 .. " 个配置", Duration = 3 })
			tbl15 = {}

			pcall(function()
				v23:Select(nil)
			end)

			fn50()
		end,
	})

	kbCurrentBg = nil

	kbApplyBackground = function(arg)
		if arg == "默认背景图" then
			if pcall(function()
				local kbBgImage = v2.UIElements.Main.Background:FindFirstChild("KbBgImage")

				if kbBgImage then
					kbBgImage:Destroy()
				end
			end) then
				kbCurrentBg = arg
				lib:Notify({ Title = "切换背景图", Content = "已切换为：" .. arg, Duration = 3 })
			else
				lib:Notify({ Title = "切换背景图", Content = "切换失败", Duration = 3 })
			end

			return
		end

		local tbl16 = {
			["eva背景图"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785339712342_469.jpg",
			["银花背景图1"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785339143310_475.jpg",
			["银花背景图2"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785339141889_101.jpg",
			["银花背景图3"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785339140644_893.jpg",
			["白子背景图"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785395257153_996.jpg",
			["东京喰种背景图"] = "https://raw.githubusercontent.com/kongbaNB/TB/refs/heads/main/Image_1785866305554_326.jpg",
		}

		local function fn51(image)
			local background = v2.UIElements.Main.Background
			local kbBgImage = background:FindFirstChild("KbBgImage")

			if not kbBgImage then
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.Name = "KbBgImage"
				imageLabel.BackgroundTransparency = 1
				imageLabel.Size = UDim2.new(1, 0, 1, 0)
				imageLabel.ScaleType = Enum.ScaleType.Crop
				imageLabel.ImageTransparency = 0
				imageLabel.ZIndex = 1
				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(0, v2.UICorner or 16)
				uiCorner.Parent = imageLabel
				imageLabel.Parent = background
				kbBgImage = imageLabel
			end

			kbBgImage.Image = image
			kbBgImage.Visible = true

			pcall(function()
				v2:SetBackgroundImage(image)
			end)
		end

		if arg == "汪脚本背景图" then
			if pcall(function()
				fn51("rbxassetid://113517588654522")
			end) then
				kbCurrentBg = arg
				lib:Notify({ Title = "切换背景图", Content = "已切换为：" .. arg, Duration = 3 })
			else
				lib:Notify({ Title = "切换背景图", Content = "切换失败", Duration = 3 })
			end

			return
		end

		if tbl16[arg] then
			if pcall(function()
				local str14 = "汪脚本/bg_" .. arg .. ".jpg"

				if makefolder and not isfolder("汪脚本") then
					makefolder("汪脚本")
				end

				if not (isfile and isfile(str14)) then
					local response = game:HttpGet(tbl16[arg])
					writefile(str14, response)
				end

				local v26 = getcustomasset(str14)
				fn51(v26)
			end) then
				kbCurrentBg = arg
				lib:Notify({ Title = "切换背景图", Content = "已切换为：" .. arg, Duration = 3 })
			else
				lib:Notify({ Title = "切换背景图", Content = "切换失败", Duration = 3 })
			end
		end
	end

	local v26 = nil

	local v27 = tbl10.SettingsTab:Dropdown({
		Title = "切换背景图",
		Values = { "默认背景图", "汪脚本背景图", "eva背景图", "东京喰种背景图" },
		Callback = function(arg)
			v26 = arg
		end,
	})

	tbl10.SettingsTab:Button({
		Title = "切换此背景图",
		Callback = function()
			kbPlayDing()
			if not v26 then
				lib:Notify({ Title = "切换此背景图", Content = "请先在上面选择一个背景图", Duration = 3 })
				return
			end
			kbApplyBackground(v26)
			v26 = nil

			pcall(function()
				v27:Select(nil)
			end)
		end,
	})

	local v28 = nil

	local v29 = tbl10.SettingsTab:Dropdown({
		Title = "粉丝定制背景图",
		Desc = "想要定制的进我的群找：空白大帝",
		Values = { "银花背景图1", "银花背景图2", "银花背景图3", "白子背景图" },
		Callback = function(arg)
			v28 = arg
		end,
	})

	tbl10.SettingsTab:Button({
		Title = "切换此定制背景图",
		Callback = function()
			kbPlayDing()
			if not v28 then
				lib:Notify({ Title = "切换此定制背景图", Content = "请先在上面选择一个背景图", Duration = 3 })
				return
			end
			kbApplyBackground(v28)
			v28 = nil

			pcall(function()
				v29:Select(nil)
			end)
		end,
	})

	task.spawn(function()
		task.wait(0.5)

		if isfile and isfile(str13) then
			local v30 = readfile(str13)

			if v30 and v30 ~= "" then
				if kbLoadConfig(v30) then
					lib:Notify({ Title = "配置", Content = "已自动加载配置：" .. v30, Duration = 3 })
				end
			end
		end

		task.wait(0.2)

		if not flag21 and kbTadaAsset then
			pcall(function()
				local sound2 = Instance.new("Sound")
				sound2.SoundId = kbTadaAsset
				sound2.Volume = 2
				sound2.Parent = CoreGui
				sound2:Play()

				sound2.Ended:Connect(function()
					sound2:Destroy()
				end)
			end)
		end
	end)
end)