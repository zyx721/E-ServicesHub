import os
import shutil
import cv2
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import face_recognition
import easyocr
from PIL import Image
import re
# Load your trained YOLO model
model = YOLO("best.pt")

app = FastAPI()

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Path to store extracted face images
extracted_face_path = 'extracted_largest_face.jpg'


def preprocess_image(image_path):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    img = cv2.resize(img, (1280, 1280))  # Ensure consistent size
    img = cv2.GaussianBlur(img, (5, 5), 0)  # Reduce noise
    img = cv2.adaptiveThreshold(img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                cv2.THRESH_BINARY, 11, 2)  # Adaptive thresholding
    return img

def extract_id_number(image_path):
    reader = easyocr.Reader(['en'])
    preprocessed_img = preprocess_image(image_path)
    results = reader.readtext(preprocessed_img)

    # Compile a regex pattern to match exactly 18 digits
    digit_pattern = re.compile(r'\b(\d{18})\b')

    # Collect all detected texts
    detected_texts = [text for (bbox, text, prob) in results]

    # Join detected texts into a single string
    combined_text = ' '.join(detected_texts)
    print(f"Combined detected text: {combined_text}")  # For debugging

    # Search for an exact match for 18 consecutive digits
    match = digit_pattern.search(combined_text)

    if match:
        id_number = match.group(1)  # Extract the 18-digit number
        print(f"ID number found: {id_number}")
        return id_number

    print("No valid ID number found.")
    return None
def check_logos(image_path):
    results = model.predict(source=image_path, save=False, imgsz=1280, device=0)
    logos_found = {0: False, 1: False}  # Assuming classes 0 and 1 correspond to the logos

    for result in results:
        boxes = result.boxes
        if boxes is not None:
            for box in boxes:
                class_id = box.cls.item()
                if class_id in logos_found:
                    logos_found[class_id] = True

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

    # Check if both logos are detected
    if not logos_found[0] or not logos_found[1]:
        detected_logos = [k for k, v in logos_found.items() if v]
        print(f"Invalid ID: Detected logos: {detected_logos}")
        return JSONResponse(content={
            "message": "Invalid ID: Please retake the picture.",
            "detected_logos": detected_logos,
            "stop_capture": False  # Indicate not to stop capturing
        })

    print(f"File saved at: {file_location}")
    print("File exists:", os.path.exists(file_location))

    print("Valid ID")

    # Proceed with ID extraction only if valid ID
    id_number = extract_id_number(file_location)
    if not id_number:
        print("No valid ID number found in the image.")
        return JSONResponse(content={"message": "ID is valid but no ID number found.", "stop_capture": False})

    print(f"ID number found: {id_number}")

    # Proceed with face extraction if both logos are valid
    face_image_path = extract_face(file_location)

    if face_image_path:
        return JSONResponse(content={
            "message": "Face extracted.",
            "face_image_path": face_image_path,
            "id_number": id_number,
            "stop_capture": True  # Indicate to stop capturing
        })
    else:
        return JSONResponse(content={
            "message": "ID valid but no face detected.",
            "id_number": id_number,
            "stop_capture": True  # Indicate to stop capturing
        })


def compare_faces(face_image_path, tolerance=0.5):
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
async def compare_face(file: UploadFile = File(...)):
    upload_dir = "face_images"
    os.makedirs(upload_dir, exist_ok=True)
    file_location = f"{upload_dir}/{file.filename}"

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Call compare_faces with a tolerance value, e.g., 0.5 for moderate strictness
    faces_match = compare_faces(file_location, tolerance=0.5)

    if faces_match:
        return JSONResponse(content={"message": "Faces match!"})
    else:
        return JSONResponse(content={"message": "Faces do not match."})

# To run the server, use:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload 

# To run the server, use:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload
