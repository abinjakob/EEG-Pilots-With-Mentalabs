% SIMPLE AUDITORY ODDBALL TASK - USING PSYCHTOOLBOX
% -------------------------------------------------
% This script implements a basic Auditory Oddball paradigm where a sequences 
% of standard or deviant tones are presented. Trial markers are sent via 
% LabStreamingLayer (LSL) ("1" for standard, "2" for deviant).
% 
% Psychtoolbox's PsychPortAudio engine is used to generate the tones with high 
% timing precision, minimizing audio latency and jitter.
%
% Pre-requisits:
% - LabStreamLayer
% - PsychToolBox
%
% 
% Author(s):  Translational Psychology Lab
%             Carl von Ossietzky Universität Oldenburg
% Date     :  24/09/2025


clear; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% stimulus parameters
amp = 0.5;                          % amplitude of tone (0-1)
duration = 0.04;                    % duration of tone in seconds 
freqs = [880 1760];                 % frequencies for both toness in Hz

% experiment parameters
minITI = 1;                         % minimum inter trial interval
ntrials = 500;                      % total number of trials 
startwait = 20;                     % initial wait period before experiment begins 

% ------------------------------------------------------------------------

% initialize LSL 
disp('Loading LSL library...');
lib = lsl_loadlib();

% create a new LSL marker stream 
disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outlet = lsl_outlet(info);

% PsychPortAudio setup
InitializePsychSound(1);                                       % 1 = low-latency mode
fs = 44100;                                                    % sampling rate (standard)
nrchannels = 1;                                                % mono
pahandle = PsychPortAudio('Open', [], 1, 1, fs, nrchannels);   % mode=1 playback only, latency=1

% generate stimuli
t = 0:1/fs:duration;
sound1 = amp * sin(2*pi*freqs(1)*t);
sound2 = amp * sin(2*pi*freqs(2)*t);

% wait before starting
disp(['Experiement will start in ',num2str(startwait),' sec...']);
WaitSecs(startwait); 


% -- main task loop -- 
for k = 1:ntrials
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
    % 1=play once, 0=start immediately, 1=return timestamp
    startTime = PsychPortAudio('Start', pahandle, 1, 0, 1); 
    
    % push LSL marker **exactly at audio onset**
    outlet.push_sample({marker});
    
    % wait for playback to finish
    PsychPortAudio('Stop', pahandle, 1);
    
    % wait random ITI
    WaitSecs(minITI + rand);
end

% cleanup
PsychPortAudio('Close', pahandle);
disp('Experiment Complete');

