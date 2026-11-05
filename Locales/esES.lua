local _, ns = ...

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then
    return
end

local L = ns.L

L.ADDON_TITLE = "Best Food & Drink"
L.LOADED = "cargado. Escribe /bfd para ver qué usarán tus macros de comida y bebida."
L.SLASH_HELP = "Comandos: /bfd [estado | crear | opciones | debug | reset]"
L.ERR_COMBAT = "No disponible en combate; inténtalo al salir de él."
L.RESET_CONFIRM = "Escribe /bfd reset confirmar para volver a los valores por defecto."
L.RESET_DONE = "Opciones restauradas a los valores por defecto."
L.COMPARTMENT_TOOLTIP = "Clic para abrir las opciones."

L.MACRO_FOOD = "MejorComida"
L.MACRO_DRINK = "MejorBebida"
L.MACROS_CREATED = "creadas las macros de personaje %s y %s. Arrástralas desde /macro a tus barras."
L.MACROS_READY = "macros %s y %s listas (se han vuelto a crear si faltaban)."
L.ERR_NO_MACRO_SLOTS = "no quedan huecos de macro de personaje; borra una y escribe /bfd crear."
L.NO_FOOD = "no llevas comida que puedas usar."
L.NO_DRINK = "no llevas bebida que puedas usar."
L.STATUS_HEADER = "lo que usarán las macros:"
L.STATUS_LINE = "%s (x%d, restaura %s)"

L.OPT_ENABLED = "Mantener las macros al día"
L.OPT_ENABLED_TT = "Reescribe las dos macros (fuera de combate) cuando cambian tus bolsas o tu nivel."
L.OPT_CREATE = "Crear las macros solo"
L.OPT_CREATE_TT = "Crea las dos macros de personaje la primera vez en cada personaje. "
    .. "Si las borras, no vuelven hasta /bfd crear."
L.OPT_BUFF = "Preferir comida con bonus"
L.OPT_BUFF_TT = "Activado: primero la comida y bebida que da Bien alimentado. "
    .. "Desactivado: solo se usan si no tienes otra, para guardarlas para cuando importan."

L.DEBUG_HEADER = "Diagnóstico (pégalo al informar de un problema):"
