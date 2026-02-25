local Local = {}
local Shared = {}

Shared.UPDATE_INTERVAL = 120
Shared.TOP_PLAYERS = 100

Shared.Stats = {
	{
		Name = "Coins",
		DisplayName = "Coins",
		ModelName = "CoinsLeaderboard",
		OrderedStoreKey = "LB_Coins",
		GetValue = function(data)
			return data.Currency.Coins or 0
		end,
	},
	{
		Name = "PuzzleCoins",
		DisplayName = "Puzzle Coins",
		ModelName = "PuzzleCoinsLeaderboard",
		OrderedStoreKey = "LB_PuzzleCoins",
		GetValue = function(data)
			return data.Currency.PuzzleCoins or 0
		end,
	},
	{
		Name = "PuzzlesSolved",
		DisplayName = "Puzzles Solved",
		ModelName = "PuzzlesSolvedLeaderboard",
		OrderedStoreKey = "LB_PuzzlesSolved",
		GetValue = function(data)
			return data.Stats.PuzzlesSolved or 0
		end,
	},
	{
		Name = "TotalPlayTime",
		DisplayName = "Play Time",
		ModelName = "TimePlayedLeaderboard",
		OrderedStoreKey = "LB_TotalPlayTime",
		GetValue = function(data)
			return data.Stats.TotalPlayTime or 0
		end,
	},
}

function Shared.GetStatByName(name: string)
	for _, stat in Shared.Stats do
		if stat.Name == name then
			return stat
		end
	end
	return nil
end

return Shared
