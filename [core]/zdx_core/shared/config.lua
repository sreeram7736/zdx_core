Config = {}

-- ══════════════════════════════════════════════════════════════
-- SPAWN SETTINGS
-- ══════════════════════════════════════════════════════════════
Config.DefaultSpawn = vector4(-269.4, -955.3, 31.2, 205.8)
Config.DefaultModel = 'mp_m_freemode_01'

-- ══════════════════════════════════════════════════════════════
-- MONEY SETTINGS
-- ══════════════════════════════════════════════════════════════
Config.StartingAccounts = {
    money = 500,        -- Cash on hand
    bank = 5000,        -- Bank account
    black_money = 0,    -- Dirty money (ESX compat)
}

-- ══════════════════════════════════════════════════════════════
-- JOB SETTINGS
-- ══════════════════════════════════════════════════════════════
Config.DefaultJob = 'unemployed'
Config.DefaultJobGrade = 0

Config.Jobs = {
    ['unemployed'] = {
        label = 'Unemployed',
        type = 'none',
        defaultDuty = true,
        grades = {
            [0] = { name = 'Freelancer', label = 'Freelancer', payment = 10, isboss = false },
        }
    },
    ['police'] = {
        label = 'Law Enforcement',
        type = 'leo',
        defaultDuty = true,
        grades = {
            [0] = { name = 'recruit', label = 'Recruit', payment = 50, isboss = false },
            [1] = { name = 'officer', label = 'Officer', payment = 75, isboss = false },
            [2] = { name = 'sergeant', label = 'Sergeant', payment = 100, isboss = false },
            [3] = { name = 'chief', label = 'Chief', payment = 150, isboss = true },
        }
    },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = true,
        grades = {
            [0] = { name = 'recruit', label = 'Recruit', payment = 50, isboss = false },
            [1] = { name = 'paramedic', label = 'Paramedic', payment = 75, isboss = false },
            [2] = { name = 'doctor', label = 'Doctor', payment = 100, isboss = false },
            [3] = { name = 'chief', label = 'Chief of Medicine', payment = 150, isboss = true },
        }
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = true,
        grades = {
            [0] = { name = 'recruit', label = 'Recruit', payment = 40, isboss = false },
            [1] = { name = 'mechanic', label = 'Mechanic', payment = 60, isboss = false },
            [2] = { name = 'boss', label = 'Boss', payment = 90, isboss = true },
        }
    },
}

-- ══════════════════════════════════════════════════════════════
-- GANG SETTINGS (QB Compat)
-- ══════════════════════════════════════════════════════════════
Config.DefaultGang = 'none'
Config.DefaultGangGrade = 0

Config.Gangs = {
    ['none'] = {
        label = 'No Gang',
        grades = {
            [0] = { name = 'unaffiliated', label = 'Unaffiliated', isboss = false },
        }
    },
}

-- ══════════════════════════════════════════════════════════════
-- SERVER SETTINGS
-- ══════════════════════════════════════════════════════════════
Config.ServerName = 'ZDX Server'
Config.MaxCharacters = 1 -- Set to 1 for cinematic (no multichar)
Config.PVP = true
