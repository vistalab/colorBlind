%% s_ctConeSamplesForLetters
%  Script to test distance effects on clearType cone sampled image SVM
%  classification accuracy
%  This program uses SVM by liblinear / libsvm with linear kernel by
%  default. If liblinear is not set up properly, the program will use the
%  SVM provided by MATLAB

%% Clean up and Init
close all;
% Set number of samples. If we do not need to update cone samples each time,
% we can set it much larger
nSamples     = 300;
eyeMove      = 2; % 1 - Scanning, 2 - Gaussian random move
updateMosaic = false;

% Init Labels
% Use 1 and -1 to be the labels to keep consistant with the liblinear and
% libsvm
Y = [ones(nSamples,1);-ones(nSamples,1)];

% Init font parameters
if ~exist('letter','var'), letter = ['c','o']; end
if ~exist('fontFamily','var'), fontFamily = 'georgia'; end
if ~exist('fontSize','var'), fontSize   = 9; end
if ~exist('dpi','var'), dpi = 100; end

% Load vDisp
% load('Dell Chevron Pixels Pixel Size 26.mat')
load('Dell LCD Stripes Pixel Size 24.mat')

%% SVM Classifier
count     = 1;
if ~exist('distRange','var'), distRange = 0.7:0.2:1.8; end
%distRange = [1.2:0.1:2.0 2.2:0.2:3.0 3.5:0.5:5]; % no eye move
acc       = zeros(length(distRange),1); % Used to store classification accuracy
err       = zeros(length(distRange),1); % Used to store standard deviation

% Init Sensor
sensor    = sensorCreate('human');
sensor    = sensorSet(sensor,'exp time',0.05);

% Avoid using sensor name 'human' to prevent cone mosaic refreshing
% Shall I use the same cone mosaic or not?
% sensor    = sensorSet(sensor,'name','noName');

% Loop for clearType vs non-clearType
for dist = distRange
    % Generate samples for first sample
    scene    = ctCreateFontScene(vDisp, dist, letter(1), fontSize, fontFamily, true, dpi);
    % vcAddAndSelectObject(scene); sceneWindow
    Img = ctConeSamples(scene,nSamples, sensor); % update cone mosaic;

    % Transform Img_c to matrix [row*col, nSamples]
    [row,col,~] = size(Img);
    I_c         = reshape(permute(Img,[3 1 2]),[nSamples, row*col]);
    
    % Generate samples for second letter
    scene    = ctCreateFontScene(vDisp, dist, letter(2), fontSize, fontFamily, true, dpi);
    % vcAddAndSelectObject(scene); sceneWindow

    Img = ctConeSamples(scene,nSamples, sensor, [], updateMosaic, eyeMove); % Update cone mosaic    
    % Transform Img_c to matrix [row*col, nSamples]
    [row,col,~] = size(Img);
    I_n         = reshape(permute(Img,[3 1 2]),[nSamples, row*col]);
    % Scale each line to unit power
    % I_n = I_n ./ repmat(sum(I_n,2),[1 row*col]);
    
    I_train = [I_c; I_n];
    % scale data
    %I_train = I_train ./ repmat(max(I_train),[2*nSamples 1]);
    
    s=0; sq = 0;
    for i = 1:10
        ind = randperm(2*nSamples);
        try
            % Try to use Liblinear / Libsvm to do classification
            % It's much faster and easier to convergence than MATLAB SVM
            
            % LibSVM routine
            % svmStruct = svmtrain(Y(ind(1:1.8*nSamples)),sparse(I_train(ind(1:1.8*nSamples),:)),'-s 2 -t 1 -d 1 -q');
            % [~,curAcc,~] = svmpredict(Y(ind(1.8*nSamples+1:end)),sparse(I_train(ind(1.8*nSamples+1:end),:)),svmStruct,'-q');
            
            % LibLinear Routine
            svmStruct = train(Y(ind(1:1.8*nSamples)),sparse(I_train(ind(1:1.8*nSamples),:)),'-q');
            [~,curAcc,~] = predict(Y(ind(1.8*nSamples+1:end)),sparse(I_train(ind(1.8*nSamples+1:end),:)),svmStruct,'-q');
            
            s  = s + curAcc(1)/100; % Compute sufficient statistics for accuracy
            sq = sq + (curAcc(1)/100)^2; % Compute sufficient statistics for std
        catch errorMsg
            % Liblinear/Libsvm is not working correctly
            % Try SVM provided by MATLAB instead
            disp('Using Matlab SVM');
            svmStruct = svmtrain(I_train(ind(1:1.8*nSamples),:),Y(ind(1:1.8*nSamples)));
            yy = svmclassify(svmStruct,I_train(ind(1.8*nSamples+1:end),:));
            curAcc = sum(yy == Y(ind(1.8*nSamples+1:end)))*5/nSamples;
            s  = s + curAcc;
            sq = sq + (curAcc)^2;
        end
    end
    % Compute accuracy and std from sufficient statistics
    acc(count) = s/10;
    err(count) = sqrt(sq/10 - (s/10)^2);
    disp(['Dist: ' num2str(dist) '   acc: ' num2str(s/10) '   std: ' num2str(err(count))]);
    count = count + 1;
end

%% Visualize Results
errorbar(distRange,acc,err);