-- luacheck para un addon de WoW Forever (Lua 5.1).
-- Que cada API exista DE VERDAD en Forever lo comprueba api_forever.py; aquí se declara
-- qué globales lee el addon, para que una errata en un nombre salte como "undefined variable".
std = "lua51"
max_line_length = 120
exclude_files = { "Libs/", ".release/", "tools/", ".luacheckrc" }

ignore = {
    "212/self", -- self sin usar en métodos
}

-- Globales que el addon CREA o modifica.
globals = {
    "BestFoodDrinkDB",
    "BestFoodDrinkCharDB",
    "SLASH_BESTFOODDRINK1",
    "SLASH_BESTFOODDRINK2",
    "SlashCmdList",
    "BestFoodDrink_OnAddonCompartmentClick",
    "BestFoodDrink_OnAddonCompartmentEnter",
    "BestFoodDrink_OnAddonCompartmentLeave",
}

-- API de WoW que el addon lee. Añade aquí cada global nueva que uses.
read_globals = {
    "AbbreviateNumbers",
    "C_Container",
    "C_Item",
    "C_Spell",
    "C_Timer",
    "C_TooltipInfo",
    "CreateMacro",
    "EditMacro",
    "GetMacroIndexByName",
    "GetMacroInfo",
    "GetNumMacros",
    "UnitLevel",
    "C_AddOns",
    "C_GameRules",
    "C_RestrictedActions",
    "C_Secrets",
    "Constants",
    "CreateFrame",
    "Enum",
    "GameTooltip",
    "GetAddOnMetadata",
    "GetBuildInfo",
    "GetLocale",
    "GetNormalizedRealmName",
    "GetRealmName",
    "InCombatLockdown",
    "LE_EXPANSION_CLASSIC",
    "LE_EXPANSION_LEVEL_CURRENT",
    "MinimalSliderWithSteppersMixin",
    "RegionalUniqueNamesEnabled",
    "Settings",
    "UIParent",
    "UnitGUID",
    "UnitHealth",
    "UnitHealthMax",
    "UnitName",
    "UnitNameUnmodified",
    "issecretvalue",
    "time",
    "wipe",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_CAMELOT",
    "WOW_PROJECT_FOREVER",
}

-- Tests fuera del juego (busted o scripts/probar_addon.py): Lua 5.1 estándar + API de busted.
files["tests/**/*.lua"] = {
    std = "lua51+busted",
    globals = { "string" }, -- secret_mock parchea string.format
}
