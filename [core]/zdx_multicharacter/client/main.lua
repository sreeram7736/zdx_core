local currentRoom = nil
local characterPeds = {}
local activeCam = nil
local inCharacterMenu = false
local selectedCharacter = nil
local playerPed = nil
local originalCoords = nil

-- Prevent multiple instances
CreateThread(function()
    while true do
        Wait(0)
        if inCharacterMenu then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Mouse look
            EnableControlAction(0, 2, true) -- Mouse look
        end
    end
end)

RegisterNetEvent('nexus-multicharacter:client:open', function()
    if inCharacterMenu then return end
    inCharacterMenu = true
    
    playerPed = PlayerPedId()
    originalCoords = GetEntityCoords(playerPed)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetupCharacterRoom()
    Wait(100)
    
    DoScreenFadeIn(1000)
    OpenCharacterUI()
end)

function SetupCharacterRoom()
    local room = Config.Rooms[Config.DefaultRoom]
    currentRoom = room
    
    -- Set player invisible and freeze
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)
    SetEntityInvincible(playerPed, true)
    
    -- Teleport to room
    SetEntityCoords(playerPed, room.coords.x, room.coords.y, room.coords.z, false, false, false, false)
    SetEntityHeading(playerPed, room.coords.w)
    
    -- Set time and weather
    NetworkOverrideClockTime(room.lighting.time, 0, 0)
    SetWeatherTypePersist(room.lighting.weather)
    SetWeatherTypeNow(room.lighting.weather)
    SetWeatherTypeNowPersist(room.lighting.weather)
    
    -- Disable HUD
    DisplayRadar(false)
    DisplayHud(false)
    
    -- Create main camera
    CreateMainCamera()
    
    -- Request character data
    TriggerServerCallback('nexus-multicharacter:server:getCharacters', function(data)
        if data then
            CreateCharacterPeds(data.characters)
            SendNUIMessage({
                action = 'openCharacterHub',
                characters = data.characters,
                maxSlots = data.maxSlots
            })
        end
    end)
end

function CreateMainCamera()
    local room = currentRoom
    if not room then return end
    
    local camData = room.mainCamera
    
    if activeCam then
        DestroyCam(activeCam, false)
    end
    
    activeCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camData.coords.x, camData.coords.y, camData.coords.z,
        camData.rotation.x, camData.rotation.y, camData.rotation.z,
        camData.fov,
        false, 0
    )
    
    SetCamActive(activeCam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    -- Smooth entrance animation
    CreateThread(function()
        local startFov = camData.fov + 20.0
        local endFov = camData.fov
        local duration = Config.Cameras.animations.entrance.duration
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < duration do
            local progress = (GetGameTimer() - startTime) / duration
            local currentFov = startFov + (endFov - startFov) * EaseInOutCubic(progress)
            SetCamFov(activeCam, currentFov)
            Wait(0)
        end
    end)
end

function CreateCharacterPeds(characters)
    -- Clean up existing peds
    for _, ped in pairs(characterPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    characterPeds = {}
    
    local room = currentRoom
    if not room then return end
    
    for _, charData in ipairs(characters) do
        local slot = charData.slot
        if room.positions[slot] then
            local pos = room.positions[slot]
            local model = charData.gender == 'male' and `mp_m_freemode_01` or `mp_f_freemode_01`
            
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            
            local ped = CreatePed(4, model, pos.ped.x, pos.ped.y, pos.ped.z, pos.ped.w, false, true)
            
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedCanRagdoll(ped, false)
            
            -- Apply appearance
            if charData.appearance then
                local appearance = type(charData.appearance) == 'string' and json.decode(charData.appearance) or charData.appearance
                
                -- Wait for ped to be ready
                while not DoesEntityExist(ped) do Wait(10) end
                
                local success, error = pcall(function()
                    exports[Config.Appearance.resource]:setPedAppearance(ped, appearance)
                end)
                
                if not success then
                    print('^3[WARNING] Failed to set appearance for slot ' .. slot .. ': ' .. tostring(error) .. '^0')
                end
            end
            
            -- Apply scenario
            if pos.scenario then
                TaskStartScenarioInPlace(ped, pos.scenario, 0, true)
            end
            
            characterPeds[slot] = ped
            
            SetModelAsNoLongerNeeded(model)
        end
    end
end

function OpenCharacterUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        visible = true
    })
end

function CloseCharacterUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'setVisible',
        visible = false
    })
end

function CleanupCharacterSelection()
    -- Clean up cameras
    if activeCam then
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
    
    -- Restore player
    if DoesEntityExist(playerPed) then
        SetEntityVisible(playerPed, true, false)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
    end
    
    -- Restore HUD
    DisplayRadar(true)
    DisplayHud(true)
    
    -- Reset time/weather
    NetworkOverrideClockTimeFreeze(false)
    
    inCharacterMenu = false
    CloseCharacterUI()
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CleanupCharacterSelection()
    cb('ok')
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    selectedCharacter = data
    
    -- Open spawn selector
    SendNUIMessage({
        action = 'openSpawnSelector',
        character = data.character,
        spawns = Config.Spawns
    })
    
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('nexus-multicharacter:server:createCharacter', data)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('nexus-multicharacter:server:deleteCharacter', data.slot)
    cb('ok')
end)

RegisterNUICallback('editCharacter', function(data, cb)
    CloseCharacterUI()
    OpenAppearanceCreator(data.character, false)
    cb('ok')
end)

RegisterNUICallback('focusCharacter', function(data, cb)
    FocusOnCharacter(data.slot)
    cb('ok')
end)

RegisterNUICallback('disconnect', function(data, cb)
    cb('ok')
    Wait(100)
    TriggerServerEvent('nexus-multicharacter:server:disconnect')
end)

-- Server events
RegisterNetEvent('nexus-multicharacter:client:characterCreated', function(slot)
    -- Close UI and open appearance
    CloseCharacterUI()
    
    TriggerServerCallback('nexus-multicharacter:server:getCharacter', function(character)
        if character then
            OpenAppearanceCreator(character, true)
        end
    end, slot)
end)

RegisterNetEvent('nexus-multicharacter:client:characterDeleted', function(slot)
    -- Remove ped
    if characterPeds[slot] and DoesEntityExist(characterPeds[slot]) then
        DeleteEntity(characterPeds[slot])
        characterPeds[slot] = nil
    end
    
    -- Refresh character list
    TriggerServerCallback('nexus-multicharacter:server:getCharacters', function(data)
        if data then
            CreateCharacterPeds(data.characters)
            SendNUIMessage({
                action = 'updateCharacters',
                characters = data.characters,
                maxSlots = data.maxSlots
            })
        end
    end)
end)

RegisterNetEvent('nexus-multicharacter:client:notify', function(type, message)
    -- Add your notification system here
    print('[Notification] ' .. type .. ': ' .. message)
end)

-- Command for testing
RegisterCommand('charmenu', function()
    TriggerEvent('nexus-multicharacter:client:open')
end, false)