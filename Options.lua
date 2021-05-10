local NAME, S = ...
local SCR = ScrollingChatText

local L = S.L
local profile
local chat, other, filter

function SCR:RefreshDB2()
	profile = self.db.profile
	chat = profile.chat
	other = profile.other
	filter = profile.filter
end

local pairs, ipairs = pairs, ipairs
local format = format

local args = {}

	--------------------------
	--- Example Timestamps ---
	--------------------------

local exampleTime = time({ -- FrameXML\InterfaceOptionsPanels.lua L1203 (4.3.4.15595)
	year = 2010,
	month = 12,
	day = 15,
	hour = 15,
	min = 27,
	sec = 32,
})

local xmpl_timestamps = {}

for i, v in ipairs(S.timestamps) do
	xmpl_timestamps[i] = BetterDate(v, exampleTime)
end

	--------------------
	--- Blizzard FCT ---
	--------------------

local testCache = {}
local testRange = {
	{48, 57}, -- numbers
	{65, 90}, -- uppercase letters
	{97, 122}, -- lowercase letters
	--{32, 32}, -- space
}

	----------------
	--- Defaults ---
	----------------

-- force updating COMBAT_TEXT_FLOAT_MODE and COMBAT_TEXT_LOCATIONS before we get our defaults
COMBAT_TEXT_FLOAT_MODE = GetCVar("floatingCombatTextFloatMode")
CombatText_UpdateDisplayedMessages()

S.defaults = {
	profile = {
		chat = {
			SAY = true,
			YELL = true,

			EMOTE = true,
			TEXT_EMOTE = true,

			CHANNEL1 = true, -- default General channel
			CHANNEL2 = true, -- default Trade channel

			WHISPER = true,
			WHISPER_INFORM = true, -- self
			BN_WHISPER = true,
			BN_WHISPER_INFORM = true, -- self

			GUILD = true,
			OFFICER = true,

			PARTY = true,
			PARTY_LEADER = true,

			RAID = true,
			RAID_LEADER = true,

			INSTANCE_CHAT = true,
			INSTANCE_CHAT_LEADER = true,
		},
		other = {},

		sink20OutputSink = "Blizzard",
		Message = "<ICON> [<TIME>] [<CHAN>] [<NAME>]: <MSG>",

		FilterSelf = true,
		TrimRealm = true,
		Split = true,

		filter = {
			Combat = true,
			NoCombat = true,

			Solo = true,
			Group = true,
		},

		Timestamp = 6, -- 15:27
		IconSize = 16,

		fct = {
			COMBAT_TEXT_SCALE = CombatText:GetScale(), -- can also just assign 1 maybe lol
			COMBAT_TEXT_SCROLLSPEED = COMBAT_TEXT_SCROLLSPEED,
			COMBAT_TEXT_FADEOUT_TIME = COMBAT_TEXT_FADEOUT_TIME,
			COMBAT_TEXT_LOCATIONS = CopyTable(COMBAT_TEXT_LOCATIONS),
		},
		color = {
			-- other colors get imported from defaults
			TIMESTAMP = {r = 0.67, g = 0.67, b = 0.67},
		},
	}
}

local defaults = S.defaults

-- copy custom/default class colors
for k, v in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
	defaults.profile.color[k] = {
		r = v.r,
		g = v.g,
		b = v.b,
	}
end

-- import default colors; avoid possibly tainting ChatTypeInfo
function SCR:GetChatTypeInfo()
	for _, v in ipairs(S.ColorOptions) do
		local color = ChatTypeInfo[v]
		defaults.profile.color[v] = {
			r = color.r,
			g = color.g,
			b = color.b,
		}
		if S.colorremap[v] then -- EMOTE, WHISPER, BN_WHISPER
			defaults.profile.color[S.colorremap[v]] = defaults.profile.color[v]
		end
	end

	-- global channels
	for i = 1, MAX_WOW_CHAT_CHANNELS do
		local color = ChatTypeInfo["CHANNEL"..i]
		defaults.profile.color["CHANNEL"..i] = {
			r = color.r,
			g = color.g,
			b = color.b,
		}
	end

	for _, v in ipairs(S.ColorOtherOptions) do
		v = (v == "ERRORS") and "FILTERED" or v -- dirty hack

		local color = ChatTypeInfo[v]
		defaults.profile.color[v] = {
			r = color.r,
			g = color.g,
			b = color.b,
		}
		-- special reverse case: ERRORS -> FILTERED -> ERRORS, RESTRICTED
		if S.colorremap[v] then
			for _, v2 in ipairs(S.colorremap[v]) do
				defaults.profile.color[v2] = defaults.profile.color.FILTERED
			end
		end
	end
end

	---------------
	--- Options ---
	---------------

S.options = {
	type = "group",
	childGroups = "tab",
	name = format("%s |cffADFF2F%s|r", NAME, GetAddOnMetadata(NAME, "Version")),
	args = {
		main = {
			type = "group", order = 1,
			name = GAMEOPTIONS_MENU,
			handler = SCR,
			get = function(i) return chat[i[#i]] end,
			set = function(i, v)
				chat[i[#i]] = v
				local remap = S.eventremap[i[#i]]
				if remap then
					if type(remap) == "table" then
						for _, event in ipairs(remap) do
							chat[event] = v
						end
					else
						chat[remap] = v
					end
				end
			end,
			args = {
				inline1 = {
					type = "group", order = 1,
					name = CHAT,
					inline = true,
					args = {}, -- populated later
				},
				inline2 = {
					type = "group", order = 2,
					name = CHANNELS,
					inline = true,
					args = {}, -- see Core.lua:CHANNEL_UI_UPDATE
				},
				LibSink = SCR:GetSinkAce3OptionsDataTable(),
				Message = {
					type = "input", order = 5,
					width = "full",
					name = "",
					get = "GetValue",
					set = "SetMessage",
				},
				Preview = {
					type = "description", order = 6,
					fontSize = "large",
					name = function()
						local raceFile = select(2, UnitRace("player"))
						local sex = UnitSex("player")
						local raceIcon = S.GetRaceIcon(raceFile, sex, 2, 3)
						local classFile = select(2, UnitClass("player"))
						local classIcon = S.GetClassIcon(classFile, -2, 3)
						args.icon = (profile.IconSize > 1) and raceIcon..classIcon or ""
						args.time = S.GetTimestamp()

						local chatType = ChatEdit_GetLastActiveWindow():GetAttribute("chatType")
						local channelTarget = ChatEdit_GetLastActiveWindow():GetAttribute("channelTarget")
						if not profile.color[chatType] then return "   |cffFF0000"..ERROR_CAPS.."|r: "..chatType end -- Error: RAID_WARNING, ...
						local chanColor = S.chatCache[chatType]
						args.chan = "|cff"..chanColor..(chatType == "CHANNEL" and channelTarget or L[chatType]).."|r"

						args.name = "|cff"..S.classCache[S.playerClass]..S.playerName.."|r"
						args.msg = "|cff"..chanColor..L.HELLO_WORLD.."|r"
						return "  "..SCR:ReplaceArgs(profile.Message, args)
					end,
				},
				spacing = {type = "description", order = 7, name = " "},
				inline3 = {
					type = "group", order = 8,
					name = COMBAT,
					inline = true,
					args = {}, -- populated later
				},
				inline4 = {
					type = "group", order = 9,
					name = PVP,
					inline = true,
					args = {},
				},
				inline5 = {
					type = "group", order = 10,
					name = OTHER,
					inline = true,
					args = {},
				},
				inline6 = {
					type = "group", order = 11,
					name = CREATURE_MESSAGES,
					inline = true,
					args = {},
				},
			},
		},
		advanced = {
			type = "group", order = 2,
			name = ADVANCED_LABEL,
			handler = SCR,
			get = "GetValue",
			set = "SetValue",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = " ",
					inline = true,
					args = {
						FilterSelf = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							name = L.OPTION_FILTER_SELF,
						},
						TrimRealm = {
							type = "toggle", order = 2,
							width = "full", descStyle = "",
							name = L.OPTION_TRIM_REALM_NAME,
						},
						ColorMessage = {
							type = "toggle", order = 3,
							width = "full", descStyle = "",
							name = L.OPTION_COLOR_MESSAGE,
						},
						Split = {
							type = "toggle", order = 4,
							width = "full", descStyle = "",
							name = L.OPTION_TRIM_MESSAGE,
						},
						ParentCombatText = {
							type = "toggle", order = 5,
							width = "full",
							name = L.OPTION_REPARENT_COMBAT_TEXT,
							set = function(i, v)
								profile[i[#i]] = v
								CombatText:SetParent(v and WorldFrame or UIParent)
							end,
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = L.OPTION_GROUP_SHOW_WHEN,
					inline = true,
					get = function(i) return filter[i[#i]] end,
					set = function(i, v) filter[i[#i]] = v end,
					args = {
						Combat = {
							type = "toggle", order = 1,
							descStyle = "",
							name = "|cffFF0000"..COMBAT.."|r",
						},
						NoCombat = {
							type = "toggle", order = 2,
							descStyle = "",
							name = L.OPTION_SHOW_NOTINCOMBAT,
						},
						header = {type = "header", order = 3, name = ""},
						Solo = {
							type = "toggle", order = 4,
							descStyle = "",
							name = SOLO,
						},
						Group = {
							type = "toggle", order = 5,
							descStyle = "",
							name = "|cffA8A8FF"..GROUP.."|r",
						},
					},
				},
				Timestamp = {
					type = "select", order = 3,
					desc = OPTION_TOOLTIP_TIMESTAMPS,
					values = xmpl_timestamps,
					name = " "..TIMESTAMPS_LABEL,
				},
				IconSize = {
					type = "select", order = 4,
					descStyle = "",
					values = {},
					name = " "..L.OPTION_ICON_SIZE,
					set = function(i, v)
						profile[i[#i]] = v
						wipe(S.raceIconCache)
						wipe(S.classIconCache)
					end,
				},
			},
		},
		colors = {
			type = "group", order = 3,
			name = COLORS,
			handler = SCR,
			get = "GetValueColor",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = CLASS,
					inline = true,
					set = "SetValueColorClass",
					args = {},
				},
				inline2 = {
					type = "group", order = 2,
					name = CHAT,
					inline = true,
					set = "SetValueColorChat",
					args = {
						TIMESTAMP = {
							type = "color", order = -1,
							name =  TIMESTAMPS_LABEL,
						}
					},
				},
				inline3 = {
					type = "group", order = 3,
					name = CHANNELS,
					inline = true,
					set = "SetValueColorChat",
					args = {
					},
				},
				inline4 = {
					type = "group", order = 4,
					name = OTHER,
					inline = true,
					set = "SetValueColorChat",
					args = {},
				},
				Reset = {
					type = "execute", order = 5,
					descStyle = "",
					name = RESET,
					confirm = true, confirmText = RESET_TO_DEFAULT.."?",
					func = function()
						-- self note: defaults already accounts for the ERRORS special case
						for k, v in pairs(defaults.profile.color) do
							profile.color[k] = {
								r = v.r,
								g = v.g,
								b = v.b,
							}
						end
						SCR:WipeCache()
					end,
				},
			},
		},
		fct = {
			type = "group", order = 4,
			--name = assigned later
			desc = FLOATING_COMBATTEXT_LABEL,
			handler = SCR,
			get = "GetValue",
			set = "SetValue",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = "|cff3FBF3F"..SPEED.."|r",
					inline = true,
					-- would so name this SCR.GetGlobal if it wasnt anonymous
					get = function(i) return _G[i[#i]] end,
					args = {
						COMBAT_TEXT_SCROLLSPEED = {
							type = "range", order = 1,
							descStyle = "",
							name = L.OPTION_FCT_SCROLLSPEED,
							min = 0, softMin = 1,
							max = 20, softMax = 10,
							step = .1,
							set = function(i, v)
								COMBAT_TEXT_SCROLLSPEED = v
								S.options.args.fct.args.inline1.args.COMBAT_TEXT_FADEOUT_TIME.max = v
								if COMBAT_TEXT_FADEOUT_TIME > v then
									COMBAT_TEXT_FADEOUT_TIME = v
								end
								profile.fct.COMBAT_TEXT_SCROLLSPEED = v
							end,
						},
						COMBAT_TEXT_FADEOUT_TIME = {
							type = "range", order = 2,
							descStyle = "",
							name = L.OPTION_FCT_FADEOUT_TIME,
							min = 0,
							max = COMBAT_TEXT_SCROLLSPEED,
							step = .1,
							set = function(i, v)
								COMBAT_TEXT_FADEOUT_TIME = v
								profile.fct.COMBAT_TEXT_FADEOUT_TIME = v
							end,
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = "|cff3FBF3F"..L.OPTION_FCT_POSITION.."|r |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:1|t",
					inline = true,
					args = {
						COMBAT_TEXT_SCALE = {
							type = "range", order = 1,
							width = "double", descStyle = "",
							name = "|cff71D5FF"..L.OPTION_FCT_SCALE.."|r",
							min = .1,
							max = 5, softMax = 2,
							step = .1,
							-- using SetFont and COMBAT_TEXT_HEIGHT was too troublesome ..
							get = function(i) return CombatText:GetScale() end,
							set = function(i, v)
								CombatText:SetScale(v)
								profile.fct.COMBAT_TEXT_SCALE = v
							end,
						},
						newline1 = {type = "description", order = 2, name = ""},
						startX = {
							type = "range", order = 3,
							width = "double", descStyle = "",
							name = "|cffFFFFFFX|r "..START,
							min = -2000, softMin = -500,
							max = 2000, softMax = 500,
							step = 1,
							get = function(i) return COMBAT_TEXT_LOCATIONS.startX end,
							set = function(i, v)
								COMBAT_TEXT_LOCATIONS.startX = v
								profile.fct.COMBAT_TEXT_LOCATIONS.startX = v
							end,
						},
						endX = {
							type = "range", order = 4,
							width = "double", descStyle = "",
							name = "|cffFFFFFFX|r "..L.OPTION_FCT_END,
							min = -2000, softMin = -500,
							max = 2000, softMax = 500,
							step = 1,
							get = function(i) return COMBAT_TEXT_LOCATIONS.endX end,
							set = function(i, v)
								COMBAT_TEXT_LOCATIONS.endX = v
								profile.fct.COMBAT_TEXT_LOCATIONS.endX = v
							end,
						},
						newline2 = {type = "description", order = 5, name = ""},
						startY = {
							type = "range", order = 6,
							width = "double", descStyle = "",
							name = "|cffFFFFFFY|r "..START,
							min = -2000, softMin = 0,
							max = 2000, softMax = 1000,
							step = 1,
							get = function(i) return COMBAT_TEXT_LOCATIONS.startY end,
							set = function(i, v)
								COMBAT_TEXT_LOCATIONS.startY = v
								profile.fct.COMBAT_TEXT_LOCATIONS.startY = v
							end,
						},
						endY = {
							type = "range", order = 7,
							width = "double", descStyle = "",
							name = "|cffFFFFFFY|r "..L.OPTION_FCT_END,
							min = -2000, softMin = 0,
							max = 2000, softMax = 1000,
							step = 1,
							get = function(i) return COMBAT_TEXT_LOCATIONS.endY end,
							set = function(i, v)
								COMBAT_TEXT_LOCATIONS.endY = v
								profile.fct.COMBAT_TEXT_LOCATIONS.endY = v
							end,
						},
						desc = {
							type = "description",
							fontSize = "large",
							order = 8,
							name = function()
								return format("\n\206\148 X = |cffCC66CC%d|r\n\206\148 Y = |cffCC66CC%d|r", COMBAT_TEXT_LOCATIONS.endX - COMBAT_TEXT_LOCATIONS.startX, COMBAT_TEXT_LOCATIONS.endY - COMBAT_TEXT_LOCATIONS.startY)
							end,
						},
					},
				},
				test = {
					type = "execute", order = 6,
					descStyle = "",
					name = function() return format("|cffFFFFFF%s|r", S.Test and "|TInterface\\TimeManager\\ResetButton:24|t Stop Test" or "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:24|t Start Test") end,
					func = function()
						S.Test = not S.Test
						if S.Test then
							S.TestTimer = C_Timer.NewTicker(1, function()
								-- just output a bunch of randomized characters
								for i = 1, random(75) do
									testCache[i] = strchar(random(unpack(testRange[random(3)])))
								end

								SCR:Pour("|cffFFFF00Test:|r "..table.concat(testCache))
								wipe(testCache)
							end)
						else
							S.TestTimer:Cancel()
						end
					end,
				},
				reset = {
					type = "execute", order = 7,
					descStyle = "",
					name = RESET,
					confirm = true, confirmText = RESET_TO_DEFAULT.."?",
					func = function()
						for k, v in pairs(profile.fct) do
							if type(v) == "table" then -- COMBAT_TEXT_LOCATIONS
								for k2, v2 in pairs(defaults.profile.fct[k]) do
									_G[k][k2] = v2
									v[k2] = v2
								end
							else
								profile.fct[k] = defaults.profile.fct[k]
								if k == "COMBAT_TEXT_SCALE" then
									CombatText:SetScale(defaults.profile.fct[k])
								else
									_G[k] = defaults.profile.fct[k]
								end
							end
						end
					end,
				},
			},
		},
	},
}

local options = S.options

	---------------
	--- Methods ---
	---------------

function SCR:GetValue(i)
	return profile[i[#i]]
end

function SCR:SetValue(i, v)
	profile[i[#i]] = v
end

function SCR:GetValueOther(i)
	return other[i[#i]]
end

function SCR:SetValueOther(i, v)
	other[i[#i]] = v

	-- (un)register according to options
	local event = S.OtherEvents[i[#i]]
	local reg = v and "RegisterEvent" or "UnregisterEvent"

	if type(event) == "table" then
		for _, subevent in pairs(event) do
			self[reg](self, subevent, "CHAT_MSG_OTHER")
		end
	else
		self[reg](self, event, "CHAT_MSG_OTHER")
	end
end

function SCR:GetValueColor(i)
	local c = profile.color[i[#i]]
	return c.r, c.g, c.b
end

function SCR:SetValueColor(i, r, g, b)
	local c = profile.color[i[#i]]
	c.r = r
	c.g = g
	c.b = b

	local group = S.colorremap[i[#i]]
	if not group then return end

	if type(group) == "table" then -- special reverse case: ERRORS
		for _, v in ipairs(group) do
			profile.color[v] = c
		end
	else
		profile.color[group] = c
	end
end

function SCR:SetValueColorClass(...)
	wipe(S.classCache)
	self:SetValueColor(...)
end

function SCR:SetValueColorChat(...)
	wipe(S.chatCache)
	self:SetValueColor(...)
end

function SCR:SetMessage(i, v)
	profile[i[#i]] = (v:trim() == "") and defaults.profile[i[#i]] or v
end

	---------------------
	--- Options: Main ---
	---------------------

do
	local chat = {
		[1] = "SAY",
		[4] = "YELL",
		[7] = "EMOTE",
		[10] = "ACHIEVEMENT",

		[2] = "GUILD",
		[5] = "OFFICER",
		[8] = "WHISPER",
		[11] = "BN_WHISPER",

		[3] = "PARTY",
		[6] = "RAID",
		[9] = "INSTANCE_CHAT",
	}

	local chatGroup = options.args.main.args.inline1.args

	for i, v in ipairs(chat) do
		local v2 = (v == "ACHIEVEMENT") and "ACHIEVEMENTS" or v -- exception
		chatGroup[v] = {
			type = "toggle", order = i,
			descStyle = "",
			name = function() return format("|cff%s%s|r", S.chatCache[v], _G[v2]) end,
		}
	end
end

	----------------------------
	--- LibSink monkey patch ---
	----------------------------

-- also affects other addons ofcourse ..
do
	local LibSink = options.args.main.args.LibSink
	LibSink.inline = true
	LibSink.order = 4

	-- use "Blizzard FCT" translation for option
	options.args.fct.name = LibSink.args.Blizzard.name

	-- dont let libsink hide the Blizzard FCT option
	LibSink.args.Blizzard.hidden = nil
end

	----------------------
	--- Options: Other ---
	----------------------

do
	-- kinda same table, different key grouping
	local otherChat = {
		[1] = { -- COMBAT
			[1] = "COMBAT_XP_GAIN",
			[4] = "COMBAT_HONOR_GAIN",
			[7] = "COMBAT_FACTION_CHANGE",
			[10] = "SKILL",

			[2] = "LOOT",
			[5] = "CURRENCY",
			[8] = "MONEY",
			[11] = "TRADESKILLS",

			[3] = "OPENING",
			[6] = "PET_INFO",
			[9] = "COMBAT_MISC_INFO",
		},
		[2] = { -- PVP
			"BG_SYSTEM_HORDE",
			"BG_SYSTEM_ALLIANCE",
			"BG_SYSTEM_NEUTRAL",
		},
		[3] = { -- OTHER
			[1] = "SYSTEM",
			[4] = "ERRORS", -- special: "FILTERED", "RESTRICTED"
			[7] = "IGNORED",

			[2] = "CHANNEL",
			[5] = "TARGETICONS",
			[8] = "BN_INLINE_TOAST_ALERT",

			[3] = "PET_BATTLE_COMBAT_LOG",
			[6] = "PET_BATTLE_INFO",
		},
		[4] = { -- CREATURE_MESSAGES
			[1] = "MONSTER_SAY",
			[4] = "MONSTER_EMOTE",

			[2] = "MONSTER_YELL",
			[5] = "MONSTER_WHISPER",

			[3] = "RAID_BOSS_EMOTE",
			[6] = "RAID_BOSS_WHISPER",

		},
	}

	for i1, v1 in ipairs(otherChat) do
		local group = options.args.main.args["inline"..i1+2].args

		for i2, v2 in ipairs(v1) do
			group[v2] = {
				type = "toggle", order = i2,
				width = "normal", descStyle = "",
				name = function() return format("|cff%s%s|r", S.chatCache[v2], S.otherremap[v2] or _G[v2] or v2) end,
				get = "GetValueOther",
				set = "SetValueOther",
			}
		end
	end
end

	----------------
	--- Advanced ---
	----------------

do
	local iconSize = options.args.advanced.args.IconSize.values

	for i = 8, 32, 2 do
		iconSize[i] = i
	end
	iconSize[1] = NONE
end

	--------------
	--- Colors ---
	--------------

do
	local class = options.args.colors.args.inline1.args

	if CUSTOM_CLASS_COLORS then
		class.notification = {
			type = "description",
			fontSize = "large",
			name = L.USE_CLASS_COLORS,
		}
	else
		for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			class[k] = {
				type = "color",
				name = v,
			}
		end
	end
end

do
	local chat = options.args.colors.args.inline2.args

	local chatremap = {
		CHAT_MSG_CHANNEL = CHANNEL, -- no globalstring
		CHAT_MSG_WHISPER = WHISPER, -- not preferable globalstring
	}

	for i, v in ipairs(S.ColorOptions) do
		chat[v] = {
			type = "color",
			order = i,
			name = chatremap[v] or _G[v] or v,
		}
	end
end

do
	local chan = options.args.colors.args.inline3.args

	for i = 1, MAX_WOW_CHAT_CHANNELS do
		chan["CHANNEL"..i] = {
			type = "color",
			order = i,
			name = function() return format("%s. %s", i, S.channels[i] or "") end,
			hidden = function()
				if not S.channels[i] then
					return true
				end
			end,
		}
	end
end

do
	local other = options.args.colors.args.inline4.args

	for i, v in ipairs(S.ColorOtherOptions) do
		other[v] = {
			type = "color",
			order = i,
			name = S.otherremap[v] or _G[v] or v,
		}
	end
end
