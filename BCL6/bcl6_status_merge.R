
### Reading in the BCL6 status
library(dplyr)
library(data.table)
library(future)
library(furrr)


## MS
folder_path <- "/TMA_reduced_quantified_bcl6_five/ms"

# Set up parallel processing
plan(multisession)

# List all files in the folder
file_list <- list.files(folder_path, full.names = TRUE)

# Process files in parallel
all_data <- future_map(file_list, function(file) {
  # Read the file efficiently
  df <- fread(file)
  
  # Extract the first two components of the file name
  basenameID <- paste(unlist(strsplit(basename(file), "_"))[1:2], collapse = "_")
  
  # Add the extracted components as a new column
  df$ImageID <- basenameID
  
  # Select specific columns
  df %>% select(CellID, Y_centroid, X_centroid, Area, BCL6_status_4, ImageID)
}, .options = furrr_options(seed = TRUE, stdout = TRUE))

final_data <- bind_rows(all_data)

final_data$Group <- "MS"
str(final_data)
write.csv(final_data, "/TMA_reduced_quantified_bcl6_five/TMA_ms_BCL6status.csv", row.names = FALSE)


## hc
folder_path <- "/Volumes/Kek_2Tt_7T/TMA_analysis/TMA_reduced_quantified_bcl6_five/hc"

# Set up parallel processing
plan(multisession)

# List all files in the folder
file_list <- list.files(folder_path, full.names = TRUE)

# Process files in parallel
all_data <- future_map(file_list, function(file) {
  # Read the file efficiently
  df <- fread(file)
  
  # Extract the first two components of the file name
  basenameID <- paste(unlist(strsplit(basename(file), "_"))[1:2], collapse = "_")
  
  # Add the extracted components as a new column
  df$ImageID <- basenameID
  
  # Select specific columns
  df %>% select(CellID, Y_centroid, X_centroid, Area, BCL6_status_4, ImageID)
}, .options = furrr_options(seed = TRUE, stdout = TRUE))

final_data <- bind_rows(all_data)

final_data$Group <- "HC"

write.csv(final_data, "/TMA_reduced_quantified_bcl6_five/TMA_hc_BCL6status.csv", row.names = FALSE)




