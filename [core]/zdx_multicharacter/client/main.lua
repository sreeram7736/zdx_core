_print = print

local jsLoaded = false
local isOpen = false
local multicharInitDone = false
local previewPed = nil
local characterList = {}
local currentPreviewCharId = nil

function GetCurrentPreviewCharId()
    return currentPreviewCharId
end

function ResolveModelHash(model, fallbackHash)
    if model == nil or model == "" then return fallbackHash end
    if type(model) == "string" then
        local numeric = tonumber(model)
        if numeric then model = numeric else model = GetHashKey(model) end
    end
    return model
end

function DeletePreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

function SpawnPreviewPed(modelHash)
    DeletePreviewPed()

    local cfg = Config.CinematicRoom
    if not cfg then return nil end

    modelHash = ResolveModelHash(modelHash, GetHashKey("mp_m_freemode_01"))

    RequestModel(modelHash)
    local waited = 0
    while not HasModelLoaded(modelHash) and waited < 5000 do
        Wait(10)
        waited = waited + 10
    end

    if not HasModelLoaded(modelHash) then
        return nil
    end

    previewPed = CreatePed(6, modelHash, cfg.pedCoords.x, cfg.pedCoords.y, cfg.pedCoords.z, cfg.pedCoords.w, false, false)
    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetEntityCollision(previewPed, true, true)
    SetEntityAlpha(previewPed, 255, false)

    -- Play simple idle anim
    RequestAnimDict("anim@heists@heist_corona@single_team")
    while not HasAnimDictLoaded("anim@heists@heist_corona@single_team") do Wait(10) end
    TaskPlayAnim(previewPed, "anim@heists@heist_corona@single_team", "single_team_loop_boss", 8.0, -8.0, -1, 1, 0, false, false, false)

    SetModelAsNoLongerNeeded(modelHash)
    return previewPed
end

function OpenMulticharUI(characters, maxChars, canDelete)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        characters = characters or {},
        maxCharacters = maxChars or 5,
        canDelete = canDelete
    })
end

function OpenMultichar()
    if isOpen then return end
    isOpen = true

    DisplayHud(false)
    SetNuiFocus(true, true)
    DoScreenFadeOut(500)
    Wait(500)

    CameraSystem.CreatePreviewCam()
    CameraSystem.ApplyEnvironment()

    TriggerServerEvent("zdx_multichar:playerEnteredMultichar")

    while not jsLoaded do Wait(500) end

    Core.TriggerCallback("zdx_multichar:getCharacters", function(response)
        local characters = response.characters or {}
        local maxCharacters = response.maxCharacters or 5
        local canDelete = response.canDelete
        characterList = characters

        OpenMulticharUI(characters, maxCharacters, canDelete)
        
        if #characters > 0 then
            currentPreviewCharId = characters[1].id
            TriggerServerEvent("zdx_multichar:previewCharacter", currentPreviewCharId)
        else
            SpawnPreviewPed()
            Wait(1000)
            DoScreenFadeIn(400)
            SendNUIMessage({ action = "setReady", ready = true })
        end
    end)
end

function CloseMultichar(skipServerLeaveEvent)
    if not isOpen then return end
    isOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    
    DeletePreviewPed()
    CameraSystem.DestroyAllCams()

    DisplayHud(true)

    if not skipServerLeaveEvent then
        TriggerServerEvent("zdx_multichar:playerLeftMultichar")
    end
end

function FinishSpawn(spawnCoords, heading, isNew, charData)
    if isNew and Config.SpawnWithApartment and Config.SpawnWithApartment ~= "Disabled" then
        if SpawnBridge and SpawnBridge.TriggerExternalSpawn then
            CloseMultichar(true)
            SpawnBridge.TriggerExternalSpawn(charData, true)
            return
        end
    end

    if Config.SpawnSelector and not isNew then
        if SpawnBridge and SpawnBridge.TriggerExternalSpawn then
            CloseMultichar(true)
            SpawnBridge.TriggerExternalSpawn(charData, false)
            return
        end
    end

    CloseMultichar(true)
    DoScreenFadeOut(500)
    Wait(500)

    local ped = PlayerPedId()
    SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
    SetEntityHeading(ped, heading or 0.0)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)

    Wait(1000)
    DoScreenFadeIn(1000)
    TriggerServerEvent("zdx_multichar:playerLeftMultichar")
end

function BeginCharacterSpawn(characterData, isNewCharacter)
    if not characterData or not characterData.id then return end

    SetNuiFocus(false, false)
    TriggerServerEvent("zdx_multichar:selectCharacter", characterData.id)

    CreateThread(function()
        Wait(isNewCharacter and 750 or 1500)
        local spawnSelection = nil

        if isNewCharacter then
            spawnSelection = { coords = Config.FirstSpawnLocation or vector3(0,0,0), heading = 0.0 }
        else
            spawnSelection = { coords = characterData.coords or Config.EmergencySpawnLocation, heading = characterData.heading or 0.0 }
        end

        FinishSpawn(spawnSelection.coords, spawnSelection.heading, isNewCharacter, characterData)
    end)
end

RegisterNUICallback("jsLoaded", function(data, cb)
    cb("ok")
    jsLoaded = true
end)

RegisterNUICallback("previewCharacter", function(data, cb)
    cb("ok")
    if data.id then
        currentPreviewCharId = data.id
        TriggerServerEvent("zdx_multichar:previewCharacter", data.id)
    end
end)

RegisterNUICallback("selectCharacter", function(data, cb)
    cb("ok")
    if data.id then
        currentPreviewCharId = data.id
        TriggerServerEvent("zdx_multichar:previewCharacter", data.id)
    end
end)

RegisterNUICallback("playCharacter", function(data, cb)
    cb("ok")
    if data.data then
        BeginCharacterSpawn(data.data, data.isNew == true)
    end
end)

RegisterNUICallback("createCharacter", function(data, cb)
    cb("ok")
    TriggerServerEvent("zdx_multichar:createCharacter", data)
end)

RegisterNUICallback("deleteCharacter", function(data, cb)
    cb("ok")
    if data.id then
        TriggerServerEvent("zdx_multichar:deleteCharacter", data.id)
    end
end)

RegisterNUICallback("quitGame", function(data, cb)
    cb("ok")
    TriggerServerEvent("zdx_multichar:server:quitGame")
end)

RegisterNetEvent("zdx_multichar:client:open", function()
    if not multicharInitDone then
        multicharInitDone = true
        OpenMultichar()
    end
end)

RegisterNetEvent("zdx_multichar:client:logout", function()
    if isOpen then return end
    multicharInitDone = false
    TriggerServerEvent("zdx_multichar:playerEnteredMultichar")
    Wait(500)
    OpenMultichar()
end)

RegisterNetEvent("zdx_multichar:client:updateCharacters", function(characters)
    characterList = characters or {}
    SendNUIMessage({ action = "setCharacters", characters = characters })
end)

RegisterNetEvent("zdx_multichar:client:characterCreated", function(characters, newCharId)
    characterList = characters or {}
    local newChar = nil
    for _, c in ipairs(characterList) do
        if tostring(c.id) == tostring(newCharId) then newChar = c break end
    end
    SendNUIMessage({ action = "characterCreated" })
    if newChar then BeginCharacterSpawn(newChar, true) end
end)

RegisterNetEvent("zdx_multichar:client:characterCreateFailed", function(reason)
    SendNUIMessage({ action = "setReady", ready = true })
    SendNUIMessage({ action = "characterCreated" })
    print("[zdx Multichar] Character creation failed:", reason)
end)

RegisterNetEvent("zdx_multichar:client:characterDeleted", function(characters)
    characterList = characters or {}
    SendNUIMessage({ action = "characterDeleted", characters = characters })
end)

RegisterNetEvent("zdx_multichar:client:previewPed", function(modelHash, appearance)
    local ped = SpawnPreviewPed(modelHash)
    if ped then
        pcall(function()
            ClothingBridge.ApplyAppearance(ped, appearance)
        end)
    end
    Wait(1000)
    DoScreenFadeIn(400)
    SendNUIMessage({ action = "setReady", ready = true })
end)

RegisterNetEvent("zdx_multichar:client:previewFailed", function()
    print("[zdx Multichar] Character preview failed on server")
    Wait(1000)
    DoScreenFadeIn(400)
    SendNUIMessage({ action = "setReady", ready = true })
end)

RegisterNetEvent("zdx_multichar:client:onPlayerLoaded", function()
    if Core.Framework == "qb" then
        TriggerServerEvent("QBCore:Server:OnPlayerLoaded")
        TriggerEvent("QBCore:Client:OnPlayerLoaded")
        TriggerServerEvent("qb-houses:server:sethouses")
    end
end)

RegisterNetEvent("zdx_multichar:client:cleanup", function()
    DeletePreviewPed()
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableIdleCamera(true)
        end
        Wait(1000)
    end
end)
