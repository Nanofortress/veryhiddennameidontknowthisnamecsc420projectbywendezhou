%VOCEVALSEG Evaluates a set of segmentation results.
% VOCEVALSEG(VOCopts,ID); prints out the per class and overall
% segmentation accuracies. Accuracies are given using the intersection/union 
% metric:
%   true positives / (true positives + false positives + false negatives) 
%
% [ACCURACIES,AVACC,CONF] = VOCEVALSEG(VOCopts,ID) returns the per class
% percentage ACCURACIES, the average accuracy AVACC and the confusion
% matrix CONF.
%
% [ACCURACIES,AVACC,CONF,RAWCOUNTS] = VOCEVALSEG(VOCopts,ID) also returns
% the unnormalised confusion matrix, which contains raw pixel counts.
function [accuracies,avacc,conf,rawcounts] = evalseg(resdir, gtids)

globals;
imset = 'test';

gt_dir = fullfile(DATA_DIR, imset, 'gt_left');
% evaluating assign

if nargin < 1
    resdir = fullfile(DATA_DIR, 'train', 'results-seg');
    %resdir = gt_dir;
end;
if nargin < 2;
   gt_filename = fullfile(DATA_DIR, imset, [imset '.txt']);
   fid = fopen(gt_filename, 'r+');
   gtids = textscan(fid, '%s');
   gtids = gtids{1};
   fclose(fid);
end;

%[gtids]=textread(fullfile(DATASET_ROOT, [testset '.txt']),'%s');

classes{1} = 'car';

% number of labels = number of classes plus one for the background
num = length(classes) + 1; 
nclasses = length(classes);
confcounts = zeros(num);
count=0;
tic;
fprintf('testing %d images\n', length(gtids))
for i=1:length(gtids)
    % display progress
    if toc>1
        fprintf('%s confusion: %d/%d\n',imset,i,length(gtids));
        drawnow;
        tic;
    end
        
    imname = gtids{i};
    
    % ground truth label file
    gtfile = fullfile(gt_dir, [imname '.png']);
    if ~exist(gtfile, 'file')
        fprintf('gt file doesnt exist, skipping\n');
        continue;
    end;
    data = getData(imname, imset, 'gt-left');
    [gtim,map] = imread(gtfile);    
    gtim = double(gtim);
    gtim = getDontcare(gtim, data.objects);
    
    % results file
    resfile = fullfile(resdir, [imname '.png']);
    if ~exist(resfile, 'file')
       %resfile = fullfile(resdir, ['newseg' imname '.png']); 
       %resfile = fullfile(resdir, [imname '_sg.jpg']);
       resfile = fullfile(resdir, [sprintf('imm%d', i) '.png']);
    end;
    if exist(resfile, 'file')
       [resim,map] = imread(resfile);
    else
        resim = zeros(size(gtim));
    end;
    %stanislav
    %resfile = fullfile(resdir, [imname '-seg.mat']);
    %data1=load(resfile);
    %resim = data1.segmented_im;
    %resim=max(resim,[],3);
    resim = double(resim > 0.1);

    szgtim = size(gtim); szresim = size(resim);
    if any(szgtim~=szresim)
        error('Results image ''%s'' is the wrong size, was %d x %d, should be %d x %d.',imname,szresim(1),szresim(2),szgtim(1),szgtim(2));
    end
    
    %pixel locations to include in computation
    locs = gtim<255;
    gtim(locs) = double(gtim(locs) > 0);
    
    % joint histogram
    sumim = 1+gtim+resim*num; 
    hs = histc(sumim(locs),1:num*num); 
    count = count + numel(find(locs));
    confcounts(:) = confcounts(:) + hs(:);
end

% confusion matrix - first index is true label, second is inferred label
%conf = zeros(num);
conf = 100*confcounts./repmat(1E-20+sum(confcounts,2),[1 size(confcounts,2)]);
rawcounts = confcounts;

% Percentage correct labels measure is no longer being used.  Uncomment if
% you wish to see it anyway
%overall_acc = 100*sum(diag(confcounts)) / sum(confcounts(:));
%fprintf('Percentage of pixels correctly labelled overall: %6.3f%%\n',overall_acc);

accuracies = zeros(nclasses,1);
fprintf('Accuracy for each class (intersection/union measure)\n');
for j=1:num
   
   gtj=sum(confcounts(j,:));
   resj=sum(confcounts(:,j));
   gtjresj=confcounts(j,j);
   % The accuracy is: true positive / (true positive + false positive + false negative) 
   % which is equivalent to the following percentage:
   accuracies(j)=100*gtjresj/(gtj+resj-gtjresj);   
   
   clname = 'background';
   if (j>1), clname = classes{j-1};end;
   fprintf('  %14s: %6.3f%%\n',clname,accuracies(j));
end
accuracies = accuracies(2:end);
avacc = mean(accuracies);
fprintf('-------------------------\n');
fprintf('Car accuracy: %6.3f%%\n',avacc);


function gtim = getDontcare(gtim, objects)

for i = 1 : length(objects)
    o = objects(i);
    cls = o.type;
    do = 1;
    if strcmp(cls, 'DontCare') || strcmp(cls, 'Truck')
        top = min(max(1,round(o.y1)), size(gtim, 1));
        bottom = min(max(1,round(o.y2)), size(gtim, 1));
        left = min(max(1,round(o.x1)), size(gtim, 2));
        right = min(max(1,round(o.x2)), size(gtim, 2));
        gtim(top:bottom,left:right)=255;
    elseif strcmp(cls, 'Van')
        do = 0;
    elseif o.occlusion > 2
        do = 0;
    elseif o.truncation > 0.4
        do = 0;
    end;
    if do==0
        gtim(gtim==i) = 255;
    end;
end;
