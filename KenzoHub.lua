--[[ 
    🐟 KENZO HUB - FINAL EDITION 🐟
    Version: 3.2 (Anti-Double Fixed)
    Fix: 
    - Menggunakan tick() untuk presisi waktu
    - ID Unik berdasarkan (Player+Ikan+Berat)
    - Mencegah double notif dari Legacy & New Chat
]]

-- ⚠️ KONFIGURASI
getgenv().KenzoConfig = {
    Token = "ZvKehiTkNVt8YrYn1xAW",    
    GroupID = "120363044268395313@g.us", 
    IsScanning = false                  
}

-----------------------------------------------------------
-- 1. BAGIAN LOGIKA SISTEM (BACKEND)
-----------------------------------------------------------
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local http_request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

-- [FIX BARU] Variabel Anti-Double Lebih Ketat
local lastCatchID = "" -- Menyimpan "Player-Ikan-Berat"
local lastCatchTime = 0 -- Menggunakan tick()

local RARITY_THRESHOLD = 250000 

local knownMutations = {
    "Big", "Giant", "Skeleton", "Albino", "Dark", "Shiny", "Tiny", 
    "Midas", "Golden", "Rainbow", "Ghost", "Neon", "Radioactive",
    "Atlantis", "Void", "Abyssal", "Cursed", "Blessed", "Stone",
    "Midnight", "Fairy Dust", "Gemstone", "Corrupt", "Galaxy", "Sandy",
    "Lightning"
}

-- [MESIN PENERJEMAH K/M/B]
local function parseChanceValue(chanceString)
    local valueStr, suffix = string.match(chanceString, "1 in ([%d%.]+)(%a?)")
    if not valueStr then return 0 end
    local number = tonumber(valueStr)
    if not number then return 0 end
    local multiplier = 1
    local s = string.lower(suffix or "")
    if s == "k" then multiplier = 1000        
    elseif s == "m" then multiplier = 1000000     
    elseif s == "b" then multiplier = 1000000000  
    end
    return number * multiplier
end

-- Fungsi Kirim WA (Normal)
local function sendWhatsApp(data)
    if not getgenv().KenzoConfig.IsScanning then return end 

    local caption = 
        "*Kenzo HUB | Secret Found!*\n" ..
        "🚨 *ALERT! Rare Catch (".. data.chance ..")*\n\n" ..
        "*👤 Player:* " .. data.player .. "\n" ..
        "*🐟 Fish:* " .. data.fish .. "\n" ..
        "*🧬 Mutation:* " .. data.mutation .. "\n" ..
        "*⚖️ Weight:* " .. data.weight .. "\n" ..
        "*🎲 Chance:* " .. data.chance .. "\n\n" ..
        "_" .. os.date("%A, %H:%M") .. "_"

    local body = {
        ["target"] = getgenv().KenzoConfig.GroupID,
        ["message"] = caption,
        ["delay"] = "2",
        ["url"] = "https://i.imgur.com/4M7IwwP.png" 
    }

    if http_request then
        http_request({
            Url = "https://api.fonnte.com/send",
            Method = "POST",
            Headers = {["Authorization"] = getgenv().KenzoConfig.Token, ["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end
end

-- [FITUR] Fungsi Test Koneksi Manual
local function testConnection()
    local caption = 
        "*Kenzo HUB | Test Mode*\n" ..
        "✅ *Koneksi Berhasil!*\n\n" ..
        "Token & ID Grup Valid.\n" ..
        "Script siap digunakan.\n\n" ..
        "_" .. os.date("%A, %H:%M") .. "_"

    local body = {
        ["target"] = getgenv().KenzoConfig.GroupID,
        ["message"] = caption,
        ["delay"] = "1"
    }

    if http_request then
        local response = http_request({
            Url = "https://api.fonnte.com/send",
            Method = "POST",
            Headers = {["Authorization"] = getgenv().KenzoConfig.Token, ["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
        
        if response and response.StatusCode == 200 then
            game.StarterGui:SetCore("SendNotification", {Title="Test Sukses", Text="Cek WA sekarang!", Duration=3})
        else
            game.StarterGui:SetCore("SendNotification", {Title="Test Gagal", Text="Cek Token/ID Salah!", Duration=3})
        end
    else
        game.StarterGui:SetCore("SendNotification", {Title="Error", Text="Executor tidak support HTTP", Duration=3})
    end
end

-- Fungsi Utama (Processor - LOGIKA BARU)
local function processMessage(msg)
    if not getgenv().KenzoConfig.IsScanning then return end

    local cleanMsg = string.gsub(msg, "<.->", "")

    -- 1. Baca Dulu Datanya
    local player, fullFishName, weight, chanceRaw = string.match(cleanMsg, "^%[Server%]:%s*(.-)%s+obtained%s+an?%s+(.-)%s+(%([%d%.]+kg%))%s+with%s+a%s+(.-)%s+chance")
    
    if player and fullFishName and weight then
        
        -- [LOGIKA ANTI-DOUBLE V2]
        local currentID = player .. "-" .. fullFishName .. "-" .. weight
        
        if currentID == lastCatchID and (tick() - lastCatchTime) < 10 then
            return
        end

        local rarityValue = parseChanceValue(chanceRaw)
        
        if rarityValue >= RARITY_THRESHOLD then
            lastCatchID = currentID
            lastCatchTime = tick() 
            
            local detectedMutation = "None"
            local realFishName = fullFishName
            
            for _, mut in pairs(knownMutations) do
                if string.find(fullFishName, "^"..mut) then
                    detectedMutation = mut
                    realFishName = string.gsub(fullFishName, mut.."%s*", "")
                    break
                end
            end
            
            sendWhatsApp({player=player, fish=realFishName, mutation=detectedMutation, weight=weight, chance=chanceRaw})
        end
    end
end

-- Listener Chat
if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
    ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
        if data and data.Message then processMessage(data.Message) end
    end)
end
TextChatService.MessageReceived:Connect(function(textChatMessage)
    if textChatMessage and textChatMessage.Text then processMessage(textChatMessage.Text) end
end)

-----------------------------------------------------------
-- 2. BAGIAN TAMPILAN UI (FRONTEND - V3)
-----------------------------------------------------------
if CoreGui:FindFirstChild("KenzoHUB") then CoreGui.KenzoHUB:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KenzoHUB"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- [TOMBOL MINIMIZE (KECIL)]
local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Parent = ScreenGui
MiniButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MiniButton.Position = UDim2.new(0, 10, 0.5, -25) 
MiniButton.Size = UDim2.new(0, 50, 0, 50)
MiniButton.Font = Enum.Font.GothamBold
MiniButton.Text = "K"
MiniButton.TextColor3 = Color3.fromRGB(85, 255, 255)
MiniButton.TextSize = 24
MiniButton.Visible = false 
local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 10)
MiniCorner.Parent = MiniButton
local MiniStroke = Instance.new("UIStroke")
MiniStroke.Parent = MiniButton
MiniStroke.Color = Color3.fromRGB(85, 255, 255)
MiniStroke.Thickness = 2

-- [FRAME UTAMA]
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35) 
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 280) 
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Header.Size = UDim2.new(1, 0, 0, 40)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Kenzo HUB | Fish It"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

local Version = Instance.new("TextLabel")
Version.Parent = Header
Version.BackgroundTransparency = 1
Version.Position = UDim2.new(0.65, 0, 0, 0)
Version.Size = UDim2.new(0.25, 0, 1, 0)
Version.Font = Enum.Font.Gotham
Version.Text = "V3.2 Fix"
Version.TextColor3 = Color3.fromRGB(150, 150, 150)
Version.TextSize = 12

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.Size = UDim2.new(0, 120, 1, -40)

local TabButton = Instance.new("TextButton")
TabButton.Parent = Sidebar
TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45) 
TabButton.Position = UDim2.new(0, 10, 0, 10)
TabButton.Size = UDim2.new(0, 100, 0, 35)
TabButton.Font = Enum.Font.GothamSemibold
TabButton.Text = "  🏠 General"
TabButton.TextColor3 = Color3.fromRGB(85, 255, 255) 
TabButton.TextSize = 14
TabButton.TextXAlignment = Enum.TextXAlignment.Left
local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 6)
TabCorner.Parent = TabButton

-- Content Area
local Content = Instance.new("Frame")
Content.Parent = MainFrame
Content.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Content.Position = UDim2.new(0, 130, 0, 50)
Content.Size = UDim2.new(0, 310, 1, -50)

-- FITUR 1: TOGGLE
local FeatureFrame = Instance.new("Frame")
FeatureFrame.Parent = Content
FeatureFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
FeatureFrame.Size = UDim2.new(0.95, 0, 0, 50)
FeatureFrame.Position = UDim2.new(0, 0, 0, 0)

local FeatureCorner = Instance.new("UICorner")
FeatureCorner.CornerRadius = UDim.new(0, 8)
FeatureCorner.Parent = FeatureFrame

local FeatureLabel = Instance.new("TextLabel")
FeatureLabel.Parent = FeatureFrame
FeatureLabel.BackgroundTransparency = 1
FeatureLabel.Position = UDim2.new(0, 15, 0, 0)
FeatureLabel.Size = UDim2.new(0.6, 0, 1, 0)
FeatureLabel.Font = Enum.Font.GothamSemibold
FeatureLabel.Text = "Auto Send WhatsApp"
FeatureLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FeatureLabel.TextSize = 14
FeatureLabel.TextXAlignment = Enum.TextXAlignment.Left

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = FeatureFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
ToggleBtn.Size = UDim2.new(0, 50, 0, 25)
ToggleBtn.Text = ""
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local Circle = Instance.new("Frame")
Circle.Parent = ToggleBtn
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Circle.Position = UDim2.new(0, 2, 0.5, -10) 
Circle.Size = UDim2.new(0, 20, 0, 20)
local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

-- FITUR 2: TEST BUTTON
local TestBtn = Instance.new("TextButton")
TestBtn.Parent = Content
TestBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TestBtn.Position = UDim2.new(0, 0, 0, 60) 
TestBtn.Size = UDim2.new(0.95, 0, 0, 40)
TestBtn.Font = Enum.Font.GothamBold
TestBtn.Text = "📢  TEST WHATSAPP (CLICK ME)"
TestBtn.TextColor3 = Color3.fromRGB(85, 255, 255)
TestBtn.TextSize = 14
local TestCorner = Instance.new("UICorner")
TestCorner.CornerRadius = UDim.new(0, 8)
TestCorner.Parent = TestBtn

-- Logic: Toggle
local isOn = false
ToggleBtn.MouseButton1Click:Connect(function()
    isOn = not isOn
    getgenv().KenzoConfig.IsScanning = isOn

    if isOn then
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 200)}):Play()
        FeatureLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    else
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        FeatureLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- Logic: Test Button
TestBtn.MouseButton1Click:Connect(function()
    game.StarterGui:SetCore("SendNotification", {Title="Testing...", Text="Mengirim pesan tes...", Duration=2})
    testConnection()
end)

-- Logic: Drag MainFrame
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- TOMBOL HEADER (CLOSE & MINIMIZE)

-- Close Button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Header
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 16
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize Button (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Parent = Header
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -60, 0, 0) 
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 20

-- Logic: Minimize & Restore
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

game.StarterGui:SetCore("SendNotification", {Title="Kenzo HUB V3.2", Text="Anti-Double Active!", Duration=5})
