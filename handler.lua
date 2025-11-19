local http_requesting = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
local httpreq = http_requesting

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


function notify(notif_type, msg, duration)
    NotifyLib:External_Notification(tostring(notif_type), tostring(msg), tonumber(duration))
end
wait(0.1)
if not getgenv().notify then
    getgenv().notify = notify
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
    return warn("Invalid user list (not a table)")
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
    LocalPlayer:Kick(("Temporarily blacklisted from | Flames Hub - Services | Reason: %s (expires %s)")
        :format(entry.reason or "No reason provided", entry.expires or "unknown"))
    task.wait(3)
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
        getgenv().notify("Warning", ("Blacklisted user in server: %s (%s)"):format(name, entry.reason or "No reason"))
    end
end

Players.PlayerAdded:Connect(function(Player)
    local entry = users[Player.Name]
    if entry and not is_expired(entry) then
        getgenv().notify("Warning", ("Blacklisted user joined: %s (%s)"):format(Player.Name, entry.reason or "No reason"), 5)
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
