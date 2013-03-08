% Convert significance map to 3D for FSLview
clear all;
addpath(genpath('D:/research/toolboxes/nifti'));
filepath = 'I:/research/code/imagen/anatFuncConnComparison/';

% Load parcel template
nii = load_nii('I:/research/data/imagen/group/ica_roi_parcel500_refined.nii');
template = nii.img;
rois = unique(template); % Parcel numbers
nROIs = length(rois)-1;
thresh = 380; % Corresponds to p-value = 0.01 for thresh = 0:0.25:100

% Choose method and contrast
method = 'OLS';
method = 'SGGM';
method = 'TTKgaussBlur';
method = 'TTKextrap5_';

contrast = 3;
load([filepath,'sig/sig',method,'59subs_ica_roi_parcel500_refined']);
sig3D = sigTo3D(squeeze(sig(contrast,:,thresh)),rois,template);

switch contrast
    case 1
        contrast = 'auditory_math';
    case 2
        contrast = 'visual_math';
    case 3
        contrast = 'listen_sentences';
    case 4
        contrast = 'read_sentences';
    case 5
        contrast = 'motor_left';
    case 6
        contrast = 'motor_right';
    case 7
        contrast = 'press_visual';
    case 8
        contrast = 'press_auditory';
    case 9
        contrast = 'hcheckerboard';
    case 10
        contrast = 'vcheckerboard';
end
nii = load_nii('I:/research/data/imagen/group/mni152_T1_3mm.nii');
nii.img = int8(sig3D);
save_nii(nii,[filepath,'sig3D/',contrast,'_sig3d',method,'.nii']);
disp(method);

