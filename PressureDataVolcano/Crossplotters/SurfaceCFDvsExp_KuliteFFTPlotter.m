%% ============================================================
% CFD vs Experimental Kulite Cross Plotter - Surface Data
%
% Features:
%   - Multi-Kulite selection
%   - Multi-CFD file selection (surface CSV data)
%   - Time window filtering
%   - Narrowband SPL (FFT averaged)
%   - PSD (Welch)
%   - OASPL (time-domain RMS, cross-checked via PSD integration)
%
%% ============================================================

clear; clc; close all;

%% ============================================================
% CONSTANTS with calibration
%% ============================================================

PREF = 20e-6;
PSI_TO_PA = 6894.757;

sensor_sens = 0.03;   % V/psi

gain = [ ...
    65.3 ...
    65.9 ...
    65.1 ...
    67.15 ...
    65.2 ...
    66.4 ];

channelNames = { ...
    'Voltage_5' ...
    'Voltage_1' ...
    'Voltage_2' ...
    'Voltage_3' ...
    'Voltage_4' ...
    'Voltage_0' };

legendNames = { ...
    'K1','K2','K3','K4','K5','K6' };

%% ============================================================
% COLOR SYSTEM
%% ============================================================

nColors = 10;
baseRGB = lines(nColors);
baseLAB = rgb2lab(baseRGB);

% Experimental = darker
% CFD = brighter
Lshift = [-15 +15];

%% ============================================================
% USER INPUT: EXPERIMENT FILE
%% ============================================================

[expFile,expPath] = uigetfile('*.csv','Select Experimental CSV');

if isequal(expFile,0), return; end

T = readtable(fullfile(expPath,expFile),...
    'VariableNamingRule','modify');

% timeExpFull = T.Voltage_0_Time_;
timeExpFull = T.Time_;

%% ============================================================
% USER INPUT: CFD FILES (MULTI)
%% ============================================================

[cfdFiles,cfdPath] = uigetfile( ...
    {'*.csv','CFD Surface CSV Files'}, ...
    'Select CFD Files', ...
    'MultiSelect','on');

if isequal(cfdFiles,0), return; end

if ischar(cfdFiles)
    cfdFiles = {cfdFiles};
end

cfdNames =  cellfun(@(x) strtok(x,'.'), cfdFiles, 'UniformOutput', false);

%% ============================================================
% SELECT EXPERIMENT CHANNELS (MULTI)
%% ============================================================

[chIdx,tf] = listdlg( ...
    'PromptString','Select Kulite Channels', ...
    'SelectionMode','multiple', ...
    'ListString',legendNames);

if ~tf, return; end

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
    'CFD vs Experiment', ...
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
% TIME WINDOW (EXPERIMENT)
%% ============================================================

timeMaskExp = timeExpFull >= tStart & timeExpFull <= tEnd;
timeExp = timeExpFull(timeMaskExp);

%% ============================================================
% PROCESS EXPERIMENT CHANNELS
%% ============================================================

expSignals = cell(length(chIdx),1);

figure(1); hold on; grid on;
title([plotTitle ' - Time History']);
xlabel('Time [s]');
ylabel('Pressure [Pa]');

for i = 1:length(chIdx)

    k = chIdx(i);

    V = T.(channelNames{k});
    V = V(timeMaskExp);

    system_sens = sensor_sens * gain(k);

    p = (V ./ system_sens) * PSI_TO_PA;

    p = p - mean(p);

    expSignals{i} = p;

    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(1);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    plot(timeExp,p,'LineWidth',1.2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);
end

%% ============================================================
% PROCESS CFD FILES (CSV SURFACE DATA)
%% ============================================================

cfdSignals = cell(length(cfdFiles),1);
cfdTime    = cell(length(cfdFiles),1);

figure(1);

for i = 1:length(cfdFiles)

    fname = fullfile(cfdPath,cfdFiles{i});

    TCFD = readtable(fname,...
        'VariableNamingRule','preserve');

    % Required columns:
    % filename, iteration, time, pressure_mean

    t = TCFD.time;
    p = TCFD.pressure_mean;

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask);

    % remove DC component
    p = p - mean(p);

    cfdSignals{i} = p;
    cfdTime{i}    = t;

    % Extract location name from file name
    %
    % Example:
    %   K1_Plane_pressure_complete.csv
    %   -> K1
    %
    [~,baseName,~] = fileparts(cfdFiles{i});

    token = regexp(baseName,'^(K\d+)','tokens','once');

    if ~isempty(token)
        locationName = token{1};
    else
        locationName = baseName;
    end

    k = find(strcmp(locationName,legendNames),1);

    if isempty(k)
        k = mod(i-1,nColors)+1;
    end

    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(2);

    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);

    plot(t,p,...
        'LineWidth',1.0,...
        'Color',plotColor,...
        'DisplayName',['CFD ' locationName]);

    cfdNames{i} = locationName;

end

legend('show','Location','southoutside','NumColumns', 3);

%% ============================================================
% FFT FUNCTION (ROBUST)
%% ============================================================

computeNBFFT = @(sig,fs) localFFT(sig,fs,df_desired,PREF);

%% ============================================================
% NARROWBAND SPL
%% ============================================================

figure(2); hold on; grid on;
title([plotTitle ' - Narrowband SPL']);
xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
set(gca,'XScale','log');

%% EXPERIMENT FFT
fsExp = 1/mean(diff(timeExp));

% Storage for OASPL bar chart / summary table
oaspl_labels = {};
oaspl_td = [];      % time-domain OASPL (from RMS of p(t))
oaspl_psd = [];      % OASPL integrated from PSD (cross-check)
oaspl_isCFD = [];    % 0 = exp, 1 = CFD

for i = 1:length(expSignals)

    [f,NB] = computeNBFFT(expSignals{i},fsExp);

    k = chIdx(i);

    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(1);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,NB,'LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);

    %% OASPL (time domain), band-limited to [fmin fmax] via bandpass-equivalent RMS
    oaspl_td(end+1,1) = computeOASPL_TD(expSignals{i},fsExp,fmin,fmax,PREF); %#ok<SAGROW>
    oaspl_labels{end+1,1} = ['Exp ' legendNames{k}]; %#ok<SAGROW>
    oaspl_isCFD(end+1,1) = 0; %#ok<SAGROW>
end

%% CFD FFT
for i = 1:length(cfdSignals)

    fsCFD = 1/mean(diff(cfdTime{i}));

    [f,NB] = computeNBFFT(cfdSignals{i},fsCFD);

    k = find(strcmp(cfdNames{i}, legendNames),1);
    if isempty(k), k = mod(i-1,nColors)+1; end
    
    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(2);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,NB,'-','LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['CFD ' cfdNames{i}]);

    %% OASPL (time domain)
    oaspl_td(end+1,1) = computeOASPL_TD(cfdSignals{i},fsCFD,fmin,fmax,PREF); %#ok<SAGROW>
    oaspl_labels{end+1,1} = ['CFD ' cfdNames{i}]; %#ok<SAGROW>
    oaspl_isCFD(end+1,1) = 1; %#ok<SAGROW>
end

xlim([fmin fmax]);
legend('show', 'Location','southoutside', 'NumColumns', 3);

%% ============================================================
% PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' - PSD']);
xlabel('Frequency [Hz]');
ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

psdIdxCounter = 0;

%% EXP PSD
for i = 1:length(expSignals)

    seg = floor(length(expSignals{i})/8);
    w = hann(seg);

    [P,f] = pwelch(expSignals{i},w,round(seg/2),[],fsExp);

    k = chIdx(i);

    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(1);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,10*log10(P / PREF^2),'LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);

    %% OASPL cross-check via PSD integration over [fmin fmax]
    psdIdxCounter = psdIdxCounter + 1;
    oaspl_psd(psdIdxCounter,1) = computeOASPL_PSD(f,P,fmin,fmax,PREF); %#ok<SAGROW>
end

%% CFD PSD
for i = 1:length(cfdSignals)

    seg = floor(length(cfdSignals{i})/8);
    w = hann(seg);

    fsCFD = 1/mean(diff(cfdTime{i}));

    [P,f] = pwelch(cfdSignals{i},w,round(seg/2),[],fsCFD);

    k = find(strcmp(cfdNames{i}, legendNames),1);
    if isempty(k), k = mod(i-1,nColors)+1; end
    
    kColor = mod(k-1,nColors)+1;

    lab = baseLAB(kColor,:);
    lab(1) = lab(1) + Lshift(2);    
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,10*log10(P / PREF^2),'-','LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['CFD ' cfdNames{i}]);

    %% OASPL cross-check via PSD integration over [fmin fmax]
    psdIdxCounter = psdIdxCounter + 1;
    oaspl_psd(psdIdxCounter,1) = computeOASPL_PSD(f,P,fmin,fmax,PREF); %#ok<SAGROW>
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns', 3);

%% ============================================================
% OASPL SUMMARY (bar chart + table)
%% ============================================================

figure(4); hold on; grid on;
title([plotTitle ' - OASPL (' num2str(fmin) '-' num2str(fmax) ' Hz)']);
ylabel('OASPL [dB re 20 \muPa]');

barColors = zeros(length(oaspl_labels),3);

% Reconstruct per-entry color (same logic used above) so bars match line colors
ptrExp = 1;
ptrCfd = 1;
for i = 1:length(oaspl_labels)
    if oaspl_isCFD(i) == 0
        k = chIdx(ptrExp);
        kColor = mod(k-1,nColors)+1;

        lab = baseLAB(kColor,:);
        lab(1) = lab(1) + Lshift(1);
        ptrExp = ptrExp + 1;
    else
        k = find(strcmp(cfdNames{ptrCfd}, legendNames),1);
        if isempty(k), k = mod(ptrCfd-1,nColors)+1; end
        kColor = mod(k-1,nColors)+1;

        lab = baseLAB(kColor,:);
        lab(1) = lab(1) + Lshift(2);
        ptrCfd = ptrCfd + 1;
    end
    c = lab2rgb(lab);
    barColors(i,:) = max(min(c,1),0);
end

b = bar(categorical(oaspl_labels,oaspl_labels), oaspl_psd, 'FaceColor','flat');
b.CData = barColors;

% Annotate bars with both TD and PSD-integrated values
for i = 1:length(oaspl_labels)
    txt = sprintf('%.1f dB', oaspl_psd(i));
    text(i, oaspl_psd(i)/2, txt, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'middle', ...
        'Rotation',            90, ...
        'FontSize',            12, ...
        'Color',               'w', ...
        'FontWeight',          'bold');
end

ylim([0, max(oaspl_td)*1.15]);
xtickangle(45);

%% Print summary table to command window
fprintf('\n=== OASPL Summary (%.0f-%.0f Hz band) ===\n', fmin, fmax);
fprintf('%-15s %15s %15s %15s\n','Label','OASPL_TD [dB]','OASPL_PSD [dB]','Diff [dB]');
for i = 1:length(oaspl_labels)
    fprintf('%-15s %15.2f %15.2f %15.2f\n', ...
        oaspl_labels{i}, oaspl_td(i), oaspl_psd(i), oaspl_td(i)-oaspl_psd(i));
end
fprintf('\n');

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function [f,NB] = localFFT(signal,fs,df_desired,PREF)

signal = signal(:);

%% FFT length
Nfft = round(fs/df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

window = hann(Nfft);

nBlocks = floor(length(signal)/Nfft);

if nBlocks < 2
    error('Signal too short for FFT resolution.');
end

spec = zeros(Nfft,nBlocks);

for k = 1:nBlocks

    idx1 = (k-1)*Nfft + 1;
    idx2 = k*Nfft;

    x = signal(idx1:idx2);

    X = fft(x .* window);

    spec(:,k) = 2*abs(X)/Nfft;

end

Xavg = mean(spec,2);

f = (0:Nfft/2)' * (fs/Nfft);

NB = 20*log10(Xavg(1:Nfft/2+1)/PREF);

end

function OASPL = computeOASPL_TD(signal,fs,fmin,fmax,PREF)
% Computes OASPL directly from the time-domain signal using its RMS,
% after band-limiting via a zero-phase Butterworth bandpass filter to
% [fmin fmax]. This is the most direct OASPL definition:
%   OASPL = 20*log10(p_rms / PREF)
%
% If fmin/fmax span (effectively) the full available bandwidth, the
% filter step still applies cleanly since Nyquist clamps fmax.

signal = signal(:) - mean(signal);

nyq = fs/2;

loCut = max(fmin, 1e-3);          % avoid 0 Hz edge case
hiCut = min(fmax, nyq*0.999);     % stay safely below Nyquist

if hiCut <= loCut
    % Degenerate band (e.g. fmax > Nyquist and fmin close to it);
    % fall back to broadband RMS with a warning.
    warning('computeOASPL_TD:bandInvalid', ...
        'Requested band [%.1f %.1f] Hz invalid relative to fs=%.1f Hz. Using full bandwidth.', ...
        fmin,fmax,fs);
    p_rms = rms(signal);
else
    Wn = [loCut hiCut] / nyq;
    [b,a] = butter(4, Wn, 'bandpass');
    p_filt = filtfilt(b,a,signal);
    p_rms = rms(p_filt);
end

OASPL = 20*log10(p_rms / PREF);

end

function OASPL = computeOASPL_PSD(f,P,fmin,fmax,PREF)
% Cross-check: integrates the one-sided PSD (Pa^2/Hz) over [fmin fmax]
% to recover mean-square pressure, then converts to OASPL.
%   p_rms^2 = integral( P(f) df ) over the band
%   OASPL = 10*log10( p_rms^2 / PREF^2 )

mask = f >= fmin & f <= fmax;

if nnz(mask) < 2
    OASPL = NaN;
    return;
end

p_meansq = trapz(f(mask), P(mask));

OASPL = 10*log10(p_meansq / PREF^2);

end