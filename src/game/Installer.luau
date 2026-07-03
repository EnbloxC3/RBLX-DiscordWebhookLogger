-- This script only for model file (.rbxm one) for replacing scripts automatically, you can ignore this script if you manually drag and drop or copy and paste
-- You can run this script in command bar 

-- Use `require(game.Workspace:FindFirstChild("RBLX-DiscordWebhookLogger").Installer).install()` to run this script

local Installer = {}

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function moveChildren(from, to, overwrite)
	for _, child in ipairs(from:GetChildren()) do
		local existing = to:FindFirstChild(child.Name)

		if existing then
			if overwrite then
				existing:Destroy()
				child.Parent = to
			end
			-- ign
		else
			child.Parent = to
		end
	end
end

function Installer.install(overwrite)
	local model = script.Parent

	local storageFolder = model:FindFirstChild("ServerStorage")
	local scriptFolder = model:FindFirstChild("ServerScriptService")

	assert(storageFolder, "Missing ServerStorage folder.")
	assert(scriptFolder, "Missing ServerScriptService folder.")

	moveChildren(scriptFolder, ServerScriptService, overwrite)
    moveChildren(storageFolder, ServerStorage, false)

	model:Destroy()

	print("Installed successfully!")
end

return Installer