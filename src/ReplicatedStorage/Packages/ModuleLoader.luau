local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local IsServer = RunService:IsServer()
local RootDirectory = if IsServer then ServerScriptService else Players.LocalPlayer:WaitForChild("PlayerScripts")
local ModuleDirectory = if IsServer then RootDirectory.Services else RootDirectory:WaitForChild("Controllers")

local LoadedModules = {}

local function RequireModule(module: ModuleScript)
	if not module:IsA("ModuleScript") then
		return
	end

	local import = require(module)
	LoadedModules[module] = import

	local onStart = import.OnStart
	if onStart then
		task.spawn(onStart)
	end
end

local function ReloadClientModules()
	for module, import in LoadedModules do
		local onStart = import.OnStart
		if onStart then
			task.spawn(onStart)
		end
	end
end

return function()
	for _, descendant: ModuleScript in ModuleDirectory:GetDescendants() do
		RequireModule(descendant)
	end

	if not IsServer then
		ModuleDirectory.DescendantAdded:Connect(function(descendant: ModuleScript)
			RequireModule(descendant)
		end)

		-- Handle character death and respawn
		local player = Players.LocalPlayer
		player.CharacterAdded:Connect(function()
			ReloadClientModules()
		end)
	end
end
