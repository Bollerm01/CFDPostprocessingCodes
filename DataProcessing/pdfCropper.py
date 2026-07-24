#!/usr/bin/env python3
"""
crop_pdfs_gui.py
=================

A simple desktop GUI for cropping every PDF under a root folder (recursively,
including all subfolders) to match a crop box you draw on one reference PDF.

Workflow:
    1. Browse for the input root folder (the folder containing your PDFs /
       subfolders of PDFs).
    2. Pick a reference PDF (defaults to the first PDF found in the input
       folder — change it if you want).
    3. Click "Select Crop Box...", drag a rectangle over the area you want
       to keep, click Confirm.
    4. Browse for an output folder.
    5. Click "Run — Crop All PDFs". Cropped copies are written to the output
       folder, mirroring the input folder's subfolder structure. Your
       original files are never modified.

Requirements:
    pip install pymupdf pillow matplotlib
    (tkinter ships with most Python installs; on some Linux distros install
    it separately, e.g. `sudo apt install python3-tk`)

Run:
    python3 crop_pdfs_gui.py
"""

import io
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

import fitz  # PyMuPDF


# ---------------------------------------------------------------------------
# Core cropping logic
# ---------------------------------------------------------------------------

def crop_box_for_page(target_rect: fitz.Rect, ref_box: fitz.Rect, center: bool) -> fitz.Rect:
    """Fit ref_box onto a page of size target_rect, clamping so the box
    never falls outside the actual page (handles pages that are a
    different size than the reference)."""
    w = min(ref_box.width, target_rect.width)
    h = min(ref_box.height, target_rect.height)

    if center:
        x0 = target_rect.x0 + (target_rect.width - w) / 2
        y0 = target_rect.y0 + (target_rect.height - h) / 2
    else:
        x0 = max(target_rect.x0, min(ref_box.x0, target_rect.x1 - w))
        y0 = max(target_rect.y0, min(ref_box.y0, target_rect.y1 - h))

    return fitz.Rect(x0, y0, x0 + w, y0 + h)


def apply_crop(src: Path, dst: Path, ref_box: fitz.Rect, page_num: int, all_pages: bool, center: bool) -> bool:
    doc = fitz.open(src)
    pages = list(doc) if all_pages else ([doc[page_num]] if page_num < len(doc) else [])

    if not pages:
        doc.close()
        return False

    for page in pages:
        box = crop_box_for_page(page.rect, ref_box, center)
        page.set_cropbox(box)

    dst.parent.mkdir(parents=True, exist_ok=True)
    doc.save(str(dst), garbage=3, deflate=True)
    doc.close()
    return True


# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------

class CropApp:
    def __init__(self, root):
        self.root = root
        root.title("PDF Crop Tool")
        root.geometry("700x560")
        root.minsize(620, 480)

        self.input_folder = tk.StringVar()
        self.output_folder = tk.StringVar()
        self.reference_file = tk.StringVar()
        self.preview_page = tk.IntVar(value=1)
        self.all_pages = tk.BooleanVar(value=True)
        self.center_on_mismatch = tk.BooleanVar(value=False)
        self.crop_box = None  # fitz.Rect, set once the user confirms a selection

        self._build_ui()

    # -- UI layout ----------------------------------------------------------

    def _build_ui(self):
        pad = {"padx": 10, "pady": 6}

        frm_in = ttk.LabelFrame(self.root, text="1. Input folder (root — will scan all subfolders for PDFs)")
        frm_in.pack(fill="x", **pad)
        ttk.Entry(frm_in, textvariable=self.input_folder).pack(side="left", fill="x", expand=True, padx=5, pady=5)
        ttk.Button(frm_in, text="Browse...", command=self.choose_input).pack(side="left", padx=5)

        frm_ref = ttk.LabelFrame(self.root, text="2. Reference PDF (source of the crop box)")
        frm_ref.pack(fill="x", **pad)
        ttk.Entry(frm_ref, textvariable=self.reference_file).pack(side="left", fill="x", expand=True, padx=5, pady=5)
        ttk.Button(frm_ref, text="Browse...", command=self.choose_reference).pack(side="left", padx=5)
        ttk.Label(frm_ref, text="Page:").pack(side="left", padx=(10, 0))
        ttk.Spinbox(frm_ref, from_=1, to=999, width=5, textvariable=self.preview_page).pack(side="left", padx=(0, 5))

        frm_box = ttk.LabelFrame(self.root, text="3. Crop box")
        frm_box.pack(fill="x", **pad)
        ttk.Button(frm_box, text="Select Crop Box...", command=self.select_crop_box).pack(side="left", padx=5, pady=5)
        self.box_label = ttk.Label(frm_box, text="No crop box selected yet")
        self.box_label.pack(side="left", padx=10)

        frm_opts = ttk.LabelFrame(self.root, text="Options")
        frm_opts.pack(fill="x", **pad)
        ttk.Checkbutton(
            frm_opts,
            text="Apply to every page of each PDF (uncheck to only crop the same page number as the reference)",
            variable=self.all_pages,
        ).pack(anchor="w", padx=5, pady=2)
        ttk.Checkbutton(
            frm_opts,
            text="Center the crop box on pages that are a different size than the reference",
            variable=self.center_on_mismatch,
        ).pack(anchor="w", padx=5, pady=2)

        frm_out = ttk.LabelFrame(self.root, text="4. Output folder (originals are never modified)")
        frm_out.pack(fill="x", **pad)
        ttk.Entry(frm_out, textvariable=self.output_folder).pack(side="left", fill="x", expand=True, padx=5, pady=5)
        ttk.Button(frm_out, text="Browse...", command=self.choose_output).pack(side="left", padx=5)

        self.run_btn = ttk.Button(self.root, text="Run — Crop All PDFs", command=self.run)
        self.run_btn.pack(pady=8)

        self.log = tk.Text(self.root, height=14)
        self.log.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    # -- Folder / file pickers ----------------------------------------------

    def choose_input(self):
        folder = filedialog.askdirectory(title="Select input root folder")
        if not folder:
            return
        self.input_folder.set(folder)
        if not self.reference_file.get():
            pdfs = sorted(Path(folder).rglob("*.pdf"))
            if pdfs:
                self.reference_file.set(str(pdfs[0]))

    def choose_reference(self):
        f = filedialog.askopenfilename(title="Select reference PDF", filetypes=[("PDF files", "*.pdf")])
        if not f:
            return
        self.reference_file.set(f)
        self.crop_box = None
        self.box_label.config(text="No crop box selected yet (reference changed)")

    def choose_output(self):
        folder = filedialog.askdirectory(title="Select output folder")
        if folder:
            self.output_folder.set(folder)

    # -- Crop box selection ---------------------------------------------------

    def select_crop_box(self):
        ref = self.reference_file.get()
        if not ref or not Path(ref).is_file():
            messagebox.showerror("Error", "Please select a valid reference PDF first.")
            return

        page_num = max(0, self.preview_page.get() - 1)
        try:
            box = self._open_selector(ref, page_num)
        except Exception as e:
            messagebox.showerror("Error", str(e))
            return

        if box is None:
            return  # user cancelled

        self.crop_box = box
        self.box_label.config(
            text=f"({box.x0:.0f}, {box.y0:.0f}) -> ({box.x1:.0f}, {box.y1:.0f})  "
                 f"[{box.width:.0f} x {box.height:.0f} pt]"
        )

    def _open_selector(self, pdf_path, page_num, dpi=150):
        # NOTE: deliberately avoid matplotlib.pyplot here. pyplot runs its own
        # event/window management, and mixing it with an embedded Tk canvas
        # is a known cause of sibling widgets (like a Confirm button)
        # becoming unresponsive. Building the Figure directly and embedding
        # it keeps everything on Tkinter's single event loop.
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
        from matplotlib.figure import Figure
        from matplotlib.widgets import RectangleSelector
        from PIL import Image

        doc = fitz.open(pdf_path)
        if page_num >= len(doc):
            n = len(doc)
            doc.close()
            raise ValueError(f"Reference PDF only has {n} page(s) — lower the page number.")
        page = doc[page_num]
        zoom = dpi / 72.0
        pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom))
        image = Image.open(io.BytesIO(pix.tobytes("png")))
        img_w, img_h = image.size
        doc.close()

        top = tk.Toplevel(self.root)
        top.title(f"Drag a crop box — {Path(pdf_path).name} (page {page_num + 1})")
        top.transient(self.root)
        top.grab_set()

        fig = Figure(figsize=(8, 9.5))
        ax = fig.add_subplot(111)
        ax.imshow(image)
        ax.set_title("Drag to select the crop area, then click Confirm")
        ax.set_xticks([])
        ax.set_yticks([])

        canvas = FigureCanvasTkAgg(fig, master=top)
        canvas.draw()
        canvas.get_tk_widget().pack(fill="both", expand=True)

        selector = RectangleSelector(
            ax, lambda eclick, erelease: None, useblit=True, button=[1],
            minspanx=5, minspany=5, spancoords="pixels", interactive=True,
        )

        result = {"box": None}

        def confirm():
            # Read straight from the selector's own state rather than a
            # callback flag — this is what actually reflects what's drawn
            # on screen right now, regardless of event-firing quirks.
            x0, x1, y0, y1 = selector.extents
            if (x1 - x0) < 2 or (y1 - y0) < 2:
                messagebox.showwarning("No selection", "Drag a rectangle on the image first.")
                return
            x0, x1 = sorted((max(0, x0), min(img_w, x1)))
            y0, y1 = sorted((max(0, y0), min(img_h, y1)))
            result["box"] = fitz.Rect(x0 / zoom, y0 / zoom, x1 / zoom, y1 / zoom)
            top.destroy()

        def cancel():
            top.destroy()

        btn_frame = ttk.Frame(top)
        btn_frame.pack(fill="x")
        ttk.Button(btn_frame, text="Confirm", command=confirm).pack(side="left", padx=10, pady=6)
        ttk.Button(btn_frame, text="Cancel", command=cancel).pack(side="left", padx=10, pady=6)

        top.protocol("WM_DELETE_WINDOW", cancel)
        self.root.wait_window(top)
        return result["box"]

    # -- Run ------------------------------------------------------------------

    def run(self):
        input_folder = self.input_folder.get()
        output_folder = self.output_folder.get()

        if not input_folder or not Path(input_folder).is_dir():
            messagebox.showerror("Error", "Please select a valid input folder.")
            return
        if not output_folder:
            messagebox.showerror("Error", "Please select an output folder.")
            return
        if self.crop_box is None:
            messagebox.showerror("Error", "Please select a crop box first.")
            return

        root = Path(input_folder)
        out_root = Path(output_folder)

        pdfs = sorted(root.rglob("*.pdf"))
        if not pdfs:
            messagebox.showerror("Error", "No PDFs found in the input folder.")
            return

        if out_root.resolve() == root.resolve():
            messagebox.showerror("Error", "Output folder must be different from the input folder.")
            return

        self.log.delete("1.0", tk.END)
        self.run_btn.config(state="disabled")
        threading.Thread(target=self._process, args=(pdfs, root, out_root), daemon=True).start()

    def _process(self, pdfs, root, out_root):
        ref_box = self.crop_box
        page_num = max(0, self.preview_page.get() - 1)
        all_pages = self.all_pages.get()
        center = self.center_on_mismatch.get()

        ok, skipped = 0, 0
        for pdf in pdfs:
            rel = pdf.relative_to(root)
            dst = out_root / rel
            try:
                if apply_crop(pdf, dst, ref_box, page_num, all_pages, center):
                    self._log(f"cropped: {rel}")
                    ok += 1
                else:
                    self._log(f"skipped (no matching page): {rel}")
                    skipped += 1
            except Exception as e:
                self._log(f"FAILED: {rel}  ({e})")
                skipped += 1

        self._log(f"\nDone. {ok} cropped, {skipped} skipped/failed.")
        self._log(f"Output folder: {out_root}")
        self.root.after(0, lambda: self.run_btn.config(state="normal"))

    def _log(self, msg):
        def _append():
            self.log.insert(tk.END, msg + "\n")
            self.log.see(tk.END)
        self.root.after(0, _append)


def main():
    root = tk.Tk()
    CropApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()