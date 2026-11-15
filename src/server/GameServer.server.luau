-- init.server: the server bootstrap for Crystal Rush. It creates the
-- RemoteEvents, owns the one GameState, runs the game loop on Heartbeat,
-- and broadcasts snapshots and sound events to every client. One bad tick
-- is caught and warned about, so it can never kill the game loop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameState = require(script.Parent.GameState)
local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))

local state = GameState.new()

local function createRemote(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing ~= nil then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local moveIntent = createRemote("MoveIntent")
local gameCommand = createRemote("GameCommand")
local stateSnapshot = createRemote("StateSnapshot")
local gameEvent = createRemote("GameEvent")

-- A client sends its held direction; the server clamps it in GameState.
moveIntent.OnServerEvent:Connect(function(player, directionX, directionY)
	if typeof(directionX) ~= "number" or typeof(directionY) ~= "number" then
		return
	end
	GameState.setMoveDirection(state, directionX, directionY)
end)

-- Commands from the client: "start" begins a new game, "next" advances
-- after a level is cleared, "restart" starts over after a win or a loss.
gameCommand.OnServerEvent:Connect(function(player, command)
	if command == "start" or command == "restart" then
		GameState.startGame(state)
	elseif command == "next" then
		GameState.advanceLevel(state)
	end
end)

-- The game loop: advance the state every frame, broadcast a snapshot at
-- the configured rate, and fan each event out as a sound cue.
local snapshotAccumulator = 0
local snapshotInterval = 1 / LevelConfig.SNAPSHOT_RATE_HZ
RunService.Heartbeat:Connect(function(dt)
	local ok, events = pcall(GameState.tick, state, dt)
	if not ok then
		warn("[CrystalRush] tick failed: " .. tostring(events))
		return
	end
	snapshotAccumulator = snapshotAccumulator + dt
	if snapshotAccumulator >= snapshotInterval then
		snapshotAccumulator = 0
		local snapshotOk, snapshot = pcall(GameState.snapshot, state)
		if snapshotOk then
			stateSnapshot:FireAllClients(snapshot)
		end
	end
	if events ~= nil then
		for _, eventName in ipairs(events) do
			gameEvent:FireAllClients(eventName)
		end
	end
end)

-- A player who joins mid-game gets the current state at once.
Players.PlayerAdded:Connect(function(player)
	local snapshotOk, snapshot = pcall(GameState.snapshot, state)
	if snapshotOk then
		stateSnapshot:FireClient(player, snapshot)
	end
end)

print("[CrystalRush] server ready: 3 levels, " .. LevelConfig.levelCount() .. " in all")
