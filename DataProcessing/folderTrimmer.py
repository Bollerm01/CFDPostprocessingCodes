#!/usr/bin/env python3
"""
Select folders -> pick variables -> copy matching files into Output/<folder name>/.

Assumes files are named  <prefix>.<variable>.<ext>  e.g. "DS_MP.machnumber.dat",
where the middle dot-separated segment is the variable name. The variable
list is built from the FIRST selected folder; every selected folder is then
filtered using the variables you tick.

Only the standard library is used (tkinter, shutil, os).
"""

import os
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox

OUTPUT_NAME = "Output"
PREFIX_FILTER = ""  # e.g. "DS_MP" to only consider files starting with that; "" = any prefix


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def variable_of(filename):
    """
    Filenames look like  <prefix>.<variable>.<ext>  e.g. "DS_MP.machnumber.dat".
    Return the variable name (the middle segment), or None if the name doesn't
    have at least three dot-separated parts.
    """
    if filename.startswith("."):
        return None
    parts = filename.split(".")
    if len(parts) < 3:
        return None
    prefix = parts[0]
    variable = parts[-2]
    if not prefix or not variable:
        return None
    if PREFIX_FILTER and not prefix.startswith(PREFIX_FILTER):
        return None
    return variable


def scan_folder(folder):
    """Return {variable: [filenames]} for one folder."""
    found = {}
    for name in sorted(os.listdir(folder)):
        if not os.path.isfile(os.path.join(folder, name)):
            continue
        var = variable_of(name)
        if var:
            found.setdefault(var, []).append(name)
    return found


def unique_dir(parent, name):
    """Avoid collisions if two selected folders share the same name."""
    path = os.path.join(parent, name)
    n = 2
    while os.path.exists(path) and os.path.abspath(path) in used_dirs:
        path = os.path.join(parent, f"{name}_{n}")
        n += 1
    used_dirs.add(os.path.abspath(path))
    return path


used_dirs = set()


# --------------------------------------------------------------------------- #
# GUI 1: folder selection
# --------------------------------------------------------------------------- #
def pick_folders():
    folders = []
    state = {"ok": False, "last": os.path.expanduser("~")}

    root = tk.Tk()
    root.title("Select folders to process")
    root.geometry("650x380")

    tk.Label(root, text="Add the folders to iterate through (order matters: "
                        "the first folder is scanned for variable names).",
             wraplength=620, justify="left").pack(padx=10, pady=(10, 4), anchor="w")

    frame = tk.Frame(root)
    frame.pack(fill="both", expand=True, padx=10, pady=4)
    sb = tk.Scrollbar(frame)
    sb.pack(side="right", fill="y")
    lb = tk.Listbox(frame, selectmode="extended", yscrollcommand=sb.set)
    lb.pack(side="left", fill="both", expand=True)
    sb.config(command=lb.yview)

    def add():
        d = filedialog.askdirectory(title="Add a folder", initialdir=state["last"])
        if d:
            d = os.path.normpath(d)
            state["last"] = os.path.dirname(d)
            if d not in folders:
                folders.append(d)
                lb.insert("end", d)

    def remove():
        for i in reversed(lb.curselection()):
            lb.delete(i)
            folders.pop(i)

    def go():
        if not folders:
            messagebox.showwarning("No folders", "Add at least one folder.")
            return
        state["ok"] = True
        root.destroy()

    btns = tk.Frame(root)
    btns.pack(fill="x", padx=10, pady=10)
    tk.Button(btns, text="Add folder...", command=add).pack(side="left")
    tk.Button(btns, text="Remove selected", command=remove).pack(side="left", padx=6)
    tk.Button(btns, text="Continue", command=go, width=12).pack(side="right")
    tk.Button(btns, text="Cancel", command=root.destroy, width=8).pack(side="right", padx=6)

    root.mainloop()
    return folders if state["ok"] else None


# --------------------------------------------------------------------------- #
# GUI 2: variable checkboxes
# --------------------------------------------------------------------------- #
def pick_variables(first_folder, variables):
    state = {"ok": False}
    root = tk.Tk()
    root.title("Select variables to keep")
    root.geometry("420x520")

    tk.Label(root, text=f"Variables found in:\n{first_folder}",
             wraplength=390, justify="left").pack(padx=10, pady=(10, 4), anchor="w")

    outer = tk.Frame(root)
    outer.pack(fill="both", expand=True, padx=10, pady=4)
    canvas = tk.Canvas(outer, highlightthickness=0)
    sb = tk.Scrollbar(outer, orient="vertical", command=canvas.yview)
    inner = tk.Frame(canvas)
    inner.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
    canvas.create_window((0, 0), window=inner, anchor="nw")
    canvas.configure(yscrollcommand=sb.set)
    canvas.pack(side="left", fill="both", expand=True)
    sb.pack(side="right", fill="y")

    # Mouse wheel scrolling (Windows/macOS/Linux)
    def wheel(e):
        canvas.yview_scroll(-1 if (e.num == 4 or e.delta > 0) else 1, "units")
    canvas.bind_all("<MouseWheel>", wheel)
    canvas.bind_all("<Button-4>", wheel)
    canvas.bind_all("<Button-5>", wheel)

    vars_ = {}
    for v in sorted(variables):
        var = tk.BooleanVar(value=False)
        vars_[v] = var
        tk.Checkbutton(inner, text=v, variable=var, anchor="w").pack(fill="x", anchor="w")

    def set_all(val):
        for var in vars_.values():
            var.set(val)

    def go():
        if not any(v.get() for v in vars_.values()):
            messagebox.showwarning("Nothing selected", "Tick at least one variable.")
            return
        state["ok"] = True
        root.destroy()

    top = tk.Frame(root)
    top.pack(fill="x", padx=10)
    tk.Button(top, text="Select all", command=lambda: set_all(True)).pack(side="left")
    tk.Button(top, text="Deselect all", command=lambda: set_all(False)).pack(side="left", padx=6)

    bottom = tk.Frame(root)
    bottom.pack(fill="x", padx=10, pady=10)
    tk.Button(bottom, text="Copy files", command=go, width=12).pack(side="right")
    tk.Button(bottom, text="Cancel", command=root.destroy, width=8).pack(side="right", padx=6)

    root.mainloop()
    if not state["ok"]:
        return None
    return [v for v, var in vars_.items() if var.get()]


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def main():
    folders = pick_folders()
    if not folders:
        return

    first_scan = scan_folder(folders[0])
    if not first_scan:
        r = tk.Tk(); r.withdraw()
        messagebox.showerror("No variables found",
                             f"No '<prefix>.<variable>.<ext>' files found in:\n{folders[0]}")
        return

    keep = pick_variables(folders[0], list(first_scan))
    if not keep:
        return
    keep_set = set(keep)

    # Output root goes in the common parent of the selected folders
    try:
        parent = os.path.commonpath(folders)
        if parent in folders:
            parent = os.path.dirname(parent)
    except ValueError:  # different drives
        parent = os.path.dirname(folders[0])
    out_root = os.path.join(parent, OUTPUT_NAME)
    os.makedirs(out_root, exist_ok=True)

    total, log = 0, []
    for folder in folders:
        if os.path.abspath(folder) == os.path.abspath(out_root):
            continue
        scan = scan_folder(folder)
        dest = unique_dir(out_root, os.path.basename(folder))
        os.makedirs(dest, exist_ok=True)

        copied = 0
        for var in keep:
            for fname in scan.get(var, []):
                shutil.copy2(os.path.join(folder, fname), os.path.join(dest, fname))
                copied += 1
        missing = sorted(keep_set - set(scan))
        line = f"{os.path.basename(folder)}: {copied} file(s) copied"
        if missing:
            line += f"  (no files for: {', '.join(missing)})"
        log.append(line)
        total += copied

    summary = f"Done. {total} file(s) copied to:\n{out_root}\n\n" + "\n".join(log)
    print(summary)
    r = tk.Tk(); r.withdraw()
    messagebox.showinfo("Finished", summary)
    r.destroy()


if __name__ == "__main__":
    main()