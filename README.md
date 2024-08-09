# Image analysis of lymph nodes from patients with multiple sclerosis and healthy controls

Following summarizes the analysis steps used in image analysis by Sarkkinen et al (DOI will be updated after acceptance of the manuscript).

## Segmentation

Segmentation of nuclei was done using StarDist´s (https://github.com/stardist/stardist) 2D_versatile_fluo_from_Stardist_Fiji algorithm, which was further trained with own data set.

## Quantification and Quality control

The details of quantification and quality control steps can be found from https://github.com/SarkkinenJ/OV_CA_TLS (public soon)

The mean fluorescence intensity (MFI) for each cell mask was computed using the Bioformats library in MatLab (MATLAB version: 9.13.0 (R2022b)), see “quantification” folder behind the link above. Between staining rounds of CyCIF, some cells are lost due to tissue damage caused by the protocol or slight movement between microscopy images. We identified lost cells with python-based script (lost_cells.yml, lost_cells_script.py). The visualization of lost cells was done in Napari (https://napari.org/stable/). See "QC" folder behind the link above.

## Single-cell (spatial) analysis

Merging and editing of the data frames for cell phenotyping followed by cell abundance exploration, statistics, and part of neighborhood analysis were perfomed using R studio. Cell type calling including data normalization and spatial analysis was performed using Scimap (scimap.xyz). For further information, see "analysis" folder, which contains the apeced_manus.Rmd and jupyter notebook files.

## EBER-ISH analysis

The analysis of EBER-ISH stained TMA slides was performed with QuPath (v. 0.4.3) using "Positive cell detection" -tool. For this, see tutorial at https://qupath.readthedocs.io/en/stable/docs/tutorials/cell_detection.html#run-positive-cell-detection.
