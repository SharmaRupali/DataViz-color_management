require(data.table)
require(colorscience)
require(tcR)

lab_measure <- fread("Data/LabMeasurements-Color-Card.csv", dec = ",")
master_color_card <- fread("Data/MasterColorCard.csv", dec = ",")

XX <- data.matrix(lab_measure)
YY <- data.matrix(master_color_card)

# column names
cols <- c("Sheet", "Rows", "Columns", unique(substr(colnames(XX), 2, 3))[c(-1,-2)])

mid_blocks = c() # store the indices of middle elements
for (i in c("44", "45", "54", "55")) {
  mid_blocks[i] = which(cols == i)
}

corners = c() # store the indices of corner elements
for (i in c("11", "18", "81", "88")) {
  corners[i] = which(cols[-mid_blocks] == i)
}

borders = c() # store the indices of border elements
for (i in unique(c(paste(1, 1:8, sep=""), paste(8, 1:8, sep=""), paste(1:8, 1, sep=""), paste(1:8, 8, sep="")))) {
  borders[i] = which(cols[-mid_blocks] == i)
}


## distance (deltaE) & similarity (cosine similarity) between color patches

## each color patch on each card of each paper is compared to the respective color patch on the master color card
## matrix aa (546,64): rows corresponding to the rows from XX (lab_measure) (1 row = 1 color card with 64 patches), 
## and cols corresponding to the deltaE values for each color patch: 3 cols (XX)(L, a, b) = 1 col (aa) deltaE

### Correct one --
aa <- matrix(nrow = dim(XX)[1], ncol = 64)
bb <- matrix(nrow = 8, ncol = 8)

for (n_row in 1:dim(XX)[1]) {
  for (i in 1:8) {
    for (j in 1:8) {
      bb[i,j] <- deltaE2000(c(XX[n_row ,paste("L", i, j, sep="")], XX[n_row ,paste("a", i, j, sep="")], XX[n_row ,paste("b", i, j, sep="")]),
                            c(YY[YY[, "Crow"] == i & YY[, "Ccol"] == j, 9], YY[YY[, "Crow"] == i & YY[, "Ccol"] == j, 10], YY[YY[, "Crow"] == i & YY[, "Ccol"] == j, 11]))
      aa[n_row, ] <- c(t(bb))
    }
  }
}

dist_mat <- cbind(rep(1:13, 42), XX[, c(1,2)], aa)
colnames(dist_mat) <- cols

## without the middle part: cols: 44, 45, 54, 55
## keeping the same name (for without the middle because we're excluding the middle part at all times)
dist_mat <- dist_mat[, -mid_blocks]

## without the corners
dist_mat_no_corners <- dist_mat[, -corners]

## without the borders
dist_mat_no_borders <- dist_mat[, -borders]

## means
dist_means <- matrix(nrow = dim(dist_mat)[1], ncol = 6)
colnames(dist_means) <- c("Sheet", "Rows", "Columns", "Means_dist_all_colors", "Means_dist_no_corners", "Means_dist_no_borders")
dist_means[, 1:3] <- dist_mat[, 1:3]

for (i in 1:dim(dist_mat)[1]) {
  dist_means[i, 4] <- mean(dist_mat[i, 4:dim(dist_mat)[2]])
  dist_means[i, 5] <- mean(dist_mat_no_corners[i, 4:dim(dist_mat_no_corners)[2]])
  dist_means[i, 6] <- mean(dist_mat_no_borders[i, 4:dim(dist_mat_no_borders)[2]])
}

### -- Correct one