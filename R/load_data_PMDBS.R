#' Load ABC Atlas PMDBS data
#'
#' This function loads the ABC Atlas PMDBS data from the specified download base directory.
#' @param download_base The base directory where the data is downloaded.
#' @return A list containing cell metadata, gene data, and other metadata tables.
#' @export

load_data_PMDBS <- function(download_base = 'abc_download_root') {
  library(reticulate)
  library(dplyr)

  setup_environment()

  # Convert the R path to a Python path
  py_download_base <- import("pathlib")$Path(download_base)

  # Import Python modules
  pandas <- import("pandas")
  AbcProjectCache <- import("abc_atlas_access.abc_atlas_cache.abc_project_cache")$AbcProjectCache

  cat("Finished Python importing\n")

  # Create cache
  abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)
  cat("Finished creating cache\n")

  # Load cell metadata
  cell <- abc_cache$get_metadata_dataframe(
    directory = 'ASAP-PMDBS-10X',
    file_name = 'cell_metadata',
    dtype = dict(cell_label = 'str')
  )
  cat("Finished loading cell metadata\n")
  cat("Number of cells =", nrow(cell), "\n")

  # Load additional metadata
  sample <- abc_cache$get_metadata_dataframe(directory = 'ASAP-PMDBS-10X', file_name = 'sample')
  donor <- abc_cache$get_metadata_dataframe(directory = 'ASAP-PMDBS-10X', file_name = 'donor')
  
  # Set appropriate rownames
  rownames(cell) <- cell$cell_label
  rownames(sample) <- sample$sample_label
  rownames(donor) <- donor$donor_label
  
  cell_extended <- cell %>%
  left_join(sample, by = "sample_label") %>%
  left_join(donor, by = "donor_label")
                                

  head(cell_extended, 5)

  # Gene data

  gene <- abc_cache$get_metadata_dataframe(directory='WHB-10Xv3', file_name='gene')
  rownames(gene) <- gene$gene_identifier
  cat("Number of genes = ", nrow(gene), "\n")
  head(gene, 5)

  # extracting interesting columns and unique values in them from which the gene count matrix can be asked for from fetchdata() 
                                
  cols_of_interest <- c("source_dataset_label", "region_of_interest_label", "donor_race", "donor_sex", "primary_diagnosis", "age_at_death", "apoe4_status", "braak_stage", "cerad_score", "cognitive_status")
  unique_values_list <- lapply(cell_extended[cols_of_interest], unique)

  return (list(cell_metadata = cell_extended, gene_data = gene, unique_values = unique_values_list))
                                
}
