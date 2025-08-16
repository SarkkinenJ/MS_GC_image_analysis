import numpy as np
from scipy.ndimage import find_objects, binary_erosion
from skimage.io import imread, imsave
import os
import glob


# Function to shrink masks
def shrink_masks(masked_image, pixels_to_shrink=2):
    """
    Shrinks the objects in a labeled mask image.

    Parameters:
        masked_image (np.array): Input labeled mask image.
        pixels_to_shrink (int): Number of pixels to shrink objects.

    Returns:
        np.array: A new labeled mask image with shrunken objects.
    """
    # Find all individual object coordinates from the image
    obj_coordinates = find_objects(masked_image)

    # Create a new empty image file
    new_masked_image = np.zeros_like(masked_image)

    # Iterate over all object coordinates
    for val, obj_coordinate in enumerate(obj_coordinates, start=1):
        # Get the object from the coordinates
        object_matrix = masked_image[obj_coordinate]

        # Erode the object by the specified number of pixels
        object_erosion = binary_erosion(object_matrix == val, iterations=pixels_to_shrink).astype(int)

        # Assign the object ID to the eroded object
        object_erosion[object_erosion == 1] = val

        # Add the eroded object to the new image
        new_masked_image[obj_coordinate] = object_erosion

    return new_masked_image


# Function to process all images in a folder
def process_masks(input_folder, output_folder, pixels_to_shrink=1):
    """
    Processes all mask files in the input folder, shrinks objects, and saves them to the output folder.

    Parameters:
        input_folder (str): Path to the input folder containing .tif mask files.
        output_folder (str): Path to the output folder for saving processed masks.
        pixels_to_shrink (int): Number of pixels to shrink objects.
    """
    # Ensure the output folder exists
    os.makedirs(output_folder, exist_ok=True)

    # Find all .tif files in the input folder
    file_list = glob.glob(os.path.join(input_folder, "*.tif"))
    total_files = len(file_list)
    print(f"Found {total_files} files to process.")

    for index, file_path in enumerate(file_list, start=1):
        # Get the file name and construct output path
        base_name = os.path.basename(file_path)
        output_path = os.path.join(output_folder, base_name)

        # Progress update
        print(f"[{index}/{total_files}] Processing {base_name}...")

        # Read the mask image
        masked_image = imread(file_path)

        # Ensure the mask is a single-channel labeled mask
        if len(masked_image.shape) != 2:
            print(f"  Skipping {base_name}: not a single-channel image.")
            continue

        # Shrink the masks
        new_masked_image = shrink_masks(masked_image, pixels_to_shrink=pixels_to_shrink)

        # Save the new mask image
        imsave(output_path, new_masked_image.astype(np.uint32))
        print(f"  Saved processed mask to {output_path}.")

    print("Processing complete.")


# Specify input and output directories
input_folder = "/TMA_analysis/TMA_hc_masks"  # Update with your input folder path
output_folder = "/TMA_analysis/TMA_hc_masks_reduced"  # Update with your output folder path
pixels_to_shrink = 2  # Set the number of pixels to shrink

# Process all mask files
process_masks(input_folder, output_folder, pixels_to_shrink)
