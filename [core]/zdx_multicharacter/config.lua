

Config = {}

Config.Debug = true

Config.Framework     = "Auto"   

Config.Clothing      = "illenium-appearance"   
Config.DefaultLang   = "tr"
Config.Keybinds = {
    changePose     = { key = 38,  name = "E" },  
    changeLocation = { key = 74,  name = "J" },  
    hideUI         = { key = nil, name = "H" },  
    cinematicBar   = { key = nil, name = "B" },  
}

Config.LogoutCommand = "logout"  

Config.DefaultTheme     = "dark"  
Config.DefaultMenuStyle = 2       

Config.SpawnSelector = false

Config.LastLocation  = true

Config.SpawnWithApartment  = "Auto"
Config.ApartmentOnlyForNew = false  

Config.FirstSpawnLocation =  vector3(-1037.93, -2738.13, 20.17)

Config.EmergencySpawnLocation = vector3(-1728.43, -1123.35, 13.03) 

Config.SpawnLocations = {
    
}

Config.CinematicRoom = {
    pedCoords = vector4(402.8664, -996.4108, -99.00027, -90.0),
    camCoords = vector3(402.8664, -999.0, -98.5),
    camPointAt = vector3(402.8664, -996.4108, -98.5),
    fov = 50.0,
    weather = "EXTRASUNNY",
    time = { hour = 12, minute = 0 }
}

Config.Environment = {

    DisableThirdPartySync = function()
        print(123, "Disabling third-party weather/time syncs")
        TriggerEvent('qb-weathersync:client:DisableSync')
        TriggerEvent('vSync:requestSync')
    end,

    EnableThirdPartySync = function()
        print(123, "Re-enabling third-party weather/time syncs")
        TriggerEvent('qb-weathersync:client:EnableSync')
    end,
}

Config.EmptyScreenCamera = {
    camPos    = vector3(-2089.43, -1187.83, 41.9),  
    camPointAt = vector3(-1620.14, -1071.96, 0.0),  
    fov       = 50.0,

    dof = {
        enabled   = false,
        nearStart = 1.0,
        nearEnd   = 5.0,
        farStart  = 10.0,
        farEnd    = 30.0,
        strength  = 0.3,
    },
}

Config.Preview = {
    fov            = 48.0,
    camOffset      = vector3(0.65, 1.85, 0.55),
    camPointAt     = vector3(0.0, 0.0, 0.35),
    interpDuration = 800,

    dof = {
        enabled   = true,
        nearStart = 0.2,
        nearEnd   = 5.0,
        farStart  = 3.5,
        farEnd    = 4.0,
        strength  = 1.0,
    },
}

Config.StarterItems = {
    { item = "water",    count = 5  },
    { item = "bread",    count = 5  },
    { item = "phone",    count = 1  },
}

Config.Credits = {
    { role = "Developer", name = "ZiDFPS" },
    { role = "Owner",     name = "ZDX Scripts" },
}

Locales = {}

