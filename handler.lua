local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local TeleportService = cloneref and cloneref(game:GetService("TeleportService")) or game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local url = "https://raw.githubusercontent.com/EnterpriseExperience/FakeChatGUI/refs/heads/main/users.json"

local success, result = pcall(function()
    local data = game:HttpGet(url)
    return HttpService:JSONDecode(data)
end)

if not success then
    return warn("Failed to load user list:", result)
end

local users = result
if type(users) ~= "table" then
    return warn("Invalid user list (not a table)")
end

getgenv().blacklisted_users = users

local function is_expired(entry)
    if not entry.expires or entry.expires == "" then return false end
    local y, m, d = entry.expires:match("(%d+)%-(%d+)%-(%d+)")
    if not y or not m or not d then return false end
    local expires = os.time({ year = y, month = m, day = d, hour = 0 })
    return os.time() > expires
end

local entry = users[LocalPlayer.Name]
if entry and not is_expired(entry) then
    LocalPlayer:Kick(("Temporarily blacklisted from | Flames Hub - Services | Reason: %s (expires %s)")
        :format(entry.reason or "No reason provided", entry.expires or "unknown"))
    task.wait(6.5)
    workspace:Destroy()
    if game.Players.LocalPlayer then
        pcall(function()
            game.Players.LocalPlayer:Destroy()
        end)
    end
    while true do end
end

for name, entry in pairs(users) do
   if not is_expired(entry) and Players:FindFirstChild(name) then
      getgenv().notify("Warning", ("Blacklisted user in server: %s (%s)"):format(name, entry.reason or "No reason"), 5)
   end
end

getgenv().BlacklistedUserList_Loaded_Flames_Hub_Hook = true

Players.PlayerAdded:Connect(function(Player)
   local entry = users[Player.Name]
   if entry and not is_expired(entry) then
      getgenv().notify("Warning", ("Blacklisted user joined: %s (%s)"):format(Player.Name, entry.reason or "No reason"), 5)
   end
end)

task.spawn(function()
    while task.wait(0.5) do
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
