import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
import cv2
import easyocr
from skimage.feature import hog




# Initialize EasyOCR reader
reader = easyocr.Reader(['ar', 'en'])  # Specify languages used on the ID card


# Load and preprocess the image
def load_and_preprocess_image(image_path):
    # Read image
    image = cv2.imread(image_path)
    # Resize image if needed
    image = cv2.resize(image, (600, 400))
    # Convert to grayscale for better feature extraction
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return gray


# Extract text using EasyOCR
def extract_text(image):
    results = reader.readtext(image, detail=0)  # Set detail to 0 for plain text output
    extracted_text = " ".join(results)  # Combine the text lines
    return extracted_text


# Extract HOG features to detect security patterns like holograms or watermarks
def extract_hog_features(image):
    hog_features, _ = hog(image, pixels_per_cell=(16, 16), cells_per_block=(1, 1),
                          visualize=True, feature_vector=True)
    return hog_features


# Verify extracted data
def verify_id_data(extracted_text):
    # Placeholder for actual verification logic
    # Check for the presence of typical ID text patterns or keywords
    if "ALGERIA" in extracted_text or "ALGÉRIE" in extracted_text:
        return True
    return False


# Main function to perform verification
def verify_id(image_path):
    image = load_and_preprocess_image(image_path)

    # Step 1: Extract text data
    extracted_text = extract_text(image)
    print("Extracted Text:", extracted_text)

    # Step 2: Extract features
    hog_features = extract_hog_features(image)
    print("Extracted HOG Features:", hog_features[:5])  # Print sample of HOG features

    # Step 3: Verify extracted data
    if verify_id_data(extracted_text):
        print("ID Verification Passed: The ID appears to be real.")
    else:
        print("ID Verification Failed: The ID might be invalid.")


# Test the function with an image of an Algerian ID
verify_id("testing_images/PXL_20241012_182045207.jpg")
