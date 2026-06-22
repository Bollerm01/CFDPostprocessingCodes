%% ============================================================
% CFD Slice Surface Dataset (A) vs CFD Full Surface Dataset (B)
%
% Features:
%   - Multi-file CFD Surface Slice Domain Set (A)
%   - Multi-file CFD Surface Full Domain Set (B)
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

PREF = 20e-6;

%% ============================================================
% COLOR SYSTEM
%% ============================================================

nColors = 10;
baseRGB = lines(nColors);
baseLAB = rgb2lab(baseRGB);

% Brightness shifts
Lshift = [-15 +15];   % A = darker, B = brighter

%% ============================================================
% USER INPUT: CFD Slice SURFACE DATASET A
%% ============================================================

[aFiles, aPath] = uigetfile( ...
    {'*.csv','CFD Surface A Files'}, ...
    'Select CFD Slice Surface Dataset', ...
    'MultiSelect','on');

if isequal(aFiles,0), return; end
if ischar(aFiles), aFiles = {aFiles}; end

aNames = cellfun(@(x) strtok(x,'_'), aFiles, 'UniformOutput', false);

%% ============================================================
% USER INPUT: CFD Full SURFACE DATASET B
%% ============================================================

[bFiles, bPath] = uigetfile( ...
    {'*.csv','CFD Surface B Files'}, ...
    'Select CFD Full Surface Dataset', ...
    'MultiSelect','on');

if isequal(bFiles,0), return; end
if ischar(bFiles), bFiles = {bFiles}; end

bNames = cellfun(@(x) strtok(x,'_'), bFiles, 'UniformOutput', false);

%% ============================================================
% USER SETTINGS
%% ============================================================

answer = inputdlg( ...
    { ...
    'Plot Title', ...
    'Start Time [s]', ...
    'End Time [s]', ...
    'FFT df [Hz]', ...
    'Min Frequency [Hz]', ...
    'Max Frequency [Hz]'}, ...
    'Settings', ...
    [1 50], ...
    { ...
    'CFD Slice vs Full Kulite Surface Comparison', ...
    '0', ...
    '10', ...
    '75', ...
    '100', ...
    '20000'});

if isempty(answer), return; end

plotTitle = answer{1};
tStart = str2double(answer{2});
tEnd   = str2double(answer{3});

df_desired = str2double(answer{4});
fmin = str2double(answer{5});
fmax = str2double(answer{6});

%% ============================================================
% STORAGE
%% ============================================================

A_sig  = cell(length(aFiles),1);
A_time = cell(length(aFiles),1);

B_sig  = cell(length(bFiles),1);
B_time = cell(length(bFiles),1);

%% ============================================================
% TIME HISTORY PLOT
%% ============================================================

figure(1); hold on; grid on;
title([plotTitle ' - Time History']);
xlabel('Time [s]');
ylabel('Pressure Mean [Pa]');

%% ============================================================
% PROCESS DATASET A
%% ============================================================

for i = 1:length(aFiles)

    T = readtable(fullfile(aPath,aFiles{i}), ...
        'VariableNamingRule','preserve');

    t = T.time;
    p = T.pressure_mean;

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask) - mean(p(mask));

    A_time{i} = t;
    A_sig{i}  = p;

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);

    c = max(min(lab2rgb(lab),1),0);

    plot(t,p,'-','LineWidth',1.2, ...
        'Color',c, ...
        'DisplayName',['CFD Slice ', aNames{i}]);
end

%% ============================================================
% PROCESS DATASET B
%% ============================================================

for i = 1:length(bFiles)

    T = readtable(fullfile(bPath,bFiles{i}), ...
        'VariableNamingRule','preserve');

    t = T.time;
    p = T.pressure_mean;

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask) - mean(p(mask));

    B_time{i} = t;
    B_sig{i}  = p;

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);

    c = max(min(lab2rgb(lab),1),0);

    plot(t,p,'-','LineWidth',1.4, ...
        'Color',c, ...
        'DisplayName',['CFD Full ', bNames{i}]);
end

legend('show');

%% ============================================================
% FFT FUNCTION (returns linear amplitudes + dB NB)
%% ============================================================

computeNBFFT = @(sig,fs) localFFT(sig,fs,df_desired,PREF);

%% ============================================================
% NARROWBAND FFT
%% ============================================================

figure(2); hold on; grid on;
title([plotTitle ' - Narrowband SPL']);
xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
set(gca,'XScale','log');

%% DATASET A FFT
for i = 1:length(A_sig)

    fs = 1/mean(diff(A_time{i}));

    [f,NB] = computeNBFFT(A_sig{i},fs);

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,NB,'LineWidth',2, ...
        'Color',c, ...
        'DisplayName',['CFD Slice ', aNames{i}]);
end

%% DATASET B FFT
for i = 1:length(B_sig)

    fs = 1/mean(diff(B_time{i}));

    [f,NB] = computeNBFFT(B_sig{i},fs);

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,NB,'-','LineWidth',2, ...
        'Color',c, ...
        'DisplayName',['CFD Full ', bNames{i}]);
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns',2);

%% ============================================================
% PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' - PSD']);
xlabel('Frequency [Hz]');
ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

%% DATASET A PSD
for i = 1:length(A_sig)

    seg = floor(length(A_sig{i})/8);
    w   = hann(seg);

    fs = 1/mean(diff(A_time{i}));

    [P,f] = pwelch(A_sig{i}, w, round(seg/2), [], fs);

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,10*log10(P),'LineWidth',2, ...
        'Color',c, ...
        'DisplayName',['CFD Slice ', aNames{i}]);
end

%% DATASET B PSD
for i = 1:length(B_sig)

    seg = floor(length(B_sig{i})/8);
    w   = hann(seg);

    fs = 1/mean(diff(B_time{i}));

    [P,f] = pwelch(B_sig{i}, w, round(seg/2), [], fs);

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,10*log10(P),'-','LineWidth',2, ...
        'Color',c, ...
        'DisplayName',['CFD Full ', bNames{i}]);
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns',2);

%% ============================================================
% OASPL CALCULATION
%% ============================================================
% Integrate narrowband mean-square pressure contributions
% over the user-defined frequency range [fmin, fmax].
%
% Method:
%   Xlin (Pa, peak) from localFFT  ->  Xrms = Xlin / sqrt(2)
%   p_ms(i) = Xrms(i)^2  = (Xlin(i)^2) / 2
%   OASPL = 10 * log10( sum(p_ms, in band) / PREF^2 )
%
% The DC bin (f=0) is excluded; the Nyquist bin is included.
%% ============================================================

nA = length(aFiles);
nB = length(bFiles);

oaspl_A = zeros(nA,1);
oaspl_B = zeros(nB,1);

colors_A = zeros(nA,3);
colors_B = zeros(nB,3);

%% DATASET A OASPL
for i = 1:nA

    fs = 1/mean(diff(A_time{i}));

    [f, ~, Xlin] = computeNBFFT(A_sig{i}, fs);

    % Restrict to [fmin, fmax] (exclude DC bin f=0)
    mask = f >= fmin & f <= fmax;

    % RMS pressure^2 per bin (single-sided spectrum, peak -> rms)
    p_ms = (Xlin(mask).^2) / 2;

    oaspl_A(i) = 10 * log10( sum(p_ms) / PREF^2 );

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);
    colors_A(i,:) = max(min(lab2rgb(lab),1),0);
end

%% DATASET B OASPL
for i = 1:nB

    fs = 1/mean(diff(B_time{i}));

    [f, ~, Xlin] = computeNBFFT(B_sig{i}, fs);

    mask = f >= fmin & f <= fmax;

    p_ms = (Xlin(mask).^2) / 2;

    oaspl_B(i) = 10 * log10( sum(p_ms) / PREF^2 );

    k = mod(i-1,nColors)+1;
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);
    colors_B(i,:) = max(min(lab2rgb(lab),1),0);
end

%% ============================================================
% OASPL BAR CHART (Figure 4)
%% ============================================================

figure(4); hold on; grid on;
title([plotTitle sprintf(' - OASPL [%.0f - %.0f Hz]', fmin, fmax)]);
ylabel('OASPL [dB re 20 \muPa]');

% Build bar positions: Dataset A first, then Dataset B
% with a small gap between the two groups
gap    = 0.5;
xA     = (1 : nA);
xB     = (nA + 1 + gap) : (nA + nB + gap);
xAll   = [xA, xB];
oasplAll = [oaspl_A; oaspl_B];
colAll   = [colors_A; colors_B];

% Draw individual colored bars
for i = 1:nA+nB
    bar(xAll(i), oasplAll(i), 0.7, ...
        'FaceColor', colAll(i,:), ...
        'EdgeColor', colAll(i,:)*0.6);
end

% Annotate bar tops with dB value
for i = 1:nA+nB
    text(xAll(i), oasplAll(i)/2, ...
        sprintf('%.1f dB', oasplAll(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle',  ...
        'Rotation',90, ...
        'FontSize',12, ...
        'Color','w', ...
        'FontWeight','bold');
end

% X-tick labels
labelsA = cellfun(@(x) ['Slice ' x], aNames, 'UniformOutput',false);
labelsB = cellfun(@(x) ['Full '  x], bNames, 'UniformOutput',false);

set(gca, ...
    'XTick',      [xA, xB], ...
    'XTickLabel', [labelsA, labelsB], ...
    'XTickLabelRotation', 30);

xlim([0.3, xB(end) + 0.7]);

% Group divider line and labels
% yl = ylim;
% xline(nA + gap/2 + 0.5, '--k', 'Alpha', 0.3);
% text(mean(xA), yl(2) - 0.5*diff(yl)*0.05, 'CFD Slice', ...
%     'HorizontalAlignment','center','FontSize',9,'Color',[0.4 0.4 0.4]);
% text(mean(xB), yl(2) - 0.5*diff(yl)*0.05, 'CFD Full', ...
%     'HorizontalAlignment','center','FontSize',9,'Color',[0.4 0.4 0.4]);

%% ============================================================
% PRINT OASPL TABLE TO COMMAND WINDOW
%% ============================================================

fprintf('\n=== OASPL Summary [%.0f - %.0f Hz] ===\n', fmin, fmax);
fprintf('%-35s  %10s\n', 'Name', 'OASPL [dB]');
fprintf('%s\n', repmat('-',1,50));
for i = 1:nA
    fprintf('CFD Slice  %-25s  %10.2f\n', aNames{i}, oaspl_A(i));
end
for i = 1:nB
    fprintf('CFD Full   %-25s  %10.2f\n', bNames{i}, oaspl_B(i));
end
fprintf('%s\n\n', repmat('-',1,50));

%% ============================================================
% LOCAL FFT FUNCTION
% Returns:
%   f     - frequency vector [Hz]
%   NB    - narrowband SPL [dB re PREF]
%   Xlin  - linear amplitude [Pa, peak, single-sided]
%% ============================================================

function [f, NB, Xlin] = localFFT(signal, fs, df_desired, PREF)

signal = signal(:);

Nfft = round(fs / df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

window  = hann(Nfft);
nBlocks = floor(length(signal) / Nfft);

if nBlocks < 2
    error('Signal too short for FFT resolution.');
end

spec = zeros(Nfft, nBlocks);

for k = 1:nBlocks
    idx1 = (k-1)*Nfft + 1;
    idx2 =  k   *Nfft;

    x = signal(idx1:idx2);
    X = fft(x .* window);

    spec(:,k) = 2*abs(X) / Nfft;
end

Xavg = mean(spec, 2);

f    = (0 : Nfft/2)' * (fs / Nfft);
Xlin = Xavg(1 : Nfft/2+1);          % linear amplitude [Pa peak]
NB   = 20*log10(Xlin / PREF);        % narrowband SPL [dB]

end