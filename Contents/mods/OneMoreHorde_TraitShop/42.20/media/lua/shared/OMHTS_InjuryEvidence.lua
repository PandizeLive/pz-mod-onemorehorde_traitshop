local E = {}

---@param player IsoPlayer Injured character
---@return table snapshot Primitive body state, without attacker claims
function E.capture(player)
    local parts = player:getBodyDamage():getBodyParts()
    local result = {health = player:getHealth()}
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        result[i + 1] = {part:getHealth(), part:getScratchTime(), part:getCutTime(),
            part:getDeepWoundTime(), part:getBleedingTime(), part:haveBullet()}
    end
    return result
end

---@param before table Pre-application snapshot
---@param after table Post-application snapshot
---@return boolean injured Health lost or a wound created/extended
function E.injured(before, after)
    if after.health < before.health then return true end
    for i = 1, #before do
        local a, b = before[i], after[i]
        if b and (b[1] < a[1] or b[2] > a[2] or b[3] > a[3]
            or b[4] > a[4] or b[5] > a[5] or (b[6] and not a[6])) then return true end
    end
    return false
end

---@param player IsoPlayer Candidate recovery
---@return boolean recovered All body health and wounds recovered
function E.recovered(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part:getHealth() < 100 or part:getScratchTime() > 0 or part:getCutTime() > 0
            or part:getDeepWoundTime() > 0 or part:getBleedingTime() > 0 or part:haveBullet() then return false end
    end
    return true
end

return E
