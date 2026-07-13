function CFD_ImageTiler()
% CFD_ImageTiler - Interactive tool for cropping and tiling CFD slice images
%   with a shared colorbar, row/column labels, and PNG/PDF export.
%
% Workflow:
%   1. GUI: select tiling layout, labels, and output filename
%   2. Select a colorbar image and interactively crop it
%   3. Crop the first image freely (sets the crop size for all others)
%   4. Crop subsequent images with a locked size but free position
%   5. Tile images and export as PNG and PDF

    clc;

    %% ── STEP 1: Layout / Label / Output GUI ─────────────────────────────
    params = getLayoutParams();
    if isempty(params), disp('User cancelled. Exiting.'); return; end

    nImages        = params.nImages;
    nRows          = params.nRows;
    nCols          = params.nCols;
    rowLabels      = params.rowLabels;
    colLabels      = params.colLabels;
    outName        = params.outName;
    singleColorbar = params.singleColorbar;

    %% ── STEP 2: Colorbar selection & interactive crop ────────────────────
    if singleColorbar
        % One shared colorbar centred below all columns
        [cbFile, cbPath] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
            'Image Files'}, 'Select the shared colorbar image');
        if isequal(cbFile, 0), disp('Cancelled. Exiting.'); return; end
        [cbImg, ~, cbAlpha] = imread(fullfile(cbPath, cbFile));
        if ~isempty(cbAlpha), cbImg = cat(3, cbImg, cbAlpha); end
        fprintf('\nShared colorbar: adjust rectangle then click Confirm.\n');
        cbCropped = interactiveCrop(cbImg, [], 'Crop Shared Colorbar – click Confirm when done');
    else
        % One colorbar per column
        cbCropped = cell(1, nCols);
        for c = 1 : nCols
            [cbFile, cbPath] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
                'Image Files'}, sprintf('Select colorbar image for column %d of %d', c, nCols));
            if isequal(cbFile, 0), disp('Cancelled. Exiting.'); return; end
            [cbImg, ~, cbAlpha] = imread(fullfile(cbPath, cbFile));
            if ~isempty(cbAlpha), cbImg = cat(3, cbImg, cbAlpha); end
            fprintf('\nColumn %d colorbar: adjust rectangle then click Confirm.\n', c);
            cbCropped{c} = interactiveCrop(cbImg, [], ...
                sprintf('Crop Colorbar – Column %d of %d – click Confirm when done', c, nCols));
        end
    end

    %% ── STEP 3 & 4: Select and crop each CFD image ──────────────────────
    croppedImages = cell(1, nImages);
    cropSize      = [];   % [height, width] set after first image

    for k = 1 : nImages
        [imgFile, imgPath] = uigetfile( ...
            {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image Files'}, ...
            sprintf('Select image %d of %d', k, nImages));
        if isequal(imgFile, 0), disp('Cancelled. Exiting.'); return; end

        % Lock the output folder to wherever the first image lives
        if k == 1
            outFolder = imgPath;
        end

        [img, ~, imgAlpha] = imread(fullfile(imgPath, imgFile));
        % Attach alpha as 4th channel if present so interactiveCrop passes it through
        if ~isempty(imgAlpha)
            img = cat(3, img, imgAlpha);
        end

        if k == 1
            fprintf('\nImage 1: crop freely. Double-click when satisfied.\n');
            croppedImages{k} = interactiveCrop(img, [], ...
                sprintf('Crop Image 1 of %d – double-click when done', nImages));
            cropSize = [size(croppedImages{k}, 1), size(croppedImages{k}, 2)];
            fprintf('Crop size locked to %d × %d px for remaining images.\n', ...
                cropSize(2), cropSize(1));
        else
            fprintf('\nImage %d: move the box to centre it, then double-click.\n', k);
            croppedImages{k} = interactiveCrop(img, cropSize, ...
                sprintf('Crop Image %d of %d – move box, double-click when done', ...
                k, nImages));
        end
    end

    %% ── STEP 5: Tile and export ──────────────────────────────────────────
    fullOutName = fullfile(outFolder, outName);
    fprintf('\nAssembling tiled figure …\n');
    exportTiledFigure(croppedImages, cbCropped, nRows, nCols, ...
        rowLabels, colLabels, fullOutName, singleColorbar);

    fprintf('\nDone! Files saved:\n  %s.png\n  %s.pdf\n', fullOutName, fullOutName);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ── getLayoutParams ───────────────────────────────────────────────────────
function params = getLayoutParams()
% Modal dialog that collects all tiling/label/output parameters.

    params = [];

    %% Build the dialog figure
    dlg = figure('Name', 'CFD Image Tiler – Setup', ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
        'Resize', 'off', 'WindowStyle', 'modal', ...
        'Position', [100 100 480 610], 'Color', [0.94 0.94 0.94]);

    pad = 14;   % horizontal padding
    y   = 560;  % top-down y cursor
    lh  = 22;   % label height
    eh  = 26;   % edit/popup height
    gap = 10;   % gap between controls

    function y = addLabel(txt, yPos)
        uicontrol(dlg, 'Style', 'text', 'String', txt, ...
            'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position', [pad yPos 440 lh], 'BackgroundColor', [0.94 0.94 0.94]);
        y = yPos;
    end

    %% Number of images
    addLabel('Number of images to tile:', y); y = y - eh - 2;
    h.nImages = uicontrol(dlg, 'Style', 'edit', 'String', '4', ...
        'FontSize', 10, 'Position', [pad y 80 eh]);
    y = y - gap - lh;

    %% Rows
    addLabel('Number of rows:', y); y = y - eh - 2;
    h.nRows = uicontrol(dlg, 'Style', 'edit', 'String', '2', ...
        'FontSize', 10, 'Position', [pad y 80 eh]);
    y = y - gap - lh;

    %% Columns
    addLabel('Number of columns:', y); y = y - eh - 2;
    h.nCols = uicontrol(dlg, 'Style', 'edit', 'String', '2', ...
        'FontSize', 10, 'Position', [pad y 80 eh]);
    y = y - gap - lh - 4;

    %% Row labels toggle + field
    % Create the checkbox without a callback first (handle not yet available)
    h.useRowLabels = uicontrol(dlg, 'Style', 'checkbox', ...
        'String', 'Add row labels', 'FontSize', 10, 'Value', 0, ...
        'Position', [pad y 200 lh], 'BackgroundColor', [0.94 0.94 0.94]);
    y = y - eh - 2;
    % Create the edit field, then wire the checkbox callback so h.rowEdit exists
    h.rowEdit = uicontrol(dlg, 'Style', 'edit', ...
        'String', 'Label1, Label2', 'FontSize', 9, ...
        'Position', [pad y 440 eh], 'Enable', 'off', ...
        'TooltipString', 'Comma-separated row labels (top to bottom)');
    h.useRowLabels.Callback = @(s,~) toggleField(s, h.rowEdit);
    y = y - gap - lh - 4;

    %% Column labels toggle + field
    % Same pattern: checkbox first (no callback), then edit field, then wire callback
    h.useColLabels = uicontrol(dlg, 'Style', 'checkbox', ...
        'String', 'Add column labels', 'FontSize', 10, 'Value', 0, ...
        'Position', [pad y 200 lh], 'BackgroundColor', [0.94 0.94 0.94]);
    y = y - eh - 2;
    h.colEdit = uicontrol(dlg, 'Style', 'edit', ...
        'String', 'ColA, ColB', 'FontSize', 9, ...
        'Position', [pad y 440 eh], 'Enable', 'off', ...
        'TooltipString', 'Comma-separated column labels (left to right)');
    h.useColLabels.Callback = @(s,~) toggleField(s, h.colEdit);
    y = y - gap - lh - 4;

    %% Single shared colorbar override
    h.singleColorbar = uicontrol(dlg, 'Style', 'checkbox', ...
        'String', 'Use a single shared colorbar (centred below all images)', ...
        'FontSize', 10, 'Value', 0, ...
        'Position', [pad y 440 lh], 'BackgroundColor', [0.94 0.94 0.94]);
    y = y - gap - lh - 4;

    %% Output filename
    addLabel('Output filename (no extension):', y); y = y - eh - 2;
    h.outName = uicontrol(dlg, 'Style', 'edit', 'String', 'CFD_Tiled_Output', ...
        'FontSize', 10, 'Position', [pad y 440 eh]);
    y = y - gap*2 - lh;

    %% OK / Cancel
    uicontrol(dlg, 'Style', 'pushbutton', 'String', 'OK', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [120 y 100 34], 'Callback', @okCb);
    uicontrol(dlg, 'Style', 'pushbutton', 'String', 'Cancel', ...
        'FontSize', 11, 'Position', [260 y 100 34], 'Callback', @(~,~) delete(dlg));

    uiwait(dlg);  % block until OK or Cancel

    %% Nested callbacks ────────────────────────────────────────────────────
    function toggleField(chk, editCtrl)
        if chk.Value
            editCtrl.Enable = 'on';
        else
            editCtrl.Enable = 'off';
        end
    end

    function okCb(~, ~)
        nI = round(str2double(h.nImages.String));
        nR = round(str2double(h.nRows.String));
        nC = round(str2double(h.nCols.String));

        if any(isnan([nI nR nC])) || any([nI nR nC] < 1)
            errordlg('Please enter positive integers for image count and grid dimensions.', 'Input Error');
            return;
        end
        if nR * nC < nI
            errordlg(sprintf('Grid %d×%d only holds %d cells but %d images requested.', ...
                nR, nC, nR*nC, nI), 'Input Error');
            return;
        end

        p.nImages = nI;
        p.nRows   = nR;
        p.nCols   = nC;

        if h.useRowLabels.Value
            p.rowLabels = strtrim(strsplit(h.rowEdit.String, ','));
        else
            p.rowLabels = {};
        end

        if h.useColLabels.Value
            p.colLabels = strtrim(strsplit(h.colEdit.String, ','));
        else
            p.colLabels = {};
        end

        p.outName        = strtrim(h.outName.String);
        if isempty(p.outName), p.outName = 'CFD_Tiled_Output'; end

        p.singleColorbar = logical(h.singleColorbar.Value);

        params = p;
        delete(dlg);
    end
end


% ── interactiveCrop ───────────────────────────────────────────────────────
function cropped = interactiveCrop(img, lockSize, titleStr)
% Show image in a figure and let the user drag a crop rectangle.
% If lockSize = [H W], the rectangle is constrained to that size.
% User double-clicks inside the rectangle to confirm.

    [imgH, imgW, ~] = size(img);

    % ── Figure layout: image area + button bar at bottom ─────────────
    screenSz  = get(0, 'ScreenSize');          % [1 1 W H]
    maxFigW   = screenSz(3) * 0.85;
    maxFigH   = screenSz(4) * 0.80;
    btnBarH   = 52;                            % pixels reserved for button

    scale  = min(maxFigW / imgW, (maxFigH - btnBarH) / imgH);
    scale  = min(scale, 1);                    % never upscale
    dispW  = max(round(imgW * scale), 300);
    dispH  = max(round(imgH * scale), 200);
    figH   = dispH + btnBarH;

    hFig = figure('Name', titleStr, 'NumberTitle', 'off', ...
        'MenuBar', 'none', 'ToolBar', 'figure', ...
        'Units', 'pixels', ...
        'Position', [max(1, round((screenSz(3)-dispW)/2)), ...
                     max(1, round((screenSz(4)-figH)/2)), ...
                     dispW, figH], ...
        'Resize', 'on', ...
        'Color', 'white', ...
        'CloseRequestFcn', @figCloseCb);

    % Separate alpha before display – imshow only accepts RGB or grayscale.
    % If the image has an alpha channel, composite it over white for display
    % so transparent areas appear white rather than black in the crop window.
    % The original img (with alpha) is still used for the actual crop output.
    if size(img, 3) == 4
        alpha255 = double(img(:,:,4)) / 255;
        imgRGB   = uint8( alpha255 .* double(img(:,:,1:3)) + ...
                          (1 - alpha255) .* 255 );
    else
        imgRGB   = img;
    end

    % Axes fills everything above the button bar
    hAx = axes('Parent', hFig, 'Units', 'pixels', ...
        'Position', [0, btnBarH, dispW, dispH], ...
        'Color', 'white');
    imshow(imgRGB, 'Parent', hAx, 'Border', 'tight');
    set(hAx, 'Color', 'white');
    title(hAx, titleStr, 'Interpreter', 'none', 'FontSize', 9);

    % "Confirm Crop" button centred in the button bar
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', '✔  Confirm Crop', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Units', 'pixels', ...
        'Position', [round(dispW/2) - 90, 10, 180, 32], ...
        'BackgroundColor', [0.2 0.65 0.2], 'ForegroundColor', 'white', ...
        'Callback', @confirmCb);

    % ── Place imrect ──────────────────────────────────────────────────
    if isempty(lockSize)
        % Free crop
        initRect = [round(imgW*0.1), round(imgH*0.1), ...
                    round(imgW*0.8), round(imgH*0.8)];
        hRect = imrect(hAx, initRect);
        fcn   = makeConstrainToRectFcn('imrect', [1 imgW], [1 imgH]);
        setPositionConstraintFcn(hRect, fcn);
    else
        % Locked size – position only
        lockH = lockSize(1);
        lockW = lockSize(2);
        x0    = max(1, round((imgW - lockW) / 2));
        y0    = max(1, round((imgH - lockH) / 2));
        hRect = imrect(hAx, [x0, y0, lockW, lockH]);
        constrainFcn = @(pos) [max(1, min(pos(1), imgW - lockW + 1)), ...
                                max(1, min(pos(2), imgH - lockH + 1)), ...
                                lockW, lockH];
        setPositionConstraintFcn(hRect, constrainFcn);
    end

    % ── Block here until Confirm button or window close ───────────────
    uiwait(hFig);

    % ── Extract crop after uiresume ───────────────────────────────────
    if isvalid(hFig) && isvalid(hRect)
        pos  = round(getPosition(hRect));
        x1   = max(1, pos(1));
        y1   = max(1, pos(2));
        w    = min(pos(3), imgW - x1 + 1);
        h_   = min(pos(4), imgH - y1 + 1);
        cropped = img(y1 : y1+h_-1, x1 : x1+w-1, :);   % full RGBA slice
    else
        warning('Crop window closed without confirming. Using full image.');
        if ~isempty(lockSize)
            cropped = centreForce(img, lockSize(1), lockSize(2));
        else
            cropped = img;
        end
    end

    if isvalid(hFig), delete(hFig); end

    % Guarantee exact locked size (guards against rounding)
    if ~isempty(lockSize)
        cropped = forceSize(cropped, lockSize(1), lockSize(2));
    end

    % ── Nested callbacks ──────────────────────────────────────────────
    function confirmCb(~, ~)
        uiresume(hFig);          % unblock uiwait, keep figure open briefly
    end

    function figCloseCb(~, ~)
        uiresume(hFig);          % also unblock if user closes the window
        delete(hFig);
    end
end


% ── centreForce ───────────────────────────────────────────────────────────
function out = centreForce(img, H, W)
% Centre-crop img to H×W. Pads with transparent white if img is smaller.
    [ih, iw, ic] = size(img);
    % White opaque pad: RGB=255, alpha=255 if 4-ch, else all 255
    out = 255 * ones(H, W, ic, 'uint8');
    if ic == 4, out(:,:,4) = 0; end  % fully transparent padding
    r1 = max(1, floor((ih-H)/2)+1); r2 = min(ih, r1+H-1);
    c1 = max(1, floor((iw-W)/2)+1); c2 = min(iw, c1+W-1);
    oh = r2-r1+1; ow = c2-c1+1;
    out(1:oh, 1:ow, :) = img(r1:r2, c1:c2, :);
end


% ── forceSize ─────────────────────────────────────────────────────────────
function out = forceSize(img, H, W)
% Trim or pad img to exactly H×W, preserving all channels.
    [ih, iw, ic] = size(img);
    if ih == H && iw == W, out = img; return; end
    out = img(1:min(ih,H), 1:min(iw,W), :);
    if size(out,1) < H
        pad = 255 * ones(H-size(out,1), size(out,2), ic, 'uint8');
        if ic == 4, pad(:,:,4) = 0; end
        out = [out; pad];
    end
    if size(out,2) < W
        pad = 255 * ones(size(out,1), W-size(out,2), ic, 'uint8');
        if ic == 4, pad(:,:,4) = 0; end
        out = [out, pad];
    end
end


% ── exportTiledFigure ─────────────────────────────────────────────────────
function exportTiledFigure(images, cbImg, nRows, nCols, rowLabels, colLabels, outName, singleColorbar)
% Assembles a pixel-perfect tiled image, adds labels, places colorbars,
% then exports to PNG and PDF.
% cbImg is either a single image (if singleColorbar=true) or a 1×nCols cell array.

    nImages        = numel(images);
    [cropH, cropW] = deal(size(images{1},1), size(images{1},2));
    nChan          = size(images{1}, 3);

    % ── Spacing constants (pixels) ─────────────────────────────────────
    cellPad     = 20;   % gap between tiled images
    borderPad   = 50;   % outer border (wider left margin for row labels)
    rowLabelGap = 20;   % extra padding between row labels and image grid
    labelFontSz = 13;
    colLabelH   = 0;
    rowLabelW   = 0;

    hasColLabels = ~isempty(colLabels);
    hasRowLabels = ~isempty(rowLabels);

    % Reserve space for labels
    if hasColLabels, colLabelH = 36;  end
    if hasRowLabels, rowLabelW = 120; end

    % Extra gap inserted between label column and image grid
    labelToGridGap = rowLabelGap * double(hasRowLabels);

    % ── Build tiled pixel canvas ──────────────────────────────────────
    canvasW = borderPad + rowLabelW + labelToGridGap + nCols*cropW + (nCols-1)*cellPad + borderPad;
    canvasH = borderPad + colLabelH + nRows*cropH + (nRows-1)*cellPad + borderPad;

    % ── Scale and place colorbars ─────────────────────────────────────
    cbScale = 0.5;
    cbGap   = 18;   % gap between tile block and colorbar row

    if singleColorbar
        % Scale the single image
        cb = cbImg;
        if size(cb,3) == 4
            cb = cat(3, imresize(cb(:,:,1:3), cbScale, 'bilinear'), ...
                        imresize(cb(:,:,4),   cbScale, 'bilinear'));
        else
            cb = imresize(cb, cbScale, 'bilinear');
        end
        cbMaxH = size(cb, 1);
        totalH = canvasH + cbGap + cbMaxH + borderPad;
        canvas = 255 * ones(totalH, canvasW, 3, 'uint8');

        % (images placed below after canvas is created)
        canvas = placeTiles(canvas, images, nCols, cropH, cropW, cellPad, ...
            borderPad, colLabelH, rowLabelW, labelToGridGap);

        % Centre single colorbar under entire grid
        gridW  = nCols*cropW + (nCols-1)*cellPad;
        cbW_   = size(cb, 2);
        cbX    = borderPad + rowLabelW + labelToGridGap + ...
                 max(0, floor((gridW - cbW_) / 2));
        cbY    = canvasH + cbGap;
        canvas = placeColorbar(canvas, cb, cbX, cbY, totalH, canvasW);
    else
        % One colorbar per column
        cbImgs = cell(1, nCols);
        for c = 1 : nCols
            cb = cbImg{c};
            if size(cb,3) == 4
                cbImgs{c} = cat(3, imresize(cb(:,:,1:3), cbScale, 'bilinear'), ...
                                   imresize(cb(:,:,4),   cbScale, 'bilinear'));
            else
                cbImgs{c} = imresize(cb, cbScale, 'bilinear');
            end
        end
        cbMaxH = max(cellfun(@(x) size(x,1), cbImgs));
        totalH = canvasH + cbGap + cbMaxH + borderPad;
        canvas = 255 * ones(totalH, canvasW, 3, 'uint8');

        canvas = placeTiles(canvas, images, nCols, cropH, cropW, cellPad, ...
            borderPad, colLabelH, rowLabelW, labelToGridGap);

        cbY = canvasH + cbGap;
        for c = 1 : nCols
            cb    = cbImgs{c};
            cbW_  = size(cb, 2);
            colX0 = borderPad + rowLabelW + labelToGridGap + (c-1)*(cropW + cellPad);
            cbX   = colX0 + max(0, floor((cropW - cbW_) / 2));
            cbX   = max(1, min(cbX, canvasW - cbW_));
            canvas = placeColorbar(canvas, cb, cbX, cbY, totalH, canvasW);
        end
    end

    % ── Render with MATLAB figure for labels + export ─────────────────
    % Convert canvas to figure, draw labels as axes text, then print
    dpi   = 150;
    figW  = canvasW / dpi;   % inches
    figH  = totalH  / dpi;

    hFig = figure('Visible', 'off', 'Units', 'inches', ...
        'Position', [1 1 figW figH], 'Color', 'white', ...
        'PaperUnits', 'inches', 'PaperSize', [figW figH], ...
        'PaperPosition', [0 0 figW figH]);

    % Main axes covering whole figure
    hAx = axes(hFig, 'Units', 'normalized', 'Position', [0 0 1 1]);
    imshow(canvas, 'Parent', hAx);
    hold(hAx, 'on');
    set(hAx, 'YDir', 'reverse');   % image coords (0,0 top-left)

    % ── Column labels (centred above each column) ─────────────────────
    if hasColLabels
        for c = 1 : min(numel(colLabels), nCols)
            xCentre = borderPad + rowLabelW + labelToGridGap + (c-1)*(cropW+cellPad) + cropW/2;
            yCentre = borderPad + colLabelH/2;
            text(hAx, xCentre, yCentre, colLabels{c}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', labelFontSz, 'FontWeight', 'bold', 'Color', 'k');
        end
    end

    % ── Row labels (centred left of each row) ─────────────────────────
    if hasRowLabels
        for r = 1 : min(numel(rowLabels), nRows)
            xCentre = borderPad + rowLabelW/2;
            yCentre = borderPad + colLabelH + (r-1)*(cropH+cellPad) + cropH/2;
            text(hAx, xCentre, yCentre, rowLabels{r}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', labelFontSz, 'FontWeight', 'bold', 'Color', 'k');
        end
    end

    hold(hAx, 'off');
    axis(hAx, 'off');

    % ── Export PNG ────────────────────────────────────────────────────
    pngFile = [outName '.png'];
    exportgraphics(hFig, pngFile, 'Resolution', dpi, 'BackgroundColor', 'white');
    fprintf('  PNG saved: %s\n', pngFile);

    % ── Export PDF ────────────────────────────────────────────────────
    pdfFile = [outName '.pdf'];
    exportgraphics(hFig, pdfFile, 'ContentType', 'vector', 'BackgroundColor', 'white');
    fprintf('  PDF saved: %s\n', pdfFile);

    close(hFig);
end


% ── placeTiles ────────────────────────────────────────────────────────────
function canvas = placeTiles(canvas, images, nCols, cropH, cropW, cellPad, ...
        borderPad, colLabelH, rowLabelW, labelToGridGap)
% Alpha-composite each cropped image onto the canvas at its grid position.
    for idx = 1 : numel(images)
        r = ceil(idx / nCols);
        c = mod(idx-1, nCols) + 1;
        yStart = borderPad + colLabelH + (r-1)*(cropH + cellPad) + 1;
        xStart = borderPad + rowLabelW + labelToGridGap + (c-1)*(cropW + cellPad) + 1;
        yEnd   = yStart + cropH - 1;
        xEnd   = xStart + cropW - 1;
        tile   = images{idx};
        if size(tile,3) == 1,  tile = repmat(tile,[1 1 3]); end
        if size(tile,3) == 4
            a  = double(tile(:,:,4)) / 255;
            fg = double(tile(:,:,1:3));
            bg = double(canvas(yStart:yEnd, xStart:xEnd, :));
            canvas(yStart:yEnd, xStart:xEnd, :) = uint8(a.*fg + (1-a).*bg);
        else
            canvas(yStart:yEnd, xStart:xEnd, :) = tile;
        end
    end
end


% ── placeColorbar ─────────────────────────────────────────────────────────
function canvas = placeColorbar(canvas, cb, cbX, cbY, totalH, canvasW)
% Alpha-composite a colorbar image onto the canvas at (cbX, cbY).
    cbH_ = size(cb,1);
    cbW_ = size(cb,2);
    cbYe = min(cbY + cbH_ - 1, totalH);
    cbXe = min(cbX + cbW_ - 1, canvasW);
    cbR  = cb;
    if size(cbR,3) == 1, cbR = repmat(cbR,[1 1 3]); end
    h_ = cbYe-cbY+1;  w_ = cbXe-cbX+1;
    if size(cbR,3) == 4
        a  = double(cbR(1:h_,1:w_,4)) / 255;
        fg = double(cbR(1:h_,1:w_,1:3));
        bg = double(canvas(cbY:cbYe, cbX:cbXe, :));
        canvas(cbY:cbYe, cbX:cbXe, :) = uint8(a.*fg + (1-a).*bg);
    else
        canvas(cbY:cbYe, cbX:cbXe, :) = cbR(1:h_,1:w_,:);
    end
end