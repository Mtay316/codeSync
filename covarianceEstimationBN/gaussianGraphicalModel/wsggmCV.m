% Weighted sparse Gaussain graphical model
% Input:    X = nxd feature matrix, n = #samples, d = #features
%           kFolds = #folds for cross validation
%           nLevels = #levels for choosing lambda 
%           nGridPts = #grid points per level
%           weight = dxd weights on |Kij|, currently set to exp(-weight/sigma) 
%           nWt = #grid points for sigma
% Output:   K = dxd sparse inverse covariance matrix
%           lambdaBest = best lambda based on data likelihood
%           sigmaBest = best sigma based on data likelihood
function [K,lambdaBest,sigmaBest] = wsggmCV(X,kFolds,nLevels,nGridPts,weight,nWt)
addpath(genpath('/home/bn228083/matlabToolboxes/quic'));
[n,d] = size(X);
S = cov(X);
lambdaMax = max(abs(S(~eye(d))));
scaleMax = 1;
scaleMin = 0.01;
scaleBest = 0.1; % Initialization
[trainInd,testInd] = cvSeq(n,kFolds); % Create validation folds
scaleAcc = scaleBest; % Skip computed lambda during refinement
% Refinement level
for i = 1:nLevels
    if i == 1
        scaleGrid = logspace(log10(scaleMin),log10(scaleMax),nGridPts);
    else
        if abs(scaleBest-scaleGrid(1))<1e-6
            scaleGrid = logspace(log10(scaleGrid(2)),log10(scaleGrid(1)),nGridPts+1);
        elseif abs(scaleBest-scaleGrid(end))<1e-6
            scaleGrid = logspace(log10(scaleGrid(end)/10),log10(scaleGrid(end-1)),nGridPts+1);
        else
            ind = find(abs(scaleGrid-scaleBest)<1e-6);
            scaleGrid = logspace(log10(scaleGrid(ind+1)),log10(scaleGrid(ind-1)),nGridPts+2);
        end
    end
    scaleGrid = fliplr(scaleGrid); % Always in descending order
    [~,ind,~] = find(abs(ones(length(scaleAcc),1)*scaleGrid-scaleAcc'*ones(1,length(scaleGrid)))<1e-6); % More robust than using set functions
    scaleGridMod = sort([scaleGrid(setdiff(1:length(scaleGrid),ind)),scaleBest],2,'descend'); % Remove computed scales
    scaleAcc = [scaleAcc,scaleGridMod]; % Store computed scales
    mu = mean(weight(weight>0)); % Fiber counts appear exponentially distributed
    sigmaGrid = linspace(log(4/3)*mu,log(4)*mu,nWt); % Between 25th and 75th percentile
    % Compute K for each grid point
    evid = -inf*ones(length(scaleGridMod),nWt,kFolds);
    for k = 1:kFolds
        for w = 1:nWt
            Xtrain = X(trainInd{k},:);
            Xtest = X(testInd{k},:);
            Strain = cov(Xtrain);
            Stest = cov(Xtest);
            K = QUIC('path',Strain,lambdaMax.*exp(-weight/sigmaGrid(w)).*~eye(d),scaleGridMod,1e-9,2,200);
            for j = 1:length(scaleGridMod)
                dg = dualGap(K(:,:,j),Strain,lambdaMax.*scaleGridMod(j).*exp(-weight/sigmaGrid(w)).*~eye(d))
                if dg < 1e-5
                    evid(j,w,k) = logDataLikelihood(Stest,K(:,:,j));
                end
            end
        end
    end
    evidAve = mean(evid,3);
    [~,ind] = max(evidAve(:));
    [x,y] = ind2sub(size(evidAve),ind);
    scaleBest = scaleGridMod(x);
    sigmaBest = sigmaGrid(y);
end
% Compute sparse inverse covariance using optimal lambda
lambdaBest = lambdaMax*scaleBest;
K = QUIC('default',S,lambdaBest.*exp(-weight/sigmaBest).*~eye(d),1e-9,2,200);


        
        
        
        

