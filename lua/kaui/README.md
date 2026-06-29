# KAUI / KissAssist Lua

Lua bootstrap for KAUI and the future KissAssist Lua engine.

## MacroQuest launch

Copy `lua/kaui/` into the MacroQuest `lua` folder, then run:

```mq
/lua run kaui/main.lua
```

Expected MQ output:

```text
[KAUI][INFO] Starting KAUI / KissAssist Lua v0.5.0
[KAUI][INFO] KissAssist INI loaded/created (...)
[KAUI][INFO] Module loaded: core_heartbeat
[KAUI][INFO] Module loaded: ui_imgui
[KAUI][INFO] ImGui UI initialized: /kaui show | /kaui hide
[KAUI][INFO] Command available: /kaui help
[KAUI][INFO] Bootstrap complete.
[KAUI][INFO] Main loop active: pulse 250 ms.
```

## Runtime commands

```mq
/kaui help
/kaui status
/kaui show
/kaui hide
/kaui ui toggle
/kaui pause
/kaui resume
/kaui pulse 500
/kaui mode manual
/kaui role unknown
/kaui config status
/kaui config save
/kaui list status
/kaui list DPS
/kaui list DPS compact
/kaui cond status
/kaui cond missing
/kaui cond set 1 ${Me.PctHPs}<50
/kaui stop
```

Use `/kaui stop` to trigger a clean shutdown and `onShutdown` hooks.

## Structure

- `main.lua`: stable entrypoint.
- `core/`: bootstrap, constants, runtime, loop, commands, MQ/TLO helpers, logging.
- `config/`: KissAssist INI parser/save support in `mq.configDir`, typed schema, character/server file resolution, ordered lists and `[KConditions]`.
- `modules/`: runtime module registry and `onInit`, `onPulse`, `onShutdown` hooks.
- `ui/`: ImGui window for load/save, status and raw INI editing.
- `utils/`: shared helpers.
