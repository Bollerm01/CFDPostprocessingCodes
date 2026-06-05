import tkinter as tk
from tkinter import filedialog, simpledialog
import pandas as pd
import numpy as np
import os

# Hide main window
root = tk.Tk()
root.withdraw()

# Ask user for total duration
duration = simpledialog.askfloat(
    "Simulation Duration",
    "Enter total duration:"
)

if duration is None:
    print("No duration entered.")
    exit()

# Select CSV files
csv_files = filedialog.askopenfilenames(
    title="Select CSV Files",
    filetypes=[("CSV files", "*.csv")]
)

if not csv_files:
    print("No files selected.")
    exit()

for csv_file in csv_files:

    print(f"Processing: {os.path.basename(csv_file)}")

    # Read CSV
    df = pd.read_csv(csv_file)

    n_rows = len(df)

    if n_rows == 0:
        print(f"Skipping empty file: {csv_file}")
        continue

    # Generate evenly spaced time values
    if n_rows == 1:
        time_values = [0.0]
    else:
        time_values = np.linspace(
            0.0,
            duration,
            n_rows
        )

    # Insert between columns B and C
    df.insert(2, "time2", time_values)

    # Overwrite original file
    df.to_csv(csv_file, index=True)

    print(f"Updated: {csv_file}")

print(f"\nCompleted {len(csv_files)} file(s).")