import pandas as pd
from pathlib import Path
import numpy as np
import anndata

from abc_atlas_access.abc_atlas_cache.abc_project_cache import AbcProjectCache
from abc_atlas_access.abc_atlas_cache.anndata_utils import get_gene_data

# Change the download_base variable to where you have downloaded the data in your system.

download_base = Path('../../abc_download_root')
abc_cache = AbcProjectCache.from_s3_cache(download_base)

# Load the cell metadata.

cell = abc_cache.get_metadata_dataframe(
    directory='WHB-10Xv3',
    file_name='cell_metadata',
    dtype={'cell_label': str}
)
cell.set_index('cell_label', inplace=True)
print("Number of cells = ", len(cell))

# Load the cluster memembership metadata and combine the data with the cell data.
membership = abc_cache.get_metadata_dataframe(
    directory='WHB-taxonomy',
    file_name='cluster_to_cluster_annotation_membership'
)

term_sets = abc_cache.get_metadata_dataframe(directory='WHB-taxonomy', file_name='cluster_annotation_term_set').set_index('label')
cluster_details = membership.groupby(['cluster_alias', 'cluster_annotation_term_set_name'])['cluster_annotation_term_name'].first().unstack()
cluster_details = cluster_details[term_sets['name']] # order columns
cluster_details.fillna('Other', inplace=True)

cluster_details.sort_values(['supercluster', 'cluster', 'subcluster'], inplace=True)
cluster_colors = membership.groupby(['cluster_alias', 'cluster_annotation_term_set_name'])['color_hex_triplet'].first().unstack()
cluster_colors = cluster_colors[term_sets['name']]
cluster_colors.sort_values(['supercluster', 'cluster', 'subcluster'], inplace=True)
cluster_colors

roi = abc_cache.get_metadata_dataframe(directory='WHB-10Xv3', file_name='region_of_interest_structure_map')
roi.set_index('region_of_interest_label', inplace=True)
roi.rename(columns={'color_hex_triplet': 'region_of_interest_color'},
           inplace=True)

del membership
del term_sets

cell_extended = cell.join(cluster_details, on='cluster_alias')
cell_extended = cell_extended.join(cluster_colors, on='cluster_alias', rsuffix='_color')
cell_extended = cell_extended.join(roi[['region_of_interest_color']], on='region_of_interest_label')

del cluster_details
del cluster_colors
del roi

cell_extended.head(5)

# Gene data 

gene = abc_cache.get_metadata_dataframe(directory='WHB-10Xv3', file_name='gene')
gene.set_index('gene_identifier', inplace=True)
print("Number of genes = ", len(gene))
gene.head(5)


