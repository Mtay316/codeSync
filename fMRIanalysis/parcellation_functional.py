"""
Functional Parcellation for IMAGEN data
Notes: Requires folder structure described in readMe.txt
"""
import os
import numpy as np
import nibabel as nib
from scipy import io
from scipy.ndimage import gaussian_filter
from nipy.labs import as_volume_img
#from nipy.labs import mask as mask_utils
from sklearn.decomposition import PCA
from sklearn.externals.joblib import Memory
from sklearn.feature_extraction.image import grid_to_graph
from sklearn.cluster import WardAgglomeration
from scipy.ndimage.morphology import binary_closing

# Choose number of parcels
n_parcels = 500.0

# Change path to files
BASE_DIR = "/volatile/bernardng/data/imagen/"
subList = np.loadtxt(os.path.join(BASE_DIR, "subjectLists/subjectList.txt"), dtype='str')
GM_DIR = "/volatile/bernardng/templates/spm8/rgrey.nii"

# Concatenating PCA-ed voxel timecourses across subjects
for sub in subList:
    tc = io.loadmat(os.path.join(BASE_DIR, sub, "restfMRI/tc_rest_vox.mat"))
    tc = tc["tc"]
    pca = PCA(n_components=10)    
    pca.fit(tc.T)
    tc_pca = pca.transform(tc.T)
    
    # Standardizing pca-ed time courses
    tc_std = np.std(tc_pca, axis=1)
    ind = tc_std > 1e-16
    tc_pca[ind, :] = tc_pca[ind, :] - tc_pca[ind, :].mean(axis=1)[:, np.newaxis]
    tc_pca[ind, :] = tc_pca[ind, :] / tc_pca[ind, :].std(axis=1)[:, np.newaxis]

    # Concatenate time courses across subjects
    if sub == subList[0]:
        tc_group = tc_pca
    else:
        tc_group = np.hstack((tc_group, tc_pca))
    print("Concatenating subject" + sub + "'s timecourses")

# Generate dilated GM mask
brain_img = as_volume_img(GM_DIR)
brain = brain_img.get_data()
dim = np.shape(brain)
brain = brain > 0.33
brain = binary_closing(brain, structure=np.ones((3, 3, 3))) # To account of inter-subject variability

# Spatial smoothing to encourage smooth parcels
tc_group = tc_group.reshape((dim[0], dim[1], dim[2], -1))
n_tpts = tc_group.shape[-1]
for t in np.arange(n_tpts):
    tc_group[:,:,:,t] = gaussian_filter(tc_group[:,:,:,t], sigma=1.5)
tc_group = tc_group.reshape((-1, n_tpts))
tc_group = tc_group[brain.ravel()==1, :]

# Functional parcellation with Ward clustering
print("Performing Ward Clustering")
mem = Memory(cachedir='.', verbose=1)
# Define connectivity based on brain mask
A = grid_to_graph(n_x=brain.shape[0], n_y=brain.shape[1], n_z=brain.shape[2], mask=brain)
# Create ward object
ward = WardAgglomeration(n_clusters=n_parcels, connectivity=A.tolil(), memory=mem)
ward.fit(tc_group.T)
template = np.zeros((dim[0], dim[1], dim[2]))
template[brain==1] = ward.labels_ + 1 # labels start from 0, which is used for background

# Remove parcels with zero timecourses in any of the subjects
template = template.ravel()
template_refined = template.copy()
label = np.unique(template)
for sub in subList:
    print str("Subject" + sub)
    # Load preprocessed voxel timecourses    
    tc = io.loadmat(os.path.join(BASE_DIR, sub, "restfMRI/tc_rest_vox.mat"))
    tc = tc["tc"]
   
    # Generate subject-specific tissue mask
    gm_file = os.path.join(BASE_DIR, sub, "anat", "gmMask.nii")
    gm_img = as_volume_img(gm_file)
    gm_img = gm_img.resampled_to_img(brain_img)
    gm = gm_img.get_data()
    wm_file = os.path.join(BASE_DIR, sub, "anat", "wmMask.nii")
    wm_img = as_volume_img(wm_file)
    wm_img = wm_img.resampled_to_img(brain_img)
    wm = wm_img.get_data()
    csf_file = os.path.join(BASE_DIR, sub, "anat", "csfMask.nii")
    csf_img = as_volume_img(csf_file)
    csf_img = csf_img.resampled_to_img(brain_img)
    csf = csf_img.get_data()
    probTotal = gm + wm + csf
    ind = probTotal > 0
    gm[ind] = gm[ind] / probTotal[ind]
    wm[ind] = wm[ind] / probTotal[ind]
    csf[ind] = csf[ind] / probTotal[ind]
    tissue = np.array([gm.ravel(), wm.ravel(), csf.ravel()])
    tissue_mask = tissue.argmax(axis=0) + 1
    tissue_mask[probTotal.ravel() == 0] = 0
    
    # Refine Parcellation    
    tc_parcel = np.zeros((tc.shape[0], label.shape[0] - 1))
    for i in np.arange(label.shape[0] - 1): # Skipping background
        ind = (template == label[i + 1]) & (tissue_mask == 1)
        tc_parcel[:, i] = np.mean(tc[:, ind], axis=1)
        if np.sum(tc_parcel[:, i]) == 0:
            template_refined[template == label[i + 1]] = 0
template_refined = template_refined.reshape([dim[0], dim[1], dim[2]])

# Ensure template labels do not have gaps in the numbers, e.g. 0 1 3 ...
rois = np.unique(template_refined)
template_refined = (rois[:, np.newaxis, np.newaxis, np.newaxis] == template_refined[np.newaxis, :]).astype(int).argmax(0)

# Saving the template
io.savemat(os.path.join(BASE_DIR, "group/parcel500.mat"), {"template": template_refined})
nii = nib.Nifti1Image(template_refined, brain_img.affine)
nib.save(nii, os.path.join(BASE_DIR, "group/parcel500.nii"))

            

