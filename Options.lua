local NAME, S = ...
local SCR = ScrollingChatText

local LSM = LibStub("LibSharedMedia-3.0")

local L = S.L
local profile

function SCR:RefreshDB2()
	profile = self.db.profile
end

local pairs, ipairs = pairs, ipairs
local format, gsub = format, gsub

	--------------------------
	--- Example Timestamps ---
	--------------------------

local exampleTime = time({ -- FrameXML\InterfaceOptionsPanels.lua L1203 (4.3.3.15354)
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

	----------------
	--- Defaults ---
	----------------

S.defaults = {
	profile = {
		SAY = true,
		YELL = true,
		
		EMOTE = true,
		TEXT_EMOTE = true,
		
		CHANNEL1 = true, -- default General channel
		CHANNEL2 = true, -- default Trade channel
		
		WHISPER = true,
		BN_WHISPER = true,
		BN_CONVERSATION = true,
		
		GUILD = true,
		OFFICER = true,
		
		PARTY = true,
		PARTY_LEADER = true,
		
		RAID = true,
		RAID_LEADER = true,
		
		BATTLEGROUND = true,
		BATTLEGROUND_LEADER = true,
		
		sink20OutputSink = "Blizzard",
		Message = "<ICON> [<TIME>] [<CHAN>] [<NAME>]: <MSG>",
		LevelMessage = "<ICON> [<CHAN>] [<NAME>]: "..LEVEL.." <LEVEL>",
		
		FilterSelf = true,
		TrimRealm = true,
		
		InCombat = true,
		NotInCombat = true,
		
		Timestamp = 6, -- 15:27
		IconSize = 16,
		Font = LSM:GetDefault(LSM.MediaType.FONT),
		FontSize = 16,
		
		color = {
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

-- copy default channels colors; avoid possibly tainting ChatTypeInfo
function SCR:GetChatTypeInfo()
	for _, v in ipairs(S.ColorEvents) do
		local color = ChatTypeInfo[v]
		defaults.profile.color[v] = {
			r = color.r,
			g = color.g,
			b = color.b,
		}
		if S.colorremap[v] then -- EMOTE -> TEXT_EMOTE
			defaults.profile.color[S.colorremap[v]] = defaults.profile.color[v]
		end
	end
end

	---------------
	--- Options ---
	---------------

local args = {}
local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]

S.options = {
	type = "group",
	childGroups = "tab",
	get = "GetValue",
	set = "SetValue",
	name = format("%s |cffADFF2Fv%s|r", NAME, S.VERSION),
	args = {
		main = {
			type = "group", order = 1,
			name = L.OPTION_TAB_MAIN,
			handler = SCR,
			get = "GetValue",
			set = "SetValue",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = CHAT,
					inline = true,
					args = {
						SAY = {
							type = "toggle", order = 1,
							descStyle = "",
							name = " "..CHAT_MSG_SAY,
						},
						YELL = {
							type = "toggle", order = 4,
							descStyle = "",
							name = " |cffFF4040"..YELL.."|r",
						},
						EMOTE = {
							type = "toggle", order = 7,
							descStyle = "",
							name = " |cffFF8040"..EMOTE.."|r",
						},
						PARTY = {
							type = "toggle", order = 2,
							descStyle = "",
							name = " |cffA8A8FF"..PARTY.."|r",
						},
						RAID = {
							type = "toggle", order = 5,
							descStyle = "",
							name = " |cffFF7F00"..RAID.."|r",
						},
						BATTLEGROUND = {
							type = "toggle", order = 8,
							descStyle = "",
							name = " |cffFF7F00"..BATTLEGROUND.."|r",
						},
						WHISPER = {
							type = "toggle", order = 3,
							descStyle = "",
							name = " |cffFF80FF"..WHISPER.."|r",
						},
						GUILD = {
							type = "toggle", order = 6,
							descStyle = "",
							name = " |cff40FF40"..GUILD.."|r",
						},
						ACHIEVEMENT = {
							type = "toggle", order = 9,
							descStyle = "",
							name = " |cffFFFF00"..ACHIEVEMENTS.."|r",
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = CHANNELS,
					inline = true,
					args = {},
				},
				Reminder = {
					type = "description", order = 3,
					fontSize = "large",
					name = "\n |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:16:16:2:5|t |cff71D5FF["..COMBAT_TEXT_LABEL.."]|r |cffFF0000"..VIDEO_OPTIONS_DISABLED.."|r",
					hidden = function()
						if SHOW_COMBAT_TEXT == "1" then return true end
						for _, v in pairs(S.CombatTextEnabled) do
							if v then
								return true
							end
						end
					end,
				},
				LibSink = SCR:GetSinkAce3OptionsDataTable(),
				Message = {
					type = "input", order = 5,
					width = "full",
					name = "",
					set = "SetMessage",
				},
				Preview = {
					type = "description", order = 6,
					fontSize = "large",
					name = function()
						local raceIcon = S.GetRaceIcon(strupper(select(2, UnitRace("player"))).."_"..S.sexremap[UnitSex("player")], 1, 3)
						local classIcon = S.GetClassIcon(select(2, UnitClass("player")), 2, 3)
						args.icon = (profile.IconSize > 1) and raceIcon..classIcon or ""
						args.time = S.GetTimestamp()
						
						local chatType = ChatEdit_GetLastActiveWindow():GetAttribute("chatType")
						local channelTarget = ChatEdit_GetLastActiveWindow():GetAttribute("channelTarget")
						if not profile.color[chatType] then return "   |cffFF0000"..ERROR_CAPS.."|r: "..chatType end -- Error: RAID_WARNING, ...
						local chanColor = S.chanCache[chatType]
						args.chan = "|cff"..chanColor..(chatType == "CHANNEL" and channelTarget or L[chatType]).."|r"
						
						args.name = "|cff"..S.classCache[S.playerClass]..S.playerName.."|r"
						args.msg = "|cff"..chanColor..L.HELLO_WORLD.."|r"
						return "  "..SCR:ReplaceArgs(profile.Message, args)
					end,
				},
			},
		},
		options = {
			type = "group", order = 2,
			name = GAMEOPTIONS_MENU,
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
						},
						ParentCombatText = {
							type = "toggle", order = 5,
							width = "full",
							name = L.OPTION_REPARENT_COMBAT_TEXT,
							set = function(i, v)
								profile[i[#i]] = v
								if CombatText then
									CombatText:SetParent(v and WorldFrame or UIParent)
								end
							end,
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = L.OPTION_GROUP_SHOW_WHEN,
					inline = true,
					args = {
						InCombat = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							name = L.OPTION_SHOW_INCOMBAT,
						},
						NotInCombat = {
							type = "toggle", order = 2,
							width = "full", descStyle = "",
							name = L.OPTION_SHOW_NOTINCOMBAT,
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
				},
				newline = {type = "description", order = 5, name = ""},
				Font = {
					type = "select", order = 6,
					descStyle = "",
					values = LSM:HashTable("font"),
					dialogControl = "LSM30_Font",
					name = " "..L.OPTION_FONT.." |cffFF0000(NYI)|r",
				},
				FontSize = {
					type = "select", order = 7,
					descStyle = "",
					values = {},
					name = " "..FONT_SIZE.." |cffFF0000(NYI)|r",
				},
			},
		},
		colors = {
			type = "group", order = 3,
			name = COLORS,
			handler = SCR,
			args = {
				inline1 = {
					type = "group", order = 1,
					name = CLASS,
					inline = true,
					args = {},
				},
				inline2 = {
					type = "group", order = 2,
					name = CHANNEL,
					inline = true,
					args = {},
				},
				inline3 = {
					type = "group", order = 3,
					name = OTHER,
					inline = true,
					args = {
						TIMESTAMP = {
							type = "color", order = 1,
							name = TIMESTAMPS_LABEL,
							get = "GetValueColor",
							set = "SetValueColorChannel",
						},
					},
				},
				Reset = {
					type = "execute", order = 4,
					descStyle = "",
					name = RESET,
					func = function()
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
		extra = {
			type = "group", order = 4,
			name = L.OPTION_TAB_EXTRA,
			handler = SCR,
			get = "GetValue",
			set = "SetValueLevel",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = " "..L.OPTION_GROUP_LEVELUP,
					inline = true,
					args = {
						LevelParty = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							name = "|cffA8A8FF"..PARTY.."|r",
						},
						LevelRaid = {
							type = "toggle", order = 2,
							width = "full", descStyle = "",
							name = "|cffFF7F00"..RAID.."|r",
						},
						LevelGuild = {
							type = "toggle", order = 3,
							width = "full", descStyle = "",
							name = "|cff40FF40"..GUILD.."|r",
						},
						LevelFriend = {
							type = "toggle", order = 4,
							width = "full", descStyle = "",
							name = FRIENDS_WOW_NAME_COLOR_CODE..FRIENDS.."|r",
						},
						LevelFriendBnet = {
							type = "toggle", order = 5,
							width = "full", descStyle = "",
							name = FRIENDS_BNET_NAME_COLOR_CODE..BATTLENET_FRIEND.."|r",
						},
					},
				},
				LevelMessage = {
					type = "input", order = 2,
					width = "full",
					name = "",
					set = "SetMessage",
				},
				Preview = {
					type = "description", order = 3,
					fontSize = "large",
					name = function()
						local raceIcon = S.GetRaceIcon(strupper(select(2, UnitRace("player"))).."_"..S.sexremap[UnitSex("player")], 1, 3)
						local classIcon = S.GetClassIcon(select(2, UnitClass("player")), 2, 3)
						args.icon = (profile.IconSize > 1) and raceIcon..classIcon or ""
						args.time = S.GetTimestamp()
						args.chan = GetNumRaidMembers() > 0 and "|cffFF7F00"..RAID.."|r" or "|cffA8A8FF"..PARTY.."|r"
						args.name = "|cff"..S.classCache[S.playerClass]..S.playerName.."|r"
						local playerLevel = UnitLevel("player")
						args.level = "|cffADFF2F"..playerLevel + (playerLevel == maxLevel and 0 or 1).."|r"
						return "  "..SCR:ReplaceArgs(profile.LevelMessage, args)
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
	local remap = S.eventremap[i[#i]]
	if remap then
		if type(remap) == "table" then
			for _, event in ipairs(remap) do
				profile[event] = v
			end
		else
			profile[remap] = v
		end
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
	if S.colorremap[i[#i]] then
		profile.color[S.colorremap[i[#i]]] = c
	end
end

function SCR:SetValueColorClass(...)
	wipe(S.classCache)
	self:SetValueColor(...)
end

function SCR:SetValueColorChannel(...)
	wipe(S.chanCache)
	self:SetValueColor(...)
end

function SCR:SetMessage(i, v)
	profile[i[#i]] = (v:trim() == "") and defaults.profile[i[#i]] or v
	for k in gmatch(v, "%b<>") do
		local s = strlower(gsub(k, "[<>]", ""))
		if not S.validateMsg[s] then
			self:Print(ERROR_CAPS..": |cffFFFF00"..k.."|r")
		end
	end
end

	----------------------------
	--- LibSink monkey patch ---
	----------------------------

do
	local LibSink = options.args.main.args.LibSink
	LibSink.inline = true
	LibSink.order = 4
	
	-- use "Blizzard FCT" translation for option, and then color the name blue or gray in LibSink options
	local nameBlizzard = LibSink.args.Blizzard.name
	options.args.options.args.inline1.args.Split.name = "|cff71D5FF["..nameBlizzard.."]|r "..L.OPTION_TRIM_MESSAGE
	
	local funcBlizzard = function()
		return "|cff"..(SHOW_COMBAT_TEXT == "1" and "71D5FF" or "979797")..nameBlizzard.."|r"
	end
	
	for i, v in ipairs({"Blizzard", "MikSBT", "Parrot", "SCT"}) do
		LibSink.args[v].name = (v == "Blizzard") and funcBlizzard or "|cff71D5FF"..LibSink.args[v].name.."|r"
		LibSink.args[v].order = i
	end
	
	-- disabled instead of hidden; little bit confusing me now
	LibSink.args.Blizzard.disabled = LibSink.args.Blizzard.hidden
	LibSink.args.Blizzard.hidden = nil
end

	---------------
	--- Options ---
	---------------

do
	local iconSize = options.args.options.args.IconSize.values
	
	for i = 8, 32, 2 do
		iconSize[i] = i
	end
	iconSize[1] = NONE
	
	local fontSize = options.args.options.args.FontSize.values
	
	for i = 2, 32, 2 do
		fontSize[i] = i
	end
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
				get = "GetValueColor",
				set = "SetValueColorClass",
			}
		end
	end
	
	local chanremap = {
		CHAT_MSG_CHANNEL = CHANNEL, -- no globalstring
		CHAT_MSG_WHISPER = WHISPER, -- not preferable globalstring
	}
	
	local channel = options.args.colors.args.inline2.args
	
	for i, v in ipairs(S.ColorEvents) do
		channel[v] = {
			type = "color",
			order = i*2,
			name = chanremap[v] or _G[v] or v,
			get = "GetValueColor",
			set = "SetValueColorChannel",
		}
	end
end
