local NAME, S = ...
local SCR = ScrollingChatText

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local L = S.L
local options = S.options
local profile

local pairs, ipairs = pairs, ipairs
local strsub, gsub = strsub, gsub

	-------------------------
	--- ChatTypeInfo Wait ---
	-------------------------

-- ChatTypeInfo does not yet contain the color info, which we need for the defaults
local f = CreateFrame("Frame")

function f:WaitInitialize(elapsed)
	if ChatTypeInfo.SAY.r then
		SCR:OnInitialize()
		self:SetScript("OnUpdate", nil)
	end
end

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"ScrollingChatText_Main",
	"ScrollingChatText_Advanced",
	"ScrollingChatText_Colors",
	"ScrollingChatText_Extra",
}

-- using ipairs to iterate through appKey by index
-- but still want to be able to use key-value tables
local appValue = {
	ScrollingChatText_Main = options.args.main,
	ScrollingChatText_Advanced = options.args.advanced,
	ScrollingChatText_Colors = options.args.colors,
	ScrollingChatText_Extra = options.args.extra,
}

local slashCmds = {"scr", "scrollchat", "scrollingchat", "scrollingchattext"}

function SCR:OnInitialize()
	if not ChatTypeInfo.SAY.r then
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
	ACD:SetDefaultSize("ScrollingChatText_Parent", 700, 570)
	
	-- setup profiles now, self reminder: requires db to be already defined
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	options.args.profiles.order = 5
	tinsert(appKey, "ScrollingChatText_Profiles")
	appValue.ScrollingChatText_Profiles = options.args.profiles
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME)
	end
	
	for _, v in ipairs(slashCmds) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
	
	if not S.CombatTextEnabled.sct then
		self:RegisterChatCommand("sct", "SlashCommand")
	end
	
	-- keybind info not yet available (but we're delayed anyway)
	options.args.advanced.args.inline1.args.ParentCombatText.desc = format(UI_HIDDEN, GetBindingText(GetBindingKey("TOGGLEUI"), "KEY_"))
	
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
	
	-- Level events
	for _, v in pairs(S.LevelEvents) do
		self:RegisterEvent(v)
	end
	
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
	self:SetSinkStorage(profile) -- LibSink savedvars
	
	-- update table references in other files
	for i = 1, 3 do
		self["RefreshDB"..i](self)
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

local channels = {}
local chanGroup = options.args.main.args.inline2.args

-- There doesn't seem to be an event that shows when CHANNEL_UI_UPDATE has completely finished updating (it fires multiple times in a row)
-- and I don't know a way to throttle it to only the very last call, so this will generate some garbage
function SCR:CHANNEL_UI_UPDATE()
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
				name = " |cffFFC0C0"..i..". "..channels[i].."|r",
				get = "GetValue", set = "SetValue",
			}
		else
			chanGroup["CHANNEL"..i] = nil
		end
	end
	ACR:NotifyChange("ScrollingChatText_Parent")
end

function SCR:PLAYER_REGEN(event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		combatState = true
	elseif event == "PLAYER_REGEN_ENABLED" then
		combatState = false
	end
end

local function CombatFilter()
	if (profile.NotInCombat and not combatState) or (profile.InCombat and combatState) then
		return true
	end
end

local space, sorted = {}, {}

local function SplitMessage(msg)
	-- results might vary depending on usage of wide/thin characters (e.g. I vs W),
	-- word placement and char length of icon/time/name/channel
	local msglen = strlen(gsub(msg, "|c.-(%[.-%]).-|r", "%1"))
	
	if msglen > 75 then
		
		wipe(space)
		-- what happened to string.gfind? :(
		-- avoid letting strfind choke on () and []
		for c in gmatch(msg, "[^%p]%s+[^%p]") do
			-- fails when there are multiple instances of the same capture
			-- e.g. "o g" in "go go go go" or "so good so gray"
			local a, b = strfind(msg, c)
			space[a+1] = true
			space[b-1] = true
		end
		
		wipe(sorted)
		for k in pairs(space) do
			tinsert(sorted, k)
		end
		sort(sorted)
		
		local first, second
		if msglen > 160 then
			-- there is room to improve since I don't even know what I'm doing. really
			first = (msglen / 3) - 25
			second = (first * 2) + 25
		else
			first = (msglen / 2) - 20
		end
		
		for _, v in pairs(sorted) do
			if first and v > first then
				msg = strsub(msg, 1, v).."\n"..strsub(msg, v+1)
				first = nil
			elseif second and v > second then
				-- account for characters being moved +1 to the right
				msg = strsub(msg, 1, v+1).."\n"..strsub(msg, v+2)
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
	local msg, sourceName, _, channelString, destName, _, _, channelID, channelName, _, _, guid = ...
	if not guid or guid == "" then return end
	
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	local isPlayer = (sourceName == S.playerName)
	if profile.FilterSelf and isPlayer then return end -- filter self
	if isChat and isPlayer and not profile.FilterSelf then return end -- prevent looping your own chat
	
	local subevent = event:match("CHAT_MSG_(.+)")
	-- options filter
	if profile[subevent] or (subevent == "CHANNEL" and profile["CHANNEL"..channelID]) then
		local _, class, _, race, sex, realm = GetPlayerInfoByGUID(guid)
		if not class then return end
		
		local raceIcon = S.GetRaceIcon(strupper(race).."_"..S.sexremap[sex], 1, 1)
		local classIcon = S.GetClassIcon(class, 1, 1)
		args.icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
		
		local chanColor = S.chanCache[subevent]
		args.chan = "|cff"..chanColor..(channelID > 0 and channelID or L[subevent]).."|r"
		
		sourceName = profile.TrimRealm and sourceName:match("(.-)%-") or sourceName -- remove realm names
		args.name = "|cff"..S.classCache[class]..sourceName.."|r"
		
		-- this should be done before converting to raid target icons
		if profile.sink20OutputSink == "Blizzard" and profile.Split then
			msg = SplitMessage(msg)
		end
		
		if not isChat then
			-- convert Raid Target icons; FrameXML\ChatFrame.lua L3168 (4.3.3.15354)
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

function SCR:CHAT_MSG_ACH(event, ...)
	local msg, sourceName, _, channelString, destName, _, _, channelID, channelName, _, _, guid = ...
	local _, class, _, race, sex = GetPlayerInfoByGUID(guid)
	if not class then return end
	
	-- filter own achievs; avoid spamloop
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	local isPlayer = (sourceName == S.playerName)
	if profile.FilterSelf and isPlayer then return end
	if isChat and isPlayer and not profile.FilterSelf then return end
	
	local subevent = event:match("CHAT_MSG_(.+)")	
	if profile[subevent] then
		local raceIcon = S.GetRaceIcon(strupper(race).."_"..S.sexremap[sex], 1, 1)
		local classIcon = S.GetClassIcon(class, 1, 1)
		local icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
		local color = profile.color[subevent]
		sourceName = profile.TrimRealm and sourceName:match("(.-)%-") or sourceName -- remove realm names
		local name = "|cffFFFFFF[|r|cff"..S.classCache[class]..sourceName.."|r|cffFFFFFF]|r"
		self:Pour(icon.." "..msg:format(name), color.r, color.g, color.b, fonts[profile.FontWidget], profile.FontSize)
	end
end

local linkColor = {
	achievement = "FFFF00",
	currency = "00AA00",
	enchant = "FFD000",
	instancelock = "FF8000",
	item = "FFFFFF", -- don't know much about item caching; in order to get the specific quality color
	journal = "66BBFF",
	quest = "FFFF00",
	spell = "71D5FF",
	talent = "4E96F7",
	trade = "FFD000",
}

local gsubtrack = {}

function SCR:CHAT_MSG_BN(event, ...)
	local msg, realName, _, _, _, _, _, _, _, _, _, _, presenceId = ...
	local _, toonName, client, _, _, _, _, class = BNGetToonInfo(presenceId)
	
	local subevent = event:match("CHAT_MSG_(.+)")
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	
	if profile[subevent] then
		if client == BNET_CLIENT_WOW then
			local isPlayer = (toonName == S.playerName) -- participating in a Real ID conversation
			if profile.FilterSelf and isPlayer then return end
			
			-- you can chat with a friend from a friend, through a Real ID Conversation,
			-- but only the toon name, and not the class/race/level/realm would be available
			local classIcon = (class ~= "") and S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1) or ""
			args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
			-- can't add (or very hard to) add Race Icons, since the BNGetToonInfo return values are localized; also would need to know the sex
			
			local chanColor = S.chanCache[subevent]
			args.chan = "|cff"..chanColor..L[subevent].."|r"
			
			local name = isChat and toonName or realName -- can't SendChatMessage Real ID Names, which is understandable
			args.name = (class ~= "") and "|cff"..S.classCache[S.revLOCALIZED_CLASS_NAMES[class]]..name.."|r" or "|cff"..chanColor..name.."|r"
			
			if profile.sink20OutputSink == "Blizzard" and profile.Split then
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
				local linkType = k:match("|H(.-):")
				if not gsubtrack[linkColor[linkType]] then
					gsubtrack[linkColor[linkType]] = true -- substituted all instances of the linkType
					msg = msg:gsub("|H"..linkType..":.-|h.-|h", "|cff"..linkColor[linkType].."%1|r|cff"..chanColor) -- continue coloring
				end
			end
			
			args.msg = "|cff"..chanColor..msg.."|r"
			
			self:Output(profile.Message, args, profile.color[subevent])
		elseif client == BNET_CLIENT_SC2 or client == BNET_CLIENT_D3 then
			args.icon = (profile.IconSize > 1 and not isChat) and "|TInterface\\ChatFrame\\UI-ChatIcon-"..S.clients[client]..":14:14:0:-1|t" or ""
			
			local chanColor = S.chanCache[subevent]
			args.chan = "|cff"..chanColor..L[subevent].."|r"
			
			local name = isChat and toonName or realName
			args.name = "|cff"..chanColor..name.."|r"
			
			args.msg = "|cff"..chanColor..msg.."|r"
			
			self:Output(profile.Message, args, profile.color[subevent])
		end
	end
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
	if not CombatFilter() then return end
	
	args.time = S.GetTimestamp()
	msg = self:ReplaceArgs(msg, args)
	
	color = profile.ColorMessage and color or nokey
	self:Pour(msg, color.r, color.g, color.b, fonts[profile.FontWidget], profile.FontSize)
end
