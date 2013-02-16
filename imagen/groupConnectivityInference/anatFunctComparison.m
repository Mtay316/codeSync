% Compare anatomical and functional connectivity
clear all; 
close all;
filepath = 'I:/research/data/imagen/';
addpath(genpath('I:/research/toolboxes/general'));
addpath(genpath('I:/research/code/covarianceEstimationBN'));

fid = fopen([filepath,'subjectLists/subjectListDWI.txt']);
nSubs = 59;
sublist = cell(nSubs,1);
for i = 1:nSubs
    sublist{i} = fgetl(fid);
end

level = 2; % 1=Subject level, 2=Group level
method = 3; % 1=OAS, 2=SGGM, 3=SGGGM
meanType = 3; % 1=Eucl, 2=LogEucl, 3=Concat

template = 'ica_roi_parcel500_refined';
nROIs = 492;
lowtri = tril(ones(nROIs),-1)==1;

if level == 1
    Krest = zeros(sum(lowtri(:)),nSubs);
    Kanat = zeros(sum(lowtri(:)),nSubs);
    load([filepath,'group/grpConn/KsgggmADMM_ica_roi_parcel500_refined.mat']);
    Ksub(:,:,3) = []; % Sub000004622874 does not have DWI data
    for sub = 1:nSubs
        if method == 1
            load([filepath,sublist{sub},'/restfMRI/tc_',template,'.mat']);
            tcRest = tc; clear tc;
            tcRest = tcRest-ones(size(tcRest,1),1)*mean(tcRest);
            tcRest = tcRest./(ones(size(tcRest,1),1)*std(tcRest));
            % Insert random signal for zero time courses
            indNan = isnan(tcRest);
            if sum(indNan(:))~=0
                tcRest(indNan) = randn(sum(indNan(:)),1);
            end
            Ktemp = inv(oas(tcRest));
        elseif method == 2
            load([filepath,sublist{sub},'/restfMRI/K_',template,'_quic335_cv.mat']);
            Ktemp = K;
        elseif method == 3
            Ktemp = Ksub(:,:,sub);
        end
        dia = diag(1./sqrt(Ktemp(eye(nROIs)==1)));
%         Ktemp = -dia*Ktemp*dia;
        Krest(:,sub) = -Ktemp(lowtri);
        load([filepath,'group/groupFiber/group_all/results_trackvis/K_gaussian_blur_',template,'.mat']);
%         load([filepath,sublist{sub},'/dwi/results_ttk/K_gaussian_blur_',template,'.mat']);
        Kanat(:,sub) = Kfibcnt(lowtri);
    end
elseif level == 2
    load([filepath,'group/groupFiber/group_all/results_trackvis/K_gaussian_blur_',template,'.mat']);
    Kanat = Kfibcnt(lowtri);
    if method == 1 % OAS
        switch meanType
            case 1 % Euclidean mean
                load([filepath,'group/grpConn/KoasEuclSubMean_ica_roi_parcel500_refined.mat']);
            case 2 % Log Euclidean mean
                load([filepath,'group/grpConn/KoasLogEuclSubMean_ica_roi_parcel500_refined.mat']);
            case 3 % Concatenated time courses
                load([filepath,'group/grpConn/KoasConcatAll_ica_roi_parcel500_refined.mat']);
        end
    elseif method == 2 % SGGM
        switch meanType
            case 1 % Euclidean mean
                load([filepath,'group/grpConn/KsggmEuclSubMean_ica_roi_parcel500_refined.mat']);
            case 2 % Log Euclidean mean
                load([filepath,'group/grpConn/KsggmLogEuclSubMean_ica_roi_parcel500_refined.mat']);
            case 3 % Concatenated time courses
                load([filepath,'group/grpConn/KsggmConcatAll_ica_roi_parcel500_refined.mat']);
        end
    elseif method == 3 % SGGGM
        load([filepath,'group/grpConn/KsgggmADMM_ica_roi_parcel500_refined.mat']);
    end
    dia = diag(1./sqrt(Kgrp(eye(nROIs)==1)));
%     Kgrp = -dia*Kgrp*dia;
    Krest = -Kgrp(lowtri);
end    
[rho,p] = corr(Krest(:),log(Kanat(:)+1))
% [rho,p] = corr(Krest(:),Kanat(:))

% diceCoef(Krest(:)~=0,Kanat(:)~=0)
% hold on; plot(log(Kanat(~eye(nROIs))+1),(Krest(~eye(nROIs))),'.');
