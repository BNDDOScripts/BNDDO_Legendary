local Debug = GetConvar("bnddo_legendary:debug", "off") == "on"
local LegendarySpawnCoords = {} -- Table to store legendary animal spawn coordinates
local InCombat = false


-- -------------------------------------------------------------------------- --
--                                  FUNCTIONS                                 --
-- -------------------------------------------------------------------------- --

-- --------------------------------- init() --------------------------------- --
-- Get list of coords from server
local function init()
    jo.callback.triggerServer("bnddo_legendary:server:getLegendaryAnimals", function(animals)
        for animal, animalInfo in pairs(animals) do
            local coords = animalInfo.coords
            local spawned = animalInfo.spawned or false
            local killed = animalInfo.killed or false

            local data = Config.LegendaryAnimals[animal] or nil
            LegendarySpawnCoords[animal] = {
                coords = coords,
                spawned = spawned,
                killed = killed,

            }
        end
    end)
end
-- ----------------------------- cooldownPassed ----------------------------- --
local function cooldownPassed(startTime, durationMs)
    return not startTime or (GetGameTimer() - startTime) >= durationMs
end

-- -------------------------- distance() ------------------------- --
--checks player distance to spawn zones
local function distance(player, entity)
    local dist = #(player - entity)
    return dist
end
-- ------------------------- handlePredatorBehavior ------------------------- --
local function handlePredatorBehavior(entity, animalName, config)
    dprint("[DEBUG] Starting legendary hunt for predator: " .. animalName)
    local alertDistance = config.alertDistance or 30.0
    local player = PlayerPedId()
    local netId = PedToNet(entity)


    -- Combat tuning

    Citizen.InvokeNative(0x2BA918C823B8BA56, entity, 0.0)                -- Disable headshot damage
    Citizen.InvokeNative(0xC7622C0D36B2FDA8, entity, 3)                  -- CAL_PROFESSIONAL
    Citizen.InvokeNative(0x4D9CA1009AFBD057, entity, 2)                  -- Offensive combat movement

    Citizen.InvokeNative(0xCBDA22C87977244F, entity, 104, alertDistance) -- ATF_WarnSoundRange

    Citizen.InvokeNative(0x96AA1304D30E6BC3, entity, 14, true)           -- ATB_CombatStalk


    AddRelationshipGroup("LEGENDARY_ANIMAL")
    SetPedRelationshipGroupHash(entity, `LEGENDARY_ANIMAL`)

    SetRelationshipBetweenGroups(5, `LEGENDARY_ANIMAL`, `PLAYER`)
    local neutralGroups = { `CIVMALE`, `CIVFEMALE`, `REL_WILD_ANIMAL`, `REL_ALLIGATOR`, `REL_WILD_ANIMAL_BIRD`,
        `REL_WILD_ANIMAL_PREDATOR` }
    for _, group in ipairs(neutralGroups) do
        SetRelationshipBetweenGroups(1, `LEGENDARY_ANIMAL`, group)
    end


    CreateThread(function()
        while DoesEntityExist(entity) do
            local animalCoord = GetEntityCoords(entity)
            local playerCoord = GetEntityCoords(player)

            if IsPedShooting(player) or GetEntityHealth(entity) < GetEntityMaxHealth(entity) then
                TaskCombatHatedTargets(entity, alertDistance) -- Engage combat if player is shooting
            end

            if GetEntityHealth(entity) == GetEntityMaxHealth(entity) / 2 then
                TaskFleePed(entity, player, 5, 3, -1.0, -1, 0) -- Flee if health is low
            end

            if distance(playerCoord, animalCoord) <= alertDistance then
                TaskCombatHatedTargets(entity, alertDistance) -- Engage combat if player is close
            end
            Wait(500)                                         -- Check every 500ms
        end
    end)
end
-- --------------------------- handlePreyBehavior --------------------------- --
local function handlePreyBehavior(entity, animalName, config)
    dprint("[DEBUG] Starting legendary hunt for Prey: " .. animalName)
    local alertDistance = config.alertDistance or 30.0
    local player = PlayerPedId()
    local netId = PedToNet(entity)
    dprint(("[DEBUG] Prey Net ID: %s"):format(tostring(netId)))

    Citizen.InvokeNative(0x2BA918C823B8BA56, entity, 0.0)                -- Disable headshot multiplier damage
    Citizen.InvokeNative(0xCBDA22C87977244F, entity, 104, alertDistance) -- ATF_WarnSoundRange
    Citizen.InvokeNative(0xAE6004120C18DF97, entity, 0, false)           -- Prevent lassoing


    CreateThread(function()
        while DoesEntityExist(entity) do
            local animalCoord = GetEntityCoords(entity)
            local playerCoord = GetEntityCoords(player)



            if IsPedShooting(player) or GetEntityHealth(entity) < GetEntityMaxHealth(entity) then
                TaskFleePed(entity, player, 5, 3, -1.0, -1, 0) -- Flee if player is shooting
            end

            if distance(playerCoord, animalCoord) <= alertDistance then
                TaskFleePed(entity, player, 5, 3, -1.0, -1, 0) -- Flee if player is close
            else
                TaskWanderStandard(entity, 2.0, 10)            -- Wander if player is not close
            end
            Wait(500)                                          -- Check every 500ms
        end
    end)
end

-- ------------------------- spawnLegendaryAnimal() ------------------------- --
-- Spawns a legendary animal at the given coordinates if enabled in config.
-- Notifies the server of the spawn and starts AI behavior for the animal.
-- Only proceeds if the entity is successfully created and exists.
local function spawnLegendaryAnimal(animalName, coords)
    local config = Config.LegendaryAnimals[animalName]
    if not config or not config.Object or not config.Object.Enabled then
        dprint(("^1[ERROR]^0 Attempted to spawn invalid or disabled legendary animal: %s"):format(animalName))
        return
    end

    dprint(("[DEBUG] Attempting to spawn legendary animal: %s"):format(animalName))

    local model = config.Object.Model
    local spawnRadius = config.Object.SpawnRadius or 45
    local heading = math.random(-180, 180)
    local animalConfig = Config.LegendaryAnimals[animalName]

    -- Create the entity with provided model and parameters
    local entity = jo.entity.create(model, coords, heading, true, 50)

    if entity and DoesEntityExist(entity) then
        dprint(("[DEBUG] Spawned legendary animal: %s | Entity: %s"):format(animalName, tostring(entity)))
        InCombat = true
        -- Store and sync the network ID
        local netId = PedToNet(entity)
        LegendarySpawnCoords[animalName].spawnedEntity = netId

        -- Notify the server
        TriggerServerEvent("bnddo_legendary:server:animalSpawned", animalName, entity, netId, true)
        if Config.FreezeLegendary then
            FreezeEntityPosition(entity, true)
        end

        -- Initial setup
        SetAttributeCoreValue(entity, 0, animalConfig.Object.Health or 10000) -- Health
        SetEntityHealth(entity, animalConfig.Object.Health or 10000, 0)
        SetPedScale(entity, animalConfig.Object.Scale or 1.0)
        SetBlockingOfNonTemporaryEvents(entity, true)
        Citizen.InvokeNative(0xAEB97D84CDF3C00B, entity, true)
        -- TaskWanderStandard(entity, 2.0, 10)
        EquipMetaPedOutfitPreset(entity, animalConfig.Object.defaultOutfit or -1)

        jo.gameEvents.listen("EVENT_NETWORK_DAMAGE_ENTITY", function(data)
            if data.target_entity == entity and data.is_victim_destroyed == 1 then
                dprint(("[DEBUG] Prey entity destroyed: %s"):format(tostring(entity)))
                TriggerServerEvent("bnddo_legendary:server:animalKilled", animalName, netId)
            end
        end)

        local isPredator = GetIsPredator(entity) == 1

        -- Begin behavior logic
        if isPredator then
            handlePredatorBehavior(entity, animalName, config)
        else
            handlePreyBehavior(entity, animalName, config)
        end
    else
        dprint(("[ERROR] Failed to spawn entity for: %s"):format(animalName))
    end
end

-- --------------------- handlePlayerEnterLegendaryZone --------------------- --
-- Handles logic when a player enters the legendary animal's spawn zone.
-- Notifies the server that the player is in the zone and attempts to spawn the animal if allowed.
local function handlePlayerEnterLegendaryZone(name, legendary)
    dprint(("Moved into spawn area, checking status for: %s"):format(name))

    -- Notify server that the player is now in the zone
    TriggerServerEvent("bnddo_legendary:server:updatePlayerInZone", name, true)

    if legendary.spawned or legendary.killed then
        dprint(("Legendary animal already spawned or killed: %s"):format(name))
        return
    end

    local currentTime = GetGameTimer()

    if not cooldownPassed(legendary.spawnedTime, Config.ClientCooldown) then
        dprint(("Legendary animal spawn cooldown active for: %s"):format(name))
        return
    end

    -- Ask the server if we can spawn the legendary animal
    jo.callback.triggerServer("bnddo_legendary:server:trySpawnLegendary", function(canSpawn, netId)
        if canSpawn then
            dprint(("Player can spawn legendary animal: %s"):format(name))
            spawnLegendaryAnimal(name, legendary.coords)
        elseif netId then
            dprint(("Legendary animal already spawned: %s, Net ID: %s"):format(name, tostring(netId)))
            legendary.spawnedEntity = netId
        else
            dprint(("Legendary spawn denied and no entity reference returned for: %s"):format(name))
        end
    end, name)
end

-- ---------------------- handlePlayerExitLegendaryZone --------------------- --
-- Handles logic when a player leaves the legendary animal's spawn zone.
-- If the animal is alive and exists, informs the server the player left.
-- If the animal is dead or deleted, also updates the server with that state.
local function handlePlayerExitLegendaryZone(name, legendary)
    if not legendary.spawnedEntity then return end

    local entity = NetworkGetEntityFromNetworkId(legendary.spawnedEntity)

    if not DoesEntityExist(entity) or IsEntityDead(entity) then
        dprint(("Player moved out of spawn zone for %s (dead or deleted)"):format(name))
        TriggerServerEvent("bnddo_legendary:server:updatePlayerInZone", name, false)
    else
        dprint(("Player moved out of spawn zone for %s"):format(name))
        TriggerServerEvent("bnddo_legendary:server:updatePlayerInZone", name, false)
    end
    InCombat = false
end

-- -------------------------------------------------------------------------- --
--                                   EVENTS                                   --
-- -------------------------------------------------------------------------- --

-- -------------------- legendary:client:spawnPermission -------------------- --
-- TriggerServerEvent("legendary:server:checkSpawnStatus", name)

RegisterNetEvent("bnddo_legendary:client:spawnLegendaryAnimal", function(animalName, coords)
    spawnLegendaryAnimal(animalName, coords)
end)

RegisterNetEvent("bnddo_legendary:client:updateStatus", function(animalName, action)
    if not LegendarySpawnCoords[animalName] then
        dprint(("[WARN] Missing LegendarySpawnCoords entry for: %s"):format(animalName))
        init() -- or re-request that specific animal
        return
    end

    if action == "killed" then
        LegendarySpawnCoords[animalName].killed = true
        dprint(("Legendary animal killed: %s"):format(animalName))
    elseif action == "spawned" then
        LegendarySpawnCoords[animalName].spawned = true
        LegendarySpawnCoords[animalName].spawnedTime = GetGameTimer()
        dprint(("Legendary animal spawned: %s"):format(animalName))
    elseif action == "despawned" then
        LegendarySpawnCoords[animalName].spawned = false
        LegendarySpawnCoords[animalName].spawnedEntity = nil
        LegendarySpawnCoords[animalName].spawnedTime = GetGameTimer()
        dprint(("Legendary animal deleted: %s"):format(animalName))
    end
end)

-- -------------------------------------------------------------------------- --
--                                   THREADS                                  --
-- -------------------------------------------------------------------------- --
-- initial thread to initialize legendary spawn coordinates
CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    if Debug then
        local duration = jo.debugger.perfomance("Initial setup...", function()
            init()
        end)
    else
        init()
    end
end)

-- Main thread to check player proximity to spawn zones and handle spawning
CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession and table.count(LegendarySpawnCoords) > 0

    local playerPed = PlayerPedId()
    local inZone = {} -- Tracks per-animal zone status

    while true do
        local timeout = 1000
        local playerCoords = GetEntityCoords(playerPed)

        for name, legendary in pairs(LegendarySpawnCoords) do
            if legendary.coords then
                local distanceToAnimal = distance(playerCoords, legendary.coords)

                -- Entered spawn zone
                if not inZone[name] and distanceToAnimal <= Config.MinimumSpawnDistance then
                    inZone[name] = true
                    if Debug then
                        jo.debugger.perfomance("Check server for spawn status for " .. name, function()
                            handlePlayerEnterLegendaryZone(name, legendary)
                        end)
                    else
                        handlePlayerEnterLegendaryZone(name, legendary)
                    end

                    -- Exited spawn zone
                elseif inZone[name] and distanceToAnimal > Config.LegendaryAnimals[name].huntArea then
                    inZone[name] = false
                    handlePlayerExitLegendaryZone(name, legendary)
                end
            end
        end

        Wait(timeout)
    end
end)

-- -------------------------------------------------------------------------- --
--                               DEBUG/DEV STUFF                              --
-- -------------------------------------------------------------------------- --

exports("initLegendaryAnimals", init)

if Debug then
    RegisterCommand("getclientLegendaries", function(source, args, rawCommand)
        dprint(json.encode(LegendarySpawnCoords))
    end)
end
