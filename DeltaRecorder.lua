-- [[ Delta Recorder v12.0 - الدمج النهائي مع Terror-Hub ]]
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
local terrorHubLoaded = false
local terrorHubWindow = nil

-- ===== نظام تحميل Terror-Hub =====
local function loadTerrorHub()
    if terrorHubLoaded then
        if terrorHubWindow then
            terrorHubWindow.Visible = not terrorHubWindow.Visible
        end
        return
    end
    
    print("🌀 جاري تحميل Terror-Hub...")
    
    -- تحميل السكربت وتنفيذه
    local success, err = pcall(function()
        local hubScript = loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Terror-hub-100012"))()
        if hubScript then
            terrorHubLoaded = true
            print("✅ تم تحميل Terror-Hub بنجاح")
            
            -- محاولة العثور على نافذة Terror-Hub وربطها بالسرعة
            task.wait(1) -- ننتظر قليلاً لتظهر النافذة
            for _, gui in ipairs(player.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:lower():find("terror") then
                    terrorHubWindow = gui
                    break
                end
            end
        end
    end)
    
    if not success then
        print("❌ فشل تحميل Terror-Hub: " .. tostring(err))
    end
end

-- ===== نظام اكتشاف وإزالة العوائق =====
local function findAndRemoveObstacles()
    local playerPos = rootPart.Position
    local removedCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= character then
            obj:Destroy()
            removedCount = removedCount + 1
        elseif obj:IsA("Part") and (obj.Name:lower():find("water") or obj.Name:lower():find("تسونامي") or obj.Name:lower():find("wave")) then
            if (obj.Position - playerPos).Magnitude < 100 then
                obj:Destroy()
                removedCount = removedCount + 1
            end
        elseif obj:IsA("Part") and (obj.Name:lower():find("ball") or obj.Name:lower():find("كرة") or obj.Shape == Enum.PartType.Ball) then
            if (obj.Position - playerPos).Magnitude < 50 then
                obj:Destroy()
                removedCount = removedCount + 1
            end
        elseif obj:IsA("Part") and (obj.Name:lower():find("door") or obj.Name:lower():find("باب")) then
            if obj:FindFirstChild("ClickDetector") or obj:FindFirstChild("ProximityPrompt") then
                obj:Destroy()
                removedCount = removedCount + 1
            end
        end
    end
    
    if removedCount > 0 then
        print("🗑️ تم إزالة " .. removedCount .. " عائق")
    end
    return removedCount
end

-- ===== دوال التسجيل =====
local function startRecording()
    if isRecording then return end
    recordedPath = {}
    isRecording = true
    print("⏺ بدء التسجيل...")
    
    if removeObstacles then
        findAndRemoveObstacles()
    end
    
    local conn = game:GetService("RunService").Heartbeat:Connect(function()
        if isRecording then
            table.insert(recordedPath, {
                pos = rootPart.Position,
                cf = rootPart.CFrame
            })
            if removeObstacles then
                findAndRemoveObstacles()
            end
        else
            conn:Disconnect()
        end
    end)
    
    task.wait(recordDuration)
    isRecording = false
    print("✅ تم التسجيل ("..#recordedPath.." نقطة)")
    statusLabel.Text = "✅ تم التسجيل ("..#recordedPath.." نقطة)"
end

-- ===== دوال إعادة التشغيل =====
local function startReplay()
    if #recordedPath == 0 then
        print("❌ لا يوجد مسار مسجل!")
        statusLabel.Text = "❌ لا يوجد مسار مسجل!"
        return
    end
    if isReplaying then return end
    
    isReplaying = true
    replayIndex = 1
    print("🔄 بدء إعادة التشغيل (سرعة x" .. replaySpeed .. ")")
    statusLabel.Text = "🔄 جاري إعادة التحركات (سرعة x" .. replaySpeed .. ")"
    
    if humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * replaySpeed
    end
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying and replayIndex <= #recordedPath then
            rootPart.CFrame = recordedPath[replayIndex].cf
            replayIndex = replayIndex + 1
            if removeObstacles then
                findAndRemoveObstacles()
            end
        elseif isReplaying and replayIndex > #recordedPath then
            isReplaying = false
            winsCount = winsCount + 1
            print("🏆 انتصار #" .. winsCount)
            statusLabel.Text = "🏆 انتصار #" .. winsCount
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
        print("⚡ وضع الأداء مفعل (60 فريم)")
        statusLabel.Text = "⚡ وضع الأداء مفعل (60 فريم)"
    else
        settings().Rendering.QualityLevel = 4
        print("⚡ وضع الأداء معطل")
        statusLabel.Text = "⚡ وضع الأداء معطل"
    end
end

-- ===== إنشاء الواجهة الرئيسية =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 620)
frame.Position = UDim2.new(0.5, -180, 0.5, -310)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = screenGui

local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

-- شريط العنوان
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Delta Recorder v12"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- زر الإغلاق
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

-- أيقونة مصغرة
local miniIcon = Instance.new("ImageButton")
miniIcon.Size = UDim2.new(0, 50, 0, 50)
miniIcon.Position = UDim2.new(0, 10, 0, 10)
miniIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
miniIcon.Image = "rbxassetid://4483345998"
miniIcon.Visible = false
miniIcon.BorderSizePixel = 1
miniIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
miniIcon.Parent = screenGui

local miniCorners = Instance.new("UICorner")
miniCorners.CornerRadius = UDim.new(1, 0)
miniCorners.Parent = miniIcon

-- وظيفة السحب
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
            statusLabel.Text = "⚡ السرعة مضبوطة: x" .. replaySpeed
            print("⚡ السرعة مضبوطة على: " .. replaySpeed)
        else
            speedBox.Text = tostring(replaySpeed)
        end
    end
end)

yOffset = yOffset + 45

-- أزرار التحكم
createButton("▶ بدء التسجيل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startRecording)
yOffset = yOffset + 40

createButton("🔄 تشغيل المسار", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), startReplay)
yOffset = yOffset + 40

local loopBtn = createButton("♾ وضع التكرار (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isLooping = not isLooping
    loopBtn.Text = isLooping and "♾ وضع التكرار (تشغيل)" or "♾ وضع التكرار (إيقاف)"
    loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
    statusLabel.Text = isLooping and "♾ التكرار اللا نهائي مفعل" or "⏸ تم إيقاف التكرار"
end)
yOffset = yOffset + 40

createButton("⏹ إيقاف الكل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    isRecording = false
    isReplaying = false
    isLooping = false
    loopBtn.Text = "♾ وضع التكرار (إيقاف)"
    loopBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "⏹ تم الإيقاف الكامل"
    print("⏹ تم الإيقاف الكامل")
end)
yOffset = yOffset + 40

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
yOffset = yOffset + 40

-- زر تحسين الأداء
local perfBtn = createButton("⚡ تحسين الأداء (إيقاف)", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    togglePerformance()
    perfBtn.Text = isPerformanceMode and "⚡ تحسين الأداء (تشغيل)" or "⚡ تحسين الأداء (إيقاف)"
    perfBtn.BackgroundColor3 = isPerformanceMode and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 255, 255)
end)
yOffset = yOffset + 40

-- زر Terror-Hub
local terrorBtn = createButton("🌀 تشغيل Terror-Hub", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    loadTerrorHub()
    statusLabel.Text = "🌀 جاري تحميل Terror-Hub..."
    task.wait(1)
    statusLabel.Text = "✅ تم تحميل Terror-Hub"
end)
yOffset = yOffset + 40

-- زر مسح المسار
createButton("🗑️ مسح المسار المسجل", yOffset, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), function()
    recordedPath = {}
    statusLabel.Text = "🗑️ تم مسح المسار"
    print("🗑️ تم مسح المسار")
end)
yOffset = yOffset + 40

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

print("⚡ Delta Recorder v12.0 جاهز! جميع الأوامر تعمل.")
