import cv2

def verify_logo(id_card_image_path, logo_image_path):
    # Load images in grayscale
    id_card = cv2.imread(id_card_image_path, cv2.IMREAD_GRAYSCALE)
    logo = cv2.imread(logo_image_path, cv2.IMREAD_GRAYSCALE)

    # Initialize ORB detector
    orb = cv2.ORB_create()

    # Detect keypoints and descriptors
    kp1, des1 = orb.detectAndCompute(logo, None)
    kp2, des2 = orb.detectAndCompute(id_card, None)

    # If descriptors are None, return False (indicates poor feature detection)
    if des1 is None or des2 is None:
        print("Insufficient features detected for logo verification.")
        return False

    # FLANN-based matcher parameters
    FLANN_INDEX_LSH = 6
    index_params = dict(algorithm=FLANN_INDEX_LSH, table_number=6, key_size=12, multi_probe_level=1)
    search_params = dict(checks=50)  # Increase if you need more accuracy

    # Using FLANN-based matcher with Ratio Test
    flann = cv2.FlannBasedMatcher(index_params, search_params)
    matches = flann.knnMatch(des1, des2, k=2)

    # Apply Ratio Test to filter good matches
    good_matches = []
    for m, n in matches:
        if m.distance < 0.7 * n.distance:  # Lower threshold to reduce false positives
            good_matches.append(m)

    # Define a threshold for successful match based on the number of good matches
    match_threshold = 15  # Adjust this for optimal performance

    # Check if there are enough good matches
    if len(good_matches) >= match_threshold:
        print("Logo verified successfully!")
        return True
    else:
        print("Logo not found!")
        return False

# Example usage
id_card_image_path = 'testing_images/2.jpg'
logo_image_path = 'testing_images/logo/logo.jpg'
is_verified = verify_logo(id_card_image_path, logo_image_path)
print("Verification result:", is_verified)
