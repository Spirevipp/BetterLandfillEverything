-- Here are the values that are shared across different files.
ble_defines = {}
-- Prefix of the entity names and item names.
ble_defines.name_prefix = "better_landfill_everything_"

-- Names and values
ble_defines.names = {}
ble_defines.values = {}

-- Setting names
ble_defines.names.settings =
{
	preferred_tile = ble_defines.name_prefix .. "preferred-tile",
	custom_tile = ble_defines.name_prefix .. "custom-tile"
}

-- Setting - Available tiles
ble_defines.values.preferred_tile_values =
{
	default = "Factorio default",
	platforms = "platforms",
	spaceplating = "Space Platform Plating",
	spacescaffolding = "Space Platform Scaffolding"
}

-- Tile mapping
ble_defines.tile_mapping = {
	[ble_defines.values.preferred_tile_values.platforms] = "platform",
	[ble_defines.values.preferred_tile_values.default] = "landfill",
	[ble_defines.values.preferred_tile_values.spaceplating] = "se-space-platform-plating",
	[ble_defines.values.preferred_tile_values.spacescaffolding] = "se-space-platform-scaffold"
}

ble_defines.reserved_tiles = {}
for mod, tile in pairs(ble_defines.tile_mapping) do
	ble_defines.reserved_tiles[tile] = true
end
