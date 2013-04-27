local _, S = ...

	---------------------------------------------------------
	--- Credits to Prat-3.0 for the Channel Abbreviations ---
	---------------------------------------------------------

local L = {
	deDE = {
		OPTION_TAB_EXTRA = "Extras",
		OPTION_GROUP_LEVELUP = "Stufenzunahme",
		OPTION_GROUP_SHOW_WHEN = "Anzeigen, wenn ..",
		OPTION_FILTER_SELF = "Eigene Nachrichten ausfiltern",
		OPTION_TRIM_REALM_NAME = "Realmnamen k\195\188rzen",
		OPTION_COLOR_MESSAGE = "Ganze Chat-Nachrichten einf\195\164rben",
		OPTION_TRIM_MESSAGE = "Lange Nachrichten unterteilen",
		OPTION_SHOW_NOTINCOMBAT = "Nicht im Kampf",
		OPTION_ICON_SIZE = "Symbolgr\195\182\195\159e",
		OPTION_FONT = "Schriftart",
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmen\195\188 zu \195\182ffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
		HELLO_WORLD = "Hallo Welt!",
		USE_CLASS_COLORS = "Bitte ben\195\188tzt daf\195\188r das |cff71D5FFClass Colors|r AddOn",
		WHISPER = "Fl\195\188stern von", BN_WHISPER = "Fl\195\188stern von",
	},
	enUS = {
		OPTION_TAB_EXTRA = "Extra",
		OPTION_GROUP_LEVELUP = "Level Up",
		OPTION_GROUP_SHOW_WHEN = "Show when...",
		OPTION_FILTER_SELF = FILTER.." self",
		OPTION_TRIM_REALM_NAME = "Trim realm name",
		OPTION_COLOR_MESSAGE = "Color full message",
		OPTION_TRIM_MESSAGE = "Divide long messages",
		OPTION_REPARENT_COMBAT_TEXT = "Reparent to |cff71D5FFWorldFrame|r",
		OPTION_SHOW_NOTINCOMBAT = "Not in "..COMBAT,
		OPTION_ICON_SIZE = "Icon Size",
		OPTION_FONT = "Font",
		
		OPTION_FCT_SCROLLSPEED = "Scroll speed",
		OPTION_FCT_FADEOUT_TIME = "Fade out time",
		OPTION_FCT_POSITION = "Position",
		OPTION_FCT_SCALE = "Scale",
		OPTION_FCT_END = "End",
		
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
		HELLO_WORLD = "Hello World!",
		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		SAY = "S",
		YELL = "Y",
		EMOTE = "E", TEXT_EMOTE = "E", -- deprecated
		WHISPER = "W From", BN_WHISPER = "W From",
		WHISPER_INFORM = "W To", BN_WHISPER_INFORM = "W To",
		BN_CONVERSATION = "BN",
		GUILD = "G",
		OFFICER = "O",
		PARTY = "P",
		PARTY_LEADER = "PL",
		RAID = "R",
		RAID_LEADER = "RL",
		BATTLEGROUND = "B",
		BATTLEGROUND_LEADER = "BL",
		INSTANCE_CHAT = "I",
		INSTANCE_CHAT_LEADER = "IL",
	},
	esES = {
		BROKER_CLICK = "|cffffffffHaz clic|r para ver opciones",
		BROKER_SHIFT_CLICK = "|cffffffffMayús-clic|r para activar/desactivar",
	},
	esMX = {
		BROKER_CLICK = "|cffffffffHaz clic|r para ver opciones",
		BROKER_SHIFT_CLICK = "|cffffffffMayús-clic|r para activar/desactivar",
	},
	frFR = {
	},
	itIT = {
	},
	koKR = {
		BATTLEGROUND = "전장",
		BATTLEGROUND_LEADER = "전투대장",
		EMOTE = "이모티콘",
		GUILD = "길드",
		OFFICER = "오피서",
		OPTION_FONT = "글꼴",
		OPTION_GROUP_LEVELUP = "레벨업",
		OPTION_ICON_SIZE = "아이콘 크기",
		OPTION_TAB_EXTRA = "추가기능",
		PARTY = "파티", PARTY_LEADER = "파티",
		RAID = "공대",
		RAID_LEADER = "공대장",
		SAY = "대화",
		WHISPER = "받은귓말", BN_WHISPER = "받은귓말",
		WHISPER_INFORM = "귓말", BN_WHISPER_INFORM = "귓말",
		YELL = "외침",
	},
	ptBR = {
	},
	ruRU = {
	},
	zhCN = {
		OPTION_GROUP_LEVELUP = "\229\141\135\231\186\167", -- "升级"
		OPTION_GROUP_SHOW_WHEN = "\229\189\147...\230\151\182\230\152\190\231\164\186", -- "当...时显示"
		OPTION_FILTER_SELF = "\232\191\135\230\187\164\232\135\170\232\186\171", -- "过滤自身"
		OPTION_COLOR_MESSAGE = "\231\157\128\232\137\178\229\174\140\230\149\180\230\182\136\230\129\175", -- "着色完整消息"
		OPTION_TRIM_MESSAGE = "\229\136\146\229\136\134\233\149\191\230\182\136\230\129\175", -- "划分长消息"
		OPTION_SHOW_NOTINCOMBAT = "\228\184\141\229\156\168\230\136\152\230\150\151\228\184\173", -- "不在战斗中"
		OPTION_ICON_SIZE = "\229\155\190\230\160\135\229\164\167\229\176\143", -- "图标大小"
		OPTION_FONT = "\229\173\151\228\189\147", -- "字体"
		BROKER_CLICK = "|cffFFFFFF\231\130\185\229\135\187|r\230\137\147\229\188\128\233\128\137\233\161\185\232\143\156\229\141\149", -- "点击打开选项菜单"
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-\231\130\185\229\135\187|r \229\144\175\231\148\168\230\136\150\231\166\129\231\148\168\230\143\146\228\187\182", -- "Shift-点击 启用或禁用插件"
		HELLO_WORLD = "\228\189\160\229\165\189\239\188\129", -- "你好！"
		USE_CLASS_COLORS = "\232\175\183\228\189\191\231\148\168 |cff71D5FFClassColors|r \230\143\146\228\187\182", -- "请使用 ClassColors 插件"
		SAY = "\232\175\180", -- "说"
		YELL = "\229\150\138", -- "喊"
		WHISPER = "\230\148\182", BN_WHISPER = "\230\148\182", -- "收"
		WHISPER_INFORM = "\229\175\134", BN_WHISPER_INFORM = "\229\175\134", -- "密"
		GUILD = "\228\188\154", -- "会"
		OFFICER = "\231\174\161", -- "管"
		PARTY = "\233\152\159", -- "队"
		PARTY_LEADER = "\233\152\159\233\149\191", -- "队长"
		RAID = "\229\155\162", -- "团"
		RAID_LEADER = "\233\133\177", -- "酱"
		BATTLEGROUND = "\230\136\152", -- "战"
		BATTLEGROUND_LEADER = "\232\159\128", -- "蟀"
	},
	zhTW = {
		BATTLEGROUND = "戰",
		BATTLEGROUND_LEADER = "戰領",
		GUILD = "會",
		HELLO_WORLD = "你好！",
		OFFICER = "官",
		OPTION_FCT_POSITION = "位置",
		OPTION_FCT_SCALE = "縮放",
		OPTION_FONT = "字體",
		OPTION_ICON_SIZE = "圖示大小",
		PARTY = "隊",
		PARTY_LEADER = "隊長",
		RAID = "團",
		RAID_LEADER = "團長",
		SAY = "說",
		WHISPER = "聽", BN_WHISPER = "聽",
		WHISPER_INFORM = "密", BN_WHISPER_INFORM = "聽",
		YELL = "喊",
	},
}

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
