local Local = {}
local Shared = {}

Shared.DEFAULT_PLAYER_DATA = {
	FirstTime = true,
	Currency = {
		Coins = 0,
		PuzzleCoins = 0,
		VipStars = 0,
	},
	Status = {
		PreTester = false,
		NewestUpdate = false,
	}
}

export type PlayerData = typeof(Shared.DEFAULT_PLAYER_DATA)

return Shared
