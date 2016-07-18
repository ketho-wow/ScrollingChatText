local _, S = ...

	---------------------------------------------------------
	--- Credits to Prat-3.0 for the Channel Abbreviations ---
	---------------------------------------------------------

local L = {
	deDE = {
		BATTLEGROUND = "BG",
		BATTLEGROUND_LEADER = "BL",
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmenü zu öffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
		EMOTE = "E",
		GUILD = "G",
		HELLO_WORLD = "Hallo Welt!",
		OFFICER = "O",
		OPTION_COLOR_MESSAGE = "Ganze Chat-Nachrichten einfärben",
		OPTION_FILTER_SELF = "Eigene Nachrichten ausfiltern", -- Needs review
		OPTION_FONT = "Schriftart",
		OPTION_GROUP_SHOW_WHEN = "Anzeigen, wenn ..",
		OPTION_ICON_SIZE = "Symbolgröße",
		OPTION_REPARENT_COMBAT_TEXT = "Kampftext loslösen und ins Weltfenster (WorldFrame) einbetten", -- Needs review
		OPTION_SHOW_NOTINCOMBAT = "Nicht im Kampf", -- Needs review
		OPTION_TRIM_MESSAGE = "Lange Nachrichten unterteilen", -- Needs review
		OPTION_TRIM_REALM_NAME = "Realmnamen kürzen", -- Needs review
		PARTY = "P",
		PARTY_LEADER = "PL",
		RAID = "R",
		RAID_LEADER = "RL",
		SAY = "S",
		USE_CLASS_COLORS = "Bitte benützt dafür das Class Colors AddOn",
		WHISPER = "Flüstern von",
		YELL = "Y",
	},
	enUS = {
		OPTION_GROUP_LEVELUP = LEVEL.." Up",
		OPTION_GROUP_SHOW_WHEN = "Show when...",
		OPTION_FILTER_SELF = FILTER.." self",
		OPTION_TRIM_REALM_NAME = "Trim realm "..NAME,
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
		OPTION_ICON_SIZE = "아이콘 크기",
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
		OPTION_GROUP_SHOW_WHEN = "当...时显示",
		OPTION_FILTER_SELF = "过滤自身",
		OPTION_COLOR_MESSAGE = "着色完整消息",
		OPTION_TRIM_MESSAGE = "划分长消息",
		OPTION_SHOW_NOTINCOMBAT = "不在战斗中",
		OPTION_ICON_SIZE = "图标大小",
		OPTION_FONT = "字体",
		BROKER_CLICK = "点击打开选项菜单",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-点击|r 启用或禁用插件",
		HELLO_WORLD = "你好！",
		USE_CLASS_COLORS = "请使用 ClassColors 插件",
		SAY = "说",
		YELL = "喊",
		WHISPER = "收", BN_WHISPER = "收",
		WHISPER_INFORM = "密", BN_WHISPER_INFORM = "密",
		GUILD = "会",
		OFFICER = "管",
		PARTY = "队",
		PARTY_LEADER = "队长",
		RAID = "团",
		RAID_LEADER = "酱",
		BATTLEGROUND = "战",
		BATTLEGROUND_LEADER = "蟀",
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
