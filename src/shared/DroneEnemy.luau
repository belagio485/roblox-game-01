-- DroneEnemy: the hunters of Crystal Rush. A drone patrols between two
-- waypoints until the player comes inside its chase radius, then it turns
-- and chases; it gives up and returns to patrol when the player escapes.
local LevelConfig = require(script.Parent.LevelConfig)

local DroneEnemy = {}

local function distance(ax, ay, bx, by)
	local dx = bx - ax
	local dy = by - ay
	return math.sqrt(dx * dx + dy * dy)
end

-- newDrone places a drone on its patrol line. The patrol endpoints are
-- picked from the level seed so each level's drones guard different lanes.
function DroneEnemy.newDrone(id, levelIndex, droneIndex, level)
	local rng = Random.new(levelIndex * 500 + droneIndex * 31 + 3)
	local y = rng:NextInteger(2, LevelConfig.ARENA_HEIGHT - 1)
	local x1 = rng:NextInteger(6, 10)
	local x2 = rng:NextInteger(13, 18)
	return {
		id = id,
		x = x1,
		y = y,
		waypointX = x2,
		waypointY = y,
		homeX = x1,
		homeY = y,
		speed = level.droneSpeed,
		chaseRadius = level.chaseRadius,
		state = "patrol",
	}
end

-- updateDrone moves one drone for one tick and returns its new state.
-- It never teleports: patrol and chase both move at the drone's speed.
function DroneEnemy.updateDrone(drone, playerX, playerY, dt)
	local targetX = drone.waypointX
	local targetY = drone.waypointY
	local chasing = distance(drone.x, drone.y, playerX, playerY) <= drone.chaseRadius
	if chasing then
		drone.state = "chase"
		targetX = playerX
		targetY = playerY
	elseif drone.state == "chase" then
		drone.state = "patrol"
		targetX = drone.homeX
		targetY = drone.homeY
	end
	local dx = targetX - drone.x
	local dy = targetY - drone.y
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist > 0.001 then
		local step = math.min(dist, drone.speed * dt)
		drone.x = drone.x + (dx / dist) * step
		drone.y = drone.y + (dy / dist) * step
	end
	if not chasing and dist <= drone.speed * dt + 0.05 then
		if drone.waypointX == drone.homeX and drone.waypointY == drone.homeY then
			drone.waypointX = drone.homeX + 6
			if drone.waypointX > LevelConfig.ARENA_WIDTH - 1 then
				drone.waypointX = drone.homeX
			end
		else
			drone.waypointX = drone.homeX
			drone.waypointY = drone.homeY
		end
	end
	drone.x, drone.y = LevelConfig.clampPosition(drone.x, drone.y)
	return drone.state
end

function DroneEnemy.distanceToPlayer(drone, playerX, playerY)
	return distance(drone.x, drone.y, playerX, playerY)
end

return DroneEnemy
