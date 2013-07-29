%% s_coneAbsoptionStdVision
%
%  Using SVM on 20/20 vision test
%
%
%
% HJ VISTASOFT Team 2013

%% Create two scenes with slightly different colors
%  Set Parameters
fov         =  0.305;             % field of view
dCal        = 'LCD-Apple.mat';
vd          = 6;                % Viewing distance- Six meters

% Create Scene 1 - Two lines that are 1.75 mm apart
I = zeros(128,128);
I(:,[61 68]) = 255;
imwrite(I,'patch1.png');
I = zeros(128,128);
I(:,[64 65]) = 255;
imwrite(I,'patch2.png');

% Create Scene 1
scene1 = sceneFromFile('patch1.png','rgb',100,dCal);
scene1 = sceneSet(scene1,'fov',fov);       %
scene1 = sceneSet(scene1,'distance',vd);  % Six meters
scene1 = sceneSet(scene1,'name','Two Lines');
%vcAddAndSelectObject(scene1); sceneWindow

% Create Scene 2
scene2 = sceneFromFile('patch2.png','rgb',100,dCal);
scene2 = sceneSet(scene2,'fov',fov);       %
scene2 = sceneSet(scene2,'distance',vd);  % Two meters
scene2 = sceneSet(scene2,'name','One Line');
% vcAddAndSelectObject(scene2); sceneWindow

%% Create a sample human optics
pupilMM = 3;

% We need to save zCoefs somewhere as part of the record.
wave   = 400:10:780;
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
sensor = sensorSet(sensor,'fov',fov);
[sensor,~,coneType] = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 0.6 0.3 0.1],[]);
sensorL = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 1 0 0]);
sensorM = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 0 1 0]);
sensorS = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 0 0 1]);
sensorL1 = sensorComputeNoiseFree(sensorL,oi1);
sensorL2 = sensorComputeNoiseFree(sensorL,oi2);
sensorM1 = sensorComputeNoiseFree(sensorM,oi1);
sensorM2 = sensorComputeNoiseFree(sensorM,oi2);
sensorS1 = sensorComputeNoiseFree(sensorS,oi1);
sensorS2 = sensorComputeNoiseFree(sensorS,oi2);

G = fspecial('gaussian',[24 24],12);
vL1 = sensorGet(sensorL1,'volts'); vL1 = imfilter(vL1,G,'same');
vL2 = sensorGet(sensorL2,'volts'); vL2 = imfilter(vL2,G,'same');
vM1 = sensorGet(sensorM1,'volts'); vM1 = imfilter(vM1,G,'same');
vM2 = sensorGet(sensorM2,'volts'); vM2 = imfilter(vM2,G,'same');
vS1 = sensorGet(sensorS1,'volts'); vS1 = imfilter(vS1,G,'same');
vS2 = sensorGet(sensorS2,'volts'); vS1 = imfilter(vS1,G,'same');

sensor1 = sensorComputeNoiseFree(sensor,oi1);
sensor2 = sensorComputeNoiseFree(sensor,oi2);
volts1 = sensorGet(sensor1,'volts');
volts1(coneType==2) = vL1(coneType==2);
volts1(coneType==3) = vM1(coneType==3);
volts1(coneType==4) = vS1(coneType==4);
sensor1 = sensorSet(sensor1,'volts',volts1);

volts2 = sensorGet(sensor2,'volts');
volts2(coneType==2) = vL2(coneType==2);
volts2(coneType==3) = vM2(coneType==3);
volts2(coneType==4) = vS2(coneType==4);
sensor2 = sensorSet(sensor2,'volts',volts2);
% vcAddAndSelectObject(sensor1); sensorWindow;


nSamples = 500;    % Number of trials
noiseType = 1;    % Just photon noise

voltImages1 = sensorComputeSamples(sensor1,nSamples,noiseType);
voltImages2 = sensorComputeSamples(sensor2,nSamples,noiseType);
% Found this once using 
%[locs,rect] = vcROISelect(sensor1)
%rect = [4    4    4   4];

% Crop Images by rect
%voltImages1 = voltImages1(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3),:);
%voltImages2 = voltImages2(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3),:);

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
 


