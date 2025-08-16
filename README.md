# Image analysis of lymph nodes from patients with multiple sclerosis and healthy controls

The following summarizes the analysis steps used in image analysis by Sarkkinen et al (DOI will be updated after acceptance of the manuscript).

## Segmentation

Segmentation of nuclei was done using StarDist´s (https://github.com/stardist/stardist) 2D_versatile_fluo_from_Stardist_Fiji algorithm, which was further trained with our own data set.

## Quantification 

The mean fluorescence intensity (MFI) for each cell mask was computed using the Bioformats library in MatLab (MATLAB version: 9.13.0 (R2022b)), see “quantification” folder. First, the folder (S3segmenter) was added to the path in Matlab, after which the quantification script (Quantification.m) was used. Download also bioformats_package.jar from https://www.openmicroscopy.org/bio-formats/downloads/ and add it to the S3segmenter folder.

## Quality control

Between staining rounds of CyCIF, some cells are lost due to tissue damage caused by the protocol or slight movement between microscopy images. We identified lost cells with python-based script (lost_cells.yml, lost_cells_script.py). The visualization of lost cells was done in Napari (https://napari.org/stable/). See "QC" folder. 
An example of how to use Jupyter Notebook via Anaconda. First, create a conda environment based on the .yml file. 
```
conda env create -f qc_for_lost_mac.yml
```
Then, activate the environment
```
conda activate qc_for_lost
```
And open the Jupyter notebook
```
jupyter notebook
```
Please note that the Conda environment qc_for_lost_mac was created and exported from a Mac computer. While the environment should work on other platforms, there may be some compatibility issues due to differences in operating systems and package dependencies. You can find a Windows version under the name qc_for_lost_windows.

## Analysis of BCL6 signal

Due to incomplete bleaching of the cytoplasmic CD27 signal from the previous staining cycle, nuclear BCL6 staining was partially obscured. The BCL6 expression was quantified specifically within nuclear masks that were uniformly shrunken by 2 pixels. 

First, set up scimap.xyz by following the tutorial at https://scimap.xyz/Getting%20Started/ 

Then, activate the scimap environment, and open the reduce_mask_xosxos.py file and specify your input and output directories. Then run
```
python reduce_mask_xosxos.py
```

Within these masks, perform quantification again. Download the quantification script from https://github.com/farkkilab/image_processing/tree/main/pipeline/3_quantification and the quantification yml file from https://github.com/farkkilab/image_processing/tree/main/envs.

Create a conda environment
```
conda env create --name quantification --file=path/to/ymlfile/environments.yml
```
Then, activate the environment
```
conda activate quantification
```
Edit the input and output folders in the script. The image stacks should be in one folder, and masks in one folder, and the files should have the same names. You also need a csv file with channel names. Then,
```
python quantification_workflow.py -o ../../TMA_reduced_quantified -ch ../../channel_names.csv -c 4
```
For additional help, see https://github.com/farkkilab/image_processing from Färkkilä Lab. Note, you can also perform the initial quantification by following their steps.

To check for BCL6 status, again activate the scimap conda environment, navigate to the BCL6_script.ipynb, edit the paths, run, and inspect the results.

## Single-cell (spatial) analysis

Merging and editing of the data frames for cell phenotyping, followed by cell abundance exploration, statistics, and part of neighborhood analysis, were performed using R studio. Cell type calling, including data normalization and spatial analysis, was performed using Scimap (scimap.xyz). For further information, see the "analysis" folder, which contains the UPDATE_FILE_NAME.Rmd and Jupyter notebook files. Cell counts were normalised to tissue area, which was calculated with QuPath (v. 0.4.3) using the "Create thresholder" tool from the first DAPI image of the image stacks. This resulted data frame area_images.csv, see "analysis" folder.

## EBER-ISH analysis

The analysis of EBER-ISH-stained TMA slides was performed with QuPath (v. 0.4.3) using the "Positive cell detection" tool. For this, see the tutorial at https://qupath.readthedocs.io/en/stable/docs/tutorials/cell_detection.html#run-positive-cell-detection. For statistical analysis, see the "analysis" folder, which contains the UPDATE_FILE_NAME.Rmd.

