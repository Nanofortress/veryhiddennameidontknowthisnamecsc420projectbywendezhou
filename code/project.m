% Note to self: To Setup the environment before running...
% Run excute addpath(genpath(pwd)) on folder /code to add path, then
% run compile.m inside folder code/dmp to setup DPM. 
% Execute run('vlfeat-0.9.20/toolbox/vl_setup') on folder /code to setup 
% SIFT.


% 2.5D Occlusion Filling. (beta)

close all;
clearvars;

% Read the test images, where source is the image with occlusion, data is
% the image without occlusion.
source = imread('../data/project/source.jpg');
data = imread('../data/project/data.jpg');

% Use DPM to detect the objects (Cars). If it has not yet being detected 
% before. Results are stored in the folder /results.
recompute = 0;
if (recompute == 1 || exist('results/ds_source.mat', 'file') == 0 || ...
    exist('results/ds_target.mat', 'file') == 0)
    dataCar = getData([], [], 'detector-car');
    model = dataCar.model;
    
    % Detect object (Cars) on source image.
    
    % Resize the data image, it works better for detecting small objects in
    % DPM.
    f = 3;
    sourcer = imresize(source,f);

    % Detect car objects.
    % You may need to reduce the threshold if you want more detections.
    model.thresh = model.thresh*0.5;
    [ds, bs] = imgdetect(sourcer, model, model.thresh);
    % Non-maximum suppression to eliminate overlapping object detection.
    nms_thresh = 0.3;
    top = nms(ds, nms_thresh);
    if model.type == model_types.Grammar
        bs = [ds(:,1:4) bs];
    end
    if ~isempty(ds)
        % resize back
        ds(:, 1:end-2) = ds(:, 1:end-2)/f;
        bs(:, 1:end-2) = bs(:, 1:end-2)/f;
    end
    ds_source = ds(top, :);

    % Save ds in results folder.
    filename = sprintf('ds_source.mat');
    save(['results/' filename],'ds_source');
    
    % Detect object (Cars) on data image.

    % Resize the data image, it works better for detecting small objects in
    % DPM.
    f = 3;
    datar = imresize(data,f);

    % Detect car objects.
    % You may need to reduce the threshold if you want more detections.
    model.thresh = model.thresh*0.5;
    [ds, bs] = imgdetect(datar, model, model.thresh);
    % Non-maximum suppression to eliminate overlapping object detection.
    nms_thresh = 0.3;
    top = nms(ds, nms_thresh);
    if model.type == model_types.Grammar
        bs = [ds(:,1:4) bs];
    end
    if ~isempty(ds)
        % Resize back.
        ds(:, 1:end-2) = ds(:, 1:end-2)/f;
        bs(:, 1:end-2) = bs(:, 1:end-2)/f;
    end
    ds_data = ds(top, :);

    % Save ds in results folder.
    filename = sprintf('ds_data.mat');
    save(['results/' filename],'ds_data');

% The DPM has already been computed.    
else
    ds_source = importdata('results/ds_source.mat');
    ds_data = importdata('results/ds_data.mat');
end

% Visualize the segmented objects on source and data images.
% Note: the objects detected might be different, due to the Non-maximum 
% suppression.
figure;
image(source); 
axis image;
axis off;
showboxes(source, ds_source, 'r', 'Car');
figure;
image(data); 
axis image;
axis off;
showboxes(data, ds_data, 'r', 'Car');


% TODO:
% steps next
% 1. use sift to find all the matching key points on the two images
% 2. get the 4 pairs on matching key points such that they form the 4 most
% outer corners of the rectangle that indicates the transformation from
% data image to source image. (where non of the four matching keypoints
% goes out of boundary in their respective images)
% 3. find the transformation matrix of those 4 points.
% 4. find objects (using the boundaries of the objects) in data image such
% that it is not present in the source image.
% 5. apply the transformation to all pixels inside the objects not present
% and project those pixels onto the source image.
% Result: gets the source image such that all of its ocluded objects are
% being filled.











% Custom function to show the rectagle boxes labeling the objects. 
% Used in Q2 (c).
% Note: this is a modified version of the function showboxes (same name) in 
%       the file code/showboxesMy.m 
function showboxes(im, boxes, col, label)
    cwidth = 2;
    if ~isempty(boxes)
          % draw the boxes with the detection window on top (reverse order)
          if 1
              %for i = numfilters:-1:1
              for i = 1:1
                    x1 = boxes(:,1+(i-1)*4);
                    y1 = boxes(:,2+(i-1)*4);
                    x2 = boxes(:,3+(i-1)*4);
                    y2 = boxes(:,4+(i-1)*4);
                    % remove unused filters
                    del = find(((x1 == 0) .* (x2 == 0) .* (y1 == 0) .* (y2 == 0)) == 1);
                    x1(del) = [];
                    x2(del) = [];
                    y1(del) = [];
                    y2(del) = [];
                    if i == 1
                      c = col; %[160/255 0 0];
                      s = '-';
                    else
                      c = 'b';
                      s = '-';
                    end
                    text(x1,y1-20,label,'Color',c,'FontSize',14)
                    line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, 'linewidth', cwidth, 'linestyle', s);
              end
          end
    end
end










