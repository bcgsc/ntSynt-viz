# ntSynt-viz: Visualizing multi-genome synteny

Here, we provide an easy-to-use pipeline for generating ribbon plots combined with chromosome painting to visualize multi-genome synteny blocks. The tool is set-up to accept synteny blocks formatted in the [ntSynt](https://github.com/bcgsc/ntSynt) style, but any synteny block file that adheres to the simple, BED-like TSV format of ntSynt can be visualized using ntSynt-viz.

This flexible pipeline implements numerous features, including:
* Option to normalize the strands of input chromosomes, based on a target assembly
* Evidence-guided ordering of assemblies from top-to-bottom, based on an input tree structure or distance estimates from the synteny blocks
* Sorting chromosomes right-to-left based on synteny to other assemblies
* Colouring both the ribbons and chromosomes based on the chromosomes in the target (top) assembly

These features ensure that the output ribbon plots (powered by [gggenomes](https://thackl.github.io/gggenomes/)) are as easily understandable and as information-rich as possible.

### Dependencies
* [quicktree](https://github.com/khowe/quicktree)
* R packages:
  * [gggenomes](https://github.com/thackl/gggenomes)
  * [treeio](https://www.bioconductor.org/packages/release/bioc/html/treeio.html)
  * [ggpubr](https://rpkgs.datanovia.com/ggpubr/)
  * [ggtree](https://github.com/YuLab-SMU/ggtree)
  * [tidytree](https://cran.rstudio.com/web/packages/tidytree/index.html)
  * [phytools](https://cran.r-project.org/web/packages/phytools/index.html)
  * [dplyr](https://dplyr.tidyverse.org/)
  * [tidyr](https://tidyr.tidyverse.org/)
  * [argparse](https://cran.r-project.org/web/packages/argparse/index.html)
  * [scales](https://scales.r-lib.org/)
  * [stringr](https://stringr.tidyverse.org/)

#### Installing dependencies using conda
```
conda install --yes -c conda-forge -c bioconda quicktree r-base bioconductor-treeio r-ggpubr bioconductor-ggtree r-phytools r-dplyr r-argparse r-scales r-stringr r-gggenomes
```

### Usage
```
usage: ntsynt_viz.py [-h] --blocks BLOCKS --fais FAIS [FAIS ...] [--name_conversion NAME_CONVERSION] [--tree TREE] [--target-genome TARGET_GENOME] [--normalize]
                     [--indel INDEL] [--length LENGTH] [--seq_length SEQ_LENGTH] [--keep KEEP [KEEP ...]] [--centromeres CENTROMERES] [--haplotypes HAPLOTYPES]
                     [--prefix PREFIX] [--format {png,pdf}] [--scale SCALE] [--height HEIGHT] [--width WIDTH] [--no-arrow] [--ribbon_adjust RIBBON_ADJUST] [-f]
                     [-n]

Visualizing multi-genome synteny

optional arguments:
  -h, --help            show this help message and exit

required arguments:
  --blocks BLOCKS       ntSynt-formatted synteny blocks TSV
  --fais FAIS [FAIS ...]
                        FAI files for all input assemblies. Can be a list or a file with one FAI path per line.

main plot formatting arguments:
  --name_conversion NAME_CONVERSION
                        TSV for converting names in the blocks TSV (old -> new). IMPORTANT: new names cannot have spaces. If you want to have spaces in the
                        final ribbon plot, use the special character '_'. All underscores in the new name will be converted to spaces.
  --tree TREE           User-input tree file in newick format. If specified, this tree will be plotted next to the output ribbon plot, and used for ordering the
                        assemblies. The names in the newick file must match the new names if --name_conversion is specified, or the genome file names in the
                        synteny blocks input file otherwise. If not specified, the synteny blocks will be used to estimate pairwise distances for the assembly
                        ordering and associated tree.
  --target-genome TARGET_GENOME
                        Target genome. If specified, this genome will be at the top of the ribbon plot, with ribbons coloured based on its chromosomes and (if
                        applicable) other chromosomes normalized to it. If not specified, the top genome will be arbitrary.
  --normalize           Normalize strand of chromosomes relative to the target (top) genome in the ribbon plots
  --centromeres CENTROMERES
                        TSV file with centromere positions. Must have the headers: bin_id,seq_id,start,end. bin_id must match the new names from
                        --name_conversion or the assembly names if --name_conversion is not specified. seq_id is the chromosome name.
  --haplotypes HAPLOTYPES
                        File listing haplotype assembly names: TSV, maternal/paternal assembly file names separated by tabs.
  --no-arrow            Only used with --normalize; do not draw arrows indicating reverse-complementation

block filtering arguments:
  --indel INDEL         Indel size threshold [50000]
  --length LENGTH       Minimum synteny block length [100000]
  --seq_length SEQ_LENGTH
                        Minimum sequence length [500000]
  --keep KEEP [KEEP ...]
                        List of assembly_name:chromosome to show in visualization. All chromosomes with links to the specified chromosomes will also be shown.

output arguments:
  --prefix PREFIX       Prefix for output files [ntSynt_ribbon-plot]
  --format {png,pdf}    Output format of ribbon plot [png]
  --scale SCALE         Length of scale bar in bases [100e6]
  --height HEIGHT       Height of plot in cm [20]
  --width WIDTH         Width of plot in cm [50]
  --ribbon_adjust RIBBON_ADJUST
                        Ratio for adjusting spacing beside ribbon plot. Increase if ribbon plot labels are cut off, and decrease to reduce the white space to
                        the left of the ribbon plot [0.1]

execution arguments:
  -f, --force           Force a re-run of the entire pipeline
  -n                    Dry-run for snakemake pipeline
```
#### Example commands
All the files referenced in these commands can be found in the `tests` subfolder for you to use in testing.

##### Plot ribbon plots with an input cladogram in newick format, normalizing the strands of the assembly chromosomes
```
ntsynt_viz.py --blocks great-apes.ntSynt.synteny_blocks.tsv --fais fais.tsv --tree great-apes.mt-tree.nwk --name_conversion great-apes.name-conversions.tsv --normalize --prefix great-apes_ribbon-plots --ribbon_adjust 0.14
```
![Example_ribbon_plot](https://github.com/bcgsc/ntSynt-viz/blob/main/tests/great-apes_ribbon-plots.example1.png)

##### Plot ribbon plots without input cladogram, skipping normalization of the assembly chromosome strands
```
ntsynt_viz.py --blocks great-apes.ntSynt.synteny_blocks.tsv --fais fais.tsv  --name_conversion great-apes.name-conversions.tsv  --prefix great-apes_ribbon-plots_no-tree --ribbon_adjust 0.15 --scale 500000000 
```
![Example_ribbon_plot](https://github.com/bcgsc/ntSynt-viz/blob/main/tests/great-apes_ribbon-plots.example2.png)

