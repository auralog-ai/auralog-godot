import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;

const requiredFiles = [
  "addons/auralog/plugin.cfg",
  "addons/auralog/auralog.gd",
  "addons/auralog/auralog_config.gd",
  "addons/auralog/auralog_logger.gd",
  "addons/auralog/auralog_transport.gd",
  "addons/auralog/auralog_serializer.gd",
  "addons/auralog/editor/auralog_plugin.gd",
  "README.md",
  "CHANGELOG.md",
  "LICENSE",
  "test/unit/test_serializer.gd",
  "test/unit/test_config.gd",
  "test/unit/test_client.gd",
  "test/unit/test_timestamp.gd",
];

const requiredPatterns = new Map([
	  ["addons/auralog/auralog.gd", [
	    /func init\(options: Dictionary\)/,
	    /func info\(message: String/,
	    /func error\(message: String/,
	    /OS\.add_logger\(_godot_logger\)/,
	    /OS\.remove_logger\(_godot_logger\)/,
	    /Program crashed with signal/,
	    /func _utc_timestamp\(\) -> String:/,
	    /Time\.get_datetime_string_from_system\(true\)/,
	    /get_unix_time_from_system\(\) \* 1000\.0/,
	  ]],
  ["addons/auralog/auralog_logger.gd", [
    /extends Logger/,
    /func _log_message\(message: String, error: bool\)/,
    /func _log_error\(/,
    /Mutex\.new\(\)/,
    /get_frame_file/,
  ]],
	  ["addons/auralog/auralog_transport.gd", [
	    /HTTPRequest\.new\(\)/,
	    /\/v1\/logs\/single/,
	    /\/v1\/logs/,
	    /projectApiKey/,
	    /_schedule_retry/,
	    /max_retry_attempts/,
	  ]],
  ["addons/auralog/auralog_serializer.gd", [
    /TYPE_VECTOR2/,
    /TYPE_COLOR/,
    /TYPE_OBJECT/,
    /Circular/,
    /MaxDepth/,
  ]],
	]);

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

for (const file of requiredFiles) {
  const path = join(root, file);
  assert(statSync(path).isFile(), `Missing required file: ${file}`);
}

for (const [file, patterns] of requiredPatterns) {
  const content = readFileSync(join(root, file), "utf8");
  for (const pattern of patterns) {
    assert(pattern.test(content), `Expected ${file} to match ${pattern}`);
  }
}

const gdFiles = collectFiles(join(root, "addons/auralog")).filter((file) => file.endsWith(".gd"));
for (const file of gdFiles) {
  const content = readFileSync(file, "utf8");
  assert(!content.includes("\r\n"), `${file} should use LF line endings`);
  assert(!/[ \t]+$/m.test(content), `${file} has trailing whitespace`);
  assert(!content.includes("print("), `${file} should not print from SDK internals`);
}

const allFiles = collectFiles(root).filter((file) => !file.includes(`${join(root, ".git")}/`));
for (const file of allFiles) {
  assert(!file.endsWith(".uid"), `${file} should not be checked in`);
}

const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const pluginCfg = readFileSync(join(root, "addons/auralog/plugin.cfg"), "utf8");
const client = readFileSync(join(root, "addons/auralog/auralog.gd"), "utf8");
const pluginVersion = pluginCfg.match(/^version="([^"]+)"/m)?.[1];
const sdkVersion = client.match(/^const SDK_VERSION := "([^"]+)"/m)?.[1];
assert(pluginVersion === packageJson.version, "plugin.cfg version must match package.json");
assert(sdkVersion === packageJson.version, "SDK_VERSION must match package.json");

console.log(`static checks passed (${gdFiles.length} GDScript files)`);

function collectFiles(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? collectFiles(path) : [path];
  });
}
