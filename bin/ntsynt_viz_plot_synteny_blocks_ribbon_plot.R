#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(argparse)
  library(scales)
  library(ggtree)
  library(treeio)
  library(phytools)
  library(dplyr)
  library(ggpubr)
  library(stringr)
  library(gggenomes)
  library(tidyr)})

# Example script for generating ntSynt synteny ribbon plots using gggenomes

# Parse the input arguments
parser <- ArgumentParser(description = "Plot the ntSynt synteny blocks ribbon plot using gggenomes")
parser$add_argument("-s", "--sequences", help = "Input sequence lengths TSV", required = TRUE)
parser$add_argument("-l", "--links", help = "Synteny block links", required = TRUE)
parser$add_argument("-c", "--painting", help = "File with chromosome painting information", required = FALSE)
parser$add_argument("--centromeres", help = "File with centromere positions", required = FALSE, default = NULL)
parser$add_argument("--scale", help = "Length of scale bar in bases (default 1 Gbp)", default = 1e9,
                    required = FALSE, type = "double")
parser$add_argument("--width", help = "Width of plot in cm (default 50)", default = 50,
                    required = FALSE, type = "double")
parser$add_argument("--height", help = "Height of plot in cm (default 20)", default = 20,
                    required = FALSE, type = "double")
parser$add_argument("--tree", help = "Newick-formatted cladogram", required = FALSE)
parser$add_argument("--no-arrow", help = paste("Do not plot arrows indicating reverse complementation.",
                                                "Only use when blocks were normalized."),
                    action = "store_true", default = FALSE)
parser$add_argument("--haplotypes", help = "TSV with haplotype nudges", required = FALSE)
parser$add_argument("--ratio",
                    help = paste("Ratio adjustment for labels on left side of the ribbon plot.",
                                 "Increase if the labels are cut-off,",
                                 "decrease to decrease space between ribbon plot and cladogram"),
                    default = 0.1, required = FALSE, type = "double")
parser$add_argument("-p", "--prefix",
                    help = "Output prefix for PNG image (default synteny_gggenomes_plot)", required = FALSE,
                    default = "synteny_gggenomes_plot")
parser$add_argument("--format", help = "Output format for image (png or pdf)", required = FALSE,
                    default = "png", choices = c("png", "pdf"))
parser$add_argument("--order", help = "TSV file with desired order of tip labels (only used if --tree specified).", required = FALSE)

args <- parser$parse_args()

# Read in and prepare sequences
sequences <- read.csv(args$sequences, sep = "\t", header = TRUE) %>%
  mutate(relative_orientation = if_else(relative_orientation == "+", "", "\u2190"))


# Prepare name conversions for tree
name_conversions <- sequences %>%
  select(bin_id) %>%
  mutate(bin_id_translate = str_replace_all(bin_id, "_", " "))

# https://stackoverflow.com/questions/32378108/using-gtoolsmixedsort-or-alternatives-with-dplyrarrange
sequences <- sequences %>%
  mutate(bin_id = str_replace_all(bin_id, "_", " "))
input_order <- unique(sequences$bin_id)
input_chrom_order <- unique(sequences$seq_id)

sequences <- sequences %>%
  arrange(factor(bin_id, levels = input_order))

# Read in and prepare synteny links
links_ntsynt <- read.csv(args$links,
                         sep = "\t", header = TRUE) %>%
  mutate(bin_id = str_replace_all(bin_id, "_", " "),
         bin_id2 = str_replace_all(bin_id2, "_", " "))
links_ntsynt$seq_id <- factor(links_ntsynt$seq_id,
                              levels = input_chrom_order)
links_ntsynt <- links_ntsynt %>% arrange(factor(seq_id, levels = input_chrom_order))
links_ntsynt$seq_id2 <- as.character(links_ntsynt$seq_id2)
links_ntsynt$colour_block <- factor(links_ntsynt$colour_block,
                                    levels = input_chrom_order)

# Prepare scale bar data frame
scale <- args$scale

scale_bar <- tibble(x = c(0), xend = c(scale),
                    y = c(0), yend = c(0))

# Infer best units for scale bar
label <- paste(scale, "bp", sep = " ")
if (scale %% 1e9 == 0) {
  label <- paste(scale / 1e9, "Gbp", sep = " ")
} else if (scale %% 1e6 == 0) {
  label <- paste(scale / 1e6, "Mbp", sep = " ")
} else if (scale %% 1e3 == 0) {
  label <- paste(scale / 1e3, "kbp", sep = " ")
}

# Read in the data frame for chromosome painting features
painting <- read.csv(args$painting, sep = "\t", header = TRUE) %>%
  mutate(bin_id = str_replace_all(bin_id, "_", " "))

# Get the y coordinates for the features
get_y_coord <- function(haplotypes, bin_id, y, end=FALSE) {
  if (typeof(haplotypes) == "logical") {
    return(y)
  } else {
    coordinates <- data.frame(bin_id = bin_id, y = y)
    if (end == TRUE) {
      haplotypes <- haplotypes %>% 
        mutate(bin_id_next = lead(bin_id, 1), nudge_next = lead(nudge, 1)) %>%
        mutate(nudge_next = replace_na(nudge_next, 0))
      joined <- inner_join(coordinates, haplotypes, by = "bin_id") %>%
        mutate(y = y + nudge_next)
    } else {
      joined <- inner_join(coordinates, haplotypes, by = "bin_id") %>%
              mutate(y = y + nudge)
    }


    return(joined$y)
  }
}

# Make the ribbon plot - these layers can be fully customized as needed!
make_plot <- function(links, sequences, painting, add_scale_bar = FALSE, centromeres = FALSE, add_arrow = FALSE, haplotypes = FALSE) {
  target_genome <- (sequences %>% head(1) %>% select(bin_id))[[1]]
  sequences_filt <- unique((sequences %>% filter(bin_id == target_genome))$seq_id)
  num_colours <- length(sequences_filt)
  colours <- hue_pal()(num_colours)
  
  if (is.data.frame(centromeres)) {
    p <-  gggenomes(seqs = sequences, links = links, feats = list(painting, centromeres))
  } else {
    p <-  gggenomes(seqs = sequences, links = links, feats = list(painting))
  }

  plot <- p + theme_gggenomes_clean(base_size = 15) +
  geom_link(aes(fill = colour_block,
               y = get_y_coord(haplotypes, .data$bin_id, .data$y),
              yend = get_y_coord(haplotypes, .data$bin_id, .data$yend, end = TRUE)),
               offset = 0, alpha = 0.5, size = 0.05) +
  geom_seq(aes(y = get_y_coord(haplotypes, .data$bin_id, .data$y),
               yend = get_y_coord(haplotypes, bin_id, .data$y)),
               size = 2, colour = "darkgrey") + # draw contig/chromosome lines
  geom_feat(data = feats(painting), aes(colour = as.factor(colour_block),
                y = get_y_coord(haplotypes, bin_id, .data$y),
               yend = get_y_coord(haplotypes, bin_id, .data$y)), position = "identity", linewidth = 2) +
  geom_bin_label(aes(label = bin_id,
                    y = get_y_coord(haplotypes, bin_id, .data$y)),
                size = 6, fontface = "italic") + # label each bin
  #geom_seq_label(aes(label = seq_id), vjust = 1.1, size = 4) + # Can add seq labels if desired
  theme(axis.text = element_text(size = 25, face = "italic"),
        legend.position = "bottom",
        legend.text = element_text(size = 15)) +
  scale_fill_manual(values = colours,
                    breaks = sequences_filt) +
  scale_colour_manual(values = colours,
                      breaks = sequences_filt) +
  guides(fill = guide_legend(title = "", ncol = 10),
          colour = guide_legend(title = ""))
  if (add_arrow) {
    plot <- plot + geom_seq_label(aes(label = relative_orientation, 
                                      x = pmax(.data$x, .data$xend),
                                      y = get_y_coord(haplotypes, bin_id, .data$y)), nudge_y = -0.05, 
                                  size = 3.25, hjust = 1) 
  }
  xmax <- ggplot_build(plot)$layout$panel_params[[1]]$x.range[[2]]
  plot <- plot + xlim(0 - xmax * args$ratio, NA)

  if (is.data.frame(centromeres)) {
    plot <- plot + geom_feat(data = feats(centromeres), position = "identity",
                             linewidth = 2, colour = "black")
  }

  if (add_scale_bar) {
    plot <- plot + geom_segment(data = scale_bar, aes(x = x, xend = xend, y = y, yend = yend),
                                linewidth = 1.5) +
      geom_text(data = scale_bar, aes(x = x + (xend / 2), y = y - 0.4, label = label), size = 5) +
      theme(axis.line.x = element_blank(),
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank())
  }

  return(plot)

}

# Read in haplotypes, or set to FALSE
if (! is.null(args$haplotypes)) {
  haplotypes <- read.csv(args$haplotypes, sep = "\t", header = TRUE) %>% mutate(bin_id = str_replace_all(bin_id, "_", " "))
} else {
  haplotypes <- FALSE
}

if (! is.null(args$centromeres)) {
  centromeres <- read.csv(args$centromeres, sep = "\t", header = TRUE)
} else {
  centromeres <- FALSE
}

# Make the ribbon plot
synteny_plot <- make_plot(links_ntsynt, sequences, painting, add_scale_bar = TRUE, centromeres = centromeres,
                          add_arrow = !args$no_arrow, haplotypes = haplotypes)


if (is.null(args$tree)) {
  # If no tree is provided, just plot the synteny blocks
  plots <- synteny_plot
} else {
  # Prepare the tree
  ntsynt_tree <- treeio::read.newick(args$tree)
  ntsynt_tree <- phytools::midpoint_root(ntsynt_tree)

  if (!is.null(args$order)) {
    ntsynt_ggtree <- ggtree(ntsynt_tree, branch.length = "none") # Initial tree to rotate
    orders <- read.csv(args$order, sep = "\t", header = F)
    colnames(orders) <- c("label")
    named_order_vector <- setNames(1:length(orders$label), rev(orders$label))
    is_tree_right_order <- identical(names(named_order_vector), as.phylo(ntsynt_ggtree)$tip.label)
    new_tree <- as.phylo(ntsynt_ggtree)
    while (! is_tree_right_order) {
      new_tree <- minRotate(new_tree, named_order_vector)
      is_tree_right_order <- identical(names(named_order_vector), new_tree$tip.label)
    }
    new_tree <- rename_taxa(new_tree, name_conversions)
    ntsynt_ggtree <- ggtree(new_tree, branch.length = "none", ladderize = FALSE)
  } else {
    ntsynt_tree <- rename_taxa(ntsynt_tree, name_conversions)
    ntsynt_ggtree <- ggtree(ntsynt_tree, branch.length = "none")
  }

  # Align the plots properly
  synteny_y_range <- ggplot_build(synteny_plot)$layout$panel_params[[1]]$y.range

  plots <- ggarrange(ntsynt_ggtree + scale_y_continuous(limits = synteny_y_range, expand = c(0, 0)),
                     (synteny_plot %>% pick_by_tree(ntsynt_ggtree)),
                     common.legend = TRUE, align = "hv",
                     widths = c(1, 10), legend = "bottom")
}

any_rc <- length((sequences %>% filter(relative_orientation != ""))$relative_orientation) > 0
if (any_rc && !args$no_arrow) {
  note <- text_grob("sequences reverse complemented with --normalize indicated with arrows", size = 15)
  plots <- ggarrange(plots, note, ncol = 1, heights = c(10, 1))
}

# Save the ribbon plot
if (args$format == "pdf") {
  ggsave(paste(args$prefix, ".pdf", sep = ""), plots,
         units = "cm", width = args$width, height = args$height, bg = "white")
  cat(paste("Plot saved:", paste(args$prefix, ".pdf", sep = ""), "\n", sep = " "))
} else {
  png(paste(args$prefix, ".png", sep = ""), units = "cm", width = args$width, height = args$height,
      res = 300, bg = "white")
  print(plots)
  dev.off()
  cat(paste("Plot saved:", paste(args$prefix, ".png", sep = ""), "\n", sep = " "))
}
