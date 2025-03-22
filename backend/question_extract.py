from ocr import detect_text

def extract_question(imagepath):

    text = detect_text(imagepath)
    result=','.join(text)
    result.replace("\n","")
    result.replace("\r","")
    return result