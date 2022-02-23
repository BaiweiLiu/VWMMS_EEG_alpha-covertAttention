%% It's always good to start with a clean sheet
clc, clear, close all, warning('off','all')

%% set project name
projectname = 'extract lateralisation of power in toward, away, no microsaccade, trials';

%% prepare Toolbox
parent_folder = '/Users/baiweil/AnalysisDesk/shared_code/';
cd(parent_folder)

%% Set directions
write_dir_eye = creatDir([parent_folder 'normalized_eye_data']);
write_dir_eeg = creatDir([parent_folder 'eeg_tf']);
write_dir_fig = creatDir([write_dir_eeg filesep 'figures']);

%% extract lateralisation of power 
sublist_tf = get_subFiles(write_dir_eeg); % get the eeg files
sublist_event = get_subFiles([parent_folder filesep 'event_TAN_mini1']); % get the event files
sublist_nonNan = get_subFiles([parent_folder filesep 'trial_ok_noNan']); % get the clean eye event
sublist_okEEG =get_subFiles([parent_folder filesep 'trial_keep'] ); % get the clean eeg event

% channels for left and right hemifield
chan_l = {'O1','PO7','PO3','P7','P5','P3','P1'};
chan_r = {'O2','PO8','PO4','P8','P6','P4','P2'};

GA_struct = [];
output_dir = creatDir([parent_folder  'results']);

% loop for subjects
for subjInd = 1:length(sublist_okEEG)
    
    % load all data and event 
    load(sublist_tf{subjInd})
    load(sublist_event{subjInd})
    sel_toward = logical(event.sel_toward);
    sel_away = logical(event.sel_away);
    sel_noMS = logical(event.sel_noMS);
    load(sublist_nonNan{subjInd})
    tl_ok_noNan = event.sel';
    
    load(sublist_okEEG{subjInd})
    tl_ok_eeg = event.sel';
    
    % create the clean vector
    tl_ok = tl_ok_noNan & tl_ok_eeg;
    
    % creat the condition vector
    cond = {sel_toward, sel_away, sel_noMS};
    
    % get the alpha power in different condition
    for condInd = 1:3 
        sel_cond = cond{condInd};
        
        % find left and right channel
        channel_left = match_str(data_tfr.label, chan_l);
        channel_right = match_str(data_tfr.label, chan_r);
        
        % find left and right trial
        left = ismember(data_tfr.trialinfo(:,1), trigs.left_en);
        right = ismember(data_tfr.trialinfo(:,1), trigs.right_en);
        
        % caculated toward and away signal
        a = mean(mean(data_tfr.powspctrm(left&tl_ok&sel_cond,channel_right,:,:))); % contra-chR
        b = mean(mean(data_tfr.powspctrm(right&tl_ok&sel_cond,channel_right,:,:))); % ipsi-chR
        c = mean(mean(data_tfr.powspctrm(right&tl_ok&sel_cond,channel_left,:,:))); % contra-chL
        d = mean(mean(data_tfr.powspctrm(left&tl_ok&sel_cond,channel_left,:,:))); % ipsi-chL
        
        % caculated lateralisation 
        cvsi_chR = squeeze(((a-b) ./ (a+b)) * 100);
        cvsi_chL = squeeze(((c-d) ./ (c+d)) * 100);
        data_cvsi(condInd,:,:) = (cvsi_chR + cvsi_chL) ./ 2;
    end
    GA_struct.data(subjInd,:,:,:) = data_cvsi;
end

% save data
GA_struct.time = data_tfr.time;
GA_struct.condLabel = {'toward' 'away' 'noMS'};
save([output_dir filesep 'GA_alpha_toAwNo'], 'GA_struct')