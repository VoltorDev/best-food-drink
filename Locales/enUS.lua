local _, ns = ...

-- Tabla de textos: si falta una clave, devuelve la propia clave en vez de nil
-- (un texto sin traducir se ve, pero no rompe el addon).
local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
ns.L = L

L.ADDON_TITLE = "Best Food & Drink"
L.LOADED = "loaded. Type /bfd to see what your food and drink macros will use."
L.SLASH_HELP = "Commands: /bfd [status | create | config | debug | reset]"
L.ERR_COMBAT = "Not available in combat; try again when combat ends."
L.RESET_CONFIRM = "Type /bfd reset confirm to restore the defaults."
L.RESET_DONE = "Settings restored to defaults."
L.COMPARTMENT_TOOLTIP = "Click to open the options."

-- Nombres de las macros (máximo 16 caracteres). Distintivos para no pisar macros de Nico.
L.MACRO_FOOD = "BestFood"
L.MACRO_DRINK = "BestDrink"
L.MACROS_CREATED = "created the character macros %s and %s. Drag them from /macro to your action bars."
L.MACROS_READY = "macros %s and %s are ready (created again if they were missing)."
L.ERR_NO_MACRO_SLOTS = "no free character macro slots; delete one and type /bfd create."
L.NO_FOOD = "you have no usable food in your bags."
L.NO_DRINK = "you have no usable drink in your bags."
L.STATUS_HEADER = "what the macros will use:"
L.STATUS_LINE = "%s (x%d, restores %s)"

L.OPT_ENABLED = "Keep macros updated"
L.OPT_ENABLED_TT = "Rewrites the two macros (out of combat) when your bags or your level change."
L.OPT_CREATE = "Create the macros automatically"
L.OPT_CREATE_TT = "Creates the two character macros the first time on each character. "
    .. "If you delete them, they are not created again until /bfd create."
L.OPT_BUFF = "Prefer food with a buff"
L.OPT_BUFF_TT = "On: food and drink that give Well Fed come first. "
    .. "Off: they are only used when you have nothing else, so you keep them for when they matter."

L.DEBUG_HEADER = "Diagnostics (paste this when reporting a problem):"
