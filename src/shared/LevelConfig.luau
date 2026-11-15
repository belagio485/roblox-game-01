-- LevelConfig: the single shared definition of Crystal Rush.
-- Both the server (rules, spawning, scoring) and the client (drawing, HUD)
-- require this one module, so the arena, levels and palette can never drift
-- apart between the two sides of the game.
local LevelConfig = {}

-- Arena: a 20 by 12 cell grid. Every position in the game is a cell
-- coordinate; the client turns cells into screen space, the server turns
-- them into movement, collisions and pickups.
LevelConfig.ARENA_WIDTH = 20
LevelConfig.ARENA_HEIGHT = 12

-- Movement and contact distances, in cells.
LevelConfig.PLAYER_SPEED = 8
LevelConfig.PLAYER_RADIUS = 0.45
LevelConfig.COLLECT_RADIUS = 0.75
LevelConfig.DRONE_TOUCH_RADIUS = 0.8

LevelConfig.START_LIVES = 3
LevelConfig.PLAYER_START_X = 2
LevelConfig.PLAYER_START_Y = 6

-- Pickups chained inside this window raise the combo multiplier.
LevelConfig.COMBO_WINDOW_SECONDS = 4
LevelConfig.CRYSTAL_POINTS = 100
LevelConfig.ENERGY_TIME_BONUS_SECONDS = 8

-- How often the server broadcasts a state snapshot to every client.
LevelConfig.SNAPSHOT_RATE_HZ = 15

-- The game's palette: deep space navy, neon cyan, magenta, gold.
LevelConfig.PALETTE = {
	Background = Color3.fromRGB(11, 16, 38),
	Arena = Color3.fromRGB(17, 24, 54),
	ArenaBorder = Color3.fromRGB(34, 211, 238),
	Player = Color3.fromRGB(34, 211, 238),
	PlayerGlow = Color3.fromRGB(165, 243, 252),
	Crystal = Color3.fromRGB(251, 191, 36),
	Energy = Color3.fromRGB(74, 222, 128),
	Shield = Color3.fromRGB(96, 165, 250),
	Drone = Color3.fromRGB(244, 114, 182),
	DroneEye = Color3.fromRGB(255, 255, 255),
	HudText = Color3.fromRGB(226, 232, 240),
	HudDim = Color3.fromRGB(148, 163, 184),
	Danger = Color3.fromRGB(248, 113, 113),
	Panel = Color3.fromRGB(15, 23, 42),
	Button = Color3.fromRGB(8, 145, 178),
}

-- Three levels. Each one is real in the code: more crystals to collect,
-- more and faster drones, a wider chase radius and a tighter timer.
LevelConfig.LEVELS = {
	{
		name = "Emerald Fields",
		subtitle = "Learn the ropes",
		crystals = 6,
		energyOrbs = 2,
		shields = 1,
		drones = 2,
		droneSpeed = 2.2,
		chaseRadius = 4,
		timeLimit = 75,
	},
	{
		name = "Magma Depths",
		subtitle = "The drones hunt in packs",
		crystals = 8,
		energyOrbs = 2,
		shields = 1,
		drones = 3,
		droneSpeed = 2.8,
		chaseRadius = 5,
		timeLimit = 70,
	},
	{
		name = "Void Citadel",
		subtitle = "Every second counts",
		crystals = 10,
		energyOrbs = 3,
		shields = 1,
		drones = 4,
		droneSpeed = 3.4,
		chaseRadius = 6,
		timeLimit = 65,
	},
}

function LevelConfig.getLevel(index)
	local level = LevelConfig.LEVELS[index]
	if level == nil then
		return nil
	end
	return level
end

function LevelConfig.levelCount()
	return #LevelConfig.LEVELS
end

-- Clamp a cell coordinate inside the arena, keeping the player and the
-- drones on the board instead of letting them drift off the screen.
function LevelConfig.clampPosition(x, y)
	local clampedX = math.clamp(x, 1, LevelConfig.ARENA_WIDTH)
	local clampedY = math.clamp(y, 1, LevelConfig.ARENA_HEIGHT)
	return clampedX, clampedY
end

return LevelConfig
