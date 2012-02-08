-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2011.07.05					---
--- Version: r1 [2012.02.08]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/scrollingchattext
--- WoWInterface	N/A

-- To Do:
-- # More possible chat types. CHAT_MSG_SYSTEM, Loot, Monsters/NPCs, CHAT_MSG_TARGETICONS (?)
-- # Some kind of filtering against spam
-- # Prevent looping yourself, but still being able to talk in a \Chat\ Channel, different from the output \Chat\ Channel

-- To Fix:
-- # Error: SendChatMessage(): Invalid escape code in chat message; When trying to output more than 255 characters, and there was a Link at the end
-- # LibSink(?) Links being converted to raw text when outputting to a Channel
-- # LibSink(?) Links and the remainder of the text being cut out
-- # LibSink(?) Messages with Links sometimes not even being output to a chat channel

local NAME, S = ...
S.VERSION = 0.1
S.BUILD = "Release"

-- ScrollingChatText abbreviates to SCR in order to avoid confusion with SCT (ScrollingCombatText)
ScrollingChatText = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local SCR = ScrollingChatText

local profile

function SCR:RefreshDB1()
	profile = self.db.profile
end

local pairs, ipairs = pairs, ipairs
local format = format

S.playerName = UnitName("player")
S.playerClass = select(2, UnitClass("player"))

	------------------
	--- Race Icons ---
	------------------

S.racePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"

S.RACE_ICON_TCOORDS_256 = { -- GlueXML\CharacterCreate.lua L25 (4.3.0.15050)
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
}

S.sexremap = {nil, "MALE", "FEMALE"}

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

	--------------
	--- Events ---
	--------------

S.events = {
	CHAT_MSG = {
		"CHAT_MSG_SAY",
		"CHAT_MSG_YELL",
		"CHAT_MSG_EMOTE",
		"CHAT_MSG_TEXT_EMOTE",
		"CHAT_MSG_CHANNEL",
		"CHAT_MSG_WHISPER",
		--"CHAT_MSG_WHISPER_INFORM", -- self
		"CHAT_MSG_GUILD",
		"CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY",
		"CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_BATTLEGROUND",
		"CHAT_MSG_BATTLEGROUND_LEADER",
	},
	CHAT_MSG_ACH = {
		"CHAT_MSG_ACHIEVEMENT",
		"CHAT_MSG_GUILD_ACHIEVEMENT",
	},
	CHAT_MSG_BN = {
		"CHAT_MSG_BN_WHISPER",
		--"CHAT_MSG_BN_WHISPER_INFORM", -- self
		"CHAT_MSG_BN_CONVERSATION",
	},
}

-- profile settings
S.eventremap = {
	ACHIEVEMENT = "GUILD_ACHIEVEMENT",
	BATTLEGROUND = "BATTLEGROUND_LEADER",
	EMOTE = "TEXT_EMOTE",
	GUILD = "OFFICER",
	PARTY = "PARTY_LEADER",
	RAID = "RAID_LEADER",
	WHISPER = {"BN_WHISPER", "BN_CONVERSATION"},
}

-- this particular ordering is used for in the color menu
S.ColorEvents = {
	"ACHIEVEMENT",
	"GUILD_ACHIEVEMENT",
	"SAY",
	
	"GUILD",
	"OFFICER",
	"YELL",
	
	"PARTY",
	"PARTY_LEADER",
	"EMOTE",
	
	"RAID",
	"RAID_LEADER",
	"WHISPER",
	
	"BATTLEGROUND",
	"BATTLEGROUND_LEADER",
	"CHANNEL",
	
	"BN_WHISPER",
	"BN_CONVERSATION",
}

-- TEXT_EMOTE: /wave
-- EMOTE: /emote Hello World!
S.colorremap = {
	EMOTE = "TEXT_EMOTE",
}

S.LevelEvents = {
	"UNIT_LEVEL",
	"GUILD_ROSTER_UPDATE",
	"FRIENDLIST_UPDATE",
	"BN_FRIEND_INFO_CHANGED",
}

-- register/unregister events depending on options
S.levelremap = {
	LevelParty = "UNIT_LEVEL",
	LevelRaid = "UNIT_LEVEL",
	LevelGuild = "GUILD_ROSTER_UPDATE",
	LevelFriend = "FRIENDLIST_UPDATE",
	LevelFriendBnet = "BN_FRIEND_INFO_CHANGED",
}

-- determine if any of the LevelGroup options are enabled
function S.LevelGroup()
	return profile.LevelParty or profile.LevelRaid
end

	--------------
	--- Colors ---
	--------------

S.classCache = setmetatable({}, {__index = function(t, k)
	local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[k] or profile.color[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

S.chanCache = setmetatable({}, {__index = function(t, k)
	local color = profile.color[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

function SCR:WipeCache()
	wipe(S.classCache)
	wipe(S.chanCache)
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
