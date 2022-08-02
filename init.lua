local S = minetest.get_translator(minetest.get_current_modname())

sum_teleporters = {
	connections = {},
}

local teleporter = {}

local function debug()
	minetest.sound_play(mcl_sounds.node_sound_metal_defaults().dig, {pos=pos, max_hear_distance=16}, true)
end

teleporter.connect = function(pos, ingot)
	if not sum_teleporters.connections[ingot] then sum_teleporters.connections[ingot] = {pos, nil} end
	local connection = sum_teleporters.connections[ingot]
	if not connection then return false end
	if pos ~= connection[0] and pos ~= connection[1] then
		if connection[0] == nil then
			connection[0] = pos
		else
			connection[1] = pos
		end
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("ingot", ingot)
	return connection
end

teleporter.disconnect = function(pos, ingot)
	if not sum_teleporters.connections[ingot] then sum_teleporters.connections[ingot] = {pos, nil} end
	local connection = sum_teleporters.connections[ingot]
	if not connection then return false end
	if pos == connection[0] then
		connection[0] = nil
	else
		connection[1] = nil
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("ingot", "")
	debug()
	return connection
end

teleporter.activate = function(pos, node, player, itemstack, pointed_thing,  ingot)
	local connection = sum_teleporters.connections[ingot]
	local can_activate = true
	if connection and (not connection[0] or not connection[1]) then
		can_activate = true
	end

	if can_activate then
		local x = teleporter.connect(pos, ingot)
	end
end

teleporter.deactivate = function(pos, ingot)
	local connection = sum_teleporters.connections[ingot]
	if not connection then return false end
	if connection[0] == pos then connection[0] = nil
	else connection[1] = nil end
end

teleporter.teleport = function(pos, node, player, itemstack, pointed_thing,  ingot)
	local radius = 3

	local connection = sum_teleporters.connections[ingot]
	if not connection then return false end
	local destination = pos
	if connection[0] == pos then destination = connection[1]
	else destination = connection[0] end
	if not destination then return false end

	if not (connection and (connection[0] and connection[1])) then
		debug()
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
	for index, value in pairs(list) do
		if value == item then
			has_found = true
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
				if not x then debug() end
			end
		end
	end,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	stack_max = 64,
	groups = {pickaxey=5, building_block=1, material_stone=1},
	_mcl_blast_resistance = 1200,
	_mcl_hardness = 50,
})