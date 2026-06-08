-- zdx_vehicles client main

Citizen.CreateThread(function()
    print("ZDX Vehicles Initialized.")
end)

-- Helper function
local function GetPlayerVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    return nil
end

RegisterCommand('repair', function()
    local veh = GetPlayerVehicle()
    if veh then
        SetVehicleFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        print("Vehicle repaired.")
    end
end, false)

RegisterCommand('dv', function()
    local veh = GetPlayerVehicle()
    if veh then
        DeleteEntity(veh)
    end
end, false)

RegisterCommand('dirt', function(source, args)
    local veh = GetPlayerVehicle()
    if veh and args[1] then
        local dirt = tonumber(args[1])
        if dirt then
            SetVehicleDirtLevel(veh, dirt + 0.0)
        end
    end
end, false)

RegisterCommand('color', function(source, args)
    local veh = GetPlayerVehicle()
    if veh and args[1] and args[2] and args[3] then
        local r, g, b = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if r and g and b then
            SetVehicleCustomPrimaryColour(veh, r, g, b)
        end
    end
end, false)

RegisterCommand('color2', function(source, args)
    local veh = GetPlayerVehicle()
    if veh and args[1] and args[2] and args[3] then
        local r, g, b = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if r and g and b then
            SetVehicleCustomSecondaryColour(veh, r, g, b)
        end
    end
end, false)

RegisterCommand('livery', function(source, args)
    local veh = GetPlayerVehicle()
    if veh and args[1] then
        local livery = tonumber(args[1])
        if livery then
            SetVehicleLivery(veh, livery)
            SetVehicleMod(veh, 48, livery, false)
        end
    end
end, false)

RegisterCommand('maxperf', function()
    local veh = GetPlayerVehicle()
    if veh then
        SetVehicleModKit(veh, 0)
        SetVehicleMod(veh, 11, 3, false) -- Engine
        SetVehicleMod(veh, 12, 2, false) -- Brakes
        SetVehicleMod(veh, 13, 2, false) -- Transmission
        SetVehicleMod(veh, 15, 2, false) -- Suspension
        SetVehicleMod(veh, 16, 4, false) -- Armor
        ToggleVehicleMod(veh, 18, true)  -- Turbo
        print("Vehicle performance maxed.")
    end
end, false)

RegisterCommand('extra', function(source, args)
    local veh = GetPlayerVehicle()
    if veh and args[1] then
        local extraId = tonumber(args[1])
        if extraId and DoesExtraExist(veh, extraId) then
            local isEnabled = IsVehicleExtraTurnedOn(veh, extraId)
            SetVehicleExtra(veh, extraId, isEnabled and 1 or 0)
        end
    end
end, false)
