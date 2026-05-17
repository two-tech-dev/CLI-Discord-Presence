#!/usr/bin/env node
import { loadConfig } from './config.js';
import { PresenceController } from './presence.js';
import { runCommand } from './runner.js';

async function main() {
  const config = loadConfig(process.argv.slice(2), process.env);
  const presence = new PresenceController(config);

  await presence.start();
  runCommand(config, presence);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
