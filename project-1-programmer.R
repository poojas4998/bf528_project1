#Loading Libraries 
library("affy")
library("affyPLM")
library("sva")
library("AnnotationDbi")
library("hgu133plus2.db")
library("tidyverse")
library("ggplot2")

#input CEL files using ReadAffy
filepath<- '/projectnb/bf528/users/group_5/project_1/project_1_group_5/samples/all_CEL_files'
affy_batch <- ReadAffy(celfile.path=filepath)

#Normalizing batch files
normalized_data <- rma(affy_batch)

#Compute RLE and NUSE scores 
plm_fit <- fitPLM(affy_batch, background = TRUE, normalize = TRUE)
rle_scores <- RLE(plm_fit, type = 'stats')
nuse_scores <- NUSE(plm_fit, type = 'stats')

#creating a new dataframe with just the median values
rle_median_df <- as.data.frame(rle_scores[1,])
nuse_median_df <- as.data.frame(nuse_scores[1,])

#Creating histograms
hist(rle_median_df[,1], main = "Distribution of RLE scores", xlab = "Median RLE Score", col="indianred")
hist(nuse_median_df[,1], main = "Distribution of NUSE scores", xlab = "Median NUSE Score", xlim = c(0.97, 1.06), col="indianred")

#Correcting for batch effects
#input is normalized data 
annotation_file <- read.csv("/project/bf528/project_1/doc/proj_metadata.csv")

#Extract batch information and features of interest 
batch_info <- annotation_file$normalizationcombatbatch
features_of_interest <- annotation_file$normalizationcombatmod
mod = model.matrix(~as.factor(normalizationcombatmod), data = annotation_file)

#Correct for batch effects using ComBat
corrected_data <- ComBat(dat = normalized_data, batch = batch_info, mod = mod)

# Write out corrected expression data to a CSV file
write.csv(corrected_data, '/projectnb/bf528/users/group_5/project_1/project_1_group_5/expression_data/corrected_exprs_data.csv')

#PCA plots 
data_matrix <- exprs(normalized_data) # Extract the data matrix from rma() output
data_matrix_t <- t(corrected_data) #transposing the data matrix
data_centered_scaled <- scale(data_matrix_t, center = TRUE, scale = TRUE) #scaling and centering the data
data_centered_scaled_t <- t(data_centered_scaled) #transposing it again after scaling and centering
pca_result <- prcomp(data_centered_scaled_t, scale. = FALSE, center = FALSE) #performing PCA
pca_result_summ <- summary(pca_result)

#storing the importance values and as percentage 
importance <- pca_result_summ$importance
pc1_var <- importance[2, 1] * 100
pc2_var <- importance[2, 2] * 100

my_colors <- c("lightcoral", "deepskyblue3") #defining my own vector of colors

#plotting PC1 vs PC2 
ggplot(data.frame(pca_result$rotation), aes(PC1, PC2, color= annotation_file$SixSubtypesClassification)) +
  geom_point(size = 2) +
  scale_color_manual(values = my_colors) +
  labs(color = "Subtype Classification") +
  xlab(paste("PC1 (", round(pc1_var, 2), "% variability)", sep = "")) +
  ylab(paste("PC2 (", round(pc2_var, 2), "% variability)", sep = "")) +
  ggtitle("PCA Plot of PC1 vs PC2")












