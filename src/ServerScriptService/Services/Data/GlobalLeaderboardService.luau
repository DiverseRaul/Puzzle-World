local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local LeaderboardConfig = require(ReplicatedStorage.Configs.LeaderboardConfig)

local Remotes = ReplicatedStorage.Remotes
local LeaderboardRemotes = Remotes.Leaderboard
local GetLeaderboard = LeaderboardRemotes.GetLeaderboard

local UPDATE_INTERVAL = LeaderboardConfig.UPDATE_INTERVAL
local TOP_PLAYERS = LeaderboardConfig.TOP_PLAYERS

local Local = {}
local Shared = {}

local Cache = {}
local OrderedStores = {}
local IsUpdating = false

function Shared.OnStart()
	GetLeaderboard.OnServerInvoke = function(Player, StatName: string)
		return Shared.GetCachedLeaderboard(StatName)
	end

	for _, Stat in LeaderboardConfig.Stats do
		if not RunService:IsStudio() then
			OrderedStores[Stat.Name] = DataStoreService:GetOrderedDataStore(Stat.OrderedStoreKey)
		end
		Cache[Stat.Name] = {}
	end

	task.spawn(Local.UpdateLoop)
end

function Local.UpdateLoop()
	while true do
		Local.UpdateAllLeaderboards()
		task.wait(UPDATE_INTERVAL)
	end
end

function Local.UpdateAllLeaderboards()
	if IsUpdating then return end
	IsUpdating = true

	local PlayerDataService = require(ServerScriptService.Services.Data.PlayerData)

	for _, Stat in LeaderboardConfig.Stats do
		Local.SavePlayerStats(Stat, PlayerDataService)
		Local.FetchTopPlayers(Stat)
	end

	IsUpdating = false
end

function Local.SavePlayerStats(stat, PlayerDataService)
	local store = OrderedStores[stat.Name]

	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.GetData(player)
		if data then
			local value = stat.GetValue(data)
			if type(value) == "number" and value > 0 then
				local key = tostring(player.UserId)
				if store then
					local success, err = pcall(function()
						store:SetAsync(key, math.floor(value))
					end)
					if not success then
						warn(`[GlobalLeaderboard]: Failed to save {stat.Name} for {player.Name}: {err}`)
					end
				end
			end
		end
	end
end

function Local.FetchTopPlayers(stat)
	local store = OrderedStores[stat.Name]

	if not store then
		Local.BuildMockCache(stat)
		return
	end

	local success, result = pcall(function()
		return store:GetSortedAsync(false, TOP_PLAYERS)
	end)

	if not success or not result then
		warn(`[GlobalLeaderboard]: Failed to fetch {stat.Name}: {tostring(result)}`)
		return
	end

	local entries = {}
	local page = result:GetCurrentPage()

	for rank, entry in page do
		local userId = tonumber(entry.key)
		local displayName = Local.GetPlayerName(userId)

		table.insert(entries, {
			Rank = rank,
			UserId = userId,
			DisplayName = displayName,
			Value = entry.value,
		})
	end

	Cache[stat.Name] = entries
end

function Local.BuildMockCache(stat)
	local PlayerDataService = require(ServerScriptService.Services.Data.PlayerData)
	local entries = {}

	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.GetData(player)
		if data then
			local value = stat.GetValue(data)
			if type(value) == "number" then
				table.insert(entries, {
					Rank = 0,
					UserId = player.UserId,
					DisplayName = player.DisplayName,
					Value = math.floor(value),
				})
			end
		end
	end

	table.sort(entries, function(a, b) return a.Value > b.Value end)
	for i, entry in entries do
		entry.Rank = i
	end

	Cache[stat.Name] = entries
end

function Local.GetPlayerName(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end

	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	return if success then name else "Unknown"
end

function Shared.GetCachedLeaderboard(statName: string)
	if not statName then return nil end

	local cached = Cache[statName]
	if cached and #cached > 0 then
		return cached
	end

	local stat = LeaderboardConfig.GetStatByName(statName)
	if stat then
		Local.FetchTopPlayers(stat)
	end

	return Cache[statName]
end

return Shared
