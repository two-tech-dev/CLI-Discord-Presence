export function detectModel(args, env, profile) {
  return env.PRESENCE_MODEL || getArgValue(args, '--model') || getArgValue(args, '-m') || getEnvValue(env, profile.modelEnvs || [profile.modelEnv]) || '';
}

function getArgValue(args, flag) {
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === flag) {
      return args[index + 1] || '';
    }

    if (arg.startsWith(`${flag}=`)) {
      return arg.slice(flag.length + 1);
    }
  }

  return '';
}

function getEnvValue(env, names) {
  for (const name of names) {
    if (name && env[name]) {
      return env[name];
    }
  }

  return '';
}
