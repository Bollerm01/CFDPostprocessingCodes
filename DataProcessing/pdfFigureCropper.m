function pdfFigureCropper()
%PDFFIGURECROPPER Interactively crop figures out of a multi-page PDF deck
%   and save each crop as its own (vector) PDF file.
%
%   USAGE:
%       Just run:  pdfFigureCropper
%
%   WORKFLOW:
%       1. Choose the source PDF.
%       2. Type in which page to crop from.
%       3. The page is displayed; drag/resize the red rectangle around the
%          figure you want, then double-click inside it to confirm.
%       4. Choose a filename/location for the cropped PDF.
%       5. You'll be asked if you want to crop another figure (from the
%          same or a different page) - repeat as many times as you like.
%
%   REQUIREMENTS:
%       - Ghostscript must be installed and on the system PATH
%         (called 'gs' on macOS/Linux, 'gswin64c' or 'gswin32c' on Windows).
%         Download: https://ghostscript.com/releases/gsdnld.html
%       - Image Processing Toolbox (for drawrectangle / imshow).
%
%   NOTES:
%       - Cropping is done on the actual PDF page (via Ghostscript CropBox),
%         so text/vector content stays sharp - it is NOT rasterized.
%       - The on-screen preview IS rasterized (for display only); this does
%         not affect the quality of the saved crop.

    gsCmd = locateGhostscript();
    if isempty(gsCmd)
        error(['Ghostscript not found on the system PATH. Install it from ' ...
               'https://ghostscript.com/releases/gsdnld.html and try again.']);
    end

    [f, p] = uigetfile('*.pdf', 'Select the PDF deck to crop figures from');
    if isequal(f, 0)
        return;
    end
    srcPdf = fullfile(p, f);

    nPages = getPdfPageCount(srcPdf, gsCmd);
    fprintf('Loaded "%s" (%d pages).\n', f, nPages);

    renderDPI = 200;   % resolution used only for the on-screen preview
    keepGoing = true;

    while keepGoing
        pageStr = inputdlg(sprintf('Page number to crop from (1-%d):', nPages), ...
                            'Select Page', 1, {'1'});
        if isempty(pageStr)
            break;
        end
        pageNum = round(str2double(pageStr{1}));
        if isnan(pageNum) || pageNum < 1 || pageNum > nPages
            uiwait(warndlg('Invalid page number.', 'Error'));
            continue;
        end

        tmpImg = [tempname() '.png'];
        renderPageToImage(srcPdf, pageNum, renderDPI, tmpImg, gsCmd);
        img = imread(tmpImg);
        delete(tmpImg);

        [pageWpt, pageHpt] = getPageSizePoints(srcPdf, pageNum, gsCmd);

        fig = figure('Name', sprintf('Page %d - drag box, double-click to confirm', pageNum), ...
                     'NumberTitle', 'off');
        imshow(img);
        title('Drag/resize the rectangle around the figure, then double-click inside it to confirm.');
        imgH = size(img, 1);
        imgW = size(img, 2);
        initPos = [imgW*0.1, imgH*0.1, imgW*0.8, imgH*0.8];
        h = drawrectangle('Color', 'r', 'Position', initPos);
        wait(h);                 % blocks until user double-clicks the ROI
        pos = h.Position;        % [x y w h] in pixel coords, origin top-left
        close(fig);

        % --- convert pixel box to PDF points (origin bottom-left) ---
        sx = pageWpt / imgW;
        sy = pageHpt / imgH;
        x1 = pos(1) * sx;
        x2 = (pos(1) + pos(3)) * sx;
        yTopPx = pos(2) * sy;
        yBotPx = (pos(2) + pos(4)) * sy;
        y1 = pageHpt - yBotPx;
        y2 = pageHpt - yTopPx;

        [sf, sp] = uiputfile('*.pdf', sprintf('Save cropped figure from page %d as', pageNum));
        if isequal(sf, 0)
            uiwait(warndlg('Save cancelled - figure not saved.', 'Cancelled'));
        else
            outPdf = fullfile(sp, sf);
            cropPdfPage(srcPdf, pageNum, [x1 y1 x2 y2], outPdf, gsCmd);
            fprintf('Saved: %s\n', outPdf);
        end

        choice = questdlg('Crop another figure?', 'Continue?', 'Yes', 'No', 'Yes');
        keepGoing = strcmp(choice, 'Yes');
    end

    disp('Done.');
end

% ============================= helpers =============================

function gsCmd = locateGhostscript()
    candidates = {'gs', 'gswin64c', 'gswin32c'};
    gsCmd = '';
    for i = 1:numel(candidates)
        [status, ~] = system(sprintf('%s -v', candidates{i}));
        if status == 0
            gsCmd = candidates{i};
            return;
        end
    end
end

function nPages = getPdfPageCount(pdfFile, gsCmd)
    cmd = sprintf('%s -q -dNODISPLAY -dNOSAFER -c "(%s) (r) file runpdfbegin pdfpagecount = quit"', ...
                   gsCmd, strrep(pdfFile, '\', '/'));
    [status, out] = system(cmd);
    if status ~= 0
        error('Failed to read PDF page count via Ghostscript.\n%s', out);
    end
    toks = regexp(out, '\d+', 'match');
    nPages = str2double(toks{end});
end

function [wPt, hPt] = getPageSizePoints(pdfFile, pageNum, gsCmd)
    script = sprintf(['(%s) (r) file runpdfbegin %d pdfgetpage /MediaBox get ' ...
                       '{=print ( ) print} forall quit'], ...
                      strrep(pdfFile, '\', '/'), pageNum);
    cmd = sprintf('%s -q -dNODISPLAY -dNOSAFER -c "%s"', gsCmd, script);
    [status, out] = system(cmd);
    if status ~= 0
        error('Failed to read page size via Ghostscript.\n%s', out);
    end
    vals = str2num(out); %#ok<ST2NM>
    wPt = vals(3) - vals(1);
    hPt = vals(4) - vals(2);
end

function renderPageToImage(pdfFile, pageNum, dpi, outImg, gsCmd)
    cmd = sprintf(['%s -q -dNOPAUSE -dBATCH -sDEVICE=png16m -r%d ' ...
                    '-dFirstPage=%d -dLastPage=%d -o "%s" "%s"'], ...
                   gsCmd, dpi, pageNum, pageNum, outImg, pdfFile);
    [status, out] = system(cmd);
    if status ~= 0
        error('Ghostscript failed to render page.\n%s', out);
    end
end

function cropPdfPage(pdfFile, pageNum, box, outPdf, gsCmd)
    % box = [x1 y1 x2 y2] in PDF points (PDF coordinate system)
    pdfmarkStr = sprintf('[/CropBox [%.2f %.2f %.2f %.2f] /PAGE pdfmark', ...
                          box(1), box(2), box(3), box(4));
    cmd = sprintf(['%s -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite ' ...
                    '-dFirstPage=%d -dLastPage=%d -o "%s" -c "%s" -f "%s"'], ...
                   gsCmd, pageNum, pageNum, outPdf, pdfmarkStr, pdfFile);
    [status, out] = system(cmd);
    if status ~= 0
        error('Ghostscript failed to crop PDF page.\n%s', out);
    end
end