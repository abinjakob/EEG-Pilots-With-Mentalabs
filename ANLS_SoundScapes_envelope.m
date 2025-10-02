clear all; clc; close all;

% files & fodlers
foldername = 'Recording30092025';
filename   = 'Soundscape_run001.set';
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% audio files
audiofiles = {'doors-01', 'office-01', 'office-02'};
% markers 
events = {'SoundOnset'}; 

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath);
EEG_all = EEG;


%% check audio files

i = 1;

% load audio file
audiofile = fullfile(rootpath, 'Audio Files', [audiofiles{i}, '.mp3']);
[y, Fs] = audioread(audiofile);
duration = length(y) / Fs; 

% select the EEG segment during the audio 
startEventIdx = find(strcmp({EEG_all.event.type}, audiofiles{i}));
st = EEG_all.event(startEventIdx).latency;
ed = st + round(duration * EEG_all.srate) - 1;
EEG = pop_select(EEG_all, 'point',[st ed]); 

% time vec for audio
timevec = linspace(0,duration, length(y));

% plot audio and bela onsets 
figure;
hold on
plot(timevec, y)
plot([EEG.event.latency]/EEG.srate, zeros(length(EEG.event)), 'd')

% differences between onsets
figure; 
hist(diff([EEG.event.latency]/EEG.srate))


figure; 
plot(timevec, y(:,1))
hold on
plot(timevec, abs(hilbert(y(:,1))))

%%

env = abs(hilbert(y(:,1)));
win = round(0.2*Fs);                  
env_smooth = movmean(env, win);

figure; 
plot(timevec, y(:,1))
hold on
plot(timevec, env_smooth, 'r','LineWidth',2)

%%
[pks, locs] = findpeaks(env_smooth, 'MinPeakHeight', .03, 'MinPeakDistance', round(1*Fs));
onset_times = timevec(locs);

figure; hold on
plot(timevec, y(:, 1))
plot(timevec, env_smooth, 'r','LineWidth',2)
plot(onset_times, zeros(length(onset_times)), 'yd')


%%




onset_samples = round(onset_times * EEG.srate);

% create new events 
new_events = struct( ...
    'type', repmat({'AudioOnset'}, 1, length(onset_samples)), ...
    'latency', num2cell(onset_samples), ...
    'duration', num2cell(zeros(1,length(onset_samples))) ... 
);


% append to EEG events
EEG.event = [EEG.event, new_events];
EEG = eeg_checkset(EEG, 'eventconsistency');

% sort by latency
[~, idx] = sort([EEG.event.latency]);
EEG.event = EEG.event(idx);



