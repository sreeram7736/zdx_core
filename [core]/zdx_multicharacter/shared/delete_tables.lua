

Config.DeleteTables = {
    qb = {
        { table = "zdx_playtime",       column = "char_id"   },
        { table = "player_skins",       column = "citizenid" },
        { table = "player_outfits",     column = "citizenid" },
        { table = "player_vehicles",    column = "citizenid" },
        { table = "player_houses",      column = "citizenid" },
        { table = "player_contacts",    column = "citizenid" },
        { table = "player_mails",       column = "citizenid" },
        { table = "apartments",         column = "citizenid" },
        { table = "bank_accounts",      column = "citizenid" },
        { table = "crypto_transactions",column = "citizenid" },
        { table = "gloveboxitems",      column = "citizenid" },
        { table = "stashitems",         column = "citizenid" },
        { table = "trunkitems",         column = "citizenid" },
        { table = "phone_messages",     column = "citizenid" },
        { table = "phone_contacts",     column = "citizenid" },
        { table = "phone_invoices",     column = "citizenid" },
        { table = "properties",         column = "citizenid" },
    },
    esx = {
        
        { table = "users",                column = "identifier" },
        { table = "zdx_playtime",       column = "char_id" },
        { table = "user_licenses",        column = "owner" },
        { table = "owned_vehicles",       column = "owner" },
        { table = "owned_properties",     column = "owner" },
        { table = "rented_vehicles",      column = "owner" },
        { table = "addon_account_data",   column = "owner" },
        { table = "addon_inventory_items",column = "owner" },
        { table = "datastore_data",       column = "owner" },
        { table = "billing",              column = "identifier" },
        { table = "society_moneywash",    column = "identifier" },
        { table = "properties",           column = "owner" },
    },
}

