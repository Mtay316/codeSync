% Bayesian Regression
% Input:    X = nxm regressor matrix, n = #samples, m = #regressors
%           Y = nxd data matrix, d = #features
%           K = dxd prior precision
%           model = {1,...,7} see below
%           param = user-specified alpha
%           W = dxd prior precision, use only if model = 4, else leave empty
% Output:   beta = mxd posterior regression coefficients
function beta = bayesianRegression(X,Y,K,model,param,W)
if nargin < 6
    W = [];
end
d = size(K,1);
Id = eye(d);
if nargin < 5
    param = [];
end
if ~isempty(param) && (model==1 || model==2 || model==3 || model==10)
    alpha = param;
else
    alpha = modelEvidence(X,Y,K,model,param,W);
end
if model == 1 % inv(V1) = I, inv(V2) = K
    V1inv = Id;
    V2inv = K;
elseif model == 2 % inv(V1) = K, inv(V2) = I
    V1inv = K;
    V2inv = Id;
elseif model == 3 % inv(V1) = inv(V2) = K
    V1inv = K;
    V2inv = K;
elseif model == 4 % inv(V1) = I, inv(V2) = K + alpha2*I
    V1inv = Id;
    V2inv = K + alpha(2)*Id;
elseif model == 5 % inv(V1) = K + alpha1*I, inv(V2) = I
    V1inv = K + alpha(2)*Id;
    V2inv = Id;
elseif model == 6 % inv(V1) = K + alpha1*I, inv(V2) = K + alpha2*I
    V1inv = K + alpha(2)*Id;
    V2inv = K + alpha(3)*Id;
elseif model == 7 % inv(V1) = I, inv(V2) = (1-alpha2)*K + alpha2*I
    V1inv = Id;
    V2inv = (1-alpha(2))*K + alpha(2)*Id;
elseif model == 8 % inv(V1) = (1-alpha1)*K + alpha1*I, inv(V2) = I
    V1inv = (1-alpha(2))*K + alpha(2)*Id;
    V2inv = Id;
elseif model == 9 % inv(V1) = (1-alpha1)*K + alpha1*I, inv(V2) = (1-alpha2)*K + alpha2*I
    V1inv = (1-alpha(2))*K + alpha(2)*Id;
    V2inv = (1-alpha(3))*K + alpha(3)*Id;
else % inv(V1)~=inv(V2)
    V1inv = V;
    V2inv = W;
end
beta = (V1inv+alpha(1)*V2inv)\(V1inv*Y'*X)/(X'*X);