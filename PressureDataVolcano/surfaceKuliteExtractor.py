#!/usr/bin/env pvpython

import os
import re
import csv

from paraview.simple import *
from paraview.servermanager import Fetch


# ==========================================================
# USER INPUTS
# ==========================================================
root_dir = "/home/bollerma/LESdata/SSWT/fullCav/revisedMeshStudy/test2m/surfaceData/surfKulites"


for k in range(1, 7):

    plane_folder = os.path.join(root_dir, f"K{k}_Plane")

    if not os.path.isdir(plane_folder):
        print(f"Skipping missing folder: {plane_folder}")
        continue

    output_csv = os.path.join(
        plane_folder,
        f"K{k}_Plane_pressure_complete.csv"
    )

    files = sorted(
        [
            os.path.join(plane_folder, f)
            for f in os.listdir(plane_folder)
            if re.match(r'.*\d+\.volcsurf$', f)
        ]
    )

    results = []

    for file_path in files:

        print(f"Processing {os.path.basename(file_path)}")

        src = OpenDataFile(file_path)

        try:
            src.PointArrayStatus = ['pressure']
        except:
            pass

        UpdatePipeline()

        stats = DescriptiveStatistics(Input=src)
        stats.VariablesofInterest = ['pressure']

        UpdatePipeline()
        mb = Fetch(stats, 1)

        stats_table = mb.GetBlock(0)

        mean_col = None

        for c in range(stats_table.GetNumberOfColumns()):
            if stats_table.GetColumnName(c) == "Mean":
                mean_col = c
                break

        mean_pressure = float(
            stats_table.GetValue(0, mean_col).ToString()
        )

        # mb = Fetch(stats, 1)
        # for b in range(mb.GetNumberOfBlocks()):

        #     table = mb.GetBlock(b)

        #     print(f"\nBLOCK {b}")

        #     for c in range(table.GetNumberOfColumns()):
        #         print(c, table.GetColumnName(c))

        #     print("Rows:", table.GetNumberOfRows())

        # mean_pressure = None

        # for row in range(table.GetNumberOfRows()):

        #     variable = table.GetValue(row, 0).ToString()

        #     if variable == "pressure":

        #         # Verify column index once for your ParaView version
        #         mean_pressure = float(
        #             table.GetValue(row, 4).ToString()
        #         )
        #         break

        filename = os.path.basename(file_path)

        match = re.search(r'(\d+)\.volcsurf$', filename)

        iteration = (
            int(match.group(1))
            if match else None
        )

        results.append([
            filename,
            iteration,
            mean_pressure
        ])

        Delete(stats)
        Delete(src)

    with open(output_csv, "w", newline="") as f:

        writer = csv.writer(f)

        writer.writerow([
            "filename",
            "iteration",
            "pressure_mean"
        ])

        writer.writerows(results)

    print(f"Wrote {len(results)} rows to {output_csv}")