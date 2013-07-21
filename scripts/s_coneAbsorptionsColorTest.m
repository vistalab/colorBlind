%% s_coneAbsoptionColorTest
%
%  Compare two color patches for discriminability.
%
%
%
% HJ VISTASOFT Team 2013

%% Create two scenes with slightly different colors

% ---- Scene ----------
% fov         = 2;               % deg. Make sure we have plenty of scene samples per cone sample. By making the FOV small, we get plenty.
fov         =  0.2;             % shrink the fov to speed up calculations? 
dCal        = 'LCD-Apple.mat';
vd          = 2;                % Viewing distance- Two meters

wave = [540 550];
sz = 128;
scene1 = sceneCreate('uniform monochromatic',wave,sz);
scene1 = sceneSet(scene1,'fov',fov);       %
scene1 = sceneSet(scene1,'distance',vd);  % Two meters
scene1 = sceneSet(scene1,'name','545');
% vcAddAndSelectObject(scene1); sceneWindow

wave = [550 560];
scene2 = sceneCreate('uniform monochromatic',wave,sz);
scene2 = sceneSet(scene2,'fov',fov);       %
scene2 = sceneSet(scene2,'distance',vd);  % Two meters
scene2 = sceneSet(scene2,'name','555');
% vcAddAndSelectObject(scene2); sceneWindow

%% Create a sample human optics
pupilMM = 3;

% We need to save zCoefs somewhere as part of the record.
zCoefs = wvfLoadThibosVirtualEyes(pupilMM);
wvfP = wvfCreate('wave',wave,'zcoeffs',zCoefs,'name',sprintf('human-%d',pupilMM));
wvfP = wvfComputePSF(wvfP);
oiD = wvf2oi(wvfP,'human');
oiD = oiSet(oiD,'name','Human WVF 3mm');

oi1 = oiCompute(oiD,scene1);
oi2 = oiCompute(oiD,scene2);
% vcAddAndSelectObject(oi1); oiWindow

%% Create a sample human Sensor
sensor = sensorCreate('human');
sensor = sensorSet(sensor,'exp time',0.020);
sensor1 = sensorComputeNoiseFree(sensor,oi1);
sensor2 = sensorComputeNoiseFree(sensor,oi2);
% vcAddAndSelectObject(sensor1); sensorWindow;


nSamples = 40;    % Number of trials
noiseType = 1;    % Just photon noise
voltImages1 = sensorComputeSamples(sensor1,nSamples,noiseType);
voltImages2 = sensorComputeSamples(sensor2,nSamples,noiseType);

% Found this once using 
% [locs,rect] = vcROISelect(sensor1)
rect = [29    22    30    29];

% Use imcrop to select out the voltImages1/2 with that rect

%% Training

% Let's give better names to I and Y and so forth
ind = randperm(2*nSamples);
[row,col,~] = size(voltImages1);
I_c         = reshape(permute(voltImages1,[3 1 2]),[nSamples, row*col]);
[row,col,~] = size(voltImages2);
I_n         = reshape(permute(voltImages2,[3 1 2]),[nSamples, row*col]);
I_train = [I_c; I_n];
Y = [ones(nSamples,1);-ones(nSamples,1)];

% Train and SVM structure explain flags here
svmStruct = ...
    svmtrain(Y(ind(1:round(1.8*nSamples))),...
    sparse(I_train(ind(1:round(1.8*nSamples)),:)),'-t 1 -q');

% Predictions and accuracy
[predLabels,curAcc,~] = ...
     svmpredict(Y(ind(round(1.8*nSamples)+1:end)),...
     sparse(I_train(ind(round(1.8*nSamples)+1:end),:)),...
     svmStruct,'-q');
 
 %% Plot stuff
 


