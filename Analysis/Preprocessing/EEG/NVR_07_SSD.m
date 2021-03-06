%% NVR_07_SSD
function NVR_07_SSD(cropstyle, mov_cond, varargin)
%
% NVR_07_SSD(cropstyle, mov_cond, alphaPeakSource, plot)
%
% Run Spatio-Spectral Decomposition (Nikulin et al., 2011) on the data.
%
% INPUT:
%       cropstyle        (string): 'SBA' or 'SA' (with or without break)
%       mov_cond         (string): 'mov' or 'nomov'
%                        data from the movement or the no-movement
%                        condition?
%       alphaPeakSource  (string): 'rs' (=restingstate), 'nomov', or 'mov'
%                        Picks the individual alpha peak which has either
%                        been calculated from the resting state (eyes
%                        closed) data, movement, or no movement condition
%                        data. Defaults to mov_cond, i.e. picks the peak
%                        which has been calculated from the same data as is
%                        going into this processing step.
%       plot             (logical): shall the results be plotted?

% 2019: Felix Klotzsche (eioe) & Alberto Mariola

% % References:
%
% Nikulin VV, Nolte G, Curio G. A novel method for reliable and fast
% extraction of neuronal EEG/MEG oscillations on the basis of spatio-
% spectral decomposition.
% NeuroImage, 2011, 55: 1528-1535.
%
% Haufe, S., Dahne, S., & Nikulin, V. V. Dimensionality reduction for the
% analysis of brain oscillations.
% NeuroImage, 2014
% DOI: 10.1016/j.neuroimage.2014.06.073


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

%1.0 Calculate table with alpha peaks:
%NVR_Peak();

%1.1 Set different paths:
path_data = '../../../Data/';
path_dataeeg =  [path_data 'EEG/'];
path_in_eeg = [path_dataeeg '06_rejcomp/' mov_cond '/' cropstyle '/'];
path_in_aPeaks = [path_dataeeg '07_SSD/'];

% output paths:
path_out_eeg = [path_dataeeg '07_SSD/' mov_cond '/' cropstyle '/'];
if ~exist(path_out_eeg, 'dir'); mkdir(path_out_eeg); end
path_out_eeg_bb = [path_out_eeg 'broadband/'];
if ~exist(path_out_eeg_bb, 'dir'); mkdir(path_out_eeg_bb); end
path_out_eeg_nb = [path_out_eeg 'narrowband/'];
if ~exist(path_out_eeg_nb, 'dir'); mkdir(path_out_eeg_nb); end
path_out_plots = [path_dataeeg '07_SSD/plots_alphaPeaks/' mov_cond '/'];
if ~exist(path_out_plots, 'dir'); mkdir(path_out_plots); end

%1.2 Get data files
files_eeg = dir([path_in_eeg '*.set']);
files_eeg = {files_eeg.name};

% Get the alpha peaks:
alphaPeaks = load([path_in_aPeaks 'alphapeaks_FOOOF_fres012_812.mat'], 'output');
alphaPeaks = alphaPeaks.output;
alphaPeaks = cell2struct(alphaPeaks(2:end,:), alphaPeaks(1,:),2);

alphaPeaks_old = load([path_in_aPeaks 'alphapeaks.mat'], 'output');
alphaPeaks_old = alphaPeaks_old.output;
alphaPeaks_old = cell2struct(alphaPeaks_old(2:end,:), alphaPeaks_old(1,:),2);



for isub = (1:length(files_eeg))
    
    for i = 1:2
        
        %1.3 Launch EEGLAB:
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        
        
        % 1.4 Get subj name for getting the right event file later:
        thissubject = files_eeg{isub};
        thissubject = strsplit(thissubject, mov_cond);
        thissubject = thissubject{1};
        %thissubject = 'NVR_S06';
        
        
        %1.5 Set filename:
        filename = strcat(thissubject, ...
            mov_cond, ...
            '_PREP_', ...
            cropstyle, ...
            '_eventsaro_rejcomp');
        filename = char(filename);
        
        % 2.Import EEG data
        [EEG, com] = pop_loadset([path_in_eeg, filename '.set']);
        EEG = eegh(com,EEG);
        
        % Get the individual alpha peak:
        
        idx = find(strcmp({alphaPeaks.participant}, thissubject));
        alphaPeak = alphaPeaks(idx).(alphaPeakSource);
        if (isnan(alphaPeak))
            warning('No valid alpha peak found. Taking default = 10Hz.');
            alphaPeak = 10;
        end
        
        if i == 1
            alphaPeak = alphaPeaks_old(idx).(alphaPeakSource);
        end
        %% Prepare the SSD:
        
        % SSD expects channels in columns and double precision:
        SSD_dataIn = double(EEG.data');
        
        % Define the frequency windows:
        signalBand = [alphaPeak-2, alphaPeak+2];
        noiseBand =  [alphaPeak-4, alphaPeak+4];
        blockBand =  [alphaPeak-3, alphaPeak+3];
        SSD_freqBands = [signalBand; noiseBand; blockBand];
        
        
        [SSD_Wout, SSD_Aout, SSD_SNRs, SSD_CoVarSig, SSD_CompAct] = ...
            ssd(SSD_dataIn, ...
            SSD_freqBands, ...
            EEG.srate, ...
            [], ...
            []);
        
        % Save relevant stuff to the SET structure:
        EEG.etc.SSD.W = SSD_Wout;
        EEG.etc.SSD.A = SSD_Aout;
        EEG.etc.SSD.SNR = SSD_SNRs;
        EEG.etc.SSD.alphaPeakF = alphaPeak;
        EEG.etc.SSD.alphaPeakSource = alphaPeakSource;
        EEG.setname = [filename '_SSD'];
        
        if i == 2
            % Save the SETs:
            % broadband:
            pop_saveset(EEG, [filename '_SSD_broadband.set'] , path_out_eeg_bb);
            % narrowband:
            EEGnb = EEG;
            EEGnb.data = EEGnb.etc.SSD.A * SSD_CompAct';
            pop_saveset(EEGnb, [filename '_SSD_narrowband.set'] , path_out_eeg_nb);
            
            % Write CSV files with SSD component activation:
            % broadband:
            bbData = EEG.data' * SSD_Wout;
            csvwrite([path_out_eeg_bb filename '_SSD_broadband.csv'], bbData');
            % narrowband:
            csvwrite([path_out_eeg_nb filename '_SSD_narrowband.csv'], SSD_CompAct');
        end
        %% Plot:
        if (plot_results && i == 1)
            figure('Position',  [100, 100, 1200, 400]);
            haha = gcf;%('Position',  [100, 100, 1200, 400]);
            %haha.Position = [100, 100, 1200, 400];
            % get PSD:
            [Pxx,f] = pwelch(EEG.data'*EEG.etc.SSD.W, 256, [], [], 250);
            % ignore hi-freq:
            idx = f < 50;
            subplot(1,3,2)
            semilogy(f(idx), Pxx(idx,:))
            hold on
            plot([alphaPeak alphaPeak], ...
                [min(min(Pxx(idx,:))) max(max(Pxx(idx,:)))], ...
                'color', 'red')
            title(['old approach (alpha = ' num2str(alphaPeak) ')']);
            
            subplot(1,3,1)
            [oPxx,of] = pwelch(EEG.data', 1000, [], [], 250);
            oidx = of < 50;
            semilogy(of(oidx),oPxx(oidx, :))
            hold on
            plot([alphaPeak alphaPeak], ...
                [min(min(oPxx(oidx,:))) max(max(oPxx(oidx,:)))], ...
                'color', 'red')
            title([thissubject ' � Channel space'], 'Interpreter', 'none')
            
            %keyboard;
            % continue with dbcont
        end
        
        if (plot_results && i == 2)
            [Pxx,f] = pwelch(EEG.data'*EEG.etc.SSD.W, 256, [], [], 250);
            % ignore hi-freq:
            idx = f < 50;
            figure(haha)
            hold on
            subplot(1,3,3)
            semilogy(f(idx), Pxx(idx,:))
            hold on
            plot([alphaPeak alphaPeak], ...
                [min(min(Pxx(idx,:))) max(max(Pxx(idx,:)))], ...
                'color', 'blue')
            title(['FOOOF_fres012_812 (alpha = ' num2str(alphaPeak) ')'], ...
                'Interpreter', 'none');
            
            hold on
            subplot(1,3,1)
            hold on
            plot([alphaPeak alphaPeak], ...
                [min(min(oPxx(oidx,:))) max(max(oPxx(oidx,:)))], ...
                'color', 'blue')
            %keyboard;
            saveas(gcf, [path_out_plots thissubject '.png'], 'png');
        end
    end
    
end

