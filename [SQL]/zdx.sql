-- ============================================================
--  ZDX CINEMATIC FRAMEWORK — Database Schema
--  Made by ZDX Scripts
--  Stack: inventory · illenium-appearance · pma-voice
--         vehicle spawn · gun spawn · dresspacks
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  ESX COMPATIBILITY TABLES (required by ox_inventory)
-- ============================================================

CREATE TABLE IF NOT EXISTS `users` (
  `identifier` VARCHAR(60) NOT NULL,
  `accounts`   LONGTEXT    DEFAULT NULL,
  `group`      VARCHAR(50) NOT NULL DEFAULT 'user',
  `inventory`  LONGTEXT    DEFAULT NULL,
  `job`        VARCHAR(50) NOT NULL DEFAULT 'unemployed',
  `job_grade`  INT(11)     NOT NULL DEFAULT 0,
  `loadout`    LONGTEXT    DEFAULT NULL,
  `position`   LONGTEXT    DEFAULT NULL,
  `firstname`  VARCHAR(50) DEFAULT NULL,
  `lastname`   VARCHAR(50) DEFAULT NULL,
  `dateofbirth` VARCHAR(25) DEFAULT NULL,
  `sex`        VARCHAR(10) DEFAULT NULL,
  `skin`       LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='ESX-compatible users table for ox_inventory bridge';

CREATE TABLE IF NOT EXISTS `licenses` (
  `type`  VARCHAR(60) NOT NULL,
  `label` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='License types for ox_inventory';

INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES
('weapon', 'Weapon License'),
('dmv',    'Driving License');


-- ============================================================
--  CORE PLAYERS
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_players` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(60)  NOT NULL,
  `license`      VARCHAR(255) NOT NULL,
  `name`         VARCHAR(255) NOT NULL,
  `firstname`    VARCHAR(50)  DEFAULT NULL,
  `lastname`     VARCHAR(50)  DEFAULT NULL,
  `phone_number` VARCHAR(20)  DEFAULT NULL,
  `group`        VARCHAR(50)  NOT NULL DEFAULT 'user' COMMENT 'user | creator | admin | superadmin',
  `position`     LONGTEXT     DEFAULT NULL COMMENT 'JSON {x,y,z,heading}',
  `metadata`     LONGTEXT     DEFAULT NULL COMMENT 'JSON misc flags',
  `skin`         LONGTEXT     DEFAULT NULL COMMENT 'illenium-appearance JSON',
  `disabled`     TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen`    TIMESTAMP    NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`),
  KEY `id` (`id`),
  KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='ZDX core player records';

-- ============================================================
--  MULTICHARACTER SLOTS
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_character_slots` (
  `identifier` VARCHAR(60) NOT NULL,
  `slots`      INT(11)     NOT NULL DEFAULT 3,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Controls how many character slots a player has unlocked';

-- ============================================================
--  BANS
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_bans` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(100) DEFAULT NULL,
  `license`   VARCHAR(60)  DEFAULT NULL,
  `discord`   VARCHAR(60)  DEFAULT NULL,
  `ip`        VARCHAR(50)  DEFAULT NULL,
  `reason`    TEXT         DEFAULT NULL,
  `expire`    INT(11)      DEFAULT NULL COMMENT 'Unix timestamp; NULL = permanent',
  `banned_by` VARCHAR(255) NOT NULL DEFAULT 'ZDX-System',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip`      (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  WHITELIST
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_whitelist` (
  `identifier` VARCHAR(60) NOT NULL,
  `added_by`   VARCHAR(100) DEFAULT 'ZDX System',
  `added_at`   TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  INVENTORY  (ox_inventory / ESX compatible)
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_items` (
  `name`        VARCHAR(100) NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `weight`      INT(11)      NOT NULL DEFAULT 1,
  `stack`       TINYINT(1)   NOT NULL DEFAULT 1,
  `rare`        TINYINT(1)   NOT NULL DEFAULT 0,
  `can_remove`  TINYINT(1)   NOT NULL DEFAULT 1,
  `description` TEXT         DEFAULT NULL,
  `image`       VARCHAR(255) DEFAULT NULL COMMENT 'relative path to item image',
  `metadata`    LONGTEXT     DEFAULT NULL COMMENT 'JSON default metadata',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Master item registry for ZDX inventory';

INSERT INTO `zdx_items` (`name`, `label`, `weight`, `stack`, `rare`, `can_remove`, `description`) VALUES
('phone',         'Phone',          1, 0, 0, 0, 'Personal phone'),
('radio',         'Radio',          1, 0, 0, 1, 'Push-to-talk radio — pma-voice'),
('camera',        'Cinematic Camera',2,0, 0, 1, 'High-end cinema camera for shoots'),
('clapperboard',  'Clapperboard',   1, 0, 0, 1, 'Scene marker board'),
('drone',         'Drone',          3, 0, 1, 1, 'Aerial cinematic drone'),
('tripod',        'Tripod',         3, 0, 0, 1, 'Camera stabiliser tripod'),
('lens_wide',     'Wide Lens',      1, 0, 1, 1, 'Wide-angle lens attachment'),
('lens_tele',     'Telephoto Lens', 1, 0, 1, 1, 'Telephoto lens attachment'),
('id_card',       'ID Card',        1, 0, 1, 0, 'Player identification card'),
('prop_flare',    'Flare',          1, 1, 0, 1, 'Scene lighting flare'),
('smoke_red',     'Red Smoke',      1, 1, 0, 1, 'Red smoke grenade for effects'),
('smoke_blue',    'Blue Smoke',     1, 1, 0, 1, 'Blue smoke grenade for effects'),
('smoke_white',   'White Smoke',    1, 1, 0, 1, 'White smoke grenade for effects'),
('megaphone',     'Megaphone',      2, 0, 0, 1, 'Director megaphone')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- ============================================================
--  GUN SPAWN — Weapon Registry
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_weapons` (
  `name`        VARCHAR(100) NOT NULL COMMENT 'GTA weapon hash name e.g. WEAPON_PISTOL',
  `label`       VARCHAR(100) NOT NULL,
  `category`    VARCHAR(60)  NOT NULL DEFAULT 'handguns',
  `ammo_type`   VARCHAR(50)  DEFAULT NULL,
  `legal`       TINYINT(1)   NOT NULL DEFAULT 0,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `damage`      INT(11)      NOT NULL DEFAULT 50,
  `description` TEXT         DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='ZDX registered weapons for gun spawn system';

INSERT INTO `zdx_weapons` (`name`, `label`, `category`, `ammo_type`, `legal`, `price`, `damage`) VALUES
-- Handguns
('WEAPON_PISTOL',         'Pistol',           'handguns', 'AMMO_PISTOL',  1,  2500, 30),
('WEAPON_PISTOL50',       'Pistol .50',        'handguns', 'AMMO_PISTOL',  1,  5000, 45),
('WEAPON_COMBATPISTOL',   'Combat Pistol',     'handguns', 'AMMO_PISTOL',  1,  3500, 35),
('WEAPON_REVOLVER',       'Revolver',          'handguns', 'AMMO_PISTOL',  1,  4500, 60),
('WEAPON_APPISTOL',       'AP Pistol',         'handguns', 'AMMO_PISTOL',  0,  6500, 40),
('WEAPON_DOUBLEACTION',   'Double Action',     'handguns', 'AMMO_PISTOL',  1,  7500, 55),
('WEAPON_STUNGUN',        'Stun Gun',          'handguns',  NULL,          1,  1500, 10),
-- Shotguns
('WEAPON_PUMPSHOTGUN',    'Pump Shotgun',      'shotguns', 'AMMO_SHOTGUN', 1,  5000, 70),
('WEAPON_SAWNOFFSHOTGUN', 'Sawn-Off Shotgun',  'shotguns', 'AMMO_SHOTGUN', 0,  4000, 75),
('WEAPON_HEAVYSHOTGUN',   'Heavy Shotgun',     'shotguns', 'AMMO_SHOTGUN', 0,  8000, 85),
('WEAPON_DBSHOTGUN',      'Double Barrel',     'shotguns', 'AMMO_SHOTGUN', 1,  4500, 80),
-- SMGs
('WEAPON_MICROSMG',       'Micro SMG',         'smgs',     'AMMO_SMG',     0,  6000, 28),
('WEAPON_SMG',            'SMG',               'smgs',     'AMMO_SMG',     0,  7000, 32),
('WEAPON_COMBATPDW',      'Combat PDW',        'smgs',     'AMMO_SMG',     0,  9000, 35),
('WEAPON_MACHINEPISTOL',  'Machine Pistol',    'smgs',     'AMMO_SMG',     0,  5500, 30),
-- Assault Rifles
('WEAPON_ASSAULTRIFLE',   'Assault Rifle',     'rifles',   'AMMO_RIFLE',   0, 15000, 50),
('WEAPON_CARBINERIFLE',   'Carbine Rifle',     'rifles',   'AMMO_RIFLE',   0, 18000, 55),
('WEAPON_ADVANCEDRIFLE',  'Advanced Rifle',    'rifles',   'AMMO_RIFLE',   0, 22000, 58),
('WEAPON_SPECIALCARBINE', 'Special Carbine',   'rifles',   'AMMO_RIFLE',   0, 20000, 56),
('WEAPON_BULLPUPRIFLE',   'Bullpup Rifle',     'rifles',   'AMMO_RIFLE',   0, 19000, 54),
('WEAPON_MILITARYRIFLE',  'Military Rifle',    'rifles',   'AMMO_RIFLE',   0, 25000, 62),
-- Snipers
('WEAPON_SNIPERRIFLE',    'Sniper Rifle',      'snipers',  'AMMO_SNIPER',  1, 30000,100),
('WEAPON_HEAVYSNIPER',    'Heavy Sniper',      'snipers',  'AMMO_SNIPER',  0, 45000,120),
('WEAPON_MARKSMANRIFLE',  'Marksman Rifle',    'snipers',  'AMMO_SNIPER',  1, 25000, 90),
-- LMGs
('WEAPON_MG',             'MG',                'lmgs',     'AMMO_MG',      0, 20000, 55),
('WEAPON_COMBATMG',       'Combat MG',         'lmgs',     'AMMO_MG',      0, 28000, 60),
-- Melee
('WEAPON_KNIFE',          'Knife',             'melee',     NULL,          1,   500, 40),
('WEAPON_NIGHTSTICK',     'Nightstick',        'melee',     NULL,          1,   300, 25),
('WEAPON_CROWBAR',        'Crowbar',           'melee',     NULL,          1,   200, 30),
('WEAPON_BAT',            'Baseball Bat',      'melee',     NULL,          1,   150, 28),
('WEAPON_MACHETE',        'Machete',           'melee',     NULL,          0,   800, 55),
('WEAPON_FLASHLIGHT',     'Flashlight',        'melee',     NULL,          1,   100,  5)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- --------------------------------------------------------
--  Ammo Types

CREATE TABLE IF NOT EXISTS `zdx_ammo` (
  `name`     VARCHAR(60) NOT NULL,
  `label`    VARCHAR(60) NOT NULL,
  `price`    INT(11)     NOT NULL DEFAULT 50,
  `quantity` INT(11)     NOT NULL DEFAULT 50 COMMENT 'units per purchase',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `zdx_ammo` (`name`, `label`, `price`, `quantity`) VALUES
('AMMO_PISTOL',  'Pistol Rounds',   50,  50),
('AMMO_SHOTGUN', 'Shotgun Shells',  80,  20),
('AMMO_SMG',     'SMG Rounds',      60,  60),
('AMMO_RIFLE',   'Rifle Rounds',   100,  60),
('AMMO_SNIPER',  'Sniper Rounds',  150,  10),
('AMMO_MG',      'MG Rounds',      120, 100)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- --------------------------------------------------------
--  Player Weapon Persistence

CREATE TABLE IF NOT EXISTS `zdx_player_weapons` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(60)  NOT NULL,
  `weapon`      VARCHAR(100) NOT NULL,
  `ammo`        INT(11)      NOT NULL DEFAULT 0,
  `components`  LONGTEXT     DEFAULT NULL COMMENT 'JSON array of attachments',
  `tint`        INT(11)      NOT NULL DEFAULT 0,
  `spawned_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Persists player-owned/spawned weapons';

-- ============================================================
--  VEHICLE SPAWN
-- ============================================================

CREATE TABLE IF NOT EXISTS `vehicle_categories` (
  `name`  VARCHAR(60) NOT NULL,
  `label` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `vehicle_categories` (`name`, `label`) VALUES
('compacts',       'Compacts'),
('coupes',         'Coupés'),
('motorcycles',    'Motorcycles'),
('muscle',         'Muscle'),
('offroad',        'Off Road'),
('sedans',         'Sedans'),
('sports',         'Sports'),
('sportsclassics', 'Sports Classics'),
('super',          'Super'),
('suvs',           'SUVs'),
('vans',           'Vans'),
('emergency',      'Emergency'),
('commercial',     'Commercial'),
('military',       'Military'),
('cinematic',      'Cinematic Props')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `vehicles` (
  `name`     VARCHAR(100) NOT NULL,
  `model`    VARCHAR(60)  NOT NULL,
  `price`    INT(11)      NOT NULL DEFAULT 0,
  `category` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`model`),
  KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Master vehicle list for ZDX vehicle spawn';

INSERT INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES
-- Super
('Adder',           'adder',        900000,  'super'),
('Zentorno',        'zentorno',    1500000,  'super'),
('Entity XF',       'entityxf',     425000,  'super'),
('T20',             't20',          300000,  'super'),
('Osiris',          'osiris',       160000,  'super'),
('Bullet',          'bullet',        90000,  'super'),
-- Sports
('Carbonizzare',    'carbonizzare',  75000,  'sports'),
('Comet',           'comet2',        65000,  'sports'),
('Jester',          'jester',        65000,  'sports'),
('Elegy',           'elegy2',        38500,  'sports'),
('Banshee',         'banshee',       70000,  'sports'),
('Rapid GT',        'rapidgt',       35000,  'sports'),
('Sultan',          'sultan',        15000,  'sports'),
('Buffalo S',       'buffalo2',      20000,  'sports'),
-- Sports Classics
('Stinger GT',      'stingergt',     75000,  'sportsclassics'),
('Monroe',          'monroe',        55000,  'sportsclassics'),
('GT 500',          'gt500',        785000,  'sportsclassics'),
-- Motorcycles
('Bati 801',        'bati',          12000,  'motorcycles'),
('PCJ-600',         'pcj',            6200,  'motorcycles'),
('Hakuchou',        'hakuchou',      31000,  'motorcycles'),
('Bagger',          'bagger',        13500,  'motorcycles'),
('Sanchez',         'sanchez',        5300,  'motorcycles'),
-- Muscle
('Gauntlet',        'gauntlet',      30000,  'muscle'),
('Dominator',       'dominator',     35000,  'muscle'),
('Vigero',          'vigero',        12500,  'muscle'),
('Sabre Turbo',     'sabregt',       20000,  'muscle'),
-- SUVs
('Dubsta',          'dubsta',        45000,  'suvs'),
('Baller',          'baller2',       40000,  'suvs'),
('Patriot',         'patriot',       55000,  'suvs'),
('Landstalker',     'landstalker',   35000,  'suvs'),
-- Sedans
('Washington',      'washington',     9000,  'sedans'),
('Premier',         'premier',        8000,  'sedans'),
('Stretch',         'stretch',       90000,  'sedans'),
('Super Diamond',   'superd',       130000,  'sedans'),
-- Vans
('Rumpo',           'rumpo',         15000,  'vans'),
('Bison',           'bison',         45000,  'vans'),
('Journey',         'journey',        6500,  'vans'),
-- Offroad
('Blazer',          'blazer',         6500,  'offroad'),
('Sandking',        'sandking',      55000,  'offroad'),
('Brawler',         'brawler',       45000,  'offroad'),
-- Compacts
('Blista',          'blista',         8000,  'compacts'),
('Panto',           'panto',         10000,  'compacts'),
-- Coupés
('Felon',           'felon',         42000,  'coupes'),
('Windsor',         'windsor',       95000,  'coupes'),
('Exemplar',        'exemplar',      32000,  'coupes'),
-- Emergency (job/spawn, no price)
('Police Cruiser',  'police',             0, 'emergency'),
('Police Cruiser 2','police2',            0, 'emergency'),
('Police Buffalo',  'policeb',            0, 'emergency'),
('Ambulance',       'ambulance',          0, 'emergency'),
('Fire Truck',      'firetruk',           0, 'emergency'),
-- Commercial
('Taxi',            'taxi',               0, 'commercial'),
('Tow Truck',       'towtruck',           0, 'commercial'),
-- Military
('Insurgent',       'insurgent',     60000, 'military'),
('Barracks',        'barracks',          0, 'military')
ON DUPLICATE KEY UPDATE `price` = VALUES(`price`);

-- --------------------------------------------------------
--  Owned Vehicles

CREATE TABLE IF NOT EXISTS `owned_vehicles` (
  `owner`   VARCHAR(60)  DEFAULT NULL,
  `plate`   VARCHAR(12)  NOT NULL,
  `vehicle` LONGTEXT     DEFAULT NULL COMMENT 'JSON vehicle mods/data',
  `type`    VARCHAR(20)  NOT NULL DEFAULT 'car',
  `stored`  TINYINT(4)   NOT NULL DEFAULT 1,
  `parking` VARCHAR(100) DEFAULT NULL,
  `pound`   VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`plate`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  illenium-appearance — SKIN PERSISTENCE
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_appearance` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60) NOT NULL,
  `skin`       LONGTEXT    NOT NULL COMMENT 'Full illenium-appearance JSON payload',
  `tattoos`    LONGTEXT    DEFAULT NULL COMMENT 'JSON tattoo array',
  `last_saved` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Persists illenium-appearance character skin data per player';

-- ============================================================
--  DRESSPACKS — Cinematic Outfit Presets
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_dresspacks` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `pack_name`   VARCHAR(100) NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `description` TEXT         DEFAULT NULL,
  `category`    VARCHAR(60)  NOT NULL DEFAULT 'cinematic' COMMENT 'cinematic | civilian | police | ems | mechanic | stunt',
  `sex`         TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '0=male 1=female 2=both',
  `skin_data`   LONGTEXT     NOT NULL COMMENT 'illenium-appearance clothing JSON block',
  `created_by`  VARCHAR(100) NOT NULL DEFAULT 'ZDX Scripts',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pack_sex` (`pack_name`, `sex`),
  KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Cinematic outfit presets for ZDX Cinematic Framework';

INSERT INTO `zdx_dresspacks` (`pack_name`, `label`, `description`, `category`, `sex`, `skin_data`, `created_by`) VALUES
('director_male',      'Director',            'On-set director outfit',          'cinematic', 0, '{}', 'ZDX Scripts'),
('director_female',    'Director (F)',         'On-set director outfit',          'cinematic', 1, '{}', 'ZDX Scripts'),
('stunt_male',         'Stunt Performer',      'Stunt rig ready outfit',          'stunt',     0, '{}', 'ZDX Scripts'),
('stunt_female',       'Stunt Performer (F)',  'Stunt rig ready outfit',          'stunt',     1, '{}', 'ZDX Scripts'),
('camera_crew_male',   'Camera Crew',          'Camera operator outfit',          'cinematic', 0, '{}', 'ZDX Scripts'),
('camera_crew_female', 'Camera Crew (F)',       'Camera operator outfit',          'cinematic', 1, '{}', 'ZDX Scripts'),
('police_male',        'LSPD Patrol',          'Police patrol uniform',           'police',    0, '{}', 'ZDX Scripts'),
('police_female',      'LSPD Patrol (F)',       'Police patrol uniform',           'police',    1, '{}', 'ZDX Scripts'),
('ems_male',           'EMS Field',            'EMS field medic outfit',          'ems',       0, '{}', 'ZDX Scripts'),
('ems_female',         'EMS Field (F)',         'EMS field medic outfit',          'ems',       1, '{}', 'ZDX Scripts'),
('mechanic_male',      'Mechanic',             'Workshop mechanic overalls',      'mechanic',  0, '{}', 'ZDX Scripts'),
('mechanic_female',    'Mechanic (F)',          'Workshop mechanic overalls',      'mechanic',  1, '{}', 'ZDX Scripts'),
('civ_casual_male',    'Casual Civilian',       'Everyday civilian clothing',      'civilian',  0, '{}', 'ZDX Scripts'),
('civ_casual_female',  'Casual Civilian (F)',   'Everyday civilian clothing',      'civilian',  1, '{}', 'ZDX Scripts'),
('civ_formal_male',    'Formal Civilian',       'Suit and tie civilian',           'civilian',  0, '{}', 'ZDX Scripts'),
('civ_formal_female',  'Formal Civilian (F)',   'Elegant formal civilian',         'civilian',  1, '{}', 'ZDX Scripts');

-- --------------------------------------------------------
--  Dresspack Apply Log

CREATE TABLE IF NOT EXISTS `zdx_dresspack_log` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60)  NOT NULL,
  `pack_name`  VARCHAR(100) NOT NULL,
  `applied_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  pma-voice — VOICE SETTINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_voice_settings` (
  `identifier`    VARCHAR(60) NOT NULL,
  `voice_range`   FLOAT       NOT NULL DEFAULT 3.0 COMMENT '1.0=whisper / 3.0=normal / 15.0=shout',
  `radio_channel` INT(11)     DEFAULT NULL,
  `phone_active`  TINYINT(1)  NOT NULL DEFAULT 0,
  `muted`         TINYINT(1)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='pma-voice per-player settings';

-- ============================================================
--  CINEMATIC SCENES — ZDX Scene Presets
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_scenes` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `scene_name`  VARCHAR(100) NOT NULL,
  `label`       VARCHAR(255) DEFAULT NULL,
  `creator`     VARCHAR(60)  DEFAULT NULL COMMENT 'player identifier',
  `camera_data` LONGTEXT     NOT NULL COMMENT 'JSON: {pos, rot, fov, dof, shake}',
  `weather`     VARCHAR(50)  DEFAULT NULL,
  `time_hour`   TINYINT      DEFAULT NULL,
  `props`       LONGTEXT     DEFAULT NULL COMMENT 'JSON array of spawned props',
  `npcs`        LONGTEXT     DEFAULT NULL COMMENT 'JSON array of NPC definitions with outfits',
  `notes`       TEXT         DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `scene_name` (`scene_name`),
  KEY `creator` (`creator`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Saved cinematic scene configurations';

-- ============================================================
--  ADMIN / CREATOR GROUPS
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_groups` (
  `identifier`  VARCHAR(60)  NOT NULL,
  `group`       VARCHAR(50)  NOT NULL DEFAULT 'user' COMMENT 'user | creator | admin | superadmin',
  `assigned_by` VARCHAR(100) DEFAULT 'ZDX System',
  `assigned_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  AUDIT LOG
-- ============================================================

CREATE TABLE IF NOT EXISTS `zdx_logs` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60)  DEFAULT NULL,
  `action`     VARCHAR(100) NOT NULL,
  `details`    TEXT         DEFAULT NULL,
  `logged_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `action`     (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Audit log for all ZDX framework actions';

-- ============================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  END — ZDX CINEMATIC FRAMEWORK SQL
--  ZDX Scripts © 2024 — All rights reserved
-- ============================================================