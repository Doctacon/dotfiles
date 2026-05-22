import { CustomEditor, type ExtensionAPI, type ExtensionContext, type WorkingIndicatorOptions } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";

function rgb(hex: string, text: string): string {
	const clean = hex.replace("#", "");
	const r = Number.parseInt(clean.slice(0, 2), 16);
	const g = Number.parseInt(clean.slice(2, 4), 16);
	const b = Number.parseInt(clean.slice(4, 6), 16);
	return `\x1b[38;2;${r};${g};${b}m${text}\x1b[39m`;
}

function bowShot(_ctx: ExtensionContext): WorkingIndicatorOptions {
	const colorFrame = (frame: string) => rgb("#f97316", frame.padEnd(12, " "));

	// Fixed-width frames keep Pi's trailing "working..." text from jittering.
	// The motion is intentionally slower: draw, hold tension, release, arrow flies.
	return {
		frames: [
			colorFrame("(|--->"),
			colorFrame("(\\--->"),
			colorFrame("(-\\-->"),
			colorFrame("(--\\->"),
			colorFrame("(---\\>"),
			colorFrame("(---\\>"),
			colorFrame("(--~->"),
			colorFrame("(-~~->"),
			colorFrame("( ~~~>"),
			colorFrame("(   -->"),
			colorFrame("(     >"),
			colorFrame("(|"),
		],
		intervalMs: 180,
	};
}

const promptHistory: string[] = [];
let historyIndex: number | undefined;

const TOOL_STATUS_KEY = "aesthetic-tool-theme";
const activeTools = new Map<string, string>();

type ToolCategory = "read" | "search" | "edit" | "bash" | "mcp" | "ask" | "other";

function toolCategory(toolName: string): ToolCategory {
	if (["read", "ls", "find", "grep"].includes(toolName)) return "read";
	if (["web_search", "code_search", "fetch_content", "get_search_content"].includes(toolName)) return "search";
	if (["edit", "write"].includes(toolName)) return "edit";
	if (toolName === "bash") return "bash";
	if (toolName === "mcp" || toolName.includes("mcp") || toolName.includes("socraticode")) return "mcp";
	if (toolName === "ask_user_question") return "ask";
	return "other";
}

function toolSwatch(toolName: string): string {
	const category = toolCategory(toolName);
	const styles: Record<ToolCategory, { icon: string; color: string; label: string }> = {
		read: { icon: "◌", color: "#0f766e", label: "read" },
		search: { icon: "⌕", color: "#0ea5a4", label: "search" },
		edit: { icon: "✎", color: "#f97316", label: "edit" },
		bash: { icon: "❯", color: "#d97706", label: "bash" },
		mcp: { icon: "◇", color: "#0891b2", label: "mcp" },
		ask: { icon: "?", color: "#7c3aed", label: "ask" },
		other: { icon: "•", color: "#8f8aa3", label: "tool" },
	};
	const style = styles[category];
	return rgb(style.color, `${style.icon} ${style.label}:${toolName}`);
}

function renderToolStatus(): string | undefined {
	const tools = [...activeTools.values()];
	if (tools.length === 0) return undefined;
	const visible = tools.slice(0, 3).map(toolSwatch).join(rgb("#d8d6e4", " | "));
	const extra = tools.length > 3 ? rgb("#8f8aa3", ` +${tools.length - 3}`) : "";
	return `${visible}${extra}`;
}

class HardwareCursorEditor extends CustomEditor {
	handleInput(data: string): void {
		if (matchesKey(data, "up") && (this.getText().length === 0 || historyIndex !== undefined)) {
			if (promptHistory.length === 0) return;
			historyIndex = historyIndex === undefined ? promptHistory.length - 1 : Math.max(0, historyIndex - 1);
			this.setText(promptHistory[historyIndex] ?? "");
			return;
		}

		if (matchesKey(data, "down") && historyIndex !== undefined) {
			historyIndex += 1;
			if (historyIndex >= promptHistory.length) {
				historyIndex = undefined;
				this.setText("");
			} else {
				this.setText(promptHistory[historyIndex] ?? "");
			}
			return;
		}

		historyIndex = undefined;
		super.handleInput(data);
	}

	render(width: number): string[] {
		return super.render(width).map((line) => line.replace(/\x1b\[7m([^\x1b]?)\x1b\[0m/g, "$1"));
	}
}

export default function (pi: ExtensionAPI) {
	const apply = (ctx: ExtensionContext) => {
		ctx.ui.setWorkingIndicator(bowShot(ctx));
	};

	pi.on("session_start", async (_event, ctx) => {
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type !== "message" || entry.message.role !== "user") continue;
			const text = entry.message.content
				.map((part) => (part.type === "text" ? part.text : ""))
				.join("\n")
				.trim();
			if (text && promptHistory[promptHistory.length - 1] !== text) promptHistory.push(text);
		}

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new HardwareCursorEditor(tui, theme, keybindings));
		apply(ctx);
	});

	pi.on("input", async (event) => {
		const text = event.text.trim();
		if (!text) return;
		if (promptHistory[promptHistory.length - 1] !== text) promptHistory.push(text);
		historyIndex = undefined;
	});

	pi.on("tool_execution_start", async (event, ctx) => {
		activeTools.set(event.toolCallId, event.toolName);
		ctx.ui.setStatus(TOOL_STATUS_KEY, renderToolStatus());
	});

	pi.on("tool_execution_end", async (event, ctx) => {
		activeTools.delete(event.toolCallId);
		ctx.ui.setStatus(TOOL_STATUS_KEY, renderToolStatus());
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		activeTools.clear();
		ctx.ui.setStatus(TOOL_STATUS_KEY, undefined);
	});

	pi.registerCommand("aesthetic-indicator", {
		description: "Toggle the custom bow-and-arrow working indicator: on or reset.",
		handler: async (args, ctx) => {
			const mode = args.trim().toLowerCase();
			if (mode === "reset" || mode === "off") {
				ctx.ui.setWorkingIndicator();
				ctx.ui.notify("Working indicator reset to pi default.", "info");
				return;
			}

			apply(ctx);
			ctx.ui.notify("Working indicator set to bow-and-arrow animation.", "info");
		},
	});
}
