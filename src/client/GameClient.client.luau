-- Game.client: the client bootstrap for Crystal Rush. It builds the
-- interface, binds movement with ContextActionService (so the arrow keys
-- work even though Roblox's camera also reads them), sends the held
-- direction to the server when it changes, and renders every snapshot
-- the server broadcasts. The client never owns game state.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameHUD = require(script.Parent.GameHUD)
local GameRenderer = require(script.Parent.GameRenderer)
local SoundEffects = require(script.Parent.SoundEffects)

local moveIntent = ReplicatedStorage:WaitForChild("MoveIntent")
local gameCommand = ReplicatedStorage:WaitForChild("GameCommand")
local stateSnapshot = ReplicatedStorage:WaitForChild("StateSnapshot")
local gameEvent = ReplicatedStorage:WaitForChild("GameEvent")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrystalRushGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local renderer = GameRenderer.buildArena(screenGui)
local hud = GameHUD.build(screenGui)
SoundEffects.init()
GameHUD.showStart(hud)

local currentPhase = "menu"
local heldKeys = {}
local lastSentX = 0
local lastSentY = 0

local KEY_DIRECTIONS = {
	[Enum.KeyCode.W] = { 0, -1 },
	[Enum.KeyCode.Up] = { 0, -1 },
	[Enum.KeyCode.S] = { 0, 1 },
	[Enum.KeyCode.Down] = { 0, 1 },
	[Enum.KeyCode.A] = { -1, 0 },
	[Enum.KeyCode.Left] = { -1, 0 },
	[Enum.KeyCode.D] = { 1, 0 },
	[Enum.KeyCode.Right] = { 1, 0 },
}

local function sendDirection()
	local x = 0
	local y = 0
	for keyCode, _ in pairs(heldKeys) do
		local direction = KEY_DIRECTIONS[keyCode]
		if direction ~= nil then
			x = x + direction[1]
			y = y + direction[2]
		end
	end
	if x ~= lastSentX or y ~= lastSentY then
		lastSentX = x
		lastSentY = y
		moveIntent:FireServer(x, y)
	end
end

-- bindMove wires one key to the held-keys table. ContextActionService,
-- not InputBegan, so the keys answer even when the game already
-- processed them, and touch devices get on-screen buttons for free.
local function bindMove(actionName, keyCode)
	ContextActionService:BindAction(actionName, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			heldKeys[keyCode] = true
		elseif inputState == Enum.UserInputState.End then
			heldKeys[keyCode] = nil
		end
		sendDirection()
	end, true, keyCode)
end
bindMove("MoveUp", Enum.KeyCode.W)
bindMove("MoveUpArrow", Enum.KeyCode.Up)
bindMove("MoveDown", Enum.KeyCode.S)
bindMove("MoveDownArrow", Enum.KeyCode.Down)
bindMove("MoveLeft", Enum.KeyCode.A)
bindMove("MoveLeftArrow", Enum.KeyCode.Left)
bindMove("MoveRight", Enum.KeyCode.D)
bindMove("MoveRightArrow", Enum.KeyCode.Right)

-- Keyboard shortcuts: Enter starts or advances, R restarts after a win
-- or a loss. Buttons do the same for touch players.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Return then
		if currentPhase == "menu" or currentPhase == "lost" or currentPhase == "won" then
			SoundEffects.play("click")
			gameCommand:FireServer("start")
		elseif currentPhase == "levelComplete" then
			SoundEffects.play("click")
			gameCommand:FireServer("next")
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if currentPhase == "lost" or currentPhase == "won" then
			SoundEffects.play("click")
			gameCommand:FireServer("restart")
		end
	end
end)

hud.startButton.Activated:Connect(function()
	SoundEffects.play("click")
	gameCommand:FireServer("start")
end)
hud.nextButton.Activated:Connect(function()
	SoundEffects.play("click")
	gameCommand:FireServer("next")
end)

-- Snapshots drive everything on screen: the board, the bar and which
-- overlay, if any, the phase calls for.
stateSnapshot.OnClientEvent:Connect(function(snapshot)
	currentPhase = snapshot.phase
	GameRenderer.render(renderer, snapshot)
	GameHUD.update(hud, snapshot)
	if snapshot.phase == "playing" then
		GameHUD.hideOverlay(hud)
	elseif snapshot.phase == "menu" then
		GameHUD.showStart(hud)
	elseif snapshot.phase == "levelComplete" then
		GameHUD.showLevelComplete(hud, snapshot)
	elseif snapshot.phase == "won" or snapshot.phase == "lost" then
		GameHUD.showEnd(hud, snapshot)
	end
end)

-- Each server event is a sound cue on the client, nothing more.
gameEvent.OnClientEvent:Connect(function(eventName)
	SoundEffects.play(eventName)
end)
