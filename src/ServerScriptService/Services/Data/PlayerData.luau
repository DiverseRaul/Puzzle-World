local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.Remotes.PlayerData

local PlayerDataTemplate = require(ReplicatedStorage.Data.PlayerData)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

local DATA_STORE_KEY = "Release"

if RunService:IsStudio() then
	DATA_STORE_KEY = "StudioTest(2-22-26)[1]"
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFAULT_PLAYER_DATA)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local Local = {}
local Shared = {}

Shared.ProfileLoaded = Instance.new("BindableEvent")

function Shared.OnStart()
	Remotes.Start.OnServerEvent:Connect(function(Player: Player)
		local Data = Shared.GetData(Player)
		if Data then
			Remotes.SetData:FireClient(Player, Data)
		end
	end)
	
	for _, Player in Players:GetPlayers() do
		task.spawn(Local.LoadProfile, Player)
	end
	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)

	task.spawn(Local.TrackPlayTime)
end

function Local.TrackPlayTime()
	while task.wait(60) do
		for _, Player in Players:GetPlayers() do
			local Data = Shared.GetData(Player)
			if Data then
				Data.Stats.TotalPlayTime += 60
			end
		end
	end
end

function Local.LoadProfile(Player: Player)
	local Profile = PlayerStore:StartSessionAsync(`{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})

	if Profile == nil then
		return Player:Kick("Profile Load Fail, Please Rejoin")
	end
	
	Profile:AddUserId(Player.UserId)
	Profile:Reconcile()
	
	Profile.OnSessionEnd:Connect(function()
		Profiles[Player] = nil
		Player:Kick("Profile Session Ended, Please Rejoin")
	end)
	
	local IsInGame = Player.Parent == Players
	if IsInGame then
		Profiles[Player] = Profile
	else
		Profile:EndSession()
	end
	
	Local.CreateLeaderstats(Player)
	Shared.ProfileLoaded:Fire()
	Remotes.SetData:FireClient(Player, Profile.Data)
end

function Local.CreateLeaderstats(Player)
	local Data = Shared.GetData(Player)
	if not Data then return end

	local Leaderstats = Instance.new("Folder", Player)
	Leaderstats.Name = "leaderstats"

	local Coins = Instance.new("NumberValue", Leaderstats)
	Coins.Name = "Coins"
	Coins.Value = Data.Currency.Coins

	local PuzzleCoins = Instance.new("NumberValue", Leaderstats)
	PuzzleCoins.Name = "PuzzleCoins"
	PuzzleCoins.Value = Data.Currency.PuzzleCoins
end

function Shared.GetData(Player: Player): PlayerDataTemplate.PlayerData?
	local Profile = Profiles[Player]
	if not Profile then return end
	
	return Profile.Data
end

function Local.UpdateLeaderstats(Player: Player)
	local Data = Shared.GetData(Player)
	if not Data then return end
	
	local Leaderstats = Player:FindFirstChild("leaderstats")
	if not Leaderstats then return end
	
	Leaderstats.Coins.Value = Data.Currency.Coins
	Leaderstats.PuzzleCoins.Value = Data.Currency.PuzzleCoins
end

function Shared.UpdateCurrency(Player: Player, Currency: string, Amount: number)
	local Data = Shared.GetData(Player)
	if not Data then return end
	
	local CurrencyAmount = Data.Currency[Currency]
	if not CurrencyAmount then return end
	
	Data.Currency[Currency] += Amount
	
	Remotes.UpdateData:FireClient(Player, Data, "Currency")
	
	Local.UpdateLeaderstats(Player)
end

function Shared.UpdateClient(Player: Player, Data: any, Key: string)
	Remotes.UpdateData:FireClient(Player, Data, Key)
end

function Local.RemoveProfile(Player: Player)
	local Profile = Profiles[Player]
	if Profile then
		Profile:EndSession()
	end
end


return Shared
