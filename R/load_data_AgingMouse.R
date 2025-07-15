#' Load metadata from Zeng-Aging-Mouse-10Xv3
#'
#' This function loads and joins cell metadata, cluster annotations, and gene metadata
#' from the Zeng-Aging-Mouse datasets.
#'
#' @param download_base Path to the base directory where the ABC Atlas data is cached.
#' @return A list containing extended cell metadata, gene data, and unique values for filtering.
#' @export

load_data_AgingMouse <- function(download_base = 'abc_download_root') {
  library(reticulate)
  library(dplyr)

  setup_environment()

  py_download_base <- import("pathlib")$Path(download_base)
  pandas <- import("pandas")
  AbcProjectCache <- import("abc_atlas_access.abc_atlas_cache.abc_project_cache")$AbcProjectCache

  abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)
  cat("ABC cache initialized.\n")

  # Load metadata tables
  cell <- abc_cache$get_metadata_dataframe(
    directory = 'Zeng-Aging-Mouse-10Xv3',
    file_name = 'cell_metadata',
    dtype = dict(cell_label = "str", wmb_cluster_alias = "Int64")
  )
  rownames(cell) <- cell$cell_label

  cell_colors <- abc_cache$get_metadata_dataframe(
    directory = 'Zeng-Aging-Mouse-10Xv3',
    file_name = 'cell_annotation_colors'
  )
  rownames(cell_colors) <- cell_colors$cell_label

  cluster_info <- abc_cache$get_metadata_dataframe(
    directory = 'Zeng-Aging-Mouse-10Xv3',
    file_name = 'cluster'
  )
  rownames(cluster_info) <- cluster_info$cluster_alias

  cell_cluster_mapping <- abc_cache$get_metadata_dataframe(
    directory = 'Zeng-Aging-Mouse-WMB-taxonomy',
    file_name = 'cell_cluster_mapping_annotations'
  )
  rownames(cell_cluster_mapping) <- cell_cluster_mapping$cell_label

  # Join on cell_label
  cell_extended <- cell %>%
    left_join(cell_cluster_mapping, by = "cell_label", suffix = c("", "_cl_map")) %>%
    left_join(cell_colors, by = "cell_label", suffix = c("", "_cl_colors")) %>%
    left_join(cluster_info, by = "cluster_alias", suffix = c("", "_cl_info"))

  cat("Merged cell metadata with annotations and cluster info.\n")

  # Load gene data from WHB-10Xv3 project
  gene <- abc_cache$get_metadata_dataframe(
    directory = 'WHB-10Xv3',
    file_name = 'gene'
  )
  rownames(gene) <- gene$gene_identifier
  cat("Number of genes =", nrow(gene), "\n")

  # Extract columns of interest
  cols_of_interest <- c(
    "anatomical_division_label", "donor_sex", "donor_age", "cluster_name_cl_info", "neurotransmitter_combined_label"
  )

  cols_of_interest <- intersect(cols_of_interest, colnames(cell_extended))
  unique_values_list <- lapply(cell_extended[cols_of_interest], unique)

  return(list(
    cell_metadata = cell_extended,
    gene_data = gene,
    unique_values = unique_values_list
  ))
}
