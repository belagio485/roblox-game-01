import { cpSync, copyFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier, canonicalJson } from "./vendor/makefun-roblox.ts";

// Crystal Rush entrypoint: copies the game (place, sources, screenshots
// and play link) into the output directory and writes dossier.json with
// the kit's buildDossier, exactly as the competition rules describe.
const repoRoot = dirname(fileURLToPath(import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR || "/output";

mkdirSync(outDir, { recursive: true });

for (const file of ["game.rbxl", "PLAY.json"]) {
	const source = join(repoRoot, file);
	if (!existsSync(source)) {
		throw new Error(`missing required file: ${file}`);
	}
	copyFileSync(source, join(outDir, file));
}
for (const dir of ["src", "screenshots"]) {
	const source = join(repoRoot, dir);
	if (!existsSync(source)) {
		throw new Error(`missing required directory: ${dir}`);
	}
	cpSync(source, join(outDir, dir), { recursive: true });
}

const dossier = await buildDossier(repoRoot, { text_max_bytes: 65536 });
// buildDossier returns the dossier as bytes (a Uint8Array of JSON);
// write those bytes verbatim so the gate's rebuild compares equal.
const dossierBytes =
	dossier instanceof Uint8Array
		? dossier
		: typeof dossier === "string"
			? Buffer.from(dossier, "utf8")
			: Buffer.from(canonicalJson(dossier), "utf8");
writeFileSync(join(outDir, "dossier.json"), dossierBytes);
