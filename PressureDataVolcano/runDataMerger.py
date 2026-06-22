from pathlib import Path
import shutil

# ==========================
# USER INPUTS
# ==========================

root1 = Path("/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/surfaceData")
root2 = Path("/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/surfaceData2")
root3 = Path("/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/surfaceData3")
dest_root = Path("/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/surfaceDataCombined")

# ==========================
# COPY FUNCTION
# ==========================

def copy_tree(src_root, dst_root):
    for src_file in src_root.rglob("*"):
        if src_file.is_file():

            # Relative path from source root
            rel_path = src_file.relative_to(src_root)

            # Destination file path
            dst_file = dst_root / rel_path

            # Create destination directory if needed
            dst_file.parent.mkdir(parents=True, exist_ok=True)

            # Copy and overwrite if file exists
            shutil.copy2(src_file, dst_file)

# ==========================
# EXECUTION
# ==========================

print("Copying first dataset...")
copy_tree(root1, dest_root)

print("Copying second dataset (overwriting duplicates)...")
copy_tree(root2, dest_root)

print("Copying third dataset (overwriting duplicates)...")
copy_tree(root3, dest_root)

print("Done.")