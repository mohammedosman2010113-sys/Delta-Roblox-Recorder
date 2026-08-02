-- [[ Delta Stage 15 Auto-Recorder v3.0 ]]
-- صنع خصيصًا لأمر المستخدم
-- يعمل كـ Loader مع واجهة أزرار

local player = game.Players.LocalPlayer
local character = player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- المتغيرات الرئيسية
local recordedPath = {}
local isRecording = false
local isReplaying = false
local isLooping = false
local replayIndex = 1
local recordDuration = 60 -- مدة التسجيل بالثواني (عدلها حسب وقت الوصول للمرحلة 15)
local stageTarget = 15
local winsCount = 0

-- إنشاء واجهة GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- زوايا دائرية
local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

-- عنوان
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "⚡ Delta Recorder ⚡"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

-- زر Start Recording
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.8, 0, 0, 45)
startBtn.Position = UDim2.new(0.1, 0, 0.15, 0)
startBtn.Text = "▶ بدء التسجيل"
startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.BorderSizePixel = 0
startBtn.Parent = frame

-- زر Start Replay
local replayBtn = Instance.new("TextButton")
replayBtn.Size = UDim2.new(0.8, 0, 0, 45)
replayBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
replayBtn.Text = "🔄 تشغيل المسار"
replayBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
replayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
replayBtn.Font = Enum.Font.GothamBold
replayBtn.TextSize = 16
replayBtn.BorderSizePixel = 0
replayBtn.Parent = frame

-- زر Loop Mode
local loopBtn = Instance.new("TextButton")
loopBtn.Size = UDim2.new(0.8, 0, 0, 45)
loopBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
loopBtn.Text = "♾ وضع التكرار (إيقاف)"
loopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
loopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopBtn.Font = Enum.Font.GothamBold
loopBtn.TextSize = 16
loopBtn.BorderSizePixel = 0
loopBtn.Parent = frame

-- زر إيقاف
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.8, 0, 0, 45)
stopBtn.Position = UDim2.new(0.1, 0, 0.75, 0)
stopBtn.Text = "⏹ إيقاف الكل"
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 16
stopBtn.BorderSizePixel = 0
stopBtn.Parent = frame

-- حالة النص
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0.92, 0)
statusLabel.Text = "⏸ في الانتظار..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = frame

-- ===== دوال التسجيل =====
local function startRecording()
    recordedPath = {}
    isRecording = true
    isReplaying = false
    statusLabel.Text = "⏺ جاري التسجيل..."
    print("[Delta] بدء التسجيل")
    
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
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
    statusLabel.Text = "✅ تم التسجيل ("..#recordedPath.." نقطة)"
    print("[Delta] انتهى التسجيل، النقاط: "..#recordedPath)
end

-- ===== دوال إعادة التشغيل =====
local function startReplay()
    if #recordedPath == 0 then
        statusLabel.Text = "❌ لا يوجد مسار مسجل!"
        return
    end
    isReplaying = true
    replayIndex = 1
    statusLabel.Text = "🔄 جاري إعادة التحركات..."
    print("[Delta] بدء إعادة التشغيل")
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            rootPart.CFrame = recordedPath[replayIndex].cf
            replayIndex = replayIndex + 1
        elseif isReplaying and replayIndex > #recordedPath then
            isReplaying = false
            winsCount = winsCount + 1
            statusLabel.Text = "🏆 انتصار #" .. winsCount .. " - إعادة تشغيل..."
            print("[Delta] انتصار #" .. winsCount)
            
            if isLooping then
                task.wait(1)
                startReplay()
            else
                statusLabel.Text = "⏸ انتهى المسار (ضع loop للتكرار)"
            end
        end
    end)
end

-- ===== دوال التحكم =====
startBtn.MouseButton1Click:Connect(function()
    startRecording()
end)

replayBtn.MouseButton1Click:Connect(function()
    startReplay()
end)

loopBtn.MouseButton1Click:Connect(function()
    isLooping = not isLooping
    if isLooping then
        loopBtn.Text = "♾ وضع التكرار (تشغيل)"
        loopBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        statusLabel.Text = "♾ التكرار اللا نهائي مفعل"
    else
        loopBtn.Text = "♾ وضع التكرار (إيقاف)"
        loopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "⏸ تم إيقاف التكرار"
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    isRecording = false
    isReplaying = false
    isLooping = false
    loopBtn.Text = "♾ وضع التكرار (إيقاف)"
    loopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    statusLabel.Text = "⏹ تم الإيقاف الكامل"
    print("[Delta] إيقاف كامل")
end)

-- ===== تشغيل تلقائي عند تحميل السكربت (اختياري) =====
-- startRecording()
-- task.wait(recordDuration)
-- startReplay()
-- isLooping = true

print("[Delta] السكربت جاهز! انتظر أوامرك يا سيدي.")
