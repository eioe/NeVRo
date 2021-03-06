%% Summarize alpha peaks

% assumes the outputs of NVR_Peak to be loaded as "rest", "nomov", "mov"
% Update 16/04/19: Doing this here:
path_SSD = ['../../../Data/EEG/07_SSD'];

rest = load([path_SSD '_old/1_peaks.mat']);
rest = rest.subj_peaks;
nomov = load([path_SSD '_old/2_peaks.mat']);
nomov = nomov.subj_peaks;
mov = load([path_SSD '_old/3_peaks.mat']);
mov = mov.subj_peaks;


allAlpha = [];
nSubs = max([size(rest,1), size(nomov,1), size(mov,1)]);

allAlpha(1:nSubs,1:2) = rest(1:nSubs,1:2);
% values for nomov:
[~,globIdx,locIdx] = intersect(allAlpha(:,1),nomov(:,1));
allAlpha(globIdx,3) = nomov(locIdx,2);
% values for mov:
[~,globIdx,locIdx] = intersect(allAlpha(:,1),mov(:,1));
allAlpha(globIdx,4) = mov(locIdx,2);


for (i=1:size(allAlpha,1)) 
    
    subNum = allAlpha(i,1);
    if (subNum<10) 
        subNum_str = ['0' num2str(subNum)];
    else
        subNum_str = num2str(subNum);
    end
        
    name = ['NVR_S' subNum_str];
    alphaPeaks(i).name = name;
    alphaPeaks(i).restEyesClosed = allAlpha(i,2);
    alphaPeaks(i).nomov = allAlpha(i,3);
    alphaPeaks(i).mov = allAlpha(i,4);
end

% Save to csv:
fID = fopen([path_SSD 'alphaPeaks.csv'], 'w');
fprintf(fID, 'ID,restEyesClosed,nomov,mov\r\n'); 
fprintf(fID,'%i,%f,%f, %f\r\n',allAlpha');
fclose(fID);

% Save as .mat:
save([path_SSD '/alphaPeaks.mat'], 'alphaPeaks');

