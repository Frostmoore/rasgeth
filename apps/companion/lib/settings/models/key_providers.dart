// G42.15: the API keys one can connect, the app's copy of @redgiant/protocol's KEY_PROVIDERS (in
// its order, with an example of the key and where to make one), checked with its vectors
// (tool/models_vectors.mjs → test/fixtures/models_vectors.json). Keep both together.
typedef KeyProviderInfo = ({String id, String name, String keyExample, String keyUrl});

const List<KeyProviderInfo> keyProviders = [
  (
    id: 'anthropic',
    name: 'Anthropic (Claude)',
    keyExample: 'sk-ant-api03-…',
    keyUrl: 'https://platform.claude.com/settings/keys',
  ),
  (
    id: 'openai',
    name: 'OpenAI (GPT)',
    keyExample: 'sk-proj-…',
    keyUrl: 'https://platform.openai.com/api-keys',
  ),
  (
    id: 'gemini',
    name: 'Google Gemini',
    keyExample: 'AIza…',
    keyUrl: 'https://aistudio.google.com/apikey',
  ),
  (id: 'mistral', name: 'Mistral', keyExample: '…', keyUrl: 'https://console.mistral.ai/api-keys'),
  (
    id: 'deepseek',
    name: 'DeepSeek',
    keyExample: 'sk-…',
    keyUrl: 'https://platform.deepseek.com/api_keys',
  ),
  (id: 'xai', name: 'xAI (Grok)', keyExample: 'xai-…', keyUrl: 'https://console.x.ai'),
  (id: 'groq', name: 'Groq', keyExample: 'gsk_…', keyUrl: 'https://console.groq.com/keys'),
  (
    id: 'openrouter',
    name: 'OpenRouter',
    keyExample: 'sk-or-v1-…',
    keyUrl: 'https://openrouter.ai/keys',
  ),
  (
    id: 'together',
    name: 'Together AI',
    keyExample: '…',
    keyUrl: 'https://api.together.ai/settings/api-keys',
  ),
  (
    id: 'fireworks',
    name: 'Fireworks AI',
    keyExample: 'fw_…',
    keyUrl: 'https://app.fireworks.ai/settings/users/api-keys',
  ),
  (id: 'cerebras', name: 'Cerebras', keyExample: 'csk-…', keyUrl: 'https://cloud.cerebras.ai'),
];

/// A provider id in words (the page's `providerName`, for the keys).
String keyProviderName(String id) => keyProviders.where((p) => p.id == id).firstOrNull?.name ?? id;
