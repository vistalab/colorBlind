%% s_coneAbsoptionColorTest
%
%  Compare two color patches for discriminability.
%
%
%
% HJ VISTASOFT Team 2013

%% Create two scenes with slightly different colors
%  Set Parameters
fov         =  0.5;             % field of view
dCal        = 'LCD-Apple.mat';
vd          = 2;                % Viewing distance- Two meters

wave = [540 550];
sz = 128;

% Create Scene 1
scene1 = sceneCreate('uniform monochromatic',wave,sz);
scene1 = sceneSet(scene1,'fov',fov);       %
scene1 = sceneSet(scene1,'distance',vd);  % Two meters
scene1 = sceneSet(scene1,'name','545');
% vcAddAndSelectObject(scene1); sceneWindow

% Create Scene 2
wave = [550 560];
scene2 = sceneCreate('uniform monochromatic',wave,sz);
scene2 = sceneSet(scene2,'fov',fov);       %
scene2 = sceneSet(scene2,'distance',vd);  % Two meters
scene2 = sceneSet(scene2,'name','555');
% vcAddAndSelectObject(scene2); sceneWindow

%% Create a sample human optics
pupilMM = 3; % Diameter in um

% We need to save zCoefs somewhere as part of the record.
zCoefs = wvfLoadThibosVirtualEyes(pupilMM);
wvfP = wvfCreate('wave',wave,'zcoeffs',zCoefs,'name',sprintf('human-%d',pupilMM));
wvfP = wvfComputePSF(wvfP);
oiD = wvf2oi(wvfP,'human');
oiD = oiSet(oiD,'name','Human WVF 3mm');

oi1 = oiCompute(oiD,scene1);
oi2 = oiCompute(oiD,scene2);
% vcAddAndSelectObject(oi2); oiWindow

%% Create a sample human Sensor
sensor = sensorCreate('human');
sensor = sensorSet(sensor,'exp time',0.050);
sensor = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 0.6 0 0.1]/0.7,[]);
sensor1 = sensorComputeNoiseFree(sensor,oi1);
sensor2 = sensorComputeNoiseFree(sensor,oi2);
% vcAddAndSelectObject(sensor2); sensorWindow;


nSamples = 500;    % Number of trials
noiseType = 1;    % Just photon noise
voltImages1 = sensorComputeSamples(sensor1,nSamples,noiseType);
voltImages2 = sensorComputeSamples(sensor2,nSamples,noiseType);

% Found this once using 
% [locs,rect] = vcROISelect(sensor1)
rect = [29    22    4   4];

% Crop Images by rect
voltImages1 = voltImages1(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3),:);
voltImages2 = voltImages2(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3),:);

%% Training
ind = randperm(2*nSamples);
[row,col,~] = size(voltImages1);
dataMatrix1 = reshape(permute(voltImages1,[3 1 2]),[nSamples, row*col]);
[row,col,~] = size(voltImages2);
dataMatrix2 = reshape(permute(voltImages2,[3 1 2]),[nSamples, row*col]);
I_train = [dataMatrix1; dataMatrix2];
groupLabels = [-ones(nSamples,1);ones(nSamples,1)];

% It's important to normalize data (linearly scale each column to 0~1)
I_train = (I_train-repmat(min(I_train),[length(I_train) 1])) ...
    ./ repmat(max(I_train)-min(I_train),[length(I_train) 1]);

% Train and SVM structure 

% LibSVM routine
% Parameters:
%   -s 2: one class SVM
%   -t 0: linear kernel
% More Parameter explaination:
%   http://www.csie.ntu.edu.tw/~cjlin/libsvm/

%svmStruct = ...
%    svmtrain(groupLabels(ind(1:round(1.8*nSamples))),...
%    sparse(I_train(ind(1:round(1.8*nSamples)),:)),'-t 0 -s 2');

% Liblinear Routine
svmStruct = train(groupLabels(ind(1:round(1.8*nSamples))),...
    sparse(I_train(ind(1:round(1.8*nSamples)),:)),'-s 2 -q');

% Predictions and accuracy

% LibSVM Routine
%[predLabels,curAcc,~] = ...
%     svmpredict(groupLabels(ind(round(1.8*nSamples)+1:end)),...
%     sparse(I_train(ind(round(1.8*nSamples)+1:end),:)),...
%     svmStruct,'-q');

% Liblinear Routine
[predLabels,curAcc,~] = ...
     predict(groupLabels(ind(round(1.8*nSamples)+1:end)),...
     sparse(I_train(ind(round(1.8*nSamples)+1:end),:)),...
     svmStruct,'-q');
 
 %% Plot stuff
 


