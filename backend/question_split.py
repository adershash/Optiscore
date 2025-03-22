import re



def split_question(answer_text): # Regex to match question number followed by a period and space 
    matches = re.findall(r'(\d+)\.\s*(.*?)(?=\d+\.|$)', answer_text, re.DOTALL) 
    if not matches: return [] # Determine the highest question number 
    max_question = max(int(num) for num, _ in matches) # Initialize the answer list with empty strings 
    answers = [""] * max_question # Populate answers based on question number 
    for num, ans in matches: 
        answers[int(num) - 1] = ans.strip()
    result2=[]
    for ques in answers:
        ques1=ques.replace(","," ").replace("\n","").replace("\r","")
        result2.append(ques1)
    processed_list=[]
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
    return processed_list # Example usage input_text = "1. Answer with number 123. and more text 2. Another answer 3. Answer 3 has a number 456.78. 4. Final answer." result = split_answers(input_text) print(result) 
