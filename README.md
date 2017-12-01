
Occlusion Filling

This is one approach to this project done by me. My partner has his own approach
and uses his code sperately.

Note this uses the the vlfeat library, found in http://www.vlfeat.org/download/vlfeat-0.9.20-bin.tar.gz
due to its size, it cannot be included in this zip file. Thus to run this
code you will need to download vlsift from the link above, and place it in the
./code folder.

The occlusion filling algorithm is located in ./code/project.m
Before running the script please set up the environment as this project uses
SIFT and DPM.

1. To setup execute: run('vlfeat-0.9.20/toolbox/vl_setup') on folder /code
2. To setup DPM, execute: addpath(genpath(pwd)) on directory /code to add all
paths. Then run compile.m inside folder /code/dmp

The pictures used is contained in the folder /code/data/project
