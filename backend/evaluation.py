from langchain_groq import ChatGroq
llm=ChatGroq(api_key='your api key')

import google.generativeai as genai
genai.configure(api_key="your api key")
model = genai.GenerativeModel("gemini-1.5-pro")

import bert_score
from bert_score import score

def evaluate_answer_multiple_refs(max_score,candidate, references, model_type="microsoft/deberta-xlarge-mnli", scoring_method="max"):
    """
    Compute BERTScore for a candidate answer against multiple reference answers 
    and convert to a 10-point scale.

    Args:
    - candidate (str): The student's/model-generated answer.
    - references (list): List of LLM-generated reference answers.
    - model_type (str): Pretrained model to use for BERTScore.
    - scoring_method (str): "max" to take the best score, "average" to take the mean score.

    Returns:
    - score_out_of_10 (float): The final score out of 10.
    """
    P, R, F1 = score([candidate] * len(references), references, model_type=model_type, lang="en", verbose=False)

    f1_scores = F1.tolist()  # Convert tensor to list

    if scoring_method == "max":
        final_f1 = max(f1_scores)  # Take the highest F1-score among references
    elif scoring_method == "average":
        final_f1 = sum(f1_scores) / len(f1_scores)  # Take the average F1-score
    else:
        raise ValueError("Invalid scoring_method. Use 'max' or 'average'.")

    score_out_of_10 = round(final_f1 * max_score, 2)  # Scale to 10-point system
    print(score_out_of_10)

    return score_out_of_10






def evaluation_answer(question,student_answer):
    response1=llm.invoke(input=question)
    print(f"student_answer is {question}")
    
    response2 = model.generate_content(question)
    references=[response1.content,response2.text]
    score_10 = evaluate_answer_multiple_refs(10,student_answer, references, scoring_method="max")
    return score_10


def evaluate_without_bert(question,answer,max_mark):
    prompt=f"evaluate the answer {answer}, based on the question {question} and give mark only out of {max_mark} no explanation"
    output=model.generate_content(prompt)
    return output.text



#print(response1)




