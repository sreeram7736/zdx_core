-- zdx_chat server main

RegisterCommand('director', function(source, args)
    local msg = table.concat(args, " ")
    if msg ~= "" then
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(200, 50, 50, 0.8); border-radius: 3px;"><i class="fas fa-bullhorn"></i> <b>DIRECTOR:</b> {0}</div>',
            args = { msg }
        })
    end
end, false)

RegisterCommand('action', function(source, args)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.8vw; margin: 0.5vw; background-color: rgba(255, 165, 0, 0.9); border-radius: 5px; font-size: 1.5vw; text-align: center; text-transform: uppercase; font-weight: bold;"><i class="fas fa-video"></i> AND... ACTION!</div>',
        args = {}
    })
end, false)

RegisterCommand('cut', function(source, args)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.8vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.9); color: white; border-radius: 5px; font-size: 1.5vw; text-align: center; text-transform: uppercase; font-weight: bold;"><i class="fas fa-cut"></i> CUT!</div>',
        args = {}
    })
end, false)

RegisterCommand('crew', function(source, args)
    local msg = table.concat(args, " ")
    if msg ~= "" then
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(50, 50, 200, 0.8); border-radius: 3px;"><i class="fas fa-headset"></i> <b>CREW:</b> {0}</div>',
            args = { msg }
        })
    end
end, false)
