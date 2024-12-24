import os
import shutil
import cv2
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import face_recognition
from PIL import Image
import warnings
import easyocr
import numpy as np
import re
from datetime import datetime
import torch  # Import torch to manage GPU memory
import dlib  # Import dlib for facial landmark detection

# Suppress the FutureWarning for torch.load
warnings.filterwarnings("ignore")

# Load your trained YOLO models
model = YOLO("front_model/best.pt")
model_back = YOLO("back_model/best.pt")  # Load the second model for back ID

# Initialize EasyOCR reader for English text, force use of CPU
ocr_reader = easyocr.Reader(['en'], gpu=True)

app = FastAPI()

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Path to store extracted face images
extracted_face_path = 'extracted_largest_face.jpg'

# Define mouth landmarks (indices from the shape_predictor_68_face_landmarks.dat model)
MOUTH_POINTS = list(range(48, 68))

# Helper function to calculate mouth aspect ratio (MAR)
def mouth_aspect_ratio(landmarks):
    # Get the coordinates of the mouth landmarks
    mouth = [(landmarks.part(i).x, landmarks.part(i).y) for i in MOUTH_POINTS]

    # Calculate the vertical and horizontal distances
    vertical_distance = (abs(mouth[2][1] - mouth[10][1]) + abs(mouth[4][1] - mouth[8][1])) / 2
    horizontal_distance = abs(mouth[0][0] - mouth[6][0])

    # Calculate the mouth aspect ratio (MAR)
    mar = vertical_distance / horizontal_distance
    return mar

def verify_mouth_status(image_path, expected_status, predictor):
    detector = dlib.get_frontal_face_detector()  # Define the detector within the function
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    for face in faces:
        landmarks = predictor(gray, face)
        mar = mouth_aspect_ratio(landmarks)
        if expected_status == "closed" and mar <= 0.5:
            return True
        elif expected_status == "open" and mar > 0.5:
            return True
    return False

def clear_gpu_memory():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.ipc_collect()
        print("GPU memory cleared.")

def resize_image(image_path, max_size=(640, 640)):
    image = cv2.imread(image_path)
    height, width = image.shape[:2]
    if height > max_size[0] or width > max_size[1]:
        scaling_factor = min(max_size[0] / height, max_size[1] / width)
        new_size = (int(width * scaling_factor), int(height * scaling_factor))
        resized_image = cv2.resize(image, new_size, interpolation=cv2.INTER_AREA)
        cv2.imwrite(image_path, resized_image)
        print(f"Image resized to {new_size}")
    return image_path

def check_logos(image_path):
    # Perform logo detection using the YOLO model
    results = model.predict(source=image_path, save=False, imgsz=640, device=0)
    logos_found = {0: False, 1: False, 2: False}  # Assuming classes 0, 1, 2 correspond to the logos

    for result in results:
        boxes = result.boxes
        if boxes is not None:
            for box in boxes:
                class_id = box.cls.item()
                if class_id in logos_found:
                    logos_found[class_id] = True  # Mark the logo as found

    # Log the detection results for debugging purposes
    print(f"Logos found: {logos_found}")

    return logos_found  # Return a dictionary indicating which logos were found

def extract_face(image_path):
    image = cv2.imread(image_path)

    if image is None:
        print(f"Error: Could not open or find the image at {image_path}")
        return None

    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray_image, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

    if len(faces) == 0:
        print("No faces detected.")
        return None
    else:
        largest_face = max(faces, key=lambda face: face[2] * face[3])  # Find the largest face
        x, y, w, h = largest_face
        face = image[y:y + h, x:x + w]
        cv2.imwrite(extracted_face_path, face)  # Save to a specific path
        print(f"Largest face saved to {extracted_face_path}")
        return extracted_face_path

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    upload_dir = "uploaded_images"
    os.makedirs(upload_dir, exist_ok=True)
    file_location = f"{upload_dir}/{file.filename}"

    with open(file_location, "wb") as buffer: 
        shutil.copyfileobj(file.file, buffer)

    logos_found = check_logos(file_location)

    # Check logo combinations
    if logos_found[0] and logos_found[1] and logos_found[2]:
        valid_id = True
    elif (logos_found[0] and logos_found[2]) or (logos_found[1] and logos_found[2]):
        valid_id = True
    elif logos_found[0] and logos_found[1]:
        valid_id = False
    else:
        valid_id = False

    if not valid_id:
        print("Invalid ID: Missing required logos")
        return JSONResponse(content={
            "message": "Invalid ID: Please retake the picture.",
            "stop_capture": False  # Indicate not to stop capturing
        })

    print(f"File saved at: {file_location}")
    print("File exists:", os.path.exists(file_location))

    print("Valid ID")

    # Proceed with face extraction
    face_image_path = extract_face(file_location)

    if face_image_path:
        return JSONResponse(content={
            "message": "Face extracted.",
            "face_image_path": face_image_path,
            "stop_capture": True  # Indicate to stop capturing
        })
    else:
        return JSONResponse(content={
            "message": "ID valid but no face detected.",
            "stop_capture": True  # Indicate to stop capturing
        })

@app.post("/upload-back-id/")
async def upload_back_id(file: UploadFile = File(...)):
    upload_dir = "uploaded_back_ids"
    os.makedirs(upload_dir, exist_ok=True)
    file_location = f"{upload_dir}/{file.filename}"

    try:
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Resize image to reduce memory usage
        file_location = resize_image(file_location)

        # Perform logo detection using the second model
        logos_found = check_logos_with_model(file_location, model_back)

        # Check logo presence
        if not (logos_found[0] and logos_found[1]):
            print("Invalid Back ID: Missing required logos")
            return JSONResponse(content={
                "message": "Invalid Back ID: Please retake the picture.",
                "stop_capture": False  # Indicate not to stop capturing
            })

        # Clear GPU memory after logo detection
        clear_gpu_memory()

        # Perform OCR to extract text from the back of the ID
        extracted_text = extract_text(file_location)
        last_name, first_name = extract_names(extracted_text)

        if last_name and first_name:
            print(f"Extracted Last Name: {last_name}")
            print(f"Extracted First Name: {first_name}")
            return JSONResponse(content={
                "message": "Back ID verified.",
                "last_name": last_name,
                "first_name": first_name,
                "stop_capture": True  # Indicate to stop capturing
            })
        else:
            return JSONResponse(content={
                "message": "Failed to verify back ID.",
                "stop_capture": False  # Indicate not to stop capturing
            })
    except Exception as e:
        print(f"Error processing back ID: {e}")
        clear_gpu_memory()  # Clear GPU memory in case of an error
        return JSONResponse(content={
            "message": "Internal server error.",
            "error": str(e),
            "stop_capture": False  # Indicate not to stop capturing
        }, status_code=500)

def check_logos_with_model(image_path, model):
    # Perform logo detection using the specified YOLO model
    results = model.predict(source=image_path, save=False, imgsz=640, device=0)
    logos_found = {0: False, 1: False}  # Assuming classes 0 and 1 correspond to the logos

    for result in results:
        boxes = result.boxes
        if boxes is not None:
            for box in boxes:
                class_id = box.cls.item()
                if class_id in logos_found:
                    logos_found[class_id] = True  # Mark the logo as found

    print(f"Logos found: {logos_found}")
    return logos_found  # Return a dictionary indicating which logos were found

def compare_faces(face_image_path, tolerance=0.6):
    # Load the two images for comparison
    extracted_face = cv2.imread(extracted_face_path)
    submitted_face = cv2.imread(face_image_path)

    if extracted_face is None or submitted_face is None:
        print("Error: One or both images could not be loaded.")
        return False

    # Convert images to RGB (face_recognition uses RGB, while OpenCV uses BGR)
    extracted_face_rgb = cv2.cvtColor(extracted_face, cv2.COLOR_BGR2RGB)
    submitted_face_rgb = cv2.cvtColor(submitted_face, cv2.COLOR_BGR2RGB)

    # Get face encodings for both images
    extracted_face_encodings = face_recognition.face_encodings(extracted_face_rgb)
    submitted_face_encodings = face_recognition.face_encodings(submitted_face_rgb)

    # Check if faces were found in both images
    if len(extracted_face_encodings) == 0:
        print("No faces found in the extracted face image.")
        return False
    if len(submitted_face_encodings) == 0:
        print("No faces found in the submitted face image.")
        return False

    # Compare the first encoding (assuming one face per image) with tolerance
    results = face_recognition.compare_faces([extracted_face_encodings[0]], submitted_face_encodings[0], tolerance=tolerance)

    if results[0]:
        print("Faces match.")
    else:
        print("Faces do not match.")

    return results[0]  # Return the result of the comparison

@app.post("/compare-face/")
async def compare_face(file1: UploadFile = File(...), file2: UploadFile = File(...)):
    upload_dir = "face_images"
    os.makedirs(upload_dir, exist_ok=True)
    file_location1 = f"{upload_dir}/{file1.filename}"
    file_location2 = f"{upload_dir}/{file2.filename}"

    with open(file_location1, "wb") as buffer:
        shutil.copyfileobj(file1.file, buffer)

    with open(file_location2, "wb") as buffer:
        shutil.copyfileobj(file2.file, buffer)

    # Load the pre-trained facial landmark detector
    predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")  # Ensure you have the shape predictor file

    # Verify mouth status
    if not verify_mouth_status(file_location1, "closed", predictor):
        return JSONResponse(content={"message": "First image should have mouth closed."})
    if not verify_mouth_status(file_location2, "open", predictor):
        return JSONResponse(content={"message": "Second image should have mouth open."})

    # Proceed with face comparison
    faces_match = compare_faces(file_location1, tolerance=0.6)

    if faces_match:
        return JSONResponse(content={"message": "Faces match!"})
    else:
        return JSONResponse(content={"message": "Faces do not match."})

def enhance_sharpness_and_blacks(image_path, sharpen_amount=2.0, black_boost=1.5):
    """
    Enhance image sharpness and make black elements darker

    Parameters:
        image_path (str): Path to the input image
        sharpen_amount (float): Amount of sharpening (higher = sharper, default: 2.0)
        black_boost (float): Amount to darken blacks (higher = darker, default: 1.5)

    Returns:
        numpy.ndarray: Enhanced image
    """
    # Read the image
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError("Could not load image")

    # Convert to LAB color space for better processing
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)

    # Apply multiple levels of sharpening
    for _ in range(2):  # Apply sharpening twice for stronger effect
        # Create a Gaussian blur
        blurred = cv2.GaussianBlur(l, (0, 0), 3)
        # Apply unsharp mask
        l = cv2.addWeighted(l, sharpen_amount, blurred, -(sharpen_amount - 1), 0)

    # Enhance black elements
    _, dark_mask = cv2.threshold(l, 50, 255, cv2.THRESH_BINARY_INV)
    l = cv2.subtract(l, cv2.multiply(dark_mask // 255, int(black_boost * 30)))

    # Merge channels back
    enhanced_lab = cv2.merge([l, a, b])

    # Convert back to BGR
    enhanced = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2BGR)

    return enhanced

def preprocess_image(image_path):
    # Use the enhanced sharpness and black boosting instead of the previous preprocessing
    enhanced_image = enhance_sharpness_and_blacks(image_path, sharpen_amount=3.0, black_boost=2.0)

    # Resize the image to a smaller size to reduce memory usage
    resized = cv2.resize(enhanced_image, (0, 0), fx=1.5, fy=1.5, interpolation=cv2.INTER_LINEAR)

    # Save the preprocessed image (for debugging or further inspection)
    preprocessed_image_path = "preprocessed_image_with_extra_sharpness.png"
    cv2.imwrite(preprocessed_image_path, resized)

    return preprocessed_image_path, resized  # Return path and image data

def extract_text(image_path):
    # Clear GPU memory before OCR processing
    clear_gpu_memory()

    # Preprocess the image to improve OCR accuracy
    preprocessed_image_path, preprocessed_image = preprocess_image(image_path)

    # Perform OCR using EasyOCR to extract English text (you can change language if needed)
    result = ocr_reader.readtext(preprocessed_image, detail=0, paragraph=True)
    extracted_text = " ".join(result)

    print("Extracted Text:", extracted_text)

    # Clear GPU memory after OCR processing
    clear_gpu_memory()

    return extracted_text

# Improved extract_names function to handle the extracted text correctly
def extract_names(extracted_text):
    """
    Extract last name and first name from complex ID text patterns.
    Handles cases with multiple '<<' patterns and additional text.

    Args:
        extracted_text (str): The text extracted from the image

    Returns:
        tuple: (last_name, first_name) or (None, None) if not found
    """
    # Split text into words
    words = extracted_text.split()

    # Look for patterns that match our expected format
    name_pattern = None
    for word in words:
        # Check if the word contains '<<' and word ends with multiple '<'s
        if '<<' in word and word.endswith('<<<<<'):
            # Make sure it's not just a sequence of numbers and '<<'
            parts = word.split('<<')
            if len(parts) >= 2 and any(part.isalpha() for part in parts[:2]):
                name_pattern = word
                break

    if not name_pattern:
        print("Could not find valid name pattern")
        return None, None

    try:
        # Split by '<<' and take only the first two parts
        name_components = name_pattern.split('<<')
        if len(name_components) >= 2:
            last_name = name_components[0]
            first_name = ' '.join(name_components[1:])

            # Clean the names (remove any non-alphabetic characters)
            last_name = ''.join(c for c in last_name if c.isalpha()).upper()
            first_name = ' '.join(''.join(c for c in part if c.isalpha()).upper() for part in first_name.split())

            # Additional validation
            if len(last_name) < 2 or len(first_name) < 2:
                print("Extracted names are too short to be valid")
                return None, None

            return last_name, first_name

    except Exception as e:
        print(f"Error processing names: {e}")
        return None, None

    return None, None

# To run the server, use:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload 

# lt --port 8000 --subdomain polite-schools-ask