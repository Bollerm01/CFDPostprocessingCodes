%% ============================================================
% CFD Point vs CFD Surface Comparison Tool
%
% Features:
%   - Multi-CFD point (.DAT) selection
%   - Multi-CFD surface (.CSV) selection
%   - Time window filtering
%   - Narrowband SPL (FFT averaged)
%   - PSD (Welch)
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
% CFD point = medium brightness
% CFD surface = brighter/different
Lshift = [-20 -5 +10 +20];

%% ============================================================
% USER INPUT: CFD POINT DATA (.DAT)
%% ============================================================

[cfdFiles, cfdPath] = uigetfile( ...
    {'*.dat;*.txt','CFD Point Files'}, ...
    'Select CFD POINT Files', ...
    'MultiSelect','on');

if isequal(cfdFiles,0), return; end
if ischar(cfdFiles), cfdFiles = {cfdFiles}; end

cfdPointNames = cellfun(@(x) strtok(x,'.'), cfdFiles, 'UniformOutput', false);

%% ============================================================
% USER INPUT: CFD SURFACE DATA (.CSV)
%% ============================================================

[surfFiles, surfPath] = uigetfile( ...
    {'*.csv','CFD Surface CSV Files'}, ...
    'Select CFD SURFACE Files', ...
    'MultiSelect','on');

if isequal(surfFiles,0), return; end
if ischar(surfFiles), surfFiles = {surfFiles}; end

surfNames = cellfun(@(x) strtok(x,'_'), surfFiles, 'UniformOutput', false);

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
    'CFD Point vs Surface', ...
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
% TIME HISTORY PLOT
%% ============================================================

figure(1); hold on; grid on;
title([plotTitle ' - Time History']);
xlabel('Time [s]');
ylabel('Pressure [Pa]');

%% ============================================================
% PROCESS CFD POINT DATA
%% ============================================================

cfdPointSignals = cell(length(cfdFiles),1);
cfdPointTime = cell(length(cfdFiles),1);

for i = 1:length(cfdFiles)

    fname = fullfile(cfdPath,cfdFiles{i});

    fid = fopen(fname);

    data = textscan(fid,'%f %f', ...
        'CommentStyle','#', ...
        'CollectOutput',true);

    fclose(fid);

    data = data{1};

    t = data(:,1);
    p = data(:,2);

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask) - mean(p(mask));

    cfdPointSignals{i} = p;
    cfdPointTime{i} = t;

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2); % CFD POINT

    c = max(min(lab2rgb(lab),1),0);

    plot(t,p,'-','LineWidth',1, ...
        'Color',c, ...
        'DisplayName',['CFD Point ' cfdPointNames{i}]);
end

%% ============================================================
% PROCESS CFD SURFACE DATA (NEW)
%% ============================================================

surfSignals = cell(length(surfFiles),1);
surfTime = cell(length(surfFiles),1);

for i = 1:length(surfFiles)

    fname = fullfile(surfPath,surfFiles{i});

    T = readtable(fname, 'VariableNamingRule','preserve');

    t = T.time;
    p = T.pressure_mean;

    mask = t >= tStart & t <= tEnd;

    t = t(mask);
    p = p(mask) - mean(p(mask));

    surfSignals{i} = p;
    surfTime{i} = t;

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(3); % CFD SURFACE (brighter shift)

    c = max(min(lab2rgb(lab),1),0);

    plot(t,p,'-','LineWidth',1, ...
        'Color',c, ...
        'DisplayName',['CFD Surf ' surfNames{i}]);
end

legend('show');

%% ============================================================
% FFT FUNCTION
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

%% CFD POINT FFT
for i = 1:length(cfdPointSignals)

    fs = 1/mean(diff(cfdPointTime{i}));

    [f,NB] = computeNBFFT(cfdPointSignals{i},fs);

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,NB,'LineWidth',2, ...
        'Color',c, ...
        'DisplayName',['CFD Point ' cfdPointNames{i}]);
end

%% CFD SURFACE FFT
for i = 1:length(surfSignals)

    fs = 1/mean(diff(surfTime{i}));

    [f,NB] = computeNBFFT(surfSignals{i},fs);

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(3);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,NB,'-','LineWidth',1, ...
        'Color',c, ...
        'DisplayName',['CFD Surf ' surfNames{i}]);
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

%% CFD POINT PSD
for i = 1:length(cfdPointSignals)

    seg = floor(length(cfdPointSignals{i})/8);
    w = hann(seg);

    fs = 1/mean(diff(cfdPointTime{i}));

    [P,f] = pwelch(cfdPointSignals{i}, w, round(seg/2), [], fs);

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(2);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,10*log10(P),'LineWidth',1, ...
        'Color',c, ...
        'DisplayName',['CFD Point ' cfdPointNames{i}]);
end

%% CFD SURFACE PSD
for i = 1:length(surfSignals)

    seg = floor(length(surfSignals{i})/8);
    w = hann(seg);

    fs = 1/mean(diff(surfTime{i}));

    [P,f] = pwelch(surfSignals{i}, w, round(seg/2), [], fs);

    k = mod(i-1,nColors)+1;

    lab = baseLAB(k,:);
    lab(1) = lab(1) + Lshift(3);

    c = max(min(lab2rgb(lab),1),0);

    semilogx(f,10*log10(P),'-','LineWidth',1, ...
        'Color',c, ...
        'DisplayName',['CFD Surf ' surfNames{i}]);
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns',2);

%% ============================================================
% LOCAL FFT FUNCTION
%% ============================================================

function [f,NB] = localFFT(signal,fs,df_desired,PREF)

signal = signal(:);

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