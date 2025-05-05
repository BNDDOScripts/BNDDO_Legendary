Config = {}
Config.DevMode = false

Config.MinimumSpawnDistance = 100.0 -- distance from players that the legendary animals will spawn
Config.MaxLegendarySpawned = 5      -- total number of legendary animals that will be generated
Config.ClientCooldown = 1500        -- (15 seconds) This is different than the legendary animal cooldown. This is a cooldown for the client to prevent spamming requests to the server.

Config.FreezeLegendary = false      -- whether to freeze legendary animals in place when they spawn (good for testing)


-- You can use this command in the console to toggle debug mode on or off.
-- You can also place it in your server.cfg to enable debug mode by default.
-- If you have DevMode enabled it will place the command automatically when the resource starts.
-- All debug messages will be printed to the console when debug mode is on.

-- setr <resourceName>:debug on|off
