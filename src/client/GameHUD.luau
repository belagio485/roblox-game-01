-- GameHUD: the score bar, the start screen and the end screens of
-- Crystal Rush. The bar sits at the top centre and right, clear of the
-- top-left corner where Roblox draws its own menu buttons. Every screen
-- is built once here and only shown or hidden as the phase changes.
local LevelConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelConfig"))

local GameHUD = {}

local palette = LevelConfig.PALETTE

local function makeLabel(parent, name, text, size, position, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = palette.HudText
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = palette.Button
	button.Font = Enum.Font.GothamBold
	button.TextSize = 22
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%d:%02d", minutes, rest)
end

-- build creates the whole interface and returns its handles plus the two
-- buttons the client wires to the server's start and next commands.
function GameHUD.build(parent)
	local hud = {}

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.fromScale(0.62, 0.02)
	topBar.Size = UDim2.fromScale(0.68, 0.07)
	topBar.BackgroundTransparency = 1
	topBar.Parent = parent
	hud.topBar = topBar

	hud.levelLabel = makeLabel(topBar, "Level", "LEVEL 1/3", UDim2.fromScale(0.3, 1), UDim2.fromScale(0, 0), 20)
	hud.scoreLabel = makeLabel(topBar, "Score", "SCORE 0", UDim2.fromScale(0.3, 1), UDim2.fromScale(0.33, 0), 20)
	hud.timeLabel = makeLabel(topBar, "Time", "TIME 1:15", UDim2.fromScale(0.2, 1), UDim2.fromScale(0.66, 0), 20)
	hud.crystalLabel = makeLabel(topBar, "Crystals", "CRYSTALS 0/6", UDim2.fromScale(0.2, 1), UDim2.fromScale(0.84, 0), 16)

	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.AnchorPoint = Vector2.new(0.5, 0)
	statusBar.Position = UDim2.fromScale(0.5, 0.1)
	statusBar.Size = UDim2.fromScale(0.5, 0.05)
	statusBar.BackgroundTransparency = 1
	statusBar.Parent = parent
	hud.livesLabel = makeLabel(statusBar, "Lives", "LIVES 3", UDim2.fromScale(0.4, 1), UDim2.fromScale(0, 0), 18)
	hud.comboLabel = makeLabel(statusBar, "Combo", "", UDim2.fromScale(0.6, 1), UDim2.fromScale(0.4, 0), 18)
	hud.comboLabel.TextColor3 = palette.Crystal

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.AnchorPoint = Vector2.new(0.5, 0.5)
	overlay.Position = UDim2.fromScale(0.5, 0.5)
	overlay.Size = UDim2.fromScale(0.7, 0.6)
	overlay.BackgroundColor3 = palette.Panel
	overlay.BackgroundTransparency = 0.1
	overlay.BorderSizePixel = 0
	overlay.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = overlay
	hud.overlay = overlay

	hud.titleLabel = makeLabel(overlay, "Title", "CRYSTAL RUSH", UDim2.fromScale(0.9, 0.25), UDim2.fromScale(0.05, 0.05), 44)
	hud.titleLabel.TextColor3 = palette.Crystal
	hud.subtitleLabel = makeLabel(
		overlay,
		"Subtitle",
		"Collect every crystal. Dodge the drones. Beat the clock.",
		UDim2.fromScale(0.9, 0.12),
		UDim2.fromScale(0.05, 0.32),
		18
	)
	hud.detailLabel = makeLabel(
		overlay,
		"Detail",
		"Move: WASD or Arrow Keys  |  Green orbs add 8 seconds  |  Blue shields block one hit",
		UDim2.fromScale(0.9, 0.12),
		UDim2.fromScale(0.05, 0.46),
		15
	)
	hud.detailLabel.TextColor3 = palette.HudDim

	hud.startButton = makeButton(overlay, "StartButton", "START  (Enter)", UDim2.fromScale(0.4, 0.14), UDim2.fromScale(0.5, 0.72))
	hud.nextButton = makeButton(overlay, "NextButton", "NEXT LEVEL  (Enter)", UDim2.fromScale(0.4, 0.14), UDim2.fromScale(0.5, 0.72))
	hud.nextButton.Visible = false
	return hud
end

-- showStart shows the title screen before the first game.
function GameHUD.showStart(hud)
	hud.overlay.Visible = true
	hud.titleLabel.Text = "CRYSTAL RUSH"
	hud.titleLabel.TextColor3 = palette.Crystal
	hud.subtitleLabel.Text = "Collect every crystal. Dodge the drones. Beat the clock."
	hud.detailLabel.Text = "Move: WASD or Arrow Keys  |  Green orbs add 8 seconds  |  Blue shields block one hit"
	hud.startButton.Visible = true
	hud.nextButton.Visible = false
end

-- showLevelComplete shows the cleared-level screen between levels.
function GameHUD.showLevelComplete(hud, snapshot)
	hud.overlay.Visible = true
	hud.titleLabel.Text = "LEVEL CLEAR!"
	hud.titleLabel.TextColor3 = palette.Energy
	hud.subtitleLabel.Text = snapshot.levelName .. " cleared  |  Score: " .. tostring(snapshot.score)
	hud.detailLabel.Text = "Press Enter or tap Next Level for level " .. tostring(snapshot.levelIndex + 1)
	hud.startButton.Visible = false
	hud.nextButton.Visible = true
end

-- showEnd shows the win screen or the game-over screen, with the score.
function GameHUD.showEnd(hud, snapshot)
	hud.overlay.Visible = true
	if snapshot.phase == "won" then
		hud.titleLabel.Text = "YOU WIN!"
		hud.titleLabel.TextColor3 = palette.Crystal
		hud.subtitleLabel.Text = "All 3 levels cleared  |  Final score: " .. tostring(snapshot.score)
	else
		hud.titleLabel.Text = "GAME OVER"
		hud.titleLabel.TextColor3 = palette.Danger
		if snapshot.lastEvent == "timeUp" then
			hud.subtitleLabel.Text = "Out of time  |  Score: " .. tostring(snapshot.score)
		else
			hud.subtitleLabel.Text = "The drones got you  |  Score: " .. tostring(snapshot.score)
		end
	end
	hud.detailLabel.Text = "Press R or tap Play Again to start over"
	hud.startButton.Text = "PLAY AGAIN  (R)"
	hud.startButton.Visible = true
	hud.nextButton.Visible = false
end

function GameHUD.hideOverlay(hud)
	hud.overlay.Visible = false
end

-- update refreshes the bar from one snapshot: level, score, time left,
-- crystals, lives and the combo multiplier. The timer turns red under
-- ten seconds so the player can read the danger at a glance.
function GameHUD.update(hud, snapshot)
	hud.levelLabel.Text = "LEVEL " .. tostring(snapshot.levelIndex) .. "/" .. tostring(snapshot.levelCount)
	hud.scoreLabel.Text = "SCORE " .. tostring(snapshot.score)
	hud.timeLabel.Text = "TIME " .. formatTime(snapshot.timeLeft)
	if snapshot.timeLeft <= 10 then
		hud.timeLabel.TextColor3 = palette.Danger
	else
		hud.timeLabel.TextColor3 = palette.HudText
	end
	hud.crystalLabel.Text = "CRYSTALS "
		.. tostring(snapshot.crystalsCollected)
		.. "/"
		.. tostring(snapshot.crystalsTotal)
	hud.livesLabel.Text = "LIVES " .. tostring(snapshot.lives)
	if snapshot.shieldActive then
		hud.livesLabel.Text = hud.livesLabel.Text .. "  +SHIELD"
	end
	if snapshot.combo > 1 then
		hud.comboLabel.Text = "COMBO x" .. tostring(snapshot.combo)
	else
		hud.comboLabel.Text = ""
	end
end

return GameHUD
