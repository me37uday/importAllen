#' Load ABC Atlas data
#'
#' This function loads the ABC Atlas data from the specified download base directory.
#' @param download_base The base directory where the data is downloaded.
#' @return A list containing cell metadata and gene data.
#' @export
load_data <- function(download_base = '../../abc_download_root') {
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
  
  # Create the cache object
  abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)
  
  # Load the cell metadata
  cell <- abc_cache$get_metadata_dataframe(directory = 'WHB-10Xv3', file_name = 'cell_metadata', dtype = dict(cell_label = 'str'))
  
  # Ensure cell is a pandas DataFrame before calling set_index
  if (py$isinstance(cell, pandas$DataFrame)) {
    cell$set_index('cell_label', inplace = TRUE)
    cat("Number of cells =", cell$shape[0], "\n")
  } else {
    cat("cell is not a pandas DataFrame. Its type is:", class(cell), "\n")
    stop("cell is not a pandas DataFrame")
  }
  
  # Load the cluster membership metadata and combine the data with the cell data
  membership <- abc_cache$get_metadata_dataframe(directory = 'WHB-taxonomy', file_name = 'cluster_to_cluster_annotation_membership')
  term_sets <- abc_cache$get_metadata_dataframe(directory = 'WHB-taxonomy', file_name = 'cluster_annotation_term_set')$set_index('label')
  cluster_details <- membership$groupby(list('cluster_alias', 'cluster_annotation_term_set_name'))[['cluster_annotation_term_name']]$first()$unstack()
  cluster_details <- cluster_details[term_sets[['name']]]  # order columns
  cluster_details$fillna('Other', inplace = TRUE)
  
  cluster_details$sort_values(list('supercluster', 'cluster', 'subcluster'), inplace = TRUE)
  cluster_colors <- membership$groupby(list('cluster_alias', 'cluster_annotation_term_set_name'))[['color_hex_triplet']]$first()$unstack()
  cluster_colors <- cluster_colors[term_sets[['name']]]
  cluster_colors$sort_values(list('supercluster', 'cluster', 'subcluster'), inplace = TRUE)
  
  roi <- abc_cache$get_metadata_dataframe(directory = 'WHB-10Xv3', file_name = 'region_of_interest_structure_map')
  roi$set_index('region_of_interest_label', inplace = TRUE)
  roi$rename(columns = dict(color_hex_triplet = 'region_of_interest_color'), inplace = TRUE)
  
  # Combine data
  cell_extended <- cell$join(cluster_details, on = 'cluster_alias')
  cell_extended <- cell_extended$join(cluster_colors, on = 'cluster_alias', rsuffix = '_color')
  cell_extended <- cell_extended$join(roi[['region_of_interest_color']], on = 'region_of_interest_label')
  
  # Load gene data
  gene <- abc_cache$get_metadata_dataframe(directory = 'WHB-10Xv3', file_name = 'gene')
  gene$set_index('gene_identifier', inplace = TRUE)
  cat("Number of genes =", gene$shape[0], "\n")
  
  # Convert cell_extended and gene to R data frames
  cell_extended_r <- py_to_r(cell_extended)
  gene_r <- py_to_r(gene)
  
  return(list(cell_metadata = cell_extended_r, gene_data = gene_r))
}