local S = minetest.get_translator("teleportmenu")
local F = minetest.formspec_escape
local gui = flow.widgets

local function get_player_name_list()
	local RLST = {}
	for _,y in pairs(minetest.get_connected_players()) do
		table.insert(RLST,y:get_player_name())
	end
	return RLST
end

local function confirm_func(player,ctx)
	local name = player:get_player_name()
	local privs = minetest.check_player_privs(name,{teleport=true,bring=true})
	if not privs then
		ctx.status = S("Missing privileges!")
	else
		local from_name = ctx.pnames[ctx.form.from]
		local from_player = minetest.get_player_by_name(from_name)
		if not from_player then
			ctx.status = S("Player @1 does not exist!",ctx.pnames[ctx.form.from])
			return true
		end
		local pos
		if ctx.provide_pos then
			pos = minetest.string_to_pos(ctx.form.pos)
		else
			local to_player = minetest.get_player_by_name(ctx.pnames_targetlist[ctx.form.to])
			if not to_player then
				ctx.status = S("Player @1 does not exist!",ctx.pnames_targetlist[ctx.form.to])
				return true
			end
			pos = to_player:get_pos()
		end
		from_player:set_pos(pos)
		local to_str = minetest.pos_to_string(vector.round(pos))
		minetest.log("action",("%s teleported %s to %s"):format(name,from_name,to_str))
		ctx.status = S("Teleported @1 to @2.",from_name,to_str)
		minetest.chat_send_player(name,ctx.status)
	end
	return true
end

local function to_func(player,ctx)
	print(ctx.form.to)
	if ctx.form.to == ctx.targetlist_length then
		ctx.provide_pos = true
	else
		ctx.provide_pos = false
	end
	return true
end

local menu = flow.make_gui(function(player,ctx)
	ctx.pnames = ctx.pnames or get_player_name_list()
	if not ctx.pnames_targetlist then
		ctx.pnames_targetlist = table.copy(ctx.pnames)
		table.insert(ctx.pnames_targetlist,S("Provide a Position"))
		ctx.targetlist_length = #ctx.pnames_targetlist
	end
	if not ctx.status then
		ctx.status = S("Idle")
	end

	if ctx.provide_pos then
		return gui.VBox {
			gui.HBox {
				gui.Textlist {
					h = 7, -- Optional
					w = 4,
					name = "from", -- Optional
					listelems = ctx.pnames,
				},
				gui.VBox {
					gui.Textlist {
						h = 6,
						w = 4,
						name = "to",
						on_event = to_func,
						listelems = ctx.pnames_targetlist,
					},
					gui.Field {
						w = 4, -- Optional
						h = 1, -- Optional
						name = "pos", -- Optional
						label = "",
						default = "(0,0,0)",
					},
				}
			},
			gui.HBox {
				gui.Label {
					label = ctx.status,
				},
				gui.Spacer{},
				gui.ButtonExit{label = S("Exit")},
				gui.Button{label = S("Teleport"),on_event = confirm_func},
			}
		}
	else
		return gui.VBox {
			gui.HBox {
				gui.Textlist {
					h = 7, -- Optional
					w = 4,
					name = "from", -- Optional
					listelems = ctx.pnames,
				},
				gui.Textlist {
					h = 7,
					w = 4,
					name = "to",
					on_event = to_func,
					listelems = ctx.pnames_targetlist,
				}
			},
			gui.HBox {
				gui.Label {
					label = ctx.status,
				},
				gui.Spacer{},
				gui.ButtonExit{label = S("Exit")},
				gui.Button{label = S("Teleport"),on_event = confirm_func},
			}
		}
	end
end)

local orig_tp_func = minetest.registered_chatcommands["teleport"].func

minetest.registered_chatcommands["teleport"].func = function(name,param)
	if param == "" then
		menu:show(name)
		return true, S("Teleport menu shown.")
	else
		return orig_tp_func(name,param)
	end
end

minetest.registered_chatcommands["teleport"].params = "[" .. minetest.registered_chatcommands["teleport"].params .. "]"

minetest.registered_chatcommands["teleport"].description = S("Teleport to position or player, or open the teleport menu if no params provided")
