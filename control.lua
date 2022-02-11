require("defines")
local mod_gui = require("mod-gui")
require("util")

curvedRail = require("stdlib.curvedRail")
serpent = require("stdlib.serpent")
local v = require("stdlib.semver")

local MOD_NAME = "LandfillEverything"
local GUI_BUTTON = "le_button"

--function init_debug()
--    game.write_file("landfill_e.log", "Log file for Landfill Everything")
--end
--
--function debug(obj)
--    game.write_file("landfill_e.log", serpent.dump(obj), true)
--end

function trace(text)
    for _, player in pairs(game.players) do
        player.print("Info: " .. text)
    end
end

-- rotate bounding box 90° cw
function rotate(box)
    return {
       left_top     = { x = -box.right_bottom.y, y = box.left_top.x     },
       right_bottom = { x = -box.left_top.y    , y = box.right_bottom.x }
    }
end

function add_landfill(blueprint, player, is_shift_pressed, is_control_pressed)
    local entities = blueprint.get_blueprint_entities()
    local old_tiles = blueprint.get_blueprint_tiles()
    local preferred_tile = settings.get_player_settings(player)[le_defines.names.settings.preferred_tile].value

    -- Set up tile type to use, mod must be installed and chosen in settings.
    local landfill_tile = { name = le_defines.tile_mapping[le_defines.values.preferred_tile_values.default] }
    if game.active_mods[preferred_tile] then
        landfill_tile = { name = le_defines.tile_mapping[preferred_tile] }
    end

    local tileIndex = 0

    --pre-allocate all the prototypes
    local protos = {}
    local new_tiles = {}
	local rolling_stocks = {}

    -- check for rails and cache prototypes
    if entities then
        for k = 1, #entities, 1 do
            local name = entities[k].name
            if protos[name] == nil then
                protos[name] = game.entity_prototypes[name]
                -- local proto_type = protos[name].type
            end
        end
		
		for name, proto in pairs(game.get_filtered_entity_prototypes({{filter = "rolling-stock"}})) do 
			rolling_stocks[name] = true;
		end

        for i, ent in pairs(entities) do
            local name = ent.name

			if rolling_stocks[name] ~= nil then
				-- This is a vehicle. Do nothing
            elseif "curved-rail" ~= name then -- special case for curved rail
                local proto = protos[name];
                local box = proto.collision_box or proto.selection_box
                local pos = ent.position

                if proto.collision_mask["ground-tile"] == nil then

                    -- Rotate the box if needed, in steps of 90°
                    if ent.direction ~= nil then
                       if ent.direction ~= defines.direction.north then
                           box = rotate(box)
                           if ent.direction ~= defines.direction.east then
                               box = rotate(box)
                               if ent.direction ~= defines.direction.south then
                                  box = rotate(box)
                               end
                           end
                       end
                    end

                    local start_x = math.floor (pos.x + box.left_top.x)
                    local start_y = math.floor (pos.y + box.left_top.y)
                    local end_x   = math.floor (pos.x + box.right_bottom.x)
                    local end_y   = math.floor (pos.y + box.right_bottom.y)

                    for y = start_y, end_y, 1 do
                        for x = start_x, end_x, 1 do
                            tileIndex = tileIndex + 1
                            new_tiles[tileIndex] = { name = landfill_tile.name, position = { x, y } }
                        end
                    end
                end

                if proto.adjacent_tile_collision_test == "water-tile" then
                   -- feature: adjacent box could be waterfill'ed
                end

            else -- curved Rail
                local dir = ent.direction
                if dir == nil then
                    dir = 8
                end
                local curveMask = getCurveMask(dir)
                local pos = ent.position
                for m = 1, #curveMask do
                    local x = curveMask[m].x + pos.x
                    local y = curveMask[m].y + pos.y
                    new_tiles[tileIndex + 1] = { name = landfill_tile.name, position = { x, y } }
                    tileIndex = tileIndex + 1
                end
            end
            --            trace("new_tiles" .. serpent.block(new_tiles))
        end
    end
    if not is_shift_pressed then
        if old_tiles then
            for i, old_tile in pairs(old_tiles) do
                local pos = old_tile.position
                new_tiles[tileIndex + 1] = { name = landfill_tile.name, position = { pos.x, pos.y } }
                tileIndex = tileIndex + 1
            end
        end
    end

    if is_control_pressed and old_tiles then
        for k, tile in pairs(old_tiles) do
            table.insert(new_tiles, tile)
        end
    end

    return { tiles = new_tiles }
end


function get_le_flow(player)

    local button_flow = mod_gui.get_button_flow(player)
    local flow = button_flow.le_flow
    if not flow then
        flow = button_flow.add {
            type = "flow",
            name = "le_flow",
            direction = "horizontal"
        }
    end
    return flow
end

function add_top_button(player)

    if player.gui.top.le_flow then player.gui.top.le_flow.destroy() end -- remove the old flow

    local flow = get_le_flow(player)

    if flow[GUI_BUTTON] then flow[GUI_BUTTON].destroy() end
    flow.add {
        type = "sprite-button",
        name = GUI_BUTTON,
        sprite = "item/landfill",
        style = mod_gui.button_style,
        tooltip = { "landfill_everything_tooltip" }
    }
end

function is_valid_slot(slot, state)

    if not slot or not slot.valid_for_read then return false end

    --if state then
    if state == "empty" then
        return not slot.is_blueprint_setup()
    elseif state == "setup" then
        return slot.is_blueprint_setup()
    end
    --end
    return true
end

function get_blueprint_on_cursor(player)

    local stack = player.cursor_stack
    if stack.valid_for_read then
        if (stack.type == "blueprint" and is_valid_slot(stack, 'setup')) then
            return stack
        elseif stack.type == "blueprint-book" then
            local active = stack.get_inventory(defines.inventory.item_main)[stack.active_index]
            if is_valid_slot(active, 'setup') then
                return active
            end
        end
    end
    return false
end

script.on_init(function()
    for _, player in pairs(game.players) do
        add_top_button(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    add_top_button(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]

    if event.element.name == GUI_BUTTON then
        if player.cursor_stack.valid_for_read then
            -- TODO: check that landfill has been researched
            local blueprint = get_blueprint_on_cursor(player)
            if blueprint then
                local modified = add_landfill(blueprint, player, event.shift, event.control)
                if next(modified.tiles) ~= nil then
                    blueprint.set_blueprint_tiles(modified.tiles)
                end
            end
        end
    end
end)

script.on_configuration_changed(function(data)
    if not data or not data.mod_changes then
        return
    end
    local newVersion
    local oldVersion
    if data.mod_changes[MOD_NAME] then
        newVersion = data.mod_changes[MOD_NAME].new_version
        newVersion = v(newVersion)
        oldVersion = data.mod_changes[MOD_NAME].old_version
        if oldVersion then
            oldVersion = v(oldVersion)
            trace("Updating Landfill Everything from " .. tostring(oldVersion) .. " to " .. tostring(newVersion))
            -- Remove old button from 0.17.0
            if oldVersion < v '0.17.1' then
                for _, player in pairs(game.players) do
                    local button_flow = mod_gui.get_button_flow(player)
                    local flow = button_flow.le_flow
                    if flow["search_flow"] then flow["search_flow"].destroy() end
                end
            end
            --Reset top button
            for _, player in pairs(game.players) do
                add_top_button(player)
            end
        end
    end
end)
