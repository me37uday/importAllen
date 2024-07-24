# abc_atlas_to_seurat

Guys!

Let's start creating this function shall we?

Let's work on human brain first and eventually scale it to mouse.

So human brain data is basically split into two files - neuronal and non-neuronal

Let's begin with neuronal.

Can we start off by doing something like :

abc_atlas_to_seurat --human --neuronal

Upon running this, the script should be able to see, if the neuronal.h5ad file already exists in the current working directory if not it should skip to downloading it by running the abc script that I am trying to update!!
