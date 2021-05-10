local NAME, S = ...
local SCR = ScrollingChatText

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

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
}

-- using ipairs to iterate through appKey by index
-- but still want to be able to use key-value tables
local appValue = {
	ScrollingChatText_Main = options.args.main,
	ScrollingChatText_Advanced = options.args.advanced,
	ScrollingChatText_FCT = options.args.fct,
	ScrollingChatText_Colors = options.args.colors,
}

function SCR:OnInitialize()
	if ChatTypeInfo.YELL.g == 1 then
		f:SetScript("OnUpdate", f.WaitInitialize)
		return
	end

	self:GetChatTypeInfo()
	self.db = LibStub("AceDB-3.0"):New("ScrollingChatTextDB", S.defaults, true)

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

	-- Legion: Blizzard_CombatText is disabled by default, but we listed it as a dependency so its enabled
	-- we still want that output sink, without enabling the option for FCT, but ...

	-- CombatText_AddMessage() actually works, but LibSink checks for (SHOW_COMBAT_TEXT = "1")
	-- and we use LibSink. So the only way to use that output is to also enable Blizzard FCT. will work around it

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
	for i = 1, 2 do
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
local CUU_timer

local function CHANNEL_UI_UPDATE()
	local channels = S.channels
	wipe(channels)
	local chanList = {GetChannelList()}

	for i = 1, #chanList, 3 do
		local name = chanList[i+1]
		channels[chanList[i]] = strfind(name, "Community:") and ChatFrame_ResolveChannelName(name) or name
	end

	for i = 1, MAX_WOW_CHAT_CHANNELS do
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

-- on login ChatFrame_ResolveChannelName does not yet have the subchannel names
function SCR:CHANNEL_UI_UPDATE()
	-- throttle, cancel any previous timer
	if CUU_timer then
		CUU_timer:Cancel()
	end
	CUU_timer = C_Timer.NewTimer(2, CHANNEL_UI_UPDATE)
end

function SCR:PLAYER_REGEN(event)
	combatState = (event == "PLAYER_REGEN_DISABLED") and true or false -- "PLAYER_REGEN_ENABLED"
end

local lastState, delayState

local function StateFilter()
	local t = time() -- throttle
	if t > (delayState or 0) then
		delayState = t + 1

		local combat = filter.Combat and combatState
		local nocombat = filter.NoCombat and not combatState

		local isGroup = IsInGroup()
		local group = filter.Group and isGroup
		local solo = filter.Solo and not isGroup

		lastState = (combat or nocombat) and (group or solo)
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

local ICON_LIST = ICON_LIST
local ICON_TAG_LIST = ICON_TAG_LIST

function SCR:CHAT_MSG(event, ...)
	if not StateFilter() then return end

	local msg, sourceName, lang, channelString, destName, flags, _, channelID, channelName, _, lineId, guid, bnSenderID = ...

	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	local isPlayer = (guid == S.playerGUID)

	if profile.FilterSelf and (isPlayer or S.INFORM[event]) then return end -- filter self
	if isChat and isPlayer and not profile.FilterSelf then return end -- prevent looping your own chat

	local subevent = event:match("CHAT_MSG_(.+)")
	local chanColor = S.chatCache[S.CHANNEL[subevent] and "CHANNEL"..channelID or subevent]

	if chat[subevent] or (S.CHANNEL[subevent] and chat["CHANNEL"..channelID]) then
		-- this should be done before converting to raid target icons
		msg = profile.Split and SplitMessage(msg) or msg

		if guid then
			local class, race, sex = unpack(S.playerCache[guid])
			if not class then return end

			local x1, y1, x2, y2 = 4, 0, 4, 0 -- Legion: something is screwing with the icon positioning in FCT
			if profile.sink20OutputSink == "Blizzard" then x1, y1, x2, y2 = -14, -8, 0, -8 end
			local raceIcon = S.GetRaceIcon(race, sex, x1, y1)
			local classIcon = S.GetClassIcon(class, x2, y2)

			args.icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
			args.chan = "|cff"..chanColor..(channelID > 0 and channelID or L[subevent]).."|r"

			sourceName = profile.TrimRealm and sourceName:match("(.-)%-") or sourceName -- remove realm names
			args.name = "|cff"..S.classCache[class]..sourceName.."|r"

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
		else -- must be a non-wow Communities channel
			--isPlayer = (bnSenderID == 1) -- don't know how to guess it
			if S.CHANNEL[subevent] and chat["CHANNEL"..channelID] then
				args.chan = "|cff"..chanColor..channelID.."|r"
				args.name = "|cff71D5FF"..sourceName.."|r"
				args.icon = "" -- trim out icon arg
			end
		end

		-- try to continue the coloring if broken by hyperlinks; this is kinda ugly I guess
		msg = msg:gsub("|r", "|r|cff"..chanColor)
		args.msg = "|cff"..chanColor..msg.."|r"

		self:ChatOutput(profile.Message, args, profile.color[subevent])
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
	local msg, realName, _, _, _, _, _, _, _, _, _, _, bnSenderID = ...
	local info = C_BattleNet.GetAccountInfoByID(bnSenderID)
	local accInfo = info.gameAccountInfo

	local isPlayer = strfind(accInfo.characterName or "", S.playerName) -- participating in Real ID whispers
	if profile.FilterSelf and (isPlayer or S.INFORM[event]) then return end

	local subevent = event:match("CHAT_MSG_(.+)")
	local isChat = S.LibSinkChat[profile.sink20OutputSink]

	if not chat[subevent] then return end

	if accInfo.clientProgram == BNET_CLIENT_WOW then
		-- you can chat with a friend from a friend, through Real ID whispers
		-- but only the toon name, and not the class/race/level/realm would be available
		local classIcon = accInfo.className and S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[accInfo.className], -6, -10) or ""
		args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
		-- can't add add race icons since the return values are localized and need to know the sex

		local chanColor = S.chatCache[subevent]
		args.chan = "|cff"..chanColor..L[subevent].."|r"

		local name = isChat and accInfo.characterName or realName -- can't SendChatMessage Real ID Names, which is understandable
		local classColor = S.classCache[S.revLOCALIZED_CLASS_NAMES[accInfo.className]]
		args.name = (accInfo.className ~= "") and "|cff"..classColor..name.."|r" or "|cff"..chanColor..name.."|r"

		msg = profile.Split and SplitMessage(msg) or msg

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

		self:ChatOutput(profile.Message, args, profile.color[subevent])
	else
		args.icon = (profile.IconSize > 1 and not isChat and accInfo.clientProgram)
			and "|TInterface\\ChatFrame\\UI-ChatIcon-"..S.clients[accInfo.clientProgram]..":14:14:0:-1|t" or ""

		local chanColor = S.chatCache[subevent]
		args.chan = "|cff"..chanColor..L[subevent].."|r"

		local name = isChat and accInfo.characterName or realName
		args.name = "|cff"..chanColor..name.."|r"

		args.msg = "|cff"..chanColor..msg.."|r"

		self:ChatOutput(profile.Message, args, profile.color[subevent])
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
	local isPlayer = (guid == S.playerGUID)

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

	self:Output(msg, color)
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

	local color = profile.color[S.EventToColor[event]]

	self:Output(msg, color)
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

local nokey = {r=1, g=1, b=1}

function SCR:ChatOutput(msg, args, color)
	args.time = S.GetTimestamp()
	msg = self:ReplaceArgs(msg, args)

	color = profile.ColorMessage and color or nokey

	self:Output(msg, color)
end

function SCR:Output(msg, color)
	-- Legion: if we can to output to Blizzard FCT but LibSink sees
	--  that Blizzard FCT is disabled (only the option), then we work around it
	if profile.sink20OutputSink == "Blizzard" and SHOW_COMBAT_TEXT == "0" then
		CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, color.r, color.g, color.b)
	else
		self:Pour(msg, color.r, color.g, color.b)
	end
end
