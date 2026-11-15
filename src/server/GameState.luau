-- GameState: the one place Crystal Rush keeps its state. The server owns
-- this table and nobody else writes to it: the client only renders the
-- snapshots the server broadcasts. Every rule of the game lives here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))
local CrystalSpawner = require(ReplicatedStorage:WaitForChild("CrystalSpawner"))
local DroneEnemy = require(ReplicatedStorage:WaitForChild("DroneEnemy"))

local GameState = {}

local INVULNERABLE_SECONDS = 2

-- new creates a fresh game in the menu phase, waiting for a player.
function GameState.new()
	return {
		phase = "menu",
		levelIndex = 1,
		score = 0,
		lives = LevelConfig.START_LIVES,
		timeLeft = 0,
		combo = 0,
		comboTimer = 0,
		shieldActive = false,
		invulnerableUntil = 0,
		clock = 0,
		player = {
			x = LevelConfig.PLAYER_START_X,
			y = LevelConfig.PLAYER_START_Y,
			directionX = 0,
			directionY = 0,
		},
		pickups = {},
		drones = {},
		lastEvent = "",
	}
end

function GameState.startGame(state)
	state.score = 0
	state.lives = LevelConfig.START_LIVES
	state.combo = 0
	state.comboTimer = 0
	state.shieldActive = false
	GameState.startLevel(state, 1)
end

-- startLevel deals a fresh board: the level's pickups, its drones and
-- its timer, with the player back at the start cell.
function GameState.startLevel(state, levelIndex)
	local level = LevelConfig.getLevel(levelIndex)
	if level == nil then
		return
	end
	state.levelIndex = levelIndex
	state.phase = "playing"
	state.timeLeft = level.timeLimit
	state.combo = 0
	state.comboTimer = 0
	state.player.x = LevelConfig.PLAYER_START_X
	state.player.y = LevelConfig.PLAYER_START_Y
	state.player.directionX = 0
	state.player.directionY = 0
	state.invulnerableUntil = 0
	state.pickups = CrystalSpawner.buildLayout(levelIndex, level)
	state.drones = {}
	for i = 1, level.drones do
		table.insert(state.drones, DroneEnemy.newDrone(i, levelIndex, i, level))
	end
end

-- setMoveDirection stores the player's held direction. The client sends
-- this when the keys change; the server applies it in tick, so a lagging
-- or lying client can never move the player faster than the rules allow.
function GameState.setMoveDirection(state, directionX, directionY)
	if state.phase ~= "playing" then
		return
	end
	local length = math.sqrt(directionX * directionX + directionY * directionY)
	if length > 1 then
		directionX = directionX / length
		directionY = directionY / length
	end
	state.player.directionX = directionX
	state.player.directionY = directionY
end

local function collectPickup(state, pickup)
	if pickup.kind == "crystal" then
		if state.comboTimer > 0 then
			state.combo = state.combo + 1
		else
			state.combo = 1
		end
		state.comboTimer = LevelConfig.COMBO_WINDOW_SECONDS
		state.score = state.score + LevelConfig.CRYSTAL_POINTS * state.combo
		return "pickup"
	elseif pickup.kind == "energy" then
		state.timeLeft = state.timeLeft + LevelConfig.ENERGY_TIME_BONUS_SECONDS
		return "energy"
	elseif pickup.kind == "shield" then
		state.shieldActive = true
		return "shield"
	end
	return ""
end

local function damagePlayer(state)
	if state.clock < state.invulnerableUntil then
		return ""
	end
	if state.shieldActive then
		state.shieldActive = false
		state.invulnerableUntil = state.clock + INVULNERABLE_SECONDS
		return "shieldBreak"
	end
	state.lives = state.lives - 1
	state.combo = 0
	state.comboTimer = 0
	state.invulnerableUntil = state.clock + INVULNERABLE_SECONDS
	state.player.x = LevelConfig.PLAYER_START_X
	state.player.y = LevelConfig.PLAYER_START_Y
	if state.lives <= 0 then
		state.phase = "lost"
		return "gameOver"
	end
	return "hurt"
end

-- tick advances the whole game by dt seconds and returns the events that
-- happened, so the server can play the matching sounds on every client.
function GameState.tick(state, dt)
	if state.phase ~= "playing" then
		return {}
	end
	state.clock = state.clock + dt
	state.timeLeft = state.timeLeft - dt
	if state.comboTimer > 0 then
		state.comboTimer = state.comboTimer - dt
		if state.comboTimer <= 0 then
			state.combo = 0
		end
	end
	if state.timeLeft <= 0 then
		state.timeLeft = 0
		state.phase = "lost"
		state.lastEvent = "timeUp"
		return { "timeUp" }
	end

	local events = {}
	local player = state.player
	local nextX = player.x + player.directionX * LevelConfig.PLAYER_SPEED * dt
	local nextY = player.y + player.directionY * LevelConfig.PLAYER_SPEED * dt
	player.x, player.y = LevelConfig.clampPosition(nextX, nextY)

	for _, pickup in ipairs(state.pickups) do
		if not pickup.taken then
			local dx = pickup.x - player.x
			local dy = pickup.y - player.y
			if math.sqrt(dx * dx + dy * dy) <= LevelConfig.COLLECT_RADIUS then
				pickup.taken = true
				table.insert(events, collectPickup(state, pickup))
			end
		end
	end

	for _, drone in ipairs(state.drones) do
		DroneEnemy.updateDrone(drone, player.x, player.y, dt)
		if DroneEnemy.distanceToPlayer(drone, player.x, player.y) <= LevelConfig.DRONE_TOUCH_RADIUS then
			local event = damagePlayer(state)
			if event ~= "" then
				table.insert(events, event)
			end
			if state.phase ~= "playing" then
				break
			end
		end
	end

	if state.phase == "playing" and CrystalSpawner.remainingCrystals(state.pickups) == 0 then
		if state.levelIndex >= LevelConfig.levelCount() then
			state.phase = "won"
			table.insert(events, "gameWon")
		else
			state.phase = "levelComplete"
			table.insert(events, "levelComplete")
		end
	end

	if #events > 0 then
		state.lastEvent = events[#events]
	end
	return events
end

-- advanceLevel moves a finished level's player on to the next one.
function GameState.advanceLevel(state)
	if state.phase ~= "levelComplete" then
		return
	end
	GameState.startLevel(state, state.levelIndex + 1)
end

-- snapshot copies the state into a plain table the server can send over
-- a RemoteEvent. Taken pickups and drone waypoints stay server-side.
function GameState.snapshot(state)
	local pickups = {}
	for _, pickup in ipairs(state.pickups) do
		table.insert(pickups, {
			id = pickup.id,
			kind = pickup.kind,
			x = pickup.x,
			y = pickup.y,
			taken = pickup.taken,
		})
	end
	local drones = {}
	for _, drone in ipairs(state.drones) do
		table.insert(drones, {
			id = drone.id,
			x = drone.x,
			y = drone.y,
			state = drone.state,
		})
	end
	return {
		phase = state.phase,
		levelIndex = state.levelIndex,
		levelName = LevelConfig.getLevel(state.levelIndex).name,
		levelCount = LevelConfig.levelCount(),
		score = state.score,
		lives = state.lives,
		timeLeft = math.ceil(state.timeLeft),
		combo = state.combo,
		shieldActive = state.shieldActive,
		invulnerable = state.clock < state.invulnerableUntil,
		playerX = state.player.x,
		playerY = state.player.y,
		crystalsCollected = CrystalSpawner.totalCrystals(state.pickups)
			- CrystalSpawner.remainingCrystals(state.pickups),
		crystalsTotal = CrystalSpawner.totalCrystals(state.pickups),
		pickups = pickups,
		drones = drones,
		lastEvent = state.lastEvent,
	}
end

return GameState
