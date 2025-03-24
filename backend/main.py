from fastapi import FastAPI,File,UploadFile
from ocr import detect_text
from evaluation import evaluation_answer,evaluate_without_bert
from question_split import split_question,extract_max_number
from question_extract import extract_question
from answerspli import split_answer
import re
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware




app=FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

app.state.result=""
app.state.counter=0
app.state.max_score=0
app.state.questions=""
app.state.answers=""
app.state.ques_no=""
app.state.question_list=[]
app.state.answer_list=[]
app.state.answer_key=""
# Pydantic model to define the expected data structure
class TextRequest(BaseModel):
    question: str

class MaxScoreRequest(BaseModel):
    max_score: int

class ClearRequest(BaseModel):
    clear: bool

class AnswerkeyRequest(BaseModel):
    answerkey:str


@app.get('/')
async def root():
    return {"name":"adersh","data":101}

@app.post("/max_score/")
async def receive_max_score(data: MaxScoreRequest):
    app.state.max_score=data.max_score
    return {"message": f"Received max score: {data.max_score}"}

@app.post('/question/')
async def question_split(file:UploadFile=File(...)):
    file.filename=f"myquestion{app.state.counter}.jpg"
    app.state.counter+=1

    contents=await file.read()

    with open(f"questions/{file.filename}","wb") as f:
        f.write(contents)
    questions=extract_question(f"questions/{file.filename}")
    app.state.questions+=questions
    print(f"question is: {app.state.questions}")
    return {"filename":file.filename}
    


@app.post("/upload/")
async def create_upload(file:UploadFile=File(...)):
    file.filename="myfile.jpg"
    contents=await file.read()

    with open(f"images/{file.filename}","wb") as f:
        f.write(contents)
    answers=extract_question(f"images/{file.filename}")
    app.state.answers+=answers
    print(app.state.answers)
    return {"filename":file.filename}

@app.get("/convert/")
async def convert_text():
   image_path = "myfile.jpg"
   text = detect_text(image_path)
   app.state.result=','.join(text)
   app.state.result.replace("\n","")
   app.state.result.replace("\r","")
   return {'text':app.state.result}

@app.get("/evaluate/")
async def eval_answer():
    image_path = "myfile.jpg"
    text = detect_text(image_path)
    app.state.result=','.join(text)
    app.state.result.replace("\n","")
    app.state.result.replace("\r","")
    if not app.state.question_list:
        app.state.question_list=split_question(app.state.questions)

    score=evaluation_answer(app.state.question_list[app.state.ques_no-1],app.state.result,app.state.max_score)
    score1=str(score)
    return {"result":score1}

@app.get("/testeval/")
async def eval_without_bert():
    
    f_ind=0
    sec_ind=0
    first=0

    print(app.state.result)
    if not app.state.question_list or not app.state.answer_list:
        print("first if")
        if not app.state.question_list:
            app.state.question_list=split_question(app.state.questions)
            print("qustion list empty")
        if not app.state.answer_list:
            print("answerlist empty")
            app.state.answer_list=split_answer(app.state.answers,len(app.state.question_list))
    if app.state.ques_no.isdigit():
        print(f"before index {app.state.ques_no}")
        qno=int(app.state.ques_no)
        print(f"after index {qno}")
        print(f"question is : {app.state.question_list[qno-1]}")
        print(f"answer is : {app.state.answer_list[qno-1]}")
        out=evaluate_without_bert(app.state.question_list[qno-1],app.state.answer_list[qno-1],app.state.max_score)
    else:
        match = re.match(r'(\d+)([a-zA-Z]*)', app.state.ques_no)  # Captures digits first, then letters
        f_ind = match.group(1)
        first=int(f_ind)  # Extracts the digit part
        alpha_part = match.group(2) 
        if alpha_part == 'a':
            sec_ind=0
        elif alpha_part == 'b':
            sec_ind=1
        elif alpha_part == 'c' :
            sec_ind=2
        out=evaluate_without_bert(app.state.question_list[first-1][sec_ind],app.state.answer_list[first-1][sec_ind],app.state.max_score,app.state.answer_key)
    print(f"output is {out}")
    return {"result":out}


@app.post("/question_no/")
async def question_no(data: TextRequest):
    match = re.match(r'(\d+)([a-zA-Z]*)', data.question)  # Captures digits first, then letters
    qno = match.group(1)
    qno1=int(qno) 
    print(f"qno1:{qno1}")

    max_qno=extract_max_number(app.state.questions)
    print(f"max question number: {max_qno}")

    if qno1 > int(max_qno):
        return{"message": "false"}
    else:
        app.state.ques_no=data.question
        return {"message":"true"}
    
@app.post("/clear/")
async def clear_data(data:ClearRequest):
    if data.clear:
        app.state.result=""
        app.state.counter=0
        app.state.max_score=0
        app.state.questions=""
        app.state.answers=""
        app.state.ques_no=""
        app.state.question_list.clear()
        app.state.answer_list.clear()
        app.state.answer_key=""
        print("data: cleared")
        return{"status":"success"}
    else:
        return{"status":"fail"}
    

@app.post("/answerkey/")
async def question_no(data: AnswerkeyRequest):
    
    app.state.answer_key=data.answerkey
    print(f"answerkey is :{app.state.answer_key}")
    return {"status":"success"}