import { CustomEditor, type ExtensionAPI, type ExtensionContext, type WorkingIndicatorOptions } from "@earendil-works/pi-coding-agent";

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

class HardwareCursorEditor extends CustomEditor {
	render(width: number): string[] {
		return super.render(width).map((line) => line.replace(/\x1b\[7m([^\x1b]?)\x1b\[0m/g, "$1"));
	}
}

export default function (pi: ExtensionAPI) {
	const apply = (ctx: ExtensionContext) => {
		ctx.ui.setWorkingIndicator(bowShot(ctx));
	};

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new HardwareCursorEditor(tui, theme, keybindings));
		apply(ctx);
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
