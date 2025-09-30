% % CONVERT XDF FILES & MAP SOUND ONSET TRIGGERS 
% ----------------------------------------------
% The code loads the EEG XDF file(s) and maps the sound onset triggers
% correctly to the EEG file and save it as .set EEGLAB files.
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 20/05/2025


clear; clc; close all;

% -------------------------------------------------------------------------
% ---------------------------- CONVERSION SETUP ---------------------------

% root path to the project
rootpath     = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% path to the data folder 
foldername  = 'Recording30092025';

% file to convert : 
% add a specific filename or 'ALL' to convert all files in folder
file2convert = 'ALL';

% -------------------------------------------------------------------------



% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')

% set path to files
filepath = fullfile(rootpath,foldername);

% create list of files to convert
if strcmp(file2convert, 'ALL')
    filelist = dir(fullfile(filepath, '*.xdf'));
else
    filelist = dir(fullfile(filepath, file2convert));
end 

display(['Files to convert: ', num2str(length(filelist))])
display('Conversion Started')

% opeing EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% loop over files to convert
for file = 1:length(filelist)
    
    % current working file 
    file2load = fullfile(filepath, filelist(file).name);
    % define setname
    namesplit = strsplit(filelist(file).name, '-');
    nrun = strrep(namesplit{5}, '_eeg.xdf', '');
    setname = [namesplit{4}, num2str(nrun)];
    display(['Converting ', setname])

    % load actual EEG file in EEGLAB
    EEG = pop_loadxdf(file2load,'streamname','Explore_DAAH_ExG')
    % set channel locs
    EEG = pop_chanedit(EEG, {'lookup','/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc'},'load',{'/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/sample_data/eeglab_chan32.locs','filetype','autodetect'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    % temporarily storing channel 7 data 
    EEG7 = EEG.data(7,:);

    % load xdf and fetch all streams
    streams = load_xdf(file2load,'HandleJitterRemoval',true);
    % stream with bela audio onsets
    BelaMarkerEEGStream = get_stream_by_name(streams, 'Explore_84D1_ExG');
    % stream with EEG signal
    ActualEEG = get_stream_by_name(streams, 'Explore_DAAH_ExG')
    % align both streams 
    out = align_stream2_to_stream1(ActualEEG.time_stamps, ActualEEG.time_series(7,:), BelaMarkerEEGStream.time_stamps, BelaMarkerEEGStream.time_series(7,:));
    EEG.data(7,:) = out.X2_aligned
    % convert audio onsets to event markers 
    EEG=convertAudioToEvents(EEG,4000);

    % replacing the channel 7 with original EEG signal
    EEG.data(7,:)=EEG7;

    % save the dataset to filepath 
    EEG.setname = setname;
    EEG.comments = '';
    EEG = pop_saveset(EEG, [EEG.setname, '.set'], filepath);

end 

display('Conversion Complete')

