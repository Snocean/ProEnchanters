import csv
from collections import defaultdict

# Initialize dictionaries to store total gold and count for each enchantment
enchantment_totals = defaultdict(int)
enchantment_counts = defaultdict(int)

# Read the input CSV file
# Reads the rawoutput.csv file generated from step one. You must run the first python script to generate the raw data before using this script.
# Outputs a csv file where each enchant is listed with how many times it was done and the total gold associated to it.
# Open the csv file with excel or sheets and divide the total gold by the amount of times the enchant was completed to get the average
with open('rawoutput.csv', 'r') as csvfile:
    csvreader = csv.reader(csvfile)
    next(csvreader)  # Skip the header row

    # Process each row in the CSV
    for row in csvreader:
        username, gold, enchantments = row
        gold = int(gold)  # Convert gold amount to integer

        # Split enchantments if multiple enchantments are present
        enchantment_list = enchantments.split('|')

        # Calculate the gold amount to be assigned to each enchantment
        gold_per_enchantment = gold / len(enchantment_list) if len(enchantment_list) > 0 else 0

        # Accumulate the gold amount and count for each enchantment
        for enchantment in enchantment_list:
            if enchantment:  # Only process if there's an enchantment listed
                enchantment_totals[enchantment] += gold_per_enchantment
                enchantment_counts[enchantment] += 1

# Write the output to a new CSV file
with open('enchantment_totals_with_avg_counts.csv', 'w', newline='') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['enchantments', 'counted amount', 'total gold'])  # Write the header

    # Write each enchantment, its count, and its total gold to the CSV
    for enchantment, total_gold in enchantment_totals.items():
        count = enchantment_counts[enchantment]
        csvwriter.writerow([enchantment, count, total_gold])

print("Data successfully written to enchantment_totals_with_avg_counts.csv")
