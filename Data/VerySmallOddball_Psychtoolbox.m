clear; clc; close all;

% initialize LSL
disp('Loading LSL library...');
lib = lsl_loadlib();

% make a new LSL marker stream 
disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outlet = lsl_outlet(info);

% PsychPortAudio setup
InitializePsychSound(1);   % 1 = low-latency mode
fs = 44100;                % sampling rate (standard)
nrchannels = 1;            % mono
pahandle = PsychPortAudio('Open', [], 1, 1, fs, nrchannels); % mode=1 playback only, latency=1

% stimulus parameters
amp = 0.5;                 % amplitude (0-1)
duration = 0.04;           % duration in seconds (40 ms)
freqs = [880 1760];        % frequencies in Hz
minITI = 1;                % minimum inter trial interval
ntrials = 500;             % total number of trials 
startwait = 20;            % initial wait period before experiment begins 

% generate stimuli
t = 0:1/fs:duration;
sound1 = amp * sin(2*pi*freqs(1)*t);
sound2 = amp * sin(2*pi*freqs(2)*t);

% wait before starting
disp('Waiting to Start...');
WaitSecs(startwait); 

% main trial loop
for k = 1:500
    % Random selection
    if rand > 0.2
        s = 1;
        marker = '1';
        soundData = sound1;
    else
        s = 2;
        marker = '2';
        soundData = sound2;
    end
    
    % fill the audio buffer
    PsychPortAudio('FillBuffer', pahandle, soundData);

    % start playback; return timestamp of actual audio onset
    startTime = PsychPortAudio('Start', pahandle, 1, 0, 1); % 1=play once, 0=start immediately, 1=return timestamp
    
    % push LSL marker **exactly at audio onset**
    outlet.push_sample({marker});
    
    % wait for playback to finish
    PsychPortAudio('Stop', pahandle, 1);
    
    % wait random ITI
    WaitSecs(minITI + rand);
end

% cleanup
PsychPortAudio('Close', pahandle);
disp('Finished experiment.');
