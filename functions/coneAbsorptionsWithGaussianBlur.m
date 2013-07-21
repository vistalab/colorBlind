function pImg = coneAbsorptionsWithGaussianBlur(sensorNF, nSamples, sigma)
% Compute sensor voltage image for a given sensor and scene assuming that
% the sensor moves relative to the scene.
% 
%   pImg = coneAbsorptionsWithGaussianBlur(sensorNF, nSamples, sigma);
%
% Generate nSamples of Gaussian Blurred cone absorptions
%
% Written by HJ


%% check inputs
if notDefined('sensorNF'), error('Need sensor'); end
if notDefined('nSamples'), error('Need sample number'); end
if notDefined('sigma'),    error('Need standard diviation'); end

%% Calculate
% Get sensor fov and sz
fov = sensorGet(sensorNF, 'fov'); 
sz = sensorGet(sensorNF, 'size');

% Init pImg
pImg  = sensorComputePhotonSamples(sensorNF,nSamples);

% Create Gaussian Filter
x = round(sz(1)*sigma(1)/fov);
y = round(sz(2)*sigma(2)/fov);
G = fspecial('gaussian',[x y],mean(sz.*sigma)/fov);

for i = 1 : nSamples
    %Filter it
    pImg(:,:,i) = imfilter(pImg(:,:,i),G,'same');    
end

%% End