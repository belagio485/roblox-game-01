-- CrystalSpawner: lays out one level's pickups on the arena grid.
-- The layout is seeded per level, so every player meets the same level,
-- while the exact crystal spots are shuffled inside it. Nothing spawns on
-- the player's start cell or on a drone's patrol route.
local LevelConfig = require(script.Parent.LevelConfig)

local CrystalSpawner = {}

local SPAWN_CLEAR_RADIUS = 2

local function isClearOfSpawn(x, y)
	local dx = x - LevelConfig.PLAYER_START_X
	local dy = y - LevelConfig.PLAYER_START_Y
	return (dx * dx + dy * dy) > (SPAWN_CLEAR_RADIUS * SPAWN_CLEAR_RADIUS)
end

local function shuffledCells(seed)
	local rng = Random.new(seed)
	local cells = {}
	for x = 1, LevelConfig.ARENA_WIDTH do
		for y = 1, LevelConfig.ARENA_HEIGHT do
			if isClearOfSpawn(x, y) then
				table.insert(cells, { x = x, y = y })
			end
		end
	end
	for i = #cells, 2, -1 do
		local j = rng:NextInteger(1, i)
		cells[i], cells[j] = cells[j], cells[i]
	end
	return cells
end

-- buildLayout returns the pickups for a level: crystals first, then the
-- energy orbs that add time, then the shield that absorbs one drone hit.
-- Each pickup is { id, kind, x, y, taken }.
function CrystalSpawner.buildLayout(levelIndex, level)
	local cells = shuffledCells(levelIndex * 1000 + 7)
	local pickups = {}
	local nextId = 1
	local function place(kind)
		local cell = table.remove(cells, 1)
		if cell == nil then
			return
		end
		table.insert(pickups, {
			id = nextId,
			kind = kind,
			x = cell.x,
			y = cell.y,
			taken = false,
		})
		nextId = nextId + 1
	end
	for _ = 1, level.crystals do
		place("crystal")
	end
	for _ = 1, level.energyOrbs do
		place("energy")
	end
	for _ = 1, level.shields do
		place("shield")
	end
	return pickups
end

function CrystalSpawner.remainingCrystals(pickups)
	local remaining = 0
	for _, pickup in ipairs(pickups) do
		if pickup.kind == "crystal" and not pickup.taken then
			remaining = remaining + 1
		end
	end
	return remaining
end

function CrystalSpawner.totalCrystals(pickups)
	local total = 0
	for _, pickup in ipairs(pickups) do
		if pickup.kind == "crystal" then
			total = total + 1
		end
	end
	return total
end

return CrystalSpawner
