#' Load ABC Atlas HMBA Multiome data (HMBA-10xMultiome-BG-Aligned)
#'
#' This function loads the HMBA ABC Atlas data and joins cell, donor, and library metadata.
#' @param download_base The base directory where the data is downloaded.
#' @return A list containing extended cell metadata, donor, library, and gene data.
#' @export

load_data_HMBA <- function(download_base = 'abc_download_root') {
  library(reticulate)
  library(dplyr)

  setup_environment()

  py_download_base <- import("pathlib")$Path(download_base)

  pandas <- import("pandas")
  AbcProjectCache <- import("abc_atlas_access.abc_atlas_cache.abc_project_cache")$AbcProjectCache

  cat("Finished Python importing\n")

  abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)
  cat("Finished creating cache\n")

  # Load metadata
  cell <- abc_cache$get_metadata_dataframe(
    directory = 'HMBA-10xMultiome-BG-Aligned',
    file_name = 'cell_metadata',
    dtype = dict(cell_label = 'str')
  )
  cat("Number of cells =", nrow(cell), "\n")

  donor <- abc_cache$get_metadata_dataframe(
    directory = 'HMBA-10xMultiome-BG-Aligned',
    file_name = 'donor'
  )

  library_df <- abc_cache$get_metadata_dataframe(
    directory = 'HMBA-10xMultiome-BG-Aligned',
    file_name = 'library'
  )

  # Set rownames
  rownames(cell) <- cell$cell_label
  rownames(donor) <- donor$donor_label
  rownames(library_df) <- library_df$library_label

  # Join metadata tables
  cell_extended <- cell %>%
    left_join(donor, by = "donor_label") %>%
    left_join(library_df, by = "library_label", suffix = c("", "_library_table"))

  cat("Joined cell metadata with donor and library tables\n")

  # Load gene metadata
  gene <- abc_cache$get_metadata_dataframe(directory = 'HMBA-10xMultiome-BG-Aligned', file_name = 'gene')
  rownames(gene) <- gene$gene_identifier
  cat("Number of genes =", nrow(gene), "\n")

  # Extract unique values for filtering later
  cols_of_interest <- c("species_scientific_name", "species_common_name", "donor_sex", "donor_age", "region_of_interest_name", "anatomical_division_label")
  unique_values_list <- lapply(cell_extended[cols_of_interest], unique)

  return (list(cell_metadata = cell_extended, gene_data = gene, unique_values = unique_values_list))

}
