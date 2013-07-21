function pImg = coneAbsorptionsWithGaussianEyeMovement(sensorNF, nSamples, sigma)
% Compute sensor voltage image for a given sensor and scene assuming that
% the sensor moves relative to the scene.
% 
%   pImg = coneAbsorptions(sensorNF, nSamples, sigma);
%
% Loop through a number of samples and calculate the photon image for
% each sample, concatenating the images to (row,col,nSamples).
% 
% The computational strategy is for each sample, compute nPerSample noise images
% and combine them into one according to the 2D Guassian Distribution
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
nPerSample = 50;
tmpImg  = sensorComputePhotonSamples(sensorNF,nPerSample);
[col, row, ~] = size(tmpImg);
pImg = zeros(col, row,nSamples);

% loop for samples
for i = 1 : nSamples
    % Generate Positions
    if mod(i,10)==0
        disp(i)
    end
    yPos = round(sz(2)*randn(nPerSample,1)*sigma(2)/fov);
    xPos = round(sz(1)*randn(nPerSample,1)*sigma(1)/fov);
    for j = 1 : nPerSample
        I = zeros(col,row);
        x = xPos(j); y = yPos(j);
        % Shift tmpImg according to [x y]
        if (x >= 0) && (x < sz(1))% Shift right
            I(x+1:end,:) = tmpImg(1:end-x,:,j);
        end
        if (x < 0) && (x > -sz(1)) % Shift left
            I(1:end+x,:) = tmpImg(1-x:end,:,j);
        end
        if (y >= 0) && (y < sz(2)) % Shift up
            I(:,y+1:end) = I(:,1:end-y);
        elseif y > sz(2)
            I = 0;
        end
        if (y < 0) && (y > -sz(2)) % Shift down
            I(:,1:end+y) = I(:,1-y:end);
        elseif y < -sz(2)
            I = 0;
        end
        pImg(:,:,i) = pImg(:,:,i) + I;
    end
    tmpImg = sensorComputePhotonSamples(sensorNF,nPerSample);
end
pImg = pImg / nPerSample;

%% End