
SettingsHandler = {}

local cinematicEnabled = false
local fpsModeEnabled = false
local cinematicBarAlpha = 0.0
local cinematicBarHeight = 0.12

envWeather = nil
envHour = nil
envMinute = nil

local function WeatherKvpKey(locationId)
    return ("cylex_mc_weather_%s"):format(locationId)
end

local function TimeKvpKey(locationId)
    return ("cylex_mc_time_%s"):format(locationId)
end

local function GetLocationWeather(location)
    if envWeather then
        return envWeather
    end

    if not location then
        return nil
    end

    local savedWeather = GetResourceKvpString(WeatherKvpKey(location.id))
    if savedWeather and savedWeather ~= "" then
        return savedWeather
    end

    return location.weather or nil
end

local function GetLocationTime(location)
    if envHour then
        return { hour = envHour, minute = envMinute or 0 }
    end

    if not location then
        return nil
    end

    local savedTime = GetResourceKvpString(TimeKvpKey(location.id))
    if savedTime and savedTime ~= "" then
        local hour, minute = savedTime:match("^(%d+):(%d+)$")
        if hour then
            return { hour = tonumber(hour), minute = tonumber(minute) }
        end
    end

    return location.time or nil
end

RegisterNUICallback("changeWeather", function(data, cb)
    cb("ok")
    if not data.weather then
        return
    end

    envWeather = data.weather
    SetWeatherTypePersist(data.weather)
    SetWeatherTypeNow(data.weather)
    SetWeatherTypeNowPersist(data.weather)
    SetOverrideWeather(data.weather)

    if ActiveLocation and ActiveLocation.id then
        SetResourceKvp(WeatherKvpKey(ActiveLocation.id), data.weather)
    end
end)

RegisterNUICallback("changeTime", function(data, cb)
    cb("ok")

    local hour = tonumber(data.hour) or 12
    local minute = tonumber(data.minute) or 0
    envHour = hour
    envMinute = minute

    NetworkOverrideClockTime(hour, minute, 0)
    PauseClock(true)

    if ActiveLocation and ActiveLocation.id then
        SetResourceKvp(TimeKvpKey(ActiveLocation.id), ("%d:%d"):format(hour, minute))
    end
end)

RegisterNUICallback("toggleCinematic", function(data, cb)
    cb("ok")
    cinematicEnabled = data.enabled == true
end)

CreateThread(function()
    while true do
        if isOpen then
            if cinematicEnabled then
                cinematicBarAlpha = math.min(cinematicBarAlpha + 0.02, 1.0)
            else
                cinematicBarAlpha = math.max(cinematicBarAlpha - 0.03, 0.0)
            end

            if cinematicBarAlpha > 0.001 then
                local alpha = math.floor(cinematicBarAlpha * 255)
                DrawRect(0.5, cinematicBarHeight / 2, 1.0, cinematicBarHeight, 0, 0, 0, alpha)
                DrawRect(0.5, 1.0 - cinematicBarHeight / 2, 1.0, cinematicBarHeight, 0, 0, 0, alpha)
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
        Wait(0)
    end
end)

RegisterNUICallback("toggleFpsMode", function(data, cb)
    cb("ok")
    fpsModeEnabled = data.enabled == true

    if fpsModeEnabled then
        CascadeShadowsSetCascadeBoundsScale(0.0)
        CascadeShadowsEnableEntityTracker(false)
        SetDisableDecalRenderingThisFrame()
        SetArtificialLightsState(false)
        SetTimecycleModifier("cinema")
        SetTimecycleModifierStrength(0.2)
    else
        CascadeShadowsSetCascadeBoundsScale(1.0)
        CascadeShadowsEnableEntityTracker(true)
        ClearTimecycleModifier()
    end
end)

RegisterNUICallback("resetSettings", function(data, cb)
    cb("ok")
    if not ActiveLocation then
        return
    end

    envWeather = nil
    envHour = nil
    envMinute = nil

    for _, location in ipairs(Config.Locations) do
        DeleteResourceKvp(WeatherKvpKey(location.id))
        DeleteResourceKvp(TimeKvpKey(location.id))
    end

    cinematicEnabled = false
    if fpsModeEnabled then
        fpsModeEnabled = false
        CascadeShadowsSetCascadeBoundsScale(1.0)
        CascadeShadowsEnableEntityTracker(true)
        ClearTimecycleModifier()
    end

    local weather = (ActiveLocation and ActiveLocation.weather) or "CLEAR"
    local time = (ActiveLocation and ActiveLocation.time) or { hour = 12, minute = 0 }

    SendNUIMessage({
        action = "syncEnvironment",
        weather = weather,
        time = time,
        cinematicMode = false,
        fpsMode = false
    })
end)

CreateThread(function()
    while true do
        if isOpen then
            if fpsModeEnabled then
                SetDisableDecalRenderingThisFrame()
                CascadeShadowsSetCascadeBoundsScale(0.0)
            end

            local weather = GetLocationWeather(ActiveLocation)
            if weather then
                SetWeatherTypePersist(weather)
                SetWeatherTypeNow(weather)
                SetWeatherTypeNowPersist(weather)
                SetOverrideWeather(weather)

                local upper = weather:upper()
                if upper == "RAIN" or upper == "THUNDER" or upper == "CLEARING" then
                    SetRainLevel(1.0)
                else
                    SetRainLevel(0.0)
                end
            end

            local time = GetLocationTime(ActiveLocation)
            if time then
                NetworkOverrideClockTime(time.hour, time.minute, 0)
            end

            SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()), 0)

            if not fpsModeEnabled and not weather and not time then
                if not ActiveLocation then
                    Wait(1000)
                end
            else
                Wait(0)
            end
        else
            Wait(1000)
        end
    end
end)

function SettingsHandler.GetEnvWeather()
    return envWeather
end

function SettingsHandler.GetEnvHour()
    return envHour
end

function SettingsHandler.GetLocWeather(location)
    return GetLocationWeather(location)
end

function SettingsHandler.GetLocTime(location)
    return GetLocationTime(location)
end

function SettingsHandler.OnLocationChange()
    envWeather = nil
    envHour = nil
    envMinute = nil

    local weather = GetLocationWeather(ActiveLocation)
    local time = GetLocationTime(ActiveLocation)

    SendNUIMessage({
        action = "syncEnvironment",
        weather = weather,
        time = time
    })
end

function SettingsHandler.ResetAll()
    envWeather = nil
    ClearWeatherTypePersist()
    ClearOverrideWeather()
    SetWeatherTypeNowPersist("CLEAR")

    envHour = nil
    envMinute = nil
    PauseClock(false)

    cinematicEnabled = false
    if fpsModeEnabled then
        fpsModeEnabled = false
        CascadeShadowsSetCascadeBoundsScale(1.0)
        CascadeShadowsEnableEntityTracker(true)
        ClearTimecycleModifier()
    end
end

