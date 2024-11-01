import os
import shutil
import cv2
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import face_recognition

# Load your trained YOLO model
model = YOLO(r"C:\Users\HF\Desktop\L3\IHM\yolov8\project1\runs\detect\train15\weights\best.pt")

app = FastAPI()

# Load the Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

# Path to store extracted face images
extracted_face_path = 'extracted_largest_face.jpg'

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
            "detected_logos": detected_logos
        })

    print("Valid ID")

    # Proceed with face extraction if both logos are valid
    face_image_path = extract_face(file_location)

    if face_image_path:
        return JSONResponse(content={"message": "ID valid. Face extracted.", "face_image_path": face_image_path})
    else:
        return JSONResponse(content={"message": "ID valid but no face detected."})

def compare_faces(face_image_path):
    # Load the two images for comparison
    extracted_face = cv2.imread(extracted_face_path)
    submitted_face = cv2.imread(face_image_path)

    if extracted_face is None or submitted_face is None:
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

    # Compare the first encoding (assuming one face per image)
    results = face_recognition.compare_faces([extracted_face_encodings[0]], submitted_face_encodings[0])

    return results[0]  # Return the result of the comparison


@app.post("/compare-face/")
async def compare_face(file: UploadFile = File(...)):
    upload_dir = "face_images"
    os.makedirs(upload_dir, exist_ok=True)
    file_location = f"{upload_dir}/{file.filename}"

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    faces_match = compare_faces(file_location)

    if faces_match:
        return JSONResponse(content={"message": "Faces match!"})
    else:
        return JSONResponse(content={"message": "Faces do not match."})

# To run the server, use:
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload
