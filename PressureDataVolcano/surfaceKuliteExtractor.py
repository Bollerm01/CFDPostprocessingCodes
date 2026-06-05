#!/usr/bin/env pvpython

import os
import re
import csv

from paraview.simple import *
from paraview.servermanager import Fetch


# ==========================================================
# USER INPUTS
# ==========================================================
root_dir = "/home/bollerma/LESdata/SSWT/sliceCav/RD00s/surfaceDataCombined"


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
            if f.endswith(".volcsurf")
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

        table = Fetch(stats, 1)
        print(type(table))
        print("Number of blocks:", table.GetNumberOfBlocks())

        for i in range(table.GetNumberOfBlocks()):
            block = table.GetBlock(i)
            print(i, type(block))

        mean_pressure = None

        for row in range(table.GetNumberOfRows()):

            variable = table.GetValue(row, 0).ToString()

            if variable == "pressure":

                # Verify column index once for your ParaView version
                mean_pressure = float(
                    table.GetValue(row, 4).ToString()
                )
                break

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