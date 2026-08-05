-- Delta Recorder v3.0 - للجوال (بأمر المستخدم)
local player = game.Players.LocalPlayer
local character = player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- متغيرات التسجيل
local recorded = {}
local isRecording = false
local isReplaying = false
local index = 1
local targetStage = 15
local wins = 0

-- إنشاء واجهة جوال مصغرة
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 120, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(255, 0, 50)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- صورة مصغرة (زر التشغيل)
local imageButton = Instance.new("ImageButton")
imageButton.Size = UDim2.new(0, 40, 0, 40)
imageButton.Position = UDim2.new(0, 5, 0, 5)
imageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
imageButton.BackgroundTransparency = 1
imageButton.Image = "rbxassetid://6031092155" -- أيقونة تشغيل
imageButton.Parent = frame

-- زر إعادة الضبط (Reset)
local resetButton = Instance.new("ImageButton")
resetButton.Size = UDim2.new(0, 30, 0, 30)
resetButton.Position = UDim2.new(0, 70, 0, 10)
resetButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
resetButton.BackgroundTransparency = 1
resetButton.Image = "rbxassetid://6031092155" -- يمكن تغيير الأيقونة
resetButton.Parent = frame

-- نص حالة التشغيل
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 100, 0, 15)
statusLabel.Position = UDim2.new(0, 10, 0, -20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏹ جاهز"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = frame

-- دالة بدء التسجيل (يعتمد على التحركات الفعلية حتى المرحلة 15)
local function startRecordingUntilStage15()
    recorded = {}
    isRecording = true
    isReplaying = false
    statusLabel.Text = "⏺ تسجيل..."
    print("⏺ [Delta] بدء التسجيل حتى المرحلة 15")
    
    local stageReached = false
    local conn
    
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if not isRecording then 
            conn:Disconnect()
            return 
        end
        
        -- تسجيل التحركات
        table.insert(recorded, {
            pos = rootPart.Position,
            cf = rootPart.CFrame
        })
        
        -- التحقق من الوصول للمرحلة 15 (افترض أن هناك متغير stage أو قيمة)
        -- هنا نضع شرط وهمي، يمكن تعديله حسب اللعبة
        -- مثال: إذا كان هناك متغير عالمي stageValue
        local stageValue = _G.Stage or 0 -- غيّر حسب اللعبة
        if stageValue >= targetStage then
            stageReached = true
            wins = wins + 1
            print("🎯 [Delta] تم الوصول للمرحلة 15! الانتصارات: "..wins)
            isRecording = false
            conn:Disconnect()
            statusLabel.Text = "✅ مرحله 15 - انتصارات: "..wins
            task.wait(1)
            -- إعادة المحاولة تلقائياً
            resetGame() -- دالة افتراضية لإعادة الضبط
        end
    end)
end

-- دالة إعادة الضبط (حسب اللعبة)
local function resetGame()
    -- يمكن وضع كود إعادة التشغيل هنا مثلاً:
    -- player.Character.Humanoid.Health = 0
    -- أو استدعاء حدث معين
    print("♻️ [Delta] إعادة المحاولة...")
    task.wait(1)
    -- بعد إعادة الضبط نبدأ تسجيل جديد
    startRecordingUntilStage15()
end

-- دالة تشغيل التسجيل من البداية
local function executeDelta()
    wins = 0
    startRecordingUntilStage15()
end

-- أزرار الواجهة
imageButton.MouseButton1Click:Connect(function()
    if not isRecording and not isReplaying then
        executeDelta()
    end
end)

resetButton.MouseButton1Click:Connect(function()
    if isRecording or isReplaying then
        isRecording = false
        isReplaying = false
        statusLabel.Text = "⏹ توقف"
        print("⏹ [Delta] إيقاف يدوي")
    end
    recorded = {}
    wins = 0
    statusLabel.Text = "⏹ جاهز"
end)

-- دمج السكربت الإضافي (لوحة المفاتيح العربية)
local keyboardScript = loadstring(game:HttpGet("https://raw.githubusercontent.com/law00a0-wq/loader.lua/refs/heads/main/Keyboard-Arabic"))()
if keyboardScript then
    print("⌨️ [Delta] تم تحميل لوحة المفاتيح العربية")
end

-- تسجيل عند الضغط على F9 (للاختبار)
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F9 then
        executeDelta()
    end
end)

print("✅ [Delta] السكربت جاهز - انتظر أوامر المستخدم")
