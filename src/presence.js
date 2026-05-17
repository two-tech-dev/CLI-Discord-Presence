import RPC from 'discord-rpc';

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export class PresenceController {
  #config;
  #rpc;
  #presenceReady = false;
  #lastActivityAt = Date.now();
  #currentStatus = 'Working';
  #activityInterval;
  #isShuttingDown = false;
  #startedAt = Date.now();

  constructor(config) {
    this.#config = config;
  }

  async start() {
    if (!this.#config.clientId) {
      console.warn('PRESENCE_CLIENT_ID is not set; starting CLI without Discord presence.');
      return;
    }

    RPC.register(this.#config.clientId);
    this.#rpc = new RPC.Client({ transport: 'ipc' });

    this.#rpc.on('ready', async () => {
      this.#presenceReady = true;
      await this.update('Working');

      this.#activityInterval = setInterval(() => {
        if (Date.now() - this.#lastActivityAt >= this.#config.idleAfterMs && this.#currentStatus !== 'Idling') {
          void this.update('Idling');
        }
      }, 15_000);
    });

    try {
      await this.#rpc.login({ clientId: this.#config.clientId });
    } catch (error) {
      console.warn(`Discord presence unavailable: ${error.message}`);
    }
  }

  markWorking() {
    this.#lastActivityAt = Date.now();

    if (this.#currentStatus === 'Idling') {
      void this.update('Working');
    }
  }

  async update(status = this.#currentStatus) {
    if (!this.#rpc || !this.#presenceReady) return;

    this.#currentStatus = status;
    await this.#rpc.setActivity(this.#buildActivity(status));
  }

  async stop() {
    if (this.#isShuttingDown) return;
    this.#isShuttingDown = true;

    if (this.#activityInterval) {
      clearInterval(this.#activityInterval);
    }

    if (!this.#rpc) return;

    try {
      if (this.#presenceReady) {
        await this.#rpc.clearActivity();
        await wait(1_000);
      }
      this.#rpc.destroy();
    } catch {
    }
  }

  #activeStateText() {
    return this.#config.showModel && this.#config.model ? `${this.#config.activeState} · ${this.#config.model}` : this.#config.activeState;
  }

  #buildActivity(status) {
    const isIdle = status === 'Idling';

    return {
      details: isIdle ? 'Idling' : `In ${this.#config.projectName}`,
      state: isIdle ? `Idle in ${this.#config.projectName}` : this.#activeStateText(),
      startTimestamp: this.#startedAt,
      largeImageKey: this.#config.largeImageKey,
      largeImageText: this.#config.appName,
      smallImageKey: isIdle ? this.#config.idleImageKey : this.#config.smallImageKey,
      smallImageText: isIdle ? 'Idling' : 'Terminal',
      instance: false,
    };
  }
}
