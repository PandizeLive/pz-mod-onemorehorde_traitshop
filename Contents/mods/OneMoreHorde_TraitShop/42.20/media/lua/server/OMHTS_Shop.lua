if isClient() then return end

local State = require("OMHTS_State")
local Catalog = require("OMHTS_Catalog")
local Shop = {}

---@param player IsoPlayer
---@param record table
---@param forceSync boolean
---@return boolean
function Shop.reconcile(player, record, forceSync)
    if record.life.status ~= "alive" or player:isDead() then return false end
    local changed = false
    for id in pairs(record.life.purchases) do
        local definition = Catalog.definition(id)
        if Catalog.supported(definition) and not player:hasTrait(definition:getType()) then
            player:getCharacterTraits():add(definition:getType())
            changed = true
        end
    end
    if isServer() and (changed or forceSync) then
        sendSyncPlayerFields(player, 2)
    end
    return changed
end

---@nodiscard
---@param player IsoPlayer
---@param record table
---@param id string
---@return string
---@return number
function Shop.offer(player, record, id)
    local definition = Catalog.definition(id)
    if not Catalog.supported(definition) then return "unsupported", 0 end
    local price = Catalog.price(definition)
    if not price then return "settings", 0 end
    if record.life.purchases[id] or player:hasTrait(definition:getType()) then return "owned", price end
    if Catalog.conflicts(player, definition) then return "conflict", price end
    if record.life.status ~= "alive" or player:isDead() then return "dead", price end
    if record.life.creation.status == "pending" then return "loading", price end
    if record.life.tokens < price then return "funds", price end
    return "available", price
end

---@param player IsoPlayer
---@param record table
---@return table
function Shop.snapshot(player, record)
    local snapshot = State.snapshot(record, player:getPlayerNum())
    snapshot.offers = {}
    for index = 1, #Catalog.entries do
        local id = Catalog.entries[index].id
        local status, price = Shop.offer(player, record, id)
        snapshot.offers[index] = { id = id, status = status, price = price }
    end
    return snapshot
end

---@param player IsoPlayer
---@param record table
---@param args table
---@return string
function Shop.purchase(player, record, args)
    if type(args) ~= "table" then return "invalid" end
    for key in pairs(args) do
        if key ~= "lifeId" and key ~= "revision" and key ~= "traitId" and key ~= "price" then
            return "invalid"
        end
    end
    if not State.isCounter(args.lifeId) or not State.isCounter(args.revision)
        or not State.isCounter(args.price) or type(args.traitId) ~= "string"
        or #args.traitId > 128 then return "invalid" end
    if record.life.status ~= "alive" or player:isDead() then return "dead" end
    if args.lifeId ~= record.life.id or args.revision ~= record.revision then return "stale" end
    local status, price = Shop.offer(player, record, args.traitId)
    if status ~= "available" then return status end
    if price ~= args.price then return "price_changed" end
    if record.revision >= State.LIMIT then return "invalid" end
    record.life.tokens = record.life.tokens - price
    record.life.purchases[args.traitId] = price
    record.revision = record.revision + 1
    Shop.reconcile(player, record, true)
    return "purchased"
end

return Shop
