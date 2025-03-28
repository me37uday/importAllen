# Description of current usage

For development, you need a conda environment (installable directly from the .yml file here). It only needs reticulate and usethis (used for documentation etc.). Once the all stuff will run and work as a package, the requirements will be installed automatically with the package.

From the environment, by starting a R session, you should be able to run 
``` 
source('R/setup.R')
setup_environment()
```

which will create the python env for reticulate to work. Then, the rest is just for downloading and managing metadata.

### load_data.R

Python imports:

```
library(reticulate)
setup_environment()
# Convert the R path to a Python path
py_download_base <- import("pathlib")$Path(download_base)

# Import necessary Python modules
pandas <- import("pandas")
anndata <- import("anndata")
AbcProjectCache <- import("abc_atlas_access.abc_atlas_cache.abc_project_cache")$AbcProjectCache
get_gene_data <- import("abc_atlas_access.abc_atlas_cache.anndata_utils")$get_gene_data
py <- import_builtins()

print("Finished Python importing")
```


This downloads the cache and creates a dataframe
```
# Create the cache object
abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)

print("Finished creating cache")

# Load the cell metadata
cell <- abc_cache$get_metadata_dataframe(directory = 'WHB-10Xv3', file_name = 'cell_metadata', dtype = dict(cell_label = 'str'))
print("Finished loading cell metadata")
rownames(cell) <- cell$cell_label
cell$cell_label <- NULL
cat("Number of cells = ", nrow(cell), "\n")

```

The rest is just handling the dataframe.. But currently it's not working right. In particular, the latest error is:

```
> source('R/load_data.R')
> load_data()
[1] "Finished setting up Python environment"
[1] "Finished Python importing"
[1] "Finished creating cache"
cell_metadata.csv: 100%|████████████████████| 830M/830M [00:59<00:00, 14.0MMB/s]
[1] "Finished loading cell metadata"
Number of cells =  3369219 
cluster_to_cluster_annotation_membership.csv: 100%|█| 1.02M/1.02M [00:01<00:00, 
cluster_annotation_term_set.csv: 100%|████| 1.33k/1.33k [00:00<00:00, 5.85kMB/s]
region_of_interest_structure_map.csv: 100%|█| 8.82k/8.82k [00:00<00:00, 28.9kMB/
Structure of roi:
'data.frame':	140 obs. of  5 variables:
 $ region_of_interest_label: chr  "Human A13" "Human A14" "Human A14" "Human A19" ...
 $ structure_identifier    : chr  "DHBA:10202" "DHBA:10196" "DHBA:10197" "DHBA:10272" ...
 $ structure_symbol        : chr  "A13" "A14r" "A14c" "PSC" ...
 $ structure_name          : chr  "caudal division of OFCi (area 13)" "rostral subdivision of area 14" "caudal subdivision of area 14" "peristriate cortex (area 19)" ...
 $ color_hex_triplet       : chr  "#CAB781" "#B8A26D" "#B8A26D" "#D14D46" ...
 - attr(*, "pandas.index")=RangeIndex(start=0, stop=140, step=1)
[1] "Finished loading cluster metadata"
[1] "Structure of cell:"
'data.frame':	3369219 obs. of  16 variables:
 $ cell_barcode              : chr  "CATGGATTCTCGACGG" "TCTTGCGGTGAATTGA" "CTCATCGGTCGAGCAA" "TTGGATGAGACAAGCC" ...
 $ barcoded_cell_sample_label: chr  "10X386_2" "10X383_5" "10X386_2" "10X378_8" ...
 $ library_label             : chr  "LKTX_210825_01_B01" "LKTX_210818_02_E01" "LKTX_210825_01_B01" "LKTX_210809_01_H01" ...
 $ feature_matrix_label      : chr  "WHB-10Xv3-Neurons" "WHB-10Xv3-Neurons" "WHB-10Xv3-Neurons" "WHB-10Xv3-Neurons" ...
 $ entity                    : chr  "nuclei" "nuclei" "nuclei" "nuclei" ...
 $ brain_section_label       : chr  "H19.30.001.CX.51" "H19.30.002.BS.94" "H19.30.001.CX.51" "H19.30.002.BS.93" ...
 $ library_method            : chr  "10Xv3" "10Xv3" "10Xv3" "10Xv3" ...
 $ donor_label               : chr  "H19.30.001" "H19.30.002" "H19.30.001" "H19.30.002" ...
 $ donor_sex                 : chr  "M" "M" "M" "M" ...
 $ dataset_label             : chr  "WHB-10Xv3" "WHB-10Xv3" "WHB-10Xv3" "WHB-10Xv3" ...
 $ x                         : num  7.53 2.31 6.74 5.93 5.62 ...
 $ y                         : num  -15.2 -15.5 -16.2 -20 -13.6 ...
 $ cluster_alias             : num  20 20 17 18 16 17 20 17 17 17 ...
 $ region_of_interest_label  : chr  "Human MoAN" "Human MoSR" "Human MoAN" "Human PnAN" ...
 $ anatomical_division_label : chr  "Myelencephalon" "Myelencephalon" "Myelencephalon" "Pons" ...
 $ abc_sample_id             : chr  "b3d3a6c0-3dc5-4738-af4c-96cc5ff6033f" "0a7ed99b-d5eb-4c50-b95e-eb31b448d2c7" "458f6409-af8d-4c7c-ac9b-0b0d9b73b36d" "ff6b2d95-3752-49bf-9421-f17107538868" ...
 - attr(*, "pandas.index")=RangeIndex(start=0, stop=3369219, step=1)
Columns in cluster_details:
[1] "subcluster"       "cluster"          "supercluster"     "neurotransmitter"
Error in fix.by(by.y, y) : 'by' must specify a uniquely valid column

```