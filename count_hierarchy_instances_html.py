from bs4 import BeautifulSoup
from collections import Counter, defaultdict
import sys
import re

def count_hierarchy_from_html(html_file):
    with open(html_file, "r", encoding="utf-8") as file:
        soup = BeautifulSoup(file, "html.parser")

    total_counter = Counter()
    distinct_per_level = defaultdict(set)

    for tag in soup.find_all(attrs={"id": True}):
        full_id = tag["id"]
        if not full_id:
            continue

        # e.g. full_id = "lov-1-kapittel-3-paragraf-10-ledd-2"
        # Splitting by '-' → ["lov","1","kapittel","3","paragraf","10","ledd","2"]
        hierarchy_parts = full_id.split('-')
        for i in range(1, len(hierarchy_parts) + 1):
            level = '-'.join(hierarchy_parts[:i])
            # type_key is slash-delimited nodes with digits removed:
            # e.g. "lov-1" -> "lov"; "kapittel-3" -> "kapittel"
            type_key = '/'.join([p.split('-')[0] for p in hierarchy_parts[:i]])

            total_counter[type_key] += 1
            distinct_per_level[type_key].add(level)

    distinct_counts = {k: len(v) for k, v in distinct_per_level.items()}
    return total_counter, distinct_counts

def has_any_numeric(s: str) -> bool:
    """Return True if the string s has at least one digit in it."""
    return bool(re.search(r'\d', s))

def strip_numeric_parts(path: str) -> str:
    """
    'lov/1/kapittel/3/paragraf/14' → 'lov/kapittel/paragraf'
    removing all digits from each piece.
    """
    parts = path.split('/')
    stripped = []
    for p in parts:
        alpha = re.sub(r'\d+', '', p)  # remove digits
        alpha = alpha.strip('-_/')
        if alpha:
            stripped.append(alpha)
    return '/'.join(stripped)

def parse_path_into_pairs(raw_path: str):
    """
    Convert 'kapittel/4/paragraf/1/ledd/2' → [('kapittel','4'), ('paragraf','1'), ('ledd','2')]
    If we get 'kapittel/4/paragraf', that's [('kapittel','4'), ('paragraf','')].
    """
    segments = raw_path.split('/')
    pairs = []
    i = 0
    while i < len(segments):
        node = segments[i]   # e.g. "kapittel"
        number = ""
        # If next segment is purely numeric, treat it as the number
        if i+1 < len(segments) and re.match(r'^[0-9]+$', segments[i+1]):
            number = segments[i+1]
            i += 2
        else:
            i += 1
        pairs.append((node, number))
    return pairs

def build_canonical_subpath(pairs, node_count):
    """
    Keep the first node_count pairs and rejoin them into 'kapittel/4/paragraf/1'
    if node_count=2 and pairs is [('kapittel','4'),('paragraf','1'),('ledd','2')].
    """
    keep = pairs[:node_count]  # e.g. 2 → [('kapittel','4'),('paragraf','1')]
    parts = []
    for (node, num) in keep:
        parts.append(node)
        if num:  # only add the numeric if it exists
            parts.append(num)
    return '/'.join(parts)

def all_nodes_have_numbers(pairs):
    """
    Return True if *all* pairs have a non-empty numeric.
    If the last node is missing a numeric, we consider it a summary line.
    Example:
      [('kapittel','4'), ('paragraf','')] → False
      [('kapittel','4'), ('paragraf','1')] → True
    You may decide whether *all* nodes need a number or only the *last* node.
    Typically, for aggregator like "kapittel/paragraf", both kapittel + paragraf should be numeric.
    """
    return all(num != "" for (_, num) in pairs)

def aggregate_hierarchy(total_counts, distinct_counts):
    agg_total = Counter()
    agg_distinct_sets = defaultdict(set)

    for raw_path, total_count in total_counts.items():
        # Skip if no digits at all
        if not has_any_numeric(raw_path):
            continue

        aggregator_key = strip_numeric_parts(raw_path)
        if not aggregator_key:
            continue

        # e.g. "kapittel/paragraf" has node_count=2
        node_count = len(aggregator_key.split('/'))

        # parse raw path into (node, number) pairs, e.g. [('kapittel','4'), ('paragraf','1'), ('ledd','2')]
        pairs = parse_path_into_pairs(raw_path)

        # keep only the first node_count pairs to unify deeper expansions
        subpairs = pairs[:node_count]

        # only count if *all* those pairs have numbers
        # (so "paragraf" or "ledd" is not missing its numeric piece)
        if not all_nodes_have_numbers(subpairs):
            # skip this one, it's a "summary line" lacking a numeric in the aggregator's final node
            continue

        canonical = build_canonical_subpath(pairs, node_count)

        # Now record in aggregator
        agg_total[aggregator_key] += total_count
        agg_distinct_sets[aggregator_key].add(canonical)

    agg_distinct = {k: len(v) for k, v in agg_distinct_sets.items()}
    return agg_total, agg_distinct

def main():
    if len(sys.argv) != 2:
        print("Usage: python count_hierarchy_from_html.py <path_to_html_file>")
        return

    html_file = sys.argv[1]
    total_counts, distinct_counts = count_hierarchy_from_html(html_file)

    #print("== Original Raw Hierarchy counts: ==")
    #print("Type: Total Count; Distinct Count")
    #for hierarchy in sorted(total_counts.keys()):
    #    print(f"{hierarchy}: {total_counts[hierarchy]}; {distinct_counts[hierarchy]}")

    print("\n== Aggregated, skipping summary lines & ignoring numeric IDs: ==")
    agg_total, agg_distinct = aggregate_hierarchy(total_counts, distinct_counts)
    print("Type: Summed Distinct")
    for agg_key in sorted(agg_total.keys()):
        #print(f"{agg_key}: {agg_total[agg_key]}; {agg_distinct[agg_key]}")
        print(f"{agg_key}: {agg_distinct[agg_key]}")

if __name__ == "__main__":
    main()
