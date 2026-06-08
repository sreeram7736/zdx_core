-- zdx_inventory server main

-- Interacts with ox_inventory to sync zdx cinematic props.
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    print("ZDX Inventory Bridge initialized for ox_inventory.")
end)
