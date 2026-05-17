import { basename } from 'node:path';
import { detectModel } from './model.js';
import { DEFAULT_CLIENT_ID, PROFILES } from './profiles.js';

export function loadConfig(argv, env) {
  const separatorIndex = argv.indexOf('--');
  const profileName = env.PRESENCE_PROFILE || (separatorIndex === -1 ? 'claude' : argv[0] || 'claude');
  const profile = PROFILES[profileName] || PROFILES.claude;

  const commandArgs = separatorIndex === -1 ? argv : argv.slice(separatorIndex + 1);
  const model = detectModel(commandArgs, env, profile);

  return {
    profileName,
    profile,
    commandArgs,
    model,
    showModel: env.PRESENCE_SHOW_MODEL !== '0',
    clientId: env.PRESENCE_CLIENT_ID || env.CLAUDE_DISCORD_CLIENT_ID || DEFAULT_CLIENT_ID,
    commandBin: env.PRESENCE_BIN || env[profile.binEnv] || profile.bin,
    appName: env.PRESENCE_APP_NAME || profile.name,
    activeState: env.PRESENCE_STATE || profile.state,
    projectName: basename(process.cwd()),
    idleAfterMs: Number(env.PRESENCE_IDLE_AFTER_MS || env.CLAUDE_DISCORD_IDLE_AFTER_MS || 120_000),
    largeImageKey: env.PRESENCE_LARGE_IMAGE || env.CLAUDE_DISCORD_LARGE_IMAGE || profile.largeImage,
    smallImageKey: env.PRESENCE_SMALL_IMAGE || env.CLAUDE_DISCORD_SMALL_IMAGE || profile.smallImage,
    idleImageKey: env.PRESENCE_IDLE_IMAGE || env.CLAUDE_DISCORD_IDLE_IMAGE || 'idle',
  };
}
