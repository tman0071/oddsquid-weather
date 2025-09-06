local QBCore = exports['qb-core']:GetCoreObject()

local CurrentWeather = 'CLEAR'
local FreezeWeather = false
local Blackout = false
local FreezeTime = false
local Hour = 9
local Minute = 0
local GameMinuteDuration = 2000
local DynamicWeather = true
local TransitionSeconds = 30

local TsunamiActive = false
local TsunamiTimerThread = nil

-- ===== Utilities =====
local function dbg(...)
    if Config.Debug then
        print('[qb_weather]', ...)
    end
end

local function IsAllowed(src)
    if Config.UseAcePermissions then
        -- ACE-based permission
        return IsPlayerAceAllowed(src, Config.AceCommand)
    else
        -- QBCore permissions
        return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
    end
end

local function BroadcastWeather()
    TriggerClientEvent('qb_weather:client:SyncWeather', -1, CurrentWeather, FreezeWeather, Blackout, TransitionSeconds, TsunamiActive)
end

local function BroadcastTime()
    TriggerClientEvent('qb_weather:client:SyncTime', -1, Hour, Minute, FreezeTime, GameMinuteDuration)
end

local function NotifyAll(msg, typ)
    if Config.UseQBNotify then
        TriggerClientEvent('QBCore:Notify', -1, msg, typ or 'primary', 7500)
    else
        TriggerClientEvent('chat:addMessage', -1, { args = { '^2WEATHER', msg } })
    end
end

local function NextWeatherFromGroup(current)
    -- Try to pick next weather with a bias to remain in the same "group"
    local groups = Config.WeatherGroups
    local groupName = nil
    for name, arr in pairs(groups) do
        for _, wt in ipairs(arr) do
            if wt == current then
                groupName = name
                break
            end
        end
        if groupName then break end
    end

    local function randomFrom(tbl) return tbl[math.random(1, #tbl)] end

    if groupName and math.random() < Config.SameGroupBias then
        return randomFrom(groups[groupName])
    else
        return Config.WeatherTypes[math.random(1, #Config.WeatherTypes)]
    end
end

-- ===== Time Thread =====
CreateThread(function()
    FreezeTime = Config.FreezeTime
    Hour = Config.StartHour
    Minute = Config.StartMinute
    GameMinuteDuration = Config.GameMinuteDuration
    BroadcastTime()

    while true do
        Wait(GameMinuteDuration)
        if not FreezeTime then
            Minute = Minute + 1
            if Minute >= 60 then
                Minute = 0
                Hour = (Hour + 1) % 24
            end
            BroadcastTime()
        end
    end
end)

-- ===== Dynamic Weather Thread =====
CreateThread(function()
    DynamicWeather = Config.DynamicWeather
    TransitionSeconds = Config.TransitionSeconds
    while true do
        Wait(1000) -- Small delay to let resource init
        if DynamicWeather and not FreezeWeather and not TsunamiActive then
            Wait(Config.NewWeatherTimer * 60000)
            if DynamicWeather and not FreezeWeather and not TsunamiActive then
                CurrentWeather = NextWeatherFromGroup(CurrentWeather)
                dbg('Dynamic change to', CurrentWeather)
                BroadcastWeather()
                NotifyAll(('Weather is changing to %s.'):format(CurrentWeather), 'primary')
            end
        else
            Wait(2000)
        end
    end
end)

-- ===== Sync for joining players =====
RegisterNetEvent('qb_weather:server:RequestSync', function()
    local src = source
    TriggerClientEvent('qb_weather:client:SyncWeather', src, CurrentWeather, FreezeWeather, Blackout, TransitionSeconds, TsunamiActive)
    TriggerClientEvent('qb_weather:client:SyncTime', src, Hour, Minute, FreezeTime, GameMinuteDuration)
end)

-- ===== Admin Commands =====
local function register(cmd, cb, restricted)
    RegisterCommand(cmd, function(source, args, raw)
        if source == 0 then
            cb(0, args)
            return
        end
        if Config.UseAcePermissions then
            if not IsPlayerAceAllowed(source, Config.AceCommand) then
                TriggerClientEvent('QBCore:Notify', source, 'Not authorized', 'error')
                return
            end
        else
            if not IsAllowed(source) then
                TriggerClientEvent('QBCore:Notify', source, 'Not authorized', 'error')
                return
            end
        end
        cb(source, args)
    end, restricted or false)
end

register('weather', function(src, args)
    local t = (args[1] or ''):upper()
    if t == '' then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /weather <type>', 'error')
        return
    end
    -- Validate
    local ok = false
    for _, wt in ipairs(Config.WeatherTypes) do
        if wt == t then ok = true break end
    end
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, ('Invalid weather type: %s'):format(t), 'error')
        return
    end
    CurrentWeather = t
    FreezeWeather = true -- if admin sets, lock it until /freezeweather toggled off
    BroadcastWeather()
    NotifyAll(('Admin set weather to %s.'):format(t), 'primary')
end, Config.UseAcePermissions)

register('freezeweather', function(src, args)
    FreezeWeather = not FreezeWeather
    if FreezeWeather then
        NotifyAll('Weather is now frozen.', 'primary')
    else
        NotifyAll('Weather is now dynamic.', 'primary')
    end
    BroadcastWeather()
end, Config.UseAcePermissions)

register('blackout', function(src, args)
    Blackout = not Blackout
    BroadcastWeather()
    NotifyAll(Blackout and 'City-wide blackout activated.' or 'Blackout ended. Power restored.', Blackout and 'error' or 'success')
end, Config.UseAcePermissions)

register('freezetime', function(src, args)
    FreezeTime = not FreezeTime
    BroadcastTime()
    TriggerClientEvent('QBCore:Notify', src, FreezeTime and 'Time is now frozen.' or 'Time unfrozen.', 'primary')
end, Config.UseAcePermissions)

register('time', function(src, args)
    local h = tonumber(args[1] or '')
    local m = tonumber(args[2] or '0')
    if not h or h < 0 or h > 23 or not m or m < 0 or m > 59 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /time <hour 0-23> <minute 0-59>', 'error')
        return
    end
    Hour, Minute = h, m
    BroadcastTime()
    TriggerClientEvent('QBCore:Notify', src, ('Time set to %02d:%02d'):format(Hour, Minute), 'primary')
end, Config.UseAcePermissions)

register('timescale', function(src, args)
    local ms = tonumber(args[1] or '')
    if not ms or ms < 250 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /timescale <ms per game minute> (>=250)', 'error')
        return
    end
    GameMinuteDuration = ms
    BroadcastTime()
    TriggerClientEvent('QBCore:Notify', src, ('Game minute duration set to %d ms.'):format(ms), 'primary')
end, Config.UseAcePermissions)

local function StopTsunami()
    TsunamiActive = false
    -- Clear blackout (optional: keep it if you want)
    Blackout = false
    BroadcastWeather()
    NotifyAll('Tsunami sequence cancelled / ended.', 'success')
end

local function TsunamiThread(leadMinutes)
    if TsunamiTimerThread then return end
    TsunamiTimerThread = true
    TsunamiActive = true
    DynamicWeather = false
    FreezeWeather = true

    local total_ms = (leadMinutes or Config.TsunamiLeadMinutes) * 60000
    local startTime = GetGameTimer()
    local fired = {}

    -- Initial announce
    CurrentWeather = Config.TsunamiWeatherSequence[leadMinutes] or 'RAIN'
    BroadcastWeather()
    NotifyAll(('EMERGENCY: Tsunami predicted in ~%d minutes! Seek higher ground!'):format(leadMinutes), 'error')

    while TsunamiActive do
        Wait(500)
        local elapsed = GetGameTimer() - startTime
        local remaining = math.max(0, total_ms - elapsed)
        local remMin = math.ceil(remaining / 60000)

        -- Trigger sequence steps at configured minute marks
        for minuteMark, weather in pairs(Config.TsunamiWeatherSequence) do
            if remMin <= minuteMark and not fired[minuteMark] then
                fired[minuteMark] = true
                CurrentWeather = weather
                BroadcastWeather()
                NotifyAll(('Tsunami ETA ~%d min. Conditions worsening (%s).'):format(minuteMark, weather), 'error')
            end
        end

        -- Auto blackout
        if Config.TsunamiAutoBlackoutMinute and remMin <= Config.TsunamiAutoBlackoutMinute and not fired['blackout'] then
            fired['blackout'] = true
            Blackout = true
            BroadcastWeather()
            NotifyAll('Power grid failure! City-wide blackout!', 'error')
        end

        -- Water XML (optional)
        if Config.EnableWaterXML then
            if Config.FloodPhaseMinute and remMin <= Config.FloodPhaseMinute and not fired['flood'] then
                fired['flood'] = true
                TriggerClientEvent('qb_weather:client:LoadWaterPhase', -1, 'flood')
            end
            if Config.MaxFloodMinute and remMin <= Config.MaxFloodMinute and not fired['max'] then
                fired['max'] = true
                TriggerClientEvent('qb_weather:client:LoadWaterPhase', -1, 'max')
            end
        end

        if remaining <= 0 then
            -- Final blast: keep storm & blackout; server will restart externally.
            NotifyAll('TSUNAMI IMMINENT! Server restarting now...', 'error')
            break
        end
    end

    TsunamiTimerThread = nil
end

register('tsunami', function(src, args)
    local sub = (args[1] or 'start'):lower()
    if sub == 'stop' or sub == 'cancel' then
        StopTsunami()
        return
    end
    local mins = tonumber(args[2] or '') or Config.TsunamiLeadMinutes
    if mins < 1 then mins = 1 end
    CreateThread(function() TsunamiThread(mins) end)
end, Config.UseAcePermissions)

-- External trigger (e.g., from cron via rconcmd or server event)
RegisterNetEvent('qb_weather:server:StartTsunami', function(mins)
    if not mins or mins < 1 then mins = Config.TsunamiLeadMinutes end
    CreateThread(function() TsunamiThread(mins) end)
end)

RegisterNetEvent('qb_weather:server:StopTsunami', function()
    StopTsunami()
end)

-- Optional auto-schedule based on Config.RestartTimes
CreateThread(function()
    if not Config.TsunamiEnabled or not Config.TsunamiAutoSchedule or #Config.RestartTimes == 0 then return end
    while true do
        Wait(10000)
        local now = os.date('*t') -- server local time
        local hh = now.hour
        local mm = now.min
        for _, t in ipairs(Config.RestartTimes) do
            local H, M = t:match('^(%d%d):(%d%d)$')
            H = tonumber(H); M = tonumber(M)
            if H then
                -- compute minutes until restart
                local restartTotalMin = H*60 + M
                local nowTotalMin = hh*60 + mm
                local delta = restartTotalMin - nowTotalMin
                if delta < 0 then delta = delta + 1440 end -- wrap next day

                if delta == Config.TsunamiLeadMinutes then
                    if not TsunamiActive then
                        CreateThread(function() TsunamiThread(Config.TsunamiLeadMinutes) end)
                    end
                end
            end
        end
    end
end)
