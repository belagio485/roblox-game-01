# roblox-game-01

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/belagio485/roblox-game-01/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/belagio485/roblox-game-01/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

Crystal Rush — a 2D arcade game for Roblox: move a neon miner across a 20×12 grid, collect every gold crystal before the timer runs out, dodge patrolling and chasing drones, grab time orbs (+8s) and shields. 3 levels (Emerald Fields, Magma Depths, Void Citadel), combo multiplier for chained pickups, 3 lives, win/lose/restart flow. Server owns the single GameState and validates every move; the client only renders and sends intents. Built with Luau + Rojo.

## Run it

```sh
rojo build default.project.json --output game.rbxl
MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=fk8azh4p&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
