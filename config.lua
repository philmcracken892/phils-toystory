Config = {}

-- Scale limits
Config.MinScale = 0.1
Config.MaxScale = 7.0
Config.DefaultScale = 1.0

-- System settings
Config.EnableLogging = true
Config.EnablePersistence = true

-- Cooldown settings (in seconds)
Config.PotionCooldown = 5        -- Cooldown for using potion on self
Config.TargetPotionCooldown = 10 -- Cooldown for using potion on other players

-- Size presets available in the menu
Config.SizePresets = {
    {
        name = "Tiny",
        description = "Very small size (0.2)",
        scale = 0.2,
        icon = "fas fa-compress-alt"
    },
    {
        name = "Small",
        description = "Small size (0.4)",
        scale = 0.4,
        icon = "fas fa-compress"
    },
    {
        name = "Normal",
        description = "Default size (1.0)",
        scale = 1.0,
        icon = "fas fa-user"
    },
    {
        name = "Large",
        description = "Large size (1.5)",
        scale = 1.5,
        icon = "fas fa-expand"
    },
    {
        name = "Giant",
        description = "Very large size (2.0)",
        scale = 2.0,
        icon = "fas fa-expand-alt"
    },
    {
        name = "Colossal",
        description = "Massive size (5.0)",
        scale = 5.0,
        icon = "fas fa-mountain"
    }
}

-- Persistence settings
Config.PersistenceSettings = {
    loadDelay = 2000,      -- Delay before applying scale after player loads
    spawnDelay = 500,      -- Delay before applying scale after player spawns
    scaleCheckInterval = 5000  -- Interval for checking and maintaining scales
}

-- ox-target settings
Config.TargetSettings = {
    enabled = true,                    -- Enable ox-target functionality
    requirePotion = true,              -- Require size potion to target other players
    showDistance = 2.0,                -- Maximum distance to show target option
    consumePotionOnUse = true,         -- Whether to consume potion when targeting others
    allowSelfTarget = false            -- Whether players can target themselves (not recommended)
}
