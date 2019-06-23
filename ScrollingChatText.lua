-- Author: Ketho (EU-Boulderfist)
-- License: Public Domain

-- To Do:
-- # Some kind of filtering against spam

local NAME, S = ...

-- ScrollingChatText abbreviates to SCR in order to avoid confusion with SCT (ScrollingCombatText)
ScrollingChatText = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceEvent-3.0", "AceConsole-3.0", "LibSink-2.0")
local SCR = ScrollingChatText
SCR.S = S -- debug purpose

local profile

function SCR:RefreshDB1()
	profile = self.db.profile
end

local pairs, ipairs = pairs, ipairs
local format = format

S.playerName = UnitName("player")
S.playerGUID = UnitGUID("player")
S.playerClass = select(2, UnitClass("player"))

	--------------
	--- Events ---
	--------------

S.events = {
	CHAT_MSG = {
		"CHAT_MSG_SAY",
		"CHAT_MSG_YELL",
		"CHAT_MSG_CHANNEL",
		"CHAT_MSG_COMMUNITIES_CHANNEL",
		"CHAT_MSG_WHISPER",
		"CHAT_MSG_WHISPER_INFORM", -- self
		"CHAT_MSG_GUILD",
		"CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY",
		"CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_INSTANCE_CHAT",
		"CHAT_MSG_INSTANCE_CHAT_LEADER",
	},
	CHAT_MSG_BN = {
		"CHAT_MSG_BN_WHISPER",
		"CHAT_MSG_BN_WHISPER_INFORM", -- self
	},
	CHAT_MSG_STATIC = {
		"CHAT_MSG_EMOTE",
		"CHAT_MSG_TEXT_EMOTE",
		"CHAT_MSG_ACHIEVEMENT",
		"CHAT_MSG_GUILD_ACHIEVEMENT",
	},
	-- entering/leaving combat
	PLAYER_REGEN = {
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
	},
}

-- event groups
S.eventremap = {
	ACHIEVEMENT = "GUILD_ACHIEVEMENT",
	INSTANCE_CHAT = "INSTANCE_CHAT_LEADER",
	EMOTE = "TEXT_EMOTE",
	--GUILD = "OFFICER", -- OFFICER is now standalone
	PARTY = "PARTY_LEADER",
	RAID = "RAID_LEADER", -- left out RAID_WARNING
	WHISPER = "WHISPER_INFORM",
	BN_WHISPER = "BN_WHISPER_INFORM",
}

-- sourceName in these events are the same as destName
S.INFORM = {
	CHAT_MSG_WHISPER_INFORM = true,
	CHAT_MSG_BN_WHISPER_INFORM = true,
}

S.CHANNEL = {
	CHANNEL = true,
	COMMUNITIES_CHANNEL = true,
}

	--------------------
	--- Other Events ---
	--------------------

S.OtherEvents = {
	-- COMBAT
	COMBAT_XP_GAIN = "CHAT_MSG_COMBAT_XP_GAIN",
	COMBAT_HONOR_GAIN = "CHAT_MSG_COMBAT_HONOR_GAIN",
	COMBAT_FACTION_CHANGE = "CHAT_MSG_COMBAT_FACTION_CHANGE",
	SKILL = "CHAT_MSG_SKILL",
	LOOT = "CHAT_MSG_LOOT",
	CURRENCY = "CHAT_MSG_CURRENCY",
	MONEY = "CHAT_MSG_MONEY",
	TRADESKILLS = "CHAT_MSG_TRADESKILLS",
	OPENING = "CHAT_MSG_OPENING",
	PET_INFO = "CHAT_MSG_PET_INFO",
	COMBAT_MISC_INFO = "CHAT_MSG_COMBAT_MISC_INFO",
	
	-- PVP
	BG_SYSTEM_HORDE = "CHAT_MSG_BG_SYSTEM_HORDE",
	BG_SYSTEM_ALLIANCE = "CHAT_MSG_BG_SYSTEM_ALLIANCE",
	BG_SYSTEM_NEUTRAL = "CHAT_MSG_BG_SYSTEM_NEUTRAL",
	
	-- OTHER
	SYSTEM = "CHAT_MSG_SYSTEM", -- TIME_PLAYED_MSG, PLAYER_LEVEL_UP, etc belong to the SYSTEM group
	ERRORS = { -- special case
		"CHAT_MSG_FILTERED",
		"CHAT_MSG_RESTRICTED"
	},
	IGNORED = "CHAT_MSG_IGNORED",
	CHANNEL = {
		"CHAT_MSG_CHANNEL_JOIN",
		"CHAT_MSG_CHANNEL_LEAVE",
		"CHAT_MSG_CHANNEL_NOTICE",
		"CHAT_MSG_CHANNEL_NOTICE_USER",
		"CHAT_MSG_CHANNEL_LIST",
	},
	TARGETICONS = "CHAT_MSG_TARGETICONS",
	BN_INLINE_TOAST_ALERT = {
		"CHAT_MSG_BN_INLINE_TOAST_ALERT",
		"CHAT_MSG_BN_INLINE_TOAST_BROADCAST",
		"CHAT_MSG_BN_INLINE_TOAST_BROADCAST_INFORM",
	},
	-- added in 5.0.4
	PET_BATTLE_COMBAT_LOG = "CHAT_MSG_PET_BATTLE_COMBAT_LOG",
	PET_BATTLE_INFO = "CHAT_MSG_PET_BATTLE_INFO",
	
	-- CREATURE_MESSAGES
	MONSTER_SAY = "CHAT_MSG_MONSTER_SAY",
	MONSTER_EMOTE = "CHAT_MSG_MONSTER_EMOTE",
	MONSTER_YELL = "CHAT_MSG_MONSTER_YELL",
	MONSTER_WHISPER = "CHAT_MSG_MONSTER_WHISPER",
	RAID_BOSS_EMOTE = "CHAT_MSG_RAID_BOSS_EMOTE",
	RAID_BOSS_WHISPER = "CHAT_MSG_RAID_BOSS_WHISPER",
}

-- still a work in progress
-- Blizzard logic in FrameXML\ChatFrame.lua
S.OtherSubEvents = {
	CHAT_MSG_CHANNEL_NOTICE = {
		YOU_CHANGED = CHAT_YOU_CHANGED_NOTICE,
		YOU_JOINED = CHAT_YOU_JOINED_NOTICE,
		YOU_LEFT = CHAT_YOU_LEFT_NOTICE,
		SUSPENDED = CHAT_SUSPENDED_NOTICE,
	},
	CHAT_MSG_CHANNEL_NOTICE_USER = {
		OWNER_CHANGED = CHAT_OWNER_CHANGED_NOTICE,
		SET_MODERATOR = CHAT_SET_MODERATOR_NOTICE,
		UNSET_MODERATOR_NOTICE = CHAT_UNSET_MODERATOR_NOTICE,
	},
	CHAT_MSG_BN_INLINE_TOAST_ALERT = {
		--BROADCAST = BN_INLINE_TOAST_BROADCAST, -- 2 args
		--BROADCAST_INFORM = BN_INLINE_TOAST_BROADCAST_INFORM, -- no args
		--FRIEND_ADDED = BN_INLINE_TOAST_FRIEND_ADDED,
		FRIEND_OFFLINE = BN_INLINE_TOAST_FRIEND_OFFLINE,
		FRIEND_ONLINE = BN_INLINE_TOAST_FRIEND_ONLINE,
		--FRIEND_PENDING = BN_INLINE_TOAST_FRIEND_PENDING, -- 1 number arg
		--FRIEND_REMOVED = BN_INLINE_TOAST_FRIEND_REMOVED,
		--FRIEND_REQUEST = BN_INLINE_TOAST_FRIEND_REQUEST, -- no args
	},
	
	CHAT_MSG_CHANNEL_JOIN = CHAT_CHANNEL_JOIN_GET,
	CHAT_MSG_CHANNEL_LEAVE = CHAT_CHANNEL_LEAVE_GET,
}

S.MONSTER_EMOTE = {
	CHAT_MSG_MONSTER_EMOTE = true,
	CHAT_MSG_RAID_BOSS_EMOTE = true,
}

S.MONSTER_CHAT = {
	CHAT_MSG_MONSTER_SAY = CHAT_MONSTER_SAY_GET,
	CHAT_MSG_MONSTER_YELL = CHAT_MONSTER_YELL_GET,
	CHAT_MSG_MONSTER_WHISPER = CHAT_MONSTER_WHISPER_GET,
	CHAT_MSG_RAID_BOSS_WHISPER = CHAT_MONSTER_WHISPER_GET,
}

	---------------------
	--- Color Options ---
	---------------------

-- particular ordering
S.ColorOptions = {
	[1] = "ACHIEVEMENT",
	[4] = "GUILD",
	[7] = "PARTY",
	[10] = "RAID",
	[13] = "INSTANCE_CHAT",
	[16] = "BN_WHISPER",
	
	[2] = "GUILD_ACHIEVEMENT",
	[5] = "OFFICER",
	[8] = "PARTY_LEADER",
	[11] = "RAID_LEADER",
	[14] = "INSTANCE_CHAT_LEADER",
	
	[3] = "SAY",
	[6] = "YELL",
	[9] = "EMOTE",
	[12] = "RAID_WARNING", -- filler. not actually used..
	[15] = "WHISPER",
}

-- particular ordering, key: ChatTypeInfo
S.ColorOtherOptions = {
	-- COMBAT
	[1] = "COMBAT_XP_GAIN",
	[4] = "COMBAT_HONOR_GAIN",
	[7] = "COMBAT_FACTION_CHANGE",
	[10] = "SKILL",
	[13] = "LOOT",
	[16] = "CURRENCY",
	[19] = "MONEY",
	[22] = "TRADESKILLS",
	[25] = "OPENING",
	[28] = "PET_INFO",
	[2] = "COMBAT_MISC_INFO",
	
	-- PVP
	[5] = "BG_SYSTEM_HORDE",
	[8] = "BG_SYSTEM_ALLIANCE",
	[11] = "BG_SYSTEM_NEUTRAL",
	
	-- OTHER
	[14] = "SYSTEM",
	[17] = "ERRORS", -- special: "FILTERED", "RESTRICTED"
	[20] = "IGNORED",
	[23] = "CHANNEL",
	[26] = "TARGETICONS",
	[3] = "BN_INLINE_TOAST_ALERT",
	[6] = "PET_BATTLE_COMBAT_LOG",
	[9] = "PET_BATTLE_INFO",
	
	-- CREATURE_MESSAGES
	[12] = "MONSTER_SAY",
	[15] = "MONSTER_EMOTE",
	[18] = "MONSTER_YELL",
	[21] = "MONSTER_WHISPER",
	[24] = "RAID_BOSS_EMOTE",
	[27] = "RAID_BOSS_WHISPER",
}

S.EventToColor = {
	-- COMBAT
	CHAT_MSG_COMBAT_XP_GAIN = "COMBAT_XP_GAIN",
	CHAT_MSG_COMBAT_HONOR_GAIN = "COMBAT_HONOR_GAIN",
	CHAT_MSG_COMBAT_FACTION_CHANGE = "COMBAT_FACTION_CHANGE",
	CHAT_MSG_SKILL = "SKILL",
	CHAT_MSG_LOOT = "LOOT",
	CHAT_MSG_CURRENCY = "CURRENCY",
	CHAT_MSG_MONEY = "MONEY",
	CHAT_MSG_TRADESKILLS = "TRADESKILLS",
	CHAT_MSG_OPENING = "OPENING",
	CHAT_MSG_PET_INFO = "PET_INFO",
	CHAT_MSG_COMBAT_MISC_INFO = "COMBAT_MISC_INFO",
	
	-- PVP
	CHAT_MSG_BG_SYSTEM_HORDE = "BG_SYSTEM_HORDE",
	CHAT_MSG_BG_SYSTEM_ALLIANCE = "BG_SYSTEM_ALLIANCE",
	CHAT_MSG_BG_SYSTEM_NEUTRAL = "BG_SYSTEM_NEUTRAL",
	
	-- OTHER
	CHAT_MSG_SYSTEM = "SYSTEM",
	CHAT_MSG_FILTERED = "ERRORS",
	CHAT_MSG_RESTRICTED = "ERRORS", -- same
	CHAT_MSG_IGNORED = "IGNORED",
	CHAT_MSG_CHANNEL_JOIN = "CHANNEL",
	CHAT_MSG_CHANNEL_LEAVE = "CHANNEL", -- same
	CHAT_MSG_CHANNEL_NOTICE = "CHANNEL", -- same
	CHAT_MSG_CHANNEL_NOTICE_USER = "CHANNEL", -- same
	CHAT_MSG_CHANNEL_LIST = "CHANNEL", -- same
	CHAT_MSG_TARGETICONS = "TARGETICONS",
	CHAT_MSG_BN_INLINE_TOAST_ALERT = "BN_INLINE_TOAST_ALERT",
	CHAT_MSG_BN_INLINE_TOAST_BROADCAST = "BN_INLINE_TOAST_ALERT", -- same
	CHAT_MSG_BN_INLINE_TOAST_BROADCAST_INFORM = "BN_INLINE_TOAST_ALERT", -- same
	CHAT_MSG_PET_BATTLE_COMBAT_LOG = "PET_BATTLE_COMBAT_LOG",
	CHAT_MSG_PET_BATTLE_INFO = "PET_BATTLE_INFO",
	
	-- CREATURE_MESSAGES
	CHAT_MSG_MONSTER_SAY = "MONSTER_SAY",
	CHAT_MSG_MONSTER_EMOTE = "MONSTER_EMOTE",
	CHAT_MSG_MONSTER_YELL = "MONSTER_YELL",
	CHAT_MSG_MONSTER_WHISPER = "MONSTER_WHISPER",
	CHAT_MSG_RAID_BOSS_EMOTE = "RAID_BOSS_EMOTE",
	CHAT_MSG_RAID_BOSS_WHISPER = "RAID_BOSS_WHISPER",
}

-- for missing/preferable names
S.otherremap = {
	SKILL = SKILLUPS,
	LOOT = ITEM_LOOT,
	--CURRENCY = CURRENCY, -- kinda odd if you check CHAT_CONFIG_OTHER_COMBAT[7]
	MONEY = MONEY_LOOT,
	
	SYSTEM = SYSTEM_MESSAGES, -- missing
	
	MONSTER_SAY = CHAT_MSG_MONSTER_SAY, -- from GlobalStrings
	MONSTER_EMOTE = CHAT_MSG_MONSTER_EMOTE, -- from GlobalStrings
	MONSTER_YELL = CHAT_MSG_MONSTER_YELL, -- from GlobalStrings
	MONSTER_WHISPER = CHAT_MSG_MONSTER_WHISPER, -- from GlobalStrings
	
	RAID_BOSS_EMOTE = MONSTER_BOSS_EMOTE, -- special; GlobalStrings: CHAT_MSG_RAID_BOSS_EMOTE
	RAID_BOSS_WHISPER = MONSTER_BOSS_WHISPER, -- special
}

-- color groups
S.colorremap = {
	-- TEXT_EMOTE: /wave
	-- EMOTE: /emote Hello World!
	EMOTE = "TEXT_EMOTE",
	WHISPER = "WHISPER_INFORM", -- self
	BN_WHISPER = "BN_WHISPER_INFORM", -- self
	FILTERED = {"ERRORS", "RESTRICTED"}, -- special reverse case for defaults
	ERRORS = {"FILTERED", "RESTRICTED"}, -- special reverse case for profiles
}

	--------------
	--- Colors ---
	--------------

-- only need to look up an units class once
S.playerCache = setmetatable({}, {__index = function(t, k)
	local _, class, _, race, sex = GetPlayerInfoByGUID(k)
	local v =  {class, race, sex}
	rawset(t, k, v)
	return v
end})

S.classCache = setmetatable({}, {__index = function(t, k)
	local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[k] or profile.color[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

S.chatCache = setmetatable({}, {__index = function(t, k)
	local color = profile.color[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

function SCR:WipeCache()
	wipe(S.classCache)
	wipe(S.chatCache)
end

	------------------
	--- Race Icons ---
	------------------

S.sexremap = {nil, "MALE", "FEMALE"}

local RACE_ICON_TCOORDS = { -- GlueXML\CharacterCreate.lua 8.2.0
	["HUMAN_MALE"]		= {0, 0.125, 0, 0.25},
	["DWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
	["GNOME_MALE"]		= {0.25, 0.375, 0, 0.25},
	["NIGHTELF_MALE"]	= {0.375, 0.5, 0, 0.25},

	["TAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
	["SCOURGE_MALE"]	= {0.125, 0.25, 0.25, 0.5},
	["TROLL_MALE"]		= {0.25, 0.375, 0.25, 0.5},
	["ORC_MALE"]		= {0.375, 0.5, 0.25, 0.5},

	["HUMAN_FEMALE"]	= {0, 0.125, 0.5, 0.75},
	["DWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},
	["GNOME_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},
	["NIGHTELF_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},

	["TAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},
	["SCOURGE_FEMALE"]	= {0.125, 0.25, 0.75, 1.0},
	["TROLL_FEMALE"]	= {0.25, 0.375, 0.75, 1.0},
	["ORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0},

	["BLOODELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
	["BLOODELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0},

	["DRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
	["DRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75},

	["GOBLIN_MALE"]		= {0.629, 0.750, 0.25, 0.5},
	["GOBLIN_FEMALE"]	= {0.629, 0.750, 0.75, 1.0},

	["WORGEN_MALE"]		= {0.629, 0.750, 0, 0.25},
	["WORGEN_FEMALE"]	= {0.629, 0.750, 0.5, 0.75},

	["PANDAREN_MALE"]	= {0.756, 0.881, 0, 0.25},
	["PANDAREN_FEMALE"]	= {0.756, 0.881, 0.5, 0.75},

	["NIGHTBORNE_MALE"]	= {0.375, 0.5, 0, 0.25},
	["NIGHTBORNE_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},

	["HIGHMOUNTAINTAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
	["HIGHMOUNTAINTAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},

	["VOIDELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
	["VOIDELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0},

	["LIGHTFORGEDDRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
	["LIGHTFORGEDDRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75},

	["DARKIRONDWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
	["DARKIRONDWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},

	["MAGHARORC_MALE"]			= {0.375, 0.5, 0.25, 0.5},
	["MAGHARORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0},

	["ZANDALARITROLL_MALE"]		= {0.25, 0.375, 0, 0.25},
	["ZANDALARITROLL_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},

	["KULTIRAN_MALE"]		= {0, 0.125, 0, 0.25},
	["KULTIRAN_FEMALE"]		= {0, 0.125, 0.5, 0.75},
}

local racePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"

S.raceIconCache = setmetatable({}, {__index = function(t, k)
	local top, bottom, left, right = unpack(RACE_ICON_TCOORDS[k])
	local coords = strjoin(":", top*256, bottom*256, left*512, right*512)
	local v = format("|T%s:%s:%s:%%s:%%s:256:512:%s|t", racePath, profile.IconSize, profile.IconSize, coords)
	rawset(t, k, v)
	return v
end})

-- x and y vary so we can't cache that
function S.GetRaceIcon(k, x, y)
	return format(S.raceIconCache[k], x, y)
end

	-------------------
	--- Class Icons ---
	-------------------

S.classPath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

S.CLASS_ICON_TCOORDS_256 = CopyTable(CLASS_ICON_TCOORDS)

for k1, v1 in pairs(S.CLASS_ICON_TCOORDS_256) do
	for k2, v2 in ipairs(v1) do
		S.CLASS_ICON_TCOORDS_256[k1][k2] = v2*256
	end
end

S.classIconCache = setmetatable({}, {__index = function(t, k)
	local coords = strjoin(":", unpack(S.CLASS_ICON_TCOORDS_256[k]))
	local v = format("|T%s:%s:%s:%%s:%%s:256:256:%s|t", S.classPath, profile.IconSize, profile.IconSize, coords)
	rawset(t, k, v)
	return v
end})

function S.GetClassIcon(k, x, y)
	return format(S.classIconCache[k], x, y)
end

	--------------------
	--- Class Names  ---
	--------------------

-- for CHAT_MSG_BN_WHISPER support
S.revLOCALIZED_CLASS_NAMES = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	S.revLOCALIZED_CLASS_NAMES[v] = k
end
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	S.revLOCALIZED_CLASS_NAMES[v] = k
end

	------------------
	--- Timestamps ---
	------------------

S.timestamps = {
	TIMESTAMP_FORMAT_NONE,
	TIMESTAMP_FORMAT_HHMM,
	TIMESTAMP_FORMAT_HHMMSS,
	TIMESTAMP_FORMAT_HHMM_AMPM,
	TIMESTAMP_FORMAT_HHMMSS_AMPM,
	TIMESTAMP_FORMAT_HHMM_24HR,
	TIMESTAMP_FORMAT_HHMMSS_24HR,
}

for i, v in ipairs(S.timestamps) do
	S.timestamps[i] = v:trim() -- remove trailing space
end

function S.GetTimestamp()
	return (profile.Timestamp > 1) and "|cff"..S.chatCache.TIMESTAMP..BetterDate(S.timestamps[profile.Timestamp], time()).."|r" or ""
end

	---------------
	--- LibSink ---
	---------------

-- LibSink properly filters Coloring, but not Icons when output to Chat
S.LibSinkChat = {
	Channel = true, -- all
	ForwardCustom = true, -- private
}

	--------------------
	--- Game Clients ---
	--------------------

-- https://github.com/Gethe/wow-ui-textures/tree/live/CHATFRAME
S.clients = { -- also used as remap for SC2/D3 icon
	[BNET_CLIENT_WOW] = "WOW",
	[BNET_CLIENT_SC2] = "SC2",
	[BNET_CLIENT_D3] = "D3",
	[BNET_CLIENT_WTCG] = "WTCG",
	[BNET_CLIENT_APP] = "Battlenet",
	[BNET_CLIENT_HEROES] = "HotS", -- different than FrameXML\BNet.lua
	[BNET_CLIENT_OVERWATCH] = "Overwatch", -- same
	[BNET_CLIENT_CLNT] = "Battlenet",
}

	--------------------------
	--- Combat Text AddOns ---
	--------------------------

S.CombatTextEnabled = {}

for _, v in ipairs({"MikScrollingBattleText", "sct"}) do
	S.CombatTextEnabled[v] = select(4, GetAddOnInfo(v))
end
