function OpenAppearanceCreator(charData, isNew)
    if not charData then return end
    
    local config = {
        ped = true,
        headBlend = true,
        faceFeatures = true,
        headOverlays = true,
        components = true,
        props = true,
        tattoos = true,
        enableExit = true
    }
    
    if not isNew and charData.appearance then
        local appearance = type(charData.appearance) == 'string' and json.decode(charData.appearance) or charData.appearance
        config.currentClothing = appearance
    end
    
    -- Use pcall to catch errors
    local success, error = pcall(function()
        exports[Config.Appearance.resource]:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('nexus-multicharacter:server:saveAppearance', charData.slot, appearance)
                
                -- If new character, take screenshot
                if isNew and Config.Screenshots.enabled then
                    Wait(500)
                    TriggerServerEvent('nexus-multicharacter:server:saveScreenshot', charData.slot)
                end
            else
                -- User cancelled
                if isNew then
                    -- Delete character if was creation
                    TriggerServerEvent('nexus-multicharacter:server:deleteCharacter', charData.slot)
                end
            end
            
            -- Return to character selection
            Wait(500)
            TriggerEvent('nexus-multicharacter:client:open')
        end, config)
    end)
    
    if not success then
        print('^1[ERROR] Failed to open appearance creator: ' .. tostring(error) .. '^0')
        TriggerEvent('nexus-multicharacter:client:notify', 'error', 'Failed to open appearance creator')
        
        if isNew then
            TriggerServerEvent('nexus-multicharacter:server:deleteCharacter', charData.slot)
        end
        
        TriggerEvent('nexus-multicharacter:client:open')
    end
end