-- SoundEffects: every sound Crystal Rush plays, from Roblox's own
-- built-in sounds, so the game needs no uploaded audio assets. One
-- ping sound is re-pitched per cue: high for a pickup, low for a hit.
local SoundService = game:GetService("SoundService")

local SoundEffects = {}

local PING_SOUND = "rbxasset://sounds/electronicpingshort.wav"
local CLICK_SOUND = "rbxasset://sounds/button.wav"

local CUES = {
	pickup = { soundId = PING_SOUND, pitch = 1.4, volume = 0.5 },
	energy = { soundId = PING_SOUND, pitch = 1.8, volume = 0.5 },
	shield = { soundId = PING_SOUND, pitch = 1.0, volume = 0.5 },
	shieldBreak = { soundId = PING_SOUND, pitch = 0.6, volume = 0.6 },
	hurt = { soundId = PING_SOUND, pitch = 0.5, volume = 0.7 },
	levelComplete = { soundId = PING_SOUND, pitch = 1.6, volume = 0.6 },
	gameWon = { soundId = PING_SOUND, pitch = 2.0, volume = 0.7 },
	gameOver = { soundId = PING_SOUND, pitch = 0.4, volume = 0.7 },
	timeUp = { soundId = PING_SOUND, pitch = 0.4, volume = 0.7 },
	click = { soundId = CLICK_SOUND, pitch = 1.0, volume = 0.5 },
}

local sounds = {}

function SoundEffects.init()
	for cueName, cue in pairs(CUES) do
		local sound = Instance.new("Sound")
		sound.Name = "CrystalRush_" .. cueName
		sound.SoundId = cue.soundId
		sound.PlaybackSpeed = cue.pitch
		sound.Volume = cue.volume
		sound.Parent = SoundService
		sounds[cueName] = sound
	end
end

-- play fires one cue. Unknown cues are ignored, so a future server
-- event can never break the client by naming a sound that is not here.
function SoundEffects.play(cueName)
	local sound = sounds[cueName]
	if sound == nil then
		return
	end
	sound:Play()
end

return SoundEffects
