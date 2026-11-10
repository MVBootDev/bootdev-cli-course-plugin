# Boot.dev CLI Course Plugin

A reusable Agent Skill for Boot.dev courses where work is done in a local repository and the `bootdev` CLI checks or submits lessons.

## Portability

This package uses the Agent Plugins 1.0 layout: a root `plugin.json` and skills under `skills/<skill-name>/SKILL.md`. The skill follows the Agent Skills directory convention and carries its check-and-submit shell helper alongside the instructions.

The package format does not install or execute itself. Each harness controls discovery, installation, permissions, and how bundled scripts are run. The skill is tested with Codex. Other Agent Plugins or Agent Skills-compatible clients may use the same files, but their installation and script execution have not yet been tested.

| Client path | Status | How to use |
| --- | --- | --- |
| Codex plugin install | Tested | Add the package through a Codex marketplace and install it using Codex's plugin UI or CLI. |
| Agent Plugins 1.0 client | Format-compatible | Install the package using that client's documented plugin mechanism. The client must support skills and permit invoking the bundled shell script. |
| Agent Skills client without plugin support | Fallback | Copy `skills/bootdev-cli-lessons/` into the client's documented skills directory. Keep `SKILL.md` and `scripts/check-submit.sh` together. |
| Other harnesses | Not yet tested | Follow the harness's own skill/plugin discovery and script execution instructions; report any path, permission, or shell differences. |

The check helper requires a POSIX shell and `bootdev` on `PATH`. It checks a lesson first, then submits only if the check succeeds. For lessons with no CLI check, follow the skill's manual verification and browser completion workflow instead of invoking the helper.

## Scope

This skill is for Boot.dev CLI submission projects. It does not cover regular web-editor lessons or multiple-choice coursework. It uses the T3 integrated browser when running inside T3 Code; browser interaction instructions should be adapted to the host harness when used elsewhere.

## Install as a standalone Agent Skill

Copy the skill directory, preserving its internal structure, into the target harness's documented skills directory:

```text
skills/bootdev-cli-lessons/
├── SKILL.md
└── scripts/check-submit.sh
```

Then follow that harness's instructions for refreshing or starting a session so it discovers the skill. If the harness cannot execute skill-bundled scripts, run the equivalent `bootdev run <UUID>` and, only after success, `bootdev run -s <UUID>` commands directly.
