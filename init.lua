local S = minetest.get_translator(minetest.get_current_modname())

sum_teleporters = {
	connections = {},
}

local teleporter = {}

local function debug()
	minetest.sound_play(mcl_sounds.node_sound_metal_defaults().dig, {pos=pos, max_hear_distance=16}, true)
end
local function debug2()
	minetest.sound_play(mcl_sounds.node_sound_stone_defaults().dig, {pos=pos, max_hear_distance=16}, true)
end
local function portal_open_sound()
	minetest.sound_play("mcl_portals_open_end_portal", {gain=0.8}, true)
end


teleporter.get_destination = function(pos)
	if not pos then return nil end
	local meta = minetest.get_meta(pos)
	return {
		x = meta:get_string("destination_x"),
		y = meta:get_string("destination_y"),
		z = meta:get_string("destination_z")
	}
end
teleporter.set_destination = function(pos, destination)
	if not pos or not destination then return false end
	local meta = minetest.get_meta(pos)
	meta:set_string("destination_x", destination.x)
	meta:set_string("destination_y", destination.y)
	meta:set_string("destination_z", destination.z)
	return true
end

teleporter.connect = function(pos, ingot, player)
	local meta = minetest.get_meta(pos)
	meta:set_string("ingot", ingot)
	meta:set_string("state", "enabled")
	local connections = sum_teleporters.connections[player]
	if not connections then
		connections = {ingot = ingot, pos = pos}
	elseif connections and connections.ingot and connections.pos then
		teleporter.set_destination(connections.pos, pos)
		teleporter.set_destination(pos, connections.pos)
		sum_teleporters.connections[player] = nil
	end
end

teleporter.disconnect = function(pos, player)
	local meta = minetest.get_meta(pos)
	meta:set_string("ingot", "")
	meta:set_string("state", "disabled")
	local dest_pos = teleporter.get_destination(pos)
	if dest_pos then teleporter.disconnect(dest_pos)
	sum_teleporters.connections[player] = {ingot = nil, pos = nil}
end

teleporter.activate = function(pos, node, player, itemstack, pointed_thing, ingot)
	local connection = sum_teleporters.connections[player]
	local last_link_ingot = nil
	if connection then last_link_ingot = connection.ingot end

	if last_link_ingot == ingot then
		teleporter.connect(pos, ingot, player)
	end
end

teleporter.deactivate = function(pos, ingot)
end

teleporter.teleport = function(pos, node, player, itemstack, pointed_thing,  ingot)
	local radius = 3

	local destination = teleporter.get_destination(pos)
	if not destination then
		debug2()
		return false
	end

	for _, player in minetest.get_connected_players() do
		local dist = vector.distance(player:get_pos(), pos)
		if dist < radius then
			local offset = vector.subtract(pos, player:get_pos())
			player:set_pos(vector.add(offset, destination))
		end
	end
	return true
end

local function is_in(item, list)
	if not item or not list then return false end
	local has_found = false
	for _, value in pairs(list) do
		if value == item then
			has_found = true
			break
		end
	end
	return has_found
end


local select_box = {
	type = "fixed",
	fixed = {
		{ -5 / 16, -8 / 16, -5 / 16,
			 5 / 16, 16 / 16,  5 / 16},
	},
}

local activate_item_list = {
	"mcl_core:iron_ingot",
	"mcl_core:diamond",
	"mcl_core:emerald",
	"mcl_core:gold_ingot",
	"mcl_core:netherite_ingot"}



minetest.register_node("sum_teleporters:teleporter", {
	description = S("Teleporter"),
	_tt_help = S("Teleports the player and entities"),
	_doc_items_longdesc = S("Can teleport the player when linked with ingots of the same type. Only one link can exist."),
	_doc_items_usagehelp = S("Rightclick to teleport."),
	_doc_items_hidden = false,
	is_ground_content = false,
	drawtype = "mesh",
	mesh = "teleporter_pillar.b3d",
	tiles = {"teleporter_skin.png"},
	selection_box = select_box,
	collision_box = select_box,
	paramtype2 = "facedir",
	groups = {handy=1,axey=1,deco_block=1,flammable=-1},
	on_rightclick = function (pos, node, player, itemstack, pointed_thing)
		if not player:get_player_control().sneak then
			local meta = minetest.get_meta(pos)
			local ingot = meta:get_string("ingot")
			local wielded_item = player:get_wielded_item():get_name()
			if is_in(wielded_item, activate_item_list) and not ingot then
				teleporter.activate(pos, node, player, itemstack, pointed_thing, wielded_item)
			elseif ingot then
				local x = teleporter.teleport(pos, node, player, itemstack, pointed_thing, ingot)
				-- if not x then debug() end
			end
		end
	end,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	stack_max = 64,
	groups = {pickaxey=5, building_block=1, material_stone=1},
	_mcl_blast_resistance = 1200,
	_mcl_hardness = 50,
})