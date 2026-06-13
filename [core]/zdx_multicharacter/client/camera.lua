CameraSystem = {}

local activeCam = nil
local spawnFading = false
local spawnStreamCoords = nil

function CameraSystem.CreatePreviewCam()
    CameraSystem.DestroyAllCams()

    local cfg = Config.CinematicRoom
    if not cfg then return end

    activeCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        cfg.camCoords.x, cfg.camCoords.y, cfg.camCoords.z,
        0.0, 0.0, 0.0,
        cfg.fov or 50.0,
        false, 0
    )

    PointCamAtCoord(activeCam, cfg.camPointAt.x, cfg.camPointAt.y, cfg.camPointAt.z)
    SetCamActive(activeCam, true)
    RenderScriptCams(true, false, 0, true, false)
end

function CameraSystem.DestroyAllCams()
    spawnFading = false
    spawnStreamCoords = nil

    if activeCam then
        SetCamActive(activeCam, false)
        DestroyCam(activeCam, false)
        activeCam = nil
    end

    RenderScriptCams(false, false, 0, true, false)
end

function CameraSystem.ApplyEnvironment()
    local cfg = Config.CinematicRoom
    if not cfg then return end

    local weather = cfg.weather or "CLEAR"
    SetWeatherTypePersist(weather)
    SetWeatherTypeNowPersist(weather)
    SetOverrideWeather(weather)

    local time = cfg.time or { hour = 12, minute = 0 }
    NetworkOverrideClockTime(time.hour, time.minute, 0)
end

function CameraSystem.InterpToCoords(camPos, pointAt, streamCoords, _unused)
    if spawnFading then return end
    spawnFading = true
    spawnStreamCoords = streamCoords

    CreateThread(function()
        DoScreenFadeOut(0)
        while not IsScreenFadedOut() do
            Wait(250)
        end

        if not activeCam then
            activeCam = CreateCamWithParams(
                "DEFAULT_SCRIPTED_CAMERA",
                camPos.x, camPos.y, camPos.z,
                0.0, 0.0, 0.0,
                50.0,
                false, 0
            )
            SetCamActive(activeCam, true)
            RenderScriptCams(true, false, 0, true, false)
        else
            SetCamCoord(activeCam, camPos.x, camPos.y, camPos.z)
        end

        PointCamAtCoord(activeCam, pointAt.x, pointAt.y, pointAt.z)
        DoScreenFadeIn(750)
        Wait(750)
        spawnFading = false
    end)
end

function CameraSystem.StopSpawnStream()
    spawnStreamCoords = nil
end

function CameraSystem.IsSpawnFading()
    return spawnFading
end

CreateThread(function()
    while true do
        if spawnStreamCoords then
            local ped = PlayerPedId()
            SetEntityCoords(ped, spawnStreamCoords.x, spawnStreamCoords.y, spawnStreamCoords.z, false, false, false, false)
            SetEntityVisible(ped, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityHealth(ped, 200)
        else
            Wait(500)
        end
        Wait(0)
    end
end)
