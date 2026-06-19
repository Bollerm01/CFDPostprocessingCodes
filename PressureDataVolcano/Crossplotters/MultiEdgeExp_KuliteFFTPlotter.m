%% ============================================================
% Multi-Edge Experimental Kulite Plotter
%% ============================================================

clear; clc; close all;

%% ============================================================
% CONSTANTS
%% ============================================================

PREF = 20e-6;
PSI_TO_PA = 6894.757;

sensor_sens = 0.03;   % V/psi

gain = [ ...
    65.3 65.9 65.1 67.15 65.2 66.4 ];

channelNames = { ...
    'Voltage_5','Voltage_1','Voltage_2', ...
    'Voltage_3','Voltage_4','Voltage_0' };

legendNames = {'K1','K2','K3','K4','K5','K6'};

%% ============================================================
% PERCEPTUALLY UNIFORM COLOR SYSTEM (CIE LAB)
%% ============================================================

nChannels = length(legendNames);

baseRGB = lines(nChannels);          % base channel colors
baseLAB = rgb2lab(baseRGB);          % convert to LAB space

% Dataset brightness shifts (Exp 1 = dark, Exp 2 = medium, Exp 3 = bright)
Lshift = [-36 -18 0 +18 +36];


%% ============================================================
% SELECT EXPERIMENT FILES (UP TO 3)
%% ============================================================

[expFiles,expPath] = uigetfile('*.csv', ...
    'Select UP TO 3 Experimental CSV Files', ...
    'MultiSelect','on');

if isequal(expFiles,0), return; end

if ischar(expFiles)
    expFiles = {expFiles};
end

expFiles = expFiles(1:min(5,length(expFiles)));
nExp = length(expFiles);

expNames = cellfun(@(x) split(x,{'_','.'}), expFiles, 'UniformOutput', false);
expNames = cellfun(@(x) x{1}, expNames, 'UniformOutput', false);

Texp = cell(nExp,1);
timeExpFull = cell(nExp,1);

for e = 1:nExp
    Texp{e} = readtable(fullfile(expPath,expFiles{e}), ...
        'VariableNamingRule','modify');

    timeExpFull{e} = Texp{e}.Voltage_0_Time_;
end

%% ============================================================
% CHANNEL SELECTION
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
    {'Plot Title','Start Time [s]','End Time [s]', ...
     'FFT df [Hz]','Min Frequency [Hz]','Max Frequency [Hz]'}, ...
    'Settings', [1 50], ...
    {'Experimental Kulite R/D Comparison','0','10','75','100','20000'});

if isempty(answer), return; end

plotTitle = answer{1};
tStart = str2double(answer{2});
tEnd   = str2double(answer{3});

df_desired = str2double(answer{4});
fmin = str2double(answer{5});
fmax = str2double(answer{6});

%% ============================================================
% PROCESS EXPERIMENTS
%% ============================================================

expSignals = cell(nExp,1);
expTime = cell(nExp,1);

figure(1); hold on; grid on;
title([plotTitle ' - Time History']);
xlabel('Time [s]');
ylabel('Pressure [Pa]');

for e = 1:nExp

    time = timeExpFull{e};
    mask = time >= tStart & time <= tEnd;

    time = time(mask);
    expTime{e} = time;

    expSignals{e} = cell(length(chIdx),1);

    for i = 1:length(chIdx)

        k = chIdx(i);

        V = Texp{e}.(channelNames{k});
        V = V(mask);

        system_sens = sensor_sens * gain(k);

        p = (V ./ system_sens) * PSI_TO_PA;
        p = p - mean(p);

        expSignals{e}{i} = p;

        lab = baseLAB(k,:);

        lab(1) = lab(1) + Lshift(min(e,length(Lshift)));
        
        plotColor = lab2rgb(lab);
        plotColor = max(min(plotColor,1),0);
        
        plot(time,p,'LineWidth',1.2, ...
            'Color',plotColor, ...
            'DisplayName', ...
            ['Exp ' expNames{e} ' ' legendNames{k}]);
    end
end

legend('show','Location','southoutside','NumColumns', 3);

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

for e = 1:nExp

    fsExp = 1/mean(diff(expTime{e}));

    for i = 1:length(expSignals{e})

        [f,NB] = computeNBFFT(expSignals{e}{i},fsExp);

        k = chIdx(i);

        lab = baseLAB(k,:);
        lab(1) = lab(1) + Lshift(min(e,length(Lshift)));
        
        plotColor = lab2rgb(lab);
        plotColor = max(min(plotColor,1),0);
        
        semilogx(f,NB,'LineWidth',2, ...
            'Color',plotColor, ...
            'DisplayName', ...
            ['Exp ' expNames{e} ' ' legendNames{k}]);
    end
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns', 3);

%% ============================================================
% PSD
%% ============================================================

figure(3); hold on; grid on;
title([plotTitle ' - PSD']);
xlabel('Frequency [Hz]');
ylabel('PSD [dB/Hz]');
set(gca,'XScale','log');

for e = 1:nExp

    fsExp = 1/mean(diff(expTime{e}));

    for i = 1:length(expSignals{e})

        sig = expSignals{e}{i};

        seg = floor(length(sig)/8);
        w = hann(seg);

        [P,f] = pwelch(sig,w,round(seg/2),[],fsExp);

        k = chIdx(i);

        lab = baseLAB(k,:);
        lab(1) = lab(1) + Lshift(min(e,length(Lshift)));
        
        plotColor = lab2rgb(lab);
        plotColor = max(min(plotColor,1),0);
        
        semilogx(f,10*log10(P),'LineWidth',2, ...
            'Color',plotColor, ...
            'DisplayName', ...
            ['Exp ' expNames{e} ' ' legendNames{k}]);
    end
end

xlim([fmin fmax]);
legend('show','Location','southoutside','NumColumns', 3);

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