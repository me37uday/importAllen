#' Fetch data from ABC Atlas based on filters and return a Seurat object
#'
#' @param metadata A data.frame containing ABC atlas cell metadata (e.g., from `get_cell_metadata()`).
#' @param filters A named list of column = value pairs used to filter the metadata.
#' @param gene_data A data.frame with a 'gene_symbol' column, typically from `load_data()`.
#' @param genes A character vector of gene names to include. If NULL, all genes in gene_data$gene_symbol will be used.
#' @param assay_name The name to use for the Seurat assay (default: "RNA").
#' @return A Seurat object containing the filtered cells and gene expression data.
#' @export
fetch_data <- function(download_base = 'abc_download_root',
                       metadata,
                       filters = list(),
                       gene_data,
                       genes = NULL,
                       assay_name = "RNA") {
  # Ensure required packages are available
  requireNamespace("reticulate")
  requireNamespace("Seurat")

  # Convert R path to Python Path
  py_download_base <- reticulate::import("pathlib")$Path(download_base)

  # Create the cache object
  AbcProjectCache <- reticulate::import("abc_atlas_access.abc_atlas_cache.abc_project_cache")$AbcProjectCache
  abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)

  # Import get_gene_data function
  get_gene_data <- reticulate::import("abc_atlas_access.abc_atlas_cache.anndata_utils")$get_gene_data

  # Apply metadata filters
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

  # Extract and name cell IDs
  rownames(filtered_meta) <- filtered_meta$cell_label

  # Resolve selected genes
  if (is.null(genes)) {
    if (!"gene_symbol" %in% colnames(gene_data)) {
      stop("'gene_symbol' column not found in gene_data.")
    }
    genes <- gene_data$gene_symbol
  }

  # Fetch gene expression data
  gene_count_matrix <- get_gene_data(
    abc_atlas_cache = abc_cache,
    all_cells = filtered_meta,
    all_genes = gene_data,
    selected_genes = genes,
    data_type = "raw"
  )

  print(dim(gene_count_matrix))
  print(nrow(filtered_meta))

# Save cell names
cell_names <- rownames(gene_count_matrix)

# Ensure numeric conversion
gene_count_matrix <- as.data.frame(
  lapply(gene_count_matrix, function(x) as.numeric(unlist(x)))
)

# Restore row names before transpose
rownames(gene_count_matrix) <- cell_names

# Transpose to get genes as rows, cells as columns
gene_count_matrix <- t(gene_count_matrix)
  
# Create Seurat object
seurat_obj <- Seurat::CreateSeuratObject(
  counts = gene_count_matrix,
  assay = assay_name,
  meta.data = filtered_meta
  )

return(seurat_obj)
}

