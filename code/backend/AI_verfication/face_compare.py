import face_recognition

# Load the images
known_image = face_recognition.load_image_file('PXL_20241012_182854648.jpg')  # Known photo
extracted_face_image = face_recognition.load_image_file('extracted_largest_face_ziad.jpg')  # Extracted face from card

# Encode the face in each image
known_encoding = face_recognition.face_encodings(known_image)[0]
extracted_face_encoding = face_recognition.face_encodings(extracted_face_image)[0]

# Compare the faces
results = face_recognition.compare_faces([known_encoding], extracted_face_encoding)

if results[0]:
    print("Faces match!")
else:
    print("Faces do not match.")
