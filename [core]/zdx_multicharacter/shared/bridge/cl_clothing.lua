

ClothingBridge = ClothingBridge or {}

local clothingHandlers = {
    {
        name = 'illenium-appearance',
        handler = function(ped, skin)
            exports['illenium-appearance']:setPedAppearance(ped, skin)
        end
    },
    {
        name = 'fivem-appearance',
        handler = function(ped, skin)
            exports['fivem-appearance']:setPedAppearance(ped, skin)
        end
    },
    {
        name = 'bs-appearance',
        handler = function(ped, skin)
            exports['bs-appearance']:setPedAppearance(ped, skin)
        end
    },
    {
        name = 'onex-creation',
        handler = function(ped, skin)
            exports["onex-creation"]:loadPlayerSkin(ped, skin)
        end
    },
    {
        name = 'qb-clothing',
        handler = function(ped, skin)
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
        end
    },
    {
        name = 'bl_appearance',
        handler = function(ped, skin)
            exports['bl_appearance']:SetPedAppearance(ped, skin)
        end
    },
    {
        name = 'rcore_clothing',
        handler = function(ped, skin)
            exports['rcore_clothing']:setPedSkin(ped, skin)
        end
    },
    {
        name = 'origen_clothing',
        handler = function(ped, skin)
            exports['origen_clothing']:SetAppearance(ped, skin)
        end
    },
    {
        name = 'tgiann-clothing',
        handler = function(ped, skin)
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
        end
    },
    {
        name = 'skinchanger',
        handler = function(ped, skin)
            TriggerEvent('skinchanger:loadSkin', skin, function() end)
        end
    },
    {
        name = 'esx_skin',
        handler = function(ped, skin)
            if type(ESX_ApplySkin) == "function" then
                ESX_ApplySkin(ped, skin)
            end
        end
    },
    {
        name = 'raid_clothes',
        handler = function(ped, skin)
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
        end
    },

    {
        name = '0r-clothing',
        handler = function(ped, skin)
            TriggerEvent('0r-clothing:client:loadPlayerClothing', skin, ped)
        end
    },
    {
        name = 'crm-appearance',
        handler = function(ped, data)
            exports['crm-appearance']:crm_set_ped_appearance(ped, data)
        end
    },

    {
        name = 'p_appearance',
        handler = function(ped, data)
            TriggerEvent('qb-clothing:client:loadPlayerClothing', data, ped)
        end
    },
}

local createMenuHandlers = {
    {
        name = 'bl_appearance',
        handler = function() exports['bl_appearance']:InitialCreation() end,
    },
    {
        name = 'bs-appearance',
        handler = function()
            local config = exports['bs-appearance']:getNewCharacterConfig()
            exports['bs-appearance']:startPlayerCustomization(function(appearance)
                if appearance then
                    TriggerServerEvent('bs-appearance:server:saveAppearance', appearance)
                end
                TriggerServerEvent('bs-appearance:server:ResetRoutingBucket')
            end, config)
        end,
    },
    {
        name = 'rcore_clothing',
        handler = function()
            TriggerEvent('rcore_clothing:openCharCreator')
            if Core.Framework == 'qb' then
                TriggerEvent('rcore_clothing:qb:charcreator')
            elseif Core.Framework == 'esx' then
                TriggerEvent('rcore_clothing:esx:charcreator')
            end
        end,
    },
    {
        name = 'origen_clothing',
        handler = function() exports['origen_clothing']:startPedCreation(true) end,
    },
    
    {
        name = 'qb-clothing',
        handler = function()
            if Core.Framework == 'qb' then
                TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            else
                TriggerEvent('esx_skin:openSaveableMenu')
            end
        end,
    },
    {
        name = 'tgiann-clothing',
        handler = function()
            if Core.Framework == 'qb' then
                TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            else
                TriggerEvent('tgiann-clothing:esx:createNew')
            end
        end,
    },
    {
        name = 'illenium-appearance',
        handler = function()
            if Core.Framework == 'qb' then
                TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            else
                TriggerEvent('esx_skin:openSaveableMenu')
            end
        end,
    },
    {
        name = 'fivem-appearance',
        handler = function()
            if Core.Framework == 'qb' then
                TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            else
                TriggerEvent('esx_skin:openSaveableMenu')
            end
        end,
    },
    {
        name = 'onex-creation',
        handler = function()
            if Core.Framework == 'qb' then
                TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            else
                TriggerEvent('esx_skin:openSaveableMenu')
            end
        end,
    },
    {
        name = 'crm-appearance',
        handler = function(charData)
            
            TriggerEvent('crm-appearance:init-new-character', 'crm-male', function() 
                
            end) 
        end,
    },

    {
        name = 'p_appearance',
        handler = function(charData)
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        end,
    },
}

function ClothingBridge.OpenCreateMenu(charData)
    local cfg = Config.Clothing or "Auto"

    if cfg ~= "Auto" and cfg ~= "default" and cfg ~= "custom" then
        for _, tbl in ipairs(createMenuHandlers) do
            if tbl.name == cfg then
                tbl.handler(charData)
                return
            end
        end
        
    else
        for _, tbl in ipairs(createMenuHandlers) do
            if GetResourceState(tbl.name) == "started" or GetResourceState(tbl.name) == "starting" then
                tbl.handler(charData)
                return
            end
        end
    end

end

function ClothingBridge.ApplyAppearance(ped, appearance)
    if not appearance then return end
    
    local skin = appearance.skin or appearance
    local cfg = Config.Clothing or "Auto"

    if cfg ~= "Auto" and cfg ~= "default" and cfg ~= "custom" then
        for _, tbl in ipairs(clothingHandlers) do
            if tbl.name == cfg then
                tbl.handler(ped, skin)
                return
            end
        end
    end

    for _, tbl in ipairs(clothingHandlers) do
        if GetResourceState(tbl.name) == "started" or GetResourceState(tbl.name) == "starting" then
            tbl.handler(ped, skin)
            return
        end
    end

    if cfg == 'custom' then
        
    else
        if Config.Core == "qb" or Config.Framework == "qb" or QBCore then
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
        elseif Config.Core == "esx" or Config.Framework == "esx" or ESX then
            if type(ESX_ApplySkin) == "function" then ESX_ApplySkin(ped, skin) end
        end
    end
end

