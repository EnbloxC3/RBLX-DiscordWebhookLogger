--!nolint LocalShadow
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local providerUrl = "https://ipinfo.io/json"

local region = {
	country = "Unknown",
	region = "Unknown"
}

local function getServerRegion()
	local suc,res = pcall(function()
		return HttpService:GetAsync(providerUrl)
	end)
	if not suc then
		return nil
	end
	
	local result = HttpService:JSONDecode(res)
	
	return {
		country = result.country or "Unknown",
		region = result.region or "Unknown"
	}
end

region = getServerRegion() or region

if not ServerStorage:FindFirstChild("Region") then
	local region = Instance.new("StringValue") 
	region.Name = "Region"
	region.Parent = ServerStorage
end

ServerStorage:WaitForChild("Region").Value = string.format("%s, %s", region.country, region.region)