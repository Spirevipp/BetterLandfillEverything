require("defines")

data:extend {
	{
		type = "string-setting",
		setting_type = "runtime-per-user",
		name = ble_defines.names.settings.preferred_tile,
		default_value = ble_defines.values.preferred_tile_values.default,
		allowed_values = ble_defines.values.preferred_tile_values
	},
	{
		type = "string-setting",
		setting_type = "runtime-per-user",
		name = ble_defines.names.settings.custom_tile,
		default_value = "",
		allow_blank = true,
		auto_trim = true
	}
}
