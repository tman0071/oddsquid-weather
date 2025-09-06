# qb_weather (QBCore) — Weather, Time, Tsunami & Blackout

A from‑scratch QBCore weather/time sync with:
- All GTA V weather types
- Smooth (gradual) weather transitions
- Admin commands (QBCore or ACE-permissions)
- Configurable time speed (ms per game minute)
- Manual blackouts + automatic blackout during tsunami
- Tsunami pre‑restart sequence (10 min lead by default)
- Optional water XML hooks for real flooding

## Install
1. Place the `oddsquid_weather` folder in your `resources/`.
2. Ensure **no other weather/time** resource is running (disable `qb-weathersync`, `vSync`, etc.).
3. Add to your `server.cfg`:
   ```
   ensure oddsquid_weather
   ```

## Config Highlights (`config.lua`)
- `UseAcePermissions = false`: toggle ACE vs QBCore permissions.
- `GameMinuteDuration = 2000`: lower = faster day; raise = slower.
- `DynamicWeather = true` with `NewWeatherTimer = 12` minutes per change.
- `TransitionSeconds = 30` for gradual changes.
- `BlackoutAffectsVehicles = false`: keep vehicle lights on during blackout.
- Tsunami:
  - `TsunamiEnabled = true`
  - `TsunamiAutoSchedule = false`
  - `RestartTimes = { '06:00', '12:00' }` if you want autoschedule.
  - `TsunamiLeadMinutes = 10`
  - `EnableWaterXML = false` (see **Flooding** below).

## Commands (Admin Only)
> If `UseAcePermissions = true`, grant ACE: `add_ace group.admin command.qbweather allow`

- `/weather <TYPE>` — Set weather and freeze it (e.g. EXTRASUNNY, RAIN, THUNDER, SNOW, etc.).
- `/freezeweather` — Toggle freeze vs dynamic cycling.
- `/blackout` — Toggle city-wide blackout.
- `/freezetime` — Toggle time freezing.
- `/time <hour> <minute>` — Set the time precisely.
- `/timescale <ms>` — Set ms per in‑game minute (>= 250 ms).
- `/tsunami [start [minutes]|stop]` — Start a tsunami sequence (default 10 min lead) or stop it.

### ACE Example (server.cfg)
```
add_ace group.admin command.qbweather allow
add_principal identifier.steam:YOURSTEAMHEX group.admin
```

## Cron / Pre‑Restart Hook
You have multiple options:
- **Manual RCON**: Call `tsunami start 10` via rcon 10 minutes before restart.
- **Server Event**: Trigger `qb_weather:server:StartTsunami` from another resource:
  ```lua
  TriggerEvent('qb_weather:server:StartTsunami', 10) -- 10 minutes
  ```
- **Autoschedule**: Set `TsunamiAutoSchedule = true` and fill `RestartTimes` in config.

## Flooding (Rising Water)
GTA V requires **water XML overrides** to actually raise sea level. This resource ships with
placeholder `water_flood.xml` and `water_max.xml`. Replace them with working water height maps
for your map/build, then set `EnableWaterXML = true`. The client event
`qb_weather:client:LoadWaterPhase` is a stub where you should integrate your loader (or pair this
with a dedicated water override resource).

Without water overrides enabled, the tsunami still delivers:
- Severe storm (RAIN/THUNDER/HALLOWEEN sequence)
- Camera shakes & atmosphere FX
- City‑wide blackout
- Countdown notifications

## Notes
- Smooth transitions are limited by GTA natives (~15s max blend). Longer transitions are simulated.
- Disable other weather/time scripts to avoid conflicts.
- New players receive sync on join.
- This resource uses QBCore notifications by default; adapt notify as desired.

## Credits
- Built for QBCore servers by ChatGPT (2025).


---
## Autoschedule (CST/CDT)
Config now defaults to autoscheduling tsunami at **00:00, 06:00, 12:00, 18:00** (server local time).
If your host is not set to America/Chicago, please adjust or set `RestartTimes` accordingly.

## Companion Water Override
A template resource `qb_wateroverride` is included. Enable it in `server.cfg`:
```
setr qbwater:phase normal
ensure qb_wateroverride
```
Then keep `Config.EnableWaterXML = true` in oddsquid_weather. During tsunami, oddsquid_weather asks `qb_wateroverride`
to switch to `flood` (at ~5m) and `max` (at ~1m) before restart. Replace the XMLs and set the correct
`data_file` type for your build in `qb_wateroverride/fxmanifest.lua`.
