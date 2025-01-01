import os
import shutil
import cv2
from fastapi import FastAPI, UploadFile, File, Form
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
import firebase_admin
from firebase_admin import credentials, firestore
import hashlib  # Import hashlib for hashing

# Initialize Firebase Admin SDK
cred = credentials.Certificate("firebase-adminsdk-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Suppress the FutureWarning for torch.load
warnings.filterwarnings("ignore")

# Load your trained YOLO models
model = YOLO("front_model/best.pt")
# Remove the loading of the second model from here
# model_back = YOLO("back_model/best.pt")  # Load the second model for back ID

# Initialize EasyOCR reader for English text, force use of CPU
ocr_reader = easyocr.Reader(['en'], gpu=True)

app = FastAPI()

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Path to store extracted face images
extracted_faces_dir = 'extracted_faces'

# Ensure the directory exists
os.makedirs(extracted_faces_dir, exist_ok=True)

# Define mouth landmarks (indices from the shape_predictor_68_face_landmarks.dat model)
MOUTH_POINTS = list(range(48, 68))

# Helper function to calculate mouth aspect ratio (MAR)
#dsfsdf
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

def extract_face(image_path, compare_id):
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
        face = image[y:y + h, x:x + w]  # Corrected coordinates for cropping the face
        face_image_path = os.path.join(extracted_faces_dir, f"{compare_id}.jpg")
        cv2.imwrite(face_image_path, face)  # Save to a specific path
        print(f"Largest face saved to {face_image_path}")
        return face_image_path

def extract_number_from_logo(image_path, logo_box, expected_length, logo_type):
    try:
        x1, y1, x2, y2 = logo_box
        if logo_type == 2:
            padding_left = 90  # Increased padding to the left for logo 2
            padding_other = 10  # Minimal padding for other directions
        else:
            padding_left = 10  # Minimal padding for logo 3
            padding_other = 10  # Minimal padding for all directions

        x = max(0, int(x1) - padding_left)  # Increase padding to the left
        y = max(0, int(y1) - padding_other)
        w = int(x2 - x1) + padding_left + padding_other  # Increase padding on the right side
        h = int(y2 - y1) + 2 * padding_other
        
        image = cv2.imread(image_path)
        if image is None:
            print("Failed to load image")
            return None
            
        # Ensure coordinates are within image bounds
        y2 = min(y + h, image.shape[0])
        x2 = min(x + w, image.shape[1])
        logo_image = image[y:y2, x:x2]
        
        # Convert to grayscale
        gray_logo = cv2.cvtColor(logo_image, cv2.COLOR_BGR2GRAY)
        
        # Apply sharpening
        kernel = np.array([[0, -1, 0], [-1, 5,-1], [0, -1, 0]])
        sharpened_logo = cv2.filter2D(gray_logo, -1, kernel)
        
        # Save processed image for debugging
        debug_path = f"debug_processed_{expected_length}.png"

        
        # Perform OCR with adjusted parameters
        result = ocr_reader.readtext(
            sharpened_logo,
            detail=0,
            paragraph=False,
            batch_size=1,
            min_size=10,
            contrast_ths=0.2,
            adjust_contrast=0.5,
            text_threshold=0.6
        )
        
        # Join all results and clean up
        extracted_text = "".join(result).replace(" ", "").replace(":", "").replace("+", "").replace("*", "")
        print(f"Cleaned extracted text: {extracted_text}")
        
        # Extract numbers of expected length
        pattern = rf'\d{{{expected_length}}}'
        numbers = re.findall(pattern, extracted_text)
        
        if not numbers:
            print(f"No valid {expected_length}-digit number found in: {extracted_text}")
            return None
            
        return numbers[0]
        
    except Exception as e:
        print(f"Error in extract_number_from_logo: {e}")
        return None

def check_logos(image_path):
    results = model.predict(source=image_path, save=False, imgsz=640, device=0)
    logos_found = {0: False, 1: False, 2: False, 3: False}
    logo_numbers = {'logo2': None, 'logo3': None}
    
    try:
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    class_id = int(box.cls.item())
                    if class_id in logos_found:
                        logos_found[class_id] = True
                        
                        if class_id == 2:  # Main ID number
                            number = extract_number_from_logo(image_path, box.xyxy[0].cpu().numpy(), 18, 2)
                            if number:  # Only update if a valid number was found
                                logo_numbers['logo2'] = number
                        elif class_id == 3:  # Compare ID
                            number = extract_number_from_logo(image_path, box.xyxy[0].cpu().numpy(), 9, 3)
                            if number:  # Only update if a valid number was found
                                logo_numbers['logo3'] = number

        print(f"Logos found: {logos_found}")
        print(f"Extracted numbers: {logo_numbers}")
        return logos_found, logo_numbers
        
    except Exception as e:
        print(f"Error in check_logos: {e}")
        return {0: False, 1: False, 2: False, 3: False}, {'logo2': None, 'logo3': None}

# Global variable to store compare_id and id_number
compare_id_global = None
id_number_global = None

def hash_id_number(id_number):
    return hashlib.sha256(id_number.encode()).hexdigest()
 
def check_id_and_compare_id_exist(id_number, compare_id):
    hashed_id_number = hash_id_number(id_number)
    hashed_compare_id = hash_id_number(compare_id)
    metadata_ref = db.collection('Metadata')
    
    id_number_exists = any(metadata_ref.where('id_number', '==', hashed_id_number).stream())
    compare_id_exists = any(metadata_ref.where('compare_id', '==', hashed_compare_id).stream())
    
    print(f"Checking database for ID number: {id_number} (hashed: {hashed_id_number})")
    print(f"ID number exists: {id_number_exists}")
    print(f"Checking database for Compare ID: {compare_id} (hashed: {hashed_compare_id})")
    print(f"Compare ID exists: {compare_id_exists}")
    
    return id_number_exists, compare_id_exists

def delete_file(file_path):
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Deleted file: {file_path}")
        else:
            print(f"File not found: {file_path}")
    except Exception as e:
        print(f"Error deleting file {file_path}: {e}")

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    global compare_id_global, id_number_global
    try:
        # Generate a temporary file location to save the uploaded image
        temp_dir = "uploaded_images"
        os.makedirs(temp_dir, exist_ok=True)
        temp_file_location = f"{temp_dir}/{file.filename}"

        with open(temp_file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        logos_found, logo_numbers = check_logos(temp_file_location)

        # Check logo presence
        valid_logo_combination = (
            (logos_found[0] and logos_found[1] and logos_found[2] and logos_found[3] and logo_numbers['logo2'] and logo_numbers['logo3']) or
            (logos_found[0] and logos_found[2] and logos_found[3] and logo_numbers['logo2'] and logo_numbers['logo3']) or
            (logos_found[1] and logos_found[2] and logos_found[3] and logo_numbers['logo2'] and logo_numbers['logo3'])
        )

        if not valid_logo_combination:
            delete_file(temp_file_location)
            return JSONResponse(content={
                "message": "Invalid ID: Missing required logos or numbers. Please retake the picture.",
                "stop_capture": False
            })

        # Validate ID numbers
        id_number = logo_numbers.get('logo2')
        compare_id = logo_numbers.get('logo3')

        if not id_number or len(id_number) != 18:
            delete_file(temp_file_location)
            return JSONResponse(content={
                "message": "Invalid ID: Main ID number not properly detected. Please retake the picture.",
                "stop_capture": False
            })

        if not compare_id or len(compare_id) != 9:
            delete_file(temp_file_location)
            return JSONResponse(content={
                "message": "Invalid ID: Compare ID not properly detected. Please retake the picture.",
                "stop_capture": False
            })

        # Check if id_number and compare_id already exist in the Metadata collection
        id_number_exists, compare_id_exists = check_id_and_compare_id_exist(id_number, compare_id)
        if id_number_exists or compare_id_exists:
            delete_file(temp_file_location)
            return JSONResponse(content={
                "message": "ID number or Compare ID already exists. Please use a different ID.",
                "stop_capture": False
            })

        # Save compare_id and id_number for later use
        compare_id_global = compare_id
        id_number_global = id_number

        # Save the uploaded image with the compare_id as part of the filename
        uploaded_image_dir = "uploaded_images_with_id"
        os.makedirs(uploaded_image_dir, exist_ok=True)
        uploaded_image_path = os.path.join(uploaded_image_dir, f"{compare_id}_img.jpg")
        shutil.move(temp_file_location, uploaded_image_path)

        # Extract face
        face_image_path = extract_face(uploaded_image_path, compare_id)
        if not face_image_path:
            delete_file(uploaded_image_path)
            return JSONResponse(content={
                "message": "Invalid ID: No face detected. Please retake the picture.",
                "stop_capture": False
            })

        # Delete the uploaded image after extracting the face
        delete_file(uploaded_image_path)

        return JSONResponse(content={
            "message": "ID verified successfully.",
            "id_number": id_number,
            "compare_id": compare_id,
            "face_image_path": face_image_path,
            "stop_capture": True
        })

    except Exception as e:
        print(f"Error processing upload: {e}")
        return JSONResponse(content={
            "message": "Error processing ID. Please try again.",
            "stop_capture": False
        })

@app.post("/upload-back-id/")
async def upload_back_id(file: UploadFile = File(...)):
    global compare_id_global, id_number_global
    try:
        # Load the second YOLO model for back ID verification
        model_back = YOLO("back_model/best.pt")

        # Generate a temporary file location to save the uploaded back ID image
        temp_dir = "uploaded_back_ids"
        os.makedirs(temp_dir, exist_ok=True)
        temp_file_location = f"{temp_dir}/{file.filename}"

        with open(temp_file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Resize image to reduce memory usage
        # temp_file_location = resize_image(temp_file_location)

        # Perform logo detection using the second model
        logos_found = check_logos_with_model(temp_file_location, model_back)

        # Check logo presence
        if not (logos_found[0] and logos_found[1]):
            delete_file(temp_file_location)
            print("Invalid Back ID: Missing required logos")
            return JSONResponse(content={
                "message": "Invalid Back ID: Please retake the picture.",
                "stop_capture": False  # Indicate not to stop capturing
            })

        # Clear GPU memory after logo detection
        clear_gpu_memory()

        # Perform OCR to extract text from the back of the ID
        extracted_text = extract_text(temp_file_location)
        last_name, first_name = extract_names(extracted_text)

        # Extract second_pair_id from the text
        second_pair_id = extract_second_pair_id(extracted_text)

        if last_name and first_name and second_pair_id:
            print(f"Extracted Last Name: {last_name}")
            print(f"Extracted First Name: {first_name}")
            print(f"Extracted Second Pair ID: {second_pair_id}")

            # Compare second_pair_id with the saved compare_id
            if second_pair_id == compare_id_global:
                # Save the uploaded back ID image with the compare_id as part of the filename
                uploaded_back_id_dir = "uploaded_back_ids_with_id"
                os.makedirs(uploaded_back_id_dir, exist_ok=True)
                uploaded_back_id_path = os.path.join(uploaded_back_id_dir, f"{compare_id_global}_back_img.jpg")
                shutil.move(temp_file_location, uploaded_back_id_path)

                # Hash the id_number and compare_id and save them to the Metadata collection
                hashed_id_number = hash_id_number(id_number_global)
                hashed_compare_id = hash_id_number(compare_id_global)
                db.collection('Metadata').add({
                    'id_number': hashed_id_number,
                    'compare_id': hashed_compare_id,
                    'last_name': last_name,
                    'first_name': first_name,
                    'timestamp': datetime.now()
                })

                # Delete the back ID image after verification
                delete_file(uploaded_back_id_path)

                return JSONResponse(content={
                    "message": "Back ID verified successfully.",
                    "last_name": last_name,
                    "first_name": first_name,
                    "second_pair_id": second_pair_id,
                    "compare_id": compare_id_global,  # Add this line
                    "stop_capture": True  # Indicate to stop capturing
                })
            else:
                delete_file(temp_file_location)
                print("Back ID does not match the front ID.")
                return JSONResponse(content={
                    "message": "Back ID does not match the front ID.",
                    "stop_capture": False  # Indicate not to stop capturing
                })
        else:
            delete_file(temp_file_location)
            print("Failed to verify back ID.")
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

def compare_faces(face_image_path, compare_id, tolerance=0.6):
    # Load the extracted face image for the given compare_id
    extracted_face_path = os.path.join(extracted_faces_dir, f"{compare_id}.jpg")
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
async def compare_face(compare_id: str = Form(...), file1: UploadFile = File(...), file2: UploadFile = File(...)):
    upload_dir = "face_images"
    os.makedirs(upload_dir, exist_ok=True)
    file_location1 = f"{upload_dir}/{file1.filename}"
    file_location2 = f"{upload_dir}/{file2.filename}"

    with open(file_location1, "wb") as buffer:
        shutil.copyfileobj(file1.file, buffer)

    with open(file_location2, "wb") as buffer:
        shutil.copyfileobj(file2.file, buffer)

    try:
        # Load the pre-trained facial landmark detector
        predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")  # Ensure you have the shape predictor file

        # Verify mouth status
        if not verify_mouth_status(file_location1, "closed", predictor):
            delete_file(file_location1)
            delete_file(file_location2)
            return JSONResponse(content={"message": "First image should have mouth closed."})
        if not verify_mouth_status(file_location2, "open", predictor):
            delete_file(file_location1)
            delete_file(file_location2)
            return JSONResponse(content={"message": "Second image should have mouth open."})

        # Proceed with face comparison
        faces_match = compare_faces(file_location2, compare_id, tolerance=0.6)

        if faces_match:
            # Delete the extracted face image after successful verification
            extracted_face_path = os.path.join(extracted_faces_dir, f"{compare_id}.jpg")
            delete_file(extracted_face_path)
            delete_file(file_location1)
            delete_file(file_location2)
            return JSONResponse(content={"message": "Faces match!"})
        else:
            delete_file(file_location1)
            delete_file(file_location2)
            return JSONResponse(content={"message": "Faces do not match."})

    except Exception as e:
        print(f"Error comparing faces: {e}")
        delete_file(file_location1)
        delete_file(file_location2)
        return JSONResponse(content={"message": "Error comparing faces."})

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

    if name_pattern:
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
                if len(last_name) >= 2 and len(first_name) >= 2:
                    return last_name, first_name

        except Exception as e:
            print(f"Error processing names: {e}")

    # Alternative method: Look for "Nom:" and "Prenom(s):"
    try:
        last_name_match = re.search(r'Nom:\s*([A-Z]+)', extracted_text, re.IGNORECASE)
        first_name_match = re.search(r'Prenom\(s\):\s*([A-Z\s]+)', extracted_text, re.IGNORECASE)

        if last_name_match and first_name_match:
            last_name = last_name_match.group(1).upper()
            first_name = ' '.join(first_name_match.group(1).split()).upper()

            # Additional validation
            if len(last_name) >= 2 and len(first_name) >= 2:
                return last_name, first_name

    except Exception as e:
        print(f"Error processing names with alternative method: {e}")

    print("Could not find valid name pattern")
    return None, None

def extract_second_pair_id(extracted_text):
    """
    Extract second_pair_id from the text and ensure it contains only digits.

    Args:
        extracted_text (str): The text extracted from the image

    Returns:
        str: The cleaned second_pair_id or None if not found
    """
    second_pair_id_match = re.search(r'IDDZA(\w{9})', extracted_text, re.IGNORECASE)
    if second_pair_id_match:
        second_pair_id = second_pair_id_match.group(1)
        # Replace alphabetic characters with similar-looking digits
        second_pair_id = second_pair_id.replace('O', '0').replace('o', '0').replace('I', '1').replace('l', '1')
        if second_pair_id.isdigit():
            return second_pair_id
    return None

# To run the server, use:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload 

# lt --port 8000 --subdomain polite-schools-ask