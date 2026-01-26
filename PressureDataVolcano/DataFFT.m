function [f,p,NB,Xfsave] = DataFFT(nmics,N,fs,Wl,Wh,pt)
%UNTITLED5 Summary of this function goes here
%   Xf(:,:,j),Xf_dB(:,:,j) = Xf,Xf_dB
%   N = number of data points 4096
%   fs = acquisition fre22quency 204800
for k = 1:nmics
    h = 1/fs; %Time resolution
    T = h*N; %Time window
    df = 1/T; %Frequency resolution
    fh = fs/2; %Nyquist frequency
    t = 0:h:T-h ;  %discrete time points
    f = 0:df:fs-df; f=f';   %Set up filter parameters and filter pressure
    [b,a] = butter(5,[Wl Wh]./fh,'bandpass'); %Apply Butterworth Filter The Butterworth filter is a type of signal processing filter designed to have a frequency response that is as flat as possible in the passband. It is also referred to as a maximally flat magnitude filter 
    p(:,k) = filtfilt(b,a,pt(:,k));
  
    % p(:,k) = pt(:,k); %No Filter
    nwin = hanning(N);
    % [welch(:,k),fwelch(:,k)] = pwelch(p(:,k),nwin,[],N,fs);
    %welch = welch*fs/2;
    blocks = length(p)/(N);
    % Xf = zeros(N,blocks);
    pt_finish = 0;
    for n = 1:blocks-1
        clear x;
        pt_start = pt_finish+1;
        pt_finish = n*N;
        x = p(pt_start:pt_finish,k);
        X = fft(x.*nwin);
        Xf(:,n) = 2*abs(X)/N; %Pressure amplitude in frequency domain
        Xfsave(:,k) = mean(Xf(:,n),2); %Pressure amplitude in frequency domain
        NB(:,k) = 20*log10(mean(Xf,2)./20e-6);
    end
end
% df
end

