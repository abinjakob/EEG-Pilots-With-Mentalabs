eeglab
PATH='/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project/Recording26092025/'
allStreams=load_xdf([PATH 'sub-P001_ses-S001_task-Oddball_run-001_eeg.xdf'],'HandleJitterRemoval',true)

EEG=pop_loadxdf([PATH 'sub-P001_ses-S001_task-Oddball_run-001_eeg.xdf'],'streamname','Explore_DAAH_ExG')
EEG = pop_chanedit(EEG, {'lookup','/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc'},'load',{'/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/sample_data/eeglab_chan32.locs','filetype','autodetect'});

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

cd('/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project/Analysis Scripts');

EEG7=EEG.data(7,:);
BelaMarkerEEGStream = get_stream_by_name(allStreams, 'Explore_84D1_ExG');
ActualEEG=get_stream_by_name(allStreams, 'Explore_DAAH_ExG')
out = align_stream2_to_stream1(ActualEEG.time_stamps, ActualEEG.time_series(7,:), BelaMarkerEEGStream.time_stamps, BelaMarkerEEGStream.time_series(7,:));
EEG.data(7,:)=out.X2_aligned
pop_eegplot( EEG, 1, 1, 1);
EEG=convertAudioToEvents(EEG,4000)
EEG.data(7,:)=EEG7;
pop_eegplot( EEG, 1, 1, 1);






EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',30,'plotfreqz',1);
EEG_both = pop_epoch( EEG, {  '1'  '2' }, [-0.5           1], 'epochinfo', 'yes');

EEG_st = pop_epoch( EEG, {  '1'   }, [-0.5           1], 'epochinfo', 'yes');
EEG_odd = pop_epoch( EEG, {    '2' }, [-0.5           1], 'epochinfo', 'yes');
EEG_bela = pop_epoch( EEG, {  'SoundOnset' }, [-0.5           1], 'epochinfo', 'yes');


figure;
for k=1:32
    subplot(4,8,k)
    plot(EEG_st.times,mean(EEG_st.data(k,:,:),3))
    hold all
    plot(EEG_odd.times,mean(EEG_odd.data(k,:,:),3))
  plot(EEG_both.times,mean(EEG_both.data(k,:,:),3))
        plot(EEG_bela.times,mean(EEG_bela.data(k,:,:),3))

end




figure;
for k=32
    plot(EEG_st.times,mean(EEG_st.data(k,:,:),3))
    hold all
    plot(EEG_odd.times,mean(EEG_odd.data(k,:,:),3))
    plot(EEG_both.times,mean(EEG_both.data(k,:,:),3))
    plot(EEG_bela.times,mean(EEG_bela.data(k,:,:),3))

end
legend({'Standard MT' 'Odd MT' ' Matlab Trigger','Bela Events'})
set(gcf,'Color','w')
box off

figure;

    plot(EEG_bela.times,mean(EEG_bela.data(25:32,:,:),3))


legend({'Bela Events '})
set(gcf,'Color','w')
box off
title(['Oddball ' num2str(EEG_bela.trials)])

figure;pop_topoplot(EEG, 1, 132,'',[1 1] ,0,'electrodes','on');