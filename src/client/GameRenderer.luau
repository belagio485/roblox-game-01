-- GameRenderer: draws the arena on screen from the server's snapshots.
-- Everything is placed by cell coordinate with UDim2 scale, so the board
-- keeps its shape on any screen size. Frames are reused by id, never
-- rebuilt every snapshot, so rendering stays cheap at 15 snapshots a second.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))

local GameRenderer = {}

local palette = LevelConfig.PALETTE

local function cellPosition(x, y)
	return UDim2.fromScale(
		(x - 0.5) / LevelConfig.ARENA_WIDTH,
		(y - 0.5) / LevelConfig.ARENA_HEIGHT
	)
end

local function cellSize(cells)
	return UDim2.fromScale(
		cells / LevelConfig.ARENA_WIDTH,
		cells / LevelConfig.ARENA_HEIGHT
	)
end

local function makeFrame(parent, name, size, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function roundCorners(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = frame
end

-- buildArena creates the board frame and returns the renderer state the
-- client keeps: the arena, the player frame and the pickup/drone caches.
function GameRenderer.buildArena(parent)
	local arena = Instance.new("Frame")
	arena.Name = "Arena"
	arena.AnchorPoint = Vector2.new(0.5, 0.5)
	arena.Position = UDim2.fromScale(0.5, 0.55)
	arena.Size = UDim2.fromScale(0.92, 0.72)
	arena.BackgroundColor3 = palette.Arena
	arena.BorderSizePixel = 0
	arena.Parent = parent
	roundCorners(arena, 12)
	local border = Instance.new("UIStroke")
	border.Color = palette.ArenaBorder
	border.Thickness = 3
	border.Parent = arena

	local player = makeFrame(arena, "Player", cellSize(0.9), palette.Player)
	roundCorners(player, 6)
	local glow = Instance.new("UIStroke")
	glow.Color = palette.PlayerGlow
	glow.Thickness = 2
	glow.Parent = player

	return {
		arena = arena,
		player = player,
		pickups = {},
		drones = {},
	}
end

local PICKUP_LOOK = {
	crystal = { color = palette.Crystal, round = 4, rotation = 45 },
	energy = { color = palette.Energy, round = 40, rotation = 0 },
	shield = { color = palette.Shield, round = 40, rotation = 0 },
}

local function drawPickup(renderer, pickup)
	local frame = renderer.pickups[pickup.id]
	if frame == nil then
		local look = PICKUP_LOOK[pickup.kind] or PICKUP_LOOK.crystal
		frame = makeFrame(renderer.arena, "Pickup" .. pickup.id, cellSize(0.6), look.color)
		frame.Rotation = look.rotation
		roundCorners(frame, look.round)
		renderer.pickups[pickup.id] = frame
	end
	frame.Visible = not pickup.taken
	frame.Position = cellPosition(pickup.x, pickup.y)
end

local function drawDrone(renderer, drone)
	local frame = renderer.drones[drone.id]
	if frame == nil then
		frame = makeFrame(renderer.arena, "Drone" .. drone.id, cellSize(0.9), palette.Drone)
		roundCorners(frame, 40)
		local eye = Instance.new("Frame")
		eye.Name = "Eye"
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(0.5, 0.5)
		eye.Size = UDim2.fromScale(0.35, 0.35)
		eye.BackgroundColor3 = palette.DroneEye
		eye.BorderSizePixel = 0
		eye.Parent = frame
		roundCorners(eye, 40)
		renderer.drones[drone.id] = frame
	end
	frame.Position = cellPosition(drone.x, drone.y)
end

-- render draws one server snapshot: the player, every pickup and drone,
-- and a blink while the player is invulnerable after a hit.
function GameRenderer.render(renderer, snapshot)
	if snapshot == nil or renderer.arena == nil then
		return
	end
	local player = renderer.player
	player.Position = cellPosition(snapshot.playerX, snapshot.playerY)
	if snapshot.invulnerable then
		player.BackgroundTransparency = 0.5
	else
		player.BackgroundTransparency = 0
	end
	for _, pickup in ipairs(snapshot.pickups) do
		drawPickup(renderer, pickup)
	end
	for _, drone in ipairs(snapshot.drones) do
		drawDrone(renderer, drone)
	end
end

return GameRenderer
