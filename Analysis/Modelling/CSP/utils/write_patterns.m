
% Prelim script to write out predi vs target tables

% load results:

dirData = './Data/';
dirOut = './Results/Patterns/';

for cond = {'mov', 'nomov'}
    
    path_in_SSDcomps = [dirData, 'EEG/07_SSD/' cond{1} '/'];

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
    
    % load model output:
    load([dirData, 'EEG/08.5_CSP_10f/' cond{1} '/SBA/summaries/CSP_results_' cond{1} '.mat'])
    load([dirData, 'EEG/08.1_SPOC/' cond{1} '/SBA/summaries/SPOC_results_' cond{1} '.mat'])
 
    res_CSP = CSP_results.results;
    res_SPOC = SPOC_results.results;
    subjects_CSP = {res_CSP.participant};
    idx_CSP = find(cellfun('isempty', subjects_CSP));
    subjects_SPOC = {res_SPOC.participant};
    idx_SPOC = find(cellfun('isempty', subjects_SPOC));
    % delete empty rows:
    res_CSP(idx_CSP) = [];
    res_SPOC(idx_SPOC) = [];


    for i=1:size(res_CSP,2)      
        subject = res_CSP(i).participant;
        
           % Get the individually selected SSD components:
        idx = find(strcmp({SSDcomps_tab.participant}, subject));
        SSD_comps =  SSDcomps_tab(idx).selected_comps;
        SSD_comps_arr = str2num(SSD_comps);
        SSD_comps_ch = ['[' SSD_comps ']']; %transform to char
        if (isnan(SSDcomps_tab(idx).n_sel_comps) || ...
            SSDcomps_tab(idx).n_sel_comps < 4)
            warning(['Not enough valid components found for ' subject '!']);
            continue
        end
        
        
        A_CSP = res_CSP(i).weights.CSP_A;
        A_SSD = res_SPOC(i).weights.SSD_A_sel;
        
        A_CSP_tot = transpose(A_CSP * A_SSD');
        A_SPOC = res_SPOC(i).weights.SPOC_A;
        
        all_weights = [A_CSP_tot(:,[1, end]), A_SPOC, A_SSD(:,1)];
        chan_names = {SPOC_results.chanlocs.labels};
        col_names = {'CSP_max', 'CSP_min', 'SPOC', 'SSD'};
        
        weight_table = array2table(all_weights, ... 
            'RowNames', chan_names, ...
            'VariableNames', col_names);
        
        dirOut_cond = [dirOut, cond{1}]
        if ~exist(dirOut_cond, 'dir'); mkdir(dirOut_cond); end
        writetable(weight_table, [dirOut_cond, '/', subject '.csv'], ...
            'WriteRowNames',true, ...
            'WriteVariableNames',true);
    end
end