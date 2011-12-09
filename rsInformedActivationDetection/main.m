% Integrating resting state connectivity into task activation detection
clear all; close all;
filepath = 'D:/research/';
addpath(genpath([filepath,'toolboxes/general/']));
addpath(genpath([filepath,'covarianceEstimationNg/']));
addpath(genpath([filepath,'toolboxes/markSchmidtCode/']));
addpath(genpath([filepath,'bayesianRegressionNg/']));
fid = fopen([filepath,'data/imagen/subjectLists/subjectList.txt']);
nSubs = 65;
sublist = cell(nSubs,1);
for i = 1:nSubs
    sublist{i} = fgetl(fid);
end
nConds = 10; % 10 experimental conditions

% nSubs = 20; % For testing
method = 3; 
model = 8;

% Parameters
if method == 1
    methName = 'OLS';
elseif method == 2
    methName = 'Ridge';
elseif method == 3
    methName = 'OAS';
elseif method == 4
    methName = 'GL';
end
thresh = 0:0.25:100; % For thresholding the t-maps
lambda = [100,75,50,25,10,7.5,5,2.5]; % For Graphical LASSO using l1General, fixed grid

% Load ROI mask
load(strcat('D:/research/data/imagen/group/parcel1000Refined'));
rois = unique(roiMask);
nROIs = length(rois)-1; clear roiMask;

beta = zeros(nConds,nROIs,nSubs);
for sub = 1:nSubs
    % Load task data
    load([filepath,'data/imagen/',sublist{sub},'/tcTaskParcel1000']);
    % Normalizing the time courses
    tcTask = tcTask-ones(size(tcTask,1),1)*mean(tcTask);
    tcTask = tcTask./(ones(size(tcTask,1),1)*std(tcTask));
    % Load regressors for task data
    regressorsTask = loadRegressorsTask(sublist{sub}); 
    regressorsTask = regressorsTask(:,1:nConds); % Only the first 10 correspond to task
    X = regressorsTask; Y = tcTask; 
    % beta estimation (nConds x nROIs x nSubs)
    if method == 1 % OLS 
        beta(:,:,sub) = pinv(X)*Y; 
    elseif method == 2 % Ridge
        L = eye(nROIs); % Using identity to test effect of just ridge penalty
        beta(:,:,sub) = bayesianRegression(X,Y,L,model)';
    elseif method == 3 % OAS
        load([filepath,'/data/imagen/',sublist{sub},'/tcRestParcel1000']);
        tcRest = tcRest-ones(size(tcRest,1),1)*mean(tcRest);
        tcRest = tcRest./(ones(size(tcRest,1),1)*std(tcRest));
        L = inv(oas(tcRest));
        beta(:,:,sub) = bayesianRegression(X,Y,L,model,1e-12)';
    elseif method == 4 % Graphical LASSO
        load('dataEvidGL'); [dummy,i] = max(dataEvid(:,sub));
        load([filepath,'data/imagen/',sublist{sub},'/KrestParcel1000lambda',int2str(lambda(i)*100),'Proj']);
        % Load optimal Krest from Graphical LASSO
%         load([filepath,'data/imagen/',sublist{sub},'/KrestParcel1000opt']);
        L = Krest; % Krest that maximized model evidence
        beta(:,:,sub) = bayesianRegression(X,Y,L,model)';
    end
end
clear tcTask Krest X Y K L;

% Compute t-value of beta contrast
load([filepath,'data/imagen/contrastList.mat']);
sig = maxTpermTestGroup(beta,contrastList(9,:),thresh);
% sig = maxTpermTestGroup(beta,contrastList,thresh);
% Saving contrast of interest results
% save(['sig',methName,'coi'],'sig');



