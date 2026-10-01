# Mechanism-preserving path-proximity engine for ML-SAS.
#
# This file intentionally lives beside, rather than replacing,
# `mlsas_helpers.R`.  The reference implementation remains the authority for
# regression tests.  The optimized engine keeps the same Addcl1 synthetic
# sample, randomForest fit, full root-to-terminal paths, per-tree Jaccard
# similarity, and arithmetic mean across trees.

.extract_real_tree_paths_optimized <- function(tree, data_all, n_real) {
  paths <- vector("list", n_real)

  for (i in seq_len(n_real)) {
    path <- integer()
    node <- 1L

    repeat {
      path <- c(path, node)
      split_var <- tree[node, "split var"]
      if (split_var == 0) {
        break
      }

      split_val <- tree[node, "split point"]
      split_var_name <- colnames(data_all)[split_var]
      value <- data_all[i, split_var_name]

      split_column <- data_all[[split_var_name]]

      if (is.factor(split_column) && !is.ordered(split_column)) {
        split_bits <- intToBits(split_val)
        value_level_index <- as.integer(value)
        if (split_bits[value_level_index] == as.raw(1)) {
          node <- tree[node, "left daughter"]
        } else {
          node <- tree[node, "right daughter"]
        }
      } else if ((if (is.ordered(split_column)) as.integer(value) else value) <= split_val) {
        node <- tree[node, "left daughter"]
      } else {
        node <- tree[node, "right daughter"]
      }
    }

    paths[[i]] <- path
  }

  paths
}

.path_jaccard_sparse_optimized <- function(paths, n_nodes) {
  n <- length(paths)
  path_lengths <- lengths(paths)

  incidence <- Matrix::sparseMatrix(
    i = rep.int(seq_len(n), path_lengths),
    j = unlist(paths, use.names = FALSE),
    x = 1,
    dims = c(n, n_nodes)
  )

  intersection_sizes <- as.matrix(Matrix::tcrossprod(incidence))
  union_sizes <- outer(path_lengths, path_lengths, "+") - intersection_sizes
  intersection_sizes / union_sizes
}

