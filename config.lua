Config = {}

Config.MinScale = 0.1
Config.MaxScale = 7.0

Config.DefaultScale = 1.0

Config.EnableLogging = true

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

Config.PersistenceSettings = {
    scaleCheckInterval = 5000
}