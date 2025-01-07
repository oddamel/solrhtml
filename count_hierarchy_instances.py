import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
import sys

def count_hierarchy_levels_distinct(xml_file):
    # Parse the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()

    # Counter for total occurrences of each type
    total_counter = Counter()
    # Set to store distinct entries at each level
    distinct_per_level = defaultdict(set)

    # Traverse through each 'field' element with name="id"
    for field in root.findall(".//field[@name='id']"):
        full_id = field.text
        if full_id:
            # Split by hierarchy levels
            parts = full_id.split('/')
            for i in range(1, len(parts) + 1):
                # Generalize the type key (e.g., lov, lov/kapittel)
                type_key = '/'.join([p.split('-')[0] for p in parts[:i]])
                # Increment total counter
                total_counter[type_key] += 1
                # Add distinct value for this level
                distinct_per_level[type_key].add('/'.join(parts[:i]))

    # Compute distinct counts for each type
    distinct_counter = {key: len(distinct_per_level[key]) for key in distinct_per_level}

    return total_counter, distinct_counter

def main():
    if len(sys.argv) != 2:
        print("Usage: python count_hierarchy_levels_distinct.py <path_to_xml_file>")
        return

    xml_file = sys.argv[1]
    total_counts, distinct_counts = count_hierarchy_levels_distinct(xml_file)

    print("Hierarchy counts:")
    for hierarchy in total_counts:
        print(f"{hierarchy}: {total_counts[hierarchy]}; {distinct_counts[hierarchy]}")

if __name__ == "__main__":
    main()
