local spawnCam = nil
local previewingSpawn = nil

RegisterNUICallback('previewSpawn', function(data, cb)
    PreviewSpawnLocation(data.spawn)
    cb('ok')
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    SpawnAtLocation(data.spawn, data.character)
    cb('ok')
end)

function PreviewSpawnLocation(spawnId)
    local spawn = Config.Spawns[spawnId]
    
    if not spawn then return end
    
    if spawnId == 'last_location' then
        -- Return to main camera for last location
        ReturnToMainCamera()
        return
    end
    
    if not spawn.camera then return end
    
    -- Destroy previous spawn camera
    if spawnCam and DoesCamExist(spawnCam) then
        DestroyCam(spawnCam, false)
    end
    
    local cam = spawn.camera
    spawnCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        cam.x, cam.y, cam.z,
        -15.0, 0.0, cam.w,
        Config.Cameras.fov.default,
        false, 0
    )
    
    PointCamAtCoord(spawnCam, spawn.coords.x, spawn.coords.y, spawn.coords.z)
    
    if activeCam and DoesCamExist(activeCam) then
        SetCamActiveWithInterp(spawnCam, activeCam, Config.Cameras.animations.spawnPreview.duration, 1, 1)
    else
        SetCamActive(spawnCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    
    previewingSpawn = spawnId
end

function SpawnAtLocation(spawnId, character)
    if not character or not spawnId then return end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Clean up cameras
    if spawnCam and DoesCamExist(spawnCam) then
        DestroyCam(spawnCam, false)
        spawnCam = nil
    end
    if activeCam and DoesCamExist(activeCam) then
        DestroyCam(activeCam, false)
        activeCam = nil
    end
    RenderScriptCams(false, false, 0, true, true)
    
    -- Clean up peds
    for _, ped in pairs(characterPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    characterPeds = {}
    
    local spawn = Config.Spawns[spawnId]
    local ped = PlayerPedId()
    
    -- Set player visible again
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    
    -- Restore HUD
    DisplayRadar(true)
    DisplayHud(true)
    
    -- Spawn player
    if spawnId == 'last_location' and character.position then
        local success, pos = pcall(function()
            return json.decode(character.position)
        end)
        
        if success and pos and pos.x then
            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
            SetEntityHeading(ped, pos.w or 0.0)
        else
            -- Fallback to default spawn
            SetEntityCoords(ped, spawn.coords.x, spawn.coords.y, spawn.coords.z, false, false, false, false)
            SetEntityHeading(ped, spawn.coords.w)
        end
    elseif spawn then
        SetEntityCoords(ped, spawn.coords.x, spawn.coords.y, spawn.coords.z, false, false, false, false)
        SetEntityHeading(ped, spawn.coords.w)
    end
    
    -- Apply appearance
    if character.appearance then
        local success, appearance = pcall(function()
            return type(character.appearance) == 'string' and json.decode(character.appearance) or character.appearance
        end)
        
        if success and appearance then
            pcall(function()
                exports[Config.Appearance.resource]:setPlayerAppearance(appearance)
            end)
        end
    end
    
    -- Notify server
    TriggerServerEvent('nexus-multicharacter:server:selectCharacter', character.slot, spawnId)
    
    Wait(500)
    DoScreenFadeIn(1000)
    
    inCharacterMenu = false
    CloseCharacterUI()
end