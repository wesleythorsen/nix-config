// Minimal Pi Durable agent: SQLite-backed root conversation that survives
// restarts. Talks to local Ollama by default; set PI_MODEL to override.
// Run: npm start -- "your prompt"
import { BACKGROUND_CONTEXT } from "@earendil-works/chord/context";
import { createModels, createProvider, type Model } from "@earendil-works/pi-ai";
import { openAICompletionsApi } from "@earendil-works/pi-ai/api/openai-completions.lazy";
import { AssistantEntry, createRegistry, Harness } from "@earendil-works/pi-durable";
import { openNodeSqliteStorage } from "@earendil-works/pi-durable/storage/sqlite/node";

const modelId = process.env.PI_MODEL ?? "deepseek-r1:14b";
const baseUrl = process.env.OLLAMA_BASE_URL ?? "http://127.0.0.1:11434/v1";

const ollamaModel: Model<"openai-completions"> = {
  id: modelId,
  name: modelId,
  api: "openai-completions",
  provider: "ollama",
  baseUrl,
  reasoning: false,
  input: ["text"],
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  contextWindow: 32768,
  maxTokens: 8192,
  compat: { supportsDeveloperRole: false, supportsReasoningEffort: false },
};

const ollama = createProvider({
  id: "ollama",
  baseUrl,
  auth: { apiKey: { name: "Ollama", resolve: async () => ({ auth: {} }) } },
  models: [ollamaModel],
  api: openAICompletionsApi(),
});

const context = BACKGROUND_CONTEXT;
const models = createModels();
models.setProvider(ollama);

const storage = await openNodeSqliteStorage("./agent.sqlite");
const harness = await Harness.open(storage, { models, registry: createRegistry() }, context);
const root = await harness.root(context, { agent: { model: { provider: "ollama", modelId } } });

// Finish anything the previous process left running.
harness.resume();

const prompt = process.argv.slice(2).join(" ") || "Say hello in one sentence.";
const submission = await root.submit(
  { type: "input", content: prompt, requestId: `cli-${Date.now()}` },
  context,
);
const settled = await submission.wait(context);

if (settled.status === "done" && settled.type === "input") {
  const answer = await root.commit((tx) => tx.entry(AssistantEntry, settled.answer), context);
  console.log(answer?.model?.[0]);
} else {
  console.log("Unanswered:", settled);
}

await harness.close(context);
