%% NVR_08_CSP
% 2017 by Felix Klotzsche* and Alberto Mariola
% *: main contribution
%
%This script applies CSP to the data and stores the results.
%
% Arguments: - cropstyle
%            - mov_cond
%            - source for alpha peak information (defaults to mov_cond)
%            - show plots? (defaults to TRUE)


function NVR_08_CSP(cropstyle, mov_cond, varargin)

%% check input:
if ((nargin > 3) && (logical(varargin{2})))
    plot_results = true;
else
    plot_results = false;
end
if ((nargin > 2) && (~isempty(varargin{1})))
    alphaPeakSource = varargin{1};
else
    alphaPeakSource = mov_cond;
end


%1.1 Set different paths:
% as BCLILAB will change the pwd, I change the relative paths here:
rand_files = dir(); %get files in current dir to get link to folder;
path_orig = rand_files(1).folder;
path_data = [path_orig '/../../../Data/'];
path_dataeeg =  [path_data 'EEG/'];
path_in_eeg = [path_dataeeg '07_SSD/' mov_cond '/' cropstyle '/narrowband/'];
path_in_SSDcomps = [path_dataeeg '07_SSD/' mov_cond '/'];

% output paths:
path_out_eeg = [path_dataeeg '08.6_CSP_10f/' mov_cond '/' cropstyle '/'];
if ~exist(path_out_eeg, 'dir'); mkdir(path_out_eeg); end
path_out_summaries = [path_out_eeg '/summaries/'];
if ~exist(path_out_summaries, 'dir'); mkdir(path_out_summaries); end

%1.2 Get data files
files_eeg = dir([path_in_eeg '*.set']);
files_eeg = {files_eeg.name};

% Get the SSD comp selection table:
SSDcomps_file = dir([path_in_SSDcomps 'SSD_selected_components_*.csv']);
SSDcomps_tab = readtable([path_in_SSDcomps SSDcomps_file.name]);
SSDcomps_tab = table2struct(SSDcomps_tab);
for p = 1:size(SSDcomps_tab,1)
    if p<10
        p_str = ['NVR_S0' num2str(p)];
    else
        p_str = ['NVR_S' num2str(p)];
    end
    SSDcomps_tab(p).participant = p_str;
end

% Launch BCILAB:

bcilab;

% prepare main figures:
h1 = figure('Visible','Off');
h2 = figure('Visible','Off');

nsubs = length(files_eeg);
ncols = 1;
nrows = ceil(nsubs/ncols);

struct_classAccs = [];

isub_rel = 0;
for isub = (1:nsubs)
    
    %1.3 Launch EEGLAB:
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    
    % 1.4 Get subj name for getting the right event file later:
    thissubject = files_eeg{isub};
    thissubject = strsplit(thissubject, mov_cond);
    thissubject = thissubject{1};
    %thissubject = 'NVR_S06';
    
    fprintf(['###########################################\n\n' ...
        'Starting subject: ' thissubject '\n\n' ...
        '###########################################\n\n']);
    
    %1.5 Set filename:
    filename = strcat(thissubject, ...
        mov_cond, ...
        '_PREP_', ...
        cropstyle, ...
        '_eventsaro_rejcomp_SSD_narrowband');
    filename = char(filename);
    
    % 2.Import EEG data
    [EEG, com] = pop_loadset([path_in_eeg, filename '.set']);
    EEG = eegh(com,EEG);
    eeglab redraw;
    
    % Get the individually selected SSD components:
    idx = find(strcmp({SSDcomps_tab.participant}, thissubject));
    SSD_comps =  SSDcomps_tab(idx).selected_comps;
    SSD_comps_arr = str2num(SSD_comps);
    SSD_comps_ch = ['[' SSD_comps ']']; %transform to char
    % Have to save it in base workspace so that bcilab finds it:
    assignin('base','SSD_comps_ch',SSD_comps_ch);
    if (isnan(SSDcomps_tab(idx).n_sel_comps) || ...
            SSDcomps_tab(idx).n_sel_comps < 4)
        warning(['Not enough valid components found for ' thissubject '!']);
        continue
    end
    
    % Get SSD unmixing matrix:
    SSD_W = EEG.etc.SSD.W'; % needs to be transposed for left multiplication
    % Have to save it in base workspace so that bcilab finds it:
    assignin('base','SSD_W',SSD_W);
    
    % Define approach:
    approach_CSP = {'CSP' ...
        'SignalProcessing', { ...
            'Resampling', 'off' ...
            'Projection', { ...
                'ProjectionMatrix', 'SSD_W' ...
                'ComponentSubset', 'SSD_comps_ch'} ...
        'FIRFilter', 'off' ...
        'EpochExtraction', { ...
            'TimeWindow', [-0.5 0.5]}} ...
        'Prediction', { ...
            'FeatureExtraction', { ...
            'PatternPairs', 2}}};
    
    % Load/link data SET to BCILAB:
    isub_data = io_loadset([path_in_eeg, filename '.set']);
    
    % train the model and extract results of the CV:
    % PLS NOTICE: NOT TO LOOSE EPOCHS AT THE BOUNDARIES OF THE RECORDING,
    % WE CHANGED THE CODE IN BCILAB/bci_train.m TO NOT REQUIRE "SAFETY"
    % MARGINS. THE ACCORDING SETTING CAN BE CHANGED IN LINE 731 OF THE
    % ACCORDING SOURCE (BCILAB/bci_train.m): 
    % IF YOU RUN OUR ANALYSES WITH THE UNMODFIED BCILAB SOURCE, THE RESULTS
    % OF THE CV WILL ONLY VERY SLIGHTLY VARY (mean accuracies changed by 
    % ~0.3% in our tests).
    % BUT YOU WILL END UP WITH SOME FOLDS THAT HAVE <18 SAMPLES IN THE TEST
    % SET. TO EASEN FURTHER STATISTICAL ANALYSES AND THE UNDERSTANDING OF
    % THE READERS, WE DECIDED TO DROP THE MARGINS TO END UP WITH 10x18 TEST
    % SAMPLES. IN OUR CASE DROPPING THE MARGINS SHOULD BE UNPROBLEMATIC AS
    % NO FILTERING IS APPLIED BY BCILAB. 
    [trainloss,model,stats] = bci_train('Data',isub_data, ...
        'Approach',approach_CSP, ...
        'EvaluationScheme',[10], ... %[3 10]: 3x10-fold CV;  'loo': leave-one-out
        'TargetMarkers',{'1','3'});
    
    % save to .SET files:
    EEG.etc.CSP.trainloss = trainloss;
    EEG.etc.CSP.model = model;
    EEG.etc.CSP.stats = stats;
    
    pop_saveset(EEG, [filename '_CSP.set'] , path_out_eeg);
    
    % Save to global .mat file:
    
    CSP_A = model.featuremodel.patterns;
    CSP_W = model.featuremodel.filters;
    SSD_A_sel = EEG.etc.SSD.A(:,SSD_comps_arr);
    SSD_W_sel = SSD_W(SSD_comps_arr,:);
    
    CSP_results.results(isub).participant = thissubject;
    CSP_results.results(isub).trainloss = trainloss;
    CSP_results.results(isub).model = model;
    CSP_results.results(isub).stats = stats;
    CSP_results.results(isub).weights.CSP_A = CSP_A;
    CSP_results.results(isub).weights.CSP_W = CSP_W;
    CSP_results.results(isub).weights.SSD_A_sel = SSD_A_sel;
    CSP_results.results(isub).weights.SSD_W_sel = SSD_W_sel;
    CSP_results.chanlocs = EEG.chanlocs;

    save([path_out_summaries 'CSP_results.mat'], 'CSP_results');
    
    struct_classAccs(isub).ID = thissubject;
    struct_classAccs(isub).acc = 1 - trainloss;
    
    % Plot patterns:
    isub_rel = isub_rel + 1;
    patterns_comb = CSP_A * SSD_A_sel';
%     
     set(0, 'CurrentFigure', h1);
     subplot(nrows, ncols, isub_rel);
% %     set(subplot(nrows, ncols * 2, isub*2-1), ...
% %         'Position', [0.05, 0.7 * isub, 0.92, 0.27])
     topoplot(patterns_comb(1,:), EEG.chanlocs);
%     set(gca, 'OuterPosition', [0, 0.02*(isub), 0.018, 0.018])
     title([thissubject], 'Interpreter', 'none')
     
     set(0, 'CurrentFigure', h2);
     subplot(nrows, ncols, isub_rel);
% %     set(subplot(nrows, ncols * 2, isub*2-1), ...
% %         'Position', [0.05+ 0.8, 0.7 * isub, 0.92, 0.27])
     topoplot(patterns_comb(4,:), EEG.chanlocs);
%     set(gca, 'OuterPosition', [0.4, 0.02*(isub), 0.018, 0.018])
     title([thissubject], 'Interpreter', 'none')
%     title(['Accuracy: ', num2str(1- trainloss)]);
    
    % saveas(gcf, [path_out_summaries thissubject '.png'], 'png');
    % close(gcf);
end

saveas(h1, [path_out_summaries 'topoplots_comp1.png'], 'png');
saveas(h2, [path_out_summaries 'topoplots_comp4.png'], 'png');

table_classAccs = struct2table(struct_classAccs);
writetable(table_classAccs, [path_out_summaries '\_summary.csv']);

% back to old pwd:
cd(path_orig);