%% It's always good to start with a clean sheet
clc, clear, close all, warning('off','all')

%% set project name
projectname = 'sort trial based on the direction of detected microsaccade';

%% prepare Toolbox
parent_folder = '/Users/baiweil/AnalysisDesk/shared_code/';
cd(parent_folder)

%% Set directions
write_dir_eye = creatDir([parent_folder 'normalized_eye_data']);
write_dir_eeg = creatDir([parent_folder 'eeg_tf']);
write_dir_fig = creatDir([write_dir_eeg filesep 'figures']);

%% sorting the trial into toward away and no mcirosaccade
subjList_shift = get_subFiles([parent_folder 'gaze_shift']); % get file of gaze shift
outfilename_event = creatDir([parent_folder filesep 'event_TAN_mini1']); 
t_i = [0.2 0.6]; % time window we use to sort trial 

trigs.left_en = [21 22];
trigs.right_en= [23 24];

for subjInd = 1:length(subjList_shift)
    load(subjList_shift{subjInd}) % load shift data
    
    % find the interesting time window
    sel_time = dsearchn(data_shift.time', t_i')';
    sel_time = [sel_time(1) : sel_time(2)];
    
    % get the gaze shift
    shift = data_shift.shift;
    
    % remove saccade whose size < 1°
    shift(abs(shift)<1) = 0;
    
    % select shift in interesting time window 
    shift_tWin = shift(:,sel_time);
    shift_tWin_raw = data_shift.shift(:,sel_time);
    
    % get trialinfo
    trialinfo = data_shift.trialinfo;
    
    % create event vector
    toward = zeros(size(shift,1),1);
    noMS = zeros(size(shift,1),1);
    away = zeros(size(shift,1),1);
    tooSmallMS = zeros(size(shift,1),1);
    
    % loop for trial
    for trlInd = 1:size(shift_tWin,1)
        dataInTrl = shift_tWin(trlInd,:);
        dataInTrl_raw = shift_tWin_raw(trlInd,:);
        
        shiftInd = find(dataInTrl ~=0); 
        tooSamllSaccInd = find(dataInTrl ~= dataInTrl_raw); 
        
        % check whether there is saccade in this time window
        if (~isempty(shiftInd))
            
            % check whether the size of the first saccade is too small
            trl_ok = true;
            if (~isempty(tooSamllSaccInd))
               trl_ok = shiftInd(1) < tooSamllSaccInd(1);
            end
            
            if trl_ok
                % find the first saccade in this time window 
                shiftValue = dataInTrl(shiftInd(1));
                
                % check the saccade is toward or away
                if ismember(trialinfo(trlInd), trigs.left_en)
                    if shiftValue < 0 
                        toward(trlInd) = 1;
                    else
                        away(trlInd) = 1;
                    end
                elseif ismember(trialinfo(trlInd), trigs.right_en)
                    if shiftValue < 0 
                        away(trlInd) = 1;
                    else
                        toward(trlInd) = 1;
                    end 
                end
            else
                tooSmallMS(trlInd) = 1;
            end 
        else
            if (~isempty(tooSamllSaccInd))
                % if there is no saccade but there is too small saccade 
               tooSmallMS(trlInd) = 1;
            else
                % the real no saccade trial
                noMS(trlInd) = 1;
            end
        end
    end
    
    event = [];
    event.sel_toward = toward;
    event.sel_away = away;
    event.sel_noMS = noMS;
    event.sel_tooSmallMS = tooSmallMS;
    
    save([outfilename_event filesep subjList_shift{subjInd}(end-7:end)] ,'event')
end
