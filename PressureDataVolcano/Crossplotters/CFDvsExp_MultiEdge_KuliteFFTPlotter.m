%% ============================================================
% Multiple Edge CFD vs Experimental Kulite Cross Plotter
% CFD Data: Point Data
% Dual CSV Input: K1-3 and K4-6 per case
%% ============================================================

clear; clc; close all;

%% ============================================================
% CONSTANTS
%% ============================================================

PREF      = 20e-6;
PSI_TO_PA = 6894.757;

%% ============================================================
% SENSOR CONFIGURATION
%% ============================================================

% --- K1-3 CSV: Voltage_0->K1, Voltage_1->K2, Voltage_2->K3 ---
man_cal_sens_K13 = [ ...
    30.104/1000 ...   % K1
    30.024/1000 ...   % K2
    29.976/1000];     % K3

gain_K13 = [64.0, 64.0, 64.0];   % K1, K2, K3

% --- K4-6 CSV: Voltage_0->K4, Voltage_1->K6, Voltage_2->K5 ---
% Stored in RAW column order; reordering to K4,K5,K6 below
man_cal_sens_K46_raw = [ ...
    29.972/1000 ...   % Voltage_0 -> K4
    29.824/1000 ...   % Voltage_1 -> K6
    30.178/1000];     % Voltage_2 -> K5

gain_K46_raw = [64.0, 64.0, 64.0];   % raw col order

% Reorder K4-6 to logical K4,K5,K6: col [1,3,2]
reorder_46 = [1, 2, 3];
man_cal_sens_K46 = man_cal_sens_K46_raw(reorder_46);
gain_K46         = gain_K46_raw(reorder_46);

% --- Unified arrays in K1..K6 order ---
man_cal_sens_all = [man_cal_sens_K13, man_cal_sens_K46];
gain_all         = [gain_K13,         gain_K46];

legendNames = {'K1','K2','K3','K4','K5','K6'};

% Raw CSV column names (same in both CSVs)
rawChannels = {'Voltage_0','Voltage_1','Voltage_2'};

% For each K1..K6: which CSV group and which raw column index
sourceGroup = {'K13','K13','K13','K46','K46','K46'};
rawColIdx   = [1, 2, 3, reorder_46];   % [1,2,3, 1,2, 3]

%% ============================================================
% CASE SETUP
%% ============================================================

answer = inputdlg( ...
    {'Number of Cases','Kulite Location (K1-K6)'}, ...
    'Case Setup', ...
    [1 50], ...
    {'2','K1'});

if isempty(answer), return; end

nCases         = str2double(answer{1});
selectedKulite = upper(strtrim(answer{2}));

kIdx = find(strcmp(selectedKulite, legendNames));
if isempty(kIdx)
    error('Invalid Kulite selection: %s', selectedKulite);
end

% Determine which CSV group and raw column this sensor lives in
kGroup  = sourceGroup{kIdx};
kRawCol = rawColIdx(kIdx);
kColName = rawChannels{kRawCol};

sensor_sens_k = man_cal_sens_all(kIdx);
gain_k        = gain_all(kIdx);
system_sens_k = sensor_sens_k * gain_k;

fprintf('Selected: %s | Source CSV: %s | Raw column: %s\n', ...
    selectedKulite, kGroup, kColName);
fprintf('System sensitivity: %.6f V/Pa\n', system_sens_k / PSI_TO_PA);

caseNames = cell(nCases, 1);
expFiles_K13 = cell(nCases, 1);  expPaths_K13 = cell(nCases, 1);
expFiles_K46 = cell(nCases, 1);  expPaths_K46 = cell(nCases, 1);
cfdFiles     = cell(nCases, 1);  cfdPaths     = cell(nCases, 1);

%% ============================================================
% COLOR SYSTEM
%% ============================================================

nColors = max(nCases, 10);
baseRGB = lines(nColors);
baseLAB = rgb2lab(baseRGB);

%% ============================================================
% FILE SELECTION PER CASE
%% ============================================================

for c = 1:nCases

    tmp = inputdlg( ...
        sprintf('Name for Case %i', c), ...
        'Case Name', 1, {sprintf('Case%i', c)});
    if isempty(tmp), return; end
    caseNames{c} = tmp{1};

    [expFiles_K13{c}, expPaths_K13{c}] = uigetfile('*.csv', ...
        sprintf('[%s] Select K1-3 Experimental CSV', caseNames{c}));
    if isequal(expFiles_K13{c}, 0), return; end

    [expFiles_K46{c}, expPaths_K46{c}] = uigetfile('*.csv', ...
        sprintf('[%s] Select K4-6 Experimental CSV', caseNames{c}));
    if isequal(expFiles_K46{c}, 0), return; end

    [cfdFiles{c}, cfdPaths{c}] = uigetfile( ...
        {'*.dat;*.txt','CFD Files'}, ...
        sprintf('[%s] Select CFD File', caseNames{c}));
    if isequal(cfdFiles{c}, 0), return; end

end

%% ============================================================
% USER SETTINGS
%% ============================================================

answer = inputdlg( ...
    {'Plot Title','Start Time [s]','End Time [s]', ...
     'FFT df [Hz]','Min Frequency [Hz]','Max Frequency [Hz]'}, ...
    'Settings', [1 50], ...
    {'CFD vs Experiment','0','10','75','100','20000'});

if isempty(answer), return; end

plotTitle  = answer{1};
tStart     = str2double(answer{2});
tEnd       = str2double(answer{3});
df_desired = str2double(answer{4});
fmin       = str2double(answer{5});
fmax       = str2double(answer{6});

%% ============================================================
% EXPERIMENT PROCESSING
%% ============================================================

expSignals = {};
expLabels  = {};
expTimeRef = {};

figure(1); hold on; grid on;
title([plotTitle ' - Time History']);
xlabel('Time [s]'); ylabel('Pressure [Pa]');

for c = 1:nCases

    % Load the correct CSV based on which group the selected Kulite is in
    if strcmp(kGroup, 'K13')
        T = readtable(fullfile(expPaths_K13{c}, expFiles_K13{c}), ...
            'VariableNamingRule','modify');
    else
        T = readtable(fullfile(expPaths_K46{c}, expFiles_K46{c}), ...
            'VariableNamingRule','modify');
    end

    timeExpFull = T.Time_;
    timeMask    = timeExpFull >= tStart & timeExpFull <= tEnd;
    timeExp     = timeExpFull(timeMask);

    V = T.(kColName);
    V = V(timeMask);

    p = (V ./ system_sens_k) * PSI_TO_PA;
    p = p - mean(p);

    expSignals{c} = p;
    expTimeRef{c} = timeExp;
    expLabels{c}  = sprintf('Exp - %s', caseNames{c});

    plotColor = getCaseColor(c, false, baseLAB);
    plot(timeExp, p, 'LineWidth', 1.5, ...
        'Color', plotColor, 'DisplayName', expLabels{c});

end

%% ============================================================
% CFD PROCESSING
%% ============================================================

cfdSignals = {};
cfdTime    = {};
cfdLabels  = {};

for c = 1:nCases

    fid  = fopen(fullfile(cfdPaths{c}, cfdFiles{c}));
    data = textscan(fid, '%f %f', 'CommentStyle','#', 'CollectOutput',true);
    fclose(fid);
    data = data{1};

    t = data(:,1);
    p = data(:,2);

    mask = t >= tStart & t <= tEnd;
    t = t(mask);
    p = p(mask);
    p = p - mean(p);

    cfdSignals{c} = p;
    cfdTime{c}    = t;
    cfdLabels{c}  = sprintf('CFD - %s', caseNames{c});

    plotColor = getCaseColor(c, true, baseLAB);
    figure(1)
    plot(t, p, '--', 'LineWidth', 1.5, ...
        'Color', plotColor, 'DisplayName', cfdLabels{c});

end

legend('show', 'Location','southoutside', 'NumColumns',3);

%% ============================================================
% FFT FUNCTION HANDLE
%% ============================================================

computeNBFFT = @(sig,fs) localFFT(sig, fs, df_desired, PREF);

%% ============================================================
% NARROWBAND SPL
%% ============================================================

figure(2); hold on; grid on;
title([plotTitle ' - Narrowband SPL']);
xlabel('Frequency [Hz]'); ylabel('SPL [dB]');
set(gca,'XScale','log');

oaspl_td      = [];
oaspl_psd     = [];
oaspl_labels  = {};
oaspl_isCFD   = [];
oaspl_caseIdx = [];

for i = 1:length(expSignals)
    fsExp = 1/mean(diff(expTimeRef{i}));
    [f, NB] = computeNBFFT(expSignals{i}, fsExp);
    plotColor = getCaseColor(i, false, baseLAB);
    semilogx(f, NB, 'LineWidth', 2, 'Color', plotColor, ...
        'DisplayName', sprintf('Exp - %s', caseNames{i}));
    oaspl_td(end+1,1)      = computeOASPL_TD(expSignals{i}, fsExp, fmin, fmax, PREF);
    oaspl_labels{end+1,1}  = sprintf('Exp - %s', caseNames{i});
    oaspl_isCFD(end+1,1)   = 0;
    oaspl_caseIdx(end+1,1) = i;
end

for i = 1:length(cfdSignals)
    fsCFD = 1/mean(diff(cfdTime{i}));
    [f, NB] = computeNBFFT(cfdSignals{i}, fsCFD);
    plotColor = getCaseColor(i, true, baseLAB);
    semilogx(f, NB, 'LineWidth', 2, 'Color', plotColor, ...
        'DisplayName', sprintf('CFD - %s', caseNames{i}));
    oaspl_td(end+1,1)      = computeOASPL_TD(cfdSignals{i}, fsCFD, fmin, fmax, PREF);
    oaspl_labels{end+1,1}  = sprintf('CFD - %s', caseNames{i});
    oaspl_isCFD(end+1,1)   = 1;
    oaspl_caseIdx(end+1,1) = i;
end

xlim([fmin fmax]);
legend('show', 'Location','southoutside', 'NumColumns',3);

%% ============================================================
% PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' - PSD']);
xlabel('Frequency [Hz]'); ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

psdCount = 0;

for i = 1:length(expSignals)
    fsExp = 1/mean(diff(expTimeRef{i}));
    seg = floor(length(expSignals{i})/8);
    w   = hann(seg);
    [P, f] = pwelch(expSignals{i}, w, round(seg/2), [], fsExp);
    plotColor = getCaseColor(i, false, baseLAB);
    semilogx(f, 10*log10(P/PREF^2), 'LineWidth', 2, ...
        'Color', plotColor, 'DisplayName', sprintf('Exp - %s', caseNames{i}));
    psdCount = psdCount + 1;
    oaspl_psd(psdCount,1) = computeOASPL_PSD(f, P, fmin, fmax, PREF);
end

for i = 1:length(cfdSignals)
    fsCFD = 1/mean(diff(cfdTime{i}));
    seg = floor(length(cfdSignals{i})/8);
    w   = hann(seg);
    [P, f] = pwelch(cfdSignals{i}, w, round(seg/2), [], fsCFD);
    plotColor = getCaseColor(i, true, baseLAB);
    semilogx(f, 10*log10(P/PREF^2), 'LineWidth', 2, ...
        'Color', plotColor, 'DisplayName', sprintf('CFD - %s', caseNames{i}));
    psdCount = psdCount + 1;
    oaspl_psd(psdCount,1) = computeOASPL_PSD(f, P, fmin, fmax, PREF);
end

xlim([fmin fmax]);
legend('show', 'Location','southoutside', 'NumColumns',3);

%% ============================================================
% OASPL SUMMARY
%% ============================================================

figure(4); hold on; grid on;
title([plotTitle ' - OASPL (' num2str(fmin) '-' num2str(fmax) ' Hz)']);
ylabel('OASPL [dB re 20 \muPa]');

barColors = zeros(length(oaspl_labels), 3);
for i = 1:length(oaspl_labels)
    barColors(i,:) = getCaseColor(oaspl_caseIdx(i), logical(oaspl_isCFD(i)), baseLAB);
end

b = bar(categorical(oaspl_labels, oaspl_labels), oaspl_psd, 'FaceColor','flat');
b.CData = barColors;

for i = 1:length(oaspl_labels)
    text(i, oaspl_psd(i)/2, sprintf('%.1f dB', oaspl_psd(i)), ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'Rotation',90, 'FontSize',12, 'Color','w', 'FontWeight','bold');
end

ylim([0, max(oaspl_td)*1.15]);
xtickangle(45);

fprintf('\n=== OASPL Summary (%.0f-%.0f Hz) | Sensor: %s ===\n', fmin, fmax, selectedKulite);
fprintf('%-20s %15s %15s %15s\n','Label','OASPL_TD [dB]','OASPL_PSD [dB]','Diff [dB]');
for i = 1:length(oaspl_labels)
    fprintf('%-20s %15.2f %15.2f %15.2f\n', ...
        oaspl_labels{i}, oaspl_td(i), oaspl_psd(i), oaspl_td(i)-oaspl_psd(i));
end
fprintf('\n');

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function [f,NB] = localFFT(signal, fs, df_desired, PREF)
signal  = signal(:);
Nfft    = round(fs/df_desired);
if mod(Nfft,2)~=0, Nfft = Nfft+1; end
window  = hann(Nfft);
nBlocks = floor(length(signal)/Nfft);
spec    = zeros(Nfft, nBlocks);
for k = 1:nBlocks
    x = signal((k-1)*Nfft+1 : k*Nfft);
    X = fft(x .* window);
    spec(:,k) = 2*abs(X)/Nfft;
end
Xavg = mean(spec, 2);
f    = (0:Nfft/2)' * (fs/Nfft);
NB   = 20*log10(Xavg(1:Nfft/2+1) / PREF);
end

function OASPL = computeOASPL_TD(signal, fs, fmin, fmax, PREF)
signal = signal(:) - mean(signal);
nyq    = fs/2;
lo     = max(fmin, 1e-3);
hi     = min(fmax, nyq*0.999);
if hi <= lo
    OASPL = 20*log10(rms(signal)/PREF);
else
    [b,a] = butter(4, [lo hi]/nyq, 'bandpass');
    p     = filtfilt(b, a, signal);
    OASPL = 20*log10(rms(p)/PREF);
end
end

function OASPL = computeOASPL_PSD(f, P, fmin, fmax, PREF)
mask  = f >= fmin & f <= fmax;
OASPL = 10*log10(trapz(f(mask), P(mask)) / PREF^2);
end

function c = getCaseColor(caseNum, isCFD, baseLAB)
idx = mod(caseNum-1, size(baseLAB,1)) + 1;
lab = baseLAB(idx,:);
if isCFD
    lab(1) = min(100, lab(1)+15);
else
    lab(1) = max(0,   lab(1)-20);
end
c = max(min(lab2rgb(lab), 1), 0);
end