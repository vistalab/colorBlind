function scene = ctrdRenderImage2SceneWithDist(gd,openISET,dist)
% Push the data in the Render window data to an ISET scene
%
%   scene = = ctrdRenderImage2Scene(gd,openISET,dist)
%
% An ISET scene window is opened with the rendered image data.
%
% Example:
%    ctrdRenderImage2Scene
%
% See also ctrdRenderImage2Scene, ctrdSaveVirtualDisplayImageAsScene
% File adopted from ctToolbox
%
% (HJ) (c) PDCSOFT Team, 2013

if nargin < 3,  dist = 1.2; end

if ieNotDefined('gd'), gd = ctGetObject('render'); end
if ieNotDefined('openISET'), openISET = 1; end

vd = renderGet(gd,'vDisplay');
imgRendered  = vDisplayGet(vd, 'ImageRawData');

if isempty(imgRendered), disp('No rendered image'); return; end;

wave    = vDisplayGet(vd, 'Wavelength samples');
spd     = vDisplayGet(vd, 'spd matrix');
dpMeter = dpi2mperdot(vDisplayGet(vd,'dpi'),'meters');

% This is the total width of the display in meters
imgMeters = dpMeter*vDisplayGet(vd,'input col');

scene = sceneCreate;
scene = sceneSet(scene,'name','ctFont');
scene = sceneSet(scene,'wave',wave');
scene = sceneSet(scene,'distance',dist);

% Figure out the character size from the dpi and distance
deg   = rad2deg(atan2(imgMeters,dist));
scene = sceneSet(scene,'wAngular',deg);   

photonImg = Energy2Quanta(wave,imageLinearTransform(imgRendered,spd));
scene = sceneSet(scene,'photons',photonImg);

[luminance, meanLuminance] = sceneCalculateLuminance(scene);
scene = sceneSet(scene,'luminance',luminance);
scene = sceneSet(scene,'meanLuminance',meanLuminance);

% Either just return the data or open up an ISET window
if openISET
    vcAddAndSelectObject(scene);
    sceneWindow;
end

return


