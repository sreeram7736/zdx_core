function FocusOnCharacter(slot)
    local room = currentRoom
    if not room or not room.positions[slot] then 
        ReturnToMainCamera()
        return 
    end
    
    local pos = room.positions[slot]
    if not pos.camera then 
        ReturnToMainCamera()
        return 
    end
    
    local camData = pos.camera
    
    local newCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camData.x, camData.y, camData.z,
        0.0, 0.0, 0.0,
        Config.Cameras.fov.default,
        false, 0
    )
    
    -- Point camera at ped
    if characterPeds[slot] and DoesEntityExist(characterPeds[slot]) then
        PointCamAtEntity(newCam, characterPeds[slot], 0.0, 0.0, 0.5, true)
    else
        PointCamAtCoord(newCam, camData.x, camData.y, camData.z)
    end
    
    if activeCam and DoesCamExist(activeCam) then
        SetCamActiveWithInterp(newCam, activeCam, Config.Cameras.transitionSpeed, 1, 1)
        
        CreateThread(function()
            Wait(Config.Cameras.transitionSpeed)
            DestroyCam(activeCam, false)
        end)
    else
        SetCamActive(newCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    
    activeCam = newCam
end

function ReturnToMainCamera()
    if not inCharacterMenu then return end
    CreateMainCamera()
end

-- Easing functions
function EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - math.pow(-2 * t + 2, 3) / 2
    end
end

function EaseInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - math.pow(-2 * t + 2, 2) / 2
    end
end

function EaseInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end