if isServer() then return end

local Catalog = require("OMHTS_Catalog")
local Presentation = {}
Presentation.GOLD = { r = 0.99, g = 0.88, b = 0.49, a = 1 }

---@param player IsoPlayer
---@param state table
---@return table
---@return string
function Presentation.ownership(player, state)
    local owned = {}
    local traits = player:getCharacterTraits():getKnownTraits()
    for index = 0, traits:size() - 1 do
        owned[tostring(traits:get(index))] = true
    end
    for index = 1, #state.offers do
        local offer = state.offers[index]
        if offer.status == "owned" then
            owned[offer.id] = true
        end
    end
    local ids = {}
    for id in pairs(owned) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return owned, table.concat(ids, "|")
end

---@nodiscard
---@param left table
---@param right table
---@return boolean
function Presentation.cheapestFirst(left, right)
    if left.sortPrice ~= right.sortPrice then return left.sortPrice < right.sortPrice end
    if left.name ~= right.name then
        local forward = string.sort(left.name, right.name)
        local reverse = string.sort(right.name, left.name)
        if forward ~= reverse then return not forward end
    end
    return left.id < right.id
end

---@param definitions ArrayList
---@param owned table
---@param state table
---@param query string
---@param filter number
---@return table
function Presentation.rows(definitions, owned, state, query, filter)
    local groups = { catalog = {}, positive = {}, negative = {} }
    local offers = {}
    for index = 1, #state.offers do
        offers[state.offers[index].id] = state.offers[index]
    end
    for index = 0, definitions:size() - 1 do
        local definition = definitions:get(index)
        local id = tostring(definition:getType())
        local cost = definition:getCost()
        local isOwned = owned[id] == true
        if isOwned or (cost > 0 and not definition:isFree()) then
            local row = {
                id = id, name = definition:getLabel(), definition = definition,
                description = definition:getDescription(), group = "catalog", status = "unsupported",
                price = Catalog.price(definition), sortPrice = math.abs(cost), owned = isOwned,
            }
            if type(row.name) ~= "string" or row.name == "" then
                row.name = id
            end
            if type(row.description) ~= "string" or row.description == "" then
                row.description = getText("UI_OMHTS_NoDescription")
            end
            if row.price then
                row.sortPrice = row.price
            end
            local offer = offers[id]
            if offer then
                row.status = offer.status
                if offer.price > 0 then
                    row.price = offer.price
                    row.sortPrice = offer.price
                end
            end
            if isOwned then
                row.group = "positive"
                row.status = "owned"
                if cost < 0 then
                    row.group = "negative"
                    row.status = "removal_deferred"
                end
            elseif (isClient() or isServer()) and definition:isDisabledInMultiplayer() then
                row.status = "multiplayer"
            end
            local include = row.group ~= "catalog"
            if not include then
                include = (query == "" or string.find(string.lower(row.name), query, 1, true) ~= nil
                    or string.find(id, query, 1, true) ~= nil)
                    and (filter == 1 or (filter == 2 and row.status == "available")
                        or (filter == 3 and row.status ~= "available"))
            end
            if include then
                row.tooltip = row.name .. "\n" .. row.description .. "\n\n"
                    .. getText("UI_OMHTS_Status_" .. row.status)
                groups[row.group][#groups[row.group] + 1] = row
            end
        end
    end
    table.sort(groups.catalog, Presentation.cheapestFirst)
    table.sort(groups.positive, Presentation.cheapestFirst)
    table.sort(groups.negative, Presentation.cheapestFirst)
    return groups
end

---@nodiscard
---@param text string
---@param width number
---@return string
function Presentation.fitName(text, width)
    local manager = getTextManager()
    if manager:MeasureStringX(UIFont.Small, text) <= width then return text end
    local length = #text
    while length > 0 do
        local start = length
        local unit = string.byte(text, start)
        if start > 1 and unit >= 56320 and unit <= 57343 then
            start = start - 1
        end
        length = start - 1
        local shortened = string.sub(text, 1, length) .. "..."
        if manager:MeasureStringX(UIFont.Small, shortened) <= width then return shortened end
    end
    return "..."
end

return Presentation
