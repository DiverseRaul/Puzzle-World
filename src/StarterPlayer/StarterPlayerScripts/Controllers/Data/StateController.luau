local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild('Remotes').PlayerData

local PlayerDataTemplate = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("PlayerData"))

local Data: PlayerDataTemplate.PlayerData

export type DataType = typeof(PlayerDataTemplate.DEFAULT_PLAYER_DATA)

local Local = {}
local Shared = {}

Shared.UpdateState = Instance.new("BindableEvent")

function Shared.OnStart()
	Remotes.SetData.OnClientEvent:Connect(function(PlayerData: PlayerDataTemplate.PlayerData)
		Data = PlayerData
		Shared.UpdateState:Fire(Data, "Initial")
	end)
	
	Remotes.UpdateData.OnClientEvent:Connect(function(PlayerData: PlayerDataTemplate.PlayerData, ChangedData: string)
		if not Data then return end
		Data = PlayerData
		
		task.spawn(function()
			Shared.UpdateState:Fire(Data, ChangedData)
		end)
	end)	
	
	Remotes.Start:FireServer()
end

function Shared.GetState(): PlayerDataTemplate.PlayerData
	while Data == nil do
		task.wait(0.01)
	end
	
	return Data
end

return Shared