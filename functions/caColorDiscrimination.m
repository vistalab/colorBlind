function acc = caColorDiscrimination(dispName, cRGB1, cRGB2, varargin)
%% function caColorDiscrimination
%
%  Compare two color patches for discriminability.
%
%  Inputs:
%    dispName - string, the name of display calibration file. For safety,
%               please include path in the dispName
%    cRGB1    - 3-by-1 vector, containing RGB values of the 1st patch
%    cRGB2    - 3-by-1 vector, containing RGB values of the 2nd patch
%    varargin - To be used for accept SVM parameters, not supported yet
%
%  Outputs:
%    acc      - prediction accuracy
%
%  Example:
%    acc = caColorDiscrimination('LCD-Apple', [0 1 0]', [0 0 1]');
%
%  To Do:
%    1. Add colorblind support
%    2. Use function getSVMAccuracy to do classification - done
%    3. Accept SVM Parameters
%    4. Use more areas in a patch to increase efficiency
%    5. Giving gamma input for display
%    6. Making display structure for OLED
%  
%  (HJ) VISTASOFT Team 2013

%% Check Inputs
if nargin < 1, error('Display file is required to be specified.'); end
if nargin < 2, error('RGB color for 1st patch is required.'); end
if nargin < 3, error('RGB color for 2nd patch is required.'); end

if ~exist(dispName,'file'), error('Display file cannot be found.'); end
if max(cRGB1) > 1, cRGB1 = double(cRGB1) / 255; end
if max(cRGB2) > 1, cRGB2 = double(cRGB2) / 255; end

%% Create two scenes with slightly different colors
%  Set Parameters
fov         =  0.305;             % field of view
vd          = 6;                  % Viewing distance- Six meters

% Create Scene - show color patch with cRGB on display
I = repmat(reshape(cRGB1,[1 1 3]),[128 128 1]);
imwrite(I,'patch1.png');
I = repmat(reshape(cRGB2,[1 1 3]),[128 128 1]);
imwrite(I,'patch2.png');

% Create Scene 1
scene1 = sceneFromFile('patch1.png','rgb',[],dispName);
scene1 = sceneSet(scene1,'fov',fov);       %
scene1 = sceneSet(scene1,'distance',vd);  % Six meters
scene1 = sceneSet(scene1,'name','Color 1');
%vcAddAndSelectObject(scene1); sceneWindow

% Create Scene 2
scene2 = sceneFromFile('patch2.png','rgb',[],dispName);
scene2 = sceneSet(scene2,'fov',fov);       %
scene2 = sceneSet(scene2,'distance',vd);  % Two meters
scene2 = sceneSet(scene2,'name','Color 2');
% vcAddAndSelectObject(scene2); sceneWindow

% Delete Tmp Files Created
delete('patch1.png','patch2.png');

%% Create a sample human optics
pupilMM = 3; % Diameter in um

% We need to save zCoefs somewhere as part of the record.
wave = 400:10:780;
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
sensor = sensorSet(sensor,'exp time',0.020);
% Create Colorblind cone mosaic
%sensor = sensorCreateConeMosaic(sensor,sensorGet(sensor,'size'),[0 0.6 0 0.1]/0.7,[]);
sensor1 = sensorComputeNoiseFree(sensor,oi1);
sensor2 = sensorComputeNoiseFree(sensor,oi2);
% vcAddAndSelectObject(sensor2); sensorWindow;


nSamples = 500;    % Number of trials
noiseType = 1;    % Just photon noise
voltImages1 = sensorComputeSamples(sensor1,nSamples,noiseType);
voltImages2 = sensorComputeSamples(sensor2,nSamples,noiseType);

% Select a small region from middle part
[M,N,~] = size(voltImages1);
M = round(M/2); N = round(N/2);

% Crop Images by rect
voltImages1 = voltImages1(M-2:M+2,N-2:N+2,:);
voltImages2 = voltImages2(M-2:M+2,N-2:N+2,:);

%% Training
[row,col,~] = size(voltImages1);
dataMatrix1 = reshape(permute(voltImages1,[3 1 2]),[nSamples, row*col]);
[row,col,~] = size(voltImages2);
dataMatrix2 = reshape(permute(voltImages2,[3 1 2]),[nSamples, row*col]);

% Train and SVM structure 
acc = getSVMAccuracy([dataMatrix1; dataMatrix2], ...
              [-ones(nSamples,1);ones(nSamples,1)], 5);
 
 %% Plot stuff
 

end
