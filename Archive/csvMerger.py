import os
import pandas as pd

# Root directory containing nested folders of CSVs
root_dir = r"C:\Boller Masters Work\CFD\AVIATION CFD\uvxData_vol"

for subdir, _, files in os.walk(root_dir):
    # Only consider CSVs in this folder (non-recursive)
    csv_files = [f for f in files if f.endswith(".csv")]
    if not csv_files:
        continue

    print(f"\n📁 Processing folder: {subdir}")

    folder_dfs = []  # List to hold processed DataFrames

    for file in csv_files:
        file_path = os.path.join(subdir, file)
        print(f"  ➤ Reading {file}")

        # Read header to get the last column name
        with open(file_path, "r", encoding="utf-8") as f:
            first_line = f.readline()
        cols = first_line.strip().split(",")
        if "Points_1" not in cols:
            print(f"    ⚠️ Skipping {file}: no Points_1 column")
            continue
        last_col = cols[-1]

        # Read only Points_1 and last column
        try:
            df = pd.read_csv(file_path, usecols=["Points_1", last_col])
        except ValueError:
            print(f"    ⚠️ Skipping {file}: missing required columns")
            continue

        # Clean
        df.dropna(subset=["Points_1"], inplace=True)
        df.reset_index(drop=True, inplace=True)

        # Rename columns
        file_id = os.path.splitext(file)[0]
        df.rename(columns={
            "Points_1": f"Points_1_{file_id}",
            last_col: f"{file_id}_{last_col}"
        }, inplace=True)

        # Add a blank column for visual separation
        df[""] = ""

        # Reorder columns so blank separator is at the end
        df = df[[f"Points_1_{file_id}", f"{file_id}_{last_col}", ""]]

        folder_dfs.append(df)
        del df  # free memory

    # Concatenate horizontally
    if folder_dfs:
        combined_df = pd.concat(folder_dfs, axis=1)

        # Remove the final blank column for cleaner layout
        if combined_df.columns[-1] == "":
            combined_df = combined_df.iloc[:, :-1]

        folder_name = os.path.basename(subdir.rstrip("/\\"))
        output_path = os.path.join(subdir, f"combined_{folder_name}.xlsx")

        combined_df.to_excel(output_path, index=False, engine="openpyxl")
        print(f"  ✅ Saved combined sheet: {output_path}")
    else:
        print(f"  ⚠️ No valid CSVs found in {subdir}")
