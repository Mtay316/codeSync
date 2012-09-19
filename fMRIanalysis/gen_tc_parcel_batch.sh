# Batch preprocess IMAGEN data
# Notes: Specify script_path as required to call the python scripts
script_path='/home/bernardyng/code/fMRIanalysis'
for line in `cat /media/GoFlex/research/data/imagen/subjectLists/subjectList.txt`
do
echo $line
cd /media/GoFlex/research/data/imagen/$line/
# Generate parcel time courses for resting state fMRI data
python $script_path/gen_tc_parcel.py -tc restfMRI/tc_vox.mat -gm anat/gmMask.nii -wm anat/wmMask.nii -csf anat/csfMask.nii -t /media/GoFlex/research/data/imagen/group/fs_w_cer_parcel500_no_zero_tc.nii
# Generate parcel time courses for GCA fMRI data
python $script_path/gen_tc_parcel.py -tc gcafMRI/tc_vox.mat -gm anat/gmMask.nii -wm anat/wmMask.nii -csf anat/csfMask.nii -t /media/GoFlex/research/data/imagen/group/fs_w_cer_parcel500_no_zero_tc.nii
# Generate parcel time courses for faces fMRI data
python $script_path/gen_tc_parcel.py -tc facesfMRI/tc_vox.mat -gm anat/gmMask.nii -wm anat/wmMask.nii -csf anat/csfMask.nii -t /media/GoFlex/research/data/imagen/group/fs_w_cer_parcel500_no_zero_tc.nii
done

