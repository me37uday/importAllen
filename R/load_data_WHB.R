#' Load ABC Atlas data
#'
#' This function loads the ABC Atlas data from the specified download base directory.
#' @param download_base The base directory where the data is downloaded.
#' @return A list containing cell metadata and gene data.
#' @export

load_data <- function(download_base = 'abc_download_root') {
    
    library(reticulate)
    library(dplyr)
    
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

    # Create the cache object
    abc_cache <- AbcProjectCache$from_s3_cache(py_download_base)

    print("Finished creating cache")

    # Load the cell metadata
    cell <- abc_cache$get_metadata_dataframe(directory = 'WHB-10Xv3', file_name = 'cell_metadata', dtype = dict(cell_label = 'str'))
    print("Finished loading cell metadata")
#    rownames(cell) <- cell$cell_label
#    cell$cell_label <- NULL
    cat("Number of cells = ", nrow(cell), "\n")

    # Load the cluster membership metadata and combine the data with the cell data.
    membership <- abc_cache$get_metadata_dataframe(
    directory='WHB-taxonomy',
    file_name='cluster_to_cluster_annotation_membership'
    )

    term_sets <- abc_cache$get_metadata_dataframe(directory='WHB-taxonomy', file_name='cluster_annotation_term_set')
    
    rownames(term_sets) <- term_sets$label

    cluster_details <- aggregate(cluster_annotation_term_name ~ cluster_alias + cluster_annotation_term_set_name, 
                                data = membership, FUN = function(x) x[1])
    cluster_details <- reshape(cluster_details, 
                            idvar = "cluster_alias", 
                            timevar = "cluster_annotation_term_set_name", 
                            direction = "wide")
    colnames(cluster_details) <- gsub("cluster_annotation_term_name.", "", colnames(cluster_details))
    cluster_details <- cluster_details[, term_sets$name] # order columns
    cluster_details[is.na(cluster_details)] <- 'Other'

    # Sort values
    cluster_details <- cluster_details[order(cluster_details$supercluster, cluster_details$cluster, cluster_details$subcluster), ]

    cluster_colors <- aggregate(color_hex_triplet ~ cluster_alias + cluster_annotation_term_set_name, 
                                data = membership, FUN = function(x) x[1])
    cluster_colors <- reshape(cluster_colors, 
                            idvar = "cluster_alias", 
                            timevar = "cluster_annotation_term_set_name", 
                            direction = "wide")

    
    colnames(cluster_colors) <- gsub("color_hex_triplet.", "", colnames(cluster_colors))
    cluster_colors <- cluster_colors[, term_sets$name] # order columns
    cluster_colors <- cluster_colors[order(cluster_colors$supercluster, cluster_colors$cluster, cluster_colors$subcluster), ]
    
    roi <- abc_cache$get_metadata_dataframe(directory='WHB-10Xv3', file_name='region_of_interest_structure_map')
    cat("Structure of roi:\n")
    str(roi)
    roi$region_of_interest_label <- make.unique(as.character(roi$region_of_interest_label))
    rownames(roi) <- roi$region_of_interest_label
    
#    roi <- roi[, c('region_of_interest_color' = 'color_hex_triplet')] this way of renaming column was retaining only that specific column leading to errors downstream 

    colnames(roi)[colnames(roi) == 'color_hex_triplet'] <- 'region_of_interest_color' # corrected
                                
    print("Finished loading cluster metadata")
    # Remove unnecessary objects
    rm(membership, term_sets)

    print("Structure of cell:") 
    str(cell)

    cat("Columns in cluster_details:\n")
    print(colnames(cluster_details))

    # Combine data
#    cell_extended <- merge(cell, cluster_details, by.x = 'cluster_alias', by.y = 'cluster_alias', all.x = TRUE)
#    cat("Columns in cluster_colors:\n")
#    print(colnames(cluster_colors))
#    cell_extended <- merge(cell_extended, cluster_colors, by.x = 'cluster_alias', by.y = 'cluster_alias', suffixes = c("", "_color"), all.x = TRUE)
#    cat("Columns in roi:\n")
#    print(colnames(roi))
#    cell_extended <- merge(cell_extended, roi['region_of_interest_color'], by.x = 'region_of_interest_label', by.y = 'region_of_interest_label', all.x = TRUE)

    # Ensure cluster_alias is a proper column
    cluster_details$cluster_alias <- rownames(cluster_details)
    cluster_colors$cluster_alias <- rownames(cluster_colors)
    
    cell$cluster_alias <- as.character(cell$cluster_alias)
    
    cell_extended <- cell %>%
    left_join(cluster_details, by = "cluster_alias") %>%
    left_join(cluster_colors, by = "cluster_alias", suffix = c("", "_color")) %>%
    left_join(select(roi, region_of_interest_label, region_of_interest_color), by = "region_of_interest_label")    
                                
    # Remove unnecessary objects
#    rm(cluster_details, cluster_colors, roi)

    head(cell_extended, 5)

    # Gene data

    gene <- abc_cache$get_metadata_dataframe(directory='WHB-10Xv3', file_name='gene')
    rownames(gene) <- gene$gene_identifier
    cat("Number of genes = ", nrow(gene), "\n")
    head(gene, 5)

    # extracting interesting columns and unique values in them from which the gene count matrix can be asked for from fetchdata() 
                                
    cols_of_interest <- c("feature_matrix_label", "brain_section_label", "region_of_interest_label", "anatomical_division_label", "subcluster", "cluster", "supercluster", "neurotransmitter")
    unique_values_list <- lapply(cell_extended[cols_of_interest], unique)

    return (list(cell_metadata = cell_extended, gene_data = gene, unique_values = unique_values_list))
                                
}
