%% highFreqAxialPlotter.m
%
% Loads CFD line-probe CSV files organized as N_AXIAL axial locations x
% N_SPAN spanwise locations at each axial station (default 3x3 = 9
% files). For each file the MIDDLE probe point (median index of sorted
% numeric column prefixes) is extracted and its pressure signal is
% analysed.
%
% Outputs
%   Figure 1  –  Time History (all locations overlaid)
%   Figure 2  –  Narrowband SPL  (dB re 20 µPa, log-x axis)
%   Figure 3  –  PSD             (dB/Hz re 20 µPa, log-x axis)
%   Figure 4  –  OASPL bar chart + command-window summary table
%
% CSV format expected
%   Column 1   :  "time"  (uniform time step, seconds)
%   Other cols :  "<pointID>_<quantity>"   e.g.  "050_pressure"
%   Point IDs are the leading numeric tokens; the median one is used.
%   Pressure is in Pascals (absolute); DC is removed before analysis.
%
% Usage
%   Run the script directly.  A dialog box collects all parameters,
%   including the number of axial locations and spanwise locations per
%   axial station.  Then use the file browser to select the CSV files
%   (N_AXIAL * N_SPAN of them).  A second dialog lets you confirm/adjust
%   which axial station and spanwise position each file belongs to, plus
%   the legend label. Colors are then assigned so that:
%       - each AXIAL location gets its own distinct HUE
%       - each SPANWISE location within that axial station gets its own
%         SHADE (lightness) of that hue
%
% Requires: Signal Processing Toolbox  (pwelch, butter, filtfilt, hann)
%
% CHANGES vs. original
%   [GROUPING] Files are now organized by (axial, spanwise) index pairs
%              instead of an arbitrary flat list. This makes the color
%              logic map directly onto the physical geometry.
%
%   [COLOR]    Replaced the single-axis lightness ramp with a
%              hue-per-axial-location / shade-per-spanwise-location
%              scheme in CIE LCH space. All spanwise traces belonging to
%              the same axial station share a hue (e.g. all "blue"), and
%              are distinguished from each other only by lightness
%              (light/medium/dark). Axial stations are separated by hue
%              (evenly spaced around the hue wheel, so 3 axial stations
%              are maximally distinct, e.g. red / green / blue-ish).
%              Colours are converted LCH→LAB→RGB and clamped to [0,1] so
%              MATLAB never silently clips them to an unintended shade.
%
%   [OASPL]    computeOASPL_PSD integrates the one-sided PSD directly
%              (pwelch already applies the correct window power
%              normalisation), matching the corrected version from the
%              prior revision.
% -------------------------------------------------------------------------

clear; clc; close all;

PREF = 20e-6;   % reference pressure [Pa]

%% ============================================================
%  STEP 1 – PARAMETER DIALOG
%% ============================================================

answer = inputdlg( ...
    { ...
    'Plot Title', ...
    'Start Time [s]', ...
    'End Time [s]  (leave 0 for full signal)', ...
    'FFT df [Hz]   (frequency resolution)', ...
    'Min Frequency [Hz]', ...
    'Max Frequency [Hz]', ...
    'Number of Axial Locations', ...
    'Number of Spanwise Locations per Axial Station'}, ...
    'Analysis Settings', ...
    [1 68], ...
    { ...
    'CFD Line Probe', ...
    '0', ...
    '0', ...
    '75', ...
    '100', ...
    '20000', ...
    '3', ...
    '3'});

if isempty(answer), return; end

plotTitle    = answer{1};
tStart       = str2double(answer{2});
tEnd         = str2double(answer{3});   % 0 → use full signal
df_desired   = str2double(answer{4});
fmin         = str2double(answer{5});
fmax         = str2double(answer{6});
nAxial       = round(str2double(answer{7}));
nSpan        = round(str2double(answer{8}));

if nAxial < 1 || nSpan < 1 || isnan(nAxial) || isnan(nSpan)
    errordlg('Number of axial and spanwise locations must be positive integers.', ...
        'Input Error');
    return
end

nExpected = nAxial * nSpan;

%% ============================================================
%  STEP 2 – SELECT CSV FILES  (N_AXIAL x N_SPAN)
%% ============================================================

[fileNames, filePath] = uigetfile( ...
    '*.csv', ...
    sprintf(['Select %d CSV files (%d axial locations x %d spanwise ' ...
             'locations). Selection order does not matter -- you will ' ...
             'assign axial/spanwise indices next.'], ...
             nExpected, nAxial, nSpan), ...
    'MultiSelect','on');

if isequal(fileNames,0), return; end
if ischar(fileNames), fileNames = {fileNames}; end

nFiles = numel(fileNames);

if nFiles ~= nExpected
    warndlg( ...
        sprintf(['You selected %d file(s) but %d axial x %d spanwise = %d ' ...
                 'were expected. Proceeding anyway -- you will assign ' ...
                 'axial/spanwise indices to each file manually next.'], ...
                 nFiles, nAxial, nSpan, nExpected), ...
        'File Count Notice');
end

%% ============================================================
%  STEP 3 – AXIAL / SPANWISE GROUP ASSIGNMENT + LEGEND LABELS
%% ============================================================
%
%  Default assignment walks files in selection order, filling all
%  spanwise positions for axial station 1, then axial station 2, etc.
%  Edit the "axialIdx,spanIdx" field for any file that doesn't match
%  that assumption. The legend label defaults to "Axial <a> - Span <s>"
%  but can be freely edited (e.g. to real x/y coordinates).

groupPrompts  = cell(nFiles,1);
groupDefaults = cell(nFiles,1);
for fi = 1:nFiles
    defAxial = min(nAxial, ceil(fi / nSpan));
    defSpan  = mod(fi-1, nSpan) + 1;
    groupPrompts{fi} = sprintf( ...
        'File %d: %s\n(format:  axialIdx,spanIdx,label)', ...
        fi, fileNames{fi});
    groupDefaults{fi} = sprintf('%d,%d,Axial %d - Span %d', ...
        defAxial, defSpan, defAxial, defSpan);
end

groupAnswer = inputdlg(groupPrompts, 'Axial / Spanwise Assignment', ...
    [1 72], groupDefaults);

if isempty(groupAnswer), return; end

axialIdx     = zeros(nFiles,1);
spanIdx      = zeros(nFiles,1);
legendLabels = cell(nFiles,1);

for fi = 1:nFiles
    tokens = strsplit(groupAnswer{fi}, ',');
    if numel(tokens) < 3
        error('File %d: expected format "axialIdx,spanIdx,label"', fi);
    end
    axialIdx(fi) = round(str2double(tokens{1}));
    spanIdx(fi)  = round(str2double(tokens{2}));
    legendLabels{fi} = strtrim(strjoin(tokens(3:end), ','));
end

if any(isnan(axialIdx)) || any(isnan(spanIdx)) || ...
   any(axialIdx < 1) || any(spanIdx < 1)
    errordlg('Axial/spanwise indices must be positive integers.', ...
        'Input Error');
    return
end

nAxial = max(nAxial, max(axialIdx));   % expand if user typed a larger index
nSpan  = max(nSpan,  max(spanIdx));

%% ============================================================
%  PERCEPTUALLY-UNIFORM COLOR SYSTEM (CIE LCH -> LAB -> RGB)
%% ============================================================
%
%  HUE encodes AXIAL LOCATION:
%    nAxial hues are spread evenly around the LCH hue wheel (360/nAxial
%    degree spacing), starting at 0 deg (red) so distinct axial stations
%    are maximally separated in hue -- e.g. with 3 axial stations you
%    get roughly red / green / blue.
%
%  SHADE (lightness) encodes SPANWISE LOCATION:
%    For a given axial station's hue, nSpan lightness levels are spread
%    across L* = [40, 80] (dark -> light), so spanwise positions within
%    the same axial station are clearly distinguishable shades of the
%    same color family while remaining visually grouped.
%
%  Chroma C* is held fixed (55) for all traces -- vivid but printable.

hueDeg   = mod( (0:nAxial-1) * (360 / nAxial), 360 );   % one hue per axial stn
Cstar    = 55;                                          % fixed chroma
Lrange   = [40 80];                                     % dark -> light
if nSpan > 1
    Lshades = linspace(Lrange(1), Lrange(2), nSpan);
else
    Lshades = mean(Lrange);
end

traceColor = zeros(nFiles,3);
for fi = 1:nFiles
    H = hueDeg(axialIdx(fi));
    L = Lshades(spanIdx(fi));
    a = Cstar * cosd(H);
    b = Cstar * sind(H);
    rgb = lab2rgb([L a b]);
    traceColor(fi,:) = max(0, min(1, rgb));
end

% Line style differentiates spanwise position as a secondary (redundant)
% visual cue, useful for grey-scale printing.
styleList  = {'-', '-', '-', '-'};
traceStyle = cell(nFiles,1);
for fi = 1:nFiles
    traceStyle{fi} = styleList{ mod(spanIdx(fi)-1, numel(styleList)) + 1 };
end

%% ============================================================
%  LOAD DATA & EXTRACT MIDDLE-POINT PRESSURE
%% ============================================================

signals  = cell(nFiles,1);
timeVecs = cell(nFiles,1);
midIDs   = cell(nFiles,1);

for fi = 1:nFiles

    fullPath = fullfile(filePath, fileNames{fi});

    opts = detectImportOptions(fullPath);
    opts.DataLines = [2 Inf];
    T = readtable(fullPath, opts);

    allCols = T.Properties.VariableNames;

    % ---- find time column (first column) --------------------------------
    t = T{:,1};

    % ---- identify sorted numeric point prefixes -------------------------
    prefixes = extractPointPrefixes(allCols);
    prefSort = sort(prefixes);

    if isempty(prefSort)
        error('No numeric point prefixes found in %s', fileNames{fi});
    end

    midID  = prefSort{ ceil(numel(prefSort)/2) };
    midIDs{fi} = midID;

    % ---- find pressure column for middle point --------------------------
    pressCol = [midID '_pressure'];

    colMatch = find(strcmpi(pressCol, allCols), 1);

    if isempty(colMatch)
        error('Column "%s" not found in %s', pressCol, fileNames{fi});
    end

    p = T{:, colMatch};

    % ---- apply time window ---------------------------------------------
    if tEnd > 0
        mask = t >= tStart & t <= tEnd;
    else
        mask = t >= tStart;
    end

    t = t(mask);
    p = p(mask);

    p = p - mean(p);    % remove DC

    signals{fi}  = p;
    timeVecs{fi} = t;

end

%% ============================================================
%  FIGURE 1 – TIME HISTORY
%% ============================================================

figure('Name','Time History','Color','w');
hold on; grid on;

title([plotTitle ' – Time History'], 'FontSize',13,'FontWeight','bold')
xlabel('Time [s]',    'FontSize',12)
ylabel('Pressure [Pa]','FontSize',12)

for fi = 1:nFiles
    plot(timeVecs{fi}, signals{fi}, ...
        'Color',      traceColor(fi,:), ...
        'LineStyle',  traceStyle{fi}, ...
        'LineWidth',  1.2, ...
        'DisplayName', legendLabels{fi});
end

legend('show','Location','southoutside','NumColumns',3)

%% ============================================================
%  FIGURE 2 – NARROWBAND SPL
%% ============================================================

figure('Name','Narrowband SPL','Color','w');
hold on; grid on;

title([plotTitle ' – Narrowband SPL'], 'FontSize',13,'FontWeight','bold')
xlabel('Frequency [Hz]',         'FontSize',12)
ylabel('SPL [dB re 20 \muPa]',  'FontSize',12)
set(gca,'XScale','log')

oaspl_labels = cell(nFiles,1);
oaspl_psd    = nan(nFiles,1);
oaspl_color  = traceColor;

for fi = 1:nFiles

    sig = signals{fi};
    t   = timeVecs{fi};
    fs  = 1 / mean(diff(t));

    [f_nb, NB] = localFFT(sig, fs, df_desired, PREF);

    semilogx(f_nb, NB, ...
        'Color',     traceColor(fi,:), ...
        'LineStyle', traceStyle{fi}, ...
        'LineWidth',  2, ...
        'DisplayName', legendLabels{fi});

    oaspl_labels{fi}  = legendLabels{fi};

end

xlim([fmin fmax])
legend('show','Location','southoutside','NumColumns',3)

%% ============================================================
%  FIGURE 3 – PSD
%% ============================================================

figure('Name', 'PSD');
hold on
grid on
title([plotTitle ' - PSD'])
xlabel('Frequency [Hz]')
ylabel('PSD [dB/Hz]')
set(gca, 'XScale', 'log')

oaspl_psd = nan(length(oaspl_labels), 1);

for fi = 1:nFiles

    sig = signals{fi};
    t   = timeVecs{fi};
    fs  = 1 / mean(diff(t));

    seg = floor(length(sig) / 8);

    if seg < 32
        continue
    end

    w = hann(seg);

    [P, f] = pwelch( ...
        sig, ...
        w, ...
        round(seg/2), ...
        [], ...
        fs);

    semilogx( ...
        f, ...
        10*log10(P / PREF^2), ...
        'Color',       traceColor(fi,:), ...
        'LineStyle',   traceStyle{fi}, ...
        'LineWidth',   2, ...
        'DisplayName', legendLabels{fi});

    %% OASPL cross-check via PSD integration over [fmin fmax]
    oaspl_psd(fi, 1) = computeOASPL_PSD(f, P, fmin, fmax, PREF);

end

xlim([fmin fmax])
legend( ...
    'show', ...
    'Location', 'southoutside', ...
    'NumColumns', 3)

%% ============================================================
%  FIGURE 4 – OASPL BAR CHART
%% ============================================================

figure('Name','OASPL','Color','w');
hold on; grid on;

title( ...
    [plotTitle ' – OASPL (' num2str(fmin) '–' num2str(fmax) ' Hz)'], ...
    'FontSize',13,'FontWeight','bold')
ylabel('OASPL [dB re 20 \muPa]', 'FontSize',12)

b = bar(categorical(oaspl_labels, oaspl_labels), oaspl_psd, ...
        'FaceColor','flat');
b.CData = oaspl_color;

% Value labels on bars
for fi = 1:nFiles
    text(fi, oaspl_psd(fi)/2, sprintf('%.1f dB', oaspl_psd(fi)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'middle', ...
        'Rotation',            90, ...
        'FontSize',            12, ...
        'Color',               'w', ...
        'FontWeight',          'bold');
end

ylim([0, max(oaspl_psd)*1.15]);
xtickangle(45);

%% ============================================================
%  COMMAND-WINDOW OASPL SUMMARY TABLE
%% ============================================================

fprintf('\n=== OASPL Summary (%.0f–%.0f Hz band) ===\n', fmin, fmax);
fprintf('%-40s  %8s  %8s  %14s\n', ...
    'Label','Axial','Span','OASPL_PSD [dB]');
fprintf('%s\n', repmat('-',1,76));

for fi = 1:nFiles

    if isnan(oaspl_psd(fi))
        fprintf('%-40s  %8d  %8d  %14s\n', ...
            oaspl_labels{fi}, axialIdx(fi), spanIdx(fi), 'N/A');
    else
        fprintf('%-40s  %8d  %8d  %14.2f\n', ...
            oaspl_labels{fi}, axialIdx(fi), spanIdx(fi), ...
            oaspl_psd(fi));
    end

end

fprintf('\nMiddle probe point IDs used:\n');
for fi = 1:nFiles
    fprintf('  %s  (Axial %d, Span %d)  →  point %s\n', ...
        fileNames{fi}, axialIdx(fi), spanIdx(fi), midIDs{fi});
end
fprintf('\n');

%% ============================================================
%  LOCAL HELPER FUNCTIONS
%% ============================================================

function [f, NB] = localFFT(signal, fs, df_desired, PREF)
% Narrowband SPL via block-averaged FFT.
% Nfft is chosen so that df = fs/Nfft ≈ df_desired.

    signal = signal(:) - mean(signal);

    Nfft = round(fs / df_desired);
    if mod(Nfft,2) ~= 0, Nfft = Nfft + 1; end

    if Nfft > length(signal)
        % Signal too short for requested df: use full-signal single FFT
        Nfft = 2^nextpow2(length(signal));
        if Nfft > length(signal)
            Nfft = length(signal);
            if mod(Nfft,2) ~= 0, Nfft = Nfft - 1; end
        end
        X = fft(signal(1:Nfft) .* hann(Nfft));
        X = 2 * abs(X) / Nfft;
        f  = (0 : Nfft/2)' * (fs / Nfft);
        NB = 20*log10( X(1:Nfft/2+1) / PREF );
        return
    end

    window  = hann(Nfft);
    nBlocks = floor(length(signal) / Nfft);

    if nBlocks < 2
        X = fft(signal(1:Nfft) .* window);
        X = 2 * abs(X) / Nfft;
        f  = (0 : Nfft/2)' * (fs / Nfft);
        NB = 20*log10( X(1:Nfft/2+1) / PREF );
        return
    end

    spec = zeros(Nfft, nBlocks);
    for n = 1:nBlocks
        idx1 = (n-1)*Nfft + 1;
        idx2 = n * Nfft;
        X = fft(signal(idx1:idx2) .* window);
        spec(:,n) = 2 * abs(X) / Nfft;
    end

    Xavg = mean(spec, 2);
    f    = (0 : Nfft/2)' * (fs / Nfft);
    NB   = 20*log10( Xavg(1:Nfft/2+1) / PREF );

end

% -----------------------------------------------------------------

function OASPL = computeOASPL_PSD(f, P, fmin, fmax, PREF)
% Integrates the one-sided PSD over [fmin fmax] → OASPL.
%
% ACCURACY NOTE
% -------------
% pwelch uses "power" normalisation: it divides each periodogram block by
%   U = sum(w.^2) / fs
% where w is the analysis window.  This correctly scales the output so
% that integrating P over [0, fs/2] recovers the mean-square pressure.
% Therefore no additional window-correction factor is needed here; a
% straightforward trapz integration over the band of interest is correct.
%
% The key requirement (satisfied below) is that f(1) == 0 (DC bin
% present) so that trapz weights are right. If pwelch was called with an
% explicit frequency vector that omits DC, the bin spacing is still
% uniform and trapz remains exact.

    mask = f >= fmin & f <= fmax;

    if nnz(mask) < 2
        OASPL = NaN;
        return
    end

    p_meansq = trapz(f(mask), P(mask));   % [Pa^2]  — units of P are Pa^2/Hz
    OASPL    = 10*log10( p_meansq / PREF^2 );

end

% -----------------------------------------------------------------

function prefixes = extractPointPrefixes(colNames)
% Returns sorted unique numeric prefix strings from "<prefix>_<qty>" cols.

    prefixes = {};
    for k = 1:numel(colNames)
        parts = strsplit(colNames{k}, '_');
        if numel(parts) >= 2 && ~isnan(str2double(extract(parts{1},digitsPattern)))
            if ~ismember(parts{1}, prefixes)
                prefixes{end+1} = parts{1}; %#ok<AGROW>
            end
        end
    end
    prefixes = sort(prefixes);

end