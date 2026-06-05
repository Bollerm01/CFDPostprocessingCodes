%% ============================================================
% CFD vs Experimental Kulite Cross Plotter
%
% Features:
%   - Multi-Kulite selection
%   - Multi-CFD file selection
%   - Time window filtering
%   - Narrowband SPL (FFT averaged)
%   - PSD (Welch)
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
% PERCEPTUALLY UNIFORM COLOR SYSTEM (CIE LAB)
%% ============================================================

nChannels = length(legendNames);

baseRGB = lines(nChannels);     % channel identity colors
baseLAB = rgb2lab(baseRGB);     % convert to LAB space

% Dataset brightness shift:
% (CFD vs Exp or multiple CFD files)
% 1 = dark, 2 = medium, 3 = bright, 4+ = progressively brighter
Lshift = [-20 -5 +10 +20];

%% ============================================================
% USER INPUT: EXPERIMENT FILE
%% ============================================================

[expFile,expPath] = uigetfile('*.csv','Select Experimental CSV');

if isequal(expFile,0), return; end

T = readtable(fullfile(expPath,expFile),...
    'VariableNamingRule','modify');

timeExpFull = T.Voltage_0_Time_;

%% ============================================================
% USER INPUT: CFD FILES (MULTI)
%% ============================================================

[cfdFiles,cfdPath] = uigetfile( ...
    {'*.dat;*.txt','CFD Files'}, ...
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

    lab = baseLAB(k,:);

    lab(1) = lab(1) + Lshift(1); % experiments = baseline dark shift
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    plot(timeExp,p,'LineWidth',1.2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);
end

%% ============================================================
% PROCESS CFD FILES
%% ============================================================

cfdSignals = cell(length(cfdFiles),1);
cfdTime = cell(length(cfdFiles),1);

figure(1);

for i = 1:length(cfdFiles)

    fname = fullfile(cfdPath,cfdFiles{i});

    fid = fopen(fname);

    data = textscan(fid,'%f %f',...
        'CommentStyle','#',...
        'CollectOutput',true);

    fclose(fid);

    data = data{1};

    t = data(:,1);
    p = data(:,2);

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask);

    p = p - mean(p);

    cfdSignals{i} = p;
    cfdTime{i} = t;

    k = find(strcmp(cfdNames{i}, cfdNames),1);
    if isempty(k), k = mod(i-1,nChannels)+1; end
    
    lab = baseLAB(k,:);
    
    % CFD brighter than experiment
    lab(1) = lab(1) + Lshift(2);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    plot(t,p,'-','LineWidth',1.0,...
        'Color',plotColor,...
        'DisplayName',['CFD ' cfdNames{i}]);
    end

legend('show');

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

for i = 1:length(expSignals)

    [f,NB] = computeNBFFT(expSignals{i},fsExp);

    k = chIdx(i);

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,NB,'LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);
end

%% CFD FFT
for i = 1:length(cfdSignals)

    fsCFD = 1/mean(diff(cfdTime{i}));

    [f,NB] = computeNBFFT(cfdSignals{i},fsCFD);

    k = find(strcmp(cfdNames{i}, cfdNames),1);
    if isempty(k), k = mod(i-1,nChannels)+1; end
    
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,NB,'-','LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['CFD ' cfdNames{i}]);
end

xlim([fmin fmax]);
legend('show', 'Location','southoutside', 'NumColumns', 2);

%% ============================================================
% PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' - PSD']);
xlabel('Frequency [Hz]');
ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

%% EXP PSD
for i = 1:length(expSignals)

    seg = floor(length(expSignals{i})/8);
    w = hann(seg);

    [P,f] = pwelch(expSignals{i},w,round(seg/2),[],fsExp);

    k = chIdx(i);

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(1);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,10*log10(P),'LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['Exp ' legendNames{k}]);
end

%% CFD PSD
for i = 1:length(cfdSignals)

    seg = floor(length(cfdSignals{i})/8);
    w = hann(seg);

    fsCFD = 1/mean(diff(cfdTime{i}));

    [P,f] = pwelch(cfdSignals{i},w,round(seg/2),[],fsCFD);

    k = find(strcmp(cfdNames{i}, cfdNames),1);
    if isempty(k), k = mod(i-1,nChannels)+1; end
    
    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);
    
    plotColor = lab2rgb(lab);
    plotColor = max(min(plotColor,1),0);
    
    semilogx(f,10*log10(P),'-','LineWidth',2,...
        'Color',plotColor,...
        'DisplayName',['CFD ' cfdNames{i}]);
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns', 2);

%% ============================================================
% LOCAL FUNCTION
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