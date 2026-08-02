-- [[ Delta Recorder v9.0 - النظام العام لتحليل أي عائق ]]
-- يكتشف أي عائق ويتعلم كيفية تجاوزه بناءً على تحركاتك

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ===== المتغيرات الرئيسية =====
local recordedData = {}
local isRecording = false
local isReplaying = false
local isLooping = false
local replayIndex = 1
local recordDuration = 60

-- ===== نظام تحليل العوائق العام =====
local function analyzeSurroundings()
    local pos = rootPart.Position
    local detectedObjects = {}
    
    -- مسح كل الأجزاء في نطاق 30 متر
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v ~= rootPart then
            local dist = (v.Position - pos).Magnitude
            if dist < 30 then
                -- جمع خصائص العائق
                local properties = {
                    name = v.Name,
                    position = v.Position,
                    size = v.Size,
                    velocity = v.Velocity or Vector3.new(0,0,0),
                    isAnchored = v.Anchored,
                    isTransparent = v.Transparency > 0.5,
                    canCollide = v.CanCollide,
                    color = v.Color,
                    material = v.Material,
                    distance = dist,
                    -- نوع العائق (مستنتج من الخصائص)
                    type = "unknown"
                }
                
                -- استنتاج النوع من الخصائص
                if v.Velocity and v.Velocity.Magnitude > 1 then
                    properties.type = "moving"
                end
                if v.Size.Y > 5 and v.Size.X > 5 then
                    properties.type = "wall"
                end
                if v.Name:lower():find("door") or v.Name:lower():find("باب") then
                    properties.type = "door"
                end
                if v.Name:lower():find("water") or v.Name:lower():find("ماء") then
                    properties.type = "water"
                end
                if v.Transparency > 0.8 then
                    properties.type = "invisible"
                end
                if v.Anchored == false and v.Velocity.Magnitude == 0 then
                    properties.type = "movable"
                end
                
                table.insert(detectedObjects, properties)
            end
        end
    end
    
    return detectedObjects
end

-- ===== تحليل تفاعل اللاعب مع العائق =====
local function analyzePlayerAction(obstacles)
    local action = {
        type = "move",
        direction = rootPart.CFrame.LookVector,
        position = rootPart.Position,
        rotation = rootPart.Orientation
    }
    
    -- تحديد ما إذا كان اللاعب يتفادى شيئًا
    for _, obs in ipairs(obstacles) do
        if obs.distance < 5 then
            action.type = "avoid"
            action.obstacle = obs
            break
        end
    end
    
    return action
end

-- ===== التسجيل الذكي =====
local function startRecording()
    recordedData = {}
    isRecording = true
    print("⏺ بدء التسجيل مع التحليل العام...")
    
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if isRecording then
            local obstacles = analyzeSurroundings()
            local action = analyzePlayerAction(obstacles)
            
            table.insert(recordedData, {
                time = tick(),
                playerPos = rootPart.Position,
                playerCF = rootPart.CFrame,
                obstacles = obstacles,
                action = action,
                -- إضافة حالة المتاهة إذا وجدت
                mazeState = getMazeState()
            })
        else
            conn:Disconnect()
        end
    end)
    
    task.wait(recordDuration)
    isRecording = false
    print("✅ تم التسجيل ("..#recordedData.." نقطة)")
end

-- ===== دالة للحصول على حالة المتاهة (إذا وجدت) =====
local function getMazeState()
    -- محاولة اكتشاف المتاهة من خلال الجدران القريبة
    local walls = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Size.X > 2 and v.Size.Z > 2 and v.Anchored then
            table.insert(walls, {
                position = v.Position,
                size = v.Size,
                color = v.Color
            })
        end
    end
    return walls
end

-- ===== إعادة التشغيل الذكي جدًا =====
local function startReplay()
    if #recordedData == 0 then
        print("❌ لا يوجد مسار مسجل!")
        return
    end
    
    isReplaying = true
    replayIndex = 1
    print("🔄 بدء إعادة التشغيل الذكي...")
    
    local function executeStep()
        if not isReplaying or replayIndex > #recordedData then
            isReplaying = false
            if isLooping then
                task.wait(1)
                replayIndex = 1
                startReplay()
            end
            return
        end
        
        local currentStep = recordedData[replayIndex]
        
        -- 1. تنفيذ الحركة الأساسية
        rootPart.CFrame = currentStep.playerCF
        
        -- 2. تحليل الوضع الحالي والعوائق الجديدة
        local currentObstacles = analyzeSurroundings()
        
        -- 3. مقارنة العوائق المسجلة مع الحالية
        for _, recordedObs in ipairs(currentStep.obstacles) do
            for _, currentObs in ipairs(currentObstacles) do
                if (currentObs.position - recordedObs.position).Magnitude < 5 then
                    -- عائق مشابه موجود، طبّق نفس منطق التجاوز
                    if recordedObs.type == "door" then
                        -- انتظر حتى يتغير حاله
                        waitForDoor(currentObs)
                    elseif recordedObs.type == "water" then
                        -- تجنب الماء
                        avoidWater(currentObs)
                    elseif recordedObs.type == "moving" then
                        -- توقع حركته وتجنبه
                        avoidMoving(currentObs)
                    elseif recordedObs.type == "wall" then
                        -- ابحث عن ممر
                        findPassage(currentObs)
                    else
                        -- عائق غير معروف: حاول التجربة
                        handleUnknown(currentObs)
                    end
                    break
                end
            end
        end
        
        replayIndex = replayIndex + 1
        task.wait(0.05)
    end
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isReplaying then
            executeStep()
        end
    end)
end

-- ===== دوال مساعدة للتعامل مع أنواع العوائق =====
local function waitForDoor(door)
    print("🚪 انتظار فتح الباب...")
    local startTime = tick()
    while tick() - startTime < 5 do
        -- تحديث حالة الباب
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Part") and (v.Position - door.position).Magnitude < 2 then
                if v.Orientation.Y > 80 or v.Orientation.Y < -80 then
                    return -- الباب مفتوح
                end
            end
        end
        task.wait(0.1)
    end
    print("🚪 الباب لم يفتح، محاولة المرور...")
end

local function avoidWater(water)
    print("🌊 تجنب الماء...")
    local safeDir = (rootPart.Position - water.position).Unit * 5
    rootPart.CFrame = rootPart.CFrame + Vector3.new(safeDir.X, 2, safeDir.Z)
end

local function avoidMoving(movingObj)
    print("🌀 تجنب جسم متحرك...")
    local futurePos = movingObj.position + (movingObj.velocity * 0.5)
    local escapeDir = (rootPart.Position - futurePos).Unit * 3
    rootPart.CFrame = rootPart.CFrame + escapeDir
end

local function findPassage(wall)
    print("🧱 البحث عن ممر في الجدار...")
    -- البحث في الاتجاهات الأربعة عن ممر
    local directions = {
        Vector3.new(1,0,0),
        Vector3.new(-1,0,0),
        Vector3.new(0,0,1),
        Vector3.new(0,0,-1)
    }
    for _, dir in ipairs(directions) do
        local checkPos = wall.position + dir * 5
        if not workspace:FindPartOnRay(Ray.new(rootPart.Position, checkPos - rootPart.Position)) then
            rootPart.CFrame = CFrame.new(checkPos)
            print("🧱 تم العثور على ممر!")
            return
        end
    end
    print("🧱 لا يوجد ممر، محاولة المرور...")
end

local function handleUnknown(unknown)
    print("❓ عائق غير معروف، محاولة التجربة...")
    -- حاول المرور من فوق أو من الجانب
    local tryPositions = {
        rootPart.Position + Vector3.new(0, 3, 0),
        rootPart.Position + Vector3.new(2, 0, 0),
        rootPart.Position + Vector3.new(-2, 0, 0),
        rootPart.Position + Vector3.new(0, 0, 2),
        rootPart.Position + Vector3.new(0, 0, -2)
    }
    for _, tryPos in ipairs(tryPositions) do
        if not workspace:FindPartOnRay(Ray.new(rootPart.Position, tryPos - rootPart.Position)) then
            rootPart.CFrame = CFrame.new(tryPos)
            print("❓ تم تجاوز العائق!")
            return
        end
    end
end

-- ===== واجهة التحكم (GUI مبسطة) =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaAI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 180)
frame.Position = UDim2.new(0.5, -125, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corners = Instance.new("UICorner")
corners.CornerRadius = UDim.new(0, 12)
corners.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "🧠 Delta AI v9.0"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- أزرار
local function createBtn(text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 30)
    btn.Position = UDim2.new(0.1, 0, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

createBtn("▶ تسجيل", 0.25, Color3.fromRGB(0, 200, 100), startRecording)
createBtn("🔄 تشغيل", 0.45, Color3.fromRGB(0, 150, 255), startReplay)
createBtn("♾ تكرار", 0.65, Color3.fromRGB(200, 150, 0), function()
    isLooping = not isLooping
    print(isLooping and "♾ تكرار مفعل" or "♾ تكرار معطل")
end)
createBtn("⏹ إيقاف", 0.85, Color3.fromRGB(200, 50, 50), function()
    isRecording = false
    isReplaying = false
    isLooping = false
    print("⏹ تم الإيقاف")
end)

print("🧠 Delta AI v9.0 جاهز!")
