-- Services (pre-init, less reuse)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")


-- Webhook URL
local WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL"

-- Config
local RETRY_ON_FAILURE = false -- i did NOT suggest this on, it causes rate limits and infinite loops
local RETRY_DELAY = 5.0
local REQUEST_INTERVAL = 1.0
local MAX_QUEUE = 200

-- Queue
local queue = {}
local sessions = {}

---- WEBHOOK SENDER ----

task.spawn(function()
	while true do
		if #queue > 0 then
			local job = table.remove(queue, 1)

			local success, response = pcall(function()
				return HttpService:PostAsync(
					WEBHOOK_URL,
					HttpService:JSONEncode(job),
					Enum.HttpContentType.ApplicationJson
				)
			end)

			if not success then
				warn("Webhook failed: " .. tostring(response) .. "!")

				if RETRY_ON_FAILURE then
					table.insert(queue, 1, job)
					task.wait(RETRY_DELAY)
				else
					warn("RETRY_ON_FAILURE off, data ignored.")
				end
			end
			task.wait(REQUEST_INTERVAL)
		else
			task.wait(0.1)
		end
	end
end)

---- HELPER FUNCTIONS ----

-- Get Params --

local function getRuntime()
	if RunService:IsStudio() then
		return "Roblox Studio"
	else
		return "Live Client"
	end
end

--

local function getProfileUrl(userId)
	return "https://www.roblox.com/users/" .. userId .. "/profile"
end

--

local function getThumbnail(userId)
	local url = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds="
		.. userId ..
		"&size=420x420&format=Png&isCircular=false"

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if not success then
		return nil
	end
	
	local data = HttpService:JSONDecode(response)
	if data and data.data and data.data[1] then
		return data.data[1].imageUrl
	end

	return nil
end

--

local function getPlaceName()
	return MarketplaceService:GetProductInfo(game.PlaceId).Name
end

--

local function getCountry(player)
	local success, result = pcall(function()
		return LocalizationService:GetCountryRegionForPlayerAsync(player)
	end)

	return success and result or "Unknown"
end

--

local function getServerType()
	if game.PrivateServerId ~= "" then
		return game.PrivateServerOwnerId ~= 0 and "Private Server" or "Reserved Server"
	end
	return "Public Server"
end

--

local function getServerRegion()
	return ServerStorage:WaitForChild("Region").Value or "Unknown"
end

--

local function getJoinMethod(player)
	if not player then return "Unknown (Nil Player)" end
	local success, data = pcall(function()
		return player:GetJoinData()
	end)

	if success and data then
		if data.SourcePlaceId and data.SourcePlaceId > 0 then
			return "Teleport (From ID: " .. data.SourcePlaceId .. ")"
		elseif data.ReferredByPlayerId and data.ReferredByPlayerId > 0 then
			return "Friend Invite (By ID: " .. data.ReferredByPlayerId .. ")"
		elseif data.LaunchData and data.LaunchData ~= "" then
			return "Launch Link (Data: " .. data.LaunchData .. ")"
		else
			return "Standard Join"
		end
	end
	return "Standard Join (Direct)"
end

-- Format Duration --

local function formatDuration(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60

	return string.format("%02dh %02dm %02ds", h, m, s)
end

-- Enqueue --

local function enqueue(data)
	if #queue >= MAX_QUEUE then
		warn("Queue overflow")
		return
	end

	table.insert(queue, data)
end

---- MAIN EVENTS ----

-- Join Event --

Players.PlayerAdded:Connect(function(player)
	local joinTime = os.time()

	sessions[player.UserId] = {
		joinTime = joinTime,
		place = game.PlaceId,
		joinMessageLink = nil,
	}

	local embed = {
		["embeds"] = {{
			["title"] = "🟢 Player Joined",
			["color"] = 65280,
			["thumbnail"] = {["url"] = getThumbnail(player.UserId)},
			["fields"] = {
				{name = "Username", value = player.Name, inline = true},
				{name = "Display Name", value = player.DisplayName, inline = true},
				{name = "UserId", value = tostring(player.UserId), inline = true},
				
				{name = "Profile", value = "[Link](" .. getProfileUrl(player.UserId) .. ")", inline = true},
				
				{name = "Join Time", value = os.date("!%Y-%m-%d %H:%M:%S", joinTime), inline = false},

				{name = "Place", value = getPlaceName(), inline = true},
				{name = "PlaceId", value = tostring(game.PlaceId), inline = true},
				
				{name = "Country", value = getCountry(player), inline = false},
				
				{name = "Server Region", value = getServerRegion(), inline = true},
				{name = "Server Type", value = getServerType(), inline = true},
				{name = "Job ID", value = game.JobId or "0", inline = true},
				
				{name = "Runtime", value = getRuntime(), inline = true},
				{name = "Join Method", value = getJoinMethod(player), inline = true}
			}
		}}
	}

	enqueue(embed)
end)

-- Leave Event --

Players.PlayerRemoving:Connect(function(player, exitReason)
	local leaveTime = os.time()
	local session = sessions[player.UserId]

	local duration = 0
	if session then
		duration = leaveTime - session.joinTime
	end
	
	local reasonString = exitReason and tostring(exitReason.Name) or "Unknown/Timed Out"

	local embed = {
		["embeds"] = {{
			["title"] = "🔴 Player Left",
			["color"] = 16711680,
			["fields"] = {
				{name = "Username", value = player.Name, inline = true},
				{name = "Display Name", value = player.DisplayName, inline = true},
				{name = "UserId", value = tostring(player.UserId), inline = true},
				
				{name = "Profile", value = "[Link](" .. getProfileUrl(player.UserId) .. ")", inline = false},

				{name = "Join Time", value = session and os.date("!%Y-%m-%d %H:%M:%S", session.joinTime) or "Unknown", inline = false},
				{name = "Leave Time", value = os.date("!%Y-%m-%d %H:%M:%S", leaveTime), inline = true},

				{name = "Session Duration", value = formatDuration(duration), inline = false},
				
				{name = "Server Region", value = getServerRegion(), inline = true},
				{name = "Server Type", value = getServerType(), inline = true},
				{name = "Job ID", value = game.JobId or "0", inline = true},
				
				{name = "Runtime", value = getRuntime(), inline = true},
				{name = "Leave Reason", value = reasonString, inline = true},
			}
		}}
	}

	enqueue(embed)

	sessions[player.UserId] = nil
end)

---- END ----