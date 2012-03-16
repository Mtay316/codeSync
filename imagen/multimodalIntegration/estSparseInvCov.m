% Computing sparse inverse covariance 
clear all; close all;
netwpath = '/home/bn228083/code/';
localpath = '/volatile/bernardng/';
addpath(genpath([netwpath,'bayesianRegressionBN']));
addpath(genpath([netwpath,'covarianceEstimationBN']));
addpath(genpath([netwpath,'matlabToolboxes/quic']));
fid = fopen([localpath,'data/imagen/subjectLists/subjectListDWI.txt']);
nSubs = 60;

for i = 1:nSubs
    sublist{i} = fgetl(fid);
end
subs = 1:nSubs; 

% Parameters
dataType = 1; % 1 = rest, 2 = task
kFolds = 3; % Number of cross-validation folds
nLevels = 3; % Number of refinements on lambda grid
nGridPts = 5; % Number of grid points for lambda, need to be odd number

% paramSelMethod = 1; % 1 = CV, 2 = Model Evidence
% model = 1;
% KrestAcc = zeros(112,112,nSubs);
% KanatAcc = zeros(112,112,nSubs);

nROIs = 491; % Number of parcels
K = zeros(nROIs,nROIs,length(subs));
lambda = zeros(length(subs),1);
matlabpool(6);
% for sub = subs
parfor sub = 1:nSubs
    if dataType == 1 % Load rest data
        tc_parcel = load([localpath,'data/imagen/',sublist{sub},'/restfMRI/tc_rest_parcel500.mat']);
        Y = tc_parcel.tc_parcel;
    elseif dataType == 2 % Load task data
        tc_parcel = load([localpath,'data/imagen/',sublist{sub},'/gcafMRI/tc_task_parcel500.mat']);
        Y = tc_parcel.tc_parcel;
    end
    % Skipping first time point so that timecourses can be evenly divided into 3 folds
    Y(1,:) = [];    
    
    % Normalizing the time courses
    Y = Y-ones(size(Y,1),1)*mean(Y);
    Y = Y./(ones(size(Y,1),1)*std(Y));
    
    % Insert random signal for zero time courses
    indNan = isnan(Y);
    if sum(indNan(:))~=0
        Y(indNan) = randn(sum(indNan(:)),1);
    end
    
    % Sparse Inverse Covariance Estimation
    [K(:,:,sub),lambda(sub)] = sparseGGMcv(Y,kFolds,nLevels,nGridPts);
%     Krest = K(:,:,sub);
%     save([localpath,'data/imagen/',sublist{sub},'/restfMRI/K_rest_roi_fs_quic355_cv.mat'],'Krest');
    
%     load([localpath,'data/imagen/',sublist{sub},'/restfMRI/K_rest_roi_fs_quic355_cv.mat']);
%     load([localpath,'data/imagen/',sublist{sub},'/dwi/anatConnDense.mat']);
%     KrestAcc(:,:,sub) = Krest;
%     KanatAcc(:,:,sub) = Kanat;
    
%     modelEvid = @(V)modelEvidence(X,Y,V,model);
%     K = sparseGGM(Y,paramSelMethod,optMethod,'linear',kFolds,nLevels,nGridPts,modelEvid);
    disp(['Done subject',int2str(sub)]);
end
matlabpool('close');

for sub = 1:nSubs
    Krest = K(:,:,sub);
    lambdaBest = lambda(sub);
    save([localpath,'data/imagen/',sublist{sub},'/restfMRI/K_rest_parcel500_quic',int2str(kFolds),int2str(nLevels),int2str(nGridPts),'_cv.mat'],'Krest','lambdaBest');
end

    
    

