local NAME, S = ...
local SCR = ScrollingChatText

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local L = S.L
local options = S.options
local profile
local chat, other, filter

local pairs, ipairs = pairs, ipairs
local strfind, gsub = strfind, gsub
local utf8len, utf8sub = string.utf8len, string.utf8sub

local time = time

	-------------------------
	--- ChatTypeInfo Wait ---
	-------------------------

-- ChatTypeInfo does not yet contain the color info, which we need for the defaults
-- MoP 5.0.4: all the colors initialize with placeholder {r=1, g=1, b=1} values now
local f = CreateFrame("Frame")

function f:WaitInitialize(elapsed)
	-- let's not hope someone changed YELL to white or greenish in the Blizzard chat options
	if ChatTypeInfo.YELL.g ~= 1 then
		self:SetScript("OnUpdate", nil)
		SCR:OnInitialize()
	end
end

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"ScrollingChatText_Main",
	"ScrollingChatText_Advanced",
	"ScrollingChatText_Colors",
	"ScrollingChatText_FCT",
	"ScrollingChatText_Extra",
}

-- using ipairs to iterate through appKey by index
-- but still want to be able to use key-value tables
local appValue = {
	ScrollingChatText_Main = options.args.main,
	ScrollingChatText_Advanced = options.args.advanced,
	ScrollingChatText_FCT = options.args.fct,
	ScrollingChatText_Colors = options.args.colors,
	ScrollingChatText_Extra = options.args.extra,
}

function SCR:OnInitialize()
	if ChatTypeInfo.YELL.g == 1 then
		f:SetScript("OnUpdate", f.WaitInitialize)
		return
	end
	
	self:GetChatTypeInfo()
	self.db = LibStub("AceDB-3.0"):New("ScrollingChatTextDB", S.defaults, true)
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	ACR:RegisterOptionsTable("ScrollingChatText_Parent", options)
	ACD:AddToBlizOptions("ScrollingChatText_Parent", NAME)
	ACD:SetDefaultSize("ScrollingChatText_Parent", 700, 585)
	
	-- setup profiles now, self reminder: requires db to be already defined
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	profiles.order = 5
	tinsert(appKey, "ScrollingChatText_Profiles")
	appValue.ScrollingChatText_Profiles = profiles
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME)
	end
	
	----------------------
	--- Slash Commands ---
	----------------------
	
	for _, v in ipairs({"scr", "scrollchat", "scrollingchat", "scrollingchattext"}) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
	
	-- ScrollingCombatText not enabled
	if not S.CombatTextEnabled.sct then
		self:RegisterChatCommand("sct", "SlashCommand")
	end
	
	-- info not yet available (but we're delayed anyway)
	options.args.advanced.args.inline1.args.ParentCombatText.desc = format(UI_HIDDEN, GetBindingText(GetBindingKey("TOGGLEUI"), "KEY_"))
	S.defaultLang = GetDefaultLanguage()
	
	-- SHOW_COMBAT_TEXT seems to be "1" instead of "0", at loadtime regardless if the option was disabled (but we're delayed anyway again)
	if profile.sink20OutputSink == "Blizzard" and SHOW_COMBAT_TEXT == "0" then
		if S.CombatTextEnabled.MikScrollingBattleText then
			profile.sink20OutputSink = "MikSBT" 
		elseif S.CombatTextEnabled.Parrot then
			profile.sink20OutputSink = "Parrot" 
		elseif S.CombatTextEnabled.sct then
			profile.sink20OutputSink = "SCT" 
		-- assign to Prat-3.0 Popup if all Combat Text sinks are disabled,
		-- otherwise LibSink will fallback to UIErrorsFrame by default
		elseif select(4, GetAddOnInfo("Prat-3.0")) then
			profile.sink20OutputSink = "Popup" 
		end
	end
	self:OnEnable() -- delayed OnInitialize done, call OnEnable again now
end

local combatState

function SCR:OnEnable()
	if not profile then return end -- Initialization not yet done
	
	-- Chat events
	for method, tbl in pairs(S.events) do
		for _, event in ipairs(tbl) do
			self:RegisterEvent(event, method)
		end
	end
	
	-- Channel event
	self:RegisterEvent("CHANNEL_UI_UPDATE")
	self:CHANNEL_UI_UPDATE() -- addon was disabled; or user did a /reload
	
	-- support [Class Colors] by Phanx
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback("WipeCache", self)
	end
	
	-- init combat state
	combatState = UnitAffectingCombat("player")
	
	-- this kinda defeats the purpose of registering/unregistering events according to options <.<
	self:ScheduleRepeatingTimer(function()
		-- the returns of UnitLevel() aren't yet updated on UNIT_LEVEL
		if profile.LevelParty or profile.LevelRaid then
			self:UNIT_LEVEL()
		end
		if profile.LevelGuild then
			GuildRoster() -- fires GUILD_ROSTER_UPDATE
		end
		-- FRIENDLIST_UPDATE doesn't fire on actual friend levelups
		-- the returns of GetFriendInfo() only get updated when FRIENDLIST_UPDATE fires
		if profile.LevelFriend then
			ShowFriends() -- fires FRIENDLIST_UPDATE
		end
		-- BN_FRIEND_INFO_CHANGED doesn't fire on login; but it does on actual levelups; just to be sure
		if profile.LevelRealID then
			self:BN_FRIEND_INFO_CHANGED()
		end
	end, 11)
end

function SCR:OnDisable()
	-- maybe superfluous
	self:UnregisterAllEvents()
	self:CancelAllTimers()
	
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:UnregisterCallback("WipeCache", self)
	end
end

function SCR:RefreshDB()
	profile = self.db.profile -- table shortcut
	chat = profile.chat
	other = profile.other
	filter = profile.filter
	self:SetSinkStorage(profile) -- LibSink savedvars
	
	-- update table references in other files
	for i = 1, 3 do
		self["RefreshDB"..i](self)
	end
	
	-- Other events; (un)register according to options; also account for profile reset
	for k, v in pairs(S.OtherEvents) do
		local reg = other[k] and "RegisterEvent" or "UnregisterEvent"
		if type(v) == "table" then
			for _, event in ipairs(v) do
				self[reg](self, event, "CHAT_MSG_OTHER")
			end
		else
			self[reg](self, v, "CHAT_MSG_OTHER")
		end
	end
	
	-- init/update Blizzard FCT settings
	for k, v in pairs(profile.fct) do
		if type(v) == "table" then -- COMBAT_TEXT_LOCATIONS
			for k2, v2 in pairs(v) do
				_G[k][k2] = v2
			end
		else
			if k == "COMBAT_TEXT_SCALE" then
				CombatText:SetScale(v)
			else
				_G[k] = v
			end
		end
	end
	
	self:WipeCache() -- renew color caches
	self:RefreshLevelEvents() -- register/unregister level events according to options
	
	-- parent CombatText to WorldFrame so you can still see it while the UI is hidden
	if profile.ParentCombatText and CombatText then
		CombatText:SetParent(WorldFrame)
	end
end

	----------------------
	--- Slash Commands ---
	----------------------

local enable = {
	["1"] = true,
	on = true,
	enable = true,
	load = true,
}

local disable = {
	["0"] = true,
	off = true,
	disable = true,
	unload = true,
}

function SCR:SlashCommand(input)
	if enable[input] then
		self:Enable()
		self:Print("|cffADFF2F"..VIDEO_OPTIONS_ENABLED.."|r")
	elseif disable[input] then
		self:Disable()
		self:Print("|cffFF2424"..VIDEO_OPTIONS_DISABLED.."|r")
	elseif input == "toggle" then
		self:SlashCommand(self:IsEnabled() and "0" or "1")
	else
		ACD:Open("ScrollingChatText_Parent")
	end
end

	--------------
	--- Events ---
	--------------

S.channels = {} -- also used for color options
local chanGroup = options.args.main.args.inline2.args

-- There doesn't seem to be an event that shows when CHANNEL_UI_UPDATE has completely finished updating (it fires multiple times in a row)
-- and I don't know a way to throttle it to only the very last call, so this will generate some garbage
function SCR:CHANNEL_UI_UPDATE()
	local channels = S.channels
	wipe(channels)
	local chanList = {GetChannelList()}
	for i = 1, #chanList, 2 do
		channels[chanList[i]] = chanList[i+1]
	end
	for i = 1, 10 do
		if channels[i] then
			chanGroup["CHANNEL"..i] = {
				type = "toggle", order = i,
				width = "normal", descStyle = "",
				name = function() return "|cff"..S.chatCache["CHANNEL"..i]..i..". "..channels[i].."|r" end,
			}
		else
			chanGroup["CHANNEL"..i] = nil
		end
	end
	
	ACR:NotifyChange("ScrollingChatText_Parent")
end

function SCR:PLAYER_REGEN(event, ...)
	combatState = (event == "PLAYER_REGEN_DISABLED") and true or false -- "PLAYER_REGEN_ENABLED"
end

local lastState, delayState

local function StateFilter()
	local t = time() -- throttle
	if t > (delayState or 0) then
		delayState = t + 1
		
		local combat = filter.Combat and combatState
		local nocombat = filter.NoCombat and not combatState
		
		local isRaid = IsInRaid()
		local isParty = IsInGroup()
		
		local raid = filter.Raid and isRaid
		local party = filter.Party and (not isRaid and isParty)
		local solo = filter.Solo and (not isRaid and not isParty)
		
		lastState = (combat or nocombat) and (raid or party or solo)
	end
	
	return lastState
end

local space, indexed = {}, {}

-- results might vary depending on usage of wide/thin characters (e.g. I vs W),
-- word placement and char length of icon/time/name/channel
local function SplitMessage(msg)
	-- rawify hyperlinks
	local msglen = utf8len(gsub(msg, "|c.-(%[.-%]).-|r", "%1"))
	
	if msglen > 75 then
		
		wipe(space)
		
		-- find space positions/repetitions
		local pos1, pos2 = strfind(msg, "%s+")
		while pos2 do
			space[pos1] = true
			space[pos2] = true
			pos1, pos2 = strfind(msg, "%s+", pos2 + 1)
		end
		
		-- indexed table
		wipe(indexed)
		for k in pairs(space) do
			tinsert(indexed, k)
		end
		sort(indexed)
		
		-- determine positions to divide at
		local first, second
		if msglen > 160 then
			-- there is room to improve since I don't even know what I'm doing. really
			first = (msglen / 3) - 25
			second = (first * 2) + 25
		else
			first = (msglen / 2) - 10
		end
		
		-- divide at possibly the closest positions
		for _, v in ipairs(indexed) do
			if first and v > first then
				msg = utf8sub(msg, 1, v).."\n"..utf8sub(msg, v + 1)
				first = nil
			elseif second and v > second then
				-- account for characters being moved +1 to the right
				msg = utf8sub(msg, 1, v + 1).."\n"..utf8sub(msg, v + 2)
				second = nil
				break
			end
		end
	end
	return msg
end

local args = {}
local fonts = LSM:HashTable(LSM.MediaType.FONT)

local ICON_LIST = ICON_LIST
local ICON_TAG_LIST = ICON_TAG_LIST

function SCR:CHAT_MSG(event, ...)
	if not StateFilter() then return end
	
	local msg, sourceName, lang, channelString, destName, flags, _, channelID, channelName, _, lineId, guid = ...
	if not guid or guid == "" then return end
	
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	local isPlayer = strfind(sourceName, S.playerName)
	if profile.FilterSelf and (isPlayer or S.INFORM[event]) then return end -- filter self
	if isChat and isPlayer and not profile.FilterSelf then return end -- prevent looping your own chat
	
	local subevent = event:match("CHAT_MSG_(.+)")
	-- options filter
	if chat[subevent] or (subevent == "CHANNEL" and chat["CHANNEL"..channelID]) then
		
		local class, race, sex = unpack(S.playerCache[guid])
		if not class then return end
		
		local raceIcon = S.GetRaceIcon(strupper(race).."_"..S.sexremap[sex], 1, 1)
		local classIcon = S.GetClassIcon(class, 1, 1)
		args.icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
		
		local chanColor = S.chatCache[(subevent == "CHANNEL") and "CHANNEL"..channelID or subevent]
		args.chan = "|cff"..chanColor..(channelID > 0 and channelID or L[subevent]).."|r"
		
		sourceName = profile.TrimRealm and sourceName:match("(.-)%-") or sourceName -- remove realm names
		args.name = "|cff"..S.classCache[class]..sourceName.."|r"
		
		-- this should be done before converting to raid target icons
		if profile.Split then
			msg = SplitMessage(msg)
		end
		
		-- language; FrameXML\ChatFrame.lua (4.3.4.15595)
		if #lang > 0 and lang ~= "Universal" and lang ~= S.defaultLang then
			msg = format("[%s] %s", lang, msg)
		end
		
		if not isChat then
			-- convert Raid Target icons; FrameXML\ChatFrame.lua L3166 (4.3.4.15595)
			for c in gmatch(msg, "%b{}") do
				local rt = strlower(gsub(c, "[{}]", ""))
				if ICON_TAG_LIST[rt] and ICON_LIST[ICON_TAG_LIST[rt]] then
					msg = msg:gsub(c, ICON_LIST[ICON_TAG_LIST[rt]].."0|t")
				end
			end
		end
		
		-- try to continue the coloring if broken by hyperlinks; this is kinda ugly I guess
		msg = msg:gsub("|r", "|r|cff"..chanColor)
		args.msg = "|cff"..chanColor..msg.."|r"
		
		self:Output(profile.Message, args, profile.color[subevent])
	end
end

local linkColor = {
	achievement = "FFFF00",
	battlepet = "FD200",
	battlePetAbil = "4E96F7",
	currency = "00AA00",
	enchant = "FFD000",
	instancelock = "FF8000",
	--item = "FFFFFF", -- multiple item colors
	journal = "66BBFF",
	quest = "FFFF00",
	spell = "71D5FF",
	talent = "4E96F7",
	trade = "FFD000",
}

local gsubtrack = {}

function SCR:CHAT_MSG_BN(event, ...)
	if not StateFilter() then return end
	
	local msg, realName, _, _, _, _, _, _, _, _, _, _, presenceId = ...
	
	-- ToDo: add support for multiple toons / BNGetFriendToonInfo
	local _, toonName, client, _, _, _, _, class = BNGetToonInfo(presenceId)
	
	local isPlayer = strfind(toonName, S.playerName) -- participating in a Real ID conversation
	if profile.FilterSelf and (isPlayer or S.INFORM[event]) then return end
	
	local subevent = event:match("CHAT_MSG_(.+)")
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	
	if not chat[subevent] then return end
	
	if client == BNET_CLIENT_WOW then	
		-- you can chat with a friend from a friend, through a Real ID Conversation,
		-- but only the toon name, and not the class/race/level/realm would be available
		local classIcon = (class ~= "") and S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1) or ""
		args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
		-- can't add (or very hard to) add Race Icons, since the BNGetToonInfo return values are localized; also would need to know the sex
		
		local chanColor = S.chatCache[subevent]
		args.chan = "|cff"..chanColor..L[subevent].."|r"
		
		local name = isChat and toonName or realName -- can't SendChatMessage Real ID Names, which is understandable
		args.name = (class ~= "") and "|cff"..S.classCache[S.revLOCALIZED_CLASS_NAMES[class]]..name.."|r" or "|cff"..chanColor..name.."|r"
		
		if profile.Split then
			msg = SplitMessage(msg)
		end
		
		if not isChat then
			for k in gmatch(msg, "%b{}") do
				local rt = strlower(gsub(k, "[{}]", ""))
				if ICON_TAG_LIST[rt] and ICON_LIST[ICON_TAG_LIST[rt]] then
					msg = msg:gsub(k, ICON_LIST[ICON_TAG_LIST[rt]].."0|t")
				end
			end
		end
		
		wipe(gsubtrack)
		-- color hyperlinks; coloring is omitted in Real ID chat
		for k in string.gmatch(msg, "|H.-|h.-|h") do
			local linkType, linkId = k:match("|H(.-):(.-):")
			if linkType == "item" then
				local quality = select(3, GetItemInfo(linkId)) or -1 -- item not yet cached
				msg = msg:gsub(k:gsub("(%p)", "%%%1"), format("%s%s|r|cff"..chanColor, ITEM_QUALITY_COLORS[quality].hex, k))
			elseif not gsubtrack[linkColor[linkType]] then
				msg = msg:gsub("|H"..linkType..":.-|h.-|h", "|cff"..linkColor[linkType].."%1|r|cff"..chanColor) -- continue coloring
				gsubtrack[linkColor[linkType]] = true -- substituted all instances of the linkType
			end
		end
		
		args.msg = "|cff"..chanColor..msg.."|r"
		
		self:Output(profile.Message, args, profile.color[subevent])
	else
		args.icon = (profile.IconSize > 1 and not isChat) and "|TInterface\\ChatFrame\\UI-ChatIcon-"..S.clients[client]..":14:14:0:-1|t" or ""
		
		local chanColor = S.chatCache[subevent]
		args.chan = "|cff"..chanColor..L[subevent].."|r"
		
		local name = isChat and toonName or realName
		args.name = "|cff"..chanColor..name.."|r"
		
		args.msg = "|cff"..chanColor..msg.."|r"
		
		self:Output(profile.Message, args, profile.color[subevent])
	end
end

function SCR:CHAT_MSG_STATIC(event, ...)
	if not StateFilter() then return end
	
	local msg, sourceName, _, _, destName, _, _, _, _, _, _, guid = ...
	if not guid or guid == "" then return end
	local class, race, sex = unpack(S.playerCache[guid])
	if not class then return end
	
	-- filter own achievs/emotes; avoid spamloop
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	local isPlayer = strfind(sourceName, S.playerName)
	if profile.FilterSelf and isPlayer then return end
	if isChat and isPlayer and not profile.FilterSelf then return end
	
	local subevent = event:match("CHAT_MSG_(.+)")	
	if not chat[subevent] then return end
	
	local color = profile.color[subevent]
	sourceName = profile.TrimRealm and sourceName:match("(.-)%-") or sourceName -- remove realm names
	
	if subevent == "EMOTE" then
		msg = "|cff"..S.classCache[class]..sourceName.."|r "..msg
	elseif subevent == "TEXT_EMOTE" then
		msg = msg:gsub(sourceName, "|cff"..S.classCache[class]..sourceName.."|r")
	else
		msg = msg:format("|cffFFFFFF[|r|cff"..S.classCache[class]..sourceName.."|r|cffFFFFFF]|r")
	end
	
	self:Pour(msg, color.r, color.g, color.b, fonts[profile.FontWidget], profile.FontSize)
end

-- events are (un)registered according to options, no need for filtering
function SCR:CHAT_MSG_OTHER(event, ...)
	if not StateFilter() then return end
	
	local msg, sourceName, _, fullChannel, _, _, _, chanID, chanName, _, _, guid = ...
	
	local subEvents = S.OtherSubEvents[event]
	if subEvents then
		if type(subEvents) == "table" then
			if event == "CHAT_MSG_CHANNEL_NOTICE" then
				-- sanity check for (likely) missing keys
				local k = subEvents[msg]
				if k then
					msg = k:format(chanID, fullChannel)
				end
			elseif event == "CHAT_MSG_CHANNEL_NOTICE_USER" then
				local k = subEvents[msg]
				if k then
					msg = k:format(chanID, fullChannel, sourceName)
				end
			elseif event == "CHAT_MSG_BN_INLINE_TOAST_ALERT" then
				local k = subEvents[msg]
				if k then
					msg = k:format(sourceName)
				end
			end
		else
			if event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
				local class, race, sex = unpack(S.playerCache[guid])
				msg = "["..chanID.."] "..subEvents:format("|cff"..S.classCache[class].."["..sourceName.."]|r")
			end
		end
	end
	
	-- creature/boss
	if S.MONSTER_EMOTE[event] then
		msg = msg:format(sourceName)
	elseif S.MONSTER_CHAT[event] then
		msg = S.MONSTER_CHAT[event]:format(sourceName)..msg
	end
	
	-- To Do: SplitMessage is not yet tuned for static messages
	--[[
	if profile.Split then
		msg = SplitMessage(msg)
	end
	]]
	
	local color = profile.color[S.EventToColor[event]]
	
	self:Pour(msg, color.r, color.g, color.b, fonts[profile.FontWidget], profile.FontSize)
end

function SCR:ReplaceArgs(msg, args)
	for k in gmatch(msg, "%b<>") do
		-- remove <>, make case insensitive
		local s = strlower(gsub(k, "[<>]", ""))
		
		-- escape special characters
		-- a maybe better alternative to %p is "[%%%.%-%+%?%*%^%$%(%)%[%]%{%}]"
		s = gsub(args[s] or s, "(%p)", "%%%1")
		k = gsub(k, "(%p)", "%%%1")
		
		msg = msg:gsub(k, s)
	end
	return msg
end

local nokey = {}

function SCR:Output(msg, args, color)
	args.time = S.GetTimestamp()
	msg = self:ReplaceArgs(msg, args)
	
	color = profile.ColorMessage and color or nokey
	self:Pour(msg, color.r, color.g, color.b, fonts[profile.FontWidget], profile.FontSize)
end
