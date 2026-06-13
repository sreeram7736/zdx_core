RegisterNetEvent('nexus-multicharacter:server:saveScreenshot', function(slot)
    if not Config.Screenshots.enabled then return end
    
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then return end
    
    -- Check if screenshot-basic exists
    if GetResourceState('screenshot-basic') ~= 'started' then
        print('^3[WARNING] screenshot-basic is not started, skipping screenshot^0')
        return
    end
    
    local success, error = pcall(function()
        exports['screenshot-basic']:requestClientScreenshot(src, {
            encoding = 'jpg',
            quality = 0.8
        }, function(err, data)
            if err then
                print('[nexus-multicharacter] Screenshot error:', err)
                return
            end
            
            if Config.Screenshots.uploadMethod == 'discord' and Config.Screenshots.webhook then
                UploadToDiscord(data, function(url)
                    if url then
                        SaveScreenshot(license, slot, url)
                    end
                end)
            else
                -- Save data URL directly (not recommended for production)
                SaveScreenshot(license, slot, data)
            end
        end)
    end)
    
    if not success then
        print('^1[ERROR] Failed to request screenshot: ' .. tostring(error) .. '^0')
    end
end)

function UploadToDiscord(imageData, cb)
    local webhook = Config.Screenshots.webhook
    if not webhook or webhook == 'YOUR_WEBHOOK_URL' then
        cb(nil)
        return
    end
    
    PerformHttpRequest(webhook, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(function()
                return json.decode(response)
            end)
            
            if success and data and data.attachments and data.attachments[1] then
                cb(data.attachments[1].url)
            else
                cb(nil)
            end
        else
            print('[nexus-multicharacter] Discord webhook failed with status: ' .. statusCode)
            cb(nil)
        end
    end, 'POST', json.encode({
        embeds = {{
            title = 'Character Screenshot',
            image = {url = imageData},
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
        }}
    }), {['Content-Type'] = 'application/json'})
end