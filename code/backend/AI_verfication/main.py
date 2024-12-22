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

# Suppress the FutureWarning for torch.load
warnings.filterwarnings("ignore")

# Load your trained YOLO models
model = YOLO("front_model/best.pt")
model_back = YOLO("back_model/best.pt")  # Load the second model for back ID

# Initialize EasyOCR reader for English text
ocr_reader = easyocr.Reader(['en'])

app = FastAPI()

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Path to store extracted face images
extracted_face_path = 'extracted_largest_face.jpg'


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

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Perform logo detection using the second model
    logos_found = check_logos_with_model(file_location, model_back)

    # Check logo presence
    if not (logos_found[0] and logos_found[1]):
        print("Invalid Back ID: Missing required logos")
        return JSONResponse(content={
            "message": "Invalid Back ID: Please retake the picture.",
            "stop_capture": False  # Indicate not to stop capturing
        })

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

def compare_faces(face_image_path1, face_image_path2, tolerance=0.6):
    # Load the two images for comparison
    face1 = cv2.imread(face_image_path1)
    face2 = cv2.imread(face_image_path2)

    if face1 is None or face2 is None:
        print("Error: One or both images could not be loaded.")
        return False

    # Convert images to RGB (face_recognition uses RGB, while OpenCV uses BGR)
    face1_rgb = cv2.cvtColor(face1, cv2.COLOR_BGR2RGB)
    face2_rgb = cv2.cvtColor(face2, cv2.COLOR_BGR2RGB)

    # Get face encodings for both images
    face1_encodings = face_recognition.face_encodings(face1_rgb)
    face2_encodings = face_recognition.face_encodings(face2_rgb)

    # Check if faces were found in both images
    if len(face1_encodings) == 0:
        print("No faces found in the first image.")
        return False
    if len(face2_encodings) == 0:
        print("No faces found in the second image.")
        return False

    # Compare the first encoding (assuming one face per image) with tolerance
    results = face_recognition.compare_faces([face1_encodings[0]], face2_encodings[0], tolerance=tolerance)

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

    # Call compare_faces with a tolerance value, e.g., 0.5 for moderate strictness
    faces_match = compare_faces(file_location1, file_location2, tolerance=0.6)

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

    # Optionally, resize the image to make text more defined
    resized = cv2.resize(enhanced_image, (0, 0), fx=2, fy=2, interpolation=cv2.INTER_CUBIC)

    # Save the preprocessed image (for debugging or further inspection)
    preprocessed_image_path = "preprocessed_image_with_extra_sharpness.png"
    cv2.imwrite(preprocessed_image_path, resized)

    return preprocessed_image_path, resized  # Return path and image data

def extract_text(image_path):
    # Preprocess the image to improve OCR accuracy
    preprocessed_image_path, preprocessed_image = preprocess_image(image_path)

    # Perform OCR using EasyOCR to extract English text (you can change language if needed)
    result = ocr_reader.readtext(preprocessed_image, detail=0, paragraph=True)
    extracted_text = " ".join(result)

    print("Extracted Text:", extracted_text)
    return extracted_text


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
        # Check if the word contains '<<' and ends with multiple '<'s
        if '<<' in word and any(c in word for c in ['<', 'K']):  # Include 'K' as it might appear
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
            first_name = name_components[1]

            # Clean the names (remove any non-alphabetic characters)
            last_name = ''.join(c for c in last_name if c.isalpha()).upper()
            first_name = ''.join(c for c in first_name if c.isalpha()).upper()

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
