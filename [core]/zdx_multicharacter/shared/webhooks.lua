
Webhooks = Webhooks or {}

Config.Webhooks = Config.Webhooks or {
    create = "",
    delete = "",
    login = "",
    partner = "",
}

function Webhooks.Send(webhookType, title, description, color)
    local url = Config.Webhooks and Config.Webhooks[webhookType]
    if not url or url == "" then
        return
    end

    local payload = json.encode({
        username = "ZDX Multichar",
        embeds = {
            {
                title = title or "ZDX Multichar",
                description = description or "",
                color = color or 3447003,
                footer = { text = os.date("%Y-%m-%d %H:%M:%S") },
            }
        }
    })

    PerformHttpRequest(url, function() end, "POST", payload, { ["Content-Type"] = "application/json" })
end

