local existing = rawget(_G, "OneMoreHordeTraitShop")
if existing then return existing end

local TraitShop = {
    MOD_ID = "OneMoreHorde_TraitShop",
    VERSION = "0.4.2",
    CHECKPOINT = 4,
}
OneMoreHordeTraitShop = TraitShop

if isClient() then
    print("[OMH Trait Shop] v0.4.2 shared loaded: multiplayer-client")
elseif isServer() then
    print("[OMH Trait Shop] v0.4.2 shared loaded: server")
else
    print("[OMH Trait Shop] v0.4.2 shared loaded: singleplayer")
end

return TraitShop
