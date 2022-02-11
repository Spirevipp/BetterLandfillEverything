-- Here are the values that are shared across different files.
le_defines = {}
-- Prefix of the entity names and item names.
le_defines.name_prefix = "landfill_everything_"

-- Names and values
le_defines.names = {}
le_defines.values = {}

-- Setting names
le_defines.names.settings =
{
    preferred_tile = le_defines.name_prefix .. "preferred-tile",
}

-- Setting - Available tiles
le_defines.values.preferred_tile_values =
{
    default = "Factorio default",
    platforms = "platforms"
}

-- Tile mapping
le_defines.tile_mapping = {
    [le_defines.values.preferred_tile_values.platforms] = "micromario-platform",
    [le_defines.values.preferred_tile_values.default] = "landfill"
}

le_defines.reserved_tiles = {}
for mod, tile in pairs(le_defines.tile_mapping) do
    le_defines.reserved_tiles[tile] = true
end
