from fastapi import FastAPI, File, UploadFile, HTTPException
import onnxruntime
import numpy as np
from PIL import Image

app = FastAPI()

# Load the ONNX model
ort_session = onnxruntime.InferenceSession("mobilenet_model.onnx")

# Define your class labels
# Assuming 0 is for "with_id" and 1 is for "without_id"
class_labels = ["without_id", "with_id"]


def load_and_preprocess_image(image_file):
    try:
        image = Image.open(image_file)
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid image file.")

    # Resize to the expected input size, e.g., 224x224 for MobileNet
    image = image.resize((224, 224))
    # Convert image to numpy array and normalize
    image_array = np.array(image).astype(np.float32) / 255.0

    # Check if image has three channels (RGB)
    if image_array.shape[-1] != 3:
        raise HTTPException(status_code=400, detail="Image must be RGB.")

    # Change dimensions to fit the model input (N, C, H, W)
    image_array = np.transpose(image_array, (2, 0, 1))  # HWC to CHW
    image_array = np.expand_dims(image_array, axis=0)  # Add batch dimension
    return image_array


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Validate file type
    if not file.filename.endswith(('.png', '.jpg', '.jpeg')):
        raise HTTPException(status_code=400, detail="File type not supported. Please upload a PNG or JPG image.")

    # Load the image and preprocess it
    image = load_and_preprocess_image(file.file)

    # Make a prediction
    ort_inputs = {ort_session.get_inputs()[0].name: image}
    ort_outs = ort_session.run(None, ort_inputs)

    # Convert the output to class probabilities
    predictions = ort_outs[0]  # Assuming the output is a probability distribution

    # Get the predicted class
    predicted_class_index = np.argmax(predictions)  # Index of the class with the highest score
    predicted_class = class_labels[predicted_class_index]

    # Check if the prediction is for "with_id"
    if predicted_class == "with_id":
        response_color = "green"
    else:
        response_color = "red"

    return {
        "predictions": predictions.tolist(),
        "predicted_class": predicted_class,
        "rectangle_color": response_color  # Return the color for the rectangle
    }

# To run the server, use the command:
# uvicorn backend:app --reload
