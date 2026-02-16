# Function to sort the combined run Excel files into folders based on location
# Input: Run directories with pre-combined .XLSX files
# Output: Folder that contains subfolders of locations, each of which contain the combined .XLSX from the runs

import os
import shutil
import re
import tkinter as tk
from tkinter import filedialog, messagebox

# ---------------------------------------------------------------
# Utility Functions
# ---------------------------------------------------------------

def extract_prefix(filename):
    """Extract string before first underscore."""
    return filename.split("_")[0]

def extract_test_suffix(dir_path):
    folder = os.path.basename(os.path.normpath(dir_path))
    return folder



# ---------------------------------------------------------------
# GUI Checkbox Selector
# ---------------------------------------------------------------

def select_folders_gui(subdirs):
    """Show a checkbox GUI so the user can pick any number of directories."""
    sel_win = tk.Toplevel()
    sel_win.title("Select Test Directories")
    sel_win.geometry("400x400")

    tk.Label(
        sel_win,
        text="Select one or more directories:",
        font=("Arial", 12)
    ).pack(pady=5)

    vars_list = []
    for d in subdirs:
        var = tk.BooleanVar()
        cb = tk.Checkbutton(
            sel_win,
            text=os.path.basename(d),
            variable=var,
            anchor="w"
        )
        cb.pack(fill="x", padx=20)
        vars_list.append((var, d))

    selected_dirs = []

    def confirm():
        checked = [d for var, d in vars_list if var.get()]
        if len(checked) == 0:
            messagebox.showerror(
                "Error",
                "You must select at least one directory."
            )
            return
        selected_dirs.extend(checked)
        sel_win.destroy()

    tk.Button(
        sel_win,
        text="Confirm Selection",
        command=confirm
    ).pack(pady=10)

    sel_win.grab_set()   # modal
    sel_win.wait_window()

    return selected_dirs

# ---------------------------------------------------------------
# Main Script Logic
# ---------------------------------------------------------------

def main():
    root = tk.Tk()
    root.withdraw()

    # Pick parent directory
    parent_dir = filedialog.askdirectory(
        title="Select Parent Folder Containing Test Directories"
    )
    if not parent_dir:
        messagebox.showerror("Error", "No directory selected.")
        return

    subdirs = [
        os.path.join(parent_dir, d)
        for d in os.listdir(parent_dir)
        if os.path.isdir(os.path.join(parent_dir, d))
    ]

    if len(subdirs) < 1:
        messagebox.showerror(
            "Error",
            "Parent folder must contain at least one subdirectory."
        )
        return

    # GUI selection of folders
    source_dirs = select_folders_gui(subdirs)
    if not source_dirs:
        return

    # Select output folder
    output_root = filedialog.askdirectory(
        title="Select Output Folder"
    )
    if not output_root:
        messagebox.showerror("Error", "No output folder selected.")
        return

    # Collect prefixes
    prefixes = set()
    for d in source_dirs:
        for f in os.listdir(d):
            if f.lower().endswith(".xlsx"):
                prefixes.add(extract_prefix(f))

    if not prefixes:
        messagebox.showerror(
            "Error",
            "No Excel files found in selected directories."
        )
        return

    # Create prefix subfolders
    output_subfolders = {}
    for p in prefixes:
        pf = os.path.join(output_root, p)
        os.makedirs(pf, exist_ok=True)
        output_subfolders[p] = pf

    # Process files
    for d in source_dirs:
        test_suffix = extract_test_suffix(d)

        for f in os.listdir(d):
            if not f.lower().endswith(".xlsx"):
                continue

            prefix = extract_prefix(f)
            if prefix not in prefixes:
                continue

            src = os.path.join(d, f)
            dst_folder = output_subfolders[prefix]

            base, ext = os.path.splitext(f)
            new_filename = f"{base}_{test_suffix}{ext}"
            dst = os.path.join(dst_folder, new_filename)

            shutil.copy2(src, dst)

    messagebox.showinfo(
        "Done",
        f"Files successfully sorted into:\n{output_root}"
    )

# ---------------------------------------------------------------
if __name__ == "__main__":
    main()
