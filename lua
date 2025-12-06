local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local placeId = game.PlaceId
local running = false
local cursor = ""
local scannedServers = 0

local function notify(txt)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Server Finder";
        Text = txt;
        Duration = 3;
    })
end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
local Start = Instance.new("TextButton", Frame)
local Stop = Instance.new("TextButton", Frame)
local Counter = Instance.new("TextLabel", Frame)

Frame.Size = UDim2.new(0,200,0,110)
Frame.Position = UDim2.new(0.1,0,0.2,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

Start.Size = UDim2.new(1,-20,0,30)
Start.Position = UDim2.new(0,10,0,10)
Start.Text = "START"
Start.BackgroundColor3 = Color3.fromRGB(0,170,0)
Start.TextColor3 = Color3.fromRGB(255,255,255)

Stop.Size = UDim2.new(1,-20,0,30)
Stop.Position = UDim2.new(0,10,0,45)
Stop.Text = "STOP"
Stop.BackgroundColor3 = Color3.fromRGB(170,0,0)
Stop.TextColor3 = Color3.fromRGB(255,255,255)

Counter.Size = UDim2.new(1,-20,0,20)
Counter.Position = UDim2.new(0,10,0,80)
Counter.BackgroundTransparency = 1
Counter.TextColor3 = Color3.fromRGB(255,255,255)
Counter.Text = "Scanned: 0"


local function setStartGreen()
    Start.BackgroundColor3 = Color3.fromRGB(0,170,0)
    Start.Text = "START"
end

local function setStartRed()
    Start.BackgroundColor3 = Color3.fromRGB(170,0,0)
    Start.Text = "SCANNING..."
end

local function updateCounter()
    Counter.Text = "Scanned: " .. scannedServers
end


local function findServer()
    running = true
    cursor = ""
    scannedServers = 0
    updateCounter()
    setStartRed()

    notify("Searching servers...")

    local found = false

    while running do
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100&cursor="..cursor
        
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if not ok then
            notify("Gagal mendapatkan data server.")
            running = false
            setStartGreen()
            return
        end
        
        scannedServers = scannedServers + #data.data
        updateCounter()

        for _, server in ipairs(data.data) do
            if not running then return end

            if server.playing < server.maxPlayers then
                found = true
                setclipboard(server.id)
                notify("Found! Copying JobId...")
                notify("Teleporting...")

                TeleportService:TeleportToPlaceInstance(placeId, server.id)
                
                running = false
                setStartGreen()
                return
            end
        end

        if data.nextPageCursor then
            cursor = data.nextPageCursor
        else
            break
        end
    end

    if not found then
        notify("Tidak ditemukan server yang cocok.")
        running = false
        setStartGreen()
    end
end


Start.MouseButton1Click:Connect(function()
    if not running then
        findServer()
    end
end)

Stop.MouseButton1Click:Connect(function()
    running = false
    notify("Stopped.")
    setStartGreen()
end)
