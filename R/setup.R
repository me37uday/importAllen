#' Setup the Python environment
#' 
#' This function sets up the Python environment required to run the data loading functions.
#' @export
setup_environment <- function() {
  library(reticulate)
  
  # Specify the exact path to Python 3.10
  python_path <- "/home/fedo/miniforge3/bin/python3.10"
  
  # Check if the specified Python path exists
  if (!file.exists(python_path)) {
    stop("Python 3.10 not found at the specified path. Please check the path and ensure it is correct.")
  }
  
  # Use the specified Python executable
  use_python(python_path, required = TRUE)

  virtualenv_dir <- "r-reticulate-env"
  
  if (!virtualenv_exists(virtualenv_dir)) {
    virtualenv_create(virtualenv_dir, python = python_path)
    virtualenv_install(virtualenv_dir, packages = c("pandas", "pathlib", "numpy", "anndata"))
    
    # Install abc_atlas_access from GitHub
    virtualenv_install(virtualenv_dir, packages = "git+https://github.com/alleninstitute/abc_atlas_access", ignore_installed = TRUE)
  }
  
  use_virtualenv(virtualenv_dir, required = TRUE)
}
