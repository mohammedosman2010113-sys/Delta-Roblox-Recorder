-- [[ Delta Recorder v13.0 - نسخة الجوال ]]
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
local replaySpeed = 1
local isPerformanceMode = false
local removeObstacles = false

-- ===== نظام اكتشاف وإزالة العوائق (الوحوش فقط) =====
local function removeMonstersOnly()
    local removedCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- فقط الكائنات التي تحتوي على Humanoid وليست اللاعب
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= character then
            -- التأكد أنه ليس اللاعب
            if obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
                obj:Destroy()
                removedCount = removedCount + 1
                print("🗑️ تم إزالة وحش: " .. obj.Name)
            end
        end
    end
    
    if removedCount > 0 then
        print("✅ تم إزالة " .. removedCount .. " وحش/وحوش")
        statusLabel.Text = "🗑️ تم إزالة " .. removedCount .. " وحش"
    else
        statusLabel.Text = "✅ لا توجد وحوش للإزالة"
    end
    return removedCount
end

-- ===== دوال التسجيل =====
local function startRecording()
    if isRecording then return end
    recordedPath = {}
    isRecording = true
    statusLabel.Text = "⏺ جاري التسجيل..."
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
    statusLabel.Text = "✅ تم التسجيل ("..#recordedPath.." نقطة)"
    print("✅ تم التسجيل ("..#recordedPath.." نقطة)")
end

-- ===== دوال إعادة التشغيل =====
local function startReplay()
    if #recordedPath == 0 then
        statusLabel.Text = "❌ لا يوجد مسار مسجل!"
        return
    end
    if isReplaying then return end
    
    isReplaying = true
    replayIndex = 1
    statusLabel.Text = "🔄 جاري إعادة التحركات (سرعة x" .. replaySpeed .. ")"
    print("🔄 بدء إعادة التشغيل بسرعة: " .. replaySpeed)
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            rootPart.CFrame = recordedPath[replayIndex].cf
            replayIndex = replayIndex + 1
        elseif isReplaying and replayIndex > #recordedPath then
            isReplaying = false
            winsCount = winsCount + 1
            statusLabel.Text = "🏆 انتصار #" .. winsCount
            print("🏆 انتصار #" .. winsCount)
            if isLooping then
                task.wait(0.5)
                replayIndex = 1
                startReplay()
            else
                statusLabel.Text = "⏸ انتهى المسار. شغّل Loop للتكرار."
            end
        end
    end)
end

-- ===== دالة تحسين الأداء =====
local function togglePerformance()
    isPerformanceMode = not isPerformanceMode
    if isPerformanceMode then
        settings().Rendering.QualityLevel = 1
        statusLabel.Text = "⚡ وضع الأداء مفعل (60 فريم)"
    else
        settings().Rendering.QualityLevel = 4
        statusLabel.Text = "⚡ وضع الأداء معطل"
    end
end

-- ===== إنشاء الواجهة (مناسبة للجوال) =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- النافذة الرئيسية (أصغر حجمًا)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 480)
frame.Position = UDim2.new(0.5, -150, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = screenGui

local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

-- شريط العنوان (للسحب باللمس)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

-- عنوان
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Delta Recorder"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- زر الإغلاق (كبير وواضح)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

-- أيقونة مصغرة (أكبر للجوال)
local miniIcon = Instance.new("ImageButton")
miniIcon.Size = UDim2.new(0, 60, 0, 60)
miniIcon.Position = UDim2.new(0, 10, 0, 10)
miniIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
miniIcon.Image = "rbxassetid://4483345998"
miniIcon.Visible = false
miniIcon.BorderSizePixel = 2
miniIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
miniIcon.Parent = screenGui

local miniCorners = Instance.new("UICorner")
miniCorners.CornerRadius = UDim.new(1, 0)
miniCorners.Parent = miniIcon

-- ===== وظيفة السحب (باللمس والفأرة) =====
local dragging = false
local dragStart, startPos

local function startDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = frame.Position
end

local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

local function endDrag(input)
    dragging = false
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        updateDrag(input)
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag(input)
    end
end)

-- ===== عناصر التحكم =====
local yOffset = 55
local function createButton(text, yPos, color, textColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 32)
    btn.Position = UDim2.new(0.1, 0, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = textColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- حقل السرعة
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.3, 0, 0, 30)
speedLabel.Position = UDim2.new(0.05, 0, 0, yOffset)
speedLabel.Text = "السرعة:"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 14
speedLabel.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.4, 0, 0, 30)
speedBox.Position = UDim2.new(0.5, 0, 0, yOffset)
speedBox.Text = "1"
speedBox.TextColor3 = Color3.fromRGB(0, 0, 0)
speedBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.BorderSizePixel = 1
speedBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
speedBox.Parent = frame

speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newSpeed = tonumber(speedBox.Text)
        if newSpeed and newSpeed > 0 then
            replaySpeed = newSpeed
            statusLabel.Text = "⚡ السرعة: x" .. replaySpeed
        else
            speedBox.Text = tostring(replaySpeed)
        end
    end
end)

yOffset = yOffset + 42

-- أزرار التحكم (بحجم مناسب للجوال)
createButton("▶ تسجيل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startRecording)
yOffset = yOffset + 38

createButton("🔄 تشغيل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startReplay)
yOffset = yOffset + 38

local loopBtn = createButton("♾ تكرار (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isLooping = not isLooping
    loopBtn.Text = isLooping and "♾ تكرار (تشغيل)" or "♾ تكرار (إيقاف)"
    loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
    statusLabel.Text = isLooping and "♾ تكرار مفعل" or "⏸ تكرار معطل"
end)
yOffset = yOffset + 38

-- زر إزالة الوحوش (وليس كل العوائق)
local removeBtn = createButton("🗑️ إزالة الوحوش", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    removeMonstersOnly()
end)
yOffset = yOffset + 38

createButton("⚡ تحسين الأداء", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    togglePerformance()
end)
yOffset = yOffset + 38

createButton("⏹ إيقاف الكل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isRecording = false
    isReplaying = false
    isLooping = false
    loopBtn.Text = "♾ تكرار (إيقاف)"
    loopBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "⏹ تم الإيقاف"
end)
yOffset = yOffset + 38

-- حالة النص
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, yOffset + 10)
statusLabel.Text = "⏸ في الانتظار..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = frame

-- ===== وظائف الإغلاق =====
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniIcon.Visible = true
end)

miniIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniIcon.Visible = false
end)

print("⚡ Delta Recorder v13.0 جاهز (نسخة الجوال)")
