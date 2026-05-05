import os
import csv
import argparse
import xml.etree.ElementTree as ET

# Default Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_AIRD = os.path.join(
    SCRIPT_DIR, "capella-riscv-threat-model", "ThreatModel_RISCV.aird"
)
DEFAULT_OUTPUT = os.path.join(SCRIPT_DIR, "extracted_tables")


def get_local_name(tag):
    """Returns the local name of a tag, stripping the namespace prefix."""
    return tag.split("}")[-1]


def find_all_by_local_name(parent, local_name):
    """Finds all descendants with the given local name."""
    return [el for el in parent.iter() if get_local_name(el.tag) == local_name]


def find_children_by_local_name(parent, local_name):
    """Finds direct children with the given local name."""
    return [el for el in parent if get_local_name(el.tag) == local_name]


def get_uid(el):
    """Retrieves the UID of an element, handling xmi:id or uid attributes."""
    uid = el.get("uid")
    if not uid:
        # Check for xmi:id which is usually {http://www.omg.org/XMI}id
        for attr, val in el.attrib.items():
            if attr.endswith("}id"):
                return val
    return uid


def extract_tables(aird_file, output_dir):
    if not os.path.exists(aird_file):
        print(f"Error: AIRD file not found at {aird_file}")
        return

    print(f"Parsing {aird_file}...")
    try:
        # We use a standard parser. AIRD files can be large, but usually fit in memory.
        tree = ET.parse(aird_file)
    except Exception as e:
        print(f"Error parsing XML: {e}")
        return

    root = tree.getroot()

    # 1. Map Table UID to Table Name
    # Representations in Sirius are defined by descriptors that map a name to a path.
    table_uid_to_name = {}
    descriptors = find_all_by_local_name(root, "ownedRepresentationDescriptors")
    for desc in descriptors:
        name = desc.get("name")
        rep_path = desc.get("repPath")
        if name and rep_path and rep_path.startswith("#"):
            uid = rep_path[1:]
            table_uid_to_name[uid] = name

    print(f"Found {len(table_uid_to_name)} potential table descriptions.")

    # 2. Find all DTable elements
    dtables = find_all_by_local_name(root, "DTable")
    print(f"Found {len(dtables)} table objects in AIRD file.")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: {output_dir}")

    extracted_count = 0
    for dtable in dtables:
        uid = get_uid(dtable)
        if not uid or uid not in table_uid_to_name:
            continue

        table_name = table_uid_to_name[uid]
        # Sanitize filename: remove problematic characters
        safe_name = "".join(
            [c if c.isalnum() or c in (" ", "-", "_") else "_" for c in table_name]
        ).strip()
        csv_filename = f"{safe_name}.csv"
        csv_path = os.path.join(output_dir, csv_filename)

        print(f"Extracting: {table_name} ...", end="", flush=True)

        # Identify Columns
        column_headers = ["Line Label"]
        column_ids = []
        for col in find_children_by_local_name(dtable, "columns"):
            label = col.get("label", "")
            col_uid = get_uid(col)
            column_headers.append(label)
            column_ids.append(col_uid)

        # Extract Rows (handling nested lines recursively)
        all_rows = []

        def process_line(line, depth=0):
            line_label = line.get("label", "")

            # Map cell values by column ID for this specific line
            row_cells = {cid: "" for cid in column_ids}
            for cell in find_children_by_local_name(line, "cells"):
                cid = cell.get("column")
                # Column reference in cells might have '#' prefix
                if cid and cid.startswith("#"):
                    cid = cid[1:]
                if cid in row_cells:
                    row_cells[cid] = cell.get("label", "")

            # Construct the CSV row starting with the line label
            csv_row = [line_label]
            for cid in column_ids:
                csv_row.append(row_cells[cid])

            all_rows.append(csv_row)

            # Process sub-lines (Sirius tables support hierarchy)
            for sub_line in find_children_by_local_name(line, "lines"):
                process_line(sub_line, depth + 1)

        # Start recursion from top-level lines of the table
        for line in find_children_by_local_name(dtable, "lines"):
            process_line(line)

        # Write the collected data to CSV
        try:
            with open(csv_path, "w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow(column_headers)
                writer.writerows(all_rows)
            print(" [OK]")
            extracted_count += 1
        except Exception as e:
            print(f" [FAILED: {e}]")

    print(f"\nSuccessfully extracted {extracted_count} tables to {output_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract STPA tables from Capella .aird files.")
    parser.add_argument(
        "-i", "--input", 
        default=DEFAULT_AIRD,
        help=f"Path to the .aird file (default: {DEFAULT_AIRD})"
    )
    parser.add_argument(
        "-o", "--output", 
        default=DEFAULT_OUTPUT,
        help=f"Output directory for CSV files (default: {DEFAULT_OUTPUT})"
    )
    
    args = parser.parse_args()
    extract_tables(args.input, args.output)
