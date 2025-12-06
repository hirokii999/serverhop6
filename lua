--! best_server_finder.lua

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local placeId = game.PlaceId

local running = false
local cursor = ""
local scannedServers = 0
local lowestPlayers = math.huge -- Tracks the lowest player count found
local bestServerId = nil       -- Tracks the JobId of the best server

-- Configuration (Optional: you can add a UI input for this)
local MIN_PLAYERS_TARGET = 1  -- Minimum player count to consider (e.g., 1 for a truly empty server)
local MAX_PLAYERS_ALLOWED = 40 -- Max players allowed. Currently defaults to server max, but useful for filtering.
local MAX_PAGES_TO_SCAN = 10 -- Safety limit to prevent overly long scans (approx 1000 servers)

--- Core Functions ---

local function notify(txt)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Server Finder";
        Text = txt;
        Duration = 3;
    })
end

--- UI Setup ---

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerFinderUI"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 240, 0, 150) -- Larger frame for more info
Frame.Position = UDim2.new(0.5, -120, 0.5, -75) -- Center the UI
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderColor3 = Color3.fromRGB(15, 15, 15)

local Start = Instance.new("TextButton", Frame)
local Stop = Instance.new("TextButton", Frame)
local Counter = Instance.new("TextLabel", Frame)
local LowPlayerDisplay = Instance.new("TextLabel", Frame) -- New display for lowest player count

Start.Size = UDim2.new(1, -20, 0, 30)
Start.Position = UDim2.new(0, 10, 0, 10)
Start.Text = "START SCAN"
Start.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
Start.TextColor3 = Color3.fromRGB(255, 255, 255)
Start.Font = Enum.Font.SourceSansBold

Stop.Size = UDim2.new(1, -20, 0, 30)
Stop.Position = UDim2.new(0, 10, 0, 45)
Stop.Text = "STOP"
Stop.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
Stop.TextColor3 = Color3.fromRGB(255, 255, 255)
Stop.Font = Enum.Font.SourceSansBold

Counter.Size = UDim2.new(1, -20, 0, 20)
Counter.Position = UDim2.new(0, 10, 0, 80)
Counter.BackgroundTransparency = 1
Counter.TextColor3 = Color3.fromRGB(255, 255, 255)
Counter.Text = "Servers Scanned: 0"
Counter.Font = Enum.Font.SourceSans

LowPlayerDisplay.Size = UDim2.new(1, -20, 0, 20)
LowPlayerDisplay.Position = UDim2.new(0, 10, 0, 110)
LowPlayerDisplay.BackgroundTransparency = 1
LowPlayerDisplay.TextColor3 = Color3.fromRGB(85, 255, 255)
LowPlayerDisplay.Text = "Lowest Found: N/A"
LowPlayerDisplay.Font = Enum.Font.SourceSansBold

local function setStartGreen()
    Start.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    Start.Text = "START SCAN"
end

local function setStartRed()
    Start.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    Start.Text = "SCANNING..."
end

local function updateCounter()
    Counter.Text = "Servers Scanned: " .. scannedServers
    LowPlayerDisplay.Text = "Lowest Found: " .. (lowestPlayers == math.huge and "N/A" or lowestPlayers)
end

--- Main Logic ---

local function findServer()
    running = true
    cursor = ""
    scannedServers = 0
    lowestPlayers = math.huge
    bestServerId = nil
    updateCounter()
    setStartRed()

    notify("Starting scan for the server with the fewest players...")

    local pagesScanned = 0

    while running and pagesScanned < MAX_PAGES_TO_SCAN do
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&cursor=" .. cursor
        
        local ok, response = pcall(function()
            -- Use HttpGetAsync for modern practice
            return HttpService:GetAsync(url)
        end)

        if not ok then
            notify("Error fetching server data: " .. response)
            running = false
            setStartGreen()
            return
        end

        local data
        local success, err = pcall(function()
            data = HttpService:JSONDecode(response)
        end)

        if not success then
             notify("Error decoding server data: " .. err)
             running = false
             setStartGreen()
             return
        end
        
        scannedServers = scannedServers + #data.data
        pagesScanned = pagesScanned + 1
        
        for _, server in ipairs(data.data) do
            if not running then return end

            local players = server.playing
            local max = server.maxPlayers

            -- Only consider servers that are not full and meet
