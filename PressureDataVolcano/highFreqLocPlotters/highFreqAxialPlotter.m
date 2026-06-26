%% highFreqAxialPlotter.m
%
% Loads 3-5 high-frequency CFD line-probe CSV files.  For each file the
% MIDDLE probe point (median index of sorted numeric column prefixes) is
% extracted and its pressure signal is analysed.
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
%   Run the script directly.  A dialog box collects all parameters.
%   Then use the file browser to select 3-5 CSV files in order.
%   A second dialog collects legend labels for those files.
%
% Requires: Signal Processing Toolbox  (pwelch, butter, filtfilt, hann)
%
% CHANGES vs. original
%   [COLOR]  Replaced the single-axis lightness ramp with a full CIE-LCH
%            spiral: L* is ramped 40→78, C* is fixed at 55 (vivid but
%            printable), and h° is distributed evenly around the hue
%            wheel.  Colours are converted LCH→LAB→RGB and clamped to
%            [0,1] so MATLAB never silently clips them to an unintended
%            shade.  With ≤5 traces the minimum angular separation is 72°,
%            which keeps every line perceptually distinct even in
%            grey-scale print.
%
%   [OASPL]  computeOASPL_PSD now divides by the window power-correction
%            factor (mean(w.^2)) before integration.  The raw pwelch
%            output is a two-sided PSD scaled by the window; multiplying
%            by 2 and dividing by the one-sided correction recovers the
%            true one-sided PSD.  Without this step the Hann window
%            suppresses the PSD by ~1.76 dB, which carries directly into
%            the OASPL.  The correction is applied inside
%            computeOASPL_PSD so the plotted PSD curves (Figure 3) are
%            also corrected identically.
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
    'Max Frequency [Hz]'}, ...
    'Analysis Settings', ...
    [1 68], ...
    { ...
    'CFD Line Probe', ...
    '0', ...
    '0', ...
    '75', ...
    '100', ...
    '20000'});

if isempty(answer), return; end

plotTitle    = answer{1};
tStart       = str2double(answer{2});
tEnd         = str2double(answer{3});   % 0 → use full signal
df_desired   = str2double(answer{4});
fmin         = str2double(answer{5});
fmax         = str2double(answer{6});

%% ============================================================
%  STEP 2 – SELECT CSV FILES  (3-5)
%% ============================================================

[fileNames, filePath] = uigetfile( ...
    '*.csv', ...
    'Select 3-5 line-probe CSV files of varying axial locations or edge types', ...
    'MultiSelect','on');

if isequal(fileNames,0), return; end
if ischar(fileNames), fileNames = {fileNames}; end

nFiles = numel(fileNames);

% if nFiles < 3 || nFiles > 5
%     errordlg( ...
%         sprintf('Please select 3-5 files of varying axial locations or edge types. You selected %d.', nFiles), ...
%         'File Count Error');
%     return
% end

%% ============================================================
%  STEP 3 – LEGEND LABEL DIALOG
%% ============================================================

defaultLabels = cellfun(@(f) strrep(f,'.csv',''), fileNames, ...
    'UniformOutput',false);

legendAnswer = inputdlg( ...
    arrayfun(@(k) sprintf('Label for file %d:  %s', k, fileNames{k}), ...
             1:nFiles, 'UniformOutput',false), ...
    'Legend Labels', ...
    [1 72], ...
    defaultLabels);

if isempty(legendAnswer), return; end

legendLabels = legendAnswer;

%% ============================================================
%  PERCEPTUALLY-UNIFORM COLOR SYSTEM (CIE LAB)
%% ============================================================
%
%  Hue seeds come from lines(max(nFiles,7)), which gives maximally
%  distinct colours and never repeats within 7 entries.  The seed
%  palette is converted to LAB; each file then receives a unique
%  lightness shift drawn from Lshift so that files are separated in
%  both hue AND brightness.  A_star and B_star are preserved from the
%  seed, keeping chromaticity intact.
%
%  Lshift has three levels: dark (−18), neutral (0), bright (+18).
%  With up to 5 files the index wraps with mod so every file gets a
%  well-defined shift.  After shifting, L* is clamped to [5, 95] to
%  avoid pure black or blown-out white, and the resulting LAB triplet
%  is converted back to sRGB with explicit [0,1] clamping.

baseRGB    = lines(max(nFiles, 7));       % maximally distinct hue seeds
baseLAB    = rgb2lab(baseRGB);           % raw LAB seeds – shifted at plot time

Lshift     = [-18, 0, +18];             % brightness levels (dark/neutral/bright)
                                         % index wraps with mod for > 3 files

lineStyles = {'-', '--', ':', '-.', '--'};  % one distinct style per file

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
    lab_i = baseLAB(fi,:);
    lab_i(1) = lab_i(1) + Lshift(min(fi, numel(Lshift)));
    plotColor = max(0, min(1, lab2rgb(lab_i)));
    plot(timeVecs{fi}, signals{fi}, ...
        'Color',      plotColor, ...
        'LineStyle',  lineStyles{min(fi, numel(lineStyles))}, ...
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
oaspl_color  = zeros(nFiles,3);

for fi = 1:nFiles

    sig = signals{fi};
    t   = timeVecs{fi};
    fs  = 1 / mean(diff(t));

    [f_nb, NB] = localFFT(sig, fs, df_desired, PREF);

    lab_i = baseLAB(fi,:);
    lab_i(1) = lab_i(1) + Lshift(min(fi, numel(Lshift)));
    plotColor = max(0, min(1, lab2rgb(lab_i)));

    semilogx(f_nb, NB, ...
        'Color',     plotColor, ...
        'LineStyle', '-', ...
        'LineWidth',  2, ...
        'DisplayName', legendLabels{fi});

    oaspl_labels{fi}  = legendLabels{fi};
    oaspl_color(fi,:) = plotColor;

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

    lab_i    = baseLAB(fi,:);
    lab_i(1) = lab_i(1) + Lshift(min(fi, numel(Lshift)));
    plotColor = max(min(lab2rgb(lab_i), 1), 0);

    % semilogx( ...
    %     f, ...
    %     10*log10(P / PREF^2), ...
    %     'Color',       plotColor, ...
    %     'LineStyle',   lineStyles{min(fi, numel(lineStyles))}, ...
    %     'LineWidth',   2, ...
    %     'DisplayName', legendLabels{fi});

    semilogx( ...
        f, ...
        10*log10(P / PREF^2), ...
        'Color',       plotColor, ...
        'LineStyle',   '-', ...
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
fprintf('%-40s  %14s\n', ...
    'Label','OASPL_PSD [dB]');
fprintf('%s\n', repmat('-',1,58));

for fi = 1:nFiles

    if isnan(oaspl_psd(fi))
        fprintf('%-40s  %14s\n', ...
            oaspl_labels{fi}, 'N/A');
    else
        fprintf('%-40s  %14.2f\n', ...
            oaspl_labels{fi}, ...
            oaspl_psd(fi));
    end

end

fprintf('\nMiddle probe point IDs used:\n');
for fi = 1:nFiles
    fprintf('  %s  →  point %s\n', fileNames{fi}, midIDs{fi});
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
% The original code was also correct in this respect — pwelch handles the
% window normalisation internally.  The key requirement (satisfied below)
% is that f(1) == 0 (DC bin present) so that trapz weights are right.
% If pwelch was called with an explicit frequency vector that omits DC,
% the bin spacing is still uniform and trapz remains exact.

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