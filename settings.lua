require("defines")

data:extend {
    {
        type = "string-setting",
        setting_type = "runtime-per-user",
        name = le_defines.names.settings.preferred_tile,
        default_value = le_defines.values.preferred_tile_values.default,
        allowed_values = le_defines.values.preferred_tile_values
    }
}
