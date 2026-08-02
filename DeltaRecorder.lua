-- [[ Delta Recorder v10.1 - الإصدار العملي ]]
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local recordedPath = {}
local isRecording = false
local isReplaying = false
local isLooping = false
local replayIndex = 1
local recordDuration = 60
local replaySpeed = 1
local winsCount = 0

local function startRecording()
    if isRecording then return end
    recordedPath = {}
    isRecording = true
    print("⏺ بدء التسجيل...")
    
    local conn = game:GetService("RunService").Heartbeat:Connect(function()
        if isRecording then
            table.insert(recordedPath, {
                pos = rootPart.Position,
                cf = rootPart.CFrame
            })
        else
            conn:Disconnect()
        end
    end)
    
    task.wait(recordDuration)
    isRecording = false
    print("✅ تم التسجيل ("..#recordedPath.." نقطة)")
end

local function startReplay()
    if #recordedPath == 0 then
        print("❌ لا يوجد مسار مسجل!")
        return
    end
    if isReplaying then return end
    
    isReplaying = true
    replayIndex = 1
    print("🔄 بدء إعادة التشغيل (سرعة x" .. replaySpeed .. ")")
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            rootPart.CFrame = recordedPath[replayIndex].cf
            replayIndex = replayIndex + 1
        elseif isReplaying and replayIndex > #recordedPath then
            isReplaying = false
            winsCount = winsCount + 1
            print("🏆 انتصار #" .. winsCount)
            if isLooping then
                task.wait(0.5)
                replayIndex = 1
                startReplay()
            end
        end
    end)
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeltaUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 320)
    frame.Position = UDim2.new(0.5, -130, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corners = Instance.new("UICorner")
    corners.CornerRadius = UDim.new(0, 12)
    corners.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚡ Delta Recorder"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local yPos = 0.15
    local function createBtn(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 32)
        btn.Position = UDim2.new(0.1, 0, 0, yPos)
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = frame
        btn.MouseButton1Click:Connect(callback)
        yPos = yPos + 0.11
    end
    
    createBtn("▶ بدء التسجيل", Color3.fromRGB(0, 200, 100), startRecording)
    createBtn("🔄 تشغيل المسار", Color3.fromRGB(0, 150, 255), startReplay)
    
    local loopBtn = createBtn("♾ التكرار (إيقاف)", Color3.fromRGB(200, 150, 0), function()
        isLooping = not isLooping
        loopBtn.Text = isLooping and "♾ التكرار (تشغيل)" or "♾ التكرار (إيقاف)"
        loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 150, 0)
    end)
    
    createBtn("⏹ إيقاف الكل", Color3.fromRGB(200, 50, 50), function()
        isRecording = false
        isReplaying = false
        isLooping = false
        loopBtn.Text = "♾ التكرار (إيقاف)"
        loopBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        print("⏹ تم الإيقاف الكامل")
    end)
end

createUI()
print("⚡ Delta Recorder v10.1 جاهز!")
