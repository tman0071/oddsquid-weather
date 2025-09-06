-- qb_weather/client/main.lua (fixed)
local currentWeather = 'CLEAR'
local freezeWeather = false
local blackout = false
local transitionSeconds = 30
local tsunamiActive = false

local hour = 9
local minute = 0
local freezeTime = false
local gameMinuteDuration = 2000

local function dbg(...)
    if Config and Config.Debug then
        print('[qb_weather:client]', ...)
    end
end

local function applyBlackout(enabled)
    blackout = enabled and true or false
    SetArtificialLightsState(blackout)
    -- Control whether vehicles are also affected
    if Config and Config.BlackoutAffectsVehicles ~= nil then
        SetArtificialLightsStateAffectsVehicles(Config.BlackoutAffectsVehicles and true or false)
    end
end

local function setWeatherSmooth(wtype, seconds)
    local t = tonumber(seconds) or 15
    if t > 15 then t = 15 end -- native cap
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeOverTime(wtype, t + 0.0)
    Wait(t * 1000)
    SetWeatherTypeNowPersist(wtype)
    SetWeatherTypeNow(wtype)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    if wtype == 'XMAS' or wtype == 'SNOW' or wtype == 'BLIZZARD' or wtype == 'SNOWLIGHT' then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    end
end

local function setWeatherInstant(wtype)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(wtype)
    SetWeatherTypeNow(wtype)
end

RegisterNetEvent('qb_weather:client:SyncWeather', function(wtype, freeze, blackoutState, transSeconds, tsunami)
    currentWeather = wtype or currentWeather
    freezeWeather = freeze and true or false
    transitionSeconds = transSeconds or transitionSeconds
    tsunamiActive = tsunami and true or false

    dbg('SyncWeather', currentWeather, 'freeze=', freezeWeather, 'blackout=', blackoutState, 'tsunami=', tsunamiActive)

    applyBlackout(blackoutState)

    if transitionSeconds and transitionSeconds > 0 and not tsunamiActive then
        setWeatherSmooth(currentWeather, transitionSeconds)
    else
        setWeatherInstant(currentWeather)
    end
end)

RegisterNetEvent('qb_weather:client:SyncTime', function(h, m, freeze, msPerMinute)
    hour = tonumber(h) or hour
    minute = tonumber(m) or minute
    freezeTime = freeze and true or false
    gameMinuteDuration = tonumber(msPerMinute) or gameMinuteDuration
    NetworkOverrideClockTime(hour, minute, 0)
end)

-- Gentle local time advancement to reduce snapping
CreateThread(function()
    while true do
        Wait(gameMinuteDuration)
        if not freezeTime then
            minute = minute + 1
            if minute >= 60 then
                minute = 0
                hour = (hour + 1) % 24
            end
            NetworkOverrideClockTime(hour, minute, 0)
        end
    end
end)

-- Bridge to qb_wateroverride (template). If present, we request a phase change.
RegisterNetEvent('qb_weather:client:LoadWaterPhase', function(phase)
    if not Config or not Config.EnableWaterXML then return end
    if phase == 'flood' then
        TriggerServerEvent('qb_wateroverride:server:setPhase', 'flood')
    elseif phase == 'max' then
        TriggerServerEvent('qb_wateroverride:server:setPhase', 'max')
    elseif phase == 'normal' then
        TriggerServerEvent('qb_wateroverride:server:setPhase', 'normal')
    end
end)

-- Simple tsunami FX: camera shakes & extra ambiance (does not raise water level)
local function tsunamiFXTick()
    while tsunamiActive do
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.2)
        Wait(3000)
    end
end

RegisterNetEvent('qb_weather:client:TsunamiFX', function(active)
    tsunamiActive = active and true or false
    if active then
        CreateThread(tsunamiFXTick)
    end
end)

-- Enforcement loop: keep tsunami weather/blackout if another script changes it
CreateThread(function()
    while true do
        if tsunamiActive then
            -- Re-apply weather persistently
            if currentWeather then
                ClearOverrideWeather()
                ClearWeatherTypePersist()
                SetWeatherTypeNowPersist(currentWeather)
                SetWeatherTypeNow(currentWeather)
            end
            -- Re-apply blackout
            SetArtificialLightsState(blackout)
            if Config and Config.BlackoutAffectsVehicles ~= nil then
                SetArtificialLightsStateAffectsVehicles(Config.BlackoutAffectsVehicles and true or false)
            end
            Wait(5000)
        else
            Wait(1000)
        end
    end
end)


-- Request initial sync
CreateThread(function()
    Wait(500)
    TriggerServerEvent('qb_weather:server:RequestSync')
end)
