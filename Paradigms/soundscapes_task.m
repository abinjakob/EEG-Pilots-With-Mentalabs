%% PLAY MULTIPLE MP3 FILES WITH LSL MARKERS
% --------------------------------------------------
% This script plays all MP3 files in a specified folder using 
% Psychtoolbox's PsychPortAudio and sends a marker via LSL 
% immediately before each playback.
%
% Dependencies:
% - LabStreamingLayer (LSL) MATLAB interface
% - Psychtoolbox (with PsychPortAudio enabled)
%
% Notes:
% - Marker is the filename of the MP3 being played.
% - All MP3 files in the folder are played sequentially.
% - Audio is played with low latency using PsychPortAudio.
%
% Author : Abin Jacob
% Date   : 24/09/2025
% --------------------------------------------------

%% Initialize LSL
disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'AudioPlaybackStream','Markers',1,0,'cf_string','audioplaybacksource01');
outlet = lsl_outlet(info);

%% Set folder path containing MP3 files
audioFolder = fullfile(pwd, 'audio_files');  % <-- change to your folder
fileList = dir(fullfile(audioFolder, '*.mp3'));

if isempty(fileList)
    error('No MP3 files found in folder: %s', audioFolder);
end

%% Initialize PsychPortAudio
InitializePsychSound(1); % Request low-latency mode

% We'll open the device dynamically per file to handle different sample rates
for k = 1:length(fileList)
    % Load file
    filePath = fullfile(audioFolder, fileList(k).name);
    [audioData, fs] = audioread(filePath);
    audioData = audioData';  % [channels x samples]
    nrchannels = size(audioData,1);

    % Open device for this file's sample rate & channels
    pahandle = PsychPortAudio('Open', [], 1, 1, fs, nrchannels);
    PsychPortAudio('FillBuffer', pahandle, audioData);

    % Send marker BEFORE playback (use filename as marker)
    marker = fileList(k).name;
    disp(['Sending marker: ' marker]);
    outlet.push_sample({marker});

    % Start playback
    startTime = PsychPortAudio('Start', pahandle, 1, 0, 1);
    disp(['Playback started for ' marker ' at time: ' num2str(startTime)]);

    % Wait until finished
    PsychPortAudio('Stop', pahandle, 1);
    PsychPortAudio('Close', pahandle);

    % Short pause between files
    WaitSecs(1);
end

disp('All files played successfully.');
