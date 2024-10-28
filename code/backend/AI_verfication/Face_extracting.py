import cv2

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Correct file path for your image
image_path = r'testing_images/PXL_20241012_182045207.jpg'
image = cv2.imread(image_path)

# Ensure the image is loaded correctly
if image is None:
    print(f"Error: Could not open or find the image at {image_path}")
else:
    # Convert to grayscale for face detection
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Detect faces in the image
    faces = face_cascade.detectMultiScale(gray_image, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

    # Check if faces are detected
    if len(faces) == 0:
        print("No faces detected.")
    else:
        # Find the largest face by area (width * height)
        largest_face = None
        largest_area = 0

        for (x, y, w, h) in faces:
            area = w * h
            if area > largest_area:
                largest_area = area
                largest_face = (x, y, w, h)

        # Extract the largest face if found
        if largest_face:
            x, y, w, h = largest_face
            face = image[y:y + h, x:x + w]

            # Save the extracted face
            face_output_path = 'extracted_largest_facet_fares.jpg'
            cv2.imwrite(face_output_path, face)

            print(f"Largest face saved to {face_output_path}")
