-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

-- Modules
local FieldBuilder = require(game.ServerScriptService.FieldBuilder)

-- Consts
local GID = game.GameId
local green = 65280
local red = 16711680
local yellow = 16766720


-- Webhook URL
local WEBHOOK_URL = ServerStorage:WaitForChild("dcWebhookUrl").Value

-- Config
local RETRY_ON_FAILURE = false -- Not recommended
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
	return string.format("https://www.roblox.com/users/%d/profile", userId)
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
	local region = ServerStorage:WaitForChild("Region")
	if region and region:IsA("ValueBase") then
		return region.Value or "Unknown"
	end
	return "Unknown"
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

-- Format Date --

local function formatDate(time)
	return os.date("!%Y-%m-%d %H:%M:%S", time)
end

-- Enqueue --

local function enqueue(data)
	if #queue >= MAX_QUEUE then
		warn("Queue overflow")
		return
	end

	table.insert(queue, data)
end

-- Embed Helpers --

local function playerFields(player)
	local json = {
		{name = "Username", value = player.Name, inline = true},
		{name = "Display Name", value = player.DisplayName, inline = true},
		{name = "UserId", value = tostring(player.UserId), inline = true},
		{name = "Profile", value = "[Link](" .. getProfileUrl(player.UserId) .. ")", inline = false},
	}
	return json
end

--

local function serverFields(sInstance)
	local json = {
		{name = "Server Region", value = sInstance.serverRegion, inline = true},
		{name = "Server Type", value = sInstance.serverType, inline = true},
		{name = "Job ID", value = sInstance.jobId or "0", inline = true},
	}
	return json
end

--

local function placeFields(sInstance)
	local json = {
		{name = "Place", value = sInstance.placeName, inline = true},
		{name = "PlaceId", value = sInstance.placeId, inline = true},
	}
	return json
end

---- MAIN EVENTS ----

-- Server Start Event --

local function serverStart()
	local createTime = os.time()
	
	sessions[game.GameId] = {
		createTime = createTime,
		place = game.PlaceId,
		placeName = getPlaceName(),
		placeId = game.PlaceId,
		serverRegion = getServerRegion(),
		serverType = getServerType(),
		jobId = game.JobId,
	}
	
	local fields = FieldBuilder.new()
	
	fields
		:field("GameId", tostring(GID), false)
		:field("Creation Time", formatDate(sessions[GID].createTime), false)

		:addAll(placeFields(sessions[GID]))
		:blank()

		:addAll(serverFields(sessions[GID]))
	
	local embed = {
		["embeds"] = {{
			["title"] = "➕ Server Created",
			["color"] = green,
			["fields"] = fields:build(),
		}}
	}

	enqueue(embed)
	
end

-- Chat Event --
local function onChat(player, message)
	local fields = FieldBuilder.new()

	fields
		:addAll(playerFields(player))
		:field("Message", message, false)
		:addAll(placeFields(sessions[GID]))
		:blank()

		:addAll(serverFields(sessions[GID]))

	local embed = {
		["embeds"] = {{
			["title"] = "💬 Player Chat",
			["color"] = yellow,
			["thumbnail"] = {["url"] = sessions[player.UserId].thumbCache},
			["fields"] = fields:build(),
		}}
	}

	enqueue(embed)
end

-- Join Event --

Players.PlayerAdded:Connect(function(player)
	if #Players:GetPlayers() == 1 then
		serverStart()
	end
	
	local joinTime = os.time()

	sessions[player.UserId] = {
		joinTime = joinTime,
		place = game.PlaceId,
		thumbCache = getThumbnail(player.UserId),
	}
	
	local fields = FieldBuilder.new()
	
	fields
		:addAll(playerFields(player))

		:field("Join Time", formatDate(joinTime), false)

		:addAll(placeFields(sessions[GID]))

		:field("Country", getCountry(player), false)

		:addAll(serverFields(sessions[GID]))

		:field("Runtime", getRuntime())
		:field("Join Method", getJoinMethod(player))
	
	local embed = {
		["embeds"] = {{
			["title"] = "🟢 Player Joined",
			["color"] = green,
			["thumbnail"] = {["url"] = sessions[player.UserId].thumbCache},
			["fields"] = fields:build(),
		}}
	}

	enqueue(embed)
	
	-- special: caller for onChat
	player.Chatted:Connect(function(message)
		onChat(player, message)
	end)

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
	
	local fields = FieldBuilder.new()
	
	fields
		:addAll(playerFields(player))

		:field("Join Time", session and formatDate(session.joinTime) or "Unknown")
		:field("Leave Time", formatDate(leaveTime))

		:field("Session Duration", formatDuration(duration), false)

		:addAll(placeFields(sessions[GID]))
		:blank()

		:addAll(serverFields(sessions[GID]))

		:field("Runtime", getRuntime())
		:field("Leave Reason", reasonString)

	local embed = {
		["embeds"] = {{
			["title"] = "🔴 Player Left",
			["color"] = red,
			["fields"] = fields:build(),
		}}
	}

	enqueue(embed)

	sessions[player.UserId] = nil
end)


---- END ----