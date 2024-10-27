# extract_info.py
import easyocr
import cv2

def extract_id_info(image_path):
    # Initialize EasyOCR reader with Arabic and French
    reader = easyocr.Reader(['ar', 'fr', 'en'])  # Arabic, French, and English

    # Load the image
    image = cv2.imread(image_path)

    # Perform OCR
    results = reader.readtext(image)

    # Extract and print the information
    extracted_info = {}
    for (bbox, text, prob) in results:
        # You can refine this logic based on your specific needs
        if "اسم" in text:  # "اسم" means "Name" in Arabic
            extracted_info['Name'] = text.split(":")[-1].strip()  # Adjust parsing as needed
        elif "رقم" in text:  # "رقم" means "Number" in Arabic
            extracted_info['ID Number'] = text.split(":")[-1].strip()  # Adjust parsing as needed

    return extracted_info

if __name__ == "__main__":
    image_path = 'testing_images/PXL_20241012_182045207.jpg'
    info = extract_id_info(image_path)
    print("Extracted Information:", info)
