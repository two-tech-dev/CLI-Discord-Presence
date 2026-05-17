import { spawn } from 'node:child_process';

export function runCommand(config, presence) {
  const child = spawn(config.commandBin, config.commandArgs, {
    stdio: 'inherit',
    env: {
      ...process.env,
      CLI_PRESENCE_WRAPPED: '1',
    },
  });

  const exitWrapper = async (code = 0) => {
    await presence.stop();
    process.exit(code);
  };

  child.on('error', async (error) => {
    console.error(`Failed to start ${config.profileName} CLI at ${config.commandBin}: ${error.message}`);
    await exitWrapper(1);
  });

  child.on('exit', async (code, signal) => {
    if (signal) {
      await exitWrapper(128);
      return;
    }

    await exitWrapper(code ?? 0);
  });

  for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
    process.on(signal, () => {
      child.kill(signal);
      void exitWrapper(128);
    });
  }

  process.on('beforeExit', () => {
    void presence.stop();
  });
}
