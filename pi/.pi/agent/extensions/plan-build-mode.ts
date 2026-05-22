import { mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext, WorkingIndicatorOptions } from "@earendil-works/pi-coding-agent";

type AgentMode = "plan" | "build";

const STATUS_KEY = "plan-build-mode";
const AGENT_RING_STATE_PATH = path.join(process.env.HOME ?? process.cwd(), ".cache", "tmux-agent-ring-state");
let mode: AgentMode = "build";

function setAgentRingState(state: "working" | "waiting" | "blocked" | "error", ttlSeconds?: number): void {
	if (!process.env.TMUX) return;
	try {
		mkdirSync(path.dirname(AGENT_RING_STATE_PATH), { recursive: true });
		const expires = ttlSeconds ? Math.floor(Date.now() / 1000) + ttlSeconds : "";
		writeFileSync(AGENT_RING_STATE_PATH, `${state} ${expires}\n`);
	} catch {
		// Aesthetic-only tmux integration; never block Pi behavior.
	}
}

function modeLabel(): string {
	return mode === "plan" ? "PLAN mode" : "BUILD mode";
}

function color(hex: string, text: string): string {
	const clean = hex.replace("#", "");
	const r = Number.parseInt(clean.slice(0, 2), 16);
	const g = Number.parseInt(clean.slice(2, 4), 16);
	const b = Number.parseInt(clean.slice(4, 6), 16);
	return `\x1b[38;2;${r};${g};${b}m${text}\x1b[39m`;
}

function modeStatus(): string {
	return mode === "plan" ? color("#0f766e", "✎ PLAN") : color("#f97316", "⚒ BUILD");
}

function buildIndicator(): WorkingIndicatorOptions {
	const frame = (text: string) => color("#f97316", text.padEnd(18, " "));
	return {
		// Inline riff on the multi-line ASCII bow:
		//   (  \  )
		// ##------->
		//   )  /  (
		// The working indicator is a single-line slot, so the frames draw and release the bow in place.
		frames: [
			frame("(              "),
			frame("( \\            "),
			frame("( \\ )          "),
			frame("##---\\)       "),
			frame("##------)     "),
			frame("##--------->  "),
			frame("   )--------> "),
			frame("   /------->  "),
			frame("( /----->     "),
			frame("(             "),
		],
		intervalMs: 150,
	};
}

function planIndicator(): WorkingIndicatorOptions {
	const frames = ["✎      ", "✎ ·    ", "✎ · ·  ", "✎ · · ·", "✎ · ·  ", "✎ ·    "];
	return {
		frames: frames.map((frame) => color("#0f766e", frame.padEnd(12, " "))),
		intervalMs: 420,
	};
}

function applyModeUi(ctx: ExtensionContext): void {
	ctx.ui.setStatus(STATUS_KEY, modeStatus());
	ctx.ui.setWorkingIndicator(mode === "plan" ? planIndicator() : buildIndicator());
}

function setMode(nextMode: AgentMode, ctx: ExtensionContext, notify = true): void {
	mode = nextMode;
	applyModeUi(ctx);
	if (notify) {
		ctx.ui.notify(`${modeLabel()} enabled`, mode === "plan" ? "info" : "success");
	}
}

function isProbablyReadOnlyShell(command: string): boolean {
	const normalized = command.trim();
	if (!normalized) return true;

	// Obvious mutation / side-effect operators and commands. Keep this broad: plan mode should be safe.
	if (/[;&|]\s*(rm|mv|cp|mkdir|rmdir|touch|chmod|chown|sudo|tee|cat\s*>|python|node|npm|pnpm|yarn|bun|uv|pip|cargo|go|make|docker|kubectl)\b/i.test(normalized)) {
		return false;
	}
	if (/(^|\s)(>|>>|2>|&>)\s*\S+/.test(normalized)) return false;
	if (/\b(rm|mv|cp|mkdir|rmdir|touch|chmod|chown|sudo|tee|install|apply_patch)\b/i.test(normalized)) return false;
	if (/\b(npm|pnpm|yarn|bun|uv|pip|cargo|go|make|docker|kubectl)\s+(install|add|remove|update|upgrade|run|test|build|dev|start|migrate|apply)\b/i.test(normalized)) return false;
	if (/\bgit\s+(add|commit|push|pull|merge|rebase|checkout|switch|restore|reset|clean|stash|apply|am|cherry-pick)\b/i.test(normalized)) return false;

	// Common inspection commands are fine.
	return /^(pwd|ls|find|rg|grep|git\s+(status|diff|log|show|branch|rev-parse|ls-files)|wc|head|tail|sed\s+-n|awk|jq|python3?\s+-m\s+json\.tool)\b/i.test(normalized);
}

function planSystemPrompt(): string {
	return [
		"You are in PLAN MODE.",
		"Do not modify files, write code, apply patches, install packages, run migrations, or execute mutating shell commands.",
		"You may inspect/read files and gather context.",
		"Focus on understanding the request, asking clarifying questions when needed, and proposing a concrete implementation plan.",
		"If the user asks you to implement while still in PLAN MODE, explain that they should switch to BUILD MODE with /build first.",
	].join(" ");
}

function buildSystemPrompt(): string {
	return [
		"You are in BUILD MODE.",
		"You may implement requested changes using the available tools.",
		"Still be careful: inspect before editing, keep changes targeted, and summarize what changed.",
	].join(" ");
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		setMode(mode, ctx, false);
	});

	pi.registerCommand("plan", {
		description: "Switch to PLAN mode: inspect and propose, but do not modify files.",
		handler: async (_args, ctx) => setMode("plan", ctx),
	});

	pi.registerCommand("build", {
		description: "Switch to BUILD mode: allow implementation/editing tools.",
		handler: async (_args, ctx) => setMode("build", ctx),
	});

	pi.registerCommand("mode", {
		description: "Show or set the current mode: /mode, /mode plan, or /mode build.",
		handler: async (args, ctx) => {
			const value = args.trim().toLowerCase();
			if (!value) {
				ctx.ui.notify(`Current mode: ${modeLabel()}`, "info");
				return;
			}
			if (value === "plan") return setMode("plan", ctx);
			if (value === "build") return setMode("build", ctx);
			ctx.ui.notify("Usage: /mode [plan|build]", "error");
		},
	});

	pi.registerShortcut("tab", {
		description: "Toggle PLAN/BUILD mode",
		handler: async (ctx) => setMode(mode === "plan" ? "build" : "plan", ctx),
	});

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt: `${event.systemPrompt}\n\n${mode === "plan" ? planSystemPrompt() : buildSystemPrompt()}`,
		};
	});

	pi.on("tool_call", async (event, ctx) => {
		if (mode !== "plan") return;

		if (event.toolName === "write" || event.toolName === "edit") {
			const reason = `✎ PLAN protected this workspace: ${event.toolName} is blocked. Press Tab or run /build to switch to ⚒ BUILD.`;
			setAgentRingState("blocked", 12);
			if (ctx.hasUI) ctx.ui.notify(reason, "warning");
			return {
				block: true,
				reason,
			};
		}

		if (event.toolName === "bash") {
			const input = event.input as { command?: unknown };
			const command = typeof input.command === "string" ? input.command : "";
			if (!isProbablyReadOnlyShell(command)) {
				const reason = "✎ PLAN protected this workspace: mutating shell commands are blocked. Press Tab or run /build to switch to ⚒ BUILD.";
				setAgentRingState("blocked", 12);
				if (ctx.hasUI) ctx.ui.notify(reason, "warning");
				return {
					block: true,
					reason,
				};
			}
		}
	});
}
