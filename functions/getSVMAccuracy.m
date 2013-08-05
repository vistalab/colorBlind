function acc = getSVMAccuracy(dataMatrix, labels, nFolds, svmType, opts)
%% function getSVMAccuracy(dataMatrix, labels, [nFolds], [svmType], [opts])
%    compute the svm accuracy
%
%  Inputs:
%    dataMatrix - M-by-N matrix, containing data for M instances and N
%                 features
%    labels     - M-by-1 vector, label for each instance
%    nFolds     - fold for cross validation
%    svmType    - string, can be 'svm' or 'linear'
%    opts       - string, svm options
%
%  Outputs      - 2-by-1 vector, containing average accuray and standard
%                 deviation
%
%  Example:
%    acc = getSVMAccuracy(dataMatrix, labels, 10, 'linear')
%
%  (HJ) VISTASOFT Team 2013

%% Check Inputs
if nargin < 1, error('Data matrix required'); end
if nargin < 2, error('Labels for data required'); end
if nargin < 3, nFolds  = 5; end
if nargin < 4, svmType = 'linear'; end
if nargin < 5, opts = '-s 2 -q'; end

%% Divide data into nFolds
%  Normalize Data
dataMatrix = (dataMatrix-repmat(min(dataMatrix),[length(dataMatrix) 1])) ...
    ./ repmat(max(dataMatrix)-min(dataMatrix),[length(dataMatrix) 1]);
%  Random permute the data
[M,~] = size(dataMatrix);
ind   = randperm(M);

% Train and Test
accHistory  = zeros(nFolds,1);
instPerFold = round(M/nFolds);
for i = 1 : nFolds
    if i < nFolds
        trainIndx = [ind(1:(i-1)*instPerFold) ...
                     ind(i*instPerFold+1:end)];
        testIndx  = ind((i-1)*instPerFold+1:i*instPerFold);
    else
        trainIndx = ind(1:(i-1)*instPerFold);
        testIndx  = ind((i-1)*instPerFold+1:end);
    end
    trainData = sparse(dataMatrix(trainIndx,:));
    testData  = sparse(dataMatrix(testIndx,:));
    % Train
    switch svmType
        case 'linear' 
        % Liblinear routine
          svmStruct = train(labels(trainIndx),trainData,opts);
          [~,curAcc,~] = predict(labels(testIndx),testData,svmStruct,'-q');
        case 'svm'
        % LibSVM routine
        % Parameters explaination:
        %   http://www.csie.ntu.edu.tw/~cjlin/libsvm/
          svmStruct = svmtrain(labels(trainIndx),trainData,opts);
          [~,curAcc,~] = svmpredict(labels(testIndx),testData,svmStruct,'-q');
        otherwise
          error('Unknown svm type');
    end
    accHistory(i) = curAcc(1) / 100; % Convert to between 0~1
end

% Report average and std
acc(1) = mean(accHistory);
acc(2) = std(accHistory);
end