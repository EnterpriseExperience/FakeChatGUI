local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
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

for _, name in ipairs(users) do
   if name == LocalPlayer.Name then
      LocalPlayer:Kick("Blacklisted from: Flames Hub | Services.")
      task.wait(0.5)
      while true do end
   end
end

for _, name in ipairs(users) do
   if Players:FindFirstChild(name) then
      getgenv().notify("Warning", "A blacklisted user is in this server: "..name, 5)
   end
end

Players.PlayerAdded:Connect(function(Player)
   for _, name in ipairs(users) do
      if Player.Name == name then
         getgenv().notify("Warning", "A blacklisted user joined: "..name, 5)
      end
   end
end)
