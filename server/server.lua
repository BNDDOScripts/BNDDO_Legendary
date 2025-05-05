-- initialize random list of animals from Config
-- track spawned and killed status

local SpawnCoords = {}


-- -------------------------- initLegendaryAnimals -------------------------- --
-- Initializes a random subset of legendary animals for potential spawning.
-- Only includes animals with Enabled=true in their config.
local function initLegendaryAnimals(spawnCount)
    if not Config.LegendaryAnimals or not Config.AnimalSpawns then return end

    SpawnCoords = {}

    local added = 0
    for _, spawn in ipairs(Config.AnimalSpawns) do
        local data = spawn.Data
        if data and data.Object and data.Object.Enabled then
            local chance = data.spawnChance or 1.0
            if (math.random() > chance) then
                dprint(("[INFO] Skipping spawn for %s due to spawn chance"):format(spawn.Name))
            else
                local coords = spawn.Coords
                if coords and #coords > 0 then
                    local randomCoord = coords[math.random(1, #coords)]

                    SpawnCoords[spawn.Name] = {
                        coords = randomCoord,
                        spawned = false,
                        killed = false,
                        killedAt = nil
                    }

                    added = added + 1
                    if added >= spawnCount then break end
                else
                    dprint(("[WARN] No coordinates defined for spawn: %s"):format(spawn.Name))
                end
            end
        end
    end
end

-- ---------------------------- canSpawnLegendary --------------------------- --
local function canSpawnLegendary(animal)
    local animalData = SpawnCoords[animal]
    local cooldownPeriod = Config.LegendaryAnimals[animal].coolDown
    dprint("Checking spawn status for animal: " .. animal)

    if not animalData then
        dprint("No data found for animal: " .. animal)
        return false, nil
    end

    if animalData.spawnedAt then
        local timeSinceSpawned = os.time() - animalData.spawnedAt
        local timeLeft = cooldownPeriod - timeSinceSpawned
        dprint("Time left in cooldown for animal " .. animal .. ": " .. timeLeft .. " seconds")
        if timeSinceSpawned < cooldownPeriod then
            dprint("Animal is still in cooldown: " .. animal)
            return false, nil
        end
    end

    if animalData.spawned or animalData.killed then
        dprint("Animal already spawned or killed: " .. animal)
        return false, animalData.netId
    end

    return true, nil
end

-- ---------------------------- despawnLegendary ---------------------------- --
local function despawnLegendary(animalName)
    local animalData = SpawnCoords[animalName]

    if not animalData then
        dprint("No data found for animal: " .. animalName)
        return
    end

    if animalData.players and next(animalData.players) then
        dprint("Cannot despawn animal, players still in zone: " .. animalName)
        return
    end

    local entityId = NetworkGetEntityFromNetworkId(animalData.netId or 0)

    if animalData.killed then
        dprint("Animal killed, not despawning: " .. animalName)
        return
    end

    if not DoesEntityExist(entityId) then
        dprint("Entity doesn't exist for animal: " .. animalName)
        animalData.spawned = false
        animalData.netId = nil
        return
    end


    -- Despawn if not killed and no players in zone
    dprint("Despawning animal entity: " .. entityId)
    jo.entity.delete(entityId)
    animalData.entity = nil
    animalData.spawned = false
    animalData.netId = nil
    animalData.spawnedAt = os.time()
    TriggerClientEvent("bnddo_legendary:client:updateStatus", -1, animalName, "despawned")
    dprint("Animal despawned: " .. animalName)
end

-- --------------------------- getLegendaryAnimals -------------------------- --
-- Returns the current state of legendary animals, including their spawn status.
local function getLegendaryAnimals()
    return SpawnCoords
end


-- -------------------------------------------------------------------------- --
--                                  CALLBACKS                                 --
-- -------------------------------------------------------------------------- --
jo.callback.register("bnddo_legendary:server:getLegendaryAnimals", function()
    return getLegendaryAnimals()
end)

jo.callback.register("bnddo_legendary:server:trySpawnLegendary", function(source, animalName)
    return canSpawnLegendary(animalName)
end)

-- -------------------------------------------------------------------------- --
--                                   EVENTS                                   --
-- -------------------------------------------------------------------------- --

-- RegisterNetEvent("bnddo_legendary:server:trySpawnLegendary", function(animalName)
--     local _src = source
--     if not canSpawnLegendary(animalName) then
--         return
--     end
--     SpawnCoords[animalName].spawned = true
--     if Config.DevMode then
--         local duration = jo.debugger.perfomance("Telling client to spawn animal", function()
--             TriggerClientEvent("bnddo_legendary:client:spawnLegendaryAnimal", _src, animalName,
--                 SpawnCoords[animalName].coords)
--         end)
--     else
--         TriggerClientEvent("bnddo_legendary:client:spawnLegendaryAnimal", _src, animalName,
--             SpawnCoords[animalName].coords)
--     end
-- end)


RegisterNetEvent("bnddo_legendary:server:animalSpawned", function(animalName, entity, netId, action)
    if not SpawnCoords[animalName] then return end
    if action and action ~= true and action ~= false then
        dprint("Invalid action received: " .. tostring(action))
        return
    end

    SpawnCoords[animalName].spawned = true
    SpawnCoords[animalName].entity = entity
    SpawnCoords[animalName].netId = netId
    TriggerClientEvent("bnddo_legendary:client:updateStatus", -1, animalName, "spawned")

    dprint("Animal spawned: " .. animalName .. ", Entity ID: " .. tostring(entity) .. ", Net ID: " .. tostring(netId))
end)

RegisterNetEvent("bnddo_legendary:server:updatePlayerInZone", function(animalName, action)
    local _src = tostring(source)
    if action and action ~= true and action ~= false then
        dprint("Invalid action received: " .. tostring(action))
        return
    end

    if action then
        dprint("Player updated in zone: " .. animalName)
        SpawnCoords[animalName].players = SpawnCoords[animalName].players or {}
        SpawnCoords[animalName].players[_src] = true
    else
        if SpawnCoords[animalName] and SpawnCoords[animalName].players then
            SpawnCoords[animalName].players[_src] = nil

            despawnLegendary(animalName)

            dprint("Player removed from zone: " .. animalName)
        end
    end
end)

RegisterNetEvent("bnddo_legendary:server:animalKilled", function(animalName, netId)
    if not SpawnCoords[animalName] then return end

    SpawnCoords[animalName].killed = true
    SpawnCoords[animalName].killedAt = os.time()

    TriggerClientEvent("bnddo_legendary:client:updateStatus", -1, animalName, "killed")

    dprint("Animal killed: " .. animalName)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.DevMode then
            ExecuteCommand("setr bnddo_legendary:debug on")
            dprint("Devmode is enabled. Initializing legendary animals with performance measurement.")
            local duration = jo.debugger.perfomance("Init measurement", function()
                initLegendaryAnimals(Config.MaxLegendarySpawned)
            end)
        else
            ExecuteCommand("setr bnddo_legendary:debug off")
            initLegendaryAnimals(Config.MaxLegendarySpawned)
        end
    end
end)

AddEventHandler('playerDropped', function(reason, resourceName)
    local _src = tostring(source)
    for animalName, animalData in pairs(SpawnCoords) do
        if animalData.players and animalData.players[_src] then
            animalData.players[_src] = nil
            despawnLegendary(animalName)
            dprint("Player " .. _src .. " dropped, despawning animal: " .. animalName)
        end
    end
end)


-- -------------------------------------------------------------------------- --
--                                   EXPORTS                                  --
-- -------------------------------------------------------------------------- --
-- returns spawnCoords of legendary animals (server side)
exports("getLegendaryAnimals", getLegendaryAnimals)

---@Param animalName string
---@Param boolean, number|nil
exports("despawnLegendary", despawnLegendary)

---@Param spawnCount number
exports("initLegendaryAnimals", initLegendaryAnimals)




if Config.DevMode then
    RegisterCommand("getLegendaries", function(source, args, rawCommand)
        dprint(json.encode(SpawnCoords))
    end, true)

    RegisterCommand("checkStatus", function(source, args, rawCommand)
        if #args < 1 then
            for animalName, status in pairs(SpawnCoords) do
                local killedStatus = status.killed and "Yes" or "No"
                local spawnedStatus = status.spawned and "Yes" or "No"
                dprint(string.format("Animal: %s, Killed: %s, Spawned: %s", animalName, killedStatus, spawnedStatus))
            end
            return
        end

        local status = SpawnCoords[args[1]]
        if not status then
            dprint("No status found for this animal.")
            return
        end

        local killedStatus = status.killed and "Yes" or "No"
        local spawnedStatus = status.spawned and "Yes" or "No"

        dprint(string.format("Animal: %s, Killed: %s, Spawned: %s", args[1], killedStatus, spawnedStatus))
    end, true)
end
