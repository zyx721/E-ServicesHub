import os
import easyocr

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
reader = easyocr.Reader(['ar', 'en'])

def extract_information(image):
    result = reader.readtext(image)

    id_number = None
    surname = None
    first_name = None

    # Store the texts and their positions in a list
    text_data = []

    # Iterate through the OCR results
    for (bbox, text, prob) in result:
        print(f'Text: {text} (Probability: {prob})')
        text_data.append(text)

        # Check for the ID number
        if "رقم التعريف" in text or "رقم التعريف الشخصي" in text:
            # Look for a number in the surrounding texts
            for nearby_text in text_data:
                if nearby_text.isdigit() and len(nearby_text) == 18:  # Adjust length as per your ID number format
                    id_number = nearby_text
                    break

        # Extract surname and first name
        if "اللقب" in text:
            surname_index = text_data.index(text)
            if surname_index + 1 < len(text_data):
                surname = text_data[surname_index + 1].strip()  # Get the next text
        elif "الإسم" in text:
            first_name_index = text_data.index(text)
            if first_name_index + 1 < len(text_data):
                first_name = text_data[first_name_index + 1].strip()  # Get the next text

    return id_number, surname, first_name


if __name__ == "__main__":
    image_path = 'testing_images/PXL_20241012_182045207.jpg'
    info = extract_information(image_path)
    print("Extracted Information:", info)
