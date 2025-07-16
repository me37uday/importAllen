# importABCatlas

## 🧠 About the Tool

**`importABCatlas`** is an R package that provides a streamlined interface for accessing and analyzing data from the **Allen Brain Cell (ABC) Atlas** using the **Seurat** ecosystem. Built with accessibility and ease-of-use in mind, this package is intended to empower researchers—particularly those more comfortable in R environments—to explore high-resolution single-cell data from the ABC Atlas without needing Python or high-performance computing (HPC) infrastructure.

The **Allen Brain Cell Atlas** is an open-access, multimodal platform developed by the **Allen Institute** as part of the Brain Knowledge Platform. Its mission is to provide a unified, high-resolution view of the molecular and spatial diversity of brain cell types across mammalian species. This groundbreaking initiative continues to expand, offering researchers unprecedented capabilities to:

- 🔬 Identify more cell types in the brain  
- 🧭 Investigate spatial organization of these cell types  
- 🧬 Explore gene expression and co-expression patterns  
- 🧠 Refine the molecular definitions of brain regions

Despite the wealth of data available in the ABC Atlas, programmatic access is currently supported primarily via **Python APIs**. However, nearly half of the neuroscience community—including many wet lab scientists—prefer **R** for downstream single-cell transcriptomic analyses. This creates a gap in accessibility and ease-of-use.

**`importABCatlas`** aims to bridge that gap by:

- Providing seamless access to ABC Atlas data **entirely in R**
- Leveraging the **Seurat** framework for downstream analysis
- Supporting flexible subsetting and filtering of metadata
- Enabling usage on **non-HPC machines**, making it viable for most labs worldwide
- Offering compatibility with other popular R-based frameworks like **SingleCellExperiment** and **monocle3** by allowing users to extract data from Seurat objects

Whether you're investigating a small cell population in a low-resource environment or exploring atlas-wide transcriptomic patterns, `importABCatlas` is designed to provide a simple, robust, and R-native workflow.

---

## 🚧 Current Status

This package is currently **under active development**. Several core functions are already implemented, including support for:

- ✅ Setting up the environment and loading ABC Atlas metadata  
- ✅ Filtering metadata based on user-specified criteria  
- ✅ Downloading and formatting gene expression data into **Seurat** objects  

More comprehensive documentation will be added as development progresses. However, the current version is already usable and allows you to extract a **cell × gene** count matrix for selected populations from the **adult human brain dataset** of the ABC Atlas.

---

_Stay tuned for usage instructions and examples below!_
