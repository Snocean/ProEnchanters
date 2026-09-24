"""Generate Enchants_Forever.lua, the WoW Forever enchant table of ProEnchanters.

The addon keeps one data file per game flavor (Enchants_Vanilla.lua,
Enchants_TBC.lua, ...). WoW Forever renamed and rebalanced many Classic
enchants, changed their reagents (e.g. Mote of Magic) and added about a hundred
recipes (necklace enchants, relics, staves, wands), so it needs its own file.

Everything comes from the live client, captured in game by the PEProbe dev addon
(tools/PEProbe) when the Enchanting Professions window is opened:
  * the recipe list, English names, descriptions and categories,
  * reagents with quantities, and the client-built link of every reagent item.
The enchant names in the other languages come from the spreadsheet extracted
from the beta client by the addon author (SpellName table, one column per
locale). Both inputs stay outside the repository.

Rules:
  * Recipes the client files under its "SEASON OF DISCOVERY" category are
    leftovers from SoD and are skipped, except the ones Forever sells
    (KEEP_FROM_SOD, cross-checked with the Forever vendor lists).
  * CombinedEnchants only holds real enchants ("Enchant <Slot> - <Effect>"),
    like the Vanilla table. Every kept recipe (enchants and crafted items such as
    wands, rods, relics) goes to PEProfessionsCombined.ENCHANTING.craftIds.
  * Keys follow the Vanilla scheme: "ENCH100" .. n, in name order, which is also
    the display order of the enchant list.
  * The short stat text shown on buttons (" (+7 Agi)") is parsed from the
    in-game description. Effects that cannot be summarized that way reuse the
    Vanilla text when the spell is unchanged, or STATS_OVERRIDES.
  * Sections that are not specific to Enchanting (other professions, item lists)
    are copied from Enchants_Vanilla.lua unchanged.

Usage (from the repository root):
    python tools/build_forever_enchants.py <PEProbe.lua> <WoW_Forever_Enchanting_Dump.xlsx>

<PEProbe.lua> is WTF/Account/<account>/SavedVariables/PEProbe.lua. The script
prints a report (kept/skipped recipes, stat texts that needed a fallback) and
writes Enchants_Forever.lua next to Enchants_Vanilla.lua. Requires openpyxl for
the spreadsheet and tools/savedvariables.py.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from savedvariables import load  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VANILLA_PATH = os.path.join(REPO, "Enchants_Vanilla.lua")
OUTPUT_PATH = os.path.join(REPO, "Enchants_Forever.lua")

SOD_CATEGORY = "SEASON OF DISCOVERY"
# SoD-category recipes that WoW Forever sells anyway (Azeroth Commerce Authority)
KEEP_FROM_SOD = {
    1213626,  # Enchant Gloves - Arcane Power
    1213622,  # Enchant Gloves - Holy Power
}

# Stat texts for new Forever effects the description parser cannot shorten
STATS_OVERRIDES = {
    1248757: " (Spirit Proc on Cast)",   # Enchant Weapon - Insight
    1248760: " (Heal on Parry/Dodge)",   # Enchant Weapon - Recovery
    1248805: " (Spell Crit Proc)",       # Enchant Weapon - Revelation
    1294054: " (Death Lotus Chance)",    # Enchant Gloves - Lotus Claw
}

# Addon language names (PELocales in PELocalization.lua) -> spreadsheet column
LOCALE_COLUMNS = {
    "English": "Enchant Spell Name (EN)",
    "German": "Enchant Spell Name (DE)",
    "French": "Enchant Spell Name (FR)",
    "Spanish": "Enchant Spell Name (ES)",
    "Mexican": "Enchant Spell Name (MX)",
    "Russian": "Enchant Spell Name (RU)",
    "Korean": "Enchant Spell Name (KR)",
    "Chinese": "Enchant Spell Name (CN)",
    "Taiwanese": "Enchant Spell Name (TW)",
    "Portuguese": "Enchant Spell Name (BR)",
}

# "Enchant <Slot> - " -> slot names used by the addon (see tEQLoc in Helper_*.lua)
SLOTS = {
    "2H Weapon": "Weapon", "Weapon": "Weapon", "Bracer": "Bracer", "Chest": "Chest",
    "Cloak": "Cloak", "Gloves": "Gloves", "Boots": "Boots", "Shield": "Shield",
    "Off-Hand": "Off-Hand", "Necklace": "Necklace",
}

STAT_WORDS = {
    "agility": "Agi", "strength": "Str", "stamina": "Stam", "intellect": "Int",
    "spirit": "Spirit", "defense": "Def",
}
SCHOOLS = ("arcane", "fire", "frost", "shadow", "nature", "holy")
SKILLS = ("herbalism", "mining", "skinning", "fishing")


def lua_string(text):
    """Double-quoted Lua string literal."""
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def stat_text(description):
    """Summarize an enchant description the way the Vanilla table does, e.g.
    " (+7 Agi)". Returns None when no rule matches."""
    d = description.lower()
    parts = []

    def add(fmt, *values):
        parts.append(fmt.format(*values))

    m = re.search(r"(\d+)% chance per hit of giving you (\d+) points of damage absorption", d)
    if m:
        return " ({}% Chance {} Dmg Absorb)".format(*m.groups())

    m = re.search(r"\+?(\d+) to all stats", d)
    if m:
        add("+{} All Stats", m.group(1))

    m = re.search(r"(\d+) to all resistances|all schools of magic by (\d+)", d)
    if m:
        add("+{} All Res", m.group(1) or m.group(2))
    else:
        for school in SCHOOLS:
            m = re.search(r"\+?(\d+) {} resistance|resistance to {} by (\d+)".format(school, school), d)
            if m:
                add("+{} {} Res", m.group(1) or m.group(2), school.capitalize())

    m = re.search(r"(\d+) additional armor|armor by (\d+)", d)
    if m:
        add("+{} Armor", m.group(1) or m.group(2))

    # Healing power: "healing ... by up to X and ... damage ... by up to Y" or
    # "up to X points of healing ... up to Y points of damage"
    m = (re.search(r"heal\w*(?: spells)? by up to (\d+) and (?:the effects of your )?(?:spell )?damage(?: spells)? by up to (\d+)", d)
         or re.search(r"up to (\d+) points of healing .*?up to (\d+) points of damage", d))
    if m:
        add("+{} Healing, +{} Spell Dmg", m.group(1), m.group(2))
    else:
        m = (re.search(r"damage and healing by up to (\d+)", d)
             or re.search(r"(\d+) to spell power|(\d+) spell power", d))
        if m:
            add("+{} Spell Power", next(g for g in m.groups() if g))

    for school in SCHOOLS:
        m = re.search(r"{} damage by up to (\d+)|up to (\d+) additional {} damage".format(school, school), d)
        if m:
            add("+{} {} Dmg", m.group(1) or m.group(2), school.capitalize())
    m = re.search(r"add up to (\d+) damage to spells", d)
    if m:
        add("+{} Spell Dmg", m.group(1))

    m = re.search(r"(\d+) additional (?:points of )?damage (?:to|against) (beasts|elementals|demons)", d)
    if m:
        add("+{} {} Dmg", m.group(1), {"beasts": "Beast", "elementals": "Elemental", "demons": "Demon"}[m.group(2)])
    else:
        m = re.search(r"do \+?(\d+) (?:additional )?(?:points? of )?damage", d)
        if m:
            add("+{} Dmg", m.group(1))

    for skill in SKILLS:
        m = re.search(r"\+(\d+) {} skill".format(skill), d)
        if m:
            add("+{} {}", m.group(1), skill.capitalize())

    m = (re.search(r"defense skill (?:of the wearer )?(?:is increased )?by (\d+)", d)
         or re.search(r"\+(\d+) defense", d))
    if m:
        add("+{} Def", m.group(1))

    # Primary stats, in the phrasings the client uses
    stat_patterns = [
        r"(?:grant|give|to) \+?(\d+) ({})\b",
        r"increases? the ({}) of the wearer by (\d+)",
        r"increases? the wearer's ({}) by (\d+)",
        r"(?:add|and) (\d+) to ({})",  # "add 6 to intellect and 5 to spirit"
        r"increase ({}) by (\d+)",
        r"increases the ({}) of the bearer by (\d+)",
    ]
    words = "|".join(w for w in STAT_WORDS if w != "defense")
    for pattern in stat_patterns:
        for m in re.finditer(pattern.format(words), d):
            a, b = m.groups()
            value, word = (a, b) if a.isdigit() else (b, a)
            text = "+{} {}".format(value, STAT_WORDS[word])
            if text not in parts:
                parts.append(text)

    m = re.search(r"restore (\d+) mana every 5 seconds", d)
    if m:
        add("+{} Mp5", m.group(1))
    m = re.search(r"(\d+)% chance to dodge", d)
    if m:
        add("+{}% Dodge", m.group(1))
    m = re.search(r"\+?(\d+)% chance to block", d)
    if m:
        add("+{}% Block", m.group(1))
    m = re.search(r"(\d+)% critical strike chance", d)
    if m:
        add("+{}% Crit Chance", m.group(1))
    m = re.search(r"\+?(\d+)% attack and casting speed", d)
    if m:
        add("+{}% Haste", m.group(1))
    m = re.search(r"decrease threat caused by the wearer by (\d+)%", d)
    if m:
        add("-{}% Threat", m.group(1))
    else:
        m = re.search(r"increase threat .*? by (\d+)%", d)
        if m:
            add("+{}% Threat Gen", m.group(1))

    return " (" + ", ".join(parts) + ")" if parts else None


def normalize_link(link):
    """Client item links carry the capturing character's level and spec
    (fields 9 and 10 of the item string); blank them so the table is neutral."""
    m = re.match(r"^(.*\|Hitem:)([^|]*)(\|h.*)$", link)
    if not m:
        return link
    fields = m.group(2).split(":")
    for index in (8, 9):
        if index < len(fields):
            fields[index] = ""
    return m.group(1) + ":".join(fields) + m.group(3)


def parse_vanilla(text):
    """What the generator reuses from Enchants_Vanilla.lua."""
    body = text[text.index("CombinedEnchants = {"):text.index("PEProfessionsOrder")]
    entries = {}
    for key, entry in re.findall(r"\n    (ENCH\d+) = \{(.*?)\n    \},", body, re.S):
        spell_id = int(re.search(r"spell_id = (\d+)", entry).group(1))
        entries[spell_id] = {
            "name": re.search(r'name = "([^"]*)"', entry).group(1),
            "stats": re.search(r'stats = "([^"]*)"', entry).group(1),
        }
    item_vars = {int(item_id): name for name, item_id in
                 re.findall(r'\nlocal (\w+) = "[^"]*Hitem:(\d+):', text)}
    return entries, item_vars


def variable_name(item_name, taken):
    base = re.sub(r"[^a-z0-9]", "", item_name.lower()) or "item"
    if base[0].isdigit():
        base = "item" + base
    name, n = base, 2
    while name in taken:
        name, n = base + str(n), n + 1
    return name


def main(probe_path, xlsx_path):
    probe = load(probe_path)["PEProbeDB"]
    capture = probe["professions"]["Enchanting"]
    categories = capture["categories"]
    items = probe.get("items", {})
    vanilla_text = open(VANILLA_PATH, encoding="utf-8").read().replace("\r\n", "\n")
    vanilla_entries, vanilla_vars = parse_vanilla(vanilla_text)

    import openpyxl
    sheet = openpyxl.load_workbook(xlsx_path, read_only=True, data_only=True)["Enchanting"]
    rows = list(sheet.iter_rows(values_only=True))
    header = rows[0]
    localized = {}
    for row in rows[1:]:
        record = dict(zip(header, row))
        if record.get("Enchant Spell ID"):
            localized[int(record["Enchant Spell ID"])] = record

    # 1. Which recipes Forever really has
    kept, skipped = {}, []
    for recipe_id, recipe in capture["recipes"].items():
        category = categories.get(recipe["info"].get("categoryID"), {}).get("name")
        if category == SOD_CATEGORY and recipe_id not in KEEP_FROM_SOD:
            skipped.append((recipe_id, recipe["info"]["name"]))
        else:
            kept[recipe_id] = recipe

    # 2. Reagent item variables (Vanilla names kept for known items)
    used_items = sorted({item_id for r in kept.values() for g in r.get("reagents", []) for item_id in g["itemIds"]})
    var_of, taken, missing_items = {}, set(), []
    for item_id in used_items:
        info = items.get(item_id)
        if not info:
            missing_items.append(item_id)
            continue
        name = vanilla_vars.get(item_id) or variable_name(info["name"], taken)
        name = name if name not in taken else variable_name(info["name"], taken)
        taken.add(name)
        var_of[item_id] = name

    # 3. Enchants, in name order
    enchants = sorted((r for r in kept.values() if r["info"]["name"].startswith("Enchant ")),
                      key=lambda r: r["info"]["name"])
    report = {"parsed": 0, "vanilla": [], "override": [], "empty": []}
    lines_enchants, lines_locales = [], []
    for index, recipe in enumerate(enchants, start=1):
        key = "ENCH100" + str(index)
        spell_id = recipe["info"]["recipeID"]
        name = recipe["info"]["name"]
        slot_word = re.match(r"Enchant (.+?) - ", name).group(1)
        stats = STATS_OVERRIDES.get(spell_id)
        if stats:
            report["override"].append(name)
        else:
            stats = stat_text(recipe.get("description", ""))
            if stats:
                report["parsed"] += 1
            elif spell_id in vanilla_entries and vanilla_entries[spell_id]["name"] == name:
                stats = vanilla_entries[spell_id]["stats"]
                report["vanilla"].append(name)
            else:
                stats = ""
                report["empty"].append(name)
        materials = ['"{}x " .. {}'.format(g["quantityRequired"], var_of[g["itemIds"][0]])
                     for g in recipe.get("reagents", []) if g["itemIds"][0] in var_of]
        lines_enchants.append(
            "    {} = {{\n        name = {},\n        slot = {},\n        spell_id = {},\n"
            "        stats = {},\n        materials = {{\n            {}\n        }},\n    }},".format(
                key, lua_string(name), lua_string(SLOTS[slot_word]), spell_id, lua_string(stats),
                ",\n            ".join(materials)))
        names = {"English": name}
        record = localized.get(spell_id, {})
        for language, column in LOCALE_COLUMNS.items():
            if language != "English" and record.get(column):
                names[language] = record[column]
        lines_locales.append("\t\t[{}] = {{\n{}\n\t\t}},".format(
            lua_string(key), ",\n".join("\t\t\t[{}] = {}".format(lua_string(lang), lua_string(text))
                                         for lang, text in sorted(names.items()))))

    # 4. Sections reused from Enchants_Vanilla.lua
    convertables = vanilla_text[vanilla_text.index("----- PE Convertables"):vanilla_text.index("-- Dust\n")]
    rest = vanilla_text[vanilla_text.index("---- Craftables Tables"):]
    start = rest.index("    ENCHANTING = {")
    end = rest.index("    COOKING = {")
    craft_ids = sorted(kept, reverse=True)
    enchanting_block = (
        "    ENCHANTING = {{\n        profSpellId = 7411,\n\t\tcraftIds = {{\n{}\n\t\t}},\n"
        "        reagentIds = {{\n{}\n        }},\n    }},\n".format(
            ",\n".join("\t\t\t{}".format(i) for i in craft_ids),
            ",\n".join("            {}".format(i) for i in sorted(var_of, reverse=True))))
    rest = rest[:start] + enchanting_block + rest[end:]
    # Forever reagents the other lists do not know yet
    m = re.search(r"PEReagentItems ?=\s*\{(.*?)\n\}", rest, re.S)
    known = {int(x) for x in re.findall(r"\d+", m.group(1))}
    extra = [i for i in sorted(var_of) if i not in known]
    if extra:
        rest = rest[:m.end() - 2] + "".join(",\n    {}".format(i) for i in extra) + rest[m.end() - 2:]

    header_comment = """-- WoW Forever enchant table for ProEnchanters.
--
-- GENERATED by tools/build_forever_enchants.py from an in-game capture of the
-- Enchanting Professions window (PEProbe) on the WoW Forever beta, with the
-- other languages' enchant names from the beta client's SpellName table. Do not
-- edit by hand: fix the generator or its overrides, then regenerate. The
-- generator's docstring explains the rules (SoD leftovers skipped, keys,
-- stat texts). Loaded by ProEnchanters.toc (Interface 16001) instead of
-- Enchants_Vanilla.lua; the other professions' tables are Vanilla's, unchanged.
--
-- {kept} recipes kept ({enchants} enchants in CombinedEnchants), {skipped} SoD
-- leftovers skipped.

""".format(kept=len(kept), enchants=len(enchants), skipped=len(skipped))

    materials_block = "---- MATERIAL ITEMLINKS (as the Forever client builds them)\n" + "\n".join(
        "local {} = {}".format(var_of[i], lua_string(normalize_link(items[i]["link"])))
        for i in sorted(var_of, key=lambda i: var_of[i])) + "\n\n"
    cache_block = "ProEnchantersItemCacheTable = {\n" + ",\n".join(
        '    {} = "{}"'.format(var_of[i], i) for i in sorted(var_of, key=lambda i: var_of[i])) + "\n}\n\n"
    locales_block = """
-- Enchant names per language, read by GetEnchantName (Helper_*.lua). The table
-- in PELocalization.lua holds the Classic names under the Classic keys; WoW
-- Forever renamed several enchants ("Minor Health" became "Inferior Stamina"),
-- so it is replaced by the Forever names under the keys of CombinedEnchants.
PEenchantingLocales["Enchants"] = {
""" + "\n".join(lines_locales) + "\n}\n"

    output = (header_comment + convertables + materials_block + cache_block
              + "CombinedEnchants = {\n" + "\n".join(lines_enchants) + "\n}\n\n" + rest.rstrip("\n") + "\n"
              + locales_block)
    with open(OUTPUT_PATH, "w", encoding="utf-8", newline="\r\n") as handle:
        handle.write(output)

    print("kept {} recipes, {} enchants; skipped {} SoD leftovers".format(len(kept), len(enchants), len(skipped)))
    print("stat texts: {} parsed, {} from Vanilla, {} overrides, {} empty".format(
        report["parsed"], len(report["vanilla"]), len(report["override"]), len(report["empty"])))
    for label in ("vanilla", "override", "empty"):
        for name in report[label]:
            print("  {}: {}".format(label, name))
    if missing_items:
        print("reagents without a captured link (dropped from materials):", missing_items)
    print("new reagent IDs added to PEReagentItems:", len(extra))
    print("wrote", OUTPUT_PATH)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
