if isClient() then return end

local Prestige = require("OMHTS_Prestige")
local State = require("OMHTS_State")
local Bootstrap = {}

-- ConnectionDetails carries this initial state before the character creator.
-- Ordinary GlobalModData replies wait until playerConnectSent on first join.
---@return table
function Bootstrap.initialState()
    local store = ModData.get("OMHTraitShop_State_v1")
    if type(store) ~= "table" or store.schema ~= State.SCHEMA or not State.isCounter(store.nextLife)
        or type(store.accounts) ~= "table" or type(store.creations) ~= "table" then
        return { schema = 1, ready = false }
    end
    local bonuses = {}
    for account, record in pairs(store.accounts) do
        if type(account) == "string" then
            if State.isRecord(record) then
                local bonus = Prestige.pending(record)
                if bonus > 0 then
                    bonuses[account] = bonus
                end
            else
                bonuses[account] = false
            end
        end
    end
    -- Only the already-readable creation entitlement is exported, never wallets
    -- or account records. Zero balances are implicit in a complete, ready map.
    return { schema = 1, ready = true, bonuses = bonuses }
end

---@param system table
---@param command string
---@param player IsoPlayer
---@param args table
---@return nil
local function ignoreCommand(system, command, player, args)
    -- This system is a read-only connection snapshot, not a mutation endpoint.
end

---@return nil
local function initialize()
    if not isServer() then return end
    local system = SGlobalObjects.registerSystem(Prestige.SYSTEM)
    local data = system:getModData()
    data.getInitialStateForClient = Bootstrap.initialState
    data.OnClientCommand = ignoreCommand
    print("[OMH Trait Shop] connection Prestige preview ready")
end

Events.OnSGlobalObjectSystemInit.Add(initialize)
return Bootstrap
