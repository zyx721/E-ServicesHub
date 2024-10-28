# extract_info.py
import os

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
import easyocr
import cv2
reader = easyocr.Reader(['ar', 'en'])

def extract_information(image):
    result = reader.readtext(image)

    id_number = None
    surname = None
    first_name = None

    # Iterate through the OCR results
    for (bbox, text, prob) in result:
        print(f'Text: {text} (Probability: {prob})')

        # Check for the ID number
        if "رقم التعريف" in text:
            # Look for a number before or after the token
            for (bbox2, text2, prob2) in result:
                if (text2.isdigit() and len(text2) == 18):  # Adjust length as per your ID number format
                    id_number = text2
                    break

        # Extract surname and first name
        if "اللقب :" in text:
            surname = text.split(":")[-1].strip()
        elif "الإسم :" in text:
            first_name = text.split(":")[-1].strip()

    return id_number, surname, first_name


if __name__ == "__main__":
    image_path = 'testing_images/PXL_20241012_182045207.jpg'
    info = extract_information(image_path)
    print("Extracted Information:", info)
