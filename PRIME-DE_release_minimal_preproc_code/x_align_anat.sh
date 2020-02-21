#!/bin/bash
# Align anatomical image to a template.
# usuage: x_align_anat.sh <TemplateHead> <TemplateBrain> <TemplateMask> <Anat> <AnatMask>
#


# figure generation.
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
if [ $# != 5 ]; then
    echo "Your input doesn't contains enough arguments"
else


    # template image
    Template_head=$1
    Template_brain=$2
    Template_mask=$3

    # anatomicla images and funcitonal image
    anat=$4
    anat_mask=$5

    workingdir=$(dirname $anat)

    pushd ${workingdir}

    # get anat brain
    if [[ -f $anat ]] && [[ -f $anat_mask ]];then
        anat_brain=${anat_mask/mask/brain}
        fslmaths $anat -mul $anat_mask $anat_brain
    fi

    # do anatmicla registration.
    if [[ -f $anat_brain ]];then
        cp $anat_brain brain.nii.gz
        anat_brain=brain.nii.gz
        if [[ -f $anat_mask ]];then
            cp $anat_mask mask.nii.gz
            anat_mask=mask.nii.gz
        else
            fslmaths brain.nii.gz -bin mask.nii.gz
        fi


        ls $Template_mask
        mri_nu_correct.mni --i $anat_brain --o brain_nu.nii.gz  --n 6 --proto-iters 150 --stop .0001;
        N4BiasFieldCorrection -d 3 -i brain_nu.nii.gz -o brain_nuN4.nii.gz;
        flirt -ref $Template_brain -in brain_nuN4.nii.gz -omat anat2Template.mat
        echo "Doing fnirt, may take a little while"
        fnirt --in=brain_nuN4.nii.gz --aff=anat2Template.mat --cout=anat2Template_warp --iout=fnirt_anat2Template --jout=anat2Template_jac --ref=$Template_head --refmask=$Template_mask --warpres=10,10,10
        vcheck $Template_brain fnirt_anat2Template.nii.gz $workingdir'/anat_align.png'
    fi

    popd

fi
