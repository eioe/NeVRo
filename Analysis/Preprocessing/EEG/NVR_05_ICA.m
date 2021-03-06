%% NVR_05_ICA
function NVR_05_ICA(cropstyle, mov_cond, varargin) 
%
% NVR_05_ICA(cropstyle, mov_cond, icatype)
%
% ICA decemposition of the data (after removing noisy epochs). 
% in first parameter of <varargin> the ICA type can be specified. Defaults 
% to runica (Infomax) which we also used. Other ICA types have not been
% tested.
%
% INPUT: 
%       cropstyle        (string): 'SBA' or 'SA' (with or without break)
%       mov_cond         (string): 'mov' or 'nomov'
%                        data from the movement or the no-movement
%                        condition?
%       icatype          (string): which ICA shall be run on the data.
%                        Defaults to 'runica' (INFOMAX). Other ICA types 
%                        have not been tested.
%

% 2018: Felix Klotzsche --- eioe

%% 1.Set Variables
%clc
%clear all

if nargin>2
    icatype = varargin{1};
else
    icatype = 'runica';
end

%1.1 Set different paths:
path_data = '../../../Data/';
path_dataeeg =  [path_data 'EEG/'];
path_in_eeg = [path_dataeeg '04_eventsAro/' mov_cond '/' cropstyle '/']; 

% output paths:
path_out_eeg = [path_dataeeg '05_cleanICA/' mov_cond '/' cropstyle '/'];
if ~exist(path_out_eeg, 'dir'); mkdir(path_out_eeg); end
path_reports = [path_out_eeg 'reports/'];
if ~exist(path_reports, 'dir'); mkdir(path_reports); end

%1.2 Get data files
files_eeg = dir([path_in_eeg '*.set']);
files_eeg = {files_eeg.name};


% Create report file:
fid = fopen([path_reports 'rejected_epos.csv'], 'a') ;
fprintf(fid, 'ID,n_epos_rejected,epos_rejected\n') ;
fclose(fid);

discarded = {};
discarded_mat = zeros(length(files_eeg),20);
counter = 0;



for isub = 1:length(files_eeg) % 1:length(files_eeg)

    tic
    
    %1.3 Launch EEGLAB:
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    % 1.4 Get subj name for getting the right event file later:
    thissubject = files_eeg{isub};
    thissubject = strsplit(thissubject, mov_cond);
    thissubject = thissubject{1};    
    
    %1.5 Set filename:
    filename = strcat(thissubject, mov_cond, '_PREP_', cropstyle, '_eventsaro'); 
    filename = char(filename);
    
    %% 2.Import EEG data
    [EEG, com] = pop_loadset([path_in_eeg, filename '.set']);
    EEG = eegh(com,EEG);
    eeg_rank = rank(EEG.data);
    
    % Call helper func to reject noisy epochs:
    % arg1: EEG, arg2: threshold (in mV), arg3: manual check?
    EEG = NVR_S01_prep4ICA(EEG, 100, 0);
    
    rej_epos = EEG.etc.rejepo_thresh;
    
    counter = counter+1;
    discarded_mat(counter,1:length(rej_epos)) = rej_epos;
    discarded{counter} = rej_epos;
    
    %% 5. Create and Update "Rejected epochs" list
    fid = fopen([path_reports 'rejected_epos.csv'], 'a') ;
    sub_name = strsplit(filename, '_');
    sub_name = [sub_name{1} '_' sub_name{2}];
    epos = strjoin(arrayfun(@(x) num2str(x),rej_epos,'UniformOutput',false),'-');
    c = {sub_name, ...
        sprintf('%i',length(rej_epos)), ...
        sprintf('%s', epos)};
    fprintf(fid, '%s,%s,%s\n',c{1,:}) ;
    fclose(fid);
    
    % for subjects with too many rejected epochs, running an ICA on the 
    % shortened data, does not make sense. Therefore, we skip these:
    if EEG.etc.rejepo_overkill
        toc
        continue
    end

    % run ICA:
    EEG = pop_runica(EEG, ... 
        'icatype', icatype, ... 
        'extended',1, ... 
        'interupt','on', ...
        'pca',eeg_rank);
    
    EEG = eegh(com,EEG);
    EEG.setname=filename;
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    EEG = pop_saveset(EEG, [filename  '_cleanICA.set'] , path_out_eeg);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    % give out time elapsed:
    ela_time = toc;
    ela_time = ela_time/60;
    
    fprintf('\n\n\n\n This round took %f minutes \n\n\n', ela_time);
    
        
end