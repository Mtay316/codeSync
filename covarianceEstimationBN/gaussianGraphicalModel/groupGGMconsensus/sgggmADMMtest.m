% Synthetic data testing for sgggmCV
clear all; 
% close all;
addpath(genpath('D:/research/covarianceEstimationBN'));
addpath(genpath('D:/research/toolboxes/general'));

% Parameter Selection
nFeat = 150;
nSamp = 150; % Make sure divisible by 3
nSub = 60;
nIter = 1;
% df = nFeat+1;
df = 10*nFeat*(nFeat-1)/2;
lTri = tril(ones(nFeat),-1)==1;

distEucl = zeros(nIter,1);
distLogEucl = zeros(nIter,1);
distSGGGM = zeros(nIter,1);
for n = 1:nIter
    % Generate group precision
    Kgrp = sprandsym(nFeat,0.2,0.9);
    Kgrp = Kgrp+5*eye(nFeat);
    Kgrp = corrcov(Kgrp);
    CgrpSqrt = Kgrp^(-0.5);
    
    % Generating subject precision matrices
    K = zeros(nFeat,nFeat,nSub);
    Csqrt = zeros(nFeat,nFeat,nSub);
    for s = 1:nSub
        K(:,:,s) = wishrnd(Kgrp,df)/df;
    end
    
    % Generating timecourses and compute subject correlation matrices
    X = zeros(nSamp,nFeat,nSub);
    C = zeros(nFeat,nFeat,nSub);
    Coas = zeros(nFeat,nFeat,nSub);
    KlogEucl = zeros(nFeat,nFeat,nSub);
    for s = 1:nSub
        X(:,:,s) = mvnrnd(zeros(1,nFeat),K(:,:,s)^-1,nSamp);
        % Normalization
        X(:,:,s) = X(:,:,s)-ones(nSamp,1)*mean(X(:,:,s));
        X(:,:,s) = X(:,:,s)./(ones(nSamp,1)*std(X(:,:,s)));
        % Compute subject correlation matrices
%         C(:,:,s) = cov(X(:,:,s));
        C(:,:,s) = oas(X(:,:,s));
%         ClogEucl(:,:,s) = logm(C(:,:,s));
        KlogEucl(:,:,s) = logm(inv(C(:,:,s)));
    end
    
    if 1
        
    % Compute Euclidean Mean
    tc = [];
    for sub = 1:nSub
        tc = [tc;X(:,:,sub)];
    end
    tc = tc-ones(size(tc,1),1)*mean(tc);
    tc = tc./(ones(size(tc,1),1)*std(tc));
    KeuclGrp = inv(cov(tc));
%     Ceucl = mean(C,3); % Maybe use Coas??
    dia = diag(1./sqrt(KeuclGrp(eye(nFeat)==1)));
    KeuclGrp = dia*KeuclGrp*dia;
    distTemp = logm(CgrpSqrt*KeuclGrp*CgrpSqrt);
    distEucl(n) = norm(distTemp(lTri));
        
    % Compute Log Euclidean Mean
    KlogEuclGrp = expm(mean(KlogEucl,3));
    dia = diag(1./sqrt(KlogEuclGrp(eye(nFeat)==1)));
    KlogEuclGrp = dia*KlogEuclGrp*dia;
    distTemp = logm(CgrpSqrt*KlogEuclGrp*CgrpSqrt);
    distLogEucl(n) = norm(distTemp(lTri));
    
    end
    
    % Compute SGGGM Mean
    nLevels = 3;
    kFolds = 3;
    nGridPts = 5;
    maxIter = 100;
    
    [KsgggmGrp,lambdaBest] = sgggmADMMcv(X,nLevels,kFolds,nGridPts,maxIter);
    dia = diag(1./sqrt(KsgggmGrp(eye(nFeat)==1)));
    KsgggmGrp = dia*KsgggmGrp*dia;
    distTemp = logm(CgrpSqrt*KsgggmGrp*CgrpSqrt);
    distSGGGM(n) = norm(distTemp(lTri));
end

bar([mean(distEucl),mean(distLogEucl),mean(distSGGGM)]);
mean(distSGGGM)/mean(distEucl)
% [h,p] = ttest(distEucl,distSGGGM);
