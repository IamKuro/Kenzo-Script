--[[ 
    🐟 KENZO HUB - FISH IT WHATSAPP NOTIFIER 🐟
    UI Style: Makori/Fluent Dark Theme
    Features: Toggle On/Off, Server Parser, WhatsApp Integration
]]

-- ⚠️ KONFIGURASI (WAJIB DIISI)
getgenv().KenzoConfig = {
    Token = "ZvKehiTkNVt8YrYn1xAW",    -- Token Fonnte
    GroupID = "120363044268395313@g.us",         -- ID Grup Valid Kamu
    IsScanning = false                           -- Status Awal (Jangan Diubah)
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
local lastSentTime = 0

-- Database Mutasi
local knownMutations = {
    "Big", "Giant", "Skeleton", "Albino", "Dark", "Shiny", "Tiny", 
    "Midas", "Golden", "Rainbow", "Ghost", "Neon", "Radioactive",
    "Atlantis", "Void", "Abyssal", "Cursed", "Blessed", "Stone",
    "Midnight", "Fairy Dust", "Gemstone", "Corrupt", "Galaxy", "Sandy",
    "Lightning"
}

-- Fungsi Kirim WA
local function sendWhatsApp(data)
    if not getgenv().KenzoConfig.IsScanning then return end -- Cek jika dimatikan

    local caption = 
        "*Kenzo HUB | Server Detection*\n" ..
        "🚨 *ALERT! Rare Fish Caught!*\n\n" ..
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

-- Fungsi Proses Pesan
local function processMessage(msg)
    if not getgenv().KenzoConfig.IsScanning then return end

    local cleanMsg = string.gsub(msg, "<.->", "")
    -- Pola Regex Ultimate (Format Server)
    local player, fullFishName, weight, chance = string.match(cleanMsg, "%[Server%]:%s*(.-)%s+obtained%s+a%s+(.-)%s+(%([%d%.]+kg%))%s+with%s+a%s+(.-)%s+chance")
    
    if player and fullFishName then
        if os.time() - lastSentTime > 2 then
            lastSentTime = os.time()
            
            local detectedMutation = "None"
            local realFishName = fullFishName
            
            for _, mut in pairs(knownMutations) do
                if string.find(fullFishName, "^"..mut) then
                    detectedMutation = mut
                    realFishName = string.gsub(fullFishName, mut.."%s*", "")
                    break
                end
            end
            
            sendWhatsApp({player=player, fish=realFishName, mutation=detectedMutation, weight=weight, chance=chance})
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
-- 2. BAGIAN TAMPILAN UI (FRONTEND - ALA MAKORI)
-----------------------------------------------------------
-- Hapus GUI lama jika ada
if CoreGui:FindFirstChild("KenzoHUB") then CoreGui.KenzoHUB:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KenzoHUB"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Warna Gelap
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 280) -- Ukuran Tablet/HP
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
Version.Position = UDim2.new(0.7, 0, 0, 0)
Version.Size = UDim2.new(0.25, 0, 1, 0)
Version.Font = Enum.Font.Gotham
Version.Text = "Ver 1.0"
Version.TextColor3 = Color3.fromRGB(150, 150, 150)
Version.TextSize = 12

-- Sidebar (Kiri)
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.Size = UDim2.new(0, 120, 1, -40)

local TabButton = Instance.new("TextButton")
TabButton.Parent = Sidebar
TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Warna Aktif
TabButton.Position = UDim2.new(0, 10, 0, 10)
TabButton.Size = UDim2.new(0, 100, 0, 35)
TabButton.Font = Enum.Font.GothamSemibold
TabButton.Text = "  🏠 General"
TabButton.TextColor3 = Color3.fromRGB(85, 255, 255) -- Cyan
TabButton.TextSize = 14
TabButton.TextXAlignment = Enum.TextXAlignment.Left
local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 6)
TabCorner.Parent = TabButton

-- Content Area (Kanan)
local Content = Instance.new("Frame")
Content.Parent = MainFrame
Content.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Content.Position = UDim2.new(0, 130, 0, 50)
Content.Size = UDim2.new(0, 310, 1, -50)

-- FITUR TOGGLE (Seperti Gambar Makori)
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

-- Tombol Switch (Toggle)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = FeatureFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Warna Mati
ToggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
ToggleBtn.Size = UDim2.new(0, 50, 0, 25)
ToggleBtn.Text = ""
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local Circle = Instance.new("Frame")
Circle.Parent = ToggleBtn
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Circle.Position = UDim2.new(0, 2, 0.5, -10) -- Posisi Kiri (Mati)
Circle.Size = UDim2.new(0, 20, 0, 20)
local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

-- Logika Toggle (Animasi & Fungsi)
local isOn = false
ToggleBtn.MouseButton1Click:Connect(function()
    isOn = not isOn
    getgenv().KenzoConfig.IsScanning = isOn -- Ubah status scanning

    if isOn then
        -- Animasi Nyala (Ke Kanan + Cyan)
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 200)}):Play() -- Cyan Color
        FeatureLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    else
        -- Animasi Mati (Ke Kiri + Abu)
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        FeatureLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- Fitur Drag (Biar bisa digeser di HP)
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

-- Tombol Close (X) Kecil
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
    ScreenGui:Destroy() -- Tutup UI
end)

game.StarterGui:SetCore("SendNotification", {Title="Kenzo HUB", Text="Menu Aktif! Silakan Nyalakan Toggle.", Duration=5})
