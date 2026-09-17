if isServer() then return end

local Catalog = require("OMHTS_Catalog")
local Presentation = {}
Presentation.GOLD = { r = 231 / 255, g = 180 / 255, b = 40 / 255, a = 1 }
Presentation.GREEN = { r = 114 / 255, g = 184 / 255, b = 109 / 255, a = 1 }
Presentation.RED = { r = 217 / 255, g = 64 / 255, b = 64 / 255, a = 1 }
Presentation.NEUTRAL = { r = 0.8, g = 0.8, b = 0.8, a = 1 }
Presentation.TITLE_GOLD = { r = 0.95, g = 0.75, b = 0.2, a = 1 }
Presentation.TITLE_RED = { r = 0.85, g = 0.25, b = 0.25, a = 1 }

---@nodiscard
---@param row table
---@param rows table
---@param cart table
---@param tokens number
---@return string
function Presentation.previewStatus(row, rows, cart, tokens)
    if row.status ~= "available" and row.status ~= "funds" and row.status ~= "conflict" then return row.status end
    if row.group == "catalog" then
        for id, other in pairs(rows) do
            local removing = other.group == "negative" and cart[id]
                and (other.status == "available" or other.status == "funds")
            local adding = other.group == "catalog" and cart[id]
                and (other.status == "available" or other.status == "funds" or other.status == "conflict")
            if id ~= row.id and ((other.owned and not removing) or adding)
                and (row.definition:isMutuallyExclusive(other.definition)
                    or other.definition:isMutuallyExclusive(row.definition)) then
                return "conflict"
            end
        end
    end
    if row.price and row.price > tokens then return "funds" end
    return "available"
end

---@nodiscard
---@param text string
---@return string
function Presentation.normalize(text)
    return string.match(string.gsub(string.lower(text), "%s+", " "), "^%s*(.-)%s*$")
end

---@nodiscard
---@param row table
---@param query string
---@return number|nil
function Presentation.relevance(row, query)
    if query == "" then return 0 end
    local name = Presentation.normalize(row.name)
    if name == query then return 1 end
    if string.find(name, query, 1, true) then return 2 end
    if string.find(string.lower(row.id), query, 1, true) then return 3 end
    local description = Presentation.normalize(row.description)
    if string.find(description, query, 1, true) then return 4 end
    local remaining = query .. " "
    while remaining ~= "" do
        local word, rest = string.match(remaining, "^(%S+) (.*)$")
        if not word or not string.find(description, word, 1, true) then return nil end
        remaining = rest
    end
    return 5
end

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
    if left.rank and right.rank and left.rank ~= right.rank then return left.rank < right.rank end
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
    query = Presentation.normalize(query)
    local groups = { catalog = {}, positive = {}, other = {}, negative = {} }
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
                if cost == 0 then
                    row.group = "other"
                elseif cost < 0 then
                    row.group = "negative"
                    if not offer then
                        row.status = "unsupported"
                    else
                        row.status = offer.status
                    end
                end
            elseif (isClient() or isServer()) and definition:isDisabledInMultiplayer() then
                row.status = "multiplayer"
            end
            row.rank = Presentation.relevance(row, query)
            local include = row.group ~= "catalog" or (row.rank ~= nil
                and (filter == 1 or (filter == 2 and row.status == "available")
                    or (filter == 3 and row.status ~= "available")))
            if include then
                row.tooltip = row.name .. "\n" .. row.description
                groups[row.group][#groups[row.group] + 1] = row
            end
        end
    end
    table.sort(groups.catalog, Presentation.cheapestFirst)
    table.sort(groups.positive, Presentation.cheapestFirst)
    table.sort(groups.other, Presentation.cheapestFirst)
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
