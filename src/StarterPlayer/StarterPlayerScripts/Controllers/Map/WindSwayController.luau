local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG_NAME = "WindSway"

local WIND_DIRECTION = Vector3.new(1, 0, 0.5).Unit
local WIND_STRENGTH = 0.15
local WIND_SPEED = 0.42
local GUST_STRENGTH = 0.06
local GUST_SPEED = 0.2
local SWAY_TILT = 0.015
local VERTICAL_BOB = 0.025

local SKIP_NAMES = {"Trunk", "Stump", "Log", "Wood", "Base"}

local Local = {}
local Shared = {}

local swayObjects = {}

local function shouldSkip(instance: BasePart): boolean
	local name = string.lower(instance.Name)
	for _, skip in SKIP_NAMES do
		if string.find(name, skip) then
			return true
		end
	end
	return false
end

local function registerObject(instance: BasePart)
	if swayObjects[instance] or shouldSkip(instance) then return end
	swayObjects[instance] = {
		originCFrame = instance.CFrame,
		seed = math.random(0, 10000),
	}
end

local function unregisterObject(instance: BasePart)
	if not swayObjects[instance] then return end
	instance.CFrame = swayObjects[instance].originCFrame
	swayObjects[instance] = nil
end

local function applyToModel(model: Model)
	if model:IsA("BasePart") then
		registerObject(model)
	elseif model:IsA("Model") then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				registerObject(descendant)
			end
		end
	end
end

local function removeFromModel(model: Model)
	if model:IsA("BasePart") then
		unregisterObject(model)
	elseif model:IsA("Model") then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				unregisterObject(descendant)
			end
		end
	end
end

function Shared.OnStart()
	for _, instance in CollectionService:GetTagged(TAG_NAME) do
		applyToModel(instance)
	end

	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(function(instance)
		applyToModel(instance)
	end)

	CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(instance)
		removeFromModel(instance)
	end)

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()

		for part, data in swayObjects do
			local seed = data.seed
			local origin = data.originCFrame

			local noiseX = math.noise(seed * 0.1, t * WIND_SPEED, 0)
			local noiseZ = math.noise(0, t * WIND_SPEED, seed * 0.1)
			local gustNoise = math.noise(seed * 0.05, t * GUST_SPEED, seed * 0.05)

			local swayAmount = (noiseX * WIND_STRENGTH) + (gustNoise * GUST_STRENGTH)
			local lateralSway = noiseZ * WIND_STRENGTH * 0.5

			local offset = WIND_DIRECTION * swayAmount
				+ WIND_DIRECTION:Cross(Vector3.yAxis).Unit * lateralSway
				+ Vector3.new(0, math.sin(t * WIND_SPEED * 2 + seed) * VERTICAL_BOB, 0)

			local tiltX = noiseX * SWAY_TILT
			local tiltZ = noiseZ * SWAY_TILT
			local tiltCFrame = CFrame.Angles(tiltX, 0, tiltZ)

			part.CFrame = origin * CFrame.new(offset) * tiltCFrame
		end
	end)
end

return Shared
