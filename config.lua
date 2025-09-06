Config = {}

-- === Permissions ===
-- If true, commands are ACE-restricted and you must grant permissions in server.cfg
-- (e.g., add_ace group.admin command.qbweather allow)
-- If false, QBCore admin ('admin' or 'god') is used.
Config.UseAcePermissions = true
Config.AceCommand = 'command'  -- ace to check when UseAcePermissions = true

-- === Time Settings ===
-- Freeze in-game time entirely
Config.FreezeTime = false
-- Starting time (when resource starts)
Config.StartHour = 9
Config.StartMinute = 0
-- Duration (in milliseconds) of ONE in-game minute; smaller = faster days
-- GTA default is roughly 2000ms per game minute in many servers (48-min day)
Config.GameMinuteDuration = 2000

-- === Weather Settings ===
-- Gradual transitions duration in seconds (client will smooth blend up to ~15s per native;
-- longer values are simulated by chaining)
Config.TransitionSeconds = 30

-- Should the weather auto-cycle over time?
Config.DynamicWeather = true
-- Minutes between dynamic weather changes
Config.NewWeatherTimer = 12

-- All available weather types. Remove any you do not want to allow.
Config.WeatherTypes = {
    'EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'SMOG', 'FOGGY', 'OVERCAST', 'CLOUDS',
    'CLEARING', 'RAIN', 'THUNDER', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN']]
}

-- Weighted groups to choose "next" weather more naturally (optional).
-- The script will prefer moving within a group instead of jumping extremes.
Config.WeatherGroups = {
    Calm   = { 'EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'CLOUDS' },
    Hazy   = { 'SMOG', 'FOGGY', 'OVERCAST' },
    Rainy  = { 'CLEARING', 'RAIN', 'THUNDER' },
    Snowy  = { 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS' },
    Spooky = { 'HALLOWEEN' }
}
-- Probability to stay in same group on dynamic change (0.0 - 1.0)
Config.SameGroupBias = 0.65

-- === Blackout ===
Config.BlackoutAffectsVehicles = false  -- if true, blackout also kills vehicle lights

-- === Tsunami / Pre-Restart Event ===
Config.TsunamiEnabled = true
-- If you have fixed daily restart times, list them here as 'HH:MM' in SERVER'S LOCAL TIME.
-- When TsunamiAutoSchedule = true, the script will trigger tsunami LeadMinutes before each time.
Config.RestartTimes = { '00:00', '06:00', '12:00', '18:00' } -- America/Chicago (CST/CDT) -- e.g., { '06:00', '12:00', '18:00', '00:00' }
Config.TsunamiAutoSchedule = true
Config.TsunamiLeadMinutes = 10

-- Weather sequence during tsunami (minutes remaining -> weather type)
Config.TsunamiWeatherSequence = {
    [10] = 'RAIN',
    [5]  = 'THUNDER',
    [1]  = 'HALLOWEEN' -- optional for dramatic sky
}

-- Automatically enable blackout during tsunami (at 5 minutes remaining)
Config.TsunamiAutoBlackoutMinute = 5

-- Water override support (requires valid water XMLs packaged & supported by your build)
Config.EnableWaterXML = true      -- Set to true if you have working water_flood.xml / water_max.xml
Config.FloodPhaseMinute = 5        -- minute remaining when "flood" should load
Config.MaxFloodMinute   = 1        -- minute remaining when "max flood" should load

-- Notifications (customize with your phone/notify system if desired)
Config.UseQBNotify = false          -- uses QBCore:Notify for basic messages

-- Debug
Config.Debug = false
