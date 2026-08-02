-- [[ Delta Recorder v11.0 - النظام الذكي لإزالة العوائق ]]
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

-- ===== نظام اكتشاف وإزالة العوائق =====
local function findAndRemoveObstacles()
    local playerPos = rootPart.Position
    local removedCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- كشف الوحوش (أي نموذج يحتوي على Humanoid)
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= character then
            obj:Destroy()
            removedCount = removedCount + 1
            print("🗑️ تم إزالة وحش: " .. obj.Name)
        
        -- كشف التسونامي أو الماء
        elseif obj:IsA("Part") and (obj.Name:lower():find("water") or obj.Name:lower():find("تسونامي") or obj.Name:lower():find("wave")) then
            if (obj.Position - playerPos).Magnitude < 100 then
                obj:Destroy()
                removedCount = removedCount + 1
                print("🌊 تم إزالة تسونامي")
            end
        
        -- كشف الكرات أو الأجسام الخطرة
        elseif obj:IsA("Part") and (obj.Name:lower():find("ball") or obj.Name:lower():find("كرة") or obj.Shape == Enum.PartType.Ball) then
            if (obj.Position - playerPos).Magnitude < 50 then
                obj:Destroy()
                removedCount = removedCount + 1
                print("⚪ تم إزالة كرة")
            end
        
        -- كشف الأبواب المتحركة (التي تغلق)
        elseif obj:IsA("Part") and (obj.Name:lower():find("door") or obj.Name:lower():find("باب")) then
            if obj:FindFirstChild("ClickDetector") or obj:FindFirstChild("ProximityPrompt") then
                obj:Destroy()
                removedCount = removedCount + 1
                print("🚪 تم إزالة باب")
            end
        end
    end
    
    if removedCount > 0 then
        print("✅ تم إزالة " .. removedCount .. " عائق/عوائق")
    end
    return removedCount
end

-- ===== إنشاء الواجهة الرئيسية (قابلة للسحب - أبيض وأسود) =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 560)
frame.Position = UDim2.new(0.5, -180, 0.5, -280)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- خلفية سوداء
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(255, 255, 255) -- حد أبيض
frame.Parent = screenGui

-- زوايا دائرية
local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

-- شريط العنوان (للسحب - أسود مع نص أبيض)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
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
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Delta Recorder v11"
title.TextColor3 = Color3.fromRGB(255, 255, 255) -- أبيض
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- زر الإغلاق (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0) -- أسود
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- أبيض
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

-- ===== أيقونة مصغرة (بيضاء) =====
local miniIcon = Instance.new("ImageButton")
miniIcon.Size = UDim2.new(0, 50, 0, 50)
miniIcon.Position = UDim2.new(0, 10, 0, 10)
miniIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- أبيض
miniIcon.Image = "rbxassetid://4483345998"
miniIcon.Visible = false
miniIcon.BorderSizePixel = 1
miniIcon.BorderColor3 = Color3.fromRGB(0, 0, 0) -- حد أسود
miniIcon.Parent = screenGui

local miniCorners = Instance.new("UICorner")
miniCorners.CornerRadius = UDim.new(1, 0)
miniCorners.Parent = miniIcon

-- ===== وظيفة السحب =====
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

titleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ===== عناصر التحكم =====
local yOffset = 55
local function createButton(text, yPos, color, textColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 35)
    btn.Position = UDim2.new(0.1, 0, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = textColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
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

yOffset = yOffset + 45

-- أزرار التحكم
createButton("▶ بدء التسجيل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startRecording)
yOffset = yOffset + 45

createButton("🔄 تشغيل المسار", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startReplay)
yOffset = yOffset + 45

local loopBtn = createButton("♾ وضع التكرار (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isLooping = not isLooping
    loopBtn.Text = isLooping and "♾ وضع التكرار (تشغيل)" or "♾ وضع التكرار (إيقاف)"
    loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
    statusLabel.Text = isLooping and "♾ التكرار اللا نهائي مفعل" or "⏸ تم إيقاف التكرار"
end)
yOffset = yOffset + 45

createButton("⏹ إيقاف الكل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isRecording = false
    isReplaying = false
    isLooping = false
    loopBtn.Text = "♾ وضع التكرار (إيقاف)"
    loopBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "⏹ تم الإيقاف الكامل"
    print("[Delta] إيقاف كامل")
end)
yOffset = yOffset + 45

-- زر إزالة العوائق
local removeBtn = createButton("🗑️ إزالة العوائق (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    removeObstacles = not removeObstacles
    removeBtn.Text = removeObstacles and "🗑️ إزالة العوائق (تشغيل)" or "🗑️ إزالة العوائق (إيقاف)"
    removeBtn.BackgroundColor3 = removeObstacles and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
    statusLabel.Text = removeObstacles and "🗑️ إزالة العوائق مفعلة" or "⏸ إزالة العوائق معطلة"
    if removeObstacles then
        findAndRemoveObstacles()
    end
end)
yOffset = yOffset + 45

-- زر تحسين الأداء
local perfBtn = createButton("⚡ تحسين الأداء (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isPerformanceMode = not isPerformanceMode
    perfBtn.Text = isPerformanceMode and "⚡ تحسين الأداء (تشغيل)" or "⚡ تحسين الأداء (إيقاف)"
    perfBtn.BackgroundColor3 = isPerformanceMode and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
    if isPerformanceMode then
        setfpscap(60)
        settings().Rendering.QualityLevel = 1
        statusLabel.Text = "⚡ وضع الأداء مفعل (60 فريم)"
    else
        setfpscap(0)
        settings().Rendering.QualityLevel = 4
        statusLabel.Text = "⚡ وضع الأداء معطل"
    end
end)
yOffset = yOffset + 45

-- زر مسح المسار
createButton("🗑️ مسح المسار المسجل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    recordedPath = {}
    statusLabel.Text = "🗑️ تم مسح المسار"
    print("[Delta] مسح المسار")
end)
yOffset = yOffset + 45

-- زر عرض الإحصائيات
createButton("📊 عرض الإحصائيات", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    statusLabel.Text = "📊 النقاط: " .. #recordedPath .. " | الانتصارات: " .. winsCount
end)
yOffset = yOffset + 45

-- حالة النص (أبيض)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, yOffset + 10)
statusLabel.Text = "⏸ في الانتظار..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.Parent = frame

-- ===== تحديث السرعة =====
speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newSpeed = tonumber(speedBox.Text)
        if newSpeed and newSpeed > 0 then
            replaySpeed = newSpeed
            statusLabel.Text = "⚡ السرعة مضبوطة: x" .. replaySpeed
        else
            speedBox.Text = tostring(replaySpeed)
        end
    end
end)

-- ===== دوال التسجيل (مع إزالة العوائق) =====
local function startRecording()
    recordedPath = {}
    isRecording = true
    isReplaying = false
    statusLabel.Text = "⏺ جاري التسجيل..."
    print("[Delta] بدء التسجيل")

    -- إذا كانت إزالة العوائق مفعلة، قم بإزالتها أثناء التسجيل
    if removeObstacles then
        findAndRemoveObstacles()
    end

    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if isRecording then
            table.insert(recordedPath, {
                pos = rootPart.Position,
                cf = rootPart.CFrame
            })
            -- إزالة العوائق بشكل مستمر أثناء التسجيل
            if removeObstacles then
                findAndRemoveObstacles()
            end
        else
            conn:Disconnect()
        end
    end)

    task.wait(recordDuration)
    isRecording = false
    statusLabel.Text = "✅ تم التسجيل ("..#recordedPath.." نقطة)"
    print("[Delta] انتهى التسجيل، النقاط: "..#recordedPath)
end

-- ===== دوال إعادة التشغيل المحسنة =====
local function startReplay()
    if #recordedPath == 0 then
        statusLabel.Text = "❌ لا يوجد مسار مسجل!"
        return
    end
    isReplaying = true
    replayIndex = 1
    statusLabel.Text = "🔄 جاري إعادة التحركات (سرعة x" .. replaySpeed .. ")"
    print("[Delta] بدء إعادة التشغيل بسرعة: " .. replaySpeed)

    if humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * replaySpeed
    end

    local step = 1
    local speedFactor = replaySpeed

    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            for _ = 1, math.floor(speedFactor) do
                if replayIndex <= #recordedPath then
                    rootPart.CFrame = recordedPath[replayIndex].cf
                    replayIndex = replayIndex + 1
                end
            end
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
            -- إزالة العوائق أثناء إعادة التشغيل (إذا كانت مفعلة)
            if removeObstacles then
                findAndRemoveObstacles()
            end
        elseif isReplaying and replayIndex > #recordedPath then
            isReplaying = false
            winsCount = winsCount + 1
            statusLabel.Text = "🏆 انتصار #" .. winsCount .. " - إعادة تشغيل تلقائي..."
            print("[Delta] انتصار #" .. winsCount)

            if isLooping then
                task.wait(0.5)
                startReplay()
            else
                statusLabel.Text = "⏸ انتهى المسار. شغّل Loop للتكرار."
            end
        end
    end)
end

-- ===== وظائف الإغلاق =====
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniIcon.Visible = true
end)

miniIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniIcon.Visible = false
end)

-- ===== دالة تحسين الأداء =====
local function setfpscap(fps)
    if fps == 0 then
        game:GetService("RunService").RenderStepped:Wait()
    else
        local fpsWait = 1 / fps
        local _ = game:GetService("RunService").RenderStepped:Connect(function()
            task.wait(fpsWait)
        end)
    end
end

print("[Delta] السكربت v11.0 جاهز! العوائق ستُزال تلقائيًا عند تفعيل الخيار.")
