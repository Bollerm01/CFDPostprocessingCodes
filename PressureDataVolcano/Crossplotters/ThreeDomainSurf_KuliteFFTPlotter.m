%% ============================================================
% CFD Multi-Domain Unsteady Pressure Comparison
%
% Structure:
%   - 3 Domains, each with up to 2 CSV pressure location files
%       - Used primarily for the mesh refinement (test1m, test2m, test3m)
%       sweep)
%   - Each CSV: columns [time, pressure_mean]
%   - Time filtering
%   - Narrowband FFT comparison
%   - PSD comparison
%   - OASPL (Overall Sound Pressure Level)
%
%% ============================================================

clear; clc; close all;

%% ============================================================
% CONSTANTS
%% ============================================================

PREF    = 20e-6;
NDOM    = 3;          % number of domains
MAXFILE = 2;          % max CSVs per domain

%% ============================================================
% COLOR SYSTEM
%
%  - Each domain gets a distinct hue family (lines colormap)
%  - Within a domain, file 1 = darker, file 2 = brighter
%% ============================================================

nColors  = 10;
baseRGB  = lines(nColors);
baseLAB  = rgb2lab(baseRGB);
Lshift   = [-15, +15];   % file 1 darker, file 2 brighter

%% ============================================================
% DOMAIN LABELS  (edit these to match your case names)
%% ============================================================

domainNames = {'Domain 1', 'Domain 2', 'Domain 3'};

%% ============================================================
% USER SETTINGS  (single dialog up front)
%% ============================================================

answer = inputdlg( ...
    { ...
    'Plot Title', ...
    'Domain 1 Label', ...
    'Domain 2 Label', ...
    'Domain 3 Label', ...
    'Start Time [s]', ...
    'End Time [s]', ...
    'FFT df [Hz]', ...
    'Min Frequency [Hz]', ...
    'Max Frequency [Hz]'}, ...
    'Settings', ...
    [1 60], ...
    { ...
    'CFD Multi-Domain Pressure Comparison', ...
    'Domain 1', ...
    'Domain 2', ...
    'Domain 3', ...
    '0', ...
    '10', ...
    '75', ...
    '100', ...
    '20000'});

if isempty(answer), return; end

plotTitle  = answer{1};
domainNames = {answer{2}, answer{3}, answer{4}};
tStart     = str2double(answer{5});
tEnd       = str2double(answer{6});
df_desired = str2double(answer{7});
fmin       = str2double(answer{8});
fmax       = str2double(answer{9});

%% ============================================================
% FILE SELECTION  — 3 domains × up to 2 files each
%% ============================================================

% domFiles{d}  = cell array of filenames for domain d (1 or 2 entries)
% domPaths{d}  = corresponding path
domFiles = cell(NDOM,1);
domPaths = cell(NDOM,1);

for d = 1:NDOM

    [fnames, fpath] = uigetfile( ...
        {'*.csv','CSV Files'}, ...
        sprintf('Select up to %d CSV file(s) for %s', MAXFILE, domainNames{d}), ...
        'MultiSelect','on');

    if isequal(fnames,0)
        % User cancelled — treat as no files for this domain
        domFiles{d} = {};
        domPaths{d} = '';
        continue;
    end

    if ischar(fnames)
        fnames = {fnames};   % single file selected
    end

    if length(fnames) > MAXFILE
        warning('Domain %d: only the first %d file(s) will be used.', d, MAXFILE);
        fnames = fnames(1:MAXFILE);
    end

    domFiles{d} = fnames;
    domPaths{d} = fpath;
end

%% ============================================================
% STORAGE
%   domSig{d}{f}  — mean-removed pressure signal
%   domTime{d}{f} — time vector
%   domLabel{d}{f} — legend label string
%% ============================================================

domSig   = cell(NDOM,1);
domTime  = cell(NDOM,1);
domLabel = cell(NDOM,1);
domColor = cell(NDOM,1);

for d = 1:NDOM
    nf = length(domFiles{d});
    domSig{d}   = cell(nf,1);
    domTime{d}  = cell(nf,1);
    domLabel{d} = cell(nf,1);
    domColor{d} = zeros(nf,3);
end

%% ============================================================
% LOAD & CONDITION ALL SIGNALS
%% ============================================================

for d = 1:NDOM

    nf = length(domFiles{d});

    for f = 1:nf

        T = readtable(fullfile(domPaths{d}, domFiles{d}{f}), ...
            'VariableNamingRule','preserve');

        t = T.time;
        p = T.pressure;

        mask = t >= tStart & t <= tEnd;
        t    = t(mask);
        p    = p(mask) - mean(p(mask));

        domTime{d}{f} = t;
        domSig{d}{f}  = p;

        % Build legend label from filename (strip extension)
        [~,stem] = fileparts(domFiles{d}{f});
        domLabel{d}{f} = sprintf('%s – %s', domainNames{d}, stem);

        % Color: domain selects hue family, file index shifts lightness
        k   = mod(d-1, nColors) + 1;
        lab = baseLAB(k,:);
        lab(1) = lab(1) + Lshift(min(f, length(Lshift)));
        domColor{d}(f,:) = max(min(lab2rgb(lab), 1), 0);
    end
end

%% ============================================================
% HELPER: FFT function
%% ============================================================

computeNBFFT = @(sig,fs) localFFT(sig, fs, df_desired, PREF);

%% ============================================================
% FIGURE 1 — TIME HISTORY
%% ============================================================

figure(1); hold on; grid on;
title([plotTitle ' – Time History']);
xlabel('Time [s]');
ylabel('Pressure [Pa]  (mean-removed)');

for d = 1:NDOM
    for f = 1:length(domSig{d})
        plot(domTime{d}{f}, domSig{d}{f}, ...
            'LineWidth', 1.2, ...
            'Color',     domColor{d}(f,:), ...
            'DisplayName', domLabel{d}{f});
    end
end

legend('show');

%% ============================================================
% FIGURE 2 — NARROWBAND FFT (SPL)
%% ============================================================

figure(2); hold on; grid on;
title([plotTitle ' – Narrowband SPL']);
xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
set(gca,'XScale','log');

for d = 1:NDOM
    for f = 1:length(domSig{d})

        fs = 1 / mean(diff(domTime{d}{f}));
        [freq, NB] = computeNBFFT(domSig{d}{f}, fs);

        semilogx(freq, NB, ...
            'LineWidth',   2, ...
            'Color',       domColor{d}(f,:), ...
            'DisplayName', domLabel{d}{f});
    end
end

xlim([fmin fmax]);
if nf == 1
    legend('show','Location','southoutside','NumColumns',3);
else
    legend('show','Location','southoutside','NumColumns',2);
end
%% ============================================================
% FIGURE 3 — PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' – PSD']);
xlabel('Frequency [Hz]');
ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

for d = 1:NDOM
    for f = 1:length(domSig{d})

        fs  = 1 / mean(diff(domTime{d}{f}));
        seg = floor(length(domSig{d}{f}) / 8);
        w   = hann(seg);

        [P, freq] = pwelch(domSig{d}{f}, w, round(seg/2), [], fs);

        semilogx(freq, 10*log10(P / PREF^2), ...
            'LineWidth',   2, ...
            'Color',       domColor{d}(f,:), ...
            'DisplayName', domLabel{d}{f});
    end
end

xlim([fmin fmax]);
if nf == 1
    legend('show','Location','southoutside','NumColumns',3);
else
    legend('show','Location','southoutside','NumColumns',2);
end
%% ============================================================
% OASPL CALCULATION
%   Integrate narrowband RMS pressure² over [fmin, fmax]
%   OASPL = 10·log10( Σ (Xlin²/2) / PREF² )
%% ============================================================

% Flatten all entries for bar chart
allOASPL  = [];
allColors = [];
allLabels = {};

for d = 1:NDOM
    for f = 1:length(domSig{d})

        fs = 1 / mean(diff(domTime{d}{f}));
        [freq, ~, Xlin] = computeNBFFT(domSig{d}{f}, fs);

        mask  = freq >= fmin & freq <= fmax;
        p_ms  = (Xlin(mask).^2) / 2;
        oaspl = 10 * log10(sum(p_ms) / PREF^2);

        allOASPL  = [allOASPL;  oaspl];                %#ok<AGROW>
        allColors = [allColors;  domColor{d}(f,:)];    %#ok<AGROW>
        allLabels{end+1} = domLabel{d}{f};             %#ok<AGROW>
    end
end

%% ============================================================
% FIGURE 4 — OASPL BAR CHART
%% ============================================================

% Build x-positions: group bars by domain, gap between domains
xPos   = [];
xTicks = [];
gap    = 0.6;
cursor = 1;

groupCenters = zeros(NDOM,1);

for d = 1:NDOM
    nf = length(domSig{d});
    if nf == 0, continue; end

    xs = cursor : cursor + nf - 1;
    groupCenters(d) = mean(xs);
    xPos   = [xPos,   xs];          %#ok<AGROW>
    xTicks = [xTicks, xs];          %#ok<AGROW>
    cursor = cursor + nf + gap;
end

figure(4); hold on; grid on;
title([plotTitle sprintf(' – OASPL [%.0f – %.0f Hz]', fmin, fmax)]);
ylabel('OASPL [dB re 20 \muPa]');

for i = 1:length(allOASPL)
    bar(xPos(i), allOASPL(i), 0.7, ...
        'FaceColor', allColors(i,:), ...
        'EdgeColor', allColors(i,:) * 0.6);
end

% Value labels inside bars (rotated)
for i = 1:length(allOASPL)
    text(xPos(i), allOASPL(i)/2, ...
        sprintf('%.1f dB', allOASPL(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'middle', ...
        'Rotation',            90, ...
        'FontSize',            12, ...
        'Color',               'w', ...
        'FontWeight',          'bold');
end

% Domain group labels above bars
yl = ylim;
for d = 1:NDOM
    if length(domSig{d}) == 0, continue; end
    text(groupCenters(d), yl(2) * 0.97, domainNames{d}, ...
        'HorizontalAlignment', 'center', ...
        'FontSize',            10, ...
        'FontWeight',          'bold', ...
        'Color',               [0.25 0.25 0.25]);
end

set(gca, ...
    'XTick',              xTicks, ...
    'XTickLabel',         allLabels, ...
    'XTickLabelRotation', 30);

xlim([0.3, xPos(end) + 0.7]);

%% ============================================================
% PRINT OASPL TABLE TO COMMAND WINDOW
%% ============================================================

fprintf('\n=== OASPL Summary [%.0f – %.0f Hz] ===\n', fmin, fmax);
fprintf('%-45s  %10s\n', 'Name', 'OASPL [dB]');
fprintf('%s\n', repmat('-',1,60));

idx = 1;
for d = 1:NDOM
    for f = 1:length(domSig{d})
        fprintf('%-45s  %10.2f\n', allLabels{idx}, allOASPL(idx));
        idx = idx + 1;
    end
end

fprintf('%s\n\n', repmat('-',1,60));

%% ============================================================
% LOCAL FFT FUNCTION
%   Returns:
%     f     — frequency vector [Hz]
%     NB    — narrowband SPL [dB re PREF]
%     Xlin  — linear amplitude [Pa, peak, single-sided]
%% ============================================================

function [f, NB, Xlin] = localFFT(signal, fs, df_desired, PREF)

signal = signal(:);
Nfft   = round(fs / df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

window  = hann(Nfft);
nBlocks = floor(length(signal) / Nfft);

if nBlocks < 2
    error('Signal too short for the requested FFT frequency resolution.');
end

spec = zeros(Nfft, nBlocks);

for k = 1:nBlocks
    idx1 = (k-1)*Nfft + 1;
    idx2 =  k   *Nfft;
    X = fft(signal(idx1:idx2) .* window);
    spec(:,k) = 2*abs(X) / Nfft;
end

Xavg = mean(spec, 2);
f    = (0 : Nfft/2)' * (fs / Nfft);
Xlin = Xavg(1 : Nfft/2+1);
NB   = 20*log10(Xlin / PREF);

end