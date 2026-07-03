local ServerStorage = game:GetService("ServerStorage")

function GetServerRegion()
	local http = game:GetService("HttpService")

	local result

	local g,b = pcall(function()
		result = http:JSONDecode(http:GetAsync("https://ipinfo.io/json"))
	end)

	if not g or not result then
		return {"Unknown", "Unknown"}
	end
	local country = result.country
	local region = result.region
	return {country, region}
end

local serverloc = GetServerRegion()
local serverloc2 = table.concat(serverloc, ", ")

if not ServerStorage:FindFirstChild("Region") then
	local region = Instance.new("StringValue")
	region.Name = "Region"
	region.Parent = ServerStorage
end

ServerStorage:WaitForChild("Region").Value = serverloc2