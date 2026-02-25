local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LeaderboardConfig"))

local Player = Players.LocalPlayer
local LeaderboardFolder = workspace:WaitForChild("World"):WaitForChild("Hub"):WaitForChild("Funcs"):WaitForChild("Leaderboard")

local Local = {}
local Shared = {}

local REFRESH_INTERVAL = 30
local MAX_ENTRIES = 10

local RANK_ICONS = {
	[1] = "🏆",
	[2] = "🥈",
	[3] = "🥉",
}

local COLORS = {
	Background = Color3.fromRGB(245, 240, 225),
	HeaderTop = Color3.fromRGB(255, 140, 50),
	HeaderText = Color3.fromRGB(255, 255, 255),
	EntryEven = Color3.fromRGB(255, 250, 235),
	EntryOdd = Color3.fromRGB(245, 235, 210),
	Gold = Color3.fromRGB(255, 175, 0),
	GoldBg = Color3.fromRGB(255, 245, 200),
	Silver = Color3.fromRGB(130, 145, 170),
	SilverBg = Color3.fromRGB(235, 240, 250),
	Bronze = Color3.fromRGB(200, 130, 50),
	BronzeBg = Color3.fromRGB(255, 240, 220),
	Text = Color3.fromRGB(70, 50, 20),
	ValueText = Color3.fromRGB(120, 90, 40),
	LocalHighlight = Color3.fromRGB(60, 190, 100),
	LocalBg = Color3.fromRGB(220, 255, 230),
	Stroke = Color3.fromRGB(200, 160, 80),
	HeaderStroke = Color3.fromRGB(210, 110, 20),
}

function Shared.OnStart()
	for _, stat in LeaderboardConfig.Stats do
		Local.SetupBoard(stat)
	end

	task.spawn(function()
		while true do
			Local.RefreshAll()
			task.wait(REFRESH_INTERVAL)
		end
	end)
end

function Local.SetupBoard(stat)
	local Model = LeaderboardFolder:WaitForChild(stat.ModelName)
	if not Model then
		warn(`[Leaderboard]: Model "{stat.ModelName}" not found in workspace.Leaderboard`)
		return
	end

	local Board = Model:WaitForChild("Board")
	if not Board then
		warn(`[Leaderboard]: "Board" part not found in {stat.ModelName}`)
		return
	end

	local existing = Board:FindFirstChild("LeaderboardGui")
	if existing then existing:Destroy() end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = Board

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundColor3 = COLORS.Background
	container.BorderSizePixel = 0
	container.Parent = surfaceGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = COLORS.Stroke
	containerStroke.Thickness = 4
	containerStroke.Parent = container

	local containerPadding = Instance.new("UIPadding")
	containerPadding.PaddingLeft = UDim.new(0, 6)
	containerPadding.PaddingRight = UDim.new(0, 6)
	containerPadding.PaddingTop = UDim.new(0, 6)
	containerPadding.PaddingBottom = UDim.new(0, 6)
	containerPadding.Parent = container

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = COLORS.HeaderTop
	header.BorderSizePixel = 0
	header.Parent = container

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = COLORS.HeaderStroke
	headerStroke.Thickness = 3
	headerStroke.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = stat.DisplayName
	title.TextColor3 = COLORS.HeaderText
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = header

	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 12)
	titlePadding.PaddingRight = UDim.new(0, 12)
	titlePadding.PaddingTop = UDim.new(0, 6)
	titlePadding.PaddingBottom = UDim.new(0, 6)
	titlePadding.Parent = title

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -52)
	content.Position = UDim2.new(0, 0, 0, 52)
	content.BackgroundTransparency = 1
	content.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
end

function Local.RefreshAll()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local lbRemotes = remotes:FindFirstChild("Leaderboard")
	if not lbRemotes then return end
	local remote = lbRemotes:FindFirstChild("GetLeaderboard")
	if not remote then return end

	for _, stat in LeaderboardConfig.Stats do
		local success, entries = pcall(function()
			return remote:InvokeServer(stat.Name)
		end)

		if success and entries then
			Local.UpdateBoard(stat, entries)
		end
	end
end

function Local.UpdateBoard(stat, entries)
	local model = LeaderboardFolder:FindFirstChild(stat.ModelName)
	if not model then return end

	local board = model:FindFirstChild("Board")
	if not board then return end

	local gui = board:FindFirstChild("LeaderboardGui")
	if not gui then return end

	local content = gui.Container.Content

	for _, child in content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local count = math.min(#entries, MAX_ENTRIES)

	for i = 1, count do
		Local.CreateEntryRow(content, entries[i], i, stat.Name, count)
	end

	if count == 0 then
		local empty = Instance.new("Frame")
		empty.Size = UDim2.new(1, 0, 1, 0)
		empty.BackgroundTransparency = 1
		empty.Parent = content

		local emptyText = Instance.new("TextLabel")
		emptyText.Size = UDim2.fromScale(1, 1)
		emptyText.BackgroundTransparency = 1
		emptyText.Text = "No players yet!"
		emptyText.TextColor3 = COLORS.ValueText
		emptyText.TextScaled = true
		emptyText.Font = Enum.Font.FredokaOne
		emptyText.Parent = empty
	end
end

function Local.GetRowBgColor(rank: number, isLocal: boolean): Color3
	if isLocal then return COLORS.LocalBg end
	if rank == 1 then return COLORS.GoldBg end
	if rank == 2 then return COLORS.SilverBg end
	if rank == 3 then return COLORS.BronzeBg end
	return if rank % 2 == 0 then COLORS.EntryEven else COLORS.EntryOdd
end

function Local.CreateEntryRow(parent, entry, index: number, statName: string, totalCount: number)
	local isLocal = entry.UserId == Player.UserId
	local bgColor = Local.GetRowBgColor(entry.Rank, isLocal)
	local rowHeight = 1 / totalCount

	local row = Instance.new("Frame")
	row.Name = `Entry_{index}`
	row.Size = UDim2.new(1, 0, rowHeight, -3)
	row.BackgroundColor3 = bgColor
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	if isLocal then
		local highlight = Instance.new("UIStroke")
		highlight.Color = COLORS.LocalHighlight
		highlight.Thickness = 3
		highlight.Parent = row
	elseif entry.Rank <= 3 then
		local rankStroke = Instance.new("UIStroke")
		rankStroke.Color = Local.GetRankColor(entry.Rank)
		rankStroke.Thickness = 2
		rankStroke.Transparency = 0.3
		rankStroke.Parent = row
	end

	local rankText = RANK_ICONS[entry.Rank] or `#{entry.Rank}`

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0.14, 0, 1, 0)
	rankLabel.Position = UDim2.new(0, 0, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = rankText
	rankLabel.TextColor3 = Local.GetRankColor(entry.Rank)
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.FredokaOne
	rankLabel.Parent = row

	local rankPadding = Instance.new("UIPadding")
	rankPadding.PaddingLeft = UDim.new(0, 6)
	rankPadding.PaddingTop = UDim.new(0.12, 0)
	rankPadding.PaddingBottom = UDim.new(0.12, 0)
	rankPadding.Parent = rankLabel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.54, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.14, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.DisplayName or "Unknown"
	nameLabel.TextColor3 = if isLocal then COLORS.LocalHighlight else COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local namePadding = Instance.new("UIPadding")
	namePadding.PaddingLeft = UDim.new(0, 4)
	namePadding.PaddingTop = UDim.new(0.12, 0)
	namePadding.PaddingBottom = UDim.new(0.12, 0)
	namePadding.Parent = nameLabel

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.32, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.68, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = Local.FormatValue(entry.Value, statName)
	valueLabel.TextColor3 = COLORS.ValueText
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.FredokaOne
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row

	local valuePadding = Instance.new("UIPadding")
	valuePadding.PaddingRight = UDim.new(0, 8)
	valuePadding.PaddingTop = UDim.new(0.12, 0)
	valuePadding.PaddingBottom = UDim.new(0.12, 0)
	valuePadding.Parent = valueLabel
end

function Local.FormatValue(value: number, statName: string): string
	if statName == "TotalPlayTime" then
		local hours = math.floor(value / 3600)
		local minutes = math.floor((value % 3600) / 60)
		local seconds = value % 60
		if hours > 0 then
			return `{hours}h {minutes}m`
		elseif minutes > 0 then
			return `{minutes}m {seconds}s`
		end
		return `{seconds}s`
	end

	if value >= 1000000 then
		return string.format("%.1fM", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.1fK", value / 1000)
	end

	return tostring(value)
end

function Local.GetRankColor(rank: number): Color3
	if rank == 1 then return COLORS.Gold end
	if rank == 2 then return COLORS.Silver end
	if rank == 3 then return COLORS.Bronze end
	return COLORS.Text
end

return Shared
