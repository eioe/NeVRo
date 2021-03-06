%% NVR cutParts
%
% This function loads the raw and continuous EEG data (saved as EEGLAB SET
% files), extracts the MOV and NO-MOV parts, and saves them to separate
% files:
%

% 2017 (edited 2018) by Felix Klotzsche --- eioe
%

function NVR_00_cutParts()

%% 1.Set Variables
clc
%clear all

%1.1 Set different paths:

% input paths:
path_data = '../../../Data/';
path_dataeeg = [path_data 'EEG/01_raw/'];
path_in_eeg = [path_dataeeg 'full_SETs/'];

% output paths:
path_out_eeg_mov = [path_dataeeg 'mov_SETs'];
if ~exist(path_out_eeg_mov, 'dir'); mkdir(path_out_eeg_mov); end
path_out_eeg_nomov = [path_dataeeg 'nomov_SETs'];
if ~exist(path_out_eeg_nomov, 'dir'); mkdir(path_out_eeg_nomov); end


%1.2 Get data files
files_eeg = dir([path_in_eeg '*.set']);
files_eeg = {files_eeg.name};


% Define relevant events (watch out for retarded spacing):
% S 30	Space Movement Start
% S 35	Ande Movement End
% S130	Space No Movement Start
% S135	Ande No Movement End

mov_mrkrs = {'S 30' 'S 35'};
nomov_mrkrs = {'S130' 'S135'};

for isub = 1:length(files_eeg)
    
    %1.3 Launch EEGLAB:
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    % 1.4 Get subj name for getting the right event file later:
    thissubject = files_eeg{isub};
    thissubject = strsplit(thissubject, '.');
    thissubject = thissubject{1};
    
    %1.5 Set filename:
    filename = files_eeg{isub};
    filename = strsplit(filename, '.');
    filename = filename{1};
    
    
    %% 2.Load EEG data
    
    [EEG, com] = pop_loadset([path_in_eeg, filename, '.set']);
    
    % Remove ECG and GSR channels:
    EEG = pop_select( EEG,'nochannel',{'ECG' 'GSR'});
    
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    full_eeg_idx = CURRENTSET;
    
    % Cut out continuous mov and no-mov segments:
    % find timing of markers
    [ idx_mov_start] = find(strcmp({EEG.event.type}, mov_mrkrs{1}));
    [ idx_mov_end] = find(strcmp({EEG.event.type}, mov_mrkrs{2}));
    [ idx_nomov_start] = find(strcmp({EEG.event.type}, nomov_mrkrs{1}));
    [ idx_nomov_end] = find(strcmp({EEG.event.type}, nomov_mrkrs{2}));
    
    lat_mov_start = EEG.event(idx_mov_start).latency;
    lat_mov_end = EEG.event(idx_mov_end).latency;
    lat_nomov_start = EEG.event(idx_nomov_start).latency;
    lat_nomov_end = EEG.event(idx_nomov_end).latency;
    
    % Cut out and save MOV data:
    EEG = pop_select( EEG,'point',[lat_mov_start lat_mov_end] );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    mov_eeg_idx = CURRENTSET;
    
    EEG.setname = [thissubject 'mov'];
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    EEG = pop_saveset( EEG, [thissubject 'mov'] , path_out_eeg_mov);
    
    % Cut out and save NO-MOV data:
    EEG = ALLEEG(full_eeg_idx);
    EEG = pop_select( EEG,'point',[lat_nomov_start lat_nomov_end] );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    nomov_eeg_idx = CURRENTSET;
    
    EEG.setname = [thissubject 'nomov'];
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    EEG = pop_saveset( EEG, [thissubject 'nomov'] , path_out_eeg_nomov);
    
    EEG = eegh(com,EEG);
    
    %eeglab redraw;
    
end

