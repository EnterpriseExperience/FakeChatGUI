local http_requesting = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
local httpreq = http_requesting
getgenv().ConstantUpdate_Checker_Live = true
local Raw_Version = "V7.7.7 (✅)"
local Script_Version = getgenv().Script_Version or getgenv().Script_Version_GlobalGenv

function Notify(message, duration)
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")

    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "CustomErrorGui"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.Parent = CoreGui
    duration = duration or 5

    local Frame = Instance.new("Frame")
    Frame.Name = "ErrorMessage"
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.3
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(0, 500, 0, 120)
    Frame.Position = UDim2.new(0, 20, 0, 100)
    Frame.Parent = NotificationGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame

    local Icon = Instance.new("ImageLabel")
    Icon.Name = "ErrorIcon"
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0, 15, 0.5, -25)
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.Image = "rbxasset://textures/ui/Emotes/ErrorIcon.png"
    Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Name = "ErrorText"
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 80, 0, 10)
    Label.Size = UDim2.new(1, -90, 1, -20)
    Label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json")
    Label.Text = message
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 20
    Label.TextWrapped = true
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Top
    Label.Parent = Frame

    Frame.BackgroundTransparency = 1
    Icon.ImageTransparency = 1
    Label.TextTransparency = 1
    TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
    TweenService:Create(Label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        if Frame and Frame.Parent then
            TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
            TweenService:Create(Label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            task.wait(0.35)
            Frame:Destroy()
            NotificationGui:Destroy()
        end
    end)
end

local function normalize_response(res)
    local status = res.StatusCode or res.statusCode or res.status or res.Status
    local body = res.Body or res.body or res.Response or res.response or ""
    return status, body
end

local function try_load(urls)
    for i = 1, #urls do
        local url = urls[i]
        local ok, res = pcall(function()
            return http_requesting({ Url = url, Method = "GET" })
        end)

        if ok and res then
            local status, body = normalize_response(res)
            if status == 200 and body ~= "" and not tostring(body):find("404: Not Found") then
                local f, err = loadstring(body)
                if f then
                    local s_ok, s_res = pcall(f)
                    if s_ok then
                        return s_res
                    else
                        return { failed = true, status = "load-error", url = url, body = tostring(s_res) }
                    end
                else
                    return { failed = true, status = "compile-error", url = url, body = tostring(err) }
                end
            end
        end
    end
    return { failed = true, status = "no-response", url = urls[#urls] }
end

local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local TeleportService = cloneref and cloneref(game:GetService("TeleportService")) or game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local url = "https://raw.githubusercontent.com/EnterpriseExperience/FakeChatGUI/refs/heads/main/users.json"

local function retrieve_executor()
    local name
    if identifyexecutor then
        name = identifyexecutor()
    end
    return { Name = name or "Unknown Executor" }
end

local function identify_executor()
    local executorDetails = retrieve_executor()
    return tostring(executorDetails.Name)
end

local executor_string = identify_executor()

local function executor_contains(substr)
    if type(executor_string) ~= "string" then
        return false
    end

    return string.find(string.lower(executor_string), string.lower(substr), 1, true) ~= nil
end

local success, result = pcall(function()
    local data = game:HttpGet(url)
    return HttpService:JSONDecode(data)
end)

if not success then
    return warn("Failed to load user list:", result)
end

local users = result
if type(users) ~= "table" then
    return warn("Invalid user list.")
end

getgenv().blacklisted_users = users
getgenv().BlacklistedUserList_Loaded_Flames_Hub_Hook = true

local function is_expired(entry)
    if not entry.expires or entry.expires == "" then return false end
    local y, m, d = entry.expires:match("(%d+)%-(%d+)%-(%d+)")
    if not y or not m or not d then return false end
    local expires = os.time({ year = y, month = m, day = d, hour = 0 })
    return os.time() > expires
end

local entry = users[LocalPlayer.Name]
if entry and not is_expired(entry) then
    LocalPlayer:Kick(("Blacklisted from | Flames Hub - Utilities | Reason: %s (expires: %s)")
        :format(entry.reason or "No reason provided", entry.expires or "unknown"))
    wait(3)
    while true do end
end

for name, entry in pairs(users) do
    if not is_expired(entry) and Players:FindFirstChild(name) then
        getgenv().notify("Warning", ("Blacklisted user in server: %s (%s)"):format(name, entry.reason or "No reason"), 5)
    end
end

if not getgenv().Handler_Func_Initialized_Main then
    Players.PlayerAdded:Connect(function(Player)
        local entry = users[Player.Name]
        if entry and not is_expired(entry) then
            getgenv().notify("Warning", ("Blacklisted user joined: %s (%s)"):format(Player.Name, entry.reason or "No reason"), 6)
            Notify("This is a blacklisted user, you ARE allowed to fling/kill/what ever to them, you are encouraged to do so.", 15)
        end
    end)
    
    task.spawn(function()
        while task.wait(0.3) do
            local refreshed, newdata = pcall(function()
                local data = game:HttpGet(url)
                return HttpService:JSONDecode(data)
            end)
            if refreshed and type(newdata) == "table" then
                getgenv().blacklisted_users = newdata
                users = newdata
            end
    
            local entry = users[LocalPlayer.Name]
            if entry and not is_expired(entry) then
                pcall(function()
                    local placeId = game.PlaceId
                    TeleportService:Teleport(placeId, LocalPlayer)
                end)
            end
        end
    end)
    wait(0.1)
    getgenv().Handler_Func_Initialized_Main = true
end
