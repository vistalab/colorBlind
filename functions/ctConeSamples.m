function [pImg, oiD, xy, coneType] = ctConeSamples(scene, nSamples, sensor, oiD, cbType)
% Compute cone samples for scene
%
%   [voltImages, oiD] = ctConeSamples(scene, nSamples, sensor, oiD)
%
% General Process:
%   1. Load cached clearType font data, convert to non-clearType if needed
%   2. Compute virtual display output image, to colorblind if needed
%   3. Convert output Image to Scene
%
% Input Parameters:
%   scene        - ISET scene structure
%   nSamples     - number of samples to be generated
%   sensor       - eye sensor to be used, if empty, program will create one
%   oiD          - Optical image data
%   cbType       - colorblind type
%
% Output Parameter:
%   pImg         - m*n*nSamples matrix, each [m n] respresent a photon Img
%
% Example:
%    pImg = ctConeSamples(scene, 10, sensor, oiD, false, false)
%
% Author: HJ
%
%% Check Inputs
if isempty(scene)
    scene = sceneCreate('slanted bar');
    scene = sceneSet(scene,'h fov',1);
end
if nargin < 2, nSamples = 1000; end
if nargin < 3, 
    sensor = sensorCreate('human'); 
    sensor = sensorSet(sensor,'exp time',0.05);
    [sensor,xy,coneType,~] = sensorCreateConeMosaic(sensor);
end
if nargin < 4, oiD = []; end

%% Convert WVF human data to ISET
% The data were collected by Thibos and are described in the wvfLoadThibosVirtualEyes
% function and reference therein.
% This part is adpoted from waveFront Toolbox

if isempty(oiD)
    wave = 400:10:700; wave = wave(:);
    pupilMM = 3;
    
    % Load human wvf
    zCoefs = wvfLoadThibosVirtualEyes(pupilMM);
    wvfP = wvfCreate('wave',wave,'zcoeffs',zCoefs,'name',sprintf('human-%d',pupilMM));
    wvfP = wvfComputePSF(wvfP);
    
    oiD = wvf2oi(wvfP,'human');
    oiD = oiSet(oiD,'name','Human WVF 3mm');
end

%% Sensor Setup
%  set up sensor for Thibos calculation
oiD = oiCompute(oiD,scene);
sensor = sensorSetSizeToFOV(sensor,sceneGet(scene,'hfov'),scene,oiD);
sensor = sensorCompute(sensor,oiD);

%% Compute sensor image samples
%  Init eye movement parameters if not set-up yet
sensor  = ctInitEyeMovements(sensor, scene, oiD, nSamples*50, 0);
sensor     = coneAbsorptions(sensor,oiD);
photonImg  = sensorGet(sensor,'photons');
photonImg  = photonImg(:,:,randperm(size(photonImg,3)));

%cumN = sensorGet(sensor,'exp time', 'ms');
[r,c,~]      = size(photonImg);
pImg         = zeros(r,c,nSamples);
for ii = 1 : nSamples
    pImg(:,:,ii) = sum(photonImg(:,:,50*ii-49:50*ii),3);
end
    %
%     f            = sensorGet(sensor,'frames per position');
%     fc           = cumsum(f);
%     [r,c,~]      = size(tmpImg);
%     pImg         = zeros(r,c,nSamples);
%     for ii = 1 : nSamples
%         pImg(:,:,ii) = pImg(:,:,ii) + tmpImg(:,:,fc(ic(ii)));
%         fc(ic(ii))   = fc(ic(ii)) + 1;
%     end

end