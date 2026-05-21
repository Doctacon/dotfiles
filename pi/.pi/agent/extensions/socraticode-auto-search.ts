import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { appendFileSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { complete, type UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const CLASSIFY_STATUS_KEY = "socraticode-auto-search-working";
const DECISION_STATUS_KEY = "socraticode-auto-search-decision";
const DECISION_NOTICE_MS = 4_000;
const LOG_PATH = path.join(process.env.HOME ?? process.cwd(), ".pi", "agent", "logs", "socraticode-auto-search.log");
const LAST_CONTEXT_PATH = path.join(
	process.env.HOME ?? process.cwd(),
	".pi",
	"agent",
	"logs",
	"socraticode-last-context.md",
);
const MCP_COMMAND = "npx";
const MCP_ARGS = ["-y", "socraticode"];
const MCP_TIMEOUT_MS = 25_000;
const SEARCH_LIMIT = 4;
const MAX_CONTEXT_CHARS = 9_000;
const CLASSIFIER_MODEL_ID = "gpt-5.4-mini";
const CLASSIFIER_PROVIDER_PREFERENCE = ["openai-codex", "openai", "azure-openai-responses"];

const CLASSIFIER_PROMPT = `You decide whether a coding agent should run semantic code search before answering the user's next message.

Return ONLY compact JSON with this shape:
{"useSearch":true|false,"query":"short semantic search query","reason":"brief reason"}

Use semantic search ONLY when the user needs source-code context from the current repository: explaining an existing file/symbol/model, finding where code lives, architecture/data-flow questions about the repo, impact/flow/caller analysis, debugging unfamiliar repo behavior, or modifying existing repo behavior when relevant files are not already known.

Do NOT use semantic search for simple chat, terminal/file operations, log inspection, questions about Pi/opencode/quadcode/MCP/SocratiCode setup, extension testing/reload behavior, or meta questions about the assistant. "How should I test?" is a skip unless the user names a repo file/symbol/feature or explicitly asks for repo test strategy.

If the prompt is ambiguous or mostly about the agent/tooling rather than the repository, choose false.`;

type ClassifierResult = {
	useSearch: boolean;
	query: string;
	reason?: string;
	source?: "model" | "heuristic";
};

type JsonRpcMessage = {
	jsonrpc?: string;
	id?: number;
	method?: string;
	result?: unknown;
	error?: { code?: number; message?: string; data?: unknown };
};

let enabled = true;
let projectsCache: { at: number; projects: string[] } | undefined;
let decisionNoticeTimer: ReturnType<typeof setTimeout> | undefined;
let decisionNoticeSeq = 0;

function truncate(text: string, maxChars: number): string {
	if (text.length <= maxChars) return text;
	return `${text.slice(0, maxChars).trimEnd()}\n\n[semantic search context truncated]`;
}

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

function logEvent(event: string, data: Record<string, unknown> = {}): void {
	try {
		mkdirSync(path.dirname(LOG_PATH), { recursive: true });
		appendFileSync(LOG_PATH, `${JSON.stringify({ ts: new Date().toISOString(), event, ...data })}\n`);
	} catch {
		// Logging should never break the prompt path.
	}
}

function writeLastContext(context: string): void {
	try {
		mkdirSync(path.dirname(LAST_CONTEXT_PATH), { recursive: true });
		writeFileSync(LAST_CONTEXT_PATH, context);
	} catch {
		// Debug artifact writing should never break the prompt path.
	}
}

function extractText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map((part) => {
			if (part && typeof part === "object" && "type" in part && part.type === "text" && "text" in part) {
				return typeof part.text === "string" ? part.text : "";
			}
			return "";
		})
		.filter(Boolean)
		.join("\n");
}

function extractToolText(response: JsonRpcMessage): string {
	if (response.error) throw new Error(response.error.message || "MCP tool call failed");
	const result = response.result as { content?: unknown } | undefined;
	return extractText(result?.content).trim();
}

class StdioMcpClient {
	private child: ChildProcessWithoutNullStreams;
	private buffer = "";
	private nextId = 1;
	private stderr = "";
	private pending = new Map<
		number,
		{
			resolve: (message: JsonRpcMessage) => void;
			reject: (error: Error) => void;
			timer: ReturnType<typeof setTimeout>;
		}
	>();

	constructor(cwd: string) {
		this.child = spawn(MCP_COMMAND, MCP_ARGS, {
			cwd,
			env: process.env,
			stdio: ["pipe", "pipe", "pipe"],
		});

		this.child.stdout.on("data", (chunk) => this.onStdout(String(chunk)));
		this.child.stderr.on("data", (chunk) => {
			this.stderr += String(chunk);
		});
		this.child.on("error", (error) => this.rejectAll(error));
		this.child.on("exit", (code, signal) => {
			if (this.pending.size > 0) {
				this.rejectAll(new Error(`SocratiCode MCP exited (${signal ?? code ?? "unknown"})`));
			}
		});
	}

	private onStdout(chunk: string): void {
		this.buffer += chunk;
		let newline = this.buffer.indexOf("\n");
		while (newline >= 0) {
			const line = this.buffer.slice(0, newline).trim();
			this.buffer = this.buffer.slice(newline + 1);
			newline = this.buffer.indexOf("\n");
			if (!line) continue;

			let message: JsonRpcMessage;
			try {
				message = JSON.parse(line) as JsonRpcMessage;
			} catch {
				continue;
			}

			if (typeof message.id !== "number") continue;
			const pending = this.pending.get(message.id);
			if (!pending) continue;
			this.pending.delete(message.id);
			clearTimeout(pending.timer);
			pending.resolve(message);
		}
	}

	private rejectAll(error: Error): void {
		for (const [id, pending] of this.pending) {
			this.pending.delete(id);
			clearTimeout(pending.timer);
			pending.reject(error);
		}
	}

	request(method: string, params: unknown = {}, timeoutMs = MCP_TIMEOUT_MS): Promise<JsonRpcMessage> {
		const id = this.nextId++;
		const payload = { jsonrpc: "2.0", id, method, params };
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => {
				this.pending.delete(id);
				reject(new Error(`SocratiCode MCP timed out calling ${method}${this.stderr ? `: ${this.stderr}` : ""}`));
			}, timeoutMs);
			this.pending.set(id, { resolve, reject, timer });
			this.child.stdin.write(`${JSON.stringify(payload)}\n`);
		});
	}

	notify(method: string, params: unknown = {}): void {
		this.child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", method, params })}\n`);
	}

	async initialize(): Promise<void> {
		const response = await this.request("initialize", {
			protocolVersion: "2024-11-05",
			capabilities: {},
			clientInfo: { name: "pi-socraticode-auto-search", version: "1.0.0" },
		});
		if (response.error) throw new Error(response.error.message || "Failed to initialize SocratiCode MCP");
		this.notify("notifications/initialized", {});
	}

	close(): void {
		this.rejectAll(new Error("SocratiCode MCP closed"));
		this.child.kill();
	}
}

async function callSocraticodeTool(cwd: string, name: string, args: Record<string, unknown>): Promise<string> {
	const startedAt = Date.now();
	logEvent("mcp_call_start", { cwd, tool: name, args });
	const client = new StdioMcpClient(cwd);
	try {
		await client.initialize();
		const response = await client.request("tools/call", { name, arguments: args });
		const text = extractToolText(response);
		logEvent("mcp_call_success", {
			cwd,
			tool: name,
			durationMs: Date.now() - startedAt,
			resultChars: text.length,
			resultPreview: text.slice(0, 1_500),
		});
		return text;
	} catch (error) {
		logEvent("mcp_call_error", {
			cwd,
			tool: name,
			durationMs: Date.now() - startedAt,
			error: errorMessage(error),
		});
		throw error;
	} finally {
		client.close();
	}
}

function parseIndexedProjects(text: string): string[] {
	return [...text.matchAll(/^\s*-\s+(.+)$/gm)].map((match) => match[1]!.trim()).filter((p) => p.startsWith("/"));
}

async function listIndexedProjects(cwd: string): Promise<string[]> {
	if (projectsCache && Date.now() - projectsCache.at < 5 * 60_000) return projectsCache.projects;
	const text = await callSocraticodeTool(cwd, "codebase_list_projects", {});
	const projects = parseIndexedProjects(text);
	projectsCache = { at: Date.now(), projects };
	return projects;
}

function chooseProject(cwd: string, projects: string[]): string | undefined {
	const normalizedCwd = path.resolve(cwd);
	const normalizedProjects = projects.map((project) => path.resolve(project));
	const exact = normalizedProjects.find((project) => project === normalizedCwd);
	if (exact) return exact;

	const parents = normalizedProjects
		.filter((project) => normalizedCwd.startsWith(`${project}${path.sep}`))
		.sort((a, b) => b.length - a.length);
	if (parents[0]) return parents[0];

	const children = normalizedProjects
		.filter((project) => project.startsWith(`${normalizedCwd}${path.sep}`))
		.sort((a, b) => a.length - b.length);
	return children[0];
}

function hasRepoCodeSignal(prompt: string): boolean {
	const lower = prompt.toLowerCase();
	return (
		/@[\w./-]+/.test(prompt) ||
		/\b[\w./-]+\.(sql|py|ts|tsx|js|jsx|go|rs|java|scala|yaml|yml|json|md)\b/i.test(prompt) ||
		/\b(codebase|repo|repository|architecture|data flow|execution flow|callers|called by|impact|symbol|function|class|model|sql model|table|view|implementation)\b/.test(lower) ||
		/\b(where is|where are|find where|find the code|how does|what does|trace)\b/.test(lower)
	);
}

function shouldForceSkip(prompt: string): ClassifierResult | undefined {
	const lower = prompt.toLowerCase();
	if (/\b(no|don't|do not|without)\s+(semantic\s+)?search\b/.test(lower)) {
		return { useSearch: false, query: "", reason: "user opted out", source: "heuristic" };
	}

	const toolingMeta = /\b(pi|opencode|open code|quadcode|quad code|mcp|socraticode|extension|plugin|reload|restart|log|logs|classifier|sub-llm|agent|assistant|abilities)\b/.test(lower);
	const testingMeta = /\b(testing your abilities|test the extension|how should i test\??|how do i test\??|reloaded|reloaded\.)\b/.test(lower);
	if ((toolingMeta || testingMeta) && !hasRepoCodeSignal(prompt)) {
		return {
			useSearch: false,
			query: "",
			reason: "tooling/meta prompt without repo code signal",
			source: "heuristic",
		};
	}

	return undefined;
}

function heuristicDecision(prompt: string): ClassifierResult {
	const forcedSkip = shouldForceSkip(prompt);
	if (forcedSkip) return forcedSkip;

	const lower = prompt.toLowerCase();
	if (/\b(use|run)\s+(semantic|socraticode|codebase)\s+search\b/.test(lower)) {
		return { useSearch: true, query: prompt, reason: "user explicitly requested search", source: "heuristic" };
	}

	return {
		useSearch: hasRepoCodeSignal(prompt),
		query: prompt,
		reason: "heuristic fallback",
		source: "heuristic",
	};
}

function formatDecisionNotice(decision: ClassifierResult): string {
	const verdict = decision.useSearch ? "search" : "skip";
	const reason = decision.reason ? ` — ${decision.reason}` : "";
	return `SocratiCode: ${verdict}${reason}`;
}

function flashDecisionNotice(ctx: ExtensionContext, decision: ClassifierResult): void {
	if (!ctx.hasUI) return;
	const seq = ++decisionNoticeSeq;
	if (decisionNoticeTimer) clearTimeout(decisionNoticeTimer);
	ctx.ui.setStatus(DECISION_STATUS_KEY, formatDecisionNotice(decision));
	decisionNoticeTimer = setTimeout(() => {
		if (seq === decisionNoticeSeq) ctx.ui.setStatus(DECISION_STATUS_KEY, undefined);
	}, DECISION_NOTICE_MS);
}

function getClassifierModelCandidates(ctx: ExtensionContext) {
	const providers = [ctx.model?.provider, ...CLASSIFIER_PROVIDER_PREFERENCE].filter(
		(provider): provider is string => typeof provider === "string" && provider.length > 0,
	);
	const uniqueProviders = [...new Set(providers)];
	return uniqueProviders
		.map((provider) => ctx.modelRegistry.find(provider, CLASSIFIER_MODEL_ID))
		.filter((model): model is NonNullable<typeof model> => Boolean(model));
}

function parseClassifierJson(text: string): ClassifierResult | undefined {
	const jsonText = text.match(/```(?:json)?\s*([\s\S]*?)```/)?.[1] ?? text.match(/\{[\s\S]*\}/)?.[0] ?? text;
	try {
		const parsed = JSON.parse(jsonText) as Partial<ClassifierResult>;
		return {
			useSearch: Boolean(parsed.useSearch),
			query: typeof parsed.query === "string" && parsed.query.trim() ? parsed.query.trim() : "",
			reason: typeof parsed.reason === "string" ? parsed.reason : undefined,
			source: "model",
		};
	} catch {
		return undefined;
	}
}

async function decideWithModel(ctx: ExtensionContext, prompt: string): Promise<ClassifierResult> {
	const forcedSkip = shouldForceSkip(prompt);
	if (forcedSkip) {
		logEvent("classifier_forced_skip", {
			cwd: ctx.cwd,
			classifierModelId: CLASSIFIER_MODEL_ID,
			promptPreview: prompt.slice(0, 500),
			decision: forcedSkip,
		});
		return forcedSkip;
	}

	const classifierModels = getClassifierModelCandidates(ctx);
	if (classifierModels.length === 0) {
		const decision = heuristicDecision(prompt);
		logEvent("classifier_fallback", {
			reason: "classifier_model_not_found",
			classifierModelId: CLASSIFIER_MODEL_ID,
			cwd: ctx.cwd,
			promptPreview: prompt.slice(0, 500),
			decision,
		});
		return decision;
	}

	try {
		let classifierModel = classifierModels[0]!;
		let auth = await ctx.modelRegistry.getApiKeyAndHeaders(classifierModel);
		for (const candidate of classifierModels.slice(1)) {
			if (auth.ok && auth.apiKey) break;
			classifierModel = candidate;
			auth = await ctx.modelRegistry.getApiKeyAndHeaders(classifierModel);
		}
		if (!auth.ok || !auth.apiKey) {
			const decision = heuristicDecision(prompt);
			logEvent("classifier_fallback", {
				reason: auth.ok ? "missing_api_key" : "auth_error",
				authError: auth.ok ? undefined : auth.error,
				cwd: ctx.cwd,
				classifierModelId: CLASSIFIER_MODEL_ID,
				candidateModels: classifierModels.map((model) => `${model.provider}/${model.id}`),
				model: `${classifierModel.provider}/${classifierModel.id}`,
				promptPreview: prompt.slice(0, 500),
				decision,
			});
			return decision;
		}

		const userMessage: UserMessage = {
			role: "user",
			content: [
				{
					type: "text",
					text: `CWD: ${ctx.cwd}\n\nUser message:\n${prompt.slice(0, 8_000)}`,
				},
			],
			timestamp: Date.now(),
		};

		const response = await complete(
			classifierModel,
			{ systemPrompt: CLASSIFIER_PROMPT, messages: [userMessage] },
			{ apiKey: auth.apiKey, headers: auth.headers, signal: ctx.signal },
		);
		const text = extractText(response.content);
		const parsed = parseClassifierJson(text);
		if (!parsed) {
			const decision = heuristicDecision(prompt);
			logEvent("classifier_fallback", {
				reason: "unparseable_model_response",
				cwd: ctx.cwd,
				classifierModelId: CLASSIFIER_MODEL_ID,
				model: `${classifierModel.provider}/${classifierModel.id}`,
				promptPreview: prompt.slice(0, 500),
				rawResponse: text.slice(0, 1_000),
				decision,
			});
			return decision;
		}
		if (parsed.useSearch && !hasRepoCodeSignal(prompt)) {
			const decision: ClassifierResult = {
				useSearch: false,
				query: "",
				reason: "model requested search but prompt has no repo code signal",
				source: "heuristic",
			};
			logEvent("classifier_override", {
				reason: "no_repo_code_signal",
				cwd: ctx.cwd,
				classifierModelId: CLASSIFIER_MODEL_ID,
				model: `${classifierModel.provider}/${classifierModel.id}`,
				promptPreview: prompt.slice(0, 500),
				rawResponse: text.slice(0, 1_000),
				modelDecision: parsed,
				decision,
			});
			return decision;
		}
		if (parsed.useSearch && !parsed.query) parsed.query = prompt;
		logEvent("classifier_decision", {
			cwd: ctx.cwd,
			classifierModelId: CLASSIFIER_MODEL_ID,
			model: `${classifierModel.provider}/${classifierModel.id}`,
			promptPreview: prompt.slice(0, 500),
			rawResponse: text.slice(0, 1_000),
			decision: parsed,
		});
		return parsed;
	} catch (error) {
		const decision = heuristicDecision(prompt);
		logEvent("classifier_fallback", {
			reason: "classifier_error",
			error: errorMessage(error),
			cwd: ctx.cwd,
			classifierModelId: CLASSIFIER_MODEL_ID,
			candidateModels: classifierModels.map((model) => `${model.provider}/${model.id}`),
			promptPreview: prompt.slice(0, 500),
			decision,
		});
		return decision;
	}
}

async function buildSemanticContext(ctx: ExtensionContext, prompt: string): Promise<string | undefined> {
	const decision = await decideWithModel(ctx, prompt);
	flashDecisionNotice(ctx, decision);
	if (!decision.useSearch) {
		logEvent("search_skipped", {
			cwd: ctx.cwd,
			reason: decision.reason,
			decision,
		});
		return undefined;
	}

	const projects = await listIndexedProjects(ctx.cwd);
	const projectPath = chooseProject(ctx.cwd, projects);
	if (!projectPath) {
		logEvent("search_no_indexed_project", {
			cwd: ctx.cwd,
			indexedProjects: projects,
			decision,
		});
		return undefined;
	}

	const query = decision.query || prompt;
	logEvent("search_start", {
		cwd: ctx.cwd,
		projectPath,
		query,
		decision,
	});
	const results = await callSocraticodeTool(ctx.cwd, "codebase_search", {
		projectPath,
		query,
		limit: SEARCH_LIMIT,
		includeLinked: true,
	});

	if (!results || /no (results|matches)/i.test(results)) {
		logEvent("search_no_results", {
			cwd: ctx.cwd,
			projectPath,
			query,
			resultChars: results.length,
			resultPreview: results.slice(0, 1_500),
		});
		return undefined;
	}

	const fullContext = [
		"<semantic_code_search_context>",
		"A pre-agent semantic-search gate decided the current request benefits from SocratiCode codebase search.",
		`Reason: ${decision.reason ?? "not provided"}`,
		`Project: ${projectPath}`,
		`Search query: ${query}`,
		"",
		"Results:",
		results,
		"",
		"Use these results only when relevant. Treat them as navigation/context, not as a substitute for reading files before editing.",
		"</semantic_code_search_context>",
	].join("\n");
	const semanticContext = truncate(fullContext, MAX_CONTEXT_CHARS);
	writeLastContext(semanticContext);
	logEvent("context_injected", {
		cwd: ctx.cwd,
		projectPath,
		query,
		resultChars: results.length,
		contextChars: semanticContext.length,
		truncated: semanticContext.length < fullContext.length,
		contextPath: LAST_CONTEXT_PATH,
		contextPreview: semanticContext.slice(0, 1_500),
	});
	return semanticContext;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("socraticode-auto-search", {
		description: "Toggle automatic SocratiCode semantic search injection",
		handler: async (args, ctx) => {
			const value = args.trim().toLowerCase();
			if (["on", "true", "1", "enable", "enabled"].includes(value)) enabled = true;
			else if (["off", "false", "0", "disable", "disabled"].includes(value)) enabled = false;
			else if (value) {
				ctx.ui.notify("Usage: /socraticode-auto-search [on|off]", "error");
				return;
			} else enabled = !enabled;

			ctx.ui.notify(`SocratiCode auto-search ${enabled ? "enabled" : "disabled"}`, enabled ? "success" : "info");
		},
	});

	pi.registerCommand("socraticode-auto-search-log", {
		description: "Show the SocratiCode auto-search log file path",
		handler: async (_args, ctx) => {
			ctx.ui.notify(LOG_PATH, "info");
		},
	});

	pi.registerCommand("socraticode-auto-search-context", {
		description: "Show the last injected SocratiCode context file path",
		handler: async (_args, ctx) => {
			ctx.ui.notify(LAST_CONTEXT_PATH, "info");
		},
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (!enabled) {
			logEvent("turn_disabled", { cwd: ctx.cwd, promptPreview: event.prompt.slice(0, 500) });
			return;
		}
		if (!event.prompt.trim()) return;

		logEvent("turn_start", {
			cwd: ctx.cwd,
			sessionId: ctx.sessionManager.getSessionId(),
			promptPreview: event.prompt.slice(0, 500),
		});
		try {
			if (ctx.hasUI) ctx.ui.setStatus(CLASSIFY_STATUS_KEY, "SocratiCode…");
			const semanticContext = await buildSemanticContext(ctx, event.prompt);
			if (!semanticContext) return;
			return { systemPrompt: `${event.systemPrompt}\n\n${semanticContext}` };
		} catch (error) {
			logEvent("turn_error", {
				cwd: ctx.cwd,
				sessionId: ctx.sessionManager.getSessionId(),
				error: errorMessage(error),
			});
			return;
		} finally {
			if (ctx.hasUI) ctx.ui.setStatus(CLASSIFY_STATUS_KEY, undefined);
		}
	});
}
