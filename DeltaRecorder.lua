-- [[ Delta Recorder v10.0 - الإصدار العملي والمضمون ]]
-- تم إعادة بنائه بالكامل ليشتغل بشكل صحيح

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ===== إعدادات الأداء =====
local PerformanceMode = false
local FPSLimit = 60

-- ===== المتغيرات الرئيسية =====
local recordedPath = {}
local isRecording = false
local isReplaying = false
local isLooping = false
local replayIndex = 1
local recordDuration = 60 -- مدة التسجيل
local winsCount = 0
local replaySpeed = 1

-- ===== أدوات تحسين الأداء =====
local function setPerformanceMode(enabled)
    PerformanceMode = enabled
    if enabled then
        -- تقليل جودة الرسومات
        settings().Rendering.QualityLevel = 1
        -- تحديد معدل الفريمات
        game:GetService("RunService").RenderStepped:Connect(function()
            if PerformanceMode then
                task.wait(1 / FPSLimit)
            end
        end)
        print("⚡ وضع الأداء مفعل (60 فريم)")
    else
        settings().Rendering.QualityLevel = 4
        print("⚡ وضع الأداء معطل")
    end
end

-- ===== نظام التسجيل المبسط والموثوق =====
local function startRecording()
    if isRecording then
        print("⚠️ التسجيل قيد التشغيل بالفعل!")
        return
    end
    
    recordedPath = {}
    isRecording = true
    print("⏺ بدء التسجيل...")
    
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if isRecording then
            table.insert(recordedPath, {
                pos = rootPart.Position,
                cf = rootPart.CFrame,
                time = tick()
            })
        else
            conn:Disconnect()
        end
    end)
    
    task.wait(recordDuration)
    isRecording = false
    print("✅ تم التسجيل ("..#recordedPath.." نقطة)")
end

-- ===== نظام إعادة التشغيل المضمون =====
local function startReplay()
    if #recordedPath == 0 then
        print("❌ لا يوجد مسار مسجل!")
        return
    end
    
    if isReplaying then
        print("⚠️ إعادة التشغيل قيد التنفيذ بالفعل!")
        return
    end
    
    isReplaying = true
    replayIndex = 1
    print("🔄 بدء إعادة التشغيل (سرعة x" .. replaySpeed .. ")")
    
    local step = 1
    local speedFactor = replaySpeed
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            -- تطبيق السرعة
            for _ = 1, math.floor(speedFactor) do
                if replayIndex <= #recordedPath then
                    rootPart.CFrame = recordedPath[replayIndex].cf
                    replayIndex = replayIndex + 1
                end
            end
            
            -- التعامل مع السرعة الكسرية
            if speedFactor % 1 > 0 then
                step = step + (speedFactor % 1)
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
            print("🏆 انتصار #" .. winsCount)
            
            if isLooping then
                task.wait(0.5)
                replayIndex = 1
                startReplay()
            else
                print("⏸ انتهى المسار. شغّل Loop للتكرار.")
            end
        end
    end)
end

-- ===== نظام العوائق المبسط (معالجة فورية) =====
local function handleObstacles()
    local pos = rootPart.Position
    
    -- الكشف عن العوائق القريبة
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v ~= rootPart then
            local dist = (v.Position - pos).Magnitude
            if dist < 5 then
                -- تعامل مع العائق حسب نوعه
                if v.Name:lower():find("door") or v.Name:lower():find("باب") then
                    if v.Orientation.Y < 80 and v.Orientation.Y > -80 then
                        -- الباب مغلق: انتظر
                        print("🚪 باب مغلق، انتظر...")
                        task.wait(1)
                    end
                elseif v.Name:lower():find("water") or v.Name:lower():find("ماء") then
                    -- تجنب الماء بالقفز
                    rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 10, 0)
                    print("🌊 تجنب الماء")
                elseif v.Velocity and v.Velocity.Magnitude > 0 then
                    -- جسم متحرك: تحرك جانبيًا
                    local escapeDir = Vector3.new(1, 0, 0)
                    if v.Velocity.X > 0 then escapeDir = Vector3.new(-1, 0, 0) end
                    rootPart.CFrame = rootPart.CFrame + (escapeDir * 5)
                    print("🌀 تجنب جسم متحرك")
                end
            end
        end
    end
end

-- ===== إنشاء واجهة المستخدم =====
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeltaUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 350)
    frame.Position = UDim2.new(0.5, -150, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corners = Instance.new("UICorner")
    corners.CornerRadius = UDim.new(0, 12)
    corners.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚡ Delta Recorder v10"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    -- أزرار
    local yPos = 0.15
    local function createBtn(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 35)
        btn.Position = UDim2.new(0.1, 0, 0, yPos)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = frame
        btn.MouseButton1Click:Connect(callback)
        yPos = yPos + 0.12
        return btn
    end
    
    createBtn("▶ بدء التسجيل", startRecording)
    createBtn("🔄 تشغيل المسار", startReplay)
    
    local loopBtn = createBtn("♾ التكرار (إيقاف)", function()
        isLooping = not isLooping
        loopBtn.Text = isLooping and "♾ التكرار (تشغيل)" or "♾ التكرار (إيقاف)"
        loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(0, 150, 255)
    end)
    
    local perfBtn = createBtn("⚡ تحسين الأداء (إيقاف)", function()
        local isPerfOn = not PerformanceMode
        setPerformanceMode(isPerfOn)
        perfBtn.Text = isPerfOn and "⚡ تحسين الأداء (تشغيل)" or "⚡ تحسين الأداء (إيقاف)"
        perfBtn.BackgroundColor3 = isPerfOn and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(0, 150, 255)
    end)
    
    createBtn("⏹ إيقاف الكل", function()
        isRecording = false
        isReplaying = false
        isLooping = false
        loopBtn.Text = "♾ التكرار (إيقاف)"
        loopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        print("⏹ تم الإيقاف الكامل")
    end)
    
    -- حقل السرعة
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.3, 0, 0, 30)
    speedLabel.Position = UDim2.new(0.1, 0, 0, yPos + 0.02)
    speedLabel.Text = "السرعة:"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextSize = 14
    speedLabel.Parent = frame
    
    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(0.4, 0, 0, 30)
    speedBox.Position = UDim2.new(0.5, 0, 0, yPos + 0.02)
    speedBox.Text = "1"
    speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedBox.Font = Enum.Font.Gotham
    speedBox.TextSize = 14
    speedBox.BorderSizePixel = 0
    speedBox.Parent = frame
    speedBox.FocusLost:Connect(function()
        local newSpeed = tonumber(speedBox.Text)
        if newSpeed and newSpeed > 0 then
            replaySpeed = newSpeed
            print("⚡ السرعة مضبوطة: x" .. replaySpeed)
        else
            speedBox.Text = tostring(replaySpeed)
        end
    end)
end

-- ===== تشغيل السكربت =====
createUI()
setPerformanceMode(false) -- الوضع العادي افتراضيًا
print("⚡ Delta Recorder v10.0 جاهز!")
