import re
from ocr import detect_text




def extract_questions():
    image_path = "question.jpg"
    text = detect_text(image_path)
    result=','.join(text)
    result.replace("\n","")
    result.replace("\r","")
    # Pattern to match question number followed by a period and space
    pattern = r"(\d+)\.\s*([^\d]+)"
    matches = re.findall(pattern,result)

    # Convert matches to a list of tuples (number, question)
    questions = sorted(matches, key=lambda x: int(x[0]))
    
    # Extract the question text in the order of question numbers
    question_list = [q[1].strip() for q in questions]
    final_ques=question_list[::2]

    return final_ques

