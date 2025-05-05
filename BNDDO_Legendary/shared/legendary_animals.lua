Config = Config or {}


--[[ -- list of legendary animals (add more if you find them, these are just what I found so far)
    Cougar: a_c_cougar_01 | Outfit 2
    Bighorn Ram: a_c_bighornram_01 | Outfit 1
    Elk: A_C_Elk_01 | Outfit 1
    Tatanka Bison: a_c_buffalo_tatanka_01| 1
    Elk: A_C_Elk_01 | Outfit 1
    Sun Alligator: MP_A_C_ALLIGATOR_01 | Outfit 0
    Beaver: MP_A_C_BEAVER_01 | Outfit 1,2
    Giant Boar: a_c_boarlegendary_01 | Outfit 0
    Wakpa Boar: MP_A_C_BOAR_01 | Outfit 1,2,4
    Maza Cougar: MP_A_C_COUGAR_01 | Outfit 1,2
    Midnight Paw Coyote: MP_A_C_COYOTE_01 | Outfit 1,2
    Ghost Panther: MP_A_C_PANTHER_01 | Outfit 0,2
    Onyx Wolf: MP_A_C_WOLF_01 | Outfit 1
    Owiza Bear: MP_A_C_BEAR_01 | Outfit 2,3
    Chalk Horn Ram: MP_A_C_BIGHORNRAM_01 | Outfit 2,3
    Legendary Buck: MP_A_C_BUCK_01 | Outfit 2,4
    Winyan Bison: MP_A_C_BUFFALO_01 | Outfit 1,2
    Snowflake Moose: MP_A_C_MOOSE_01 | Outfit 1,2,3
]]

-- You can have multiple legendary animals defined here
-- If you want a cougar out west and one out east you can create different entries with different coords.


-- 0.0 - 1.0 = 0% - 100% chance to spawn

Config.LegendaryAnimals = {
    -- Legendary Animals
    BigHornRam = {
        Name = "Legendary Bighorn Ram", --
        Object = {
            Enabled = true,
            Model = "MP_A_C_BIGHORNRAM_01", -- ModelHash: -511163808 PeltHash: -675142890
            Scale = 1.3,
            Health = 18000,
            defaultOutfit = -1,
        },
        spawnChance = 0.2,  -- -- 0.0 - 1.0 = 0% - 100% chance to spawn
        alertDistance = 75, -- distance at which the animal will be alert of players
        huntArea = 50,      -- anything outside this distance will try despawn animal
        coolDown = 30,      -- In seconds, this is a respawn cooldown, after animal has despawned. (killed animals don't respawn)
        showBlip = false    -- Not implemented yet
    },
    Coyote = {
        Name = "Legendary Coyote",
        Object = {
            Enabled = true,
            Model = "MP_A_C_COYOTE_01", --ModelHash -1307757043 | PeltHash: Perfect: 1009802015
            Scale = 1.3,
            Health = 18000,
            defaultOutfit = 2,
        },
        spawnChance = 0.15, -- -- 0.0 - 1.0 = 0% - 100% chance to spawn
        alertDistance = 75, -- distance at which the animal will be alert of players
        huntArea = 300,     -- anything outside this distance will try despawn animal
        coolDown = 45,      -- Not implemented yet
        showBlip = false    -- Not implemented yet
    },

}

Config.AnimalSpawns = {
    { -- Western Coyote
        Name = "Coyote",
        Data = Config.LegendaryAnimals.Coyote,
        Coords = {
            vector3(-3144.25, -3571.74, 11.98),
            vector3(-3374.56, -3422.2, 47.38),
            vector3(-3313.42, -3550.87, 7.02)
        },

    },
    { -- Western Ram
        Name = "BigHornRam",
        Data = Config.LegendaryAnimals.BigHornRam,
        Coords = {
            vector3(-6154.57, -3469.38, 32.36),
            vector3(-6139.14, -3549.97, 30.57),
            vector3(-6435.97, -3449.06, -0.8)
        },

    },
}
