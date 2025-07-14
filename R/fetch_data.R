#' Fetch data from ABC Atlas based on filters and return a Seurat object
#'
#' @param metadata A data.frame containing ABC atlas cell metadata (e.g., from `get_cell_metadata()`).
#' @param filters A named list of column = value pairs used to filter the metadata.
#' @param genes A character vector of gene names to include. If NULL, all genes will be returned.
#' @param assay_name The name to use for the Seurat assay (default: "RNA").
#' @return A Seurat object containing the filtered cells and gene expression data.
#' @export
fetch_data <- function(metadata, filters = list(), genes = NULL, assay_name = "RNA") {
  # Ensure reticulate and Seurat are available
  requireNamespace("reticulate")
  requireNamespace("Seurat")

  # Load get_gene_data from the correct module
  get_gene_data <- reticulate::import("abc_atlas_access.abc_atlas_cache.anndata_utils")$get_gene_data

  # Apply filtering
  filtered_meta <- metadata
  for (filter_col in names(filters)) {
    filter_val <- filters[[filter_col]]
    if (!filter_col %in% colnames(filtered_meta)) {
      stop(paste("Column", filter_col, "not found in metadata."))
    }
    filtered_meta <- filtered_meta[filtered_meta[[filter_col]] %in% filter_val, ]
  }
  
  if (nrow(filtered_meta) == 0) {
    stop("No cells left after filtering. Check your filter values.")
  }

  # Extract cell IDs
  cell_ids <- filtered_meta$cell_label

  # Fetch expression matrix (as AnnData)
  gene_count_matrix <- get_gene_data(cell_ids = cell_ids, gene_names = genes, data_type = "raw")

  gene_count_matrix <- as.data.frame(
  lapply(gene_count_matrix, function(x) as.numeric(unlist(x)))
  )

  gene_count_matrix <- t(gene_count_matrix)
    
  # Create Seurat object
  seurat_obj <- Seurat::CreateSeuratObject(
    counts = gene_count_matrix,
    assay = assay_name,
    meta.data = filtered_meta
  )

  
  return(seurat_obj)
}
