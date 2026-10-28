local Prestige = {}
local written = {}
Prestige.PREFIX = "OMHTS_Creation_v1_"
Prestige.SYSTEM = "OMHTS_Creation"

---@nodiscard
---@param value any
---@return boolean
function Prestige.counter(value)
    return type(value) == "number" and value >= 0 and value <= 1000000000
        and value == math.floor(value)
end

---@nodiscard
---@param value string
---@return string
function Prestige.encode(value)
    local bytes = {}
    for index = 1, #value do
        local code = string.byte(value, index)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90)
            or (code >= 97 and code <= 122) or code == 45 or code == 95 then
            bytes[index] = string.sub(value, index, index)
        else
            bytes[index] = string.format("~%04x", code)
        end
    end
    return table.concat(bytes)
end

---@nodiscard
---@param account string
---@return string
function Prestige.tag(account)
    return Prestige.PREFIX .. Prestige.encode(account)
end

---@nodiscard
---@param slot number
---@return string
function Prestige.localPath(slot)
    return "OMHTraitShop/" .. Prestige.encode(getWorld():getGameMode()) .. "/"
        .. Prestige.encode(getWorld():getWorld()) .. "/prestige-" .. slot .. ".txt"
end

---@nodiscard
---@return number|nil
function Prestige.retention()
    if type(SandboxVars) ~= "table" or type(SandboxVars.OMHTraitShop) ~= "table" then return nil end
    local value = SandboxVars.OMHTraitShop.PrestigeRetentionPercentage
    if value == nil then
        value = 30
    end
    if not Prestige.counter(value) or value > 100 then return nil end
    return value
end

---@nodiscard
---@return boolean
function Prestige.officialSettings()
    if not getActivatedMods():contains("OneMoreHorde_HordeNight") then return false end
    local integrity = require("OMH_ModSettingsIntegrity")
    if not integrity or integrity.TRAIT_SHOP_BASELINE ~= "trait-shop-default-or-harder-v3" then return false end
    return integrity.evaluateTraitShop(SandboxVars.OMHTraitShop).verdict == "Allowed"
end

---@nodiscard
---@param record table
---@return number
function Prestige.pending(record)
    return record.prestige.pending + record.prestige.retained + record.prestige.earned
end

---@param account string
---@param record table
---@return nil
function Prestige.publish(account, record)
    local bonus = Prestige.pending(record)
    if isServer() then
        local preview = ModData.getOrCreate(Prestige.tag(account))
        preview.schema = 1
        preview.bonus = bonus
        preview.revision = record.revision
    elseif not isClient() then
        local slot = tonumber(string.match(account, "^local:([0-3])$"))
        if slot == nil then return end
        local path = Prestige.localPath(slot)
        if written[path] == bonus then return end
        local writer = getFileWriter(path, true, false)
        if not writer then
            print("[OMH Trait Shop] unable to save creation preview; authoritative Prestige preserved")
            return
        end
        writer:write(tostring(bonus) .. "\n")
        writer:close()
        written[path] = bonus
    end
end

return Prestige
