%% NVR Downsample and apply PREP
%
% Downsamples the data to 250Hz and applies PREP pieline. 
% For details on the PREP pipe plese see: 
% http://vislab.github.io/EEG-Clean-Tools/
%
% For the specific parameters used here, plese see below.
%
%
% 2017 & 2018 by Felix Klotzsche and Alberto Mariola



function NVR_02_DS_PREP(m_cond)

%% 1.Set Variables

clc
clear all

% Which condition?
mov_cond = m_cond;

%1.1 Set different paths:
% input paths:
path_data = '../../../Data/';
path_data_eeg = [path_data 'EEG/'];
path_in_eeg = [path_data_eeg '01_raw/' mov_cond '_SETs/']; 

% output paths:
path_out_eeg = [path_data_eeg '02_PREP/' mov_cond '/'];
if ~exist(path_out_eeg, 'dir'); mkdir(path_out_eeg); end
path_reports = [path_out_eeg 'reports/'];
if ~exist(path_reports, 'dir'); mkdir(path_reports); end


%1.2 Get data files
files_eeg = dir([path_in_eeg '*.set']);
files_eeg = {files_eeg.name};

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%%

for isub = 1:length(files_eeg)
    
    %1.5 Set filename:
    filename = files_eeg{isub};
    filename = strsplit(filename, '.');
    filename = filename{1};
    
    
    %% 2.Import EEG data
    [EEG, com] = pop_loadset([path_in_eeg, filename, '.set']);
    EEG = eegh(com,EEG);
    EEG.setname=filename;
    
    %% 3.Resample to 250 Hz
    % Downsample data.
    NewSamplingRate = 250;
    [EEG, com] = pop_resample(EEG, NewSamplingRate);
    EEG = eegh(com,EEG);
    
    % prepare some parameters for PREP pipeline:
    % In order to exclude channels which are not EEG:
    non_eeg_chans = [];
    non_eeg_ops = {'HEOG', 'VEOG', 'GSR', 'ECG'};
    for neox = 1:numel(non_eeg_ops)
        idx = find(strcmp({EEG.chanlocs.labels}, non_eeg_ops{neox}));
        if ~isempty(idx)
            non_eeg_chans(end+1) = idx;
        end
    end
    reref_chans = setdiff(1:EEG.nbchan, non_eeg_chans);
    eval_chans = reref_chans; %usually same as reref_chans
    
    % make sure not to reref ECG, GSR:
    non_head_chans = [];
    non_head_ops = {'GSR', 'ECG'};
    for nhox = 1:numel(non_head_ops)
        idx = find(strcmp({EEG.chanlocs.labels}, non_head_ops{nhox}));
        if ~isempty(idx)
            non_head_chans(end+1) = idx;
        end
    end
    rerefed_chans = setdiff(1:EEG.nbchan, non_head_chans);
    
    %% 4. PREP Pipeline
    EEG = pop_prepPipeline(EEG,struct(...
        'ignoreBoundaryEvents', true, ... 
        'referenceChannels', reref_chans, ...
        'evaluationChannels',eval_chans, ...
        'rereferencedChannels', rerefed_chans, ...
        'ransacOff', false, ...
        'ransacSampleSize', 50, ...
        'ransacChannelFraction', 0.25, ...
        'ransacCorrelationThreshold', 0.75, ...
        'ransacUnbrokenTime', 0.4, ...
        'ransacWindowSeconds', 5, ...
        'srate', EEG.srate, ...
        'robustDeviationThreshold', 5, ...
        'correlationWindowSeconds', 1, ...
        'highFrequencyNoiseThreshold', 5, ...
        'correlationThreshold', 0.4, ...
        'badTimeThreshold', 0.05, ... % change from default (0.01) due to short data length
        'maxReferenceIterations', 4, ...
        'referenceType', 'Robust', ...
        'reportingLevel', 'Verbose', ...
        'interpolationOrder', 'Post-reference', ....
        'meanEstimateType', 'Median', ...
        'samples', EEG.pnts, ....
        'lineNoiseChannels', [1:32], ...
        'lineFrequencies', [50  100], ...
        'Fs', 250, ...
        'p', 0.01, ....
        'fScanBandWidth', 2, ...
        'taperBandWidth', 2, ...
        'taperWindowSize', 4, ...
        'pad', 0, ...
        'taperWindowStep', 1, ...
        'fPassBand', [0  125], ...
        'tau', 100, ...
        'maximumIterations', 10, ...
        'cleanupReference', false, ...
        'keepFiltered', true, ...
        'removeInterpolatedChannels',false, ...
        'reportMode', 'normal', ...
        'publishOn', true, ...
        'sessionFilePath', strcat(path_reports, filename,'_Report.pdf'), ...
        'summaryFilePath', strcat(path_reports, filename,'_Summary.html'), ...
        'consoleFID', 1));
    
    %set(gcf,'Visible','off') ;
    %EEG = pop_saveset( EEG, [filename  '_PREP_Removed.set'] , prep_path);
    EEG = pop_saveset( EEG, [filename  '_PREP.set'] , path_out_eeg);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    
    % Find all windows of type figure, which have an empty FileName attribute.
    allPlots = findall(0, 'Type', 'figure', 'FileName', []);
    % Close.
    delete(allPlots);
    
    %% 5. Create and Update "Interpolated Channels" list
    fid = fopen([path_reports 'interpChans_PREP_' mov_cond '.csv'], 'a') ;
    c = {filename, ...
        sprintf('%s', num2str(EEG.etc.noiseDetection.interpolatedChannelNumbers)), ...
        sprintf('%i',length(EEG.etc.noiseDetection.interpolatedChannelNumbers))};
    fprintf(fid, '%s,%s,%s,\n',c{1,:}) ;
    fclose(fid);
    
    
end


