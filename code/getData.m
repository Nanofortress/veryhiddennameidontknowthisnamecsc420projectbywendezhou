function data = getData(imname, imset, whatdata)

% example to run: data = getData('000120', 'train', 'left');
% to load a detector, e.g.: data = getData([],[],'detector-car');

if nargin < 2
    fprintf('run with: data = getData(imname, imset, whatdata);\n');
    fprintf('where:\n');
    fprintf('   imset: ''train'' or ''test''\n');
    fprintf('   whatdata: ''list'', ''left'', ''right'', ''calib'', ''gt-left'', ''gt-right'', ''disp''\n')
    fprintf('   ''left-plot'' and ''right-plot'' and ''disp-plot'' will plot the data\n');
    fprintf('   ''detector-car'' will load a car detector, ''detector-person'', ''detector-cyclist'' similarly\n');
    fprintf('   ''superpixels'' (if you ran spsstereo code for all images, you also got superpixels)\n');
    fprintf('if the function doesn''t work, please check if globals.m is correctly set\n');
end;

globals;
data = [];

switch whatdata
    case {'list'}
        fid = fopen(fullfile(DATA_DIR, imset, [imset '.txt']), 'r+');
        ids = textscan(fid, '%s');
        ids = ids{1};
        fclose(fid);
        data.ids = ids;
    case {'left', 'left-plot', 'right', 'right-plot'}
        leftright = strrep(whatdata, '-plot', '');
        imfile = fullfile(DATA_DIR, imset, leftright, sprintf('%s.jpg', imname));
        im = imread(imfile);
        data.im = im;
        if strcmp(whatdata, sprintf('%s-plot', leftright))
            figure('position', [100,100,size(im,2)*0.7,size(im,1)*0.7]);
            subplot('position', [0,0,1,1]);
            imshow(im);
        end;
    case {'disp', 'disp-plot'}
        dispdir = fullfile(DATA_DIR, imset, 'results');
        dispfile = fullfile(dispdir, sprintf('%s_left_disparity.png', imname)); 
        if ~exist(dispfile, 'file')
            fprintf('you haven''t computed disparity yet...\n');
        else
            disparity = imread(dispfile);
            disparity = double(disparity)/256;
        end;
        data.disparity = disparity;
        if strcmp(whatdata, 'disp-plot')
            figure('position', [100,100,size(disparity,2)*0.7,size(disparity,1)*0.7]);
            subplot('position', [0,0,1,1]);
            imagesc(disparity);
            axis equal;
        end;
    case 'calib'
        % read internal params
        calib_dir = fullfile(DATA_DIR, imset, 'calib');
        [~, ~, calib] = loadCalibration(fullfile(calib_dir, sprintf('%s.txt', imname)));
        [Kl,~,tl] = KRt_from_P(calib.P_rect{3});  % left camera
        [~,~,tr] = KRt_from_P(calib.P_rect{4});  % right camera
        f = Kl(1,1);
        baseline = abs(tr(1)-tl(1));   % distance between cams
        data.f = f;
        data.baseline = baseline;
        data.K = Kl;
        data.P_left = calib.P_rect{3};
        data.P_right = calib.P_rect{4};
    case {'gt-left', 'gt-right', 'gt-left-plot', 'gt-right-plot', 'gt-left-plot-3d', 'gt-right-plot-3d'}
        leftright = strrep(strrep(whatdata, 'gt-', ''), '-plot', '');
        leftright = strrep(leftright, '-3d', '');
        label_dir = fullfile(DATA_DIR, imset, sprintf('gt_%s', leftright));
        img_idx = str2num(imname);
        objects = readLabels(label_dir,img_idx);
        data.objects = objects;
        calibdata = getData(imname, imset, 'calib');
        P = calibdata.(sprintf('P_%s', leftright));
        for i = 1 : length(objects)
           [corners_2D,~,corners_3D] = computeBox3D(objects(i),P);
           orientation3D = computeOrientation3D(objects(i),P);
           objects(i).corners3D = corners_3D;
           objects(i).corners2D = corners_2D;
           objects(i).orientation3D = orientation3D;
        end;
        if strcmp(leftright, 'left')
           labels_file = fullfile(label_dir, [imname '.png']);
           seg = double(imread(labels_file));
           data.gt_seg = seg;
        end;
        which = strrep(whatdata, sprintf('gt-%s-plot', leftright), '');
        
        if strcmp(whatdata, sprintf('gt-%s-plot%s', leftright, which))
           imgdata = getData(imname, imset, leftright);
           seg = [];
           if isfield(data, 'gt_seg')
               seg = data.gt_seg;
           end;
           if isempty(which)
              plotGT(imgdata.im, objects, seg, '2d')
           else
              plotGT(imgdata.im, objects, seg, '3d') 
           end;
           data.im = imgdata.im;
        end;
    case {'detector-car', 'detector-person', 'detector-pedestrian', 'detector-cyclist'}
        cls = strrep(whatdata, 'detector-', '');
        files = dir(fullfile(DETECTOR_DIR, sprintf('%s_final*.mat', cls)));
        if isempty(files)
            fprintf('file doesn''t exist!\n');
        else
            data = load(fullfile(DETECTOR_DIR, files(1).name));
        end;
    case {'superpixels'}
        dispdir = fullfile(DATA_DIR, imset, 'results');
        spfile = fullfile(dispdir, sprintf('%s_segment.png', imname)); 
        spim = [];
        if ~exist(spfile, 'file')
            fprintf('you haven''t ran spsstereo code yet...\n');
        else
            spim = imread(spfile);
            spim = double(spim);
        end;
        data.spim = spim;
    otherwise 
        disp('unknown data type, try again');
    
end;
