-- zdx_vehicles server main

RegisterNetEvent('zdx_vehicles:SpawnVehicle', function(model)
    local src = source
    print("ZDX Vehicles: Spawning vehicle " .. tostring(model) .. " for source " .. tostring(src))
end)
