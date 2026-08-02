-- [[ Delta Stage 15 Auto-Recorder v5.0 - مع خاصية السرعة ]]
-- صنع خصيصًا لأمر المستخدم

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ===== المتغيرات الرئيسية =====
local recordedPath = {}
local isRecording = false
local isReplaying = false
local isLooping = false
local replayIndex = 1
local recordDuration = 60
local winsCount = 0
local replaySpeed = 1 -- مضاعف السرعة (1 = سرعة عادية)

-- ===== إنشاء الواجهة =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 480)
frame.Position = UDim2.new(0.5, -160, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

-- ===== زر الإغلاق (X) =====
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame

-- ===== أيقونة مصغرة =====
local miniIcon = Instance.new("ImageButton")
miniIcon.Size = UDim2.new(0, 50, 0, 50)
miniIcon.Position = UDim2.new(0, 10, 0, 10)
miniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
miniIcon.Image = "rbxassetid://4483345998"
miniIcon.Visible = false
miniIcon.BorderSizePixel = 0
miniIcon.Parent = screenGui

local miniCorners = Instance.new("UICorner")
miniCorners.CornerRadius = UDim.new(1, 0)
miniCorners.Parent = miniIcon

-- ===== عنوان =====
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "⚡ Delta Recorder ⚡"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

-- ===== حقل إدخال السرعة =====
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 0, 30)
speedLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
speedLabel.Text = "السرعة:"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 14
speedLabel.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.4, 0, 0, 30)
speedBox.Position = UDim2.new(0.5, 0, 0.12, 0)
speedBox.Text = "1"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.BorderSizePixel = 0
speedBox.Parent = frame

-- ===== أزرار التحكم =====
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.8, 0, 0, 40)
startBtn.Position = UDim2.new(0.1, 0, 0.22, 0)
startBtn.Text = "▶ بدء التسجيل"
startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.BorderSizePixel = 0
startBtn.Parent = frame

local replayBtn = Instance.new("TextButton")
replayBtn.Size = UDim2.new(0.8, 0, 0, 40)
replayBtn.Position = UDim2.new(0.1, 0, 0.38, 0)
replayBtn.Text = "🔄 تشغيل المسار"
replayBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
replayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
replayBtn.Font = Enum.Font.GothamBold
replayBtn.TextSize = 16
replayBtn.BorderSizePixel = 0
replayBtn.Parent = frame

local loopBtn = Instance.new("TextButton")
loopBtn.Size = UDim2.new(0.8, 0, 0, 40)
loopBtn.Position = UDim2.new(0.1, 0, 0.54, 0)
loopBtn.Text = "♾ وضع التكرار (إيقاف)"
loopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
loopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopBtn.Font = Enum.Font.GothamBold
loopBtn.TextSize = 16
loopBtn.BorderSizePixel = 0
loopBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.8, 0, 0, 40)
stopBtn.Position = UDim2.new(0.1, 0, 0.70, 0)
stopBtn.Text = "⏹ إيقاف الكل"
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 16
stopBtn.BorderSizePixel = 0
stopBtn.Parent = frame

-- ===== حالة النص =====
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0.88, 0)
statusLabel.Text = "⏸ في الانتظار..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = frame

-- ===== وظائف التحكم في الإغلاق =====
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniIcon.Visible = true
end)

miniIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniIcon.Visible = false
end)

-- ===== تحديث السرعة من حقل الإدخال =====
speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newSpeed = tonumber(speedBox.Text)
        if newSpeed and newSpeed > 0 then
            replaySpeed = newSpeed
            statusLabel.Text = "⚡ السرعة مضبوطة: x" .. replaySpeed
            print("[Delta] السرعة مضبوطة على: " .. replaySpeed)
        else
            speedBox.Text = tostring(replaySpeed)
            statusLabel.Text = "⚠️ أدخل رقماً صحيحاً (مثال: 2)"
        end
    end
end)

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

-- ===== دوال إعادة التشغيل مع السرعة =====
local function startReplay()
    if #recordedPath == 0 then
        statusLabel.Text = "❌ لا يوجد مسار مسجل!"
        return
    end
    isReplaying = true
    replayIndex = 1
    statusLabel.Text = "🔄 جاري إعادة التحركات (سرعة x" .. replaySpeed .. ")"
    print("[Delta] بدء إعادة التشغيل بسرعة: " .. replaySpeed)

    -- تطبيق السرعة على الـ Humanoid
    if humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * replaySpeed
    end

    local step = 1
    local speedFactor = replaySpeed

    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            -- تطبيق السرعة عبر تكرار الخطوات أسرع
            for _ = 1, math.floor(speedFactor) do
                if replayIndex <= #recordedPath then
                    rootPart.CFrame = recordedPath[replayIndex].cf
                    replayIndex = replayIndex + 1
                end
            end
            -- التعامل مع الكسور (سرعة غير صحيحة)
            if speedFactor % 1 > 0 then
                step = step + speedFactor % 1
                if step >= 1 then
                    step = step - 1
                    if replayIndex <= #recordedPath then
                        rootPart.CFrame = recordedPath[replayIndex].cf
                        replayIndex = replayIndex + 1
                    end
                end
            end
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

-- ===== ربط الأزرار =====
startBtn.MouseButton1Click:Connect(startRecording)
replayBtn.MouseButton1Click:Connect(startReplay)

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

print("[Delta] السكربت جاهز مع خاصية السرعة!")
