local _, S = ...

	---------------------------------------------------------
	--- Credits to Prat-3.0 for the Channel Abbreviations ---
	---------------------------------------------------------

local L = {
	deDE = {
	},
	enUS = {
		OPTION_TAB_MAIN = "Main",
		OPTION_TAB_EXTRA = "Extra",
		OPTION_GROUP_LEVELUP = "Level Up",
		OPTION_ICON_SIZE = "Icon Size",
		OPTION_FONT = "Font",
		OPTION_FILTER_SELF = "Filter Self",
		OPTION_COLOR_MESSAGE = "Color full message",
		OPTION_REPARENT_COMBAT_TEXT = "Reparent |cff71D5FFCombatText|r to |cff71D5FFWorldFrame|r",
		OPTION_TRIM_REALM_NAME = "Trim Realm Name",
		OPTION_TRIM_MESSAGE = "Subdivide long messages",
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
		HELLO_WORLD = "Hello World!",
		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		SAY = "S",
		YELL = "Y",
		EMOTE = "E",
		TEXT_EMOTE = "E", -- same
		WHISPER = "W From",
		--WHISPER_INFORM = "W To",
		GUILD = "G",
		OFFICER = "O",
		PARTY = "P",
		PARTY_LEADER = "PL",
		RAID = "R",
		RAID_LEADER = "RL",
		BATTLEGROUND = "B",
		BATTLEGROUND_LEADER = "BL",
		BN_WHISPER = "BN",
		BN_CONVERSATION = "BN", -- same
	},
	esES = {
	},
	esMX = {
	},
	frFR = {
	},
	koKR = {
		SAY = "\235\140\128\237\153\148",
		YELL = "\236\153\184\236\185\168",
		WHISPER = "\235\176\155\236\157\128\234\183\147\235\167\144",
		--WHISPER_INFORM = "\234\183\147\235\167\144",
		GUILD = "\234\184\184\235\147\156",
		OFFICER = "\236\152\164\237\148\188\236\132\156",
		PARTY = "\237\140\140\237\139\176",
		PARTY_LEADER = "\237\140\140\237\139\176", -- ?; PARTY
		RAID = "\234\179\181\235\140\128",
		RAID_LEADER = "\234\179\181\235\140\128\236\158\165",
		BATTLEGROUND = "\236\160\132\236\158\165",
		BATTLEGROUND_LEADER = "\236\160\132\237\136\172\235\140\128\236\158\165",
	},
	ptBR = {
	},
	ruRU = {
	},
	zhCN = {
		SAY = "\232\175\180", -- "说"
		YELL = "\229\150\138", -- "喊"
		WHISPER = "\230\148\182", -- "收"
		--WHISPER_INFORM = "\229\175\134", -- "密"
		GUILD = "\228\188\154", -- "会"
		OFFICER = "\231\174\161", -- "管"
		PARTY = "\233\152\159", -- "队"
		PARTY_LEADER = "\233\152\159", -- ?; PARTY
		RAID = "\229\155\162", -- "团"
		RAID_LEADER = "\233\133\177", -- "酱"
		BATTLEGROUND = "\230\136\152", -- "战"
		BATTLEGROUND_LEADER = "\232\159\128", -- "蟀"
	},
	zhTW = {
		SAY = "\232\170\170", -- "說"
		YELL = "\229\150\138", -- "喊"
		WHISPER = "\232\129\189", -- "聽"
		--WHISPER_INFORM = "\229\175\134", -- "密"
		GUILD = "\230\156\131", -- "會"
		OFFICER = "\229\174\152", -- "官"
		PARTY = "\233\154\138", -- "隊"
		PARTY_LEADER = "\233\154\138", -- ?; PARTY
		RAID = "\229\156\152", -- "團"
		RAID_LEADER = "\229\156\152\233\149\183", -- "團長"
		BATTLEGROUND = "\230\136\176", -- "戰"
		BATTLEGROUND_LEADER = "\230\136\176\233\160\152", -- "戰領"
	},
}

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
