from fastapi import FastAPI,File,UploadFile
from ocr import detect_text
from evaluation import evaluation_answer,evaluate_without_bert
from question_split import extract_questions
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
app.state.questions=[]
app.state.ques_no=0
# Pydantic model to define the expected data structure
class TextRequest(BaseModel):
    question: int

class MaxScoreRequest(BaseModel):
    max_score: int


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
    questions=extract_questions()
    app.state.questions.extend(questions)
    print(f"question is: {app.state.questions[app.state.ques_no]}")
    return {"filename":file.filename}
    


@app.post("/upload/")
async def create_upload(file:UploadFile=File(...)):
    file.filename="myfile.jpg"
    contents=await file.read()

    with open(f"images/{file.filename}","wb") as f:
        f.write(contents)
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
    image_path = "images/myfile.jpg"
    text = detect_text(image_path)
    app.state.result=','.join(text)
    app.state.result.replace("\n","")
    app.state.result.replace("\r","")
    
    score=evaluation_answer(app.state.questions[app.state.ques_no-1],app.state.result,app.state.max_score)
    score1=str(score)
    return {"result":score1}

@app.get("/testeval/")
async def eval_without_bert():
    image_path = "images/myfile.jpg"
    text = detect_text(image_path)
    app.state.result=','.join(text)
    app.state.result.replace("\n","")
    app.state.result.replace("\r","")
    print(app.state.result)
    
    out=evaluate_without_bert(app.state.questions[app.state.ques_no-1],app.state.result,app.state.max_score)
    print(f"output is {out}")
    return {"result":out}


@app.post("/question_no/")
async def question_no(data: TextRequest):
    if data.question > len(app.state.questions):
        return{"message": "invalid question number entered"}
    else:
        app.state.ques_no=data.question
        return {"message":"valid number"}