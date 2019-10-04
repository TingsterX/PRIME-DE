# PRIMate-Data Exchange (PRIME-DE) Data release and minimal data preprocessing
Resource: [PRIME-DE](http://fcon_1000.projects.nitrc.org/indi/indiPRIME.html)


 - Quality Assessment [QAP](http://preprocessed-connectomes-project.org/quality-assessment-protocol)
 - Brain Extraction 
 - Functional Registration 
 
### Brain Extraction

- Template: [NMT Macaque Template] (https://afni.nimh.nih.gov/NMT)
- Site-specific Template: One animal which has been manually edited and aligned to NMT space
- Brain extraction: NMT was used as an atlas for brain extraction, if failed, the site-specific good subject was used to revised the brain mask

```
bash MaskandRegister.bash <subject_directory> <subject> <atlas_HEAD> <atlas_BRAIN>
```

### Structure alignment
```
x_align_anat.sh <TemplateHead> <TemplateBrain> <TemplateMask> <Anat> <AnatMask>
```

### Function alignment
```
x_align_anat.sh <TemplateHead> <TemplateBrain> <TemplateMask> <Anat> <AnatMask>
```