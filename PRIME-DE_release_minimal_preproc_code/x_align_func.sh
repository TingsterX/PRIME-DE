#!/bin/bash
# Align functional image to a template, it uses a warp file created form the anatomy to template in fnirt.
# usuage: x_align_func.sh <TemplateBrain> <Func> <AnatBrain> <anat2template_warp>
#

# figure generation function.
vcheck (){
    # this overlay oen image to another and save 3 slices into one figure.
    overlay=$1
    underlay=$2
    figout=$3
    workdir=`dirname ${figout}`
    pushd ${workdir}
    minImage=`fslstats ${overlay} -P 10`
    maxImage=`fslstats ${overlay} -P 90`
    slicer ${overlay} ${underlay} -i ${minImage} ${maxImage} -s 2 -x 0.60 sl1.png -y 0.60 sl2.png -z 0.65 sl3.png
    pngappend sl1.png + sl2.png + sl3.png ${figout}
    rm sl?.png
    popd
}



# Check arguments
if [ $# != 4 ]; then
    echo "Your input doesn't contains enough arguments"
else

    # template image
    Template_brain=$1


    # anatomicla images and funcitonal image
    func=$2
    anat_brain=$3
    anat2template_warp=$4

    workingdir=$(dirname $func)

    pushd ${workingdir}

    cp $func func.nii.gz
    fslmaths $anat_brain -bin anat_mask.nii.gz
    
    # func
    if [[ -f "func.nii.gz" ]] && [[ -f "$anat2template_warp" ]] && [[ -f "anat_mask.nii.gz" ]];then
        nt=$(3dinfo -ntimes func.nii.gz)
        fslroi func.nii.gz example_func $((nt/2)) 1
        N4BiasFieldCorrection -d 3 -i example_func.nii.gz -o example_func_N4.nii.gz;

        # func mask from bet2 and 3dAutomask
        3dAutomask -prefix example_func_N4_3dautomask.nii.gz example_func_N4.nii.gz
        #3dAFNItoNIFTI -prefix example_func_N4_3dautomask.nii.gz example_func_N4_3dautomask+orig 
        bet2 example_func_N4.nii.gz example_func_N4_bet2mask.nii.gz
        fslmaths example_func_N4_bet2mask.nii.gz -mul example_func_N4_3dautomask.nii.gz -bin combine_func_mask.nii.gz
        fslmaths combine_func_mask.nii.gz -mul example_func_N4.nii.gz example_func_N4_brain_init.nii.gz

        # anatomical normalization
        mri_nu_correct.mni --i $anat_brain --o brain_nu.nii.gz  --n 6 --proto-iters 150 --stop .0001;
        N4BiasFieldCorrection -d 3 -i brain_nu.nii.gz -o brain_nuN4.nii.gz;

        # registration
        flirt -dof 6 -in example_func_N4_brain_init.nii.gz -ref brain_nuN4.nii.gz -omat func_2_T1w_init.mat -out example_func__N4_2_t1w_init.nii.gz
        convert_xfm -inverse -omat T1w_2_func.mat func_2_T1w_init.mat
        flirt -applyxfm -init T1w_2_func.mat -in anat_mask.nii.gz -interp nearestneighbour -out func_mask_refine.nii.gz -ref example_func_N4_brain_init.nii.gz
        fslmaths func_mask_refine.nii.gz -mul example_func_N4.nii.gz example_func_N4_brain_refine.nii.gz
        #flirt -applyxfm -init func_2_T1w_init.mat -in example_func_brain_refine.nii.gz -ref brain.nii.gz -out example_func_2_t1w_refine.nii.gz
        flirt -dof 6 -in example_func_N4_brain_refine.nii.gz -ref brain.nii.gz -omat func_2_T1w_refine.mat -out example_func_N4_2_t1w_refine.nii.gz
        fslmaths example_func_N4_2_t1w_refine.nii.gz -bin func_mask_refine_refine.nii.gz

        fslmaths example_func_N4.nii.gz -mul func_mask_refine.nii.gz example_func_N4_brain_refine_refine.nii.gz
        #flirt -applyxfm -init func_2_T1w_refine.mat -in func_brain.nii.gz -ref brain.nii.gz -out func_2_t1w.nii.gz

        applywarp --ref=$Template_brain --in=example_func_N4_brain_refine_refine.nii.gz --out=example_func2Template.nii.gz --warp=T1w2Yerkes19_warp.nii.gz --premat=func_2_T1w_refine.mat

        #fslmaths func_warp.nii.gz -Tmean func_warp_tmean.nii.gz
        vcheck example_func2Template.nii.gz $Template_brain $workingdir"/fucn_align.png"

    fi
    popd
fi

