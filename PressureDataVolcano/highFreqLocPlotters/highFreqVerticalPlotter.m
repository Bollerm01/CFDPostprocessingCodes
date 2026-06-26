%% highFreqVerticalPlotter.m
%
% Loads a single high-frequency CFD line-probe CSV file and overlays
% 3-5 selected probe points for comparison.
%
% Outputs
%   Figure 1  –  Time History (all probes overlaid)
%   Figure 2  –  Narrowband SPL  (dB re 20 µPa, log-x axis)
%   Figure 3  –  PSD             (dB/Hz re 20 µPa, log-x axis)
%   Figure 4  –  OASPL bar chart + command-window summary table
%
% CSV format expected
%   Column 1   :  "time"  (uniform time step, seconds)
%   Other cols :  "<pointID>_<quantity>"   e.g.  "050_pressure"
%   Point IDs are the leading numeric tokens; 3-5 are selected by the user.
%   Pressure is in Pascals (absolute); DC is removed before analysis.
%
% Usage
%   Run the script directly.  A dialog box collects all parameters.
%   Then use the file browser to select a single CSV file.
%   A second dialog lets you choose which probe points to analyse.
%
% Requires: Signal Processing Toolbox  (pwelch, butter, filtfilt, hann)
%
% CHANGES vs. original
%   [COLOR]  Replaced linspace Lshift ramp + getColor helper with the
%            shared color pattern: lines(max(nProbes,7)) seeds baseLAB;
%            Lshift = [-18 0 +18] is indexed per probe (wrapping with mod)
%            and applied inline at each plot call.  lineStyles cycles
%            through four dash patterns for an additional visual dimension.
%            Explicit [0,1] clamp after lab2rgb prevents silent clipping.
%
%   [PSD]    Section restructured to match the axial plotter reference
%            style: oaspl_psd reinitialised at section top, pwelch args
%            formatted one-per-line, color resolved inline via baseLAB +
%            Lshift, lineStyles applied, oaspl_psd indexed as (pi,1).
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
%  STEP 2 – SELECT SINGLE CSV FILE
%% ============================================================

[fileName, filePath] = uigetfile( ...
    '*.csv', ...
    'Select a single line-probe CSV file');

if isequal(fileName, 0), return; end

fullPath = fullfile(filePath, fileName);

%% ============================================================
%  STEP 3 – LOAD FILE & DISCOVER PROBE POINTS
%% ============================================================

opts = detectImportOptions(fullPath);
opts.DataLines = [2 Inf];
T = readtable(fullPath, opts);

allCols  = T.Properties.VariableNames;
t_full   = T{:,1};

% Find all unique numeric point prefixes
allPrefixes = extractPointPrefixes(allCols);

if numel(allPrefixes) < 3
    errordlg( ...
        sprintf('File contains only %d probe point(s). At least 3 are required.', ...
                numel(allPrefixes)), ...
        'Insufficient Probes');
    return
end

fprintf('Found %d probe points in %s:\n', numel(allPrefixes), fileName);
fprintf('  %s\n', allPrefixes{:});

%% ============================================================
%  STEP 4 – PROBE SELECTION DIALOG
%% ============================================================

[selIdx, ok] = listdlg( ...
    'ListString',    allPrefixes, ...
    'SelectionMode', 'multiple', ...
    'PromptString',  'Select 3 to 5 probe points to overlay:', ...
    'ListSize',      [260 200], ...
    'Name',          'Probe Selection');

if ~ok || isempty(selIdx), return; end

nProbes = numel(selIdx);

if nProbes < 3 || nProbes > 5
    errordlg( ...
        sprintf('Please select 3–5 probe points. You selected %d.', nProbes), ...
        'Selection Count Error');
    return
end

selectedPrefixes = allPrefixes(selIdx);

%% ============================================================
%  STEP 5 – LEGEND LABEL DIALOG
%% ============================================================

legendAnswer = inputdlg( ...
    arrayfun(@(k) sprintf('Label for probe point  "%s":', selectedPrefixes{k}), ...
             1:nProbes, 'UniformOutput', false), ...
    'Legend Labels', ...
    [1 72], ...
    selectedPrefixes);

if isempty(legendAnswer), return; end

legendLabels = legendAnswer;

%% ============================================================
%  PERCEPTUALLY-UNIFORM COLOR SYSTEM (CIE LAB)
%% ============================================================
%
%  Matches the axial plotter: lines(max(nProbes,7)) provides maximally
%  distinct hue seeds; baseLAB holds the raw LAB values which are shifted
%  at each plot call.  Lshift cycles through three brightness levels
%  (dark/neutral/bright) via mod indexing.  lineStyles adds a fourth
%  visual dimension for greyscale legibility.  Explicit [0,1] clamp after
%  lab2rgb prevents silent clipping in all MATLAB versions.

baseRGB    = lines(max(nProbes, 7));      % maximally distinct hue seeds
baseLAB    = rgb2lab(baseRGB);           % raw LAB seeds – shifted at plot time

Lshift     = [-18, 0, +18];             % brightness levels (dark/neutral/bright)
                                         % index cycles with mod for > 3 probes

lineStyles = {'-', '--', ':', '-.', '--'};  % one distinct style per probe

%% ============================================================
%  STEP 6 – EXTRACT SIGNALS FOR EACH SELECTED PROBE
%% ============================================================

% Apply time window to the shared time vector first
if tEnd > 0
    mask = t_full >= tStart & t_full <= tEnd;
else
    mask = t_full >= tStart;
end

t = t_full(mask);

signals = cell(nProbes, 1);

for pi = 1:nProbes

    pressCol = [selectedPrefixes{pi} '_pressure'];
    colMatch = find(strcmpi(pressCol, allCols), 1);

    if isempty(colMatch)
        error('Column "%s" not found in %s.\nAvailable columns:\n  %s', ...
              pressCol, fileName, strjoin(allCols, '\n  '));
    end

    p = T{mask, colMatch};
    p = p - mean(p);    % remove DC

    signals{pi} = p;

end

%% ============================================================
%  FIGURE 1 – TIME HISTORY
%% ============================================================

figure('Name','Time History','Color','w');
hold on; grid on;

title([plotTitle ' – Time History'], 'FontSize',13,'FontWeight','bold')
xlabel('Time [s]',     'FontSize',12)
ylabel('Pressure [Pa]','FontSize',12)

for pi = 1:nProbes
    lab_i    = baseLAB(pi,:);
    lab_i(1) = lab_i(1) + Lshift(min(pi, numel(Lshift)));
    plotColor = max(0, min(1, lab2rgb(lab_i)));
    plot(t, signals{pi}, ...
        'Color',       plotColor, ...
        'LineStyle',   '-', ...
        'LineWidth',   1.2, ...
        'DisplayName', legendLabels{pi});
end

legend('show','Location','southoutside','NumColumns',3)

%% ============================================================
%  FIGURE 2 – NARROWBAND SPL
%% ============================================================

figure('Name','Narrowband SPL','Color','w');
hold on; grid on;

title([plotTitle ' – Narrowband SPL'], 'FontSize',13,'FontWeight','bold')
xlabel('Frequency [Hz]',        'FontSize',12)
ylabel('SPL [dB re 20 \muPa]', 'FontSize',12)
set(gca,'XScale','log')

fs = 1 / mean(diff(t));   % shared sample rate

oaspl_labels = cell(nProbes, 1);
oaspl_td     = zeros(nProbes, 1);
oaspl_color  = zeros(nProbes, 3);

for pi = 1:nProbes

    [f_nb, NB] = localFFT(signals{pi}, fs, df_desired, PREF);

    lab_i    = baseLAB(pi,:);
    lab_i(1) = lab_i(1) + Lshift(min(pi, numel(Lshift)));
    plotColor = max(0, min(1, lab2rgb(lab_i)));

    semilogx(f_nb, NB, ...
        'Color',       plotColor, ...
        'LineStyle',   '-', ...
        'LineWidth',   2, ...
        'DisplayName', legendLabels{pi});

    oaspl_labels{pi}  = legendLabels{pi};
    oaspl_td(pi)      = computeOASPL_TD(signals{pi}, fs, fmin, fmax, PREF);
    oaspl_color(pi,:) = plotColor;

end

xlim([fmin fmax])
ylim([120 145])
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

for pi = 1:nProbes

    seg = floor(length(signals{pi}) / 8);

    if seg < 32
        continue
    end

    w = hann(seg);

    [P, f] = pwelch( ...
        signals{pi}, ...
        w, ...
        round(seg/2), ...
        [], ...
        fs);

    lab_i    = baseLAB(pi,:);
    lab_i(1) = lab_i(1) + Lshift(min(pi, numel(Lshift)));
    plotColor = max(min(lab2rgb(lab_i), 1), 0);

    semilogx( ...
        f, ...
        10*log10(P / PREF^2), ...
        'Color',       plotColor, ...
        'LineStyle',   '-', ...
        'LineWidth',   2, ...
        'DisplayName', legendLabels{pi});

    %% OASPL cross-check via PSD integration over [fmin fmax]
    oaspl_psd(pi, 1) = computeOASPL_PSD(f, P, fmin, fmax, PREF);

end

xlim([fmin fmax])
ylim([100 125])
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
ylabel('OASPL [dB re 20 \muPa]','FontSize',12)

b = bar(categorical(oaspl_labels, oaspl_labels), oaspl_psd, ...
        'FaceColor','flat');
b.CData = oaspl_color;

for pi = 1:nProbes
    text(pi, oaspl_psd(pi)/2, sprintf('%.1f dB', oaspl_psd(pi)), ...
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
fprintf('Source file: %s\n\n', fileName);
fprintf('%-40s  %14s  %14s  %10s\n', ...
    'Probe Label','OASPL_TD [dB]','OASPL_PSD [dB]','Diff [dB]');
fprintf('%s\n', repmat('-',1,84));

for pi = 1:nProbes
    if isnan(oaspl_psd(pi))
        fprintf('%-40s  %14.2f  %14s  %10s\n', ...
            oaspl_labels{pi}, oaspl_td(pi), 'N/A', 'N/A');
    else
        fprintf('%-40s  %14.2f  %14.2f  %10.2f\n', ...
            oaspl_labels{pi}, oaspl_td(pi), oaspl_psd(pi), ...
            oaspl_td(pi) - oaspl_psd(pi));
    end
end

fprintf('\nProbe point IDs selected:\n');
for pi = 1:nProbes
    fprintf('  %-12s  →  %s\n', selectedPrefixes{pi}, legendLabels{pi});
end
fprintf('\n');

%% ============================================================
%  LOCAL HELPER FUNCTIONS
%% ============================================================

function [f, NB] = localFFT(signal, fs, df_desired, PREF)

    signal = signal(:) - mean(signal);

    Nfft = round(fs / df_desired);
    if mod(Nfft,2) ~= 0, Nfft = Nfft + 1; end

    if Nfft > length(signal)
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

function OASPL = computeOASPL_TD(signal, fs, fmin, fmax, PREF)

    signal = signal(:) - mean(signal);
    nyq    = fs / 2;

    loCut = max(fmin,  1e-3);
    hiCut = min(fmax,  nyq * 0.999);

    if hiCut <= loCut
        warning('computeOASPL_TD:bandInvalid', ...
            'Band [%.1f %.1f] Hz invalid for fs=%.1f Hz. Using full-band RMS.', ...
            fmin, fmax, fs);
        OASPL = 20*log10( rms(signal) / PREF );
        return
    end

    Wn = [loCut hiCut] / nyq;
    [b, a]  = butter(4, Wn, 'bandpass');
    p_filt  = filtfilt(b, a, signal);
    OASPL   = 20*log10( rms(p_filt) / PREF );

end

% -----------------------------------------------------------------

function OASPL = computeOASPL_PSD(f, P, fmin, fmax, PREF)

    mask = f >= fmin & f <= fmax;

    if nnz(mask) < 2
        OASPL = NaN;
        return
    end

    p_meansq = trapz(f(mask), P(mask));
    OASPL    = 10*log10( p_meansq / PREF^2 );

end

% -----------------------------------------------------------------

function prefixes = extractPointPrefixes(colNames)

    prefixes = {};
    for k = 1:numel(colNames)
        parts = strsplit(colNames{k}, '_');
        if numel(parts) >= 2 && ~isnan(str2double(extract(parts{1}, digitsPattern)))
            if ~ismember(parts{1}, prefixes)
                prefixes{end+1} = parts{1}; %#ok<AGROW>
            end
        end
    end
    prefixes = sort(prefixes);

end