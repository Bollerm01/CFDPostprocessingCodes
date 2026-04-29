function import_and_plot_condensed_xlsx(varargin)
% import_and_plot_condensed_xlsx
%
% Reads multiple condensed XLSX test case files, removes duplicate y-values
% for each quantity, interpolates all data onto a common x-grid per
% quantity, and generates overlay plots.
%
% Optional name–value arguments:
%   'XLabel'       : char/string, x-axis label, default 'x (m)'
%   'LegendLabels' : cellstr/string array, overrides file names in legend
%   'TitlePrefix'  : char/string, prepended to each auto-generated title
%   'InterpMethod' : char/string, interpolation method (e.g., 'linear','pchip','spline')
%
% Example:
%   import_and_plot_condensed_xlsx(...
%       'XLabel','x / m',...
%       'LegendLabels',{'Coarse','Medium','Fine'},...
%       'TitlePrefix','Mesh Sensitivity - ',...
%       'InterpMethod','pchip');

    % --- Parse optional inputs ---
    p = inputParser;
    addParameter(p, 'XLabel', 'x (m)', @(x)ischar(x) || isstring(x));
    addParameter(p, 'LegendLabels', {}, @(x)iscellstr(x) || isstring(x));
    addParameter(p, 'TitlePrefix', '', @(x)ischar(x) || isstring(x));
    addParameter(p, 'InterpMethod', 'linear', @(x)ischar(x) || isstring(x));
    parse(p, varargin{:});

    xLabel       = char(p.Results.XLabel);
    legendLabels = p.Results.LegendLabels;
    titlePrefix  = char(p.Results.TitlePrefix);
    interpMethod = char(p.Results.InterpMethod);

    %% --- Select test case XLSX files ---
    cd("E:\Boller CFD\AVIATION CFD\MeshSensitivityData");
    [files, path] = uigetfile('*.xlsx',...
        'Select condensed XLSX test cases (test6, test8,...)',...
        'MultiSelect','on');

    if isequal(files,0)
        disp('No files selected.');
        return;
    end

    if ischar(files)
        files = {files}; % force cell array
    end

    nFiles = numel(files);

    % If custom legend labels are given, ensure length matches number of files
    if ~isempty(legendLabels)
        legendLabels = cellstr(legendLabels);
        if numel(legendLabels) ~= nFiles
            warning('Number of LegendLabels does not match number of files. Using file names instead.');
            legendLabels = {};
        end
    end

    %% --- Select output folder ---
    outFolder = uigetdir(pwd,'Select Output Folder');
    if isequal(outFolder,0)
        disp('No output folder selected.');
        return;
    end

    %% --- Line locations (sheet names) ---
    lineSheets = {'FL','CL','CTRL'};

    %% --- Quantities (data) ---
    quantitiesData = {...
        'pressureavg';...
        'velocitymagavg';...
        'velocityxavg' };

    %% --- Plotting descriptors (edit these for labels/titles/tags) ---
    quantitiesPlot = {...
        '\textbf{Pressure (Pa)}',          '\textbf{Pressure vs Axial Location}',        'pressure';...
        '\textbf{$$|\bar{V}|$$ (m/s)}',    '\textbf{$$|\bar{V}|$$ vs Axial Location}',   'velocitymag';...
        '\textbf{$$\bar{V_{x}}$$ (m/s)}',  '\textbf{$$\bar{V_{x}}$$ vs Axial Location}', 'velocityx' };

    % Basic consistency check
    if numel(quantitiesData) ~= size(quantitiesPlot,1)
        error('quantitiesData and quantitiesPlot must have the same number of entries.');
    end

    %% --- Loop over line locations ---
    for s = 1:numel(lineSheets)

        sheetName = lineSheets{s};
        fprintf('\nProcessing sheet: %s\n', sheetName);

        % Create output subfolder
        saveSub = fullfile(outFolder, sheetName);
        if ~isfolder(saveSub)
            mkdir(saveSub);
        end

        % For interpolation: store X and Q for each quantity & file
        X_raw  = cell(numel(quantitiesData), nFiles);
        Q_raw  = cell(numel(quantitiesData), nFiles);

        %% --- Read all test cases for this sheet ---
        for i = 1:nFiles
            T = readtable(fullfile(path, files{i}), 'Sheet', sheetName);

            x_full = T.X(:);  % original x for this file

            for q = 1:numel(quantitiesData)
                colName = quantitiesData{q};
                if ~ismember(colName, T.Properties.VariableNames)
                    error('Column "%s" not found in file "%s", sheet "%s".',...
                           colName, files{i}, sheetName);
                end

                % Full y for this quantity
                y_full = T.(colName)(:);

                % Remove duplicate y-values (keep first occurrence)
                [y_unique, idx_unique] = unique(y_full, 'stable');

                % Corresponding x-values for these unique y-values
                x_q = x_full(idx_unique);

                % Store
                X_raw{q,i} = x_q;
                Q_raw{q,i} = y_unique;
            end
        end

        %% --- For each quantity, build common X-grid and interpolate ---
        for q = 1:numel(quantitiesData)

            % Build common X-grid from all files for this quantity
            allX_q = [];
            for i = 1:nFiles
                allX_q = [allX_q; X_raw{q,i}(:)];
            end
            xCommon = unique(allX_q);   % sorted union for this quantity

            X_interp   = xCommon;
            Q_interp_q = cell(1, nFiles);

            % Interpolate this quantity for all files onto xCommon
            for i = 1:nFiles
                x_i = X_raw{q,i};
                y_i = Q_raw{q,i};

                % --- Ensure x_i is unique and sorted for interp1 ---
                [x_unique, idx_unique_x] = unique(x_i);
                y_unique = y_i(idx_unique_x);

                % Sort by x to guarantee monotonic x for interpolation
                [x_unique, sortIdx] = sort(x_unique);
                y_unique = y_unique(sortIdx);

                % Handle edge case: need at least 2 points to interpolate
                if numel(x_unique) < 2
                    Q_interp_q{i} = NaN(size(X_interp));
                else
                    % Interpolate using selected method and EXTRAPOLATE
                    Q_interp_q{i} = interp1(x_unique, y_unique, X_interp, interpMethod, 'extrap');
                end
            end

            % Title formatting 
            switch sheetName
                case 'CL'
                    sheetTitle = 'Ceiling Line';
                case 'CTRL'
                    sheetTitle = 'Centerline';
                case 'FL'
                    sheetTitle = 'Floor Line';
            end

            % Build title: optional prefix + base title + (sheet)
            baseTitle    = quantitiesPlot{q,2};
            defaultTitle = sprintf('%s (%s)', baseTitle, sheetTitle);
            fullTitle    = [titlePrefix, defaultTitle];

            % Decide on legend text: custom or from file names
            if isempty(legendLabels)
                legText = files;
            else
                legText = legendLabels;
            end

            yLabel = quantitiesPlot{q,1};
            tag    = quantitiesPlot{q,3};

            % Generate and save plot for this quantity and sheet
            save_overlay_x(...
                X_interp, Q_interp_q, legText, saveSub,...
                yLabel, fullTitle, tag, xLabel);
        end

        fprintf('Sheet "%s" completed.\n', sheetName);
    end

    cd("E:\Boller CFD\GitHub\CFDPostprocessingCodes\TimeMeshSensitivityVolcanoSSWT");
    disp('=============================================');
    disp('All line locations processed. Plots saved.');
    disp('=============================================');

end


function save_overlay_x(xCommon, yData, legendText, saveFolder, yLabel, titleText, tag, xLabel)
% save_overlay_x
%   Plots multiple curves y(xCommon) on a single figure, fills any NaN
%   gaps by interpolation, adds black construction lines with aspect ratio
%   scaled to the y-range, and saves the figure.
%
% Inputs:
%   xCommon   : column vector of common x-locations
%   yData     : 1 x nFiles cell array, each cell is a vector same size as xCommon
%   legendText: cell array of legend entries
%   saveFolder: folder to save outputs
%   yLabel    : y-axis label (can contain LaTeX)
%   titleText : plot title (can contain LaTeX)
%   tag       : base filename tag (no extension)
%   xLabel    : x-axis label (plain text or LaTeX; here we use 'none' interpreter)

    % --- Fill NaN gaps in each curve by interpolation over valid points ---
    for k = 1:numel(yData)
        yk = yData{k};
        if ~isvector(yk) || numel(yk) ~= numel(xCommon)
            error('Each yData{k} must be a vector of same length as xCommon.');
        end

        nanMask = isnan(yk);
        if any(nanMask)
            validMask = ~nanMask;
            if sum(validMask) >= 2
                % Interpolate over valid (x,y) to fill NaNs; extrapolate if needed
                yk_filled = interp1(xCommon(validMask), yk(validMask), xCommon, 'linear', 'extrap');
                yData{k}  = yk_filled;
            end
        end
    end

    % --- Compute min and max y across all series (after filling) ---
    allY = [];
    for k = 1:numel(yData)
        allY = [allY; yData{k}(:)];
    end
    yMin = min(allY, [], 'omitnan');
    yMax = max(allY, [], 'omitnan');

    if isempty(yMin) || isnan(yMin)
        yMin = 0;
    end
    if isempty(yMax) || isnan(yMax)
        yMax = yMin + 1; % arbitrary non-zero range if degenerate
    end

    % y-range (for aspect-ratio scaling)
    yRange = yMax - yMin;
    if yRange <= 0
        yRange = max(abs(yMin), 1); % fallback if nearly flat
    end

    % Define 20% and 25% below the minimum as fractions of the y-range
    y20 = yMin - 0.20 * yRange;
    y25 = yMin - 0.25 * yRange;

    % --- Plot data ---
    fig = figure('Visible','on');
    hold on; grid on; box on;
    set(fig, 'Color','w');

    % Reasonable figure size (prevents crowding with outside legend)
    set(fig, 'Units','pixels', 'Position',[100 100 900 700]);

    % Axes and font sizes
    ax = gca;
    ax.FontSize      = 14;  % tick labels
    labelFontSize    = 18;  % axis labels
    titleFontSize    = 20;  % title
    legendFontSize   = 14;  % legend

    % IMPORTANT: turn off axis exponent so it doesn't overlap with title
    % (especially for pressure)
    if isprop(ax, 'YAxis')
        ax.YAxis.Exponent = 0;
    else
        ax.YRuler.Exponent = 0;  % for older MATLAB versions
    end

    % Plot data curves
    for k = 1:numel(yData)
        plot(xCommon, yData{k}, 'LineWidth', 2);
    end

    % --- Draw construction lines (solid black) ---
    plot([2.04 2.15], [y20 y20], 'k-', 'LineWidth', 1.5);
    plot([2.15 2.15], [y20 y25], 'k-', 'LineWidth', 1.5);
    plot([2.15 2.195], [y25 y25], 'k-', 'LineWidth', 1.5);
    plot([2.195 2.24], [y25 y20], 'k-', 'LineWidth', 1.5);
    plot([2.24 2.55], [y20 y20], 'k-', 'LineWidth', 1.5);

    % --- Labels, title, legend ---
    xlabel(xLabel,  'Interpreter','none',  'FontSize', labelFontSize);
    ylabel(yLabel,  'Interpreter','latex', 'FontSize', labelFontSize);

    % Let MATLAB place the title; don't manually move it
    title(titleText, 'Interpreter','latex', 'FontSize', titleFontSize);

    % Centered legend at bottom, outside, with 3 columns
    lgd = legend(legendText,...
                 'Interpreter','none',...
                 'Location','southoutside',...
                 'Orientation','horizontal');
    set(lgd, 'FontSize', legendFontSize,...
             'NumColumns', 3);

    % Give MATLAB room to fit axes + legend nicely
    set(ax, 'LooseInset', max(get(ax, 'TightInset'), 0.02));

    % --- Save outputs (use exportgraphics for all, to avoid clipping) ---
    figPathFIG = fullfile(saveFolder, sprintf('%s.fig', tag));
    figPathPDF = fullfile(saveFolder, sprintf('%s.pdf', tag));
    figPathJPG = fullfile(saveFolder, sprintf('%s.jpg', tag));

    savefig(fig, figPathFIG);  % FIG

    exportgraphics(fig, figPathPDF,...
        'ContentType','vector');              % PDF (vector)

    exportgraphics(fig, figPathJPG,...
        'ContentType','image',...
        'Resolution',300);                    % JPEG (raster, 300 dpi)

    close(fig);
end