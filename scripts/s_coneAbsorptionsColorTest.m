%% s_coneAbsoptionColorTest
%
I = repmat(reshape([200 200 200],[1 1 3]),[2 2 1])/255;
imwrite(I,'test1.png');
I = repmat(reshape([199 199 199],[1 1 3]),[2 2 1])/255;
imwrite(I,'test2.png');
% ---- Scene ----------
% fov         = 2;               % deg. Make sure we have plenty of scene samples per cone sample. By making the FOV small, we get plenty.
% im          = 'edge.jpg';
fov         =  0.02;             % shrink the fov to speed up calculations? 
dCal        = 'LCD-Apple.mat';
vd          = 2;                % Viewing distance- Two meters

% Create scene from image
fName1 = which('test1.png');
fName2 = which('test2.png');

scene1 = sceneFromFile(fName1,'rgb',[],dCal);
scene1 = sceneSet(scene1,'fov',fov);       %
scene1 = sceneSet(scene1,'distance',vd);  % Two meters

scene2 = sceneFromFile(fName2,'rgb',[],dCal);
scene2 = sceneSet(scene2,'fov',fov);       %
scene2 = sceneSet(scene2,'distance',vd);  % Two meters

%% Human Sensor
nSamples = 40;
pImg1 = ctConeSamples(scene1,40);
pImg2 = ctConeSamples(scene2,40);

s = sum(pImg1(:))/sum(pImg2(:));
pImg2 = pImg2*s;

%% Training
ind = randperm(2*nSamples);
[row,col,~] = size(pImg1);
I_c         = reshape(permute(pImg1,[3 1 2]),[nSamples, row*col]);
[row,col,~] = size(pImg2);
I_n         = reshape(permute(pImg2,[3 1 2]),[nSamples, row*col]);
I_train = [I_c; I_n];
Y = [ones(nSamples,1);-ones(nSamples,1)];

svmStruct = svmtrain(Y(ind(1:round(1.8*nSamples))),sparse(I_train(ind(1:round(1.8*nSamples)),:)),'-t 1 -q');
[predLabels,curAcc,~] = svmpredict(Y(ind(round(1.8*nSamples)+1:end)),sparse(I_train(ind(round(1.8*nSamples)+1:end),:)),svmStruct,'-q');