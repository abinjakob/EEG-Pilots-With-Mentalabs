% % SOUNDSCAPES TASK DATA ANALYSIS 
% --------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the soundscapes EEG data collected with Mentalab Amplifier (32 Channel)
% and plots relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the EEG (.set) file
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Epoch the data based on events and epoch periods
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute ERP for each sound file and plots them 
%
% Pre-requisits:
% - Assumes the data is in .set format (Use PROC_convertXDF_and_mapOnsets.m 
%   script before running this script)
% - Requires following functions to run: plotStyles
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 01/10/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'Recording26092025';
% XDF file to load for analysis
filename   = 'Soundscape_run001.set';

% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

% audio files
audiofiles = {'doors-01', 'office-01', 'office-02'};
% event markers 
events = {'AudioOnset'}; 
% high-pass filter 
HP = .1; HPorder = 826;                
% low-pass filter   
LP = 30; LPorder = 776; 
% epoch period 
epoch_start = -0.5; epoch_end = 1;
% reject artefactual epochs 
PRUNE = 4;

% audio binning 
epoch_duration = epoch_end;     % same as EEG epoch
nbins = 3;
plot_amps = false; 


% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 2;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = true;

% ------------------------------------------------------------------------


%% -- Pre-Processing EEG Data --

% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath); 
% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')
addpath(fullfile(rootpath, 'Audio Files'));


% -- EEG Preprocessing --
% filtering
disp(['Data Filtering: LP = ', num2str(LP), ' HP = ', num2str(HP)])
EEG = pop_firws(EEG, 'fcutoff', LP, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', LPorder);
EEG = pop_firws(EEG, 'fcutoff', HP, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', HPorder);
% re-referencing
if re_ref == 1
    % re-referencing to CAR
    EEG = pop_reref(EEG, [], 'refstate',0);
    display('Re-referenced to CAR')
elseif re_ref == 2
    % re-referencing to mastoids
    EEG = pop_reref( EEG, [11 15] );
    display('Re-referenced to Mastoids')
end 

% copy of the full EEG data 
EEG_all = EEG; 
% initialise variables 
tasknames = {}; eegdata = []; epochidx_all = []; nepochs = 0; 

% -- Setting up Plots --
% set plot file names
namesplit = strsplit(filename, '_');
plotfile = [namesplit{1},'_'];
% create figure folder if doesn't exist
plotfolder = fullfile(filepath,'Figures');
if ~exist(plotfolder, 'dir')
    mkdir(plotfolder);
    display('New Folder Created for Saving Plots')
end
% import plot styles
% ![ Important: requires the custom function 'plotStyles' ]
s = plotStyles();
%clr = ['r', 'b', 'm', 'g', 'c', 'k'];
if re_ref == 2
    channels2plot = [8 4 9 13];
else 
    channels2plot = [8 4 9 14];
end 


% loop over audio files
for iFile=1:length(audiofiles)

    % load the soundscape file and get the audio duration
    audiofile = fullfile(rootpath, 'Audio Files', [audiofiles{iFile}, '.mp3']);
    [y, Fs] = audioread(audiofile);
    duration = length(y) / Fs; 

    % select the EEG segment during the audio 
    startEventIdx = find(strcmp({EEG_all.event.type}, audiofiles{iFile}));
    st = EEG_all.event(startEventIdx).latency;
    ed = st + round(duration * EEG_all.srate) - 1;
    EEG = pop_select( EEG_all, 'point',[st ed] ); 

    % get audio onsets from audio file 
    % ![ Important: requires the custom function 'onset_detect_audio' ]
    audiofile2load = [audiofiles{iFile}, '.mp3'];
    display(['Computing audio onsets for file ', audiofile2load])
    [onsets, info] = onset_detect_audio(audiofile2load);
    % convert onsets to samples
    onset_samples = round(onsets * EEG.srate);
    onset_samples = onset_samples';
    % create new events 
    new_events = struct( ...
        'type', repmat({'AudioOnset'}, 1, length(onset_samples)), ...
        'latency', num2cell(onset_samples), ...
        'duration', num2cell(zeros(1,length(onset_samples))) ... 
    );
    % replace EEG events with new onset events
    EEG.event = new_events;
    % events with out-of-bounds latencies and removing from events and onsets
    badevents = find([EEG.event.latency] < 1 | [EEG.event.latency] > EEG.pnts); 
    onsets(badevents) = [];
    EEG = eeg_checkset(EEG, 'eventconsistency');

    % epoching 
    EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', audiofiles{iFile},'epochinfo', 'yes');
    % remove artifact epochs
    %EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
    EEG = eeg_checkset(EEG);
    % baseline correction
    baseline = [epoch_start*1000 0];  
    EEG = pop_rmbase(EEG, baseline);
    EEG = eeg_checkset(EEG);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    %eegdata = cat(3, eegdata, EEG.data);

    % binning audio based on amplitude
    bins = binAudioAmplitudes(y, onsets, Fs, epoch_duration, nbins, plot_amps);

    % setup plot
    figure('Units', 'centimeters', 'Position', s.figsize); 
    hold on
    for b=1:nbins
        plot(EEG.times, mean(mean( EEG.data(channels2plot,:,bins{b}.epochidx) ,3),1), 'LineWidth', s.plt_linewidth)
    end 
    plot(EEG.times, mean(mean( EEG.data(channels2plot,:,:) ,3),1), 'k', 'LineWidth', s.plt_linewidth)
    xlabel('Time (ms)'); ylabel('Amplitude (µV)');
    % create legend
    binlabels = arrayfun(@(x) sprintf('bin %d', x), 1:nbins, 'UniformOutput', false);
    legend([binlabels, {'average'}]);
    title([audiofiles{iFile}, ' ERP'])
    set(gca, 'FontSize', s.plt_fontsize);

    % save plot
    if save_fig
        plotname = ['binnedERP_', audiofiles{iFile}];
        plotsave = fullfile(plotfolder, [plotfile, plotname, '.png']);
        saveas(gcf, plotsave)
    end 

end 



