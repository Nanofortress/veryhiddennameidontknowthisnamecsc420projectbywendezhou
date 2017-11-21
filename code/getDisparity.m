function disp = getDisparity(imset, imname)
% imset ... either 'train' or 'test'

globals;

imfile_left = fullfile(DATA_DIR, imset, 'left', sprintf('%s.png', imname));
imfile_right = fullfile(DATA_DIR, imset, 'right', sprintf('%s.png', imname));
path = pwd;
cd(SPSSTEREO_PATH);
outdir = fullfile(DATA_DIR, imset, 'results');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end;
outfile = fullfile(outdir, sprintf('%s_left_disparity.png', imname)); 
if ~exist(outfile, 'file')
    fprintf('running spsstereo, may take a few secs...\n');
    tic;
    convertToPng(imfile_left)
    convertToPng(imfile_right)
    cmd = sprintf('./spsstereo %s %s', imfile_left, imfile_right);
    unix(cmd);
    e=toc;
    cleanup(imfile_left)
    cleanup(imfile_right)
    fprintf('finished! total time: %0.4f\n', e);
    cmd = sprintf('mv %s_*.* %s/', imname, outdir);
    unix(cmd);
end;

disp = imread(outfile);
disp = double(disp)/256;

cd(path);

function convertToPng(imfile)

imfile_or = strrep(imfile, '.png', '.jpg');
im = imread(imfile_or);
imwrite(im, imfile);

function cleanup(imfile)
delete(imfile);