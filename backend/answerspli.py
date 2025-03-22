import re 

def split_answer(answer_text, max_number): 
    # Regex to match question number followed by a period and space 
    matches = re.findall(r'(\d+)\.\s*(.*?)(?=\d+\.|$)', answer_text, re.DOTALL) 
    if not matches:
        return [] 
    
    # Initialize the answer list with empty strings based on max_number
    answers = ["no answer" for _ in range(max_number)]
    
    # Populate answers based on question number 
    for num, ans in matches:
        index = int(num) - 1
        if index < max_number:
            answers[index] = ans.strip()
    
    result2 = [ques.replace(",", " ").replace("\n", "").replace("\r", "") for ques in answers]
    
    processed_list = []
    for item in result2:
        # Check if the string contains sub-questions like 'a )', 'b )', 'a)', 'b)', etc.
        if re.search(r'\b[a-z]\s?\)\s', item):
            # Split based on 'a)', 'b)', 'c)', allowing optional space between letter and bracket
            sub_questions = re.split(r'\b([a-z])\s?\)\s', item)[1:]
            
            # Reconstruct the sublist properly (keeping label and content together)
            sub_questions = [sub_questions[i] + ') ' + sub_questions[i+1] for i in range(0, len(sub_questions), 2)]
            
            processed_list.append(sub_questions)
        else:
            processed_list.append(item)
    
    return processed_list

# Example usage

