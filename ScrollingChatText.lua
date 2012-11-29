-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2011.07.05					---
--- Version: 0.7.0 [2012.11.29]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/scrollingchattext
--- WoWInterface	http://www.wowinterface.com/downloads/info20827-ScrollingChatText.html

-- To Do:
-- # Some kind of filtering against spam
-- # Prevent looping yourself, but still being able to talk in a \Chat\ Channel, different from the output \Chat\ Channel

-- To Fix:
-- # Error: SendChatMessage(): Invalid escape code in chat message; When trying to output more than 255 characters, and there was a Link at the end
-- # LibSink(?) Links being converted to raw text when outputting to a Channel
-- # LibSink(?) Links and the remainder of the text being cut out
-- # LibSink(?) Messages with Links sometimes not even being output to a chat channel

local NAME, S = ...
S.VERSION = "0.7.0"
S.BUILD = "Release"

-- ScrollingChatText abbreviates to SCR in order to avoid confusion with SCT (ScrollingCombatText)
ScrollingChatText = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local SCR = ScrollingChatText
SCR.S = S -- debug purpose

local profile

function SCR:RefreshDB1()
	profile = self.db.profile
end

local pairs, ipairs = pairs, ipairs
local format = format

S.playerName = UnitName("player")
S.playerClass = select(2, UnitClass("player"))

	--------------
	--- Events ---
	--------------

S.events = {
	CHAT_MSG = {
		"CHAT_MSG_SAY",
		"CHAT_MSG_YELL",
		"CHAT_MSG_CHANNEL",
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
		"CHAT_MSG_BN_CONVERSATION",
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
	BN_WHISPER = {"BN_WHISPER_INFORM", "BN_CONVERSATION"},
}

-- sourceName in these events are the same as destName
S.INFORM = {
	CHAT_MSG_WHISPER_INFORM = true,
	CHAT_MSG_BN_WHISPER_INFORM = true,
}

	--------------------
	--- Other Events ---
	--------------------

S.OtherEvents = {
	-- COMBAT
	COMBAT_XP_GAIN = "CHAT_MSG_COMBAT_XP_GAIN",
	COMBAT_GUILD_XP_GAIN = "CHAT_MSG_COMBAT_GUILD_XP_GAIN",
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
		"CHAT_MSG_BN_INLINE_TOAST_CONVERSATION",
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
		--CONVERSATION = BN_INLINE_TOAST_CONVERSATION,
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

	--------------------
	--- Level Events ---
	--------------------

-- register/unregister events depending on options
S.levelremap = {
	LevelParty = "UNIT_LEVEL",
	LevelRaid = "UNIT_LEVEL",
	LevelGuild = "GUILD_ROSTER_UPDATE",
	LevelFriend = "FRIENDLIST_UPDATE",
	LevelRealID = "BN_FRIEND_INFO_CHANGED",
}

-- determine if any of the LevelGroup options are enabled
function S.LevelGroup()
	return profile.LevelParty or profile.LevelRaid
end

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
	[17] = "BN_CONVERSATION",
	
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
	[4] = "COMBAT_GUILD_XP_GAIN",
	[7] = "COMBAT_HONOR_GAIN",
	[10] = "COMBAT_FACTION_CHANGE",
	[13] = "SKILL",
	[16] = "LOOT",
	[19] = "CURRENCY",
	[22] = "MONEY",
	[25] = "TRADESKILLS",
	[28] = "OPENING",
	[2] = "PET_INFO",
	[5] = "COMBAT_MISC_INFO",
	
	-- PVP
	[8] = "BG_SYSTEM_HORDE",
	[11] = "BG_SYSTEM_ALLIANCE",
	[14] = "BG_SYSTEM_NEUTRAL",
	
	-- OTHER
	[17] = "SYSTEM",
	[20] = "ERRORS", -- special: "FILTERED", "RESTRICTED"
	[23] = "IGNORED",
	[26] = "CHANNEL",
	[29] = "TARGETICONS",
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
	CHAT_MSG_COMBAT_GUILD_XP_GAIN = "COMBAT_GUILD_XP_GAIN",
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
	CHAT_MSG_BN_INLINE_TOAST_CONVERSATION = "BN_INLINE_TOAST_ALERT", -- same
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

S.racePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"

S.RACE_ICON_TCOORDS_256 = { -- GlueXML\CharacterCreate.lua L25 (4.3.4.15595)
	HUMAN_MALE		= {0, 32, 0, 128},
	DWARF_MALE		= {32, 64, 0, 128},
	GNOME_MALE		= {64, 96, 0, 128},
	NIGHTELF_MALE	= {96, 128, 0, 128},

	TAUREN_MALE		= {0, 32, 128, 256},
	SCOURGE_MALE	= {32, 64, 128, 256},
	TROLL_MALE		= {64, 96, 128, 256},
	ORC_MALE		= {96, 128, 128, 256},

	HUMAN_FEMALE	= {0, 32, 256, 384},  
	DWARF_FEMALE	= {32, 64, 256, 384},
	GNOME_FEMALE	= {64, 96, 256, 384},
	NIGHTELF_FEMALE	= {96, 128, 256, 384},

	TAUREN_FEMALE	= {0, 32, 384, 512},   
	SCOURGE_FEMALE	= {32, 64, 384, 512}, 
	TROLL_FEMALE	= {64, 96, 384, 512}, 
	ORC_FEMALE		= {96, 128, 384, 512}, 

	BLOODELF_MALE	= {128, 160, 128, 256},
	BLOODELF_FEMALE	= {128, 160, 384, 512}, 

	DRAENEI_MALE	= {128, 160, 0, 128},
	DRAENEI_FEMALE	= {128, 160, 256, 384}, 

	GOBLIN_MALE		= {160, 192, 128, 256},
	GOBLIN_FEMALE	= {160, 192, 384, 512},

	WORGEN_MALE		= {160, 192, 0, 128},
	WORGEN_FEMALE	= {160, 192, 256, 384},
	
	PANDAREN_MALE	= {192, 224, 0, 128},
	PANDAREN_FEMALE	= {192, 224, 256, 384},
}

S.sexremap = {nil, "MALE", "FEMALE"}

S.raceIconCache = setmetatable({}, {__index = function(t, k)
	local coords = strjoin(":", unpack(S.RACE_ICON_TCOORDS_256[k]))
	local v = format("|T%s:%s:%s:%%s:%%s:256:512:%s|t", S.racePath, profile.IconSize, profile.IconSize, coords)
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

S.clients = { -- also used as remap for SC2/D3 icon
	[BNET_CLIENT_WOW] = "WOW",
	[BNET_CLIENT_SC2] = "SC2",
	[BNET_CLIENT_D3] = "D3",
}

	--------------------------
	--- Combat Text AddOns ---
	--------------------------

S.CombatTextEnabled = {}

for _, v in ipairs({"MikScrollingBattleText", "Parrot", "sct"}) do
	local enabled = select(4, GetAddOnInfo(v))
	S.CombatTextEnabled[v] = enabled and true or false
end
