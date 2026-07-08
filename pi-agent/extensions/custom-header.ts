// @ts-nocheck
/**
 * Custom Pi Header — omp-style welcome banner with animated gradient π logo,
 * two-column box layout, and dynamic session info.
 *
 * Ported from: https://github.com/can1357/oh-my-pi (welcome.ts)
 * Adapted to Pi's extension API (setHeader pattern).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

// ─── Logo ────────────────────────────────────────────────────────────────────

const PI_LOGO = [
	"▀██████████▀",
	" ╘██    ██  ",
	"  ██    ██  ",
	"  ██    ██  ",
	" ▄██▄  ▄██▄ ",
];

// ─── Gradient ────────────────────────────────────────────────────────────────

/** Multi-stop palette: hot pink → violet → periwinkle → bright cyan → mint */
const GRADIENT_STOPS: ReadonlyArray<readonly [number, number, number]> = [
	[255, 92, 200],
	[200, 110, 255],
	[120, 130, 255],
	[60, 200, 255],
	[120, 255, 220],
];

const SHINE_HALF_WIDTH = 0.18;

const RESET = "\x1b[0m";

interface ShineConfig {
	strength: number;
	pos: number;
}

function gradientEscape(t: number, shine?: ShineConfig): string {
	const stops = GRADIENT_STOPS;
	const seg = t * (stops.length - 1);
	const i = Math.min(stops.length - 2, Math.floor(seg));
	const f = seg - i;
	const a = stops[i];
	const b = stops[i + 1];
	let r = a[0] + (b[0] - a[0]) * f;
	let g = a[1] + (b[1] - a[1]) * f;
	let bl = a[2] + (b[2] - a[2]) * f;

	if (shine && shine.strength > 0) {
		const dist = Math.abs(t - shine.pos);
		const intensity = Math.max(0, 1 - dist / SHINE_HALF_WIDTH) * shine.strength;
		if (intensity > 0) {
			r += (255 - r) * intensity;
			g += (255 - g) * intensity;
			bl += (255 - bl) * intensity;
		}
	}

	return `\x1b[38;2;${Math.round(r)};${Math.round(g)};${Math.round(bl)}m`;
}

function gradientLogo(
	lines: readonly string[],
	phase = 0,
	shine?: ShineConfig,
): string[] {
	const rows = lines.length;
	const cols = Math.max(...lines.map((l) => l.length));
	const span = Math.max(1, cols + rows - 1);

	return lines.map((line, y) => {
		let result = "";
		for (let x = 0; x < line.length; x++) {
			const char = line[x];
			if (char === " ") {
				result += char;
				continue;
			}
			const base = (x + (rows - 1 - y)) / span;
			const t = (((base + phase) % 1) + 1) % 1;
			result += gradientEscape(t, shine) + char + RESET;
		}
		return result;
	});
}

// Cached resting frame
const REST_FRAME = gradientLogo(PI_LOGO, 0);

// ─── Animation ───────────────────────────────────────────────────────────────

const INTRO_MS = 3000;
const INTRO_TICK_MS = 33;
const INTRO_SWEEPS = 2.5;
const INTRO_SHINE_TRAVERSALS = 3;

function computeLogoFrame(animStart: number | null): readonly string[] {
	if (animStart === null) return REST_FRAME;
	const elapsed = performance.now() - animStart;
	if (elapsed >= INTRO_MS) return REST_FRAME;

	const progress = elapsed / INTRO_MS;
	const eased = 1 - (1 - progress) ** 3; // ease-out cubic
	const phase = ((((1 - eased) * INTRO_SWEEPS) % 1) + 1) % 1;
	const shinePos = (((progress * INTRO_SHINE_TRAVERSALS) % 1) + 1) % 1;
	const shineStrength = (1 - eased) ** 1.5;

	return gradientLogo(PI_LOGO, phase, {
		strength: shineStrength,
		pos: shinePos,
	});
}

// ─── Layout helpers ──────────────────────────────────────────────────────────

/** Compute visible width of a string (strips ANSI escapes). */
function visWidth(str: string): number {
	return str.replace(/\x1b\[[0-9;]*m/g, "").length;
}

/** Center text within a given width. */
function centerText(text: string, width: number): string {
	const vis = visWidth(text);
	if (vis >= width) return truncateToWidth(text, width, "");
	const left = Math.floor((width - vis) / 2);
	return " ".repeat(left) + text + " ".repeat(width - vis - left);
}

/** Fit a string to exact width: pad or truncate. */
function fitToWidth(str: string, width: number): string {
	const vis = visWidth(str);
	if (vis > width) return truncateToWidth(str, width, "");
	return str + " ".repeat(width - vis);
}

// ─── Tips ────────────────────────────────────────────────────────────────────

const TIPS: readonly string[] = [
	"Use /fork to branch a conversation and explore alternatives",
	"Press ctrl+o to expand startup details and loaded resources",
	"Use !! to run bash commands excluded from LLM context",
	"Press escape twice to open the session tree navigator",
	"Use /compact to manually trigger context compaction",
	"Drag and drop images into the editor to attach them",
	"Use # prefix for prompt template actions",
	"Press ctrl+p to open the model selector",
	"Use /tree to navigate between conversation branches",
	"Extensions in ~/.pi/agent/extensions/ auto-reload with /reload",
];

// ─── Extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		// Gather dynamic info before setting header
		let gitBranch = "";
		try {
			const { stdout } = await execFileAsync("git", [
				"-C",
				ctx.cwd,
				"branch",
				"--show-current",
			]);
			gitBranch = stdout.trim() || "detached HEAD";
		} catch {
			gitBranch = "";
		}

		const modelName = ctx.model?.name ?? "no model";
		const providerName = ctx.model?.provider ?? "—";
		const tip = TIPS[Math.floor(Math.random() * TIPS.length)];

		ctx.ui.setHeader((tui, theme) => {
			let animStart: number | null = performance.now();
			let timer: ReturnType<typeof setInterval> | null = null;

			timer = setInterval(() => {
				if (animStart !== null && performance.now() - animStart >= INTRO_MS) {
					animStart = null;
					if (timer) {
						clearInterval(timer);
						timer = null;
					}
					return;
				}
				try {
					tui.requestRender();
				} catch {
					if (timer) {
						clearInterval(timer);
						timer = null;
					}
				}
			}, INTRO_TICK_MS);

			return {
				render(termWidth: number): string[] {
					// Box sizing
					const maxWidth = 100;
					const boxWidth = Math.min(maxWidth, Math.max(0, termWidth - 2));
					if (boxWidth < 40) return []; // too narrow

					const MIN_RIGHT = 36;
					const MIN_LEFT = 16;
					const showDual = boxWidth >= MIN_LEFT + MIN_RIGHT + 3;

					const leftCol = showDual
						? Math.min(
								26,
								Math.max(MIN_LEFT, Math.floor((boxWidth - 3) * 0.32)),
							)
						: boxWidth - 2;
					const rightCol = showDual ? boxWidth - 3 - leftCol : 0;

					// Logo frame
					const logoFrame = computeLogoFrame(animStart);

					// ─── Left column ───
					const leftLines: string[] = [
						"",
						centerText(theme.bold("Welcome back!"), leftCol),
						"",
						...logoFrame.map((l) => centerText(l, leftCol)),
						"",
						centerText(theme.fg("muted", modelName), leftCol),
						centerText(theme.fg("dim", String(providerName)), leftCol),
					];

					// ─── Right column ───
					const sepWidth = Math.max(0, rightCol - 2);
					const sep = ` ${theme.fg("dim", "─".repeat(sepWidth))}`;

					const rightLines: string[] = showDual
						? [
								` ${theme.bold(theme.fg("accent", "Tips"))}`,
								` ${theme.fg("dim", "?")} ${theme.fg("muted", "keyboard shortcuts")}`,
								` ${theme.fg("dim", "/")} ${theme.fg("muted", "commands")}`,
								` ${theme.fg("dim", "!")} ${theme.fg("muted", "run bash")}`,
								` ${theme.fg("dim", "ctrl+o")} ${theme.fg("muted", "expand startup")}`,
								sep,
								` ${theme.bold(theme.fg("accent", "Session"))}`,
								...(gitBranch
									? [
											` ${theme.fg("dim", "branch")} ${theme.fg("muted", gitBranch)}`,
										]
									: [` ${theme.fg("dim", "not a git repo")}`]),
								` ${theme.fg("dim", "cwd")} ${theme.fg("muted", truncateToWidth(ctx.cwd, Math.max(1, rightCol - 6), "…"))}`,
								sep,
								` ${theme.bold(theme.fg("accent", "Version"))}`,
								` ${theme.fg("muted", `pi v${VERSION}`)}`,
								"",
							]
						: [];

					// ─── Box drawing ───
					const h = "─";
					const v = theme.fg("dim", "│");
					const tl = theme.fg("dim", "╭");
					const tr = theme.fg("dim", "╮");
					const bl = theme.fg("dim", "╰");
					const br = theme.fg("dim", "╯");

					const lines: string[] = [];

					// Top border with title
					const title = ` pi v${VERSION} `;
					const titlePrefix = "───";
					const titleStyled =
						theme.fg("dim", titlePrefix) + theme.fg("muted", title);
					const titleVisLen = visWidth(titlePrefix) + visWidth(title);
					const titleSpace = boxWidth - 2;
					const afterTitle = Math.max(0, titleSpace - titleVisLen);
					lines.push(
						tl + titleStyled + theme.fg("dim", h.repeat(afterTitle)) + tr,
					);

					// Content rows
					const maxRows = showDual
						? Math.max(leftLines.length, rightLines.length)
						: leftLines.length;
					for (let i = 0; i < maxRows; i++) {
						const left = fitToWidth(leftLines[i] ?? "", leftCol);
						if (showDual) {
							const right = fitToWidth(rightLines[i] ?? "", rightCol);
							lines.push(v + left + v + right + v);
						} else {
							lines.push(v + left + v);
						}
					}

					// Bottom border
					if (showDual) {
						lines.push(
							bl +
								theme.fg("dim", h.repeat(leftCol)) +
								theme.fg("dim", "┴") +
								theme.fg("dim", h.repeat(rightCol)) +
								br,
						);
					} else {
						lines.push(bl + theme.fg("dim", h.repeat(leftCol)) + br);
					}

					// Tip line
					if (tip) {
						const tipLabel =
							"\x1b[3m\x1b[38;2;180;140;255mTip: \x1b[2m\x1b[38;2;156;207;255m";
						const maxTipLen = boxWidth - 7;
						const tipText =
							tip.length > maxTipLen ? tip.slice(0, maxTipLen) + "…" : tip;
						lines.push(` ${tipLabel}${tipText}${RESET}`);
					}

					return lines;
				},
				invalidate() {
					if (timer) {
						clearInterval(timer);
						timer = null;
					}
					animStart = null;
				},
			};
		});
	});
}
