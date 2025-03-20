if not CLM or not CLM.GUI or not CLM.GUI.AuctionManager then return end

-- ------ CLM common cache ------- --
local LOG       = CLM.LOG
local CONSTANTS = CLM.CONSTANTS
local UTILS     = CLM.UTILS

local ScrollingTable = LibStub("ScrollingTable")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")


local eventDispatcher = LibStub("EventDispatcher")
if not eventDispatcher then return end

local ClassicLootManager_Anachronox = {}

local NeedDebugInfo = false

local manager

local function MyPrint(text)
	if (NeedDebugInfo) then
		print(text)
	end
end

local function PrintTable(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            MyPrint(formatting)
            PrintTable(v, indent + 1)
        else
            MyPrint(formatting .. tostring(v))
        end
    end
end


local rankColumn = {
    name = "Rank",
    width = 40,
    color = {r = 0.93, g = 0.70, b = 0.13, a = 1.0},
    sortnext = 4,
    align = "CENTER"
}

local idColumn = {
    name = "RankId",
    width = 0,
    color = {r = 0.93, g = 0.70, b = 0.13, a = 1.0},
    sortnext = 4,
    align = "CENTER"
}

local function GetGuildMemberRank(targetName)
    if not IsInGuild() then
        return "No Guild"
    end

    for i = 1, GetNumGuildMembers() do
        local name, rankName = GetGuildRosterInfo(i)

        -- Check full name (with realm)
        if name == targetName then
            return rankName
        end

        -- Check without realm name
        name = strsplit("-", name)
        if name == targetName then
            return rankName
        end
    end

    return "Unknown"
end

local function GetGuildMemberRankId(targetName)
    if not IsInGuild() then
        return 0
    end
    local retRank = 0
    for i = 1, GetNumGuildMembers() do
        local name, rankName, rankId = GetGuildRosterInfo(i)

        -- Check full name (with realm)
        if name == targetName then
            retRank = rankId
			break
        end

        -- Check without realm name
        name = strsplit("-", name)
        if name == targetName then
            retRank = rankId
			break
        end
    end
	-- GM = Officer = Base Raider
	if retRank <= 3 then
		retRank = 3
	end

    return 10 - retRank
end

local function AdjustCols()
	if CLM.GUI.AuctionManager.BidList.st.cols[3].sortnext == 7 then 
		return 
	end
	CLM.GUI.AuctionManager.BidList.st.cols[3].sortnext=7
	CLM.GUI.AuctionManager.BidList.st.cols[3].width=60
	CLM.GUI.AuctionManager.BidList.st.SetDisplayCols(CLM.GUI.AuctionManager.BidList.st,CLM.GUI.AuctionManager.BidList.st.cols)
end
	

local function ExternalRankColumnCallback(auction, item, name, response)
	MyPrint(name)
    local rankName = GetGuildMemberRank(name)
	AdjustCols()
    return {value = rankName, color = rankColumn.color}
end

local function ExternalIdColumnCallback(auction, item, name, response)
	MyPrint(name)
    local rankId = GetGuildMemberRankId(name)
	
    return {value = rankId, color = idColumn.color}
end
			

local function RegisterMyColumn()
    MyPrint("Checking externalColumns...")
    MyPrint("externalColumns:", CLM.GUI.AuctionManager.externalColumns)
    MyPrint("_initialized:", CLM.GUI.AuctionManager._initialized)
	
	local manager = CLM.GUI.AuctionManager

    if manager.externalColumns then
        MyPrint("externalColumns is ready. Registering column...")
		manager.externalColumns[#manager.externalColumns+1] = {column = idColumn, callback = ExternalIdColumnCallback}
		manager.externalColumns[#manager.externalColumns+1] = {column = rankColumn, callback = ExternalRankColumnCallback}
		MyPrint("externalColumns registered")
		PrintTable(manager.externalColumns)
		
		manager.BuildColumns(manager)
        -- CLM.GUI.AuctionManager.RegisterExternalColumn(column, ExternalColumnCallback)
    else
        MyPrint("externalColumns not ready. Retrying...")
        C_Timer.After(1, RegisterMyColumn)
    end
end
-- Hook into the initialization of the AuctionManager GUI
local function OnInitialize()
    if CLM.GUI.AuctionManager._initialized and CLM.GUI.AuctionManager.externalColumns then
		MyPrint("Trying to register...")
        RegisterMyColumn()
		AdjustCols()
		MyPrint("Registration success ...")
    else
        -- If AuctionManager is not ready, retry after a delay
        C_Timer.After(1, OnInitialize)
		MyPrint("Registration failed trying again soon...")
    end
end

OnInitialize()

