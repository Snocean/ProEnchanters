import re
import csv

# Input trade data as a raw string
# Input all trade data between the starting ''' and then ending '''
# Example is below

data = '''
["example1"] = {
"|cFFFFA500Invited from message: |rLF Enchanter",
"|cFFFFFFE0IN: 15x |r|cffffffff|Hitem:16204::::::::60:::::::::|hIllusion Dust|h|r",
"|cFF20B2AAREQ ENCH: |r|cFFDA70D6|Haddon:ProEnchanters:reqench:ENCH17:example1:1234|h[Enchant Bracer - Superior Stamina]|h|r",
"|cFFFFFF00IN: |r2 Gold",
"|cFFFF00FFENCH: |rEnchant Bracer - Superior Stamina|cFFFF00FF ON: |r|cffa335ee|Hitem:231055::::::::60:::::::::|hDragonstalker's Bracers|h|r",
"|cFF90EE90---- End of Workorder# 183 ----|r",
},
["example2"] = {
"|cFFFFA500Invited from message: |rinv then",
"|cFFFFFFE0IN: 2x |r|cff0070dd|Hitem:11178::::::::60:::::::::|hLarge Radiant Shard|h|r",
"|cFFFFFFE0IN: 2x |r|cffffffff|Hitem:8153::::::::60:::::::::|hWildvine|h|r",
"|cFF20B2AAREQ ENCH: |r|cFFDA70D6|Haddon:ProEnchanters:reqench:ENCH36:example2:1234|h[Enchant Gloves - Minor Haste]|h|r",
"|cFFFFFF00IN: |r4 Gold",
"|cFFFF00FFENCH: |rEnchant Gloves - Minor Haste|cFFFF00FF ON: |r|cffa335ee|Hitem:232252::::::::60:::::::::|hGauntlets of Wrath|h|r",
"|cFF90EE90---- End of Workorder# 149 ----|r",
},
'''

# Input all trade data between the starting ''' and then ending '''

# Parse the data to extract username and block information
data_dict = {}
username_pattern = re.compile(r'\["(.+?)"\] = \{(.+?)\}', re.DOTALL)

matches = username_pattern.findall(data)
for match in matches:
    username = match[0]
    block = match[1].split(",\n")  # Split the block into individual lines
    data_dict[username] = block

# Function to extract enchantments and gold from each user's data
def extract_data(username, block):
    # Find all enchantments
    enchants = re.findall(r'\|cFFFF00FFENCH: \|r(.*?)\|c', " ".join(block))
    
    # Find gold amount
    gold_match = re.search(r'\|r(\d+)\sGold', " ".join(block))
    gold = gold_match.group(1) if gold_match else '0'
    
    return username, gold, enchants

# Prepare output data for CSV
output = []

# Loop through each user in the data dictionary
for username, block in data_dict.items():
    result = extract_data(username, block)
    if result:
        username, gold, enchants = result
        output.append([username, gold, "|".join(enchants)])

# Write to CSV file
with open('rawoutput.csv', 'w', newline='') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['username', 'gold amount', 'enchantments'])
    csvwriter.writerows(output)

print("Data successfully written to rawoutput.csv")