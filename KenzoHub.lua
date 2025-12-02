--[[ 
    🐟 KENZO HUB - ULTIMATE EDITION 🐟
    Version: 2.0 (Math Parser)
    Fitur: 
    - UI Dark Theme (Makori Style)
    - Anti-Duplicate (Tidak spam pesan sama)
    - Smart Filter: Hanya kirim jika Chance >= 1 in 250k
    - Support satuan K (Ribu), M (Juta), B (Miliar)
]]

-- ⚠️ KONFIGURASI (WAJIB DIISI)
getgenv().KenzoConfig = {
    Token = "ZvKehiTkNVt8YrYn1xAW",    -- Token Fonnte
    GroupID = "120363044268395313@g.us",         -- ID Grup Valid Kamu
    IsScanning = false                           -- Status Awal (OFF)
}

-----------------------------------------------------------
-- 1. BAGIAN LOGIKA SISTEM (BACKEND CANGGIH)
-----------------------------------------------------------
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local http_request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

-- Variabel Anti-Duplicate
local lastSentTime = 0
local lastMessageContent = ""

-- [SETTING BATAS SECRET]
-- 250k = 250000. Ganti angka ini jika batasan berubah.
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
    -- Ambil angka dan huruf belakangnya
    local valueStr, suffix = string.match(chanceString, "1 in ([%d%.]+)(%a?)")
    
    if not valueStr then return 0 end
    
    local number = tonumber(valueStr)
    if not number then return 0 end
    
    local multiplier = 1
    local s = string.lower(suffix or "")
    
    if s == "k" then multiplier = 1000        -- Ribuan
    elseif s == "m" then multiplier = 1000000     -- Jutaan
    elseif s == "b" then multiplier = 1000000000  -- Miliar
    end
    
    return number * multiplier
end

-- Fungsi Kirim WA
local function sendWhatsApp(data)
    if not getgenv().KenzoConfig.IsScanning then return end 

    local caption = 
        "*Kenzo HUB | Secret Found!*\n" ..
        "🚨 *ALERT! Rare Catch (1 in ".. data.chance ..")*\n\n" ..
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

-- Fungsi Utama (Processor)
local function processMessage(msg)
    if not getgenv().KenzoConfig.IsScanning then return end

    local cleanMsg = string.gsub(msg, "<.->", "")

    -- Cek Duplikat (Pesan sama dalam 5 detik = STOP)
    if cleanMsg == lastMessageContent and (os.time() - lastSentTime) < 5 then
        return 
    end

    -- Baca Format Server
    local player, fullFishName, weight, chanceRaw = string.match(cleanMsg, "%[Server%]:%s*(.-)%s+obtained%s+a%s+(.-)%s+(%([%d%.]+kg%))%s+with%s+a%s+(.-)%s+chance")
    
    if player and fullFishName and chanceRaw then
        -- Hitung Angka Peluang
        local rarityValue = parseChanceValue(chanceRaw)
        
        -- FILTER: Hanya lolos jika >= 250.000
        if rarityValue >= RARITY_THRESHOLD then
            
            lastSentTime = os.time()
            lastMessageContent = cleanMsg 
            
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
-- 2. BAGIAN TAMPILAN UI (FRONTEND - MAKORI STYLE)
-----------------------------------------------------------
if CoreGui:FindFirstChild("KenzoHUB") then CoreGui.KenzoHUB:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KenzoHUB"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
Version.Position = UDim2.new(0.7, 0, 0, 0)
Version.Size = UDim2.new(0.25, 0, 1, 0)
